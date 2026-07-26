import 'package:hive/hive.dart';

part 'cached_song_data.g.dart';

@HiveType(typeId: 1)
class CachedAudioData extends HiveObject {
  @HiveField(0)
  final String songId;

  @HiveField(1)
  final String localPath;

  CachedAudioData({required this.songId, required this.localPath});
}

@HiveType(typeId: 2)
class CachedImageData extends HiveObject {
  @HiveField(0)
  final String songId;

  @HiveField(1)
  final String imagePath;

  CachedImageData({required this.songId, required this.imagePath});
}
