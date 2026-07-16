import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';

/// A tappable image field that supports three states:
/// - empty (show "add image" placeholder)
/// - existing network image (from [existingUrl])
/// - newly picked local file, previewed from [pickedBytes]
///
/// Uses [XFile]/bytes (not dart:io File) so it works on web, mobile, and
/// desktop alike. Callbacks let the parent form own the actual state.
class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    super.key,
    required this.existingUrl,
    required this.pickedBytes,
    required this.onPick,
    required this.onRemove,
    this.height = 200,
  });

  final String? existingUrl;
  final Uint8List? pickedBytes;
  final void Function(XFile file, Uint8List bytes) onPick;
  final VoidCallback onRemove;
  final double height;

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (result != null) {
      final bytes = await result.readAsBytes();
      onPick(result, bytes);
    }
  }

  bool get _hasImage => pickedBytes != null || existingUrl != null;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          InkWell(
            onTap: () => _pick(context),
            child: Container(
              width: double.infinity,
              height: height,
              color: AppColors.border.withOpacity(0.4),
              child: _hasImage ? _buildImage() : _buildPlaceholder(context),
            ),
          ),
          if (_hasImage)
            Positioned(
              top: 10,
              right: 10,
              child: _RoundIconButton(
                icon: Icons.close,
                onTap: onRemove,
              ),
            ),
          if (_hasImage)
            Positioned(
              bottom: 10,
              right: 10,
              child: _RoundIconButton(
                icon: Icons.edit,
                onTap: () => _pick(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (pickedBytes != null) {
      return Image.memory(pickedBytes!, fit: BoxFit.cover, width: double.infinity);
    }
    return CachedNetworkImage(
      imageUrl: existingUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.crimson),
      ),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_outlined,
            color: AppColors.textSecondary, size: 30),
        const SizedBox(height: 8),
        Text('Add an image', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
