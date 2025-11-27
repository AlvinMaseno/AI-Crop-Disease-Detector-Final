import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isObscured = true;
  UserRole _selectedRole = UserRole.farmer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final appProvider = context.read<AppProvider>();
      
      // This now creates a REAL user in Firebase Auth & Firestore
      final success = await appProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedRole,
      );

      if (success && mounted) {
        // Success: Firebase automatically logs them in, so just go Home
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Email might be in use.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<AppProvider>().isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E8), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.agriculture, size: 60, color: Colors.green),
                    const SizedBox(height: 16),
                    Text("Create Account", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text("Join our community of smart farmers", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
                    const SizedBox(height: 40),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: "Full Name", prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
                      validator: (value) => (value == null || value.isEmpty) ? "Please enter your name" : null,
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: "Email Address", prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
                      validator: (value) => (value == null || !value.contains('@')) ? "Enter a valid email" : null,
                    ),
                    const SizedBox(height: 20),

                    // Role
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      decoration: InputDecoration(labelText: "I am a...", prefixIcon: const Icon(Icons.work_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
                      items: UserRole.values.map((role) => DropdownMenuItem(value: role, child: Text(role.displayName))).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscured,
                      decoration: InputDecoration(
                        labelText: "Password", prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isObscured = !_isObscured)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
                      validator: (value) => (value == null || value.length < 6) ? "Min 6 characters required" : null,
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _isObscured,
                      decoration: InputDecoration(labelText: "Confirm Password", prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
                      validator: (value) => (value != _passwordController.text) ? "Passwords do not match" : null,
                    ),
                    const SizedBox(height: 32),

                    // Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Create Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?"),
                        TextButton(onPressed: () => context.go('/login'), child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}