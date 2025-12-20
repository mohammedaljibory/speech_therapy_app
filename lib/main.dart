import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/routes.dart';
import 'config/themes.dart';
import 'providers/auth_provider.dart';
import 'providers/children_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/evaluation_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/trainer_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();




  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      // Replace with your Firebase config
        apiKey: "AIzaSyD2QiFMuo4T9ocTNh5G4sxqlgWlSC99Sck",
        authDomain: "speech-therapy-app-14ba5.firebaseapp.com",
        projectId: "speech-therapy-app-14ba5",
        storageBucket: "speech-therapy-app-14ba5.firebasestorage.app",
        messagingSenderId: "209848414822",
        appId: "1:209848414822:web:dfe6b93c0feb5cca8eb3a7",
        measurementId: "G-851C7ESZZ8"
    ),
  );
  
  runApp(const SpeechTherapyApp());
}

class SpeechTherapyApp extends StatelessWidget {
  const SpeechTherapyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChildrenProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => EvaluationProvider()),
      ],
      child: MaterialApp(
        title: 'نظام تحسين النطق',
        debugShowCheckedModeBanner: false,
        
        // Theme Configuration
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.light,
        
        // Localization - THIS WAS MISSING!
        locale: const Locale('ar', 'IQ'),
        supportedLocales: const [
          Locale('ar', 'IQ'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        
        // Routes
        initialRoute: '/',
        onGenerateRoute: AppRoutes.generateRoute,
        
        // Home
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Navigate based on auth state
        if (authProvider.isAuthenticated) {
          return const TrainerDashboard();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
