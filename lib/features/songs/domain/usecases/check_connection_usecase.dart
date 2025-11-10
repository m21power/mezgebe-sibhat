import 'package:wereb/features/songs/domain/repository/song_repo.dart';

class CheckConnectionUsecase {
  final SongRepository songRepository;
  CheckConnectionUsecase(this.songRepository);
  Future<bool> call() {
    return songRepository.isConnected();
  }
}
