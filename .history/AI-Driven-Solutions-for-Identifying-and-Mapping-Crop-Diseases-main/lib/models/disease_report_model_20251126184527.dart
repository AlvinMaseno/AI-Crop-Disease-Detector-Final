enum DiseaseType {
  bacterialBlight,
  leafSpot,
  rust,
  powderyMildew,
  anthracnose,
  mosaic,
  wilting,
  rot,
}

class DiseaseReport {
  final String id;
  final String cropName;
  final DiseaseType diseaseType;
  final String diseaseName;
  final double confidence;
  final DateTime detectedAt;
  final String? imagePath;
  final List<String> treatmentSteps;
  final String severity;
  final String location;

  const DiseaseReport({
    required this.id,
    required this.cropName,
    required this.diseaseType,
    required this.diseaseName,
    required this.confidence,
    required this.detectedAt,
    this.imagePath,
    required this.treatmentSteps,
    required this.severity,
    required this.location,
  });

  String get confidencePercentage => '${(confidence * 100).round()}%';

  String get severityEmoji {
    switch (severity.toLowerCase()) {
      case 'low':
        return '🟢';
      case 'medium':
        return '🟡';
      case 'high':
        return '🔴';
      default:
        return '⚪';
    }
  }

  factory DiseaseReport.fromJson(Map<String, dynamic> json) {
    return DiseaseReport(
      id: json['id'] as String,
      cropName: json['cropName'] as String,
      diseaseType: DiseaseType.values.firstWhere(
        (e) => e.toString() == 'DiseaseType.${json['diseaseType']}',
      ),
      diseaseName: json['diseaseName'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      imagePath: json['imagePath'] as String?,
      treatmentSteps: List<String>.from(json['treatmentSteps'] as List),
      severity: json['severity'] as String,
      location: json['location'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropName': cropName,
      'diseaseType': diseaseType.toString().split('.').last,
      'diseaseName': diseaseName,
      'confidence': confidence,
      'detectedAt': detectedAt.toIso8601String(),
      'imagePath': imagePath,
      'treatmentSteps': treatmentSteps,
      'severity': severity,
      'location': location,
    };
  }
}


