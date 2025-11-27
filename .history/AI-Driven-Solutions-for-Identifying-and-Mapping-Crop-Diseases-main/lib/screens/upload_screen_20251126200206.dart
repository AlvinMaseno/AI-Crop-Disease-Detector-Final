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
