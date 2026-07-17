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
    List<XFile> imageFiles = const [],
  }) async {
    isSubmitting = true;
    notifyListeners();
    try {
      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        imageUrls = await _storageService.uploadImages(
          files: imageFiles,
          bucket: SupabaseConfig.commentImagesBucket,
        );
      }
      final comment = await _commentService.addComment(
        postId: postId,
        content: content,
        imageUrls: imageUrls,
      );
      comments.add(comment);
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// [keptImageUrls]: existing images the user did NOT remove.
  /// [newImageFiles]: freshly picked local files to upload.
  Future<void> updateComment({
    required CommentModel original,
    required String content,
    List<String> keptImageUrls = const [],
    List<XFile> newImageFiles = const [],
  }) async {
    isSubmitting = true;
    notifyListeners();
    try {
      final removedUrls =
          original.imageUrls.where((url) => !keptImageUrls.contains(url)).toList();
      if (removedUrls.isNotEmpty) {
        await _storageService.deleteImages(
          imageUrls: removedUrls,
          bucket: SupabaseConfig.commentImagesBucket,
        );
      }

      List<String> newUrls = [];
      if (newImageFiles.isNotEmpty) {
        newUrls = await _storageService.uploadImages(
          files: newImageFiles,
          bucket: SupabaseConfig.commentImagesBucket,
        );
      }

      final finalUrls = [...keptImageUrls, ...newUrls];

      final updated = await _commentService.updateComment(
        id: original.id,
        content: content,
        imageUrls: finalUrls,
      );
      final idx = comments.indexWhere((c) => c.id == updated.id);
      if (idx != -1) comments[idx] = updated;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteComment(CommentModel comment) async {
    if (comment.imageUrls.isNotEmpty) {
      await _storageService.deleteImages(
        imageUrls: comment.imageUrls,
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