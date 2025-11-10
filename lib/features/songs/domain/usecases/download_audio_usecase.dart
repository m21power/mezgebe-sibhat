import 'package:dartz/dartz.dart';
import 'package:wereb/core/error/failure.dart';
import 'package:wereb/features/songs/data/local/song_model.dart';
import 'package:wereb/features/songs/domain/entities/SongModel.dart';
import 'package:wereb/features/songs/domain/repository/song_repo.dart';

class DownloadAudioUseCase {
  final SongRepository songRepository;
  DownloadAudioUseCase(this.songRepository);
  Stream<Either<Failure, DownloadAudioReport>> call(
    String url,
    SongModel song,
  ) {
    return songRepository.downloadAudio(url, song);
  }
}
