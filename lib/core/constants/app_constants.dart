class AppConstants {
  static const String appName = 'MangoAI';
  static const String appTagline = 'Smart Mango Ripeness Detector';

  // Hive Box Names
  static const String scanHistoryBox = 'scan_history_box';

  // ML Model Config
  static const String modelPath = 'assets/models/mango_classifier.tflite';
  static const String labelsPath = 'assets/models/labels.txt';
  static const int modelInputSize = 224;

  // Ripeness Labels (Matching dataset / labels.txt)
  static const List<String> labels = [
    'Unripe',
    'Partially Ripe',
    'Fully Ripe',
    'Overripe',
  ];

  // Storage Tips
  static const List<String> storageTips = [
    'Keep unripe mangos at room temperature (20-25°C) away from direct sunlight.',
    'Place unripe mango in a paper bag with an apple or banana to accelerate natural ripening via ethylene gas.',
    'Refrigerate fully ripe mangos at 4-7°C to slow down further ripening and preserve freshness for up to 5 days.',
    'Cut ripe mangos can be stored in an airtight container in the refrigerator for up to 3 days.',
    'Never refrigerate unripe mangos as temperatures below 10°C permanently halt the ripening process and cause chilling injury.',
  ];

  // Shelf life descriptions by stage
  static const Map<String, String> shelfLifeMap = {
    'Unripe': '7 - 14 days at room temperature',
    'Partially Ripe': '3 - 5 days at room temperature',
    'Fully Ripe': '1 - 3 days (up to 5 days refrigerated)',
    'Overripe': 'Consume immediately or freeze for smoothies',
  };

  // Quality recommendations by stage
  static const Map<String, String> recommendationMap = {
    'Unripe': 'Firm with high acidity. Excellent for green mango salads, pickling, amchur powder, or sour chutneys.',
    'Partially Ripe': 'Firm with emerging sweetness and tropical notes. Great for mango salsa, spicy dips, grilling, or tangy snacking.',
    'Fully Ripe': 'Peak sweetness, rich floral aroma, and juicy tender pulp! Best enjoyed fresh, in desserts, smoothies, lassi, or ice cream.',
    'Overripe': 'Extremely soft with high concentrated sugar content. Best utilized right away for mango puree, jams, coulis, smoothies, or baking.',
  };

  // Nutritional Profile by stage
  static const Map<String, Map<String, String>> nutritionMap = {
    'Unripe': {
      'Vitamin C': 'Very High (130% DV)',
      'Sugar': 'Low (approx 8g/100g)',
      'Fiber': 'High Pectin Content',
      'Acidity': 'High (Citric & Malic acid)',
    },
    'Partially Ripe': {
      'Vitamin C': 'High (90% DV)',
      'Sugar': 'Moderate (11g/100g)',
      'Fiber': 'Medium Pectin',
      'Carotenoids': 'Developing',
    },
    'Fully Ripe': {
      'Vitamin A': 'Very High (Beta-carotene)',
      'Vitamin C': 'Optimal (67% DV)',
      'Sugar': 'Natural Fructose (14g/100g)',
      'Antioxidants': 'Peak Mangiferin & Polyphenols',
    },
    'Overripe': {
      'Sugar': 'High Natural Sugar (>16g/100g)',
      'Antioxidants': 'High Polyphenol Breakdown',
      'Digestibility': 'Very Easy on Digestion',
      'Energy': 'Quick Glycemic Energy Source',
    },
  };
}
