// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'utils/app_constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RecipeApp());
}

class RecipeApp extends StatefulWidget {
  const RecipeApp({super.key});

  static _RecipeAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_RecipeAppState>();

  @override
  State<RecipeApp> createState() => _RecipeAppState();
}

class _RecipeAppState extends State<RecipeApp> {
  bool isDarkMode = false;
  bool isEnglish = false;

  void toggleTheme() => setState(() => isDarkMode = !isDarkMode);
  void toggleLanguage() => setState(() => isEnglish = !isEnglish);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthWrapper(isEnglish: isEnglish),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final bool isEnglish;
  const AuthWrapper({super.key, required this.isEnglish});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isGuest = false;

  void _continueAsGuest() => setState(() => _isGuest = true);
  void _exitGuest() => setState(() => _isGuest = false);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(isEnglish: widget.isEnglish);

    if (_isGuest) {
      return HomeScreen(
        isGuest: true,
        onExitGuest: _exitGuest,
        strings: strings,
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(
            isGuest: false,
            onExitGuest: _exitGuest,
            strings: strings,
          );
        }
        return LoginScreen(
          onGuestLogin: _continueAsGuest,
          strings: strings,
        );
      },
    );
  }
}