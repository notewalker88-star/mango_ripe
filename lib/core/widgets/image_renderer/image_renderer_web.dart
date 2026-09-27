import 'dart:convert';
import 'package:flutter/material.dart';
import 'image_renderer_interface.dart';

ImageRenderer getImageRenderer() => ImageRendererWeb();

class ImageRendererWeb implements ImageRenderer {
  @override
  Widget renderImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('data:image')) {
      final base64Content = path.split(',').last;
      return Image.memory(base64Decode(base64Content), fit: fit);
    }
    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
      return Image.network(path, fit: fit);
    }
    return const Center(child: Icon(Icons.broken_image_rounded));
  }
}
