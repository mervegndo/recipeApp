// lib/models/recipe_model.dart

class RecipeModel {
  final String id;
  final String userId;
  final String userEmail;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final String category; // breakfast, lunch, dinner, dessert, snack
  final String? imageUrl;
  final DateTime createdAt;

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
  });

  // Firestore'dan okuma
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
    );
  }

  // Firestore'a yazma
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
    };
  }
}
