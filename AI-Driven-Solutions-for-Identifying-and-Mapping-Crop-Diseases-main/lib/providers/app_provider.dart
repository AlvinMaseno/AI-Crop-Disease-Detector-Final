import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/disease_report_model.dart';
import '../utils/translations.dart';

class AppProvider extends ChangeNotifier {
  // Firebase Instances
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _selectedLanguage = 'en';
  List<DiseaseReport> _diseaseReports = [];

  // Constructor: Listen to Authentication State Changes
  AppProvider() {
    _initFirebase();
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
  void _initFirebase() {
    // This listener automatically handles login/logout state persistence
    _auth.authStateChanges().listen((auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        // 1. User logged in: Fetch profile & reports
        await _fetchUserProfile(firebaseUser.uid);
        _listenToReports(firebaseUser.uid);
      } else {
        // 2. User logged out: Clear state
        _currentUser = null;
        _diseaseReports = [];
        notifyListeners();
      }
    });
  }

  // --- AUTHENTICATION ---

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Success: The listener in _initFirebase will handle the rest
      return true;
    } catch (e) {
      debugPrint("Login Error: $e");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, UserRole role) async {
    _setLoading(true);
    try {
      // 1. Create Auth User
      auth.UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // 2. Create User Profile in Firestore
      final newUser = User(
        id: cred.user!.uid,
        name: name,
        email: email,
        role: role.toString().split('.').last, // e.g. "farmer"
      );

      await _firestore.collection('users').doc(cred.user!.uid).set(newUser.toMap());
      
      return true;
    } catch (e) {
      debugPrint("Register Error: $e");
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // --- DATABASE OPERATIONS ---

  Future<void> _fetchUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = User.fromMap(doc.data() as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
    _setLoading(false);
  }

  // Real-time listener for Reports
  void _listenToReports(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('reports')
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _diseaseReports = snapshot.docs
          .map((doc) => DiseaseReport.fromMap(doc.data()))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addReport(DiseaseReport report) async {
    if (_auth.currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('reports')
          .doc(report.id)
          .set(report.toMap());
    } catch (e) {
      debugPrint("Error adding report: $e");
    }
  }

  Future<void> deleteDiseaseReport(String reportId) async {
    if (_auth.currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('reports')
          .doc(reportId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting report: $e");
    }
  }

  Future<void> updateUser(User updatedUser) async {
    if (_auth.currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(updatedUser.toMap());
      _currentUser = updatedUser; // Optimistic update
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating profile: $e");
    }
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