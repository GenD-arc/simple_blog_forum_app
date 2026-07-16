import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/max_width_container.dart';

class PostFormScreen extends StatefulWidget {
  const PostFormScreen({super.key, this.postId, this.initialPost});

  /// Present when navigating to edit an existing post.
  final String? postId;

  /// Optional pre-fetched post passed via router `extra` to avoid a refetch.
  final PostModel? initialPost;

  bool get isEditing => postId != null;

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _postService = PostService();

  PostModel? _original;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _removeImage = false;

  bool _loadingOriginal = false;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      if (widget.initialPost != null) {
        _hydrate(widget.initialPost!);
      } else {
        _fetchOriginal();
      }
    }
  }

  Future<void> _fetchOriginal() async {
    setState(() => _loadingOriginal = true);
    try {
      final post = await _postService.fetchPostById(widget.postId!);
      _hydrate(post);
    } catch (e) {
      setState(() => _loadError = 'Could not load this post.');
    } finally {
      setState(() => _loadingOriginal = false);
    }
  }

  void _hydrate(PostModel post) {
    _original = post;
    _titleController.text = post.title;
    _contentController.text = post.content;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final postProvider = context.read<PostProvider>();

    try {
      if (widget.isEditing) {
        final updated = await postProvider.updatePost(
          original: _original!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          newImageFile: _pickedImage,
          removeImage: _removeImage,
        );
        if (mounted) context.pop(updated);
      } else {
        final created = await postProvider.createPost(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imageFile: _pickedImage,
        );
        if (mounted) context.pop(created);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.', style: TextStyle(color: Colors.white),), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Post' : 'New Post', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.crimson,
      ),
      body: SafeArea(
        child: _loadingOriginal
            ? const LoadingIndicator(size: 32)
            : _loadError != null
                ? Center(child: Text(_loadError!, style: Theme.of(context).textTheme.bodyLarge))
                : MaxWidthContainer(
                    maxWidth: 560,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ImagePickerField(
                              existingUrl: _removeImage ? null : _original?.imageUrl,
                              pickedBytes: _pickedImageBytes,
                              onPick: (file, bytes) => setState(() {
                                _pickedImage = file;
                                _pickedImageBytes = bytes;
                                _removeImage = false;
                              }),
                              onRemove: () => setState(() {
                                _pickedImage = null;
                                _pickedImageBytes = null;
                                _removeImage = true;
                              }),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(labelText: 'Title'),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _contentController,
                              decoration: const InputDecoration(labelText: 'What\'s on your mind?'),
                              minLines: 6,
                              maxLines: 12,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Content is required' : null,
                            ),
                            const SizedBox(height: 26),
                            ElevatedButton(
                              onPressed: _saving ? null : _submit,
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.2, color: Colors.white),
                                    )
                                  : Text(widget.isEditing ? 'Save Changes' : 'Publish Post'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}