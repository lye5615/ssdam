class OCRResult {
  final String text;
  final String category;
  final double confidence;
  final List<String> tags;
  final String reasoning;
  final List<String> textHints; // Extracted keywords for Rule Engine

  OCRResult({
    required this.text,
    required this.category,
    required this.confidence,
    required this.tags,
    required this.reasoning,
    this.textHints = const [],
  });
}
