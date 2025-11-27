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
  // Controllers for editing
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

  // Load current user data into controllers
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
        // If cancelling, reset text to original values
        _initializeControllers();
      }
    });
  }

  void _saveProfile() {
    final provider = context.read<AppProvider>();
    final currentUser = provider.currentUser;

    if (currentUser != null) {
      // Create updated user object
      // FIXED: Removed password field as it is handled by Firebase Auth now
      final updatedUser = User(
        id: currentUser.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: currentUser.role,
      );

      // Update state & storage
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
              // Clear stack and go to login
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
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'New Password',
              controller: newPassCtrl,
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Confirm Password',
              controller: confirmPassCtrl,
              obscureText: true,
              prefixIcon: const Icon(Icons.lock),
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
              if (newPassCtrl.text.isNotEmpty && 
                  newPassCtrl.text == confirmPassCtrl.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('For security, please change password via Logout > Forgot Password')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Update'),
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

    // Generate initials safely
    final String initials = (user?.name.isNotEmpty == true) 
        ? user!.name.substring(0, 2).toUpperCase() 
        : "ME";

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
          // --- 1. USER HEADER CARD ---
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
                              CustomTextField(
                                label: "Full Name",
                                controller: _nameController,
                                prefixIcon: const Icon(Icons.person),
                              ),
                              const SizedBox(height: 12),
                              // Email is usually not editable in Firebase without re-auth, 
                              // but we can leave the field here for display or updates if you handle it.
                              CustomTextField(
                                label: "Email",
                                controller: _emailController,
                                prefixIcon: const Icon(Icons.email),
                                // Disable email editing for simplicity in this demo
                                enabled: false, 
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? "Guest User",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? "No email linked",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                // Updated to use the helper from your new User model
                                label: Text(user?.roleDisplayName ?? "FARMER"),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
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
                      TextButton(
                        onPressed: _toggleEdit,
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text("Save Changes"),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- 2. SETTINGS SECTION ---
          const Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                // Language
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("Language"),
                  subtitle: Text(appProvider.selectedLanguage == 'en' ? 'English' : 'Kiswahili'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageDialog(appProvider),
                ),
                const Divider(height: 1),
                // Dark Mode
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
                // Change Password
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

          // --- 3. HELP & SUPPORT SECTION ---
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
                  onTap: () => _showHelpDialog(
                    "How to use",
                    "1. Go to Home tab.\n2. Tap 'Diagnose Crop'.\n3. Take a photo of a leaf.\n4. Get instant results and treatment."
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.question_answer_outlined),
                  title: const Text("FAQs"),
                  onTap: () => _showHelpDialog(
                    "FAQs",
                    "Q: Does it work offline?\nA: Currently requires internet.\n\nQ: Is it accurate?\nA: Yes, but always verify with an expert."
                  ),
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
          Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}