import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // To check platform
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'providers/app_provider.dart';

// Import all your screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/comments_screen.dart'; // Added for the new comments feature

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // ----------------------------------------------------------
    // 🌐 WEB CONFIGURATION (Using keys you provided)
    // ----------------------------------------------------------
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyADaf4dtUWKUlZB058H7dXLkwsF-VQeECs",
        authDomain: "crop-disease-detector-8221b.firebaseapp.com",
        projectId: "crop-disease-detector-8221b",
        storageBucket: "crop-disease-detector-8221b.firebasestorage.app",
        messagingSenderId: "1015044450462",
        appId: "1:1015044450462:web:422e2e137baa09cdbdb38f",
        measurementId: "G-WBD6STPLG1",
      ),
    );
  } else {
    // ----------------------------------------------------------
    // 📱 MOBILE SETUP (Android/iOS)
    // Automatically uses the google-services.json file
    // ----------------------------------------------------------
    await Firebase.initializeApp();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const CropDiseaseApp(),
    ),
  );
}

class CropDiseaseApp extends StatelessWidget {
  const CropDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the App Navigation
    final GoRouter _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/upload',
          builder: (context, state) => const UploadScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp.router(
          title: 'Crop Disease Detector',
          debugShowCheckedModeBanner: false,

          // Define Light Theme
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
            ),
          ),

          // Define Dark Theme
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green, brightness: Brightness.dark),
            useMaterial3: true,
          ),

          // Toggle Logic
          themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          routerConfig: _router,
        );
      },
    );
  }
}
