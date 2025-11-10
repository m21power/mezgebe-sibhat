class Songmodel {
  final String name;
  final String? url;
  final bool isAudio;
  final bool listHere;
  final List<Songmodel> children;
  bool isDownloaded;
  String? localPath;

  Songmodel({
    required this.name,
    this.url,
    this.isAudio = false,
    this.listHere = false,
    this.children = const [],
    this.isDownloaded = false,
    this.localPath,
  });

  factory Songmodel.fromJson(Map<String, dynamic> json) {
    return Songmodel(
      name: json['name'],
      url: json['url'],
      isAudio: json['isAudio'] ?? false,
      listHere: json['listHere'] ?? false,
      children: json['children'] != null
          ? List<Songmodel>.from(
              (json['children'] as List).map((e) => Songmodel.fromJson(e)),
            )
          : [],
      isDownloaded: json['isDownloaded'] ?? false,
      localPath: json['localPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'isAudio': isAudio,
      'listHere': listHere,
      'children': children.map((e) => e.toJson()).toList(),
      'isDownloaded': isDownloaded,
      'localPath': localPath,
    };
  }
}
