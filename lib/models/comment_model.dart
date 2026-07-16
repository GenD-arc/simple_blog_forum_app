class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorUsername;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.authorUsername,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'];
    return CommentModel(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String? ?? map['created_at'] as String),
      authorUsername: profile is Map ? profile['username'] as String? : null,
    );
  }
}
