import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wereb/core/error/failure.dart';
import 'package:wereb/core/network/network_info_impl.dart';
import 'package:wereb/features/songs/data/local/song_model.dart';
import 'package:wereb/features/songs/domain/entities/SongModel.dart';
import 'package:wereb/features/songs/domain/repository/song_repo.dart';
import 'package:http/http.dart' as http;

class SongRepoImpl implements SongRepository {
  final SharedPreferences sharedPreferences;
  final NetworkInfo networkInfo;
  final http.Client client;
  SongRepoImpl({
    required this.sharedPreferences,
    required this.networkInfo,
    required this.client,
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
    return Future.value(sharedPreferences.getString('theme') ?? 'light');
  }

  @override
  Future<List<SongModel>> loadSongs() {
    final jsonValue = [
      {
        "name": "Main Folder",
        "url": null,
        "isAudio": false,
        "listHere": true,
        "children": [
          {
            "name": "Sub Folder 1",
            "url": null,
            "isAudio": false,
            "listHere": false,
            "children": [
              {
                "name": "Song 1",
                "url": "https://example.com/song1.mp3",
                "isAudio": true,
                "listHere": false,
                "children": [],
                "isDownloaded": false,
                "localPath": null,
              },
              {
                "name": "Song 2",
                "url": "https://example.com/song2.mp3",
                "isAudio": true,
                "listHere": false,
                "children": [],
                "isDownloaded": false,
                "localPath":
                    "/data/user/0/com.example.wereb/cache/28eeaad8-2693-4083-a03f-7d88fada199d/1000000034.jpg",
              },
            ],
            "isDownloaded": false,
            "localPath": null,
          },
          {
            "name": "Sub Folder 2",
            "url": null,
            "isAudio": false,
            "listHere": false,
            "children": [
              {
                "name": "Song 3",
                "url": "https://example.com/song3.mp3",
                "isAudio": true,
                "listHere": false,
                "children": [],
                "isDownloaded": false,
                "localPath": null,
              },
            ],
            "isDownloaded": false,
            "localPath": null,
          },
        ],
        "isDownloaded": false,
        "localPath": null,
      },
      {
        "name": "Standalone Folder",
        "url": null,
        "isAudio": false,
        "listHere": false,
        "children": [
          {
            "name": "Song 4",
            "url": "https://example.com/song4.mp3",
            "isAudio": true,
            "listHere": false,
            "children": [],
            "isDownloaded": false,
            "localPath": null,
          },
        ],
        "isDownloaded": false,
        "localPath": null,
      },
    ];
    List<SongModel> songs = jsonValue
        .map<SongModel>((json) => SongModel.fromJson(json))
        .toList();
    return Future.value(songs);
  }

  @override
  Future<List<SongModel>> saveImageLocally(SongModel song, String imagePath) {
    final jsonValue = [
      {
        "name": "Main Folder",
        "url": null,
        "isAudio": false,
        "listHere": true,
        "children": [
          {
            "name": "Sub Folder 1",
            "url": null,
            "isAudio": false,
            "listHere": false,
            "children": [
              {
                "name": "Song 1",
                "url": "https://example.com/song1.mp3",
                "isAudio": true,
                "listHere": false,
                "children": [],
                "isDownloaded": false,
                "localPath": null,
              },
              {
                "name": "Song 2",
                "url": "https://example.com/song2.mp3",
                "isAudio": true,
                "listHere": false,
                "children": [],
                "isDownloaded": false,
                "localPath": imagePath,
              },
            ],
            "isDownloaded": false,
            "localPath": null,
          },
          {
            "name": "Sub Folder 2",
            "url": null,
            "isAudio": false,
            "listHere": false,
            "children": [
              {
                "name": "Song 3",
                "url": "https://example.com/song3.mp3",
                "isAudio": true,
                "listHere": false,
                "children": [],
                "isDownloaded": false,
                "localPath": null,
              },
            ],
            "isDownloaded": false,
            "localPath": null,
          },
        ],
        "isDownloaded": false,
        "localPath": null,
      },
      {
        "name": "Standalone Folder",
        "url": null,
        "isAudio": false,
        "listHere": false,
        "children": [
          {
            "name": "Song 4",
            "url": "https://example.com/song4.mp3",
            "isAudio": true,
            "listHere": false,
            "children": [],
            "isDownloaded": false,
            "localPath": null,
          },
        ],
        "isDownloaded": false,
        "localPath": null,
      },
    ];
    List<SongModel> songs = jsonValue
        .map<SongModel>((json) => SongModel.fromJson(json))
        .toList();
    return Future.value(songs);
  }

  @override
  Stream<Either<Failure, DownloadAudioReport>> downloadAudio(
    String url,
    SongModel song,
  ) async* {
    if (!await networkInfo.isConnected) {
      yield Left(ServerFailure(message: "No internet connection!!!"));
    }

    try {
      final request = http.Request(
        'GET',
        Uri.parse(
          "https://res.cloudinary.com/dl6vahv6t/video/upload/v1762667783/05-%E1%88%9B%E1%88%AD%E1%8B%AB%E1%88%9D_%E1%8B%B5%E1%8A%95%E1%8C%8D%E1%88%8D_c6awdr.mp3",
        ),
      );
      final response = await client.send(request);

      if (response.statusCode != 200) {
        yield Left(ServerFailure(message: 'Failed to download file.'));
      }

      // prepare file path
      // final dir = await getTemporaryDirectory();
      // final file = File('${dir.path}/${song.name}.mp3');

      int downloaded = 0;
      final total = response.contentLength ?? 0;

      // Open file for writing chunks
      // final sink = file.openWrite();

      // Listen to download progress
      await for (final chunk in response.stream) {
        downloaded += chunk.length;
        // sink.add(chunk);
        // calculate progress
        double progress = total > 0 ? downloaded / total : 0;
        print(
          "Downloading ${song.name}: ${(progress * 100).toStringAsFixed(0)}%",
        );
        yield Right(
          DownloadAudioReport(songModel: song, progress: progress * 100),
        );
      }

      // await sink.close();

      // // Return updated song model with new path
      // song.localPath = file.path;
      for (var son in song.children) {
        if (son.url == url) {
          son.isDownloaded = true;
        }
      }

      yield Right(DownloadAudioReport(progress: 100, songModel: song));
    } catch (e) {
      yield Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isConnected() async {
    return await networkInfo.isConnected;
  }
}
