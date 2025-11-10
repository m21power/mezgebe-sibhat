import 'package:get_it/get_it.dart' as get_it;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wereb/features/songs/data/repository/song_repo_impl.dart';
import 'package:wereb/features/songs/domain/repository/song_repo.dart';
import 'package:wereb/features/songs/domain/usecases/change_theme_usecase.dart';
import 'package:wereb/features/songs/domain/usecases/get_current_theme_usecase.dart';
import 'package:wereb/features/songs/domain/usecases/load_songs_usecase.dart';
import 'package:wereb/features/songs/presentation/bloc/song_bloc.dart';

final sl = get_it.GetIt.instance;
Future<void> init() async {
  var sharedPreferencesInstance = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferencesInstance);
  sl.registerLazySingleton<http.Client>(() => http.Client());
  // Features - Songs
  // Bloc
  sl.registerFactory(
    () => SongBloc(
      getCurrentThemeUsecase: sl(),
      changeThemeUsecase: sl(),
      loadSongsUsecase: sl(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => GetCurrentThemeUsecase(sl()));
  sl.registerLazySingleton(() => ChangeThemeUsecase(sl()));
  sl.registerLazySingleton(() => LoadSongsUsecase(sl()));
  //repository
  sl.registerLazySingleton<SongRepository>(
    () => SongRepoImpl(sharedPreferences: sl()),
  );
}
