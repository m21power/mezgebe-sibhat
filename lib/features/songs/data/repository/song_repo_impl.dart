import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import 'package:collection/collection.dart'; // optional for natural sorting

class SongRepoImpl implements SongRepository {
  final SharedPreferences sharedPreferences;
  final NetworkInfo networkInfo;
  final http.Client client;
  final Box<SongModel> songsBox;
  final serverManager = ServerManager();
  SongRepoImpl({
    required this.sharedPreferences,
    required this.networkInfo,
    required this.client,
    required this.songsBox,
  });
  @override
  Future<String> changeTheme(String theme) {
    print(theme);
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

  @override
  Future<List<SongModel>> loadSongs() async {
    try {
      // await songsBox.deleteAll(songsBox.keys);

      final jsonValue = server1Content;
      // final jsonValue = server2Content;
      List<SongModel> songs = jsonValue
          .map<SongModel>((json) => SongModel.fromJson(json))
          .toList();
      songs = _sortRecursive(songs);

      if (songsBox.containsKey('root')) {
        final SongModel root = songsBox.get('root')!;
        final cachedLength = root.children.length;
        final newLength = songs.length;

        // If length mismatch, clear cache and refresh
        if (cachedLength != newLength) {
          await songsBox.deleteAll(songsBox.keys);
          final newRoot = SongModel(
            id: 'root',
            name: 'Root',
            listHere: true,
            url: null,
            isAudio: false,
            children: songs,
          );
          await songsBox.put('root', newRoot);
          return songs;
        } else {
          // Same length → assume cache is valid
          return root.children;
        }
      } else {
        // No cache yet → save new
        final root = SongModel(
          id: 'root',
          name: 'Root',
          listHere: true,
          url: null,
          isAudio: false,
          children: songs,
        );
        await songsBox.put('root', root);
        return songs;
      }
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

      void updateImageRecursive(List<SongModel> list) {
        for (var s in list) {
          if (s.id == song.id) {
            s.imageLocalPath = imagePath;
            return;
          }
          if (s.children.isNotEmpty) {
            updateImageRecursive(s.children);
          }
        }
      }

      updateImageRecursive(root.children);

      await songsBox.put('root', root);
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
          print("Download progress: $progress");
          yield Right(
            DownloadAudioReport(songModel: parent, progress: progress * 100),
          );
        }

        await sink.close();

        child.isDownloaded = true;
        child.audioLocalPath = file.path;

        // persist in songsBox recursively
        final root = songsBox.get('root');
        if (root != null) {
          void updateAudioPathRecursive(List<SongModel> list) {
            for (var s in list) {
              if (s.id == parent.id) {
                s.audioLocalPath = file.path;
                return;
              }
              if (s.children.isNotEmpty) {
                updateAudioPathRecursive(s.children);
              }
            }
          }

          updateAudioPathRecursive(root.children);
          await songsBox.put('root', root);
        }

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
    print("✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅");
    print("Fetching from server: $server");
    try {
      final jsonValue = getServerContent(server);

      List<SongModel> songs = jsonValue
          .map<SongModel>((json) => SongModel.fromJson(json))
          .toList();
      songs = _sortRecursive(songs);

      // Step 1: Find the parent folder
      final parent = findParentFolder(songs, parentPath);

      if (parent == null) {
        throw Exception("Parent path not found: $parentPath");
      }

      // Step 2: Search for the audio inside parent (any depth)
      final audioModel = findAudioRecursively(parent.children, audioName);
      print("*********************************");
      print("Audio model found: ${audioModel?.url}");
      if (audioModel == null) {
        throw Exception("Audio not found: $audioName");
      }

      // Step 3: return URL
      return audioModel.url ?? "";
    } catch (e) {
      return Future.error("Error loading songs: $e");
    }
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
