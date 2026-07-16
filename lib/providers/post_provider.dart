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
    XFile? imageFile,
  }) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _storageService.uploadImage(
        file: imageFile,
        bucket: SupabaseConfig.postImagesBucket,
      );
    }
    final post = await _postService.createPost(
      title: title,
      content: content,
      imageUrl: imageUrl,
    );
    posts.insert(0, post);
    notifyListeners();
    return post;
  }

  /// Updates a post. [removeImage] deletes the existing image with no
  /// replacement; [newImageFile] uploads a replacement (old one is removed).
  Future<PostModel> updatePost({
    required PostModel original,
    required String title,
    required String content,
    XFile? newImageFile,
    bool removeImage = false,
  }) async {
    String? imageUrl = original.imageUrl;

    if (newImageFile != null) {
      if (original.imageUrl != null) {
        await _storageService.deleteImage(
          imageUrl: original.imageUrl!,
          bucket: SupabaseConfig.postImagesBucket,
        );
      }
      imageUrl = await _storageService.uploadImage(
        file: newImageFile,
        bucket: SupabaseConfig.postImagesBucket,
      );
    } else if (removeImage && original.imageUrl != null) {
      await _storageService.deleteImage(
        imageUrl: original.imageUrl!,
        bucket: SupabaseConfig.postImagesBucket,
      );
      imageUrl = null;
    }

    final updated = await _postService.updatePost(
      id: original.id,
      title: title,
      content: content,
      imageUrl: imageUrl,
    );

    final idx = posts.indexWhere((p) => p.id == updated.id);
    if (idx != -1) posts[idx] = updated;
    notifyListeners();
    return updated;
  }

  Future<void> deletePost(PostModel post) async {
    if (post.imageUrl != null) {
      await _storageService.deleteImage(
        imageUrl: post.imageUrl!,
        bucket: SupabaseConfig.postImagesBucket,
      );
    }
    await _postService.deletePost(post.id);
    posts.removeWhere((p) => p.id == post.id);
    notifyListeners();
  }
}
