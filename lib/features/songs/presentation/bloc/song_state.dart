part of 'song_bloc.dart';

@immutable
sealed class SongState {
  final bool isLightTheme;
  final List<SongModel> songs;
  const SongState({required this.isLightTheme, required this.songs});
}

final class ThemeChangedState extends SongState {
  ThemeChangedState({
    required bool isLightTheme,
    required List<SongModel> songs,
  }) : super(isLightTheme: isLightTheme, songs: songs);
}

final class SongsLoadedState extends SongState {
  final List<SongModel> songs;

  const SongsLoadedState({required this.songs, required bool isLightTheme})
    : super(isLightTheme: isLightTheme, songs: songs);
}
