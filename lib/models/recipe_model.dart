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

  // Yeni alanlar
  final int cookingTimeMinutes;
  final int servings;
  final String difficulty; // 'easy', 'medium', 'hard'
  final int? calories;
  final List<String> dietTags; // 'vegetarian', 'vegan', 'diet', 'protein', 'carb'
  final int favoriteCount;
  final double averageRating;
  final int ratingCount;

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
  });

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
    };
  }
}