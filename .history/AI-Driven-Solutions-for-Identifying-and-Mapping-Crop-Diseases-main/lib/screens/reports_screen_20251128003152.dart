import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// PDF and Printing packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/app_provider.dart';
import '../widgets/card_widget.dart'; 
import '../widgets/custom_button.dart'; 
import '../models/disease_report_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = ['All', 'High', 'Moderate', 'Low'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DiseaseReport> _getFilteredReports() {
    final appProvider = context.watch<AppProvider>();
    List<DiseaseReport> reports = appProvider.diseaseReports;

    // Filter by severity
    if (_selectedFilter != 'All') {
      reports = reports.where((report) => 
        report.severity.toLowerCase() == _selectedFilter.toLowerCase()
      ).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      reports = reports.where((report) =>
        report.diseaseName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        report.cropName.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return reports;
  }

  // --- PDF GENERATION: ALL REPORTS ---
  Future<void> _handleDownloadReports() async {
    final appProvider = context.read<AppProvider>();
    final reports = appProvider.diseaseReports;

    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No reports to download.')),
      );
      return;
    }

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Crop Disease Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateTime.now().toString().split(' ')[0]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft, 2: pw.Alignment.centerLeft, 3: pw.Alignment.center, 4: pw.Alignment.center,
              },
              headers: <String>['Date', 'Crop', 'Disease', 'Severity', 'Conf.'],
              data: reports.map((report) {
                final date = '${report.detectedAt.day}/${report.detectedAt.month}/${report.detectedAt.year}';
                return [date, report.cropName, report.diseaseName, report.severity, report.formattedConfidence];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Total Reports: ${reports.length}"),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'crop_disease_reports.pdf');
  }

  // --- PDF GENERATION: SINGLE REPORT ---
  Future<void> _handleDownloadSingleReport(DiseaseReport report) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (pw.Context context) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(level: 0, child: pw.Text("Diagnostic Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            pw.Text("Disease: ${report.diseaseName}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text("Crop: ${report.cropName}", style: const pw.TextStyle(fontSize: 16)),
            pw.Text("Severity: ${report.severity}", style: const pw.TextStyle(fontSize: 16)),
            pw.Text("Confidence: ${report.formattedConfidence}", style: const pw.TextStyle(fontSize: 16)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text("Treatment Recommendation:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(report.treatmentRecommendation, style: const pw.TextStyle(fontSize: 14)),
          ]
        ),
      );
    }));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'report_${report.cropName}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredReports = _getFilteredReports();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Reports'),
        actions: [
          IconButton(
            onPressed: _handleDownloadReports,
            icon: const Icon(Icons.download_rounded),
            tooltip: "Download PDF",
          ),
          IconButton(
            onPressed: () => context.push('/upload'),
            icon: const Icon(Icons.add),
            tooltip: "New Diagnosis",
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Area
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search diseases or crops...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: theme.primaryColor.withOpacity(0.2),
                          checkmarkColor: theme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? theme.primaryColor : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Reports List
          Expanded(
            child: filteredReports.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        return DiseaseReportCard(
                          cropName: report.cropName,
                          diseaseName: report.diseaseName,
                          confidence: report.formattedConfidence, 
                          severity: report.severity,
                          date: report.detectedAt,
                          onTap: () => _showReportDetails(report),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'No reports found'
                  : 'No reports yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'Try adjusting your search or filter criteria'
                  : 'Start by uploading an image to detect crop diseases',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty && _selectedFilter == 'All')
              CustomButton(
                text: 'Upload First Image',
                onPressed: () => context.go('/upload'),
                icon: Icons.camera_alt,
              )
            else
              CustomButton(
                text: 'Clear Filters',
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'All';
                  });
                },
                isOutlined: true,
              ),
          ],
        ),
      ),
    );
  }

  void _showReportDetails(DiseaseReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            children: [
              // Content
              Column(
                children: [
                  const SizedBox(height: 40), // Spacer for close button
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: _getSeverityColor(report.severity).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(report.severityEmoji, style: const TextStyle(fontSize: 24))),
                        ),
                        const SizedBox(width: 16),
                        Expanded( // FIX 1: Allow Text to take up remaining space
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(report.diseaseName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              Text(report.cropName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(report.severity).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            report.severity,
                            style: TextStyle(
                              color: _getSeverityColor(report.severity),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Scrollable Details
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // FIX 2: Ensure stat items use Expanded internally or are wrapped
                                Expanded(child: _buildStatItem(context, 'Confidence', report.formattedConfidence, Icons.analytics, Theme.of(context).primaryColor)),
                                Expanded(child: _buildStatItem(context, 'Severity', report.severity, Icons.warning_amber_rounded, Colors.orange)),
                                Expanded(child: _buildStatItem(context, 'Date', '${report.detectedAt.day}/${report.detectedAt.month}/${report.detectedAt.year}', Icons.calendar_today, Colors.blue)),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Treatment
                          Text('Recommended Treatment', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                            child: Text(report.treatmentRecommendation, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Actions
                          Row(
                            // FIX 3: Ensure action buttons use Expanded
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Share Report',
                                  onPressed: () => _handleDownloadSingleReport(report),
                                  isOutlined: true,
                                  icon: Icons.share,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomButton(
                                  text: 'Delete',
                                  onPressed: () {
                                    context.read<AppProvider>().deleteDiseaseReport(report.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted'), backgroundColor: Colors.red));
                                  },
                                  backgroundColor: Colors.red,
                                  icon: Icons.delete,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Handle Bar and Close Button (Positioned on top of content)
              Positioned(
                top: 12, left: 0, right: 0,
                child: Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ),
              ),
              Positioned(
                top: 10, right: 10,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods (_buildStatItem, _getSeverityColor, _handleDownloadSingleReport) are unchanged
  // ... (Keeping them for brevity, but they are defined correctly in your file) ...
  
  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    // This item needs its content centered, but its parent needs to be Expanded (which we did above)
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return Colors.red;
      case 'moderate': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _handleDownloadSingleReport(DiseaseReport report) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (pw.Context context) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(level: 0, child: pw.Text("Diagnostic Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            pw.Text("Disease: ${report.diseaseName}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text("Crop: ${report.cropName}", style: const pw.TextStyle(fontSize: 16)),
            pw.Text("Severity: ${report.severity}", style: const pw.TextStyle(fontSize: 16)),
            pw.Text("Confidence: ${report.formattedConfidence}", style: const pw.TextStyle(fontSize: 16)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text("Treatment Recommendation:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(report.treatmentRecommendation, style: const pw.TextStyle(fontSize: 14)),
          ]
        ),
      );
    }));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'report_${report.cropName}.pdf');
  }
}