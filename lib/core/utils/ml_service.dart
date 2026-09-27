import 'package:flutter/foundation.dart';
import 'package:mango_ripe/data/models/scan_result.dart';
import 'ml_engine/ml_engine.dart';

class MLService {
  final MLEngine _engine = getMLEngine();

  Future<void> loadModel() => _engine.loadModel();

  bool get isLoaded => _engine.isLoaded;

  Future<ScanResult> classifyImage(Uint8List imageBytes) =>
      _engine.classifyImage(imageBytes);

  void dispose() => _engine.dispose();
}
