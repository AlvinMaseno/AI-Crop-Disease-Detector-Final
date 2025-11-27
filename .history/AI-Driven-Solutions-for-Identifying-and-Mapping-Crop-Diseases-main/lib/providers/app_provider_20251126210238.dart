import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/disease_report_model.dart';
import '../utils/translations.dart';

class AppProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _selectedLanguage = 'en';
  
  // 1. Private list to store reports in memory
  List<DiseaseReport> _diseaseReports = [];

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String get selectedLanguage => _selectedLanguage;
  
  // 2. Public getter for accessing reports
  List<DiseaseReport> get diseaseReports => _diseaseReports;

  bool get isLoggedIn => _currentUser != null;

  // Translation helper
  String translate(String key) {
    return Translations.get(key, _selectedLanguage);
  }

  // User Management
  Future<void> login(String email, String password) async {
    _setLoading(true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock user data
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
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock user data
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

  // Theme Management
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Language Management
  void changeLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  // Disease Reports Management
  // Renamed to 'addReport' to match UploadScreen logic
  void addReport(DiseaseReport report) {
    _diseaseReports.insert(0, report);
    notifyListeners();
  }

  void deleteDiseaseReport(String reportId) {
    _diseaseReports.removeWhere((report) => report.id == reportId);
    notifyListeners();
  }

  // Loading State
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Initialize with sample data compatible with the new model
  void initializeSampleData() {
    _diseaseReports = [
      DiseaseReport(
        id: '1',
        cropName: 'Maize',
        diseaseName: 'Maize Leaf Blight',
        confidencePercentage: 92.0, // 0-100 scale
        detectedAt: DateTime.now().subtract(const Duration(days: 1)),
        imagePath: '', // Placeholder or asset path
        treatmentRecommendation: '1. Apply fungicide containing chlorothalonil.\n2. Remove infected leaves immediately.\n3. Improve air circulation around plants.',
        severity: 'Moderate',
      ),
      DiseaseReport(
        id: '2',
        cropName: 'Tomato',
        diseaseName: 'Bacterial Blight',
        confidencePercentage: 87.5,
        detectedAt: DateTime.now().subtract(const Duration(days: 3)),
        imagePath: '',
        treatmentRecommendation: '1. Apply copper-based fungicide.\n2. Remove and destroy infected plants.\n3. Rotate crops next season.',
        severity: 'High',
      ),
      DiseaseReport(
        id: '3',
        cropName: 'Rice',
        diseaseName: 'Rice Rust',
        confidencePercentage: 78.0,
        detectedAt: DateTime.now().subtract(const Duration(days: 5)),
        imagePath: '',
        treatmentRecommendation: '1. Apply propiconazole fungicide.\n2. Reduce nitrogen fertilization.\n3. Ensure proper water management.',
        severity: 'Low',
      ),
    ];
    notifyListeners();
  }
}