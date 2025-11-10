import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:meta/meta.dart';
import 'package:wereb/core/error/failure.dart';
import 'package:wereb/core/network/network_info_impl.dart';
import 'package:wereb/features/songs/data/local/song_model.dart';
import 'package:wereb/features/songs/domain/entities/SongModel.dart';
import 'package:wereb/features/songs/domain/usecases/change_theme_usecase.dart';
import 'package:wereb/features/songs/domain/usecases/check_connection_usecase.dart';
import 'package:wereb/features/songs/domain/usecases/download_audio_usecase.dart';
import 'package:wereb/features/songs/domain/usecases/get_current_theme_usecase.dart';
import 'package:wereb/features/songs/domain/usecases/load_songs_usecase.dart';
import 'package:wereb/features/songs/domain/usecases/save_image_locally_usecase.dart';

part 'song_event.dart';
part 'song_state.dart';

class SongBloc extends Bloc<SongEvent, SongState> {
  final GetCurrentThemeUsecase getCurrentThemeUsecase;
  final ChangeThemeUsecase changeThemeUsecase;
  final LoadSongsUsecase loadSongsUsecase;
  final SaveImageLocallyUsecase saveImageLocallyUsecase;
  final DownloadAudioUseCase downloadAudioUseCase;
  final CheckConnectionUsecase checkConnectionUsecase;
  final networkInfo = NetworkInfoImpl();
  SongBloc({
    required this.getCurrentThemeUsecase,
    required this.changeThemeUsecase,
    required this.loadSongsUsecase,
    required this.saveImageLocallyUsecase,
    required this.downloadAudioUseCase,
    required this.checkConnectionUsecase,
  }) : super(
         ThemeChangedState(
           isLightTheme: true,
           songs: [],
           connectionEnabled: false,
         ),
       ) {
    // --- LISTEN TO CONNECTION CHANGES ---
    networkInfo.onStatusChange.listen((isConnected) {
      add(
        ConnectionChangedEvent(isConnected: isConnected),
      ); // create this event
    });

    on<ConnectionChangedEvent>((event, emit) {
      // just update the current state with new connection info
      emit(state.copyWith(connectionEnabled: event.isConnected));
    });
    on<ChangeThemeEvent>((event, emit) async {
      final theme = await changeThemeUsecase(event.theme);
      emit(
        ThemeChangedState(
          isLightTheme: theme == 'light',
          songs: state.songs,
          connectionEnabled: state.connectionEnabled,
        ),
      );
    });
    on<CheckConnection>((event, emit) async {
      var value = await checkConnectionUsecase();
      emit(
        SongsLoadedState(
          isLightTheme: state.isLightTheme,
          songs: state.songs,
          connectionEnabled: value,
        ),
      );
    });
    on<GetCurrentThemeEvent>((event, emit) async {
      final theme = await getCurrentThemeUsecase();
      emit(
        ThemeChangedState(
          isLightTheme: theme == 'light',
          songs: state.songs,
          connectionEnabled: state.connectionEnabled,
        ),
      );
    });
    on<LoadSongsEvent>((event, emit) async {
      final songs = await loadSongsUsecase();
      emit(
        SongsLoadedState(
          songs: songs,
          isLightTheme: state.isLightTheme,
          connectionEnabled: state.connectionEnabled,
        ),
      );
    });
    on<SaveImageLocallyEvent>((event, emit) async {
      print("am i here");
      final songs = await saveImageLocallyUsecase(event.song, event.imagePath);
      print('Saved image locally for song: ${event.song.name}');
      print(event.imagePath);
      // add(LoadSongsEvent());
      emit(
        SongsLoadedState(
          isLightTheme: state.isLightTheme,
          songs: songs,
          connectionEnabled: state.connectionEnabled,
        ),
      );
    });
    on<DownloadAudioEvent>((event, emit) async {
      // listen to the stream from the use case
      await emit.forEach<Either<Failure, DownloadAudioReport>>(
        downloadAudioUseCase(event.url, event.song),
        onData: (result) {
          return result.fold(
            (failure) => AudioDownloadFailed(
              isLightTheme: state.isLightTheme,
              songs: state.songs,
              message: failure.message,
              connectionEnabled: state.connectionEnabled,
            ),
            (audioReport) {
              if (audioReport.progress < 100) {
                // still downloading
                return AudioDownloadingFetchingState(
                  isLightTheme: state.isLightTheme,
                  songs: state.songs,
                  progress: audioReport.progress,
                  connectionEnabled: state.connectionEnabled,
                );
              } else {
                // finished
                return AudioDownloadSuccessfully(
                  isLightTheme: state.isLightTheme,
                  songs: state.songs,
                  songModel: audioReport.songModel,
                  connectionEnabled: state.connectionEnabled,
                );
              }
            },
          );
        },
      );
    });
  }
}
