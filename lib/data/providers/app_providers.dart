import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/scan_history_repository.dart';
import 'package:mango_ripe/data/models/scan_result.dart';
import 'package:mango_ripe/core/utils/ml_service.dart';

// ML Service Provider
final mlServiceProvider = Provider<MLService>((ref) {
  final service = MLService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ML Initialized Provider
final mlInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(mlServiceProvider);
  try {
    await service.loadModel();
    return true;
  } catch (_) {
    return false;
  }
});

// Repository Provider
final scanHistoryRepositoryProvider = Provider<ScanHistoryRepository>((ref) {
  return ScanHistoryRepository();
});

// Filter state
enum ScanFilter { all, unripe, partiallyRipe, ripe, overripe }

final scanFilterProvider = StateProvider<ScanFilter>((ref) => ScanFilter.all);

// History list provider
final scanHistoryProvider = StateNotifierProvider<ScanHistoryNotifier, List<ScanResult>>((ref) {
  final repo = ref.watch(scanHistoryRepositoryProvider);
  return ScanHistoryNotifier(repo);
});

class ScanHistoryNotifier extends StateNotifier<List<ScanResult>> {
  final ScanHistoryRepository _repo;

  ScanHistoryNotifier(this._repo) : super(_repo.getAllScans());

  Future<void> addScan(ScanResult result) async {
    await _repo.addScan(result);
    state = _repo.getAllScans();
  }

  Future<void> deleteScan(String id) async {
    await _repo.deleteScan(id);
    state = _repo.getAllScans();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = [];
  }

  void refresh() {
    state = _repo.getAllScans();
  }
}

// Current scan result
final currentScanResultProvider = StateProvider<ScanResult?>((ref) => null);

// Processing state
final isProcessingProvider = StateProvider<bool>((ref) => false);
