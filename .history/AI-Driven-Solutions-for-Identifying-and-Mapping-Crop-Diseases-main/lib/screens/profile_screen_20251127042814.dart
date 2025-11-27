import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
// Ensure these widgets exist in your project
import '../widgets/card_widget.dart'; 
import '../widgets/custom_text_field.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = context.read<AppProvider>().currentUser;
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

  // --- ACTIONS ---

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _initializeControllers(); // Reset if cancelled
      }
    });
  }

  void _saveProfile() {
    final provider = context.read<AppProvider>();
    final currentUser = provider.currentUser;

    if (currentUser != null) {
      // Create updated user object
      // Note: We don't touch the password or image here
      final updatedUser = User(
        id: currentUser.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: currentUser.role,
      );

      // Update in Firebase via Provider
      provider.updateUser(updatedUser);

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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().logout();
              context.go('/login'); 
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS ---

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('For security reasons, please Log Out and use the "Forgot Password" link on the login screen to reset your password via email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              provider.changeLanguage('en');
              Navigator.pop(context);
            },
            child: const Padding(padding: EdgeInsets.all(8.0), child: Text('🇺🇸 English')),
          ),
          SimpleDialogOption(
            onPressed: () {
              provider.changeLanguage('sw');
              Navigator.pop(context);
            },
            child: const Padding(padding: EdgeInsets.all(8.0), child: Text('🇹🇿 Kiswahili')),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final user = appProvider.currentUser;
    final theme = Theme.of(context);

    // Logic for Initials (e.g. John Doe -> JD)
    String initials = "ME";
    if (user != null && user.name.isNotEmpty) {
      initials = user.name.trim().substring(0, 2).toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.edit),
              tooltip: "Edit Profile",
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- 1. USER HEADER (Simple Avatar) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with Initials
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _isEditing 
                        ? Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: "Full Name",
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailController,
                                enabled: false, // Email read-only
                                decoration: const InputDecoration(
                                  labelText: "Email (Read-only)",
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? "Guest",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? "No Email",
                                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                label: Text(user?.roleDisplayName ?? "Farmer"),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 10),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: _toggleEdit, child: const Text("Cancel")),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _saveProfile, child: const Text("Save Changes")),
                    ],
                  )
                ]
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- 2. SETTINGS ---
          const Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("Language"),
                  subtitle: Text(appProvider.selectedLanguage == 'en' ? 'English' : 'Kiswahili'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageDialog(appProvider),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text("Dark Mode"),
                  trailing: Switch(
                    value: appProvider.isDarkMode,
                    onChanged: (val) => appProvider.toggleTheme(),
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text("Change Password"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- 3. HELP ---
          const Text("Help & Support", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text("How to use"),
                  onTap: () => _showHelpDialog("How to use", "1. Go to Home.\n2. Tap Diagnose.\n3. Take photo.\n4. Get results."),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.question_answer_outlined),
                  title: const Text("FAQs"),
                  onTap: () => _showHelpDialog("FAQs", "Q: Offline mode?\nA: Coming soon.\n\nQ: Accuracy?\nA: 95%+ accuracy."),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- 4. LOGOUT ---
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text("Log Out"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Center(child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey[400], fontSize: 12))),
        ],
      ),
    );
  }
}