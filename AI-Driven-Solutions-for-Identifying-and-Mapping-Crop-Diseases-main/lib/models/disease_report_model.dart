import 'package:cloud_firestore/cloud_firestore.dart';

class DiseaseReport {
  final String id;
  final String diseaseName;
  final double confidencePercentage;
  final DateTime detectedAt;
  final String imagePath;
  final String severity;
  final String cropName;
  final String treatmentRecommendation;
  final bool isSynced; 

  DiseaseReport({
    required this.id,
    required this.diseaseName,
    required this.confidencePercentage,
    required this.detectedAt,
    required this.imagePath,
    required this.severity,
    required this.cropName,
    required this.treatmentRecommendation,
    this.isSynced = true, // Firestore data is always "synced"
  });

  // Helper for UI: "98.5%"
  String get formattedConfidence => '${confidencePercentage.toStringAsFixed(1)}%';

  String get severityEmoji {
    switch (severity.toLowerCase()) {
      case 'high': return '🔴';
      case 'moderate': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diseaseName': diseaseName,
      'confidencePercentage': confidencePercentage,
      // Save as Firestore Timestamp for correct sorting
      'detectedAt': Timestamp.fromDate(detectedAt), 
      'imagePath': imagePath,
      'severity': severity,
      'cropName': cropName,
      'treatmentRecommendation': treatmentRecommendation,
      'isSynced': isSynced,
    };
  }

  factory DiseaseReport.fromMap(Map<String, dynamic> map) {
    return DiseaseReport(
      id: map['id'] ?? '',
      diseaseName: map['diseaseName'] ?? 'Unknown',
      confidencePercentage: (map['confidencePercentage'] ?? 0).toDouble(),
      // Handle conversion from Firestore Timestamp to Dart DateTime
      detectedAt: map['detectedAt'] is Timestamp 
          ? (map['detectedAt'] as Timestamp).toDate() 
          : DateTime.parse(map['detectedAt'].toString()),
      imagePath: map['imagePath'] ?? '',
      severity: map['severity'] ?? 'Low',
      cropName: map['cropName'] ?? 'Crop',
      treatmentRecommendation: map['treatmentRecommendation'] ?? '',
      isSynced: map['isSynced'] ?? true,
    );
  }
}