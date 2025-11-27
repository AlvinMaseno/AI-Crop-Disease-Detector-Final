import 'dart:convert';

class DiseaseReport {
  final String id;
  final String diseaseName;
  final double confidencePercentage;
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

  String get formattedConfidence => '${confidencePercentage.toStringAsFixed(1)}%';

  String get severityEmoji {
    switch (severity.toLowerCase()) {
      case 'high': return '🔴';
      case 'moderate': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }

  // --- NEW: JSON Serialization ---

  // Convert a Report object to a Map (for JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diseaseName': diseaseName,
      'confidencePercentage': confidencePercentage,
      'detectedAt': detectedAt.toIso8601String(),
      'imagePath': imagePath,
      'severity': severity,
      'cropName': cropName,
      'treatmentRecommendation': treatmentRecommendation,
    };
  }

  // Create a Report object from a Map (from JSON)
  factory DiseaseReport.fromMap(Map<String, dynamic> map) {
    return DiseaseReport(
      id: map['id'],
      diseaseName: map['diseaseName'],
      confidencePercentage: map['confidencePercentage'],
      detectedAt: DateTime.parse(map['detectedAt']),
      imagePath: map['imagePath'],
      severity: map['severity'],
      cropName: map['cropName'],
      treatmentRecommendation: map['treatmentRecommendation'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DiseaseReport.fromJson(String source) => DiseaseReport.fromMap(json.decode(source));
}