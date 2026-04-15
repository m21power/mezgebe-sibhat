import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:meta/meta.dart';
import 'package:mezgebe_sibhat/core/error/failure.dart';
import 'package:mezgebe_sibhat/core/network/network_info_impl.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/song_model.dart';
import 'package:mezgebe_sibhat/features/songs/domain/entities/SongModel.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/change_theme_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/check_connection_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/download_audio_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/get_current_theme_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/load_songs_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/save_image_locally_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/submit_feedback_usecase.dart';

part 'song_event.dart';
part 'song_state.dart';

class SongBloc extends Bloc<SongEvent, SongState> {
  final GetCurrentThemeUsecase getCurrentThemeUsecase;
  final ChangeThemeUsecase changeThemeUsecase;
  final LoadSongsUsecase loadSongsUsecase;
  final SaveImageLocallyUsecase saveImageLocallyUsecase;
  final DownloadAudioUseCase downloadAudioUseCase;
  final CheckConnectionUsecase checkConnectionUsecase;
  final SubmitFeedbackUsecase submitFeedbackUsecase;
  final networkInfo = NetworkInfoImpl();
  SongBloc({
    required this.getCurrentThemeUsecase,
    required this.changeThemeUsecase,
    required this.loadSongsUsecase,
    required this.saveImageLocallyUsecase,
    required this.downloadAudioUseCase,
    required this.checkConnectionUsecase,
    required this.submitFeedbackUsecase,
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
    on<SubmitFeedbackEvent>((event, emit) async {
      emit(
        SubmitFeedbackLoadingState(
          isLightTheme: state.isLightTheme,
          songs: state.songs,
          connectionEnabled: state.connectionEnabled,
        ),
      );
      try {
        await submitFeedbackUsecase(
          feedback: event.feedback,
          fullname: event.fullname,
          imageFile: event.imageFile,
        );
        emit(
          FeedbackSubmittedState(
            isLightTheme: state.isLightTheme,
            songs: state.songs,
            connectionEnabled: state.connectionEnabled,
          ),
        );
      } catch (e) {
        emit(
          FeedbackSubmissionFailedState(
            isLightTheme: state.isLightTheme,
            songs: state.songs,
            message: e.toString(),
            connectionEnabled: state.connectionEnabled,
          ),
        );
      }
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
      emit(
        AudioDownloadRequestedState(
          isLightTheme: state.isLightTheme,
          songs: state.songs,
          connectionEnabled: state.connectionEnabled,
        ),
      );
      // listen to the stream from the use case
      await emit.forEach<Either<Failure, DownloadAudioReport>>(
        downloadAudioUseCase(event.child, event.parent),
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
                print("Downloading... ${audioReport.progress}%");
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
