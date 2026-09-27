import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mango_ripe/core/constants/app_constants.dart';
import 'package:mango_ripe/data/models/scan_result.dart';
import 'package:mango_ripe/widgets/mango_analyzing_overlay.dart';

void main() {
  group('ScanResult Model Tests', () {
    test('Correctly calculates shelf life and recommendations for all stages', () {
      final unripe = ScanResult(
        id: '1',
        label: 'Unripe',
        confidence: 0.95,
        timestamp: DateTime(2026, 1, 1),
        allConfidences: [0.95, 0.03, 0.01, 0.01],
      );
      expect(unripe.shelfLife, '7-14 days');
      expect(unripe.recommendation, contains('room temperature'));

      final partiallyRipe = ScanResult(
        id: '2',
        label: 'Partially Ripe',
        confidence: 0.88,
        timestamp: DateTime(2026, 1, 1),
        allConfidences: [0.05, 0.88, 0.05, 0.02],
      );
      expect(partiallyRipe.shelfLife, '3-5 days');
      expect(partiallyRipe.recommendation, contains('smoothies or grilling'));

      final fullyRipe = ScanResult(
        id: '3',
        label: 'Fully Ripe',
        confidence: 0.92,
        timestamp: DateTime(2026, 1, 1),
        allConfidences: [0.01, 0.05, 0.92, 0.02],
      );
      expect(fullyRipe.shelfLife, '1-3 days');
      expect(fullyRipe.recommendation, contains('fresh eating'));

      final overripe = ScanResult(
        id: '4',
        label: 'Overripe',
        confidence: 0.99,
        timestamp: DateTime(2026, 1, 1),
        allConfidences: [0.0, 0.01, 0.0, 0.99],
      );
      expect(overripe.shelfLife, 'Consume immediately');
      expect(overripe.recommendation, contains('jams'));
    });

    test('copyWith properly duplicates scan result with updated fields', () {
      final original = ScanResult(
        id: '100',
        label: 'Unripe',
        confidence: 0.85,
        timestamp: DateTime(2026, 1, 1),
        allConfidences: [0.85, 0.1, 0.03, 0.02],
      );

      final updated = original.copyWith(
        label: 'Fully Ripe',
        imagePath: '/path/to/thumb.jpg',
      );

      expect(updated.id, '100');
      expect(updated.label, 'Fully Ripe');
      expect(updated.imagePath, '/path/to/thumb.jpg');
      expect(updated.confidence, 0.85);
    });
  });

  group('AppConstants Tests', () {
    test('Constants contain all 4 ripeness classes', () {
      expect(AppConstants.labels.length, 4);
      expect(AppConstants.labels, containsAll(['Unripe', 'Partially Ripe', 'Fully Ripe', 'Overripe']));
      expect(AppConstants.storageTips.length, greaterThanOrEqualTo(3));
      expect(AppConstants.modelInputSize, 224);
    });

    test('Nutrition map covers all classes', () {
      for (final label in AppConstants.labels) {
        expect(AppConstants.nutritionMap.containsKey(label), isTrue);
      }
    });
  });

  group('MangoAnalyzingOverlay Widget Tests', () {
    testWidgets('Renders holographic loading animation and updates progress phases', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MangoAnalyzingOverlay(
              totalDuration: Duration(milliseconds: 1000),
            ),
          ),
        ),
      );

      expect(find.text('AI NEURAL RIPENESS SCANNER'), findsOneWidget);
      expect(find.text('Detecting Mango Geometry'), findsOneWidget);
      expect(find.text('224x224 Tensor'), findsOneWidget);

      // Advance time half-way
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(MangoAnalyzingOverlay), findsOneWidget);

      // Advance to completion
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Ripeness Profile Ready'), findsOneWidget);
    });
  });
}
