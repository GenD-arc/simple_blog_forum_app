import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'fullscreen_image_viewer.dart';

class CommentImageStrip extends StatelessWidget {
  const CommentImageStrip({super.key, required this.imageUrls});

  final List<String> imageUrls;

  void _openViewer(BuildContext context, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) =>
            FullscreenImageViewer(imageUrls: imageUrls, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openViewer(context, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: imageUrls[index],
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade300),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image_outlined, size: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}