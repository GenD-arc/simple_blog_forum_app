import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'fullscreen_image_viewer.dart';

class PostImageGallery extends StatelessWidget {
  const PostImageGallery({super.key, required this.imageUrls, this.borderRadius = 20});

  final List<String> imageUrls;
  final double borderRadius;

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

    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: () => _openViewer(context, 0),
            child: _networkImage(imageUrls[0]),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(aspectRatio: 16 / 9, child: _buildGrid(context)),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final count = imageUrls.length;

    if (count == 2) {
      return Row(children: [
        Expanded(child: _gridTile(context, 0)),
        const SizedBox(width: 3),
        Expanded(child: _gridTile(context, 1)),
      ]);
    }

    if (count == 3) {
      return Row(children: [
        Expanded(child: _gridTile(context, 0)),
        const SizedBox(width: 3),
        Expanded(
          child: Column(children: [
            Expanded(child: _gridTile(context, 1)),
            const SizedBox(height: 3),
            Expanded(child: _gridTile(context, 2)),
          ]),
        ),
      ]);
    }

    // 4 or 5 photos: 2x2 grid; a 5th photo shows as a "+1" overlay on the last tile.
    return Column(children: [
      Expanded(
        child: Row(children: [
          Expanded(child: _gridTile(context, 0)),
          const SizedBox(width: 3),
          Expanded(child: _gridTile(context, 1)),
        ]),
      ),
      const SizedBox(height: 3),
      Expanded(
        child: Row(children: [
          Expanded(child: _gridTile(context, 2)),
          const SizedBox(width: 3),
          Expanded(child: _gridTile(context, 3, overlayCount: count == 5 ? 1 : 0)),
        ]),
      ),
    ]);
  }

  Widget _gridTile(BuildContext context, int index, {int overlayCount = 0}) {
    return GestureDetector(
      onTap: () => _openViewer(context, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _networkImage(imageUrls[index]),
          if (overlayCount > 0)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Text('+$overlayCount',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _networkImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey.shade300),
      errorWidget: (_, __, ___) =>
          Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image_outlined)),
    );
  }
}