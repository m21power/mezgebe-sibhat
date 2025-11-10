part of 'song_bloc.dart';

@immutable
sealed class SongEvent {}

final class ChangeThemeEvent extends SongEvent {
  final String theme;
  ChangeThemeEvent(this.theme);
}

final class GetCurrentThemeEvent extends SongEvent {}

final class LoadSongsEvent extends SongEvent {}
