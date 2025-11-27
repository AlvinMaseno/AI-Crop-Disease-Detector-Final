import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; // Import for platform check

// ... (Keep SelectionCard and PredictionCard widgets as they are) ...

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  // --- UPDATED STATE VARIABLES ---
  // Store the XFile (platform-agnostic) for API upload
  XFile? _selectedXFile; 
  // Store the actual File (only used on mobile/desktop)
  File? _selectedFile; 
  
  bool _isAnalyzing = false;
  String? prediction;
  double? confidence;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? img = await _picker.pickImage(source: source);

    if (img != null) {
      setState(() {
        _selectedXFile = img;
        
        // --- PLATFORM-SPECIFIC HANDLING ---
        if (!kIsWeb) {
          // If NOT on web, we can safely create a File object for Image.file
          _selectedFile = File(img.path);
        } else {
          // If ON web, we just use the XFile's path (which is a temporary URL)
          // or its bytes for display/upload. We leave _selectedFile as null.
          _selectedFile = null;
        }

        prediction = null;
        confidence = null;
      });
    }
  }

  Future<void> analyzeImage() async {
    // Use the XFile for the upload logic
    if (_selectedXFile == null) return; 

    setState(() {
      _isAnalyzing = true;
      prediction = null;
      confidence = null;
    });

    final uri = Uri.parse("http://192.168.100.3:8000/predict");

    try {
      var request = http.MultipartRequest("POST", uri);
      
      // --- CRITICAL CHANGE FOR WEB UPLOAD ---
      // We read the bytes from the XFile and use MultipartFile.fromBytes
      if (kIsWeb) {
        final bytes = await _selectedXFile!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            "file", 
            bytes, 
            filename: _selectedXFile!.name,
          ),
        );
      } else {
        // Mobile/Desktop can still use the path
        request.files.add(
          await http.MultipartFile.fromPath("file", _selectedXFile!.path),
        );
      }
      
      final response = await request.send();
      // ... (rest of your analysis logic) ...
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);
        
        if (data.containsKey("prediction") && data.containsKey("confidence")) {
          setState(() {
            prediction = data["prediction"];
            confidence = data["confidence"];
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
  
  // ... (Keep _showErrorDialog, resetState, generateReport functions) ...

  @override
  Widget build(BuildContext context) {
    final hasPrediction = prediction != null;
    // Check if we have an XFile selected
    final hasImage = _selectedXFile != null; 

    return Scaffold(
      appBar: AppBar(
        title: const Text("Identify Crop Disease"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ... (STATE 1: INITIAL/SELECTION - No changes needed) ...
            if (!hasImage && !hasPrediction)
              // ... (Your selection UI here) ...

            // --- STATE 2: IMAGE PREVIEW / READY TO ANALYZE (UPDATED) ---
            if (hasImage && !hasPrediction && !_isAnalyzing)
              Column(
                children: [
                  Card(
                    elevation: 5,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: **ImagePreviewWidget(selectedXFile: _selectedXFile!)**, // Using the new widget
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

            // ... (STATE 3: ANALYZING - No changes needed) ...
            
            // --- STATE 4: RESULTS DISPLAY (UPDATED) ---
            if (hasPrediction && _selectedXFile != null && confidence != null)
              PredictionCard(
                // Pass either the File (mobile) or use a platform-aware display logic
                selectedImage: _selectedFile ?? File(_selectedXFile!.path), // This still needs refinement for web display
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
// Widget to handle displaying images from XFile regardless of platform
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