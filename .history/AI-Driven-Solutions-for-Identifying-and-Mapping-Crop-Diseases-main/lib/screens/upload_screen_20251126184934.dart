import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/app_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/card_widget.dart';
import '../models/disease_report.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isAnalyzing = false;
  DiseaseReport? _analysisResult;
  String? _selectedImagePath;

  Future<void> _capturePhoto() async {
    // TODO: Implement camera capture
    _simulateImageSelection('Camera');
  }

  Future<void> _selectFromGallery() async {
    // TODO: Implement gallery selection
    _simulateImageSelection('Gallery');
  }

  void _simulateImageSelection(String source) {
    setState(() {
      _selectedImagePath = 'assets/images/sample_crop_${Random().nextInt(3) + 1}.jpg';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image selected from $source'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _analyzeImage() async {
    if (_selectedImagePath == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    // Simulate AI analysis
    await Future.delayed(const Duration(seconds: 3));

    // Generate mock analysis result
    final mockDiseases = [
      {
        'cropName': 'Maize',
        'diseaseName': 'Maize Leaf Blight',
        'confidence': 0.92,
        'severity': 'Medium',
        'treatmentSteps': [
          'Apply fungicide containing chlorothalonil',
          'Remove infected leaves immediately',
          'Improve air circulation around plants',
          'Avoid overhead watering',
          'Rotate crops next season',
        ],
      },
      {
        'cropName': 'Tomato',
        'diseaseName': 'Bacterial Blight',
        'confidence': 0.87,
        'severity': 'High',
        'treatmentSteps': [
          'Apply copper-based fungicide',
          'Remove and destroy infected plants',
          'Rotate crops next season',
          'Improve drainage',
          'Use disease-resistant varieties',
        ],
      },
      {
        'cropName': 'Rice',
        'diseaseName': 'Rice Rust',
        'confidence': 0.78,
        'severity': 'Low',
        'treatmentSteps': [
          'Apply propiconazole fungicide',
          'Reduce nitrogen fertilization',
          'Ensure proper water management',
          'Monitor for spread',
        ],
      },
    ];

    final randomDisease = mockDiseases[Random().nextInt(mockDiseases.length)];

    final report = DiseaseReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cropName: randomDisease['cropName'] as String,
      diseaseType: DiseaseType.leafSpot, // Mock type
      diseaseName: randomDisease['diseaseName'] as String,
      confidence: randomDisease['confidence'] as double,
      detectedAt: DateTime.now(),
      imagePath: _selectedImagePath,
      treatmentSteps: List<String>.from(randomDisease['treatmentSteps'] as List),
      severity: randomDisease['severity'] as String,
      location: 'Field ${Random().nextInt(5) + 1}',
    );

    setState(() {
      _isAnalyzing = false;
      _analysisResult = report;
    });

    // Add to reports
    context.read<AppProvider>().addDiseaseReport(report);
  }

  void _saveResult() {
    if (_analysisResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareWithExpert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing with agricultural expert...'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identify Crop Disease'),
        actions: [
          IconButton(
            onPressed: () => context.go('/reports'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Section
            if (_selectedImagePath == null && !_isAnalyzing && _analysisResult == null)
              _buildUploadSection(theme),
            
            // Image Preview
            if (_selectedImagePath != null && !_isAnalyzing && _analysisResult == null)
              _buildImagePreview(theme),
            
            // Analysis Loading
            if (_isAnalyzing)
              _buildAnalysisLoading(theme),
            
            // Analysis Result
            if (_analysisResult != null)
              _buildAnalysisResult(theme),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            if (_analysisResult != null) ...[
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Save Result',
                      onPressed: _saveResult,
                      icon: Icons.save,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Share Expert',
                      onPressed: _shareWithExpert,
                      isOutlined: true,
                      icon: Icons.share,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Analyze Another Image',
                onPressed: () {
                  setState(() {
                    _selectedImagePath = null;
                    _analysisResult = null;
                  });
                },
                isOutlined: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection(ThemeData theme) {
    return Column(
      children: [
        // Instructions
        CustomCard(
          child: Column(
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Upload Crop Image',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a clear photo of the affected plant part or select from gallery for AI analysis',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Upload Options
        Row(
          children: [
            Expanded(
              child: CustomCard(
                onTap: _capturePhoto,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 30,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Capture Photo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomCard(
                onTap: _selectFromGallery,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.photo_library,
                        size: 30,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select Gallery',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Column(
      children: [
        CustomCard(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Selected Image Preview',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Analyze Image',
                onPressed: _analyzeImage,
                icon: Icons.search,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImagePath = null;
                  });
                },
                child: const Text('Select Different Image'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisLoading(ThemeData theme) {
    return CustomCard(
      child: Column(
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing Crop Disease...',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI is examining your image to identify potential diseases',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(ThemeData theme) {
    final result = _analysisResult!;
    
    return Column(
      children: [
        // Result Header
        CustomCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getSeverityColor(result.severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: _getSeverityColor(result.severity),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.diseaseName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          result.cropName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(result.severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      result.severity,
                      style: TextStyle(
                        color: _getSeverityColor(result.severity),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    theme,
                    'Confidence',
                    result.confidencePercentage,
                    Icons.analytics,
                    theme.colorScheme.primary,
                  ),
                  _buildStatItem(
                    theme,
                    'Location',
                    result.location,
                    Icons.location_on,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    theme,
                    'Date',
                    '${result.detectedAt.day}/${result.detectedAt.month}',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Treatment Steps
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended Treatment',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...result.treatmentSteps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
