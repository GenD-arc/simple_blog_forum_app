import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/supabase_config.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';
import '../services/storage_service.dart';

class CommentProvider extends ChangeNotifier {
  final CommentService _commentService = CommentService();
  final StorageService _storageService = StorageService();

  final List<CommentModel> comments = [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> loadComments(String postId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _commentService.fetchComments(postId);
      comments
        ..clear()
        ..addAll(result);
    } catch (e) {
      errorMessage = 'Could not load comments.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addComment({
    required String postId,
    required String content,
    XFile? imageFile,
  }) async {
    isSubmitting = true;
    notifyListeners();
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadImage(
          file: imageFile,
          bucket: SupabaseConfig.commentImagesBucket,
        );
      }
      final comment = await _commentService.addComment(
        postId: postId,
        content: content,
        imageUrl: imageUrl,
      );
      comments.add(comment);
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> updateComment({
    required CommentModel original,
    required String content,
    XFile? newImageFile,
    bool removeImage = false,
  }) async {
    isSubmitting = true;
    notifyListeners();
    try {
      String? imageUrl = original.imageUrl;

      if (newImageFile != null) {
        if (original.imageUrl != null) {
          await _storageService.deleteImage(
            imageUrl: original.imageUrl!,
            bucket: SupabaseConfig.commentImagesBucket,
          );
        }
        imageUrl = await _storageService.uploadImage(
          file: newImageFile,
          bucket: SupabaseConfig.commentImagesBucket,
        );
      } else if (removeImage && original.imageUrl != null) {
        await _storageService.deleteImage(
          imageUrl: original.imageUrl!,
          bucket: SupabaseConfig.commentImagesBucket,
        );
        imageUrl = null;
      }

      final updated = await _commentService.updateComment(
        id: original.id,
        content: content,
        imageUrl: imageUrl,
      );
      final idx = comments.indexWhere((c) => c.id == updated.id);
      if (idx != -1) comments[idx] = updated;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteComment(CommentModel comment) async {
    if (comment.imageUrl != null) {
      await _storageService.deleteImage(
        imageUrl: comment.imageUrl!,
        bucket: SupabaseConfig.commentImagesBucket,
      );
    }
    await _commentService.deleteComment(comment.id);
    comments.removeWhere((c) => c.id == comment.id);
    notifyListeners();
  }

  void clear() {
    comments.clear();
    errorMessage = null;
  }
}
