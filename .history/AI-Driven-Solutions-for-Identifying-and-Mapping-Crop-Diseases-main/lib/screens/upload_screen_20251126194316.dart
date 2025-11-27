import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> pickFromCamera() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera);

    if (img != null) {
      setState(() {
        _selectedImage = File(img.path);
      });
    }
  }

  Future<void> pickFromGallery() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      setState(() {
        _selectedImage = File(img.path);
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

    final uri = Uri.parse("http://192.0.0.1:8000/predict");

    var request = http.MultipartRequest("POST", uri);
    request.files.add(
      await http.MultipartFile.fromPath("file", _selectedImage!.path),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = jsonDecode(resBody);

    setState(() {
      prediction = data["prediction"];
      confidence = data["confidence"];
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Identify Crop Disease"),
      ),
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
            if (_selectedImage != null && !_isAnalyzing && prediction == null)
              Column(
                children: [
                  Image.file(_selectedImage!, height: 200),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: analyzeImage,
                    icon: const Icon(Icons.search),
                    label: const Text("Analyze Image"),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    child: const Text("Choose another image"),
                  ),
                ],
              ),
            if (_isAnalyzing)
              const Column(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(strokeWidth: 4),
                  ),
                  SizedBox(height: 16),
                  Text("Analyzing image..."),
                ],
              ),
            if (prediction != null)
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Prediction Result",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Disease: $prediction",
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    "Confidence: ${(confidence! * 100).toStringAsFixed(2)}%",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
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
                ],
              ),
          ],
        ),
      ),
    );
  }
}
