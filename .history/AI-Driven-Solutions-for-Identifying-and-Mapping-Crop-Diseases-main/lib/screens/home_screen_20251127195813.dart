import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// --- ADDED PDF IMPORTS ---
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/app_provider.dart';
import '../models/disease_report_model.dart';
import '../widgets/real_weather_widget.dart';
import '../widgets/card_widget.dart'; 
import '../widgets/custom_button.dart';
import 'reports_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const _ReportsTab(),
    const _CommunityTab(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/upload'), 
              label: Text(context.watch<AppProvider>().translate('diagnoseCrop')),
              icon: const Icon(Icons.camera_alt_rounded),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: context.watch<AppProvider>().translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment),
            label: context.watch<AppProvider>().translate('reports'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: context.watch<AppProvider>().translate('community'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: context.watch<AppProvider>().translate('profile'),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  // --- 1. DETAILS MODAL LOGIC (Copied from ReportsScreen) ---
  void _showReportDetails(BuildContext context, DiseaseReport report) {
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
              Column(
                children: [
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: _getSeverityColor(report.severity).withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Center(child: Text(report.severityEmoji, style: const TextStyle(fontSize: 24))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(report.diseaseName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              Text(report.cropName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(context, 'Confidence', report.formattedConfidence, Icons.analytics, Theme.of(context).primaryColor),
                                _buildStatItem(context, 'Severity', report.severity, Icons.warning_amber_rounded, Colors.orange),
                                _buildStatItem(context, 'Date', '${report.detectedAt.day}/${report.detectedAt.month}/${report.detectedAt.year}', Icons.calendar_today, Colors.blue),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Recommended Treatment', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                            child: Text(report.treatmentRecommendation, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                          ),
                          const SizedBox(height: 32),
                          Row(
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

  Future<void> _handleDownloadSingleReport(DiseaseReport report) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (pw.Context context) {
      return pw.Center(
        child: pw.Column(children: [
          pw.Text(report.diseaseName, style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text("Treatment Recommendation:"),
          pw.Text(report.treatmentRecommendation),
        ])
      );
    }));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'report_${report.cropName}.pdf');
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
    ]);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return Colors.red;
      case 'moderate': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            final userName = appProvider.currentUser?.name.split(' ')[0] ?? 'User';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${appProvider.translate('hello')}, $userName 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF616161))),
              ],
            );
          },
        ),
        toolbarHeight: 80,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications')));
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_outlined, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RealWeatherWidget(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text('Overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  final reports = appProvider.diseaseReports;
                  final total = reports.length;
                  final critical = reports.where((r) => r.severity == 'High').length;
                  final healthy = reports.where((r) => r.severity == 'Low').length;

                  return Row(
                    children: [
                      Expanded(child: _buildStatCard(theme, 'Total Scans', '$total', Icons.qr_code_scanner, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(theme, 'Healthy', '$healthy', Icons.check_circle_outline, Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(theme, 'Critical', '$critical', Icons.warning_amber_rounded, Colors.red)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Reports', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () => context.go('/reports'), child: Text('View All', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                final reports = appProvider.diseaseReports;
                final recentReports = reports.take(3).toList();

                if (recentReports.isEmpty) {
                  return CustomCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No reports yet', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('Tap the Diagnose button below to start.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentReports.length,
                  itemBuilder: (context, index) {
                    final report = recentReports[index];
                    return DiseaseReportCard(
                      cropName: report.cropName,
                      diseaseName: report.diseaseName,
                      confidence: report.formattedConfidence,
                      severity: report.severity,
                      date: report.detectedAt,
                      // --- UPDATED ONTAP ---
                      onTap: () => _showReportDetails(context, report),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Daily Tips', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            CustomCard(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.lightbulb_outline, color: theme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Regular Monitoring', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text('Check crops daily for early signs.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: Text('💡 Tip: Early detection can save up to 70% of your crop yield.', style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
          Text(title, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();
  @override
  Widget build(BuildContext context) {
    return const ReportsScreen();
  }
}

class _CommunityTab extends StatelessWidget {
  const _CommunityTab();
  @override
  Widget build(BuildContext context) {
    return const CommunityScreen();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}