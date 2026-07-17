import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post_model.dart';

class PostService {
  final SupabaseClient _client = Supabase.instance.client;

  static const int pageSize = 8;

  /// Fetches a page of public posts (newest first), joined with the
  /// author's profile and a comment count.
  Future<List<PostModel>> fetchPosts({required int page}) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final data = await _client
        .from('posts')
        .select('*, profiles(username), comments(count)')
        .order('created_at', ascending: false)
        .range(from, to);

    return (data as List)
        .map((row) => PostModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<PostModel> fetchPostById(String id) async {
    final data = await _client
        .from('posts')
        .select('*, profiles(username), comments(count)')
        .eq('id', id)
        .single();
    return PostModel.fromMap(data);
  }

  Future<PostModel> createPost({
  required String title,
  required String content,
  List<String> imageUrls = const [],
}) async {
  final userId = _client.auth.currentUser!.id;
  final data = await _client
      .from('posts')
      .insert({
        'user_id': userId,
        'title': title,
        'content': content,
        'image_urls': imageUrls,
      })
      .select('*, profiles(username), comments(count)')
      .single();
  return PostModel.fromMap(data);
}

Future<PostModel> updatePost({
  required String id,
  required String title,
  required String content,
  List<String> imageUrls = const [],
}) async {
  final data = await _client
      .from('posts')
      .update({
        'title': title,
        'content': content,
        'image_urls': imageUrls,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', id)
      .select('*, profiles(username), comments(count)')
      .single();
  return PostModel.fromMap(data);
}

  Future<void> deletePost(String id) async {
    await _client.from('posts').delete().eq('id', id);
  }
}
