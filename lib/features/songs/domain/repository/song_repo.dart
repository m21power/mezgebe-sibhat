import 'package:wereb/features/songs/data/local/song_model.dart';

abstract class SongRepository {
  Future<String> changeTheme(String theme);
  Future<String> getCurrentTheme();
  Future<List<SongModel>> loadSongs();
}
