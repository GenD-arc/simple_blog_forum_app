class PostModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorUsername;
  final int commentCount;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.authorUsername,
    this.commentCount = 0,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    // profiles is joined as `profiles(username)`; comments count via `comments(count)`
    final profile = map['profiles'];
    final commentsAgg = map['comments'];
    int parsedCommentCount = 0;
    if (commentsAgg is List && commentsAgg.isNotEmpty) {
      parsedCommentCount = (commentsAgg.first['count'] as num?)?.toInt() ?? 0;
    }

    return PostModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String? ?? map['created_at'] as String),
      authorUsername: profile is Map ? profile['username'] as String? : null,
      commentCount: parsedCommentCount,
    );
  }

  PostModel copyWith({
    String? title,
    String? content,
    String? imageUrl,
    bool clearImage = false,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      authorUsername: authorUsername,
      commentCount: commentCount,
    );
  }
}
