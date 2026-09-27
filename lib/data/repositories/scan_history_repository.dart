import 'package:hive_flutter/hive_flutter.dart';
import 'package:mango_ripe/data/models/scan_result.dart';
import 'package:mango_ripe/core/constants/app_constants.dart';

class ScanHistoryRepository {
  Box<ScanResult> get _box => Hive.box<ScanResult>(AppConstants.scanHistoryBox);

  List<ScanResult> getAllScans() {
    return _box.values.toList().reversed.toList();
  }

  List<ScanResult> getScansByLabel(String label) {
    return _box.values.where((s) => s.label == label).toList().reversed.toList();
  }

  Future<void> addScan(ScanResult scan) async {
    await _box.put(scan.id, scan);
  }

  Future<void> deleteScan(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  int get totalScans => _box.length;

  Map<String, int> get labelCounts {
    final counts = <String, int>{};
    for (final scan in _box.values) {
      counts[scan.label] = (counts[scan.label] ?? 0) + 1;
    }
    return counts;
  }
}
