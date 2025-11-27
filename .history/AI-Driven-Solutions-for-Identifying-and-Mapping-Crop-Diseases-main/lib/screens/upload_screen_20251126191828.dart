// upload_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'db_helper.dart'; // DB helper we'll add next
import 'report_model.dart'; // report model class
import 'reports_screen.dart'; // navigate after save

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  String? prediction;
  double? confidence; // interpreted as percent from API (e.g., 82.79)
  final ImagePicker _picker = ImagePicker();

  Future<void> pickFromCamera() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null) {
      setState(() {
        _selectedImage = File(img.path);
        prediction = null;
        confidence = null;
      });
    }
  }

  Future<void> pickFromGallery() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _selectedImage = File(img.path);
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

    // Replace with your PC IP & port already set (you said it's 192.168.100.3)
    final uri = Uri.parse("http://192.168.100.3:8000/predict");

    try {
      var request = http.MultipartRequest("POST", uri);
      request.files.add(
        await http.MultipartFile.fromPath("file", _selectedImage!.path),
      );

      final response = await request.send().timeout(const Duration(seconds: 30));
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);

      // Expectation: backend returns {"prediction": "X", "confidence": 82.79}
      setState(() {
        prediction = data["prediction"]?.toString();
        // Safely parse confidence
        final numConf = data["confidence"];
        if (numConf is int) {
          confidence = numConf.toDouble();
        } else if (numConf is double) {
          confidence = numConf;
        } else if (numConf is String) {
          confidence = double.tryParse(numConf) ?? 0.0;
        } else {
          confidence = 0.0;
        }
        _isAnalyzing = false;
      });

      // Save to local DB if we have a valid prediction
      if (prediction != null) {
        final now = DateTime.now();
        final report = ReportModel(
          id: null,
          disease: prediction!,
          confidence: confidence ?? 0.0,
          imagePath: _selectedImage!.path,
          createdAt: now.toIso8601String(),
        );
        await DBHelper.instance.insertReport(report);
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text("Identify Crop Disease"), actions: [
        IconButton(
          icon: const Icon(Icons.article_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            );
          },
          tooltip: "View reports",
        )
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selectedImage == null)
              Column(
                children: [
                  const Text(
                    "Upload a plant image to analyze",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Capture from Camera"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Select from Gallery"),
                  ),
                ],
              ),

            if (_selectedImage != null) ...[
              // Show selected image at top
              Image.file(_selectedImage!, height: 260, fit: BoxFit.contain),
              const SizedBox(height: 12),

              // If analyzing show spinner
              if (_isAnalyzing)
                const Column(
                  children: [
                    SizedBox(width: 70, height: 70, child: CircularProgressIndicator(strokeWidth: 4)),
                    SizedBox(height: 16),
                    Text("Analyzing image..."),
                  ],
                )
              else if (prediction == null)
                // Before analyzing but after image selected
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: analyzeImage,
                      icon: const Icon(Icons.search),
                      label: const Text("Analyze Image"),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      child: const Text("Choose another image"),
                    ),
                  ],
                )
              else
                // Display results below image
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      "Prediction Result",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text("Disease: $prediction", style: const TextStyle(fontSize: 18)),
                    Text("Confidence: ${confidence?.toStringAsFixed(2) ?? '0.00'}%", style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          prediction = null;
                          confidence = null;
                          _selectedImage = null;
                        });
                      },
                      child: const Text("Analyze Another Image"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                      },
                      child: const Text("View Reports"),
                    ),
                    const SizedBox(height: 8),
                    Text('Saved on ${df.format(DateTime.now())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
            ],
          ],
        ),
      ),
    );
  }
}
