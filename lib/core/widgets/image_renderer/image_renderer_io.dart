import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'image_renderer_interface.dart';

ImageRenderer getImageRenderer() => ImageRendererIO();

class ImageRendererIO implements ImageRenderer {
  @override
  Widget renderImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('data:image')) {
      final base64Content = path.split(',').last;
      return Image.memory(base64Decode(base64Content), fit: fit);
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: fit);
    }
    return const Center(child: Icon(Icons.broken_image_rounded));
  }
}
