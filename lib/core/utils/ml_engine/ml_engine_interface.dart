import 'dart:typed_data';
import 'package:mango_ripe/data/models/scan_result.dart';

abstract class MLEngine {
  Future<void> loadModel();
  bool get isLoaded;
  Future<ScanResult> classifyImage(Uint8List imageBytes);
  void dispose();
}
