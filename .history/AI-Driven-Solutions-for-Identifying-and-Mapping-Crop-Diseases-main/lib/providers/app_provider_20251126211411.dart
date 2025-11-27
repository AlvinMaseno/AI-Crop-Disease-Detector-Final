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