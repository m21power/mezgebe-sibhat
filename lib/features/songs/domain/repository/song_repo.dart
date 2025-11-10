import 'package:dartz/dartz.dart';
import 'package:wereb/core/error/failure.dart';
import 'package:wereb/features/songs/data/local/song_model.dart';
import 'package:wereb/features/songs/domain/entities/SongModel.dart';

abstract class SongRepository {
  Future<String> changeTheme(String theme);
  Future<String> getCurrentTheme();
  Future<List<SongModel>> loadSongs();
  Future<List<SongModel>> saveImageLocally(SongModel song, String imagePath);
  Stream<Either<Failure, DownloadAudioReport>> downloadAudio(
    String url,
    SongModel song,
  );
  Future<bool> isConnected();
}
