// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_song_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedAudioDataAdapter extends TypeAdapter<CachedAudioData> {
  @override
  final int typeId = 1;

  @override
  CachedAudioData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedAudioData(
      songId: fields[0] as String,
      localPath: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedAudioData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.songId)
      ..writeByte(1)
      ..write(obj.localPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedAudioDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedImageDataAdapter extends TypeAdapter<CachedImageData> {
  @override
  final int typeId = 2;

  @override
  CachedImageData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedImageData(
      songId: fields[0] as String,
      imagePath: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedImageData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.songId)
      ..writeByte(1)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedImageDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
