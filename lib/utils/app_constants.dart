// lib/utils/app_constants.dart

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFE8603C);      // Turuncu-kırmızı (yemek teması)
  static const secondary = Color(0xFF2D6A4F);    // Koyu yeşil
  static const background = Color(0xFFFAF7F2);   // Krem arka plan
  static const surface = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF757575);
  static const error = Color(0xFFD32F2F);

  // Kategori renkleri
  static const Map<String, Color> categoryColors = {
    'breakfast': Color(0xFFFFB347),
    'lunch': Color(0xFF87CEEB),
    'dinner': Color(0xFFDDA0DD),
    'dessert': Color(0xFFFFB6C1),
    'snack': Color(0xFF90EE90),
    'other': Color(0xFFD3D3D3),
  };
}

class AppCategories {
  static const List<Map<String, String>> categories = [
    {'key': 'breakfast', 'label': 'Kahvaltı', 'emoji': '🍳'},
    {'key': 'lunch', 'label': 'Öğle Yemeği', 'emoji': '🥗'},
    {'key': 'dinner', 'label': 'Akşam Yemeği', 'emoji': '🍽️'},
    {'key': 'dessert', 'label': 'Tatlı', 'emoji': '🍰'},
    {'key': 'snack', 'label': 'Atıştırmalık', 'emoji': '🥨'},
    {'key': 'other', 'label': 'Diğer', 'emoji': '🍴'},
  ];

  static String getLabelByKey(String key) {
    return categories.firstWhere(
      (c) => c['key'] == key,
      orElse: () => {'label': 'Diğer'},
    )['label']!;
  }

  static String getEmojiByKey(String key) {
    return categories.firstWhere(
      (c) => c['key'] == key,
      orElse: () => {'emoji': '🍴'},
    )['emoji']!;
  }
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textDark),
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      );
}
