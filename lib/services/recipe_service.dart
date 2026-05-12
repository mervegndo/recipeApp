// lib/services/recipe_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe_model.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Tüm tarifleri getir (real-time stream)
  Stream<List<RecipeModel>> getAllRecipes() {
    return _firestore
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Kategoriye göre filtrele
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

  // İsme göre ara
  Future<List<RecipeModel>> searchRecipes(String query) async {
    final snapshot = await _firestore
        .collection('recipes')
        .orderBy('title')
        .startAt([query]).endAt(['$query\uf8ff']).get();

    return snapshot.docs
        .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Kullanıcının tariflerini getir
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

  // Tarif ekle
  Future<void> addRecipe(RecipeModel recipe, {File? imageFile}) async {
    String? imageUrl;

    // Fotoğraf varsa Storage'a yükle
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, recipe.id);
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
      imageUrl: imageUrl,
      createdAt: recipe.createdAt,
    );

    await _firestore
        .collection('recipes')
        .doc(recipe.id)
        .set(recipeWithImage.toMap());
  }

  // Tarif sil
  Future<void> deleteRecipe(String recipeId) async {
    // Storage'daki fotoğrafı da sil
    try {
      await _storage.ref('recipes/$recipeId').delete();
    } catch (_) {
      // Fotoğraf yoksa sessizce devam et
    }
    await _firestore.collection('recipes').doc(recipeId).delete();
  }

  // Fotoğraf yükle
  Future<String> _uploadImage(File imageFile, String recipeId) async {
    final ref = _storage.ref('recipes/$recipeId');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Yeni ID üret
  String generateId() => _uuid.v4();

  // Favorilere ekle / çıkar
  Future<void> toggleFavorite(String userId, String recipeId, bool isCurrentlyFavorite) async {
    final userRef = _firestore.collection('users').doc(userId);
    if (isCurrentlyFavorite) {
      await userRef.update({
        'favoriteRecipeIds': FieldValue.arrayRemove([recipeId]),
      });
    } else {
      await userRef.update({
        'favoriteRecipeIds': FieldValue.arrayUnion([recipeId]),
      });
    }
  }

  // Favori tarifleri getir
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
}
