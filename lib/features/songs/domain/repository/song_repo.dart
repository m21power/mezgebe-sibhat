import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:mezgebe_sibhat/core/error/failure.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/song_model.dart';
import 'package:mezgebe_sibhat/features/songs/domain/entities/SongModel.dart';

abstract class SongRepository {
  Future<String> changeTheme(String theme);
  Future<String> getCurrentTheme();
  Future<List<SongModel>> loadSongs();
  Future<List<SongModel>> saveImageLocally(SongModel song, String imagePath);
  Stream<Either<Failure, DownloadAudioReport>> downloadAudio(
    SongModel child,
    SongModel parent,
  );
  Future<bool> isConnected();
  Future<void> submitFeedback({
    required String feedback,
    required String fullname,
    File? imageFile,
  });
}

const String dbPartA = '57c3d33c931771a999b';
