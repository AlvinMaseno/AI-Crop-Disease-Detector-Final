import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:provider/provider.dart'; 
// --- PDF PACKAGES ---
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/app_provider.dart';
import '../models/disease_report_model.dart'; 

// ====================================================================
// HELPER FUNCTIONS 
// ====================================================================

String formatPredictionName(String rawName) {
  String cleanedName = rawName.replaceAll('__', ' ');
  cleanedName = cleanedName.replaceAll('_', ' ');
  return cleanedName.split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

String extractCropName(String rawName) {
  if (rawName.contains('__')) {
    String crop = rawName.split('__')[0];
    return crop.replaceAll('_', ' '); 
  }
  return "Unknown Crop";
}

String getSeverity(String rawDiseaseName) {
  final name = rawDiseaseName.toLowerCase();
  if (name.contains('healthy')) return 'Low';
  if (name.contains('miner') || name.contains('grasshoper') || name.contains('beetle') || name.contains('septoria') || name.contains('brown_spot')) {
    return 'Moderate';
  }
  return 'High';
}

String getTreatment(String rawDiseaseName) {
  final name = rawDiseaseName.toLowerCase();
  
  if (name.contains('healthy')) {
    return "✅ Your crop looks healthy! Continue with regular monitoring.\n• Ensure adequate watering.\n• Keep weeds under control.\n• Maintain soil nutrition.";
  }

  // --- CASHEW ---
  if (name.contains('cashew')) {
    if (name.contains('anthracnose')) return "1. Prune affected branches to improve airflow.\n2. Apply copper-based fungicides or Bordeaux mixture.\n3. Remove and burn infected plant debris.";
    if (name.contains('gumosis')) return "1. Improve drainage in the field.\n2. Scrape off the gum and apply Bordeaux paste.\n3. Apply copper oxychloride to the affected area.";
    if (name.contains('leaf_miner')) return "1. Encourage natural predators like weaver ants.\n2. Use sticky traps for adults.\n3. Apply neem oil or appropriate insecticides if infestation is high.";
    if (name.contains('red_rust')) return "1. Prune overcrowded branches to reduce humidity.\n2. Apply Bordeaux mixture or copper oxychloride.\n3. Ensure proper spacing between trees.";
  }

  // --- CASSAVA ---
  if (name.contains('cassava')) {
    if (name.contains('bacterial_blight')) return "1. Prune infected stems and burn them.\n2. Use resistant varieties.\n3. Sterilize farm tools to prevent spread.";
    if (name.contains('brown_spot')) return "1. Improve soil fertility (potassium helps).\n2. Apply fungicides if severe.\n3. Ensure wider spacing for better aeration.";
    if (name.contains('green_mite')) return "1. Introduce natural enemies (Typhlodromalus aripo).\n2. Spray water to dislodge mites.\n3. Use resistant varieties.";
    if (name.contains('mosaic')) return "1. Uproot (rogue) and burn infected plants immediately.\n2. Use only disease-free stem cuttings for planting.\n3. Control whiteflies (vectors) using traps.";
  }

  // --- CORN/MAIZE ---
  if (name.contains('corn') || name.contains('maize')) {
    if (name.contains('fall_armyworm')) return "1. Use pheromone traps to monitor.\n2. Apply 'Push-Pull' technology.\n3. Spray neem oil or biological agents like Bt.";
    if (name.contains('grasshoper')) return "1. Encourage natural predators (birds).\n2. Tilling soil destroys eggs.\n3. Use biological control agents like Metarhizium.";
    if (name.contains('leaf_beetle')) return "1. Remove weeds which serve as hosts.\n2. Handpick beetles in small plots.\n3. Use neem-based sprays.";
    if (name.contains('leaf_blight')) return "1. Plant resistant hybrids.\n2. Rotate with non-cereal crops.\n3. Apply fungicides like mancozeb early.";
    if (name.contains('leaf_spot')) return "1. Crop rotation is essential.\n2. Remove infected crop residues.\n3. Apply fungicides if economic threshold is reached.";
    if (name.contains('streak_virus')) return "1. Plant resistant varieties (most effective).\n2. Control leafhoppers which spread the virus.\n3. Plant early in the season.";
  }

  // --- TOMATO ---
  if (name.contains('tomato')) {
    if (name.contains('leaf_blight')) return "1. Apply copper or mancozeb fungicides.\n2. Avoid overhead irrigation.\n3. Stake plants to keep leaves off the ground.";
    if (name.contains('leaf_curl')) return "1. Control whiteflies using yellow sticky traps.\n2. Remove infected plants immediately.\n3. Use virus-resistant varieties.";
    if (name.contains('septoria')) return "1. Remove lower infected leaves.\n2. Mulch soil to prevent spore splash.\n3. Apply fungicides (chlorothalonil).";
    if (name.contains('verticulium') || name.contains('wilt')) return "1. No chemical cure exists; crop rotation is key (4+ years).\n2. Use resistant varieties (look for 'V' on seed packets).\n3. Soil solarization can help reduce fungus.";
  }

  return "Consult a local agricultural extension officer for specific advice on this condition.";
}

// ====================================================================
// WIDGETS
// ====================================================================

class SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const SelectionCard({required this.icon, required this.title, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10), child: Column(children: [Icon(icon, size: 50, color: Theme.of(context).primaryColor), const SizedBox(height: 10), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]))),
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

// ====================================================================
// MAIN SCREEN STATE
// ====================================================================

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
    // Replace with your real IP - CHECK THIS ON PRESENTATION DAY
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

        // FIREBASE SAVE
        await context.read<AppProvider>().addReport(report);

        setState(() { prediction = pred; confidence = conf; treatment = treat; });
      } else { _showError("Server Error: ${response.statusCode}"); }
    } catch (e) { _showError("Network Error: $e"); } 
    finally { setState(() => _isAnalyzing = false); }
  }

  void _showError(String msg) => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Error"), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]));

  void resetState() {
    setState(() {
      prediction = null;
      confidence = null;
      treatment = null;
      _selectedXFile = null;
    });
  }

  // --- REAL PDF GENERATION ---
  Future<void> generateReport() async {
    if (prediction == null || confidence == null || treatment == null) return;

    final doc = pw.Document();
    final displayPrediction = formatPredictionName(prediction!);
    final cropName = extractCropName(prediction!);
    final confidenceString = confidence!.toStringAsFixed(2);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text("Diagnostic Report", style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                   pw.Text("Crop Identified:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                   pw.Text(cropName, style: const pw.TextStyle(fontSize: 18)),
                ]),
                pw.SizedBox(height: 10),
                
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                   pw.Text("Disease Detected:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                   pw.Text(displayPrediction, style: pw.TextStyle(fontSize: 18, color: PdfColors.red)),
                ]),
                pw.SizedBox(height: 10),

                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                   pw.Text("Confidence:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                   pw.Text("$confidenceString%", style: const pw.TextStyle(fontSize: 18)),
                ]),

                pw.SizedBox(height: 30),
                pw.Text("Treatment Recommendation:", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                  child: pw.Text(treatment!, style: const pw.TextStyle(fontSize: 14, lineSpacing: 5)),
                ),
                
                pw.Spacer(),
                pw.Text("Generated by Crop Disease Detector", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                pw.Text(DateTime.now().toString(), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ]
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'diagnosis_${cropName}_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

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
            onGenerateReport: generateReport,
          ),
        ]),
      ),
    );
  }
}