import 'package:flutter/material.dart';
import 'image_renderer/image_renderer.dart';

class AppThumbnail extends StatelessWidget {
  final String? imagePath;
  final String fallbackEmoji;
  final double emojiSize;
  final BoxFit fit;

  const AppThumbnail({
    super.key,
    required this.imagePath,
    required this.fallbackEmoji,
    this.emojiSize = 28,
    this.fit = BoxFit.cover,
  });

  static final ImageRenderer _renderer = getImageRenderer();

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return _renderer.renderImage(imagePath!, fit: fit);
    }
    return Center(
      child: Text(
        fallbackEmoji,
        style: TextStyle(fontSize: emojiSize),
      ),
    );
  }
}
