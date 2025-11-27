// file: lib/models/disease_report_model.dart (Example)
class DiseaseReport {
  final String id;
  final String cropName; // e.g., 'Cassava'
  final String diseaseName; // e.g., 'Mossaic'
  final double confidencePercentage; // e.g., 99.85
  final String severity; // e.g., 'High', 'Low'
  final DateTime detectedAt;
  final String imagePath; // Local path or cloud URL of the analyzed image

  DiseaseReport({
    required this.id,
    required this.cropName,
    required this.diseaseName,
    required this.confidencePercentage,
    required this.severity,
    required this.detectedAt,
    required this.imagePath,
  });
}