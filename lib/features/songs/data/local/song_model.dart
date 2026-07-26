import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? url; // remote audio URL

  @HiveField(3)
  bool isAudio;

  @HiveField(4)
  bool listHere;

  // runtime only
  bool isDownloaded = false;

  String? audioLocalPath;

  String? imageLocalPath;

  @HiveField(5)
  List<SongModel> children;

  SongModel({
    required this.id,
    required this.name,
    this.url,
    this.isAudio = false,
    this.listHere = false,
    // this.isDownloaded = false,
    // this.audioLocalPath,
    // this.imageLocalPath,
    this.children = const [],
  });

  /// Recursively build SongModel from JSON
  factory SongModel.fromJson(
    Map<String, dynamic> json, [
    String parentPath = '',
  ]) {
    final currentPath = parentPath.isEmpty
        ? json['name']
        : '$parentPath/${json['name']}';

    final children =
        (json['children'] as List?)
            ?.map((child) => SongModel.fromJson(child, currentPath))
            .toList() ??
        [];

    return SongModel(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      isAudio: json['isAudio'] ?? false,
      listHere: json['listHere'] ?? false,
      // isDownloaded: json['isDownloaded'] ?? false,
      // audioLocalPath: json['audioLocalPath'],
      // imageLocalPath: json['imageLocalPath'],
      children: children,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'isAudio': isAudio,
      'listHere': listHere,
      // 'isDownloaded': isDownloaded,
      // 'audioLocalPath': audioLocalPath,
      // 'imageLocalPath': imageLocalPath,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}
