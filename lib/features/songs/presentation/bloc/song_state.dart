part of 'song_bloc.dart';

@immutable
sealed class SongState {
  final bool isLightTheme;
  final List<SongModel> songs;
  final bool connectionEnabled;
  const SongState({
    required this.isLightTheme,
    required this.songs,
    required this.connectionEnabled,
  });
  SongState copyWith({
    bool? isLightTheme,
    List<SongModel>? songs,
    bool? connectionEnabled,
  }) {
    return ThemeChangedState(
      isLightTheme: isLightTheme ?? this.isLightTheme,
      songs: songs ?? this.songs,
      connectionEnabled: connectionEnabled ?? this.connectionEnabled,
    );
  }
}

final class ThemeChangedState extends SongState {
  ThemeChangedState({
    required bool isLightTheme,
    required List<SongModel> songs,
    required bool connectionEnabled,
  }) : super(
         isLightTheme: isLightTheme,
         songs: songs,
         connectionEnabled: connectionEnabled,
       );
}

final class SongsLoadedState extends SongState {
  final List<SongModel> songs;

  const SongsLoadedState({
    required this.songs,
    required bool isLightTheme,
    required bool connectionEnabled,
  }) : super(
         isLightTheme: isLightTheme,
         songs: songs,
         connectionEnabled: connectionEnabled,
       );
}

final class ImageSavedState extends SongState {
  ImageSavedState({
    required bool isLightTheme,
    required List<SongModel> songs,
    required bool connectionEnabled,
  }) : super(
         isLightTheme: isLightTheme,
         songs: songs,
         connectionEnabled: connectionEnabled,
       );
}

final class AudioDownloadSuccessfully extends SongState {
  final SongModel songModel;
  AudioDownloadSuccessfully({
    required bool isLightTheme,
    required List<SongModel> songs,
    required this.songModel,
    required bool connectionEnabled,
  }) : super(
         isLightTheme: isLightTheme,
         songs: songs,
         connectionEnabled: connectionEnabled,
       );
}

final class AudioDownloadFailed extends SongState {
  final String message;
  AudioDownloadFailed({
    required bool isLightTheme,
    required List<SongModel> songs,
    required this.message,
    required bool connectionEnabled,
  }) : super(
         isLightTheme: isLightTheme,
         songs: songs,
         connectionEnabled: connectionEnabled,
       );
}

final class AudioDownloadingFetchingState extends SongState {
  final double progress;
  AudioDownloadingFetchingState({
    required bool isLightTheme,
    required List<SongModel> songs,
    required this.progress,
    required bool connectionEnabled,
  }) : super(
         isLightTheme: isLightTheme,
         songs: songs,
         connectionEnabled: connectionEnabled,
       );
}
