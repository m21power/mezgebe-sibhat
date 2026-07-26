import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/cached_song_data.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/server_2_content.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/server_3_content.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/server_4_content.dart';
import 'package:mezgebe_sibhat/features/songs/data/models/server_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mezgebe_sibhat/core/error/failure.dart';
import 'package:mezgebe_sibhat/core/network/network_info_impl.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/server_1_content.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/song_model.dart';
import 'package:mezgebe_sibhat/features/songs/domain/entities/SongModel.dart';
import 'package:mezgebe_sibhat/features/songs/domain/repository/song_repo.dart';
import 'package:http/http.dart' as http;

class SongRepoImpl implements SongRepository {
  final SharedPreferences sharedPreferences;
  final NetworkInfo networkInfo;
  final http.Client client;
  final Box<SongModel> songsBox;
  final Box<CachedAudioData> downloadedAudioBox;
  final Box<CachedImageData> imageCacheBox;
  final serverManager = ServerManager();
  final Map<AudioServer, List<SongModel>> _serverCache = {};
  final Map<AudioServer, Map<String, String>> _audioUrlLookup = {};
  Future<void> initializeServers() async {
    for (final server in AudioServer.values) {
      final jsonValue = getServerContent(server);

      List<SongModel> songs = jsonValue
          .map<SongModel>((json) => SongModel.fromJson(json))
          .toList();

      songs = _sortRecursive(songs);

      _serverCache[server] = songs;

      buildLookup(server, songs, 'root');
    }
  }

  void applyCachedData(List<SongModel> songs) {
    for (final song in songs) {
      final audioCache = downloadedAudioBox.get(song.id);

      if (audioCache != null) {
        song.audioLocalPath = audioCache.localPath;
        song.isDownloaded = true;
      }

      final imageCache = imageCacheBox.get(song.id);

      if (imageCache != null) {
        song.imageLocalPath = imageCache.imagePath;
      }

      if (song.children.isNotEmpty) {
        applyCachedData(song.children);
      }
    }
  }

  void buildLookup(
    AudioServer server,
    List<SongModel> songs, [
    String? parentId,
  ]) {
    _audioUrlLookup[server] ??= {};

    for (final song in songs) {
      if (song.isAudio && song.url != null && parentId != null) {
        final key = '$parentId|${song.name}';
        _audioUrlLookup[server]![key] = song.url!;
      }

      if (song.children.isNotEmpty) {
        buildLookup(server, song.children, song.id);
      }
    }
  }

  SongRepoImpl({
    required this.sharedPreferences,
    required this.networkInfo,
    required this.client,
    required this.songsBox,
    required this.downloadedAudioBox,
    required this.imageCacheBox,
  });
  @override
  Future<String> changeTheme(String theme) {
    return Future.value(
      sharedPreferences.setString('theme', theme).then((value) => theme),
    );
  }

  @override
  Future<String> getCurrentTheme() {
    return Future.value(sharedPreferences.getString('theme') ?? 'dark');
  }

  int _sortByName(SongModel a, SongModel b) {
    // Extract leading numbers if any
    final regex = RegExp(r'^(\d+)-?');
    final aMatch = regex.firstMatch(a.name);
    final bMatch = regex.firstMatch(b.name);

    if (aMatch != null && bMatch != null) {
      // both have numbers, sort numerically first
      final aNum = int.parse(aMatch.group(1)!);
      final bNum = int.parse(bMatch.group(1)!);
      if (aNum != bNum) return aNum.compareTo(bNum);
    } else if (aMatch != null) {
      // a has number, b doesn't → a comes first
      return -1;
    } else if (bMatch != null) {
      // b has number, a doesn't → b comes first
      return 1;
    }

    // fallback to lexicographic sort (Amharic or text)
    return a.name.compareTo(b.name);
  }

  List<SongModel> _sortRecursive(List<SongModel> list) {
    for (var song in list) {
      if (song.children.isNotEmpty) {
        song.children = _sortRecursive(song.children);
      }
    }
    list.sort(_sortByName);
    return list;
  }

  List<SongModel> _sortRecursiveInMain(List<SongModel> list) {
    for (var song in list) {
      if (song.children.isNotEmpty) {
        song.children = _sortRecursiveInMain(song.children);
      }
    }

    list.sort(_sortByName);
    return list;
  }

  @override
  Future<List<SongModel>> loadSongs() async {
    try {
      final raw = _serverCache[AudioServer.server1];

      if (raw == null) {
        return Future.error("Failed to load songs from server");
      }

      // 🚀 move heavy parsing to background
      final songs = await compute(
        (list) => list.map((e) => SongModel.fromJson(e.toJson())).toList(),
        raw,
      );

      // still main isolate (safe)
      _sortRecursiveInMain(songs);
      applyCachedData(songs);

      final freshRoot = SongModel(
        id: 'root',
        name: 'Root',
        listHere: true,
        url: null,
        isAudio: false,
        children: songs,
      );

      if (!songsBox.containsKey('root')) {
        await songsBox.put('root', freshRoot);
        return songs;
      }

      final cachedRoot = songsBox.get('root')!;
      if (cachedRoot.children.length != songs.length) {
        await songsBox.put('root', freshRoot);
        return songs;
      }

      await songsBox.put('root', freshRoot);
      return songs;
    } catch (e) {
      return Future.error("Error loading songs: $e");
    }
  }

  @override
  Future<List<SongModel>> saveImageLocally(
    SongModel song,
    String imagePath,
  ) async {
    try {
      final root = songsBox.get('root');
      if (root == null) return Future.error("Root not found");

      await imageCacheBox.put(
        song.id,
        CachedImageData(songId: song.id, imagePath: imagePath),
      );
      song.imageLocalPath = imagePath;
      return Future.value(root.children);
    } catch (e) {
      return Future.error("Error saving image locally: $e");
    }
  }

  @override
  Stream<Either<Failure, DownloadAudioReport>> downloadAudio(
    SongModel child,
    SongModel parent,
  ) async* {
    if (!await networkInfo.isConnected) {
      yield Left(ServerFailure(message: "No internet connection!!!"));
      return;
    }

    String finalUrl = await getAudioUrlFromServer(
      serverManager.next(),
      parent.id,
      child.name,
    );
    bool downloaded = false;

    /// Helper: download a single URL with progress
    Stream<Either<Failure, DownloadAudioReport>> downloadStream(
      SongModel parent,
      SongModel child,
      String url, {
      bool emitErrors = true,
    }) async* {
      try {
        final request = http.Request('GET', Uri.parse(url));
        final response = await client.send(request);

        if (response.statusCode != 200) {
          if (emitErrors) {
            yield Left(ServerFailure(message: 'Failed to download file.'));
          }
          return; // silently fail if emitErrors == false
        }

        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/Audio/${parent.id.replaceAll("/", "_")}';
        await Directory(path).create(recursive: true);
        final file = File('$path/${decodeAndTrimUrl(url)}');

        int downloadedBytes = 0;
        final total = response.contentLength ?? 0;
        final sink = file.openWrite();

        await for (final chunk in response.stream) {
          downloadedBytes += chunk.length;
          sink.add(chunk);

          double progress = total > 0 ? downloadedBytes / total : 0;
          yield Right(
            DownloadAudioReport(songModel: parent, progress: progress * 100),
          );
        }

        await sink.close();

        // child.isDownloaded = true;
        // child.audioLocalPath = file.path;

        await downloadedAudioBox.put(
          child.id,
          CachedAudioData(songId: child.id, localPath: file.path),
        );
        child.isDownloaded = true;
        child.audioLocalPath = file.path;
        yield Right(DownloadAudioReport(progress: 100, songModel: parent));
      } catch (e) {
        if (emitErrors) {
          yield Left(ServerFailure(message: e.toString()));
        }
      }
    }

    // WHICH SERVER TURN
    await for (final event in downloadStream(
      parent,
      child,
      finalUrl,
      emitErrors: false,
    )) {
      yield event; // emit every progress update

      final progressValue = event
          .getOrElse(() => DownloadAudioReport(songModel: parent, progress: 0))
          .progress;
      if (progressValue == 100) {
        downloaded = true;
      }
    }

    // Both servers failed
    if (!downloaded) {
      yield Left(
        ServerFailure(
          message:
              "Monthly download limit reached. Support the project to help us increase capacity and bring servers back sooner.",
        ),
      );
    }
  }

  @override
  Future<bool> isConnected() async {
    return await networkInfo.isConnected;
  }

  @override
  Future<void> submitFeedback({
    required String feedback,
    required String fullname,
    File? imageFile,
  }) async {
    final token = dotenv.env['TELEGRAM_BOT_TOKEN'];
    final userId = dotenv.env['USER_ID'];

    if (token == null || userId == null) {
      throw Exception('Bot token or user ID not configured in .env');
    }

    final caption =
        '''
*New Feedback*

*Message:*  
$feedback

*Telegram:*  
@$fullname
  '''
            .trim();

    try {
      if (imageFile != null) {
        // Send with photo
        final uri = Uri.parse('https://api.telegram.org/bot$token/sendPhoto');
        final request = http.MultipartRequest('POST', uri);

        request.fields['chat_id'] = userId;
        request.fields['caption'] = caption;
        request.fields['parse_mode'] = 'Markdown';

        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: imageFile.path.split(Platform.pathSeparator).last,
        );

        request.files.add(multipartFile);

        final response = await request.send();

        if (response.statusCode != 200) {
          final errorBody = await response.stream.bytesToString();
          throw Exception(
            'Failed to send photo: ${response.statusCode} - $errorBody',
          );
        }
      } else {
        // Send text only
        final uri = Uri.parse('https://api.telegram.org/bot$token/sendMessage');
        final response = await http.post(
          uri,
          body: {'chat_id': userId, 'text': caption, 'parse_mode': 'Markdown'},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to send message: ${response.statusCode}');
        }
      }
    } catch (e) {
      // Re-throw with user-friendly message
      throw Exception('Failed to send feedback. Please try again.');
    }
  }

  Future<String> getAudioUrlFromServer(
    AudioServer server,
    String parentPath,
    String audioName,
  ) async {
    final key = '$parentPath|$audioName';

    final url = _audioUrlLookup[server]?[key];

    if (url == null) {
      throw Exception("Audio not found on $server");
    }

    return url;
  }

  SongModel? findAudioRecursively(List<SongModel> songs, String audioName) {
    for (final song in songs) {
      if (song.name == audioName && song.isAudio == true) {
        return song;
      }

      final deeper = findAudioRecursively(song.children, audioName);
      if (deeper != null) return deeper;
    }
    return null;
  }

  SongModel? findParentFolder(List<SongModel> songs, String parentPath) {
    for (final song in songs) {
      if (song.id == parentPath) return song;

      final deeper = findParentFolder(song.children, parentPath);
      if (deeper != null) return deeper;
    }
    return null;
  }
}

String decodeAndTrimUrl(String url) {
  final decoded = Uri.decodeFull(url);
  final filename = decoded.substring(decoded.lastIndexOf('/') + 1);
  final match = RegExp(r'^(.*)_[^_]+(\.\w+)$').firstMatch(filename);
  return match != null ? '${match.group(1)}${match.group(2)}' : filename;
}

List<dynamic> getServerContent(AudioServer server) {
  switch (server) {
    case AudioServer.server1:
      return server1Content;
    case AudioServer.server2:
      return server2Content;
    case AudioServer.server3:
      return server3Content;
    case AudioServer.server4:
      return server4Content;
  }
}
