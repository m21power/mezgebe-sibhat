import 'package:shared_preferences/shared_preferences.dart';
import 'package:wereb/features/songs/data/local/song_model.dart';
import 'package:wereb/features/songs/domain/repository/song_repo.dart';

class SongRepoImpl implements SongRepository {
  final SharedPreferences sharedPreferences;
  SongRepoImpl({required this.sharedPreferences});
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
            "listHere": true,
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
                "localPath": null,
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
}
