import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/real_weather_widget.dart';
import '../widgets/card_widget.dart'; // Assuming NavigationCard and CustomCard are here
import 'reports_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

// Assuming you have a DiseaseReportCard widget defined elsewhere, 
// and an AppProvider that exposes diseaseReports.

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
              onPressed: () => context.go('/upload'),
              label: Text(context.watch<AppProvider>().translate('diagnoseCrop')),
              icon: const Icon(Icons.camera_alt_rounded),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Theme.of(context).colorScheme.primary, 
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // ------------------------------------------

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
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
    
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            final userName = appProvider.currentUser?.name.split(' ')[0] ?? 'User';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Greeting text improved
                  '${appProvider.translate('hello')}, $userName 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  appProvider.translate('monitorCrops'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
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
                    content: Text('Notifications coming soon!'),
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
            // Weather Widget - Real weather based on location
            const RealWeatherWidget(),
            
            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return Text(
                    appProvider.translate('quickActions'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Navigation Cards Grid (No Upload Card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      // Reports Card (Moved to the prominent top-left spot)
                      NavigationCard(
                        title: appProvider.translate('reports'),
                        subtitle: 'View diagnosis history',
                        icon: Icons.assignment,
                        onTap: () => context.go('/reports'),
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        iconColor: Colors.orange,
                      ),
                      // Community Card
                      NavigationCard(
                        title: appProvider.translate('community'),
                        subtitle: 'Resources & tips',
                        icon: Icons.people,
                        onTap: () => context.go('/community'),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        iconColor: Colors.blue,
                      ),
                      // New: Pest Library Card (Educational content is good for this app)
                      NavigationCard(
                        title: appProvider.translate('pestLibrary'),
                        subtitle: 'Learn about diseases',
                        icon: Icons.local_florist_rounded,
                        onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pest Library coming soon!')),
                            );
                        },
                        backgroundColor: Colors.green.withOpacity(0.1),
                        iconColor: Colors.green,
                      ),
                      // Settings/Profile Card
                      NavigationCard(
                        title: appProvider.translate('settings'),
                        subtitle: 'Profile & preferences',
                        icon: Icons.settings,
                        onTap: () => context.go('/profile'),
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        iconColor: Colors.purple,
                      ),
                    ],
                  );
                },
              ),
            ),
            
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
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Recent Reports List (Uses real data from AppProvider)
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                // Ensure diseaseReports is not null and is a list/iterable
                final reports = appProvider.diseaseReports ?? [];
                final recentReports = reports.take(3).toList();
                
                if (recentReports.isEmpty) {
                  return CustomCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reports yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the "Diagnose Crop" button to get started!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
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
                    // NOTE: DiseaseReportCard must be defined elsewhere and accept these properties
                    return DiseaseReportCard(
                      cropName: report.cropName,
                      diseaseName: report.diseaseName,
                      confidence: report.confidencePercentage,
                      severity: report.severity,
                      date: report.detectedAt,
                      onTap: () {
                        // TODO: Navigate to detailed report
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing ${report.diseaseName} details'),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Tips Section (Keep as is)
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
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Regular Monitoring',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Check your crops daily for early signs of disease',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💡 Tip: Early detection can save up to 70% of your crop yield. Take photos of suspicious areas and use our AI to identify potential issues.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
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