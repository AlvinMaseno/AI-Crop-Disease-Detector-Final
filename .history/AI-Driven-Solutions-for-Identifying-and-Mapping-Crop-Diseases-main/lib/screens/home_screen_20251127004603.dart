import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // You might need to add intl package, or use basic date formatting
import '../providers/app_provider.dart';
// Ensure these paths match your project structure
import '../widgets/real_weather_widget.dart';
import '../widgets/card_widget.dart'; 
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
      // --- FAB for Primary Action (Diagnose) ---
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/upload'), // Use push to keep back button
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now()); // Requires intl package, or use string logic

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            final userName =
                appProvider.currentUser?.name.split(' ')[0] ?? 'User';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${appProvider.translate('hello')}, $userName 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  dateStr, // Display Date here
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF616161),
                  ),
                ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No new notifications'),
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Widget
            const RealWeatherWidget(),

            // --- NEW: DASHBOARD STATS (Replaces Quick Actions) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                'Overview',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stats Row
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
                      Expanded(
                        child: _buildStatCard(
                          theme, 
                          'Scans', 
                          '$total', 
                          Icons.qr_code_scanner, 
                          Colors.blue
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme, 
                          'Healthy', 
                          '$healthy', 
                          Icons.check_circle_outline, 
                          Colors.green
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme, 
                          'Critical', 
                          '$critical', 
                          Icons.warning_amber_rounded, 
                          Colors.red
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // ---------------------------------------------------

            const SizedBox(height: 24),

            // Recent Reports Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Reports',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/reports'),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Recent Reports List
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                final reports = appProvider.diseaseReports;
                final recentReports = reports.take(3).toList();

                if (recentReports.isEmpty) {
                  return CustomCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No reports yet',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the Diagnose button below to start.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
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
                      onTap: () {
                        // Simple snackbar for feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Treatment: ${report.treatmentRecommendation.substring(0, 30)}...')),
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Tips Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Daily Tips',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.lightbulb_outline,
                            color: theme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Regular Monitoring',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text('Check crops daily for early signs.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💡 Tip: Early detection can save up to 70% of your crop yield.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // Extra space for FAB
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
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