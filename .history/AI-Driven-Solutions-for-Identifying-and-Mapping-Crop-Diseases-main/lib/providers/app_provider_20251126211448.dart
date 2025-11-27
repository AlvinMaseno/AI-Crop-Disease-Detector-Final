import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/disease_report_model.dart';
import '../utils/translations.dart';

class AppProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _selectedLanguage = 'en';
  
  // 1. Storage for reports
  List<DiseaseReport> _diseaseReports = [];

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String get selectedLanguage => _selectedLanguage;
  
  // 2. Public getter for reports
  List<DiseaseReport> get diseaseReports => _diseaseReports;

  bool get isLoggedIn => _currentUser != null;

  String translate(String key) {
    return Translations.get(key, _selectedLanguage);
  }

  // --- User Management ---
  Future<void> login(String email, String password) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2));
    _currentUser = User(
      id: '1',
      name: 'John Farmer',
      email: email,
      role: UserRole.farmer,
    );
    _setLoading(false);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password, UserRole role) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2));
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
    );
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

  // --- Theme & Language ---
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void changeLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  // --- Report Management ---
  
  // Adds a report to the top of the list
  void addReport(DiseaseReport report) {
    _diseaseReports.insert(0, report);
    notifyListeners();
  }

  void deleteDiseaseReport(String reportId) {
    _diseaseReports.removeWhere((report) => report.id == reportId);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Initialize with sample data (Updated to match new model)
  void initializeSampleData() {
    _diseaseReports = [
      DiseaseReport(
        id: '1',
        cropName: 'Maize',
        diseaseName: 'Maize Leaf Blight',
        confidencePercentage: 92.5,
        detectedAt: DateTime.now().subtract(const Duration(days: 1)),
        imagePath: '', 
        treatmentRecommendation: '1. Apply fungicide containing chlorothalonil.\n2. Remove infected leaves immediately.',
        severity: 'Moderate',
      ),
      DiseaseReport(
        id: '2',
        cropName: 'Tomato',
        diseaseName: 'Bacterial Blight',
        confidencePercentage: 88.0,
        detectedAt: DateTime.now().subtract(const Duration(days: 3)),
        imagePath: '',
        treatmentRecommendation: '1. Apply copper-based fungicide.\n2. Remove and destroy infected plants.',
        severity: 'High',
      ),
    ];
    notifyListeners();
  }
}