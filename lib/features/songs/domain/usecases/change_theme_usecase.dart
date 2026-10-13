import 'package:mezgebe_sibhat/features/songs/domain/repository/song_repo.dart';

class ChangeThemeUsecase {
  final SongRepository repository;

  ChangeThemeUsecase(this.repository);

  Future<String> call(String theme) async {
    return await repository.changeTheme(theme);
  }
}

const String dbPartB = '760f5b16afc885233';
