import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:provider/provider.dart'; 
import '../providers/app_provider.dart';
import '../models/disease_report_model.dart'; 

// --- HELPERS ---
String formatPredictionName(String rawName) {
  String cleanedName = rawName.replaceAll('__', ' ').replaceAll('_', ' ');
  return cleanedName.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '').join(' ');
}

String extractCropName(String rawName) {
  if (rawName.contains('__')) return rawName.split('__')[0].replaceAll('_', ' ');
  return "Unknown Crop";
}

String getSeverity(String rawDiseaseName) {
  final name = rawDiseaseName.toLowerCase();
  if (name.contains('healthy')) return 'Low';
  if (name.contains('miner') || name.contains('grasshoper') || name.contains('beetle') || name.contains('septoria')) return 'Moderate';
  return 'High';
}

String getTreatment(String rawDiseaseName) {
  // (Keep your long getTreatment logic here - simplified for brevity but paste your full version)
  final name = rawDiseaseName.toLowerCase();
  if (name.contains('healthy')) return "✅ Your crop looks healthy! Continue regular care.";
  return "Consult a local agricultural extension officer or verify specific disease treatment.";
}

// --- WIDGETS ---
class SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const SelectionCard({required this.icon, required this.title, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [Icon(icon, size: 50, color: Theme.of(context).primaryColor), const SizedBox(height: 10), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]))),
    );
  }
}

class ImagePreviewWidget extends StatelessWidget {
  final XFile selectedXFile;
  const ImagePreviewWidget({required this.selectedXFile, super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 300, width: double.infinity, child: kIsWeb ? Image.network(selectedXFile.path, fit: BoxFit.cover) : Image.file(File(selectedXFile.path), fit: BoxFit.cover));
  }
}

class PredictionCard extends StatelessWidget {
  final XFile selectedXFile;
  final String prediction;
  final double confidence;
  final String treatment;
  final VoidCallback onAnalyzeAnother;
  final VoidCallback onGenerateReport;
  const PredictionCard({required this.selectedXFile, required this.prediction, required this.confidence, required this.treatment, required this.onAnalyzeAnother, required this.onGenerateReport, super.key});
  @override
  Widget build(BuildContext context) {
    final cropName = extractCropName(prediction);
    return Column(children: [
      Card(elevation: 5, clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ImagePreviewWidget(selectedXFile: selectedXFile)),
      Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("🌿 Diagnosis Complete", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
          Chip(label: Text(cropName), backgroundColor: Colors.green[100]),
        ]),
        const Divider(height: 20),
        Text("Disease: ${formatPredictionName(prediction)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.redAccent)),
        const SizedBox(height: 10),
        Text("Confidence: ${confidence.toStringAsFixed(2)}%", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(height: 30),
        Text("Treatment:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
        Text(treatment, style: const TextStyle(fontSize: 16, height: 1.4)),
      ]))),
      const SizedBox(height: 30),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        OutlinedButton.icon(onPressed: onGenerateReport, icon: const Icon(Icons.file_download), label: const Text("Report")),
        ElevatedButton.icon(onPressed: onAnalyzeAnother, icon: const Icon(Icons.refresh), label: const Text("Analyze Another")),
      ]),
    ]);
  }
}

// --- STATE ---
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  XFile? _selectedXFile;
  bool _isAnalyzing = false;
  String? prediction;
  double? confidence;
  String? treatment;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? img = await _picker.pickImage(source: source);
    if (img != null) setState(() { _selectedXFile = img; prediction = null; });
  }

  Future<void> analyzeImage() async {
    if (_selectedXFile == null) return;
    setState(() { _isAnalyzing = true; prediction = null; });
    // Replace with your real IP
    final uri = Uri.parse("http://192.168.100.3:8000/predict"); 
    try {
      var request = http.MultipartRequest("POST", uri);
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes("file", await _selectedXFile!.readAsBytes(), filename: _selectedXFile!.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath("file", _selectedXFile!.path));
      }
      final response = await request.send();
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        final pred = data["prediction"];
        final conf = data["confidence"].toDouble();
        final treat = getTreatment(pred);
        final crop = extractCropName(pred);
        final sev = getSeverity(pred);

        final report = DiseaseReport(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          diseaseName: formatPredictionName(pred),
          confidencePercentage: conf,
          detectedAt: DateTime.now(),
          imagePath: _selectedXFile!.path,
          severity: sev,
          cropName: crop,
          treatmentRecommendation: treat,
        );

        // FIREBASE UPLOAD
        await context.read<AppProvider>().addReport(report);

        setState(() { prediction = pred; confidence = conf; treatment = treat; });
      } else { _showError("Server Error: ${response.statusCode}"); }
    } catch (e) { _showError("Network Error: $e"); } 
    finally { setState(() => _isAnalyzing = false); }
  }

  void _showError(String msg) => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Error"), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]));

  @override
  Widget build(BuildContext context) {
    final hasResult = prediction != null;
    return Scaffold(
      appBar: AppBar(title: const Text("Identify Crop Disease")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (_selectedXFile == null) ...[
            const Text("Upload image for diagnosis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: SelectionCard(icon: Icons.camera_alt, title: "Camera", onTap: () => pickImage(ImageSource.camera))),
              const SizedBox(width: 16),
              Expanded(child: SelectionCard(icon: Icons.photo_library, title: "Gallery", onTap: () => pickImage(ImageSource.gallery))),
            ]),
          ],
          if (_selectedXFile != null && !hasResult && !_isAnalyzing) ...[
            Card(elevation: 5, child: ImagePreviewWidget(selectedXFile: _selectedXFile!)),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: analyzeImage, icon: const Icon(Icons.search), label: const Text("Analyze Image")),
            TextButton(onPressed: () => setState(() => _selectedXFile = null), child: const Text("Choose another")),
          ],
          if (_isAnalyzing) const CircularProgressIndicator(),
          if (hasResult) PredictionCard(
            selectedXFile: _selectedXFile!, 
            prediction: prediction!, 
            confidence: confidence!, 
            treatment: treatment!, 
            onAnalyzeAnother: () => setState(() { _selectedXFile = null; prediction = null; }),
            onGenerateReport: () {},
          ),
        ]),
      ),
    );
  }
}