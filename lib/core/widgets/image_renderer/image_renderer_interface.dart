import 'package:flutter/material.dart';

abstract class ImageRenderer {
  Widget renderImage(String path, {BoxFit fit = BoxFit.cover});
}
