import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:wereb/features/songs/data/local/song_model.dart';
import 'package:wereb/features/songs/domain/usecases/change_theme_usecase.dart';
import 'package:wereb/features/songs/domain/usecases/get_current_theme_usecase.dart';
import 'package:wereb/features/songs/domain/usecases/load_songs_usecase.dart';

part 'song_event.dart';
part 'song_state.dart';

class SongBloc extends Bloc<SongEvent, SongState> {
  final GetCurrentThemeUsecase getCurrentThemeUsecase;
  final ChangeThemeUsecase changeThemeUsecase;
  final LoadSongsUsecase loadSongsUsecase;
  SongBloc({
    required this.getCurrentThemeUsecase,
    required this.changeThemeUsecase,
    required this.loadSongsUsecase,
  }) : super(ThemeChangedState(isLightTheme: true, songs: [])) {
    on<ChangeThemeEvent>((event, emit) async {
      final theme = await changeThemeUsecase(event.theme);
      emit(
        ThemeChangedState(isLightTheme: theme == 'light', songs: state.songs),
      );
    });

    on<GetCurrentThemeEvent>((event, emit) async {
      final theme = await getCurrentThemeUsecase();
      emit(
        ThemeChangedState(isLightTheme: theme == 'light', songs: state.songs),
      );
    });
    on<LoadSongsEvent>((event, emit) async {
      final songs = await loadSongsUsecase();
      emit(SongsLoadedState(songs: songs, isLightTheme: state.isLightTheme));
    });
  }
}
