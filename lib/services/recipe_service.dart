// lib/services/recipe_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe_model.dart';
import 'imgbb_service.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Stream<List<RecipeModel>> getAllRecipes() {
    return _firestore
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<RecipeModel>> getTopRatedRecipes() {
    return _firestore
        .collection('recipes')
        .orderBy('averageRating', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<RecipeModel>> getRecipesByCategory(String category) {
    return _firestore
        .collection('recipes')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<RecipeModel>> getRecipesByDietTag(String tag) {
    return _firestore
        .collection('recipes')
        .where('dietTags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<RecipeModel>> getUserRecipes(String userId) {
    return _firestore
        .collection('recipes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ImgBB ile fotoğraf yükleme — Firebase Storage kullanmaz
  Future<void> addRecipe(RecipeModel recipe, {File? imageFile, Uint8List? imageBytes, String? imageUrl}) async {
    String? finalImageUrl = imageUrl ?? recipe.imageUrl;

    // Eğer imageUrl zaten set edilmemişse, dosyadan yükle
    if (finalImageUrl == null) {
      if (kIsWeb && imageBytes != null) {
        finalImageUrl = await ImgBBService.uploadImageBytes(imageBytes);
      } else if (imageFile != null) {
        finalImageUrl = await ImgBBService.uploadImage(imageFile);
      }
    }

    final recipeWithImage = RecipeModel(
      id: recipe.id,
      userId: recipe.userId,
      userEmail: recipe.userEmail,
      title: recipe.title,
      description: recipe.description,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      category: recipe.category,
      imageUrl: finalImageUrl,
      createdAt: recipe.createdAt,
      cookingTimeMinutes: recipe.cookingTimeMinutes,
      servings: recipe.servings,
      difficulty: recipe.difficulty,
      calories: recipe.calories,
      dietTags: recipe.dietTags,
    );

    await _firestore
        .collection('recipes')
        .doc(recipe.id)
        .set(recipeWithImage.toMap());
  }

  Future<void> updateRecipe(RecipeModel recipe, {File? newImageFile, Uint8List? newImageBytes}) async {
    String? imageUrl = recipe.imageUrl;

    if (kIsWeb && newImageBytes != null) {
      imageUrl = await ImgBBService.uploadImageBytes(newImageBytes);
    } else if (newImageFile != null) {
      imageUrl = await ImgBBService.uploadImage(newImageFile);
    }

    await _firestore.collection('recipes').doc(recipe.id).update({
      'title': recipe.title,
      'description': recipe.description,
      'ingredients': recipe.ingredients,
      'steps': recipe.steps,
      'category': recipe.category,
      'imageUrl': imageUrl,
      'cookingTimeMinutes': recipe.cookingTimeMinutes,
      'servings': recipe.servings,
      'difficulty': recipe.difficulty,
      'calories': recipe.calories,
      'dietTags': recipe.dietTags,
    });
  }

  Future<void> deleteRecipe(String recipeId) async {
    // Firebase Storage kullanmıyoruz artık, sadece Firestore'dan sil
    try {
      await _storage.ref('recipes/$recipeId').delete();
    } catch (_) {
      // Storage'da yoksa sessizce devam et
    }
    await _firestore.collection('recipes').doc(recipeId).delete();
  }

  String generateId() => _uuid.v4();

  Future<void> toggleFavorite(
      String userId, String recipeId, bool isCurrentlyFavorite) async {
    final userRef = _firestore.collection('users').doc(userId);
    final recipeRef = _firestore.collection('recipes').doc(recipeId);

    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'favoriteRecipeIds': [],
        'email': '',
        'displayName': '',
      });
    }

    if (isCurrentlyFavorite) {
      await userRef.update({
        'favoriteRecipeIds': FieldValue.arrayRemove([recipeId]),
      });
      await recipeRef.update({
        'favoriteCount': FieldValue.increment(-1),
      });
    } else {
      await userRef.update({
        'favoriteRecipeIds': FieldValue.arrayUnion([recipeId]),
      });
      await recipeRef.update({
        'favoriteCount': FieldValue.increment(1),
      });
    }
  }

  Future<List<RecipeModel>> getFavoriteRecipes(List<String> recipeIds) async {
    if (recipeIds.isEmpty) return [];
    final snapshot = await _firestore
        .collection('recipes')
        .where(FieldPath.documentId, whereIn: recipeIds)
        .get();
    return snapshot.docs
        .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addComment({
    required String recipeId,
    required String userId,
    required String userEmail,
    required String userName,
    required String text,
    required double rating,
  }) async {
    final commentId = _uuid.v4();
    await _firestore
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .doc(commentId)
        .set({
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'text': text,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _updateAverageRating(recipeId);
  }

  Future<void> deleteComment(String recipeId, String commentId) async {
    await _firestore
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .doc(commentId)
        .delete();
    await _updateAverageRating(recipeId);
  }

  Stream<QuerySnapshot> getComments(String recipeId) {
    return _firestore
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _updateAverageRating(String recipeId) async {
    final comments = await _firestore
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .get();

    if (comments.docs.isEmpty) {
      await _firestore.collection('recipes').doc(recipeId).update({
        'averageRating': 0.0,
        'ratingCount': 0,
      });
      return;
    }

    double total = 0;
    for (final doc in comments.docs) {
      total += (doc.data()['rating'] ?? 0).toDouble();
    }

    await _firestore.collection('recipes').doc(recipeId).update({
      'averageRating': total / comments.docs.length,
      'ratingCount': comments.docs.length,
    });
  }

  Future<bool> isAdmin(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['role'] == 'admin';
  }

  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }
}
