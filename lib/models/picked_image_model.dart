import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class PickedImage {
  final XFile? file;
  final Uint8List? bytes;
  final String? existingUrl;
  final bool isExisting;

  PickedImage._({
    this.file,
    this.bytes,
    this.existingUrl,
    required this.isExisting,
  });

  factory PickedImage.picked(XFile file, Uint8List bytes) {
    return PickedImage._(
      file: file,
      bytes: bytes,
      isExisting: false,
    );
  }

  factory PickedImage.existing(String url) {
    return PickedImage._(
      existingUrl: url,
      isExisting: true,
    );
  }
}