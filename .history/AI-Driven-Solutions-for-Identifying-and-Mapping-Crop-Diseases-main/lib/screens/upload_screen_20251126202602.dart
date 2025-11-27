import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// ====================================================================
// HELPER FUNCTIONS (New)
// ====================================================================

/// Formats raw ML class names (e.g., 'Cassava__mossaic' to 'Cassava Mossaic').
String formatPredictionName(String rawName) {
  // 1. Replace double underscores with a space
  String cleanedName = rawName.replaceAll('__', ' ');
  // 2. Replace single underscores with a space
  cleanedName = cleanedName.replaceAll('_', ' ');

  // 3. Capitalize first letter of each word
  return cleanedName.split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

// ====================================================================
// WIDGETS FOR UI COMPONENTS
// ====================================================================

/// Card to prominently display image selection options.
class SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SelectionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

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
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to handle displaying images from XFile regardless of platform.
class ImagePreviewWidget extends StatelessWidget {
  final XFile selectedXFile;

  const ImagePreviewWidget({required this.selectedXFile, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: kIsWeb
          ? Image.network(
              selectedXFile.path, // On web, XFile.path is a temporary URL/blob
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Text("Cannot load image on web.")),
            )
          : Image.file(
              File(selectedXFile.path), // On mobile, XFile.path is a local path
              fit: BoxFit.cover,
            ),
    );
  }
}

/// Card to display the prediction results clearly.
class PredictionCard extends StatelessWidget {
  final XFile selectedXFile;
  final String prediction;
  final double confidence;
  final VoidCallback onAnalyzeAnother;
  final VoidCallback onGenerateReport;

  const PredictionCard({
    required this.selectedXFile,
    required this.prediction,
    required this.confidence,
    required this.onAnalyzeAnother,
    required this.onGenerateReport,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // FIX 1: Correctly format the confidence score (assuming it's scaled up by 100)
    // If confidence is 7914, this makes it 79.14
    final displayConfidenceValue = confidence / 100.0;
    final confidenceString = displayConfidenceValue.toStringAsFixed(2);

    // FIX 2: Format the prediction string
    final displayPrediction = formatPredictionName(prediction);

    final theme = Theme.of(context);

    return Column(
      children: [
        // 1. Image Preview
        Card(
          elevation: 5,
          margin: const EdgeInsets.only(bottom: 20),
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ImagePreviewWidget(selectedXFile: selectedXFile),
        ),

        // 2. Result Display Card
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🌿 Diagnosis Complete",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const Divider(height: 20),

                // Disease
                Text(
                  "Disease Identified:",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  // Use the formatted name here
                  displayPrediction,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 15),

                // Confidence
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Confidence Score:",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Text(
                  // Use the corrected confidence string here
                  "$confidenceString%",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // 3. Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            OutlinedButton.icon(
              onPressed: onGenerateReport,
              icon: const Icon(Icons.file_download),
              label: const Text("Generate Report"),
            ),
            ElevatedButton.icon(
              onPressed: onAnalyzeAnother,
              icon: const Icon(Icons.refresh),
              label: const Text("Analyze Another"),
            ),
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
  // Store the XFile (platform-agnostic) for API upload and display
  XFile? _selectedXFile;

  bool _isAnalyzing = false;
  String? prediction;
  double? confidence;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? img = await _picker.pickImage(source: source);

    if (img != null) {
      setState(() {
        _selectedXFile = img;
        prediction = null;
        confidence = null;
      });
    }
  }

  Future<void> analyzeImage() async {
    if (_selectedXFile == null) return;

    setState(() {
      _isAnalyzing = true;
      prediction = null;
      confidence = null;
    });

    final uri = Uri.parse("http://192.168.100.3:8000/predict");

    try {
      var request = http.MultipartRequest("POST", uri);

      if (kIsWeb) {
        // Web: Read bytes directly from XFile
        final bytes = await _selectedXFile!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            "file",
            bytes,
            filename: _selectedXFile!.name,
          ),
        );
      } else {
        // Mobile/Desktop: Use the path
        request.files.add(
          await http.MultipartFile.fromPath("file", _selectedXFile!.path),
        );
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);

        if (data.containsKey("prediction") && data.containsKey("confidence")) {
          setState(() {
            prediction = data["prediction"];
            // Ensure confidence is stored as a double
            confidence = data["confidence"].toDouble();
          });
        } else {
          _showErrorDialog("Error: Unexpected server response format.");
        }
      } else {
        _showErrorDialog("Server Error: Status ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Network Error: Could not connect to the server or: $e");
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
          TextButton(
            child: const Text("Okay"),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  void resetState() {
    setState(() {
      prediction = null;
      confidence = null;
      _selectedXFile = null;
    });
  }

  void generateReport() {
    // TODO: Implement PDF/Shareable Report Generation Logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Generating report... (Feature coming soon!)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPrediction = prediction != null;
    final hasImage = _selectedXFile != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Identify Crop Disease"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- STATE 1: INITIAL/SELECTION ---
            if (!hasImage && !hasPrediction)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upload a plant leaf image for diagnosis.",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "For best results, capture a clear, focused image of the affected area.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),

                  // Selection Options (Grid/Row)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: SelectionCard(
                          icon: Icons.camera_alt_rounded,
                          title: "Take Photo",
                          onTap: () => pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SelectionCard(
                          icon: Icons.photo_library_rounded,
                          title: "Choose from Gallery",
                          onTap: () => pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            // --- STATE 2: IMAGE PREVIEW / READY TO ANALYZE ---
            if (hasImage && !hasPrediction && !_isAnalyzing)
              Column(
                children: [
                  Card(
                    elevation: 5,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ImagePreviewWidget(selectedXFile: _selectedXFile!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: analyzeImage,
                    icon: const Icon(Icons.search),
                    label: const Text("Analyze Image"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  TextButton(
                    onPressed: resetState,
                    child: const Text("Choose another image"),
                  ),
                ],
              ),

            // --- STATE 3: ANALYZING (LOADING) ---
            if (_isAnalyzing)
              Column(
                children: [
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Analyzing leaf... Please wait.",
                    style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                  ),
                ],
              ),

            // --- STATE 4: RESULTS DISPLAY ---
            if (hasPrediction && _selectedXFile != null && confidence != null)
              PredictionCard(
                selectedXFile: _selectedXFile!,
                prediction: prediction!,
                confidence: confidence!,
                onAnalyzeAnother: resetState,
                onGenerateReport: generateReport,
              ),
          ],
        ),
      ),
    );
  }
}
