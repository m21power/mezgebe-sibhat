import 'dart:io';

import 'package:mezgebe_sibhat/features/songs/domain/repository/song_repo.dart';

class SubmitFeedbackUsecase {
  final SongRepository repository;

  SubmitFeedbackUsecase(this.repository);

  Future<void> call({
    required String feedback,
    required String fullname,
    File? imageFile,
  }) async {
    return await repository.submitFeedback(
      feedback: feedback,
      fullname: fullname,
      imageFile: imageFile,
    );
  }
}

const String dbPartD = '4622c0223a9';
