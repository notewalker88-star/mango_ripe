import 'package:hive/hive.dart';

part 'scan_result.g.dart';

@HiveType(typeId: 0)
class ScanResult extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final double confidence;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? imagePath;

  @HiveField(5)
  final List<double> allConfidences;

  ScanResult({
    required this.id,
    required this.label,
    required this.confidence,
    required this.timestamp,
    this.imagePath,
    required this.allConfidences,
  });

  String get shelfLife {
    const map = {
      'Unripe': '7-14 days',
      'Partially Ripe': '3-5 days',
      'Fully Ripe': '1-3 days',
      'Overripe': 'Consume immediately',
    };
    return map[label] ?? 'Unknown';
  }

  String get recommendation {
    const map = {
      'Unripe': 'Store at room temperature to ripen. Great for pickles, chutneys, and raw salads.',
      'Partially Ripe': 'Place in a paper bag to speed ripening. Suitable for smoothies or grilling.',
      'Fully Ripe': 'Ideal for fresh eating, desserts, smoothies, and fruit salads. Refrigerate to extend life.',
      'Overripe': 'Best used immediately for juices, jams, or baked goods. Discard if moldy.',
    };
    return map[label] ?? 'No recommendation available.';
  }

  ScanResult copyWith({
    String? id,
    String? label,
    double? confidence,
    DateTime? timestamp,
    String? imagePath,
    List<double>? allConfidences,
  }) {
    return ScanResult(
      id: id ?? this.id,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      allConfidences: allConfidences ?? this.allConfidences,
    );
  }
}