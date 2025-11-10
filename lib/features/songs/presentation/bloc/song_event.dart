part of 'song_bloc.dart';

@immutable
sealed class SongEvent {}

final class ChangeThemeEvent extends SongEvent {
  final String theme;
  ChangeThemeEvent(this.theme);
}

final class GetCurrentThemeEvent extends SongEvent {}

final class LoadSongsEvent extends SongEvent {}

final class SaveImageLocallyEvent extends SongEvent {
  final SongModel song;
  final String imagePath;
  SaveImageLocallyEvent(this.song, this.imagePath);
}

final class DownloadAudioEvent extends SongEvent {
  final SongModel song;
  final String url;
  DownloadAudioEvent(this.song, this.url);
}

final class CheckConnection extends SongEvent {}

final class ConnectionChangedEvent extends SongEvent {
  final bool isConnected;
  ConnectionChangedEvent({required this.isConnected});
}
