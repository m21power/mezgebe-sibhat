import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? url; // kept for backward-compat with old cached entries; no longer written

  @HiveField(3)
  bool isAudio;

  @HiveField(4)
  bool listHere;

  @HiveField(6) // new field — must be a fresh index, not reused
  Map<String, String> urls; // e.g. {"server1": "...", "server2": "...", ...}

  bool isDownloaded = false;
  String? audioLocalPath;
  String? imageLocalPath;

  @HiveField(5)
  List<SongModel> children;

  SongModel({
    required this.id,
    required this.name,
    this.url,
    this.urls = const {},
    this.isAudio = false,
    this.listHere = false,
    this.children = const [],
  });

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
      urls:
          (json['urls'] as Map?)?.map(
            (k, v) => MapEntry(k as String, v as String),
          ) ??
          {},
      isAudio: json['isAudio'] ?? false,
      listHere: json['listHere'] ?? false,
      children: children,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'urls': urls,
      'isAudio': isAudio,
      'listHere': listHere,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}
