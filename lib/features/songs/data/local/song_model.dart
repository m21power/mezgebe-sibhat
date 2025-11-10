import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0)
  final String id; // <-- new unique path id

  @HiveField(1)
  String name;

  @HiveField(2)
  String? url;

  @HiveField(3)
  bool isAudio;

  @HiveField(4)
  bool listHere;

  @HiveField(5)
  bool isDownloaded;

  @HiveField(6)
  String? localPath;

  @HiveField(7)
  List<SongModel> children;

  SongModel({
    required this.id,
    required this.name,
    this.url,
    this.isAudio = false,
    this.listHere = false,
    this.children = const [],
    this.isDownloaded = false,
    this.localPath,
  });

  /// Recursively build SongModel from JSON and generate id paths
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
      id: currentPath,
      name: json['name'],
      url: json['url'],
      isAudio: json['isAudio'] ?? false,
      listHere: json['listHere'] ?? false,
      isDownloaded: json['isDownloaded'] ?? false,
      localPath: json['localPath'],
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
      'isDownloaded': isDownloaded,
      'localPath': localPath,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}
