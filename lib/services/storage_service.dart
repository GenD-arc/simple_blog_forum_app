import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Uploads [file] to [bucket] under the current user's folder and
  /// returns the public URL. Reads bytes via XFile so this works on
  /// web, mobile, and desktop alike (no dart:io File).
  Future<String> uploadImage({
    required XFile file,
    required String bucket,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final bytes = await file.readAsBytes();

    final nameParts = file.name.split('.');
    final ext = nameParts.length > 1 ? nameParts.last : 'jpg';
    final fileName = '${_uuid.v4()}.$ext';
    final path = '$userId/$fileName';

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: file.mimeType,
          ),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<List<String>> uploadImages({
  required List<XFile> files,
  required String bucket,
}) {
  return Future.wait(files.map((f) => uploadImage(file: f, bucket: bucket)));
}

Future<void> deleteImages({
  required List<String> imageUrls,
  required String bucket,
}) async {
  final paths = imageUrls
      .map((url) => _extractPathFromUrl(url, bucket))
      .whereType<String>()
      .toList();
  if (paths.isEmpty) return;
  await _client.storage.from(bucket).remove(paths);
}

  /// Deletes an image from [bucket] given its full public URL.
  Future<void> deleteImage({
    required String imageUrl,
    required String bucket,
  }) async {
    final path = _extractPathFromUrl(imageUrl, bucket);
    if (path == null) return;
    await _client.storage.from(bucket).remove([path]);
  }

  String? _extractPathFromUrl(String url, String bucket) {
    final marker = '/object/public/$bucket/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    return url.substring(idx + marker.length);
  }
}
