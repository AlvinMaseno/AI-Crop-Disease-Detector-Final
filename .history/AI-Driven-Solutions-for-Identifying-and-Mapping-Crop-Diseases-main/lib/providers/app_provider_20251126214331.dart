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

  // Constructor: Load data immediately when app starts
  AppProvider() {
    _loadReportsFromStorage();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String get selectedLanguage => _selectedLanguage;
  List<DiseaseReport> get diseaseReports => _diseaseReports;
  bool get isLoggedIn => _currentUser != null;

  String translate(String key) {
    return Translations.get(key, _selectedLanguage);
  }

  // --- PERSISTENCE LOGIC ---

  // Load reports from SharedPreferences
  Future<void> _loadReportsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reportsJson = prefs.getString('saved_reports');

    if (reportsJson != null) {
      try {
        // Decode the JSON string back into a List of DiseaseReport objects
        final List<dynamic> decodedList = json.decode(reportsJson);
        _diseaseReports = decodedList.map((item) => DiseaseReport.fromMap(item)).toList();
      } catch (e) {
        // Fallback if data is corrupted
        debugPrint('Error loading reports: $e');
        _diseaseReports = [];
      }
    } else {
      // Initialize with empty list if no data found
      _diseaseReports = [];
    }
    notifyListeners();
  }

  // Save current list to SharedPreferences
  Future<void> _saveReportsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert list of objects to list of maps, then to JSON string
    final String encodedData = json.encode(
      _diseaseReports.map((report) => report.toMap()).toList()
    );
    await prefs.setString('saved_reports', encodedData);
  }

  // --- REPORT MANAGEMENT ---

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

  // --- USER & APP MANAGEMENT (Existing) ---

  Future<void> login(String email, String password) async {
    _setLoading(true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    _currentUser = User(id: '1', name: 'John Farmer', email: email, role: UserRole.farmer);
    _setLoading(false);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password, UserRole role) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2));
    _currentUser = User(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, email: email, role: role);
    _setLoading(false);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

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