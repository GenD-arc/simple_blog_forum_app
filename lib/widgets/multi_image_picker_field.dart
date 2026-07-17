import 'package:flutter/material.dart';
import '../../models/picked_image_model.dart';
import '../../core/theme.dart';

class MultiImagePickerField extends StatelessWidget {
  final List<PickedImage> images;
  final VoidCallback onAdd;
  final Function(int) onRemoveAt;

  const MultiImagePickerField({
    super.key,
    required this.images,
    required this.onAdd,
    required this.onRemoveAt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Images (${images.length}/5)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (images.length < 5)
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_photo_alternate),
                tooltip: 'Add Image',
                color: AppColors.crimson,
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Images grid
        if (images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: images.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return _buildImageItem(context, index, image);
            }).toList(),
          )
        else
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: images.length < 5 ? onAdd : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add images',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageItem(BuildContext context, int index, PickedImage image) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            image: DecorationImage(
              image: image.isExisting
                  ? NetworkImage(image.existingUrl!)
                  : MemoryImage(image.bytes!) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton(
            onPressed: () => onRemoveAt(index),
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        // Image index badge
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}