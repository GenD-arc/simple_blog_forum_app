import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../core/theme.dart';
import '../models/comment_model.dart';
import 'comment_image_strip.dart';

class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final CommentModel comment;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.crimson,
                child: Icon(Icons.person, size: 15, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorUsername ?? 'Anonymous',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      timeago.format(comment.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (comment.content.isNotEmpty)
              Text(comment.content, style: Theme.of(context).textTheme.bodyLarge),
          if (comment.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              CommentImageStrip(imageUrls: comment.imageUrls),
          ],
        ],
      ),
    );
  }
}
