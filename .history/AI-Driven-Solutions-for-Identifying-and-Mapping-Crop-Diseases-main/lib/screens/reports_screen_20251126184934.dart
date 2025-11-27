import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/card_widget.dart';
import '../widgets/custom_button.dart';
import '../models/disease_report.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = ['All', 'High', 'Medium', 'Low'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DiseaseReport> _getFilteredReports() {
    final appProvider = context.read<AppProvider>();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Reports'),
        actions: [
          IconButton(
            onPressed: () => context.go('/upload'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
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
                          selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected 
                                ? theme.colorScheme.primary 
                                : Colors.grey.shade700,
                            fontWeight: isSelected 
                                ? FontWeight.w600 
                                : FontWeight.normal,
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
            child: Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                final filteredReports = _getFilteredReports();
                
                if (filteredReports.isEmpty) {
                  return _buildEmptyState(theme);
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    // Simulate refresh
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return DiseaseReportCard(
                        cropName: report.cropName,
                        diseaseName: report.diseaseName,
                        confidence: report.confidencePercentage,
                        severity: report.severity,
                        date: report.detectedAt,
                        onTap: () => _showReportDetails(report),
                      );
                    },
                  ),
                );
              },
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
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
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
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getSeverityColor(report.severity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCropIcon(report.cropName),
                        color: _getSeverityColor(report.severity),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.diseaseName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            report.cropName,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
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
              
              // Content
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
                            _buildStatItem(
                              'Confidence',
                              report.confidencePercentage,
                              Icons.analytics,
                              Theme.of(context).colorScheme.primary,
                            ),
                            _buildStatItem(
                              'Location',
                              report.location,
                              Icons.location_on,
                              Colors.orange,
                            ),
                            _buildStatItem(
                              'Date',
                              '${report.detectedAt.day}/${report.detectedAt.month}/${report.detectedAt.year}',
                              Icons.calendar_today,
                              Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Treatment Steps
                      Text(
                        'Recommended Treatment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ...report.treatmentSteps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(14),
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
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Share Report',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sharing report...'),
                                  ),
                                );
                              },
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Report deleted'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
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

  IconData _getCropIcon(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'maize':
      case 'corn':
        return Icons.grass;
      case 'tomato':
        return Icons.local_pizza;
      case 'rice':
        return Icons.water_drop;
      case 'wheat':
        return Icons.eco;
      default:
        return Icons.agriculture;
    }
  }
}


