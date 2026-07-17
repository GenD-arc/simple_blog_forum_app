import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/supabase_config.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();

  final List<PostModel> posts = [];
  int _page = 0;
  bool hasMore = true;
  bool isLoadingInitial = false;
  bool isLoadingMore = false;
  String? errorMessage;

  Future<void> loadInitial() async {
    isLoadingInitial = true;
    errorMessage = null;
    _page = 0;
    hasMore = true;
    notifyListeners();
    try {
      final result = await _postService.fetchPosts(page: _page);
      posts
        ..clear()
        ..addAll(result);
      hasMore = result.length == PostService.pageSize;
    } catch (e) {
      errorMessage = 'Could not load posts. Pull to refresh to try again.';
    } finally {
      isLoadingInitial = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      _page += 1;
      final result = await _postService.fetchPosts(page: _page);
      posts.addAll(result);
      hasMore = result.length == PostService.pageSize;
    } catch (e) {
      _page -= 1;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<PostModel> createPost({
    required String title,
    required String content,
    List<XFile> imageFiles = const [],
  }) async {
    List<String> imageUrls = [];
    if (imageFiles.isNotEmpty) {
      imageUrls = await _storageService.uploadImages(
        files: imageFiles,
        bucket: SupabaseConfig.postImagesBucket,
      );
    }
    final post = await _postService.createPost(
      title: title,
      content: content,
      imageUrls: imageUrls,
    );
    posts.insert(0, post);
    notifyListeners();
    return post;
  }

  /// [keptImageUrls]: existing images the user did NOT remove.
  /// [newImageFiles]: freshly picked local files to upload.
  Future<PostModel> updatePost({
    required PostModel original,
    required String title,
    required String content,
    List<String> keptImageUrls = const [],
    List<XFile> newImageFiles = const [],
  }) async {
    final removedUrls =
        original.imageUrls.where((url) => !keptImageUrls.contains(url)).toList();
    if (removedUrls.isNotEmpty) {
      await _storageService.deleteImages(
        imageUrls: removedUrls,
        bucket: SupabaseConfig.postImagesBucket,
      );
    }

    List<String> newUrls = [];
    if (newImageFiles.isNotEmpty) {
      newUrls = await _storageService.uploadImages(
        files: newImageFiles,
        bucket: SupabaseConfig.postImagesBucket,
      );
    }

    final finalUrls = [...keptImageUrls, ...newUrls];

    final updated = await _postService.updatePost(
      id: original.id,
      title: title,
      content: content,
      imageUrls: finalUrls,
    );

    final idx = posts.indexWhere((p) => p.id == updated.id);
    if (idx != -1) posts[idx] = updated;
    notifyListeners();
    return updated;
  }

  Future<void> deletePost(PostModel post) async {
    if (post.imageUrls.isNotEmpty) {
      await _storageService.deleteImages(
        imageUrls: post.imageUrls,
        bucket: SupabaseConfig.postImagesBucket,
      );
    }
    await _postService.deletePost(post.id);
    posts.removeWhere((p) => p.id == post.id);
    notifyListeners();
  }
}
