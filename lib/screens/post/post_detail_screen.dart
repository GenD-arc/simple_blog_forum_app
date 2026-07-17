import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme.dart';
import '../../models/comment_model.dart';
import '../../models/picked_image_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/comment_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/max_width_container.dart';
import '../../widgets/post_image_gallery.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postService = PostService();
  PostModel? _post;
  bool _loadingPost = true;
  String? _postError;

  final _commentController = TextEditingController();
  List<PickedImage> _newCommentImages = [];
  CommentModel? _editingComment;

  static const int _maxCommentImages = 3;

  @override
  void initState() {
    super.initState();
    _loadPost();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().loadComments(widget.postId);
    });
    // Rebuild the composer (send button enabled state) as the user types.
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    setState(() {
      _loadingPost = true;
      _postError = null;
    });
    try {
      final post = await _postService.fetchPostById(widget.postId);
      setState(() => _post = post);
    } catch (e) {
      setState(() => _postError = 'This post could not be loaded.');
    } finally {
      setState(() => _loadingPost = false);
    }
  }

  Future<void> _addCommentImage() async {
    if (_newCommentImages.length >= _maxCommentImages) return;
    final picker = ImagePicker();
    final result =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1400);
    if (result == null) return;
    final bytes = await result.readAsBytes();
    setState(() => _newCommentImages = [..._newCommentImages, PickedImage.picked(result, bytes)]);
  }

  void _removeCommentImageAt(int index) {
    setState(() => _newCommentImages = List.of(_newCommentImages)..removeAt(index));
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    final hasImages = _newCommentImages.isNotEmpty;
    if (text.isEmpty && !hasImages) return;

    final commentProvider = context.read<CommentProvider>();

    final keptUrls =
        _newCommentImages.where((i) => i.isExisting).map((i) => i.existingUrl!).toList();
    final newFiles =
        _newCommentImages.where((i) => !i.isExisting).map((i) => i.file!).toList();

    if (_editingComment != null) {
      await commentProvider.updateComment(
        original: _editingComment!,
        content: text,
        keptImageUrls: keptUrls,
        newImageFiles: newFiles,
      );
    } else {
      await commentProvider.addComment(
        postId: widget.postId,
        content: text,
        imageFiles: newFiles,
      );
    }

    setState(() {
      _commentController.clear();
      _newCommentImages = [];
      _editingComment = null;
    });
    if (_post != null) {
      final refreshed = await _postService.fetchPostById(widget.postId);
      setState(() => _post = refreshed);
    }
  }

  void _startEditComment(CommentModel comment) {
    setState(() {
      _editingComment = comment;
      _commentController.text = comment.content;
      _newCommentImages = comment.imageUrls.map((u) => PickedImage.existing(u)).toList();
    });
  }

  void _cancelEditComment() {
    setState(() {
      _editingComment = null;
      _commentController.clear();
      _newCommentImages = [];
    });
  }

  Future<void> _deleteComment(CommentModel comment) async {
    final confirmed = await _confirm(
      title: 'Delete comment?',
      message: 'This cannot be undone.',
    );
    if (confirmed != true) return;
    await context.read<CommentProvider>().deleteComment(comment);
  }

  Future<void> _deletePost() async {
    final confirmed = await _confirm(
      title: 'Delete post?',
      message: 'This will remove the post and its comments permanently.',
    );
    if (confirmed != true || _post == null) return;
    await context.read<PostProvider>().deletePost(_post!);
    if (mounted) context.pop();
  }

  Future<bool?> _confirm({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final commentProvider = context.watch<CommentProvider>();
    final isPostOwner = _post != null && auth.user?.id == _post!.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.crimson,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isPostOwner)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final updated = await context.push<PostModel>(
                    '/post/${_post!.id}/edit',
                    extra: _post,
                  );
                  if (updated != null && mounted) {
                    setState(() => _post = updated);
                  }
                }
                if (value == 'delete') _deletePost();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit post')),
                PopupMenuItem(value: 'delete', child: Text('Delete post')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: _loadingPost
            ? const LoadingIndicator(size: 32)
            : _postError != null
                ? Center(child: Text(_postError!, style: Theme.of(context).textTheme.bodyLarge))
                : MaxWidthContainer(
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                            children: [
                              _buildPostHeader(_post!),
                              const SizedBox(height: 22),
                              const Divider(color: AppColors.border),
                              const SizedBox(height: 14),
                              Text('Comments (${commentProvider.comments.length})',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 14),
                              if (commentProvider.isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: LoadingIndicator(),
                                )
                              else if (commentProvider.comments.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text('No comments yet. Start the conversation.',
                                      style: Theme.of(context).textTheme.bodyMedium),
                                )
                              else
                                ...commentProvider.comments.map(
                                  (comment) => CommentCard(
                                    comment: comment,
                                    isOwner: auth.user?.id == comment.userId,
                                    onEdit: () => _startEditComment(comment),
                                    onDelete: () => _deleteComment(comment),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _buildCommentComposer(auth, commentProvider),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildPostHeader(PostModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.imageUrls.isNotEmpty) ...[
          PostImageGallery(imageUrls: post.imageUrls),
          const SizedBox(height: 18),
        ] else
          const SizedBox(height: 4),
        Text(post.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Row(
          children: [
            const CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.crimson,
              child: Icon(Icons.person, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(post.authorUsername ?? 'Anonymous',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Text('· ${timeago.format(post.createdAt)}',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 16),
        Text(post.content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
      ],
    );
  }

  Widget _imageThumbWithRemove({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentComposer(AuthProvider auth, CommentProvider commentProvider) {
    if (!auth.isLoggedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Log in to join the conversation.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    }

    final canSubmit = !commentProvider.isSubmitting &&
        (_commentController.text.trim().isNotEmpty || _newCommentImages.isNotEmpty);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_editingComment != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text('Editing comment', style: Theme.of(context).textTheme.bodyMedium),
                  const Spacer(),
                  TextButton(onPressed: _cancelEditComment, child: const Text('Cancel')),
                ],
              ),
            ),
          if (_newCommentImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newCommentImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final img = _newCommentImages[index];
                    return _imageThumbWithRemove(
                      child: img.isExisting
                          ? CachedNetworkImage(
                              imageUrl: img.existingUrl!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            )
                          : Image.memory(img.bytes!, width: 72, height: 72, fit: BoxFit.cover),
                      onRemove: () => _removeCommentImageAt(index),
                    );
                  },
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed:
                        _newCommentImages.length >= _maxCommentImages ? null : _addCommentImage,
                    icon: const Icon(Icons.image_outlined, color: AppColors.crimson),
                  ),
                  if (_newCommentImages.isNotEmpty)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.crimson,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_newCommentImages.length}/$_maxCommentImages',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment…',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: canSubmit ? _submitComment : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                ),
                icon: commentProvider.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}