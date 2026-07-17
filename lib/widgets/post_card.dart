import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../core/theme.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onTap});

  final PostModel post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imageUrls.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: post.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.border),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.border,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      if (post.imageUrls.length > 1)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_outlined, size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text('${post.imageUrls.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.crimson,
                        child: Icon(Icons.person, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.authorUsername ?? 'Anonymous',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.mode_comment_outlined,
                          size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${post.commentCount}',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(width: 12),
                      Text(
                        timeago.format(post.createdAt),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
