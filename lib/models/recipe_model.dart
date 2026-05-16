// lib/models/recipe_model.dart

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

  final int cookingTimeMinutes;
  final int servings;
  final String difficulty;
  final int? calories;
  final List<String> dietTags;
  final int favoriteCount;
  final double averageRating;
  final int ratingCount;

  // Çeviri alanları
  final String originalLanguage;
  final Map<String, dynamic> translations;

  // Arama index alanları
  final String searchEn;
  final String searchTr;

  // ─── YENİ: Öne çıkarma ───────────────────────────────────────────────────
  final bool featured;
  final String? featuredWeek; // 'YYYY-WW' formatında

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
    this.searchEn = '',
    this.searchTr = '',
    this.featured = false,
    this.featuredWeek,
  });

  // ─── Lokalizasyon getter'ları ─────────────────────────────────────────────

  String localizedTitle(String languageCode) {
    if (languageCode == originalLanguage) return title;
    final t = translations[languageCode];
    if (t != null && t['title'] != null && (t['title'] as String).isNotEmpty) {
      return t['title'] as String;
    }
    return title;
  }

  String localizedDescription(String languageCode) {
    if (languageCode == originalLanguage) return description;
    final t = translations[languageCode];
    if (t != null && t['description'] != null && (t['description'] as String).isNotEmpty) {
      return t['description'] as String;
    }
    return description;
  }

  List<String> localizedIngredients(String languageCode) {
    if (languageCode == originalLanguage) return ingredients;
    final t = translations[languageCode];
    if (t != null && t['ingredients'] != null) {
      return List<String>.from(t['ingredients'] as List);
    }
    return ingredients;
  }

  List<String> localizedSteps(String languageCode) {
    if (languageCode == originalLanguage) return steps;
    final t = translations[languageCode];
    if (t != null && t['steps'] != null) {
      return List<String>.from(t['steps'] as List);
    }
    return steps;
  }

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
      originalLanguage: map['originalLanguage'] ?? 'en',
      translations: Map<String, dynamic>.from(map['translations'] ?? {}),
      searchEn: map['searchEn'] ?? '',
      searchTr: map['searchTr'] ?? '',
      featured: map['featured'] ?? false,
      featuredWeek: map['featuredWeek'],
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
      'originalLanguage': originalLanguage,
      'searchEn': searchEn,
      'searchTr': searchTr,
      'featured': featured,
      'featuredWeek': featuredWeek,
    };
  }
}