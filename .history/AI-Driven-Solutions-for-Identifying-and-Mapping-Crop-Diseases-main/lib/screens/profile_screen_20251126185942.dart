import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/card_widget.dart';
import '../widgets/custom_text_field.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final appProvider = context.read<AppProvider>();
    final user = appProvider.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    final appProvider = context.read<AppProvider>();
    final currentUser = appProvider.currentUser;
    
    if (currentUser != null) {
      final updatedUser = User(
        id: currentUser.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: currentUser.role,
        profileImage: currentUser.profileImage,
      );
      
      appProvider.updateUser(updatedUser);
      setState(() {
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelEdit() {
    _initializeControllers();
    setState(() {
      _isEditing = false;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppProvider>().logout();
              context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Current Password',
              controller: oldPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'New Password',
              controller: newPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Confirm New Password',
              controller: confirmPasswordController,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text == confirmPasswordController.text &&
                  newPasswordController.text.length >= 6) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please check your password and try again'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            return Text(appProvider.translate('profile'));
          },
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final user = appProvider.currentUser;
          
          if (user == null) {
            return const Center(
              child: Text('No user data available'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                CustomCard(
                  child: Column(
                    children: [
                      // Profile Picture
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    // TODO: Implement image picker
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Image picker coming soon!'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // User Info
                      Text(
                        user.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.roleDisplayName,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Profile Information
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile Information',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isEditing)
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _cancelEdit,
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _saveChanges,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Name Field
                      CustomTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        enabled: _isEditing,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email Field
                      CustomTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: _isEditing,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Role Field (Read-only)
                      CustomDropdownField<UserRole>(
                        label: 'Role',
                        value: user.role,
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.displayName),
                          );
                        }).toList(),
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Settings
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<AppProvider>(
                        builder: (context, appProvider, child) {
                          return Text(
                            appProvider.translate('settings'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Language Setting
                      _buildSettingItem(
                        theme,
                        Icons.language,
                        appProvider.translate('language'),
                        appProvider.selectedLanguage == 'en' ? appProvider.translate('english') : appProvider.translate('kiswahili'),
                        () => _showLanguageDialog(appProvider),
                      ),
                      
                      const Divider(),
                      
                      // Theme Setting with Switch
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.dark_mode, color: theme.colorScheme.primary),
                        title: Text(
                          appProvider.translate('darkMode'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(appProvider.isDarkMode ? 'Enabled' : 'Disabled'),
                        trailing: Switch(
                          value: appProvider.isDarkMode,
                          onChanged: (value) => appProvider.toggleTheme(),
                          activeThumbColor: theme.colorScheme.primary,
                        ),
                      ),
                      
                      const Divider(),
                      
                      // Change Password
                      _buildSettingItem(
                        theme,
                        Icons.lock,
                        'Change Password',
                        'Update your password',
                        _showChangePasswordDialog,
                      ),
                      
                      const Divider(),
                      
                      // Notifications
                      _buildSettingItem(
                        theme,
                        Icons.notifications,
                        'Notifications',
                        'Manage notification preferences',
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification settings coming soon!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Statistics
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Statistics',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            theme,
                            '${appProvider.diseaseReports.length}',
                            'Reports',
                            Icons.assignment,
                            Colors.blue,
                          ),
                          _buildStatItem(
                            theme,
                            '${appProvider.diseaseReports.where((r) => r.severity == 'High').length}',
                            'Critical',
                            Icons.warning,
                            Colors.red,
                          ),
                          _buildStatItem(
                            theme,
                            '${DateTime.now().difference(appProvider.diseaseReports.isNotEmpty ? appProvider.diseaseReports.first.detectedAt : DateTime.now()).inDays}',
                            'Days Active',
                            Icons.calendar_today,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Danger Zone
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showLogoutDialog,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Delete Account Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account deletion feature coming soon!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingItem(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
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

  void _showLanguageDialog(AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appProvider.translate('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('🇺🇸 ${appProvider.translate('english')}'),
              value: 'en',
              groupValue: appProvider.selectedLanguage,
              onChanged: (value) {
                appProvider.changeLanguage(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('🇹🇿 ${appProvider.translate('kiswahili')}'),
              value: 'sw',
              groupValue: appProvider.selectedLanguage,
              onChanged: (value) {
                appProvider.changeLanguage(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
