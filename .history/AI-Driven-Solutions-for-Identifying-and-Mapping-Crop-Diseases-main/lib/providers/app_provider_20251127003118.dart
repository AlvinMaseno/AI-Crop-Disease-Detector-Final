import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/disease_report_model.dart';
import '../utils/translations.dart';

class AppProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _selectedLanguage = 'en';
  List<DiseaseReport> _diseaseReports = [];

  // Constructor: Initialize data loading immediately
  AppProvider() {
    _loadDataFromStorage();
  }

  // --- GETTERS ---
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String get selectedLanguage => _selectedLanguage;
  List<DiseaseReport> get diseaseReports => _diseaseReports;
  bool get isLoggedIn => _currentUser != null;

  String translate(String key) {
    return Translations.get(key, _selectedLanguage);
  }

  // --- INITIALIZATION ---
  Future<void> _loadDataFromStorage() async {
    await _loadUserFromStorage(); // Check if user is already logged in
    await _loadReportsFromStorage(); // Load their reports
  }

  // --- AUTHENTICATION LOGIC (Mock with Persistence) ---

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network

    final prefs = await SharedPreferences.getInstance();
    
    // strict check: try to find a specific user registered with this email
    final String? storedUserJson = prefs.getString('registered_user_$email');

    if (storedUserJson != null) {
      final storedUser = User.fromJson(storedUserJson);
      
      // Simple password check (In real app, utilize hashing)
      if (storedUser.password == password) {
        _currentUser = storedUser;
        await _saveSession(_currentUser!); // Save active session
        _setLoading(false);
        notifyListeners();
        return true; // Login Success
      }
    }
    
    _setLoading(false);
    notifyListeners();
    return false; // Login Failed
  }

  Future<bool> register(String name, String email, String password, UserRole role) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1)); 

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password, 
      role: role,
    );

    final prefs = await SharedPreferences.getInstance();
    // Save this specific user so they can login later
    await prefs.setString('registered_user_$email', newUser.toJson());

    // Automatically log them in after registration
    _currentUser = newUser;
    await _saveSession(newUser);
    
    _setLoading(false);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_session'); // Clear active session
    notifyListeners();
  }

  // --- USER UPDATE (Fixes ProfileScreen Error) ---
  Future<void> updateUser(User updatedUser) async {
    _currentUser = updatedUser;
    // Update the active session
    await _saveSession(updatedUser);
    
    // Also update the registered record so future logins use the new details
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registered_user_${updatedUser.email}', updatedUser.toJson());
    
    notifyListeners();
  }

  // --- SESSION PERSISTENCE ---
  // Save the currently logged-in user
  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_session', user.toJson());
  }

  // Check on startup if anyone was logged in
  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionJson = prefs.getString('active_session');
    if (sessionJson != null) {
      _currentUser = User.fromJson(sessionJson);
    }
    notifyListeners();
  }

  // --- REPORT MANAGEMENT (With Persistence) ---

  Future<void> _loadReportsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reportsJson = prefs.getString('saved_reports');

    if (reportsJson != null) {
      try {
        final List<dynamic> decodedList = json.decode(reportsJson);
        _diseaseReports = decodedList.map((item) => DiseaseReport.fromMap(item)).toList();
      } catch (e) {
        _diseaseReports = [];
      }
    }
    notifyListeners();
  }

  Future<void> _saveReportsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      _diseaseReports.map((report) => report.toMap()).toList()
    );
    await prefs.setString('saved_reports', encodedData);
  }

  void addReport(DiseaseReport report) {
    _diseaseReports.insert(0, report);
    _saveReportsToStorage(); // Auto-save
    notifyListeners();
  }

  void deleteDiseaseReport(String reportId) {
    _diseaseReports.removeWhere((report) => report.id == reportId);
    _saveReportsToStorage(); // Auto-save
    notifyListeners();
  }

  // --- UI SETTINGS ---

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void changeLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}