import 'dart:ui' show Rect;
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Reusable full-screen image crop screen.
/// Returns Uint8List (cropped bytes) or null if cancelled.
class ImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final double aspectRatio; // e.g. 1.0 for square, 8/3 for banner
  final String title;

  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    required this.aspectRatio,
    required this.title,
  });

  @override
  State<ImageCropScreen> createState() => _State();
}

class _State extends State<ImageCropScreen> {
  final _controller = CropController();
  bool _cropping = false;

  void _crop() {
    setState(() => _cropping = true);
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _cropping ? null : _crop,
            child: _cropping
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Use Photo',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        // Hints
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _hint(Icons.pinch_outlined, 'Pinch to zoom'),
            const SizedBox(width: 20),
            _hint(Icons.open_with_rounded, 'Drag to move'),
          ]),
        ),
        // Crop area
        Expanded(
          child: Crop(
            controller: _controller,
            image: widget.imageBytes,
            aspectRatio: widget.aspectRatio,
            onCropped: (result) {
              switch (result) {
                case CropSuccess(:final croppedImage):
                  Navigator.pop(context, croppedImage);
                case CropFailure():
                  setState(() => _cropping = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Crop failed, try again')));
              }
            },
            cornerDotBuilder: (size, edgeAlignment) =>
                const _CornerDot(),
            interactive: true,
            withCircleUi: false,
            baseColor: Colors.black,
            maskColor: Colors.black.withOpacity(0.55),
          ),
        ),
        // Bottom action bar
        Container(
          color: Colors.black,
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).padding.bottom + 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
            _ActionBtn(icon: Icons.refresh_rounded, label: 'Reset',
                onTap: () => _controller.cropRect = Rect.fromLTWH(0.1, 0.1, 0.8, 0.8)),
            _ActionBtn(icon: Icons.crop_rounded, label: 'Crop',
                onTap: _crop, isPrimary: true),
          ]),
        ),
      ]),
    );
  }

  Widget _hint(IconData icon, String label) => Row(children: [
    Icon(icon, color: Colors.white54, size: 14),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
  ]);
}

class _CornerDot extends StatelessWidget {
  const _CornerDot();
  @override
  Widget build(BuildContext context) => Container(
    width: 18, height: 18,
    decoration: BoxDecoration(
      color: Colors.white70,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  const _ActionBtn({required this.icon, required this.label,
      required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: isPrimary ? Colors.black : Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
            color: isPrimary ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    ),
  );
}
