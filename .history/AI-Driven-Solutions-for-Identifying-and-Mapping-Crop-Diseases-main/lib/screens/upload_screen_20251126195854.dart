import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- WIDGETS ---

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

/// Card to display the prediction results clearly.
class PredictionCard extends StatelessWidget {
  final File selectedImage;
  final String prediction;
  final double confidence;
  final VoidCallback onAnalyzeAnother;
  final VoidCallback onGenerateReport;

  const PredictionCard({
    required this.selectedImage,
    required this.prediction,
    required this.confidence,
    required this.onAnalyzeAnother,
    required this.onGenerateReport,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceString = (confidence * 100).toStringAsFixed(2);
    final theme = Theme.of(context);

    return Column(
      children: [
        // 1. Image Preview
        Card(
          elevation: 5,
          margin: const EdgeInsets.only(bottom: 20),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Image.file(
            selectedImage,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        
        // 2. Result Display Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                  prediction,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent, // Highlight the disease
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


// --- MAIN SCREEN STATE ---

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  String? prediction;
  double? confidence;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? img = await _picker.pickImage(source: source);

    if (img != null) {
      setState(() {
        _selectedImage = File(img.path);
        // Reset prediction when new image is selected
        prediction = null;
        confidence = null;
      });
    }
  }

  Future<void> analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      prediction = null;
      confidence = null;
    });

    // NOTE: Ensure your backend server is running and accessible at this IP
    final uri = Uri.parse("http://192.168.100.3:8000/predict");

    try {
      var request = http.MultipartRequest("POST", uri);
      request.files.add(
        await http.MultipartFile.fromPath("file", _selectedImage!.path),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);
        
        // Safety check for expected keys
        if (data.containsKey("prediction") && data.containsKey("confidence")) {
          setState(() {
            prediction = data["prediction"];
            confidence = data["confidence"];
          });
        } else {
           // Handle unexpected response structure
           _showErrorDialog("Error: Unexpected server response format.");
        }
      } else {
        // Handle non-200 status codes
        _showErrorDialog("Server Error: Status ${response.statusCode}");
      }
    } catch (e) {
      // Handle network/connection errors
      _showErrorDialog("Network Error: Could not connect to the server.");
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
  
  // Function to reset the screen to initial state
  void resetState() {
    setState(() {
      prediction = null;
      confidence = null;
      _selectedImage = null;
    });
  }
  
  // Placeholder function for the next step (Report generation)
  void generateReport() {
    // TODO: Implement PDF/Shareable Report Generation Logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating report... (Feature coming soon!)')),
    );
  }


  @override
  Widget build(BuildContext context) {
    final hasPrediction = prediction != null;
    final hasImage = _selectedImage != null;

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Image.file(_selectedImage!, height: 300, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: analyzeImage,
                    icon: const Icon(Icons.search),
                    label: const Text("Analyze Image"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50), // Make button full width
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
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
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
            if (hasPrediction && _selectedImage != null && confidence != null)
              PredictionCard(
                selectedImage: _selectedImage!,
                prediction: prediction!,
                confidence: confidence!,
                onAnalyzeAnother: resetState,
                onGenerateReport: generateReport, // Linked to the placeholder function
              ),
          ],
        ),
      ),
    );
  }
}
