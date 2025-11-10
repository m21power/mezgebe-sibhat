import 'package:hive/hive.dart';
import 'song_model.dart';

class SongModelAdapter extends TypeAdapter<SongModel> {
  @override
  final int typeId = 0;

  @override
  SongModel read(BinaryReader reader) {
    final name = reader.readString();
    final url = reader.readString();
    final isAudio = reader.readBool();
    final listHere = reader.readBool();
    final isDownloaded = reader.readBool();
    final localPath = reader.readString();
    final childrenCount = reader.readInt();
    final children = <SongModel>[];
    for (var i = 0; i < childrenCount; i++) {
      children.add(read(reader));
    }
    return SongModel(
      name: name,
      url: url.isEmpty ? null : url,
      isAudio: isAudio,
      listHere: listHere,
      isDownloaded: isDownloaded,
      localPath: localPath.isEmpty ? null : localPath,
      children: children,
    );
  }

  @override
  void write(BinaryWriter writer, SongModel obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.url ?? '');
    writer.writeBool(obj.isAudio);
    writer.writeBool(obj.listHere);
    writer.writeBool(obj.isDownloaded);
    writer.writeString(obj.localPath ?? '');
    writer.writeInt(obj.children.length);
    for (var child in obj.children) {
      write(writer, child);
    }
  }
}
