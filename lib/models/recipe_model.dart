// lib/models/recipe_model.dart
//
// DEĞİŞİKLİKLER:
//   - `originalLanguage` alanı eklendi (tarifi kimin dilinde yüklediği)
//   - `translations` map alanı eklendi (Cloud Function tarafından doldurulur)
//   - `localizedTitle`, `localizedDescription`, `localizedIngredients`,
//     `localizedSteps` getter'ları eklendi — UI her zaman bunları kullanır.

class RecipeModel {
  final String id;
  final String userId;
  final String userEmail;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final String category;
  final String? imageUrl;
  final DateTime createdAt;

  // Mevcut alanlar
  final int cookingTimeMinutes;
  final int servings;
  final String difficulty;
  final int? calories;
  final List<String> dietTags;
  final int favoriteCount;
  final double averageRating;
  final int ratingCount;

  // YENİ: Çeviri alanları
  /// Tarihin orijinal dili: "en" veya "tr"
  final String originalLanguage;

  /// Cloud Function tarafından doldurulan çeviriler.
  /// Yapısı: { "tr": { "title": "...", "description": "...",
  ///                    "ingredients": [...], "steps": [...] } }
  final Map<String, dynamic> translations;

  RecipeModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.category,
    this.imageUrl,
    required this.createdAt,
    this.cookingTimeMinutes = 0,
    this.servings = 1,
    this.difficulty = 'medium',
    this.calories,
    this.dietTags = const [],
    this.favoriteCount = 0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.originalLanguage = 'en',
    this.translations = const {},
  });

  // ─── Lokalizasyon getter'ları ─────────────────────────────────────────────
  // UI katmanı her zaman bu getter'ları kullanmalı, title/description'ı değil.

  /// Verilen [languageCode] için lokalize başlık döndürür.
  /// Çeviri yoksa orijinal başlığa fallback yapar.
  String localizedTitle(String languageCode) {
    if (languageCode == originalLanguage) return title;
    final t = translations[languageCode];
    if (t != null && t['title'] != null && (t['title'] as String).isNotEmpty) {
      return t['title'] as String;
    }
    return title; // fallback: orijinal
  }

  /// Verilen [languageCode] için lokalize açıklama döndürür.
  String localizedDescription(String languageCode) {
    if (languageCode == originalLanguage) return description;
    final t = translations[languageCode];
    if (t != null &&
        t['description'] != null &&
        (t['description'] as String).isNotEmpty) {
      return t['description'] as String;
    }
    return description;
  }

  /// Verilen [languageCode] için lokalize malzeme listesi döndürür.
  List<String> localizedIngredients(String languageCode) {
    if (languageCode == originalLanguage) return ingredients;
    final t = translations[languageCode];
    if (t != null && t['ingredients'] != null) {
      return List<String>.from(t['ingredients'] as List);
    }
    return ingredients;
  }

  /// Verilen [languageCode] için lokalize adımlar döndürür.
  List<String> localizedSteps(String languageCode) {
    if (languageCode == originalLanguage) return steps;
    final t = translations[languageCode];
    if (t != null && t['steps'] != null) {
      return List<String>.from(t['steps'] as List);
    }
    return steps;
  }

  /// Çeviri henüz hazır mı?
  bool hasTranslation(String languageCode) {
    if (languageCode == originalLanguage) return true;
    return translations.containsKey(languageCode);
  }

  // ─── fromMap / toMap ──────────────────────────────────────────────────────

  factory RecipeModel.fromMap(Map<String, dynamic> map, String id) {
    return RecipeModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      steps: List<String>.from(map['steps'] ?? []),
      category: map['category'] ?? 'other',
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      cookingTimeMinutes: map['cookingTimeMinutes'] ?? 0,
      servings: map['servings'] ?? 1,
      difficulty: map['difficulty'] ?? 'medium',
      calories: map['calories'],
      dietTags: List<String>.from(map['dietTags'] ?? []),
      favoriteCount: map['favoriteCount'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      // YENİ alanlar
      originalLanguage: map['originalLanguage'] ?? 'en',
      translations: Map<String, dynamic>.from(map['translations'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'cookingTimeMinutes': cookingTimeMinutes,
      'servings': servings,
      'difficulty': difficulty,
      'calories': calories,
      'dietTags': dietTags,
      'favoriteCount': favoriteCount,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      // YENİ alanlar (translations Cloud Function tarafından eklenir,
      // ama ilk kayıtta boş map olarak göndermek güvenlidir)
      'originalLanguage': originalLanguage,
      // 'translations' burada intentionally gönderilmiyor —
      // Cloud Function bu alanı kendisi yönetir.
    };
  }
}