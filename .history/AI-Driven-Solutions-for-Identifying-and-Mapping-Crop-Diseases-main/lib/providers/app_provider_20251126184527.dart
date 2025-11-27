import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/disease_report.dart';
import '../utils/translations.dart';

class AppProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _selectedLanguage = 'en';
  List<DiseaseReport> _diseaseReports = [];

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String get selectedLanguage => _selectedLanguage;
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
  void addDiseaseReport(DiseaseReport report) {
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

  // Initialize with sample data
  void initializeSampleData() {
    _diseaseReports = [
      DiseaseReport(
        id: '1',
        cropName: 'Maize',
        diseaseType: DiseaseType.leafSpot,
        diseaseName: 'Maize Leaf Blight',
        confidence: 0.92,
        detectedAt: DateTime.now().subtract(const Duration(days: 1)),
        treatmentSteps: [
          'Apply fungicide containing chlorothalonil',
          'Remove infected leaves immediately',
          'Improve air circulation around plants',
          'Avoid overhead watering',
        ],
        severity: 'Medium',
        location: 'Field A',
      ),
      DiseaseReport(
        id: '2',
        cropName: 'Tomato',
        diseaseType: DiseaseType.bacterialBlight,
        diseaseName: 'Bacterial Blight',
        confidence: 0.87,
        detectedAt: DateTime.now().subtract(const Duration(days: 3)),
        treatmentSteps: [
          'Apply copper-based fungicide',
          'Remove and destroy infected plants',
          'Rotate crops next season',
          'Improve drainage',
        ],
        severity: 'High',
        location: 'Greenhouse B',
      ),
      DiseaseReport(
        id: '3',
        cropName: 'Rice',
        diseaseType: DiseaseType.rust,
        diseaseName: 'Rice Rust',
        confidence: 0.78,
        detectedAt: DateTime.now().subtract(const Duration(days: 5)),
        treatmentSteps: [
          'Apply propiconazole fungicide',
          'Reduce nitrogen fertilization',
          'Ensure proper water management',
          'Monitor for spread',
        ],
        severity: 'Low',
        location: 'Paddy Field C',
      ),
    ];
  }
}
