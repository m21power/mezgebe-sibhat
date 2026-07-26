import 'package:get_it/get_it.dart' as get_it;
import 'package:mezgebe_sibhat/features/songs/data/local/cached_song_data.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/submit_feedback_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mezgebe_sibhat/core/network/network_info_impl.dart';
import 'package:mezgebe_sibhat/features/songs/data/repository/song_repo_impl.dart';
import 'package:mezgebe_sibhat/features/songs/domain/repository/song_repo.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/change_theme_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/check_connection_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/download_audio_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/get_current_theme_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/load_songs_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/save_image_locally_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/songs/data/local/song_model.dart';
import 'features/songs/data/local/song_model_adapter.dart';

final sl = get_it.GetIt.instance;
Future<void> init() async {
  var sharedPreferencesInstance = await SharedPreferences.getInstance();
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferencesInstance);
  sl.registerLazySingleton<http.Client>(() => http.Client());
  await Hive.initFlutter();
  Hive.registerAdapter(CachedAudioDataAdapter());
  Hive.registerAdapter(CachedImageDataAdapter());
  Hive.registerAdapter(SongModelAdapter());
  final box = await Hive.openBox<SongModel>('songsBox');
  sl.registerLazySingleton<Box<SongModel>>(() => box);
  final downloadedAudioBox = await Hive.openBox<CachedAudioData>(
    'downloaded_audio',
  );

  final imageCacheBox = await Hive.openBox<CachedImageData>('image_cache');
  sl.registerLazySingleton<Box<CachedAudioData>>(() => downloadedAudioBox);
  sl.registerLazySingleton<Box<CachedImageData>>(() => imageCacheBox);
  // Features - Songs
  // Bloc
  sl.registerFactory(
    () => SongBloc(
      getCurrentThemeUsecase: sl(),
      changeThemeUsecase: sl(),
      loadSongsUsecase: sl(),
      saveImageLocallyUsecase: sl(),
      downloadAudioUseCase: sl(),
      checkConnectionUsecase: sl(),
      submitFeedbackUsecase: sl(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => GetCurrentThemeUsecase(sl()));
  sl.registerLazySingleton(() => ChangeThemeUsecase(sl()));
  sl.registerLazySingleton(() => LoadSongsUsecase(sl()));
  sl.registerLazySingleton(() => SaveImageLocallyUsecase(sl()));
  sl.registerLazySingleton(() => DownloadAudioUseCase(sl()));
  sl.registerLazySingleton(() => CheckConnectionUsecase(sl()));
  sl.registerLazySingleton(() => SubmitFeedbackUsecase(sl()));
  //repository
  sl.registerLazySingleton<SongRepository>(
    () => SongRepoImpl(
      sharedPreferences: sl(),
      networkInfo: sl(),
      client: sl(),
      songsBox: sl(),
      downloadedAudioBox: sl(),
      imageCacheBox: sl(),
    ),
  );
}
