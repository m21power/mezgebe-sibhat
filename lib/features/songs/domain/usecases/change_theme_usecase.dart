import 'package:wereb/features/songs/domain/repository/song_repo.dart';

class ChangeThemeUsecase {
  final SongRepository repository;

  ChangeThemeUsecase(this.repository);

  Future<String> call(String theme) async {
    return await repository.changeTheme(theme);
  }
}
