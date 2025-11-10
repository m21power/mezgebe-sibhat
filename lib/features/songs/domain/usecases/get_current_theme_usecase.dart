import 'package:wereb/features/songs/domain/repository/song_repo.dart';

class GetCurrentThemeUsecase {
  final SongRepository repository;

  GetCurrentThemeUsecase(this.repository);

  Future<String> call() async {
    return await repository.getCurrentTheme();
  }
}
