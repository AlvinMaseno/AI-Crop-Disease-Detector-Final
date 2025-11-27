class DiseaseReport {
  final String id;
  final String diseaseName;
  final double confidencePercentage; // Stored as double (e.g. 98.5)
  final DateTime detectedAt;
  final String imagePath;
  final String severity;
  final String cropName;
  final String treatmentRecommendation;

  DiseaseReport({
    required this.id,
    required this.diseaseName,
    required this.confidencePercentage,
    required this.detectedAt,
    required this.imagePath,
    required this.severity,
    required this.cropName,
    required this.treatmentRecommendation,
  });

  // Helper used by HomeScreen to display "98.5%"
  String get formattedConfidence => '${confidencePercentage.toStringAsFixed(1)}%';

  // Helper used by HomeScreen for severity icons
  String get severityEmoji {
    switch (severity.toLowerCase()) {
      case 'high':
        return '🔴';
      case 'moderate':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }
}