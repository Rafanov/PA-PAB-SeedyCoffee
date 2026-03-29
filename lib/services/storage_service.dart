import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env_config.dart';
import '../core/config/supabase_config.dart';
import '../screens/shared/image_crop_screen.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _picker = ImagePicker();

  // ── Pick + Crop → returns cropped bytes ─────────────────────
  // aspectRatio: 1.0 = square (avatar/menu), 8/3 = banner landscape
  Future<Uint8List?> pickAndCrop(
    BuildContext context, {
    double aspectRatio = 1.0,
    String title = 'Crop Image',
  }) async {
    // 1. Pick from gallery
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (xfile == null) return null;

    // 2. Read bytes
    final bytes = await xfile.readAsBytes();
    if (bytes.isEmpty) return null;

    // 3. Open crop screen
    if (!context.mounted) return null;
    final cropped = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageCropScreen(
          imageBytes: bytes,
          aspectRatio: aspectRatio,
          title: title,
        ),
      ),
    );
    return cropped;
  }

  // ── Upload menu image (1:1 square crop) ─────────────────────
  Future<String?> uploadMenuImageFromBytes(Uint8List bytes) async {
    return _uploadBytes(bytes, SupabaseConfig.bucketMenuImages, 'menu');
  }

  // ── Upload banner image (wide crop) ─────────────────────────
  Future<String?> uploadBannerImageFromBytes(Uint8List bytes) async {
    return _uploadBytes(bytes, SupabaseConfig.bucketBanners, 'banner');
  }

  // ── Upload avatar (1:1 square crop) ─────────────────────────
  Future<String?> uploadAvatarFromBytes(Uint8List bytes, String userId) async {
    return _uploadBytes(bytes, SupabaseConfig.bucketMenuImages, 'avatars/$userId');
  }

  // ── Core upload via bytes — works on Web + Mobile ────────────
  Future<String?> _uploadBytes(
      Uint8List bytes, String bucket, String prefix) async {
    if (!EnvConfig.useSupabase) return null;
    if (bytes.isEmpty) return null;
    try {
      final path = '$prefix/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await SupabaseConfig.client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return SupabaseConfig.client.storage
          .from(bucket)
          .getPublicUrl(path);
    } catch (e) {
      // ignore: avoid_print
      print('Bucket: $bucket | Path: $prefix | Bytes: ${bytes.length}');
      // ignore: avoid_print
      print('Error type: \${e.runtimeType}');
      // ignore: avoid_print
      print('Error detail: \$e');
      // ignore: avoid_print
      print('================================');
      return null;
    }
  }

  // ── Legacy XFile methods (kept for compatibility) ─────────────
  Future<XFile?> pickImageFile() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (xfile == null) return null;
      final bytes = await xfile.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) return null;
      return xfile;
    } catch (_) { return null; }
  }

  Future<String?> uploadMenuImage(XFile file) async {
    final bytes = await file.readAsBytes();
    return _uploadBytes(bytes, SupabaseConfig.bucketMenuImages, 'menu');
  }

  Future<String?> uploadBannerImage(XFile file) async {
    final bytes = await file.readAsBytes();
    return _uploadBytes(bytes, SupabaseConfig.bucketBanners, 'banner');
  }

  Future<String?> uploadAvatar(XFile file, String userId) async {
    final bytes = await file.readAsBytes();
    return _uploadBytes(bytes, SupabaseConfig.bucketMenuImages, 'avatars/$userId');
  }

  bool get isAvailable => EnvConfig.useSupabase;
}
