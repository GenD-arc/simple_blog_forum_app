import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comment_model.dart';

class CommentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<CommentModel>> fetchComments(String postId) async {
    final data = await _client
        .from('comments')
        .select('*, profiles(username)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((row) => CommentModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment({
    required String postId,
    required String content,
    List<String> imageUrls = const [],
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'content': content,
          'image_urls': imageUrls,
        })
        .select('*, profiles(username)')
        .single();
    return CommentModel.fromMap(data);
  }

  Future<CommentModel> updateComment({
    required String id,
    required String content,
    List<String> imageUrls = const [],
  }) async {
    final data = await _client
        .from('comments')
        .update({
          'content': content,
          'image_urls': imageUrls,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select('*, profiles(username)')
        .single();
    return CommentModel.fromMap(data);
  }

  Future<void> deleteComment(String id) async {
    await _client.from('comments').delete().eq('id', id);
  }
}