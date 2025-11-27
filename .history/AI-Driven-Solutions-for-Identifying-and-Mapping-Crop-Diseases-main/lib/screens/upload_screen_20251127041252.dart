import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:provider/provider.dart'; 
import '../providers/app_provider.dart';
import '../models/disease_report_model.dart'; 

// ====================================================================
// HELPER FUNCTIONS 
// ====================================================================

/// Formats raw ML class names (e.g., 'Cassava__mossaic' to 'Cassava Mossaic').
String formatPredictionName(String rawName) {
  String cleanedName = rawName.replaceAll('__', ' ');
  cleanedName = cleanedName.replaceAll('_', ' ');

  return cleanedName.split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

/// Extracts the Crop Name from the raw prediction string.
String extractCropName(String rawName) {
  if (rawName.contains('__')) {
    String crop = rawName.split('__')[0];
    return crop.replaceAll('_', ' '); 
  }
  return "Unknown Crop";
}

/// Calculates severity based on the specific disease type
String getSeverity(String rawDiseaseName) {
  final name = rawDiseaseName.toLowerCase();
  
  // 1. Healthy is always Low severity
  if (name.contains('healthy')) {
    return 'Low';
  }
  
  // 2. Manageable diseases are Moderate
  if (name.contains('miner') || 
      name.contains('grasshoper') || 
      name.contains('beetle') ||
      name.contains('septoria') ||
      name.contains('brown_spot')) {
    return 'Moderate';
  }
  
  // 3. Critical diseases are High (Default)
  return 'High';
}

/// Provides detailed treatment suggestions based on the specific diseases.
String getTreatment(String rawDiseaseName) {
  final name = rawDiseaseName.toLowerCase();
  
  // --- HEALTHY CASES ---
  if (name.contains('healthy')) {
    return "✅ Your crop looks healthy! Continue with regular monitoring.\n• Ensure adequate watering.\n• Keep weeds under control.\n• Maintain soil nutrition.";
  }

  // --- CASHEW DISEASES ---
  if (name.contains('cashew')) {
    if (name.contains('anthracnose')) {
      return "1. Prune affected branches to improve airflow.\n2. Apply copper-based fungicides or Bordeaux mixture.\n3. Remove and burn infected plant debris.";
    }
    if (name.contains('gumosis')) {
      return "1. Improve drainage in the field.\n2. Scrape off the gum and apply Bordeaux paste.\n3. Apply copper oxychloride to the affected area.";
    }
    if (name.contains('leaf_miner') || name.contains('leaf miner')) {
      return "1. Encourage natural predators like weaver ants.\n2. Use sticky traps for adults.\n3. Apply neem oil or appropriate insecticides if infestation is high.";
    }
    if (name.contains('red_rust')) {
      return "1. Prune overcrowded branches to reduce humidity.\n2. Apply Bordeaux mixture or copper oxychloride.\n3. Ensure proper spacing between trees.";
    }
  }

  // --- CASSAVA DISEASES ---
  if (name.contains('cassava')) {
    if (name.contains('bacterial_blight')) {
      return "1. Prune infected stems and burn them.\n2. Use resistant varieties.\n3. Sterilize farm tools to prevent spread.";
    }
    if (name.contains('brown_spot')) {
      return "1. Improve soil fertility (potassium helps).\n2. Apply fungicides if severe.\n3. Ensure wider spacing for better aeration.";
    }
    if (name.contains('green_mite')) {
      return "1. Introduce natural enemies (Typhlodromalus aripo).\n2. Spray water to dislodge mites.\n3. Use resistant varieties.";
    }
    if (name.contains('mosaic')) {
      return "1. Uproot (rogue) and burn infected plants immediately.\n2. Use only disease-free stem cuttings for planting.\n3. Control whiteflies (vectors) using traps.";
    }
  }

  // --- CORN (MAIZE) DISEASES ---
  if (name.contains('corn') || name.contains('maize')) {
    if (name.contains('fall_armyworm')) {
      return "1. Use pheromone traps to monitor.\n2. Apply 'Push-Pull' technology.\n3. Spray neem oil or biological agents like Bt.";
    }
    if (name.contains('grasshoper')) {
      return "1. Encourage natural predators (birds).\n2. Tilling soil destroys eggs.\n3. Use biological control agents like Metarhizium.";
    }
    if (name.contains('leaf_beetle')) {
      return "1. Remove weeds which serve as hosts.\n2. Handpick beetles in small plots.\n3. Use neem-based sprays.";
    }
    if (name.contains('leaf_blight')) {
      return "1. Plant resistant hybrids.\n2. Rotate with non-cereal crops.\n3. Apply fungicides like mancozeb early.";
    }
    if (name.contains('leaf_spot')) {
      return "1. Crop rotation is essential.\n2. Remove infected crop residues.\n3. Apply fungicides if economic threshold is reached.";
    }
    if (name.contains('streak_virus')) {
      return "1. Plant resistant varieties (most effective).\n2. Control leafhoppers which spread the virus.\n3. Plant early in the season.";
    }
  }

  // --- TOMATO DISEASES ---
  if (name.contains('tomato')) {
    if (name.contains('leaf_blight')) {
      return "1. Apply copper or mancozeb fungicides.\n2. Avoid overhead irrigation.\n3. Stake plants to keep leaves off the ground.";
    }
    if (name.contains('leaf_curl')) {
      return "1. Control whiteflies using yellow sticky traps.\n2. Remove infected plants immediately.\n3. Use virus-resistant varieties.";
    }
    if (name.contains('septoria')) {
      return "1. Remove lower infected leaves.\n2. Mulch soil to prevent spore splash.\n3. Apply fungicides (chlorothalonil).";
    }
    if (name.contains('verticulium') || name.contains('wilt')) {
      return "1. No chemical cure exists; crop rotation is key (4+ years).\n2. Use resistant varieties (look for 'V' on seed packets).\n3. Soil solarization can help reduce fungus.";
    }
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Theme.of(context).primaryColor),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class ImagePreviewWidget extends StatelessWidget {
  final XFile selectedXFile;
  const ImagePreviewWidget({required this.selectedXFile, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: kIsWeb
          ? Image.network(selectedXFile.path, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Center(child: Text("Cannot load image on web")))
          : Image.file(File(selectedXFile.path), fit: BoxFit.cover),
    );
  }
}

class PredictionCard extends StatelessWidget {
  final XFile selectedXFile;
  final String prediction;
  final double confidence;
  final String treatment;
  final VoidCallback onAnalyzeAnother;
  final VoidCallback onGenerateReport;

  const PredictionCard({
    required this.selectedXFile,
    required this.prediction,
    required this.confidence,
    required this.treatment,
    required this.onAnalyzeAnother,
    required this.onGenerateReport,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceString = confidence.toStringAsFixed(2);
    final displayPrediction = formatPredictionName(prediction);
    final cropName = extractCropName(prediction);

    return Column(
      children: [
        Card(
          elevation: 5,
          margin: const EdgeInsets.only(bottom: 20),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ImagePreviewWidget(selectedXFile: selectedXFile),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("🌿 Diagnosis Complete", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                    Chip(label: Text(cropName), backgroundColor: Colors.green[100]), 
                  ],
                ),
                const Divider(height: 20),
                Text("Disease Identified:", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                Text(displayPrediction, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                const SizedBox(height: 15),
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text("Confidence Score: $confidenceString%", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const Divider(height: 30, thickness: 1),
                Text("Treatment Recommendation:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                const SizedBox(height: 8),
                Text(treatment, style: const TextStyle(fontSize: 16, height: 1.4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            OutlinedButton.icon(onPressed: onGenerateReport, icon: const Icon(Icons.file_download), label: const Text("Generate Report")),
            ElevatedButton.icon(onPressed: onAnalyzeAnother, icon: const Icon(Icons.refresh), label: const Text("Analyze Another")),
          ],
        ),
      ],
    );
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
    if (img != null) {
      setState(() {
        _selectedXFile = img;
        prediction = null;
        confidence = null;
        treatment = null;
      });
    }
  }

  Future<void> analyzeImage() async {
    if (_selectedXFile == null) return;

    setState(() {
      _isAnalyzing = true;
      prediction = null;
      confidence = null;
      treatment = null;
    });

    final uri = Uri.parse("http://192.168.100.3:8000/predict");

    try {
      var request = http.MultipartRequest("POST", uri);
      
      if (kIsWeb) {
        final bytes = await _selectedXFile!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes("file", bytes, filename: _selectedXFile!.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath("file", _selectedXFile!.path));
      }
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);
        
        if (data.containsKey("prediction") && data.containsKey("confidence")) {
          final predictedName = data["prediction"];
          final confidenceScore = data["confidence"].toDouble();
          
          // 1. Get Treatment
          final recommendation = getTreatment(predictedName);
          
          // 2. Extract Crop Name
          final detectedCrop = extractCropName(predictedName);
          
          // 3. Calculate Severity
          final severity = getSeverity(predictedName);
          
          // 4. Create Report
          final newReport = DiseaseReport(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            diseaseName: formatPredictionName(predictedName),
            confidencePercentage: confidenceScore,
            detectedAt: DateTime.now(),
            imagePath: _selectedXFile!.path,
            severity: severity, 
            cropName: detectedCrop, 
            treatmentRecommendation: recommendation,
          );

          // 5. SAVE TO FIREBASE (Connected via Provider)
          await context.read<AppProvider>().addReport(newReport);

          setState(() {
            prediction = predictedName;
            confidence = confidenceScore;
            treatment = recommendation;
          });
        } else {
           _showErrorDialog("Error: Unexpected server response format.");
        }
      } else {
        _showErrorDialog("Server Error: Status ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Network Error. Check your server connection.\nDetails: $e");
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Analysis Failed"),
        content: Text(message),
        actions: <Widget>[
          TextButton(child: const Text("Okay"), onPressed: () => Navigator.of(ctx).pop())
        ],
      ),
    );
  }

  void resetState() {
    setState(() {
      prediction = null;
      confidence = null;
      treatment = null;
      _selectedXFile = null;
    });
  }

  void generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF report... (Feature coming soon!)')));
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = prediction != null && treatment != null;
    final hasImage = _selectedXFile != null;

    return Scaffold(
      appBar: AppBar(title: const Text("Identify Crop Disease")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!hasImage && !hasResult)
              Column(
                children: [
                   const Text("Upload a plant leaf image for diagnosis.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 30),
                   Row(children: [
                     Expanded(child: SelectionCard(icon: Icons.camera_alt, title: "Camera", onTap: () => pickImage(ImageSource.camera))),
                     const SizedBox(width: 16),
                     Expanded(child: SelectionCard(icon: Icons.photo_library, title: "Gallery", onTap: () => pickImage(ImageSource.gallery))),
                   ]),
                ],
              ),
            
            if (hasImage && !hasResult && !_isAnalyzing)
              Column(
                children: [
                  Card(elevation: 5, child: ImagePreviewWidget(selectedXFile: _selectedXFile!)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: analyzeImage, 
                    icon: const Icon(Icons.search), 
                    label: const Text("Analyze Image"),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  ),
                  TextButton(onPressed: resetState, child: const Text("Choose another image")),
                ],
              ),

            if (_isAnalyzing)
               const Column(children: [
                 SizedBox(height: 50),
                 CircularProgressIndicator(strokeWidth: 5),
                 SizedBox(height: 24),
                 Text("Analyzing leaf...", style: TextStyle(fontSize: 18)),
               ]),

            if (hasResult)
              PredictionCard(
                selectedXFile: _selectedXFile!,
                prediction: prediction!,
                confidence: confidence!,
                treatment: treatment!, // Pass the full treatment text
                onAnalyzeAnother: resetState,
                onGenerateReport: generateReport, 
              ),
          ],
        ),
      ),
    );
  }
}