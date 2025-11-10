import 'package:hive/hive.dart';

// part 'song_model.g.dart'; // Needed if you want to use codegen

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? url; // only for audio

  @HiveField(2)
  bool isAudio;

  @HiveField(3)
  bool listHere; // whether to list children in same page

  @HiveField(4)
  bool isDownloaded; // offline caching

  @HiveField(5)
  String? localPath; // path after downloading audio

  @HiveField(6)
  List<SongModel> children;

  SongModel({
    required this.name,
    this.url,
    this.isAudio = false,
    this.listHere = false,
    this.children = const [],
    this.isDownloaded = false,
    this.localPath,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      name: json['name'],
      url: json['url'],
      isAudio: json['isAudio'] ?? false,
      listHere: json['listHere'] ?? false,
      isDownloaded: json['isDownloaded'] ?? false,
      localPath: json['localPath'],
      children: json['children'] != null
          ? List<SongModel>.from(
              (json['children'] as List).map((e) => SongModel.fromJson(e)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'isAudio': isAudio,
      'listHere': listHere,
      'isDownloaded': isDownloaded,
      'localPath': localPath,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}
