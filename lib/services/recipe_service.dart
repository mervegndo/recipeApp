// lib/services/recipe_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe_model.dart';
import 'imgbb_service.dart';
import 'notification_service.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notifService = NotificationService();
  final _uuid = const Uuid();

  Stream<List<RecipeModel>> getAllRecipes() {
    return _firestore.collection('recipes').orderBy('createdAt', descending: true).snapshots()
        .map((s) => s.docs.map((d) => RecipeModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<RecipeModel>> getTopRatedRecipes() {
    return _firestore.collection('recipes').orderBy('averageRating', descending: true).snapshots()
        .map((s) => s.docs.map((d) => RecipeModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<RecipeModel>> getTopRatedByCategory(String category) {
    return _firestore.collection('recipes').where('category', isEqualTo: category)
        .orderBy('averageRating', descending: true).snapshots()
        .map((s) => s.docs.map((d) => RecipeModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<RecipeModel>> getRecipesByCategory(String category) {
    return _firestore.collection('recipes').where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true).snapshots()
        .map((s) => s.docs.map((d) => RecipeModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<RecipeModel>> getRecipesByDietTag(String tag) {
    return _firestore.collection('recipes').where('dietTags', arrayContains: tag)
        .orderBy('createdAt', descending: true).snapshots()
        .map((s) => s.docs.map((d) => RecipeModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<RecipeModel>> getUserRecipes(String userId) {
    return _firestore.collection('recipes').where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true).snapshots()
        .map((s) => s.docs.map((d) => RecipeModel.fromMap(d.data(), d.id)).toList());
  }

  Future<List<RecipeModel>> searchRecipes(String query, {required String langCode, String? category}) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    try {
      Query<Map<String, dynamic>> ref = _firestore.collection('recipes');
      if (category != null && category != 'all') ref = ref.where('category', isEqualTo: category);
      final snapshot = await ref.limit(500).get();
      final allRecipes = snapshot.docs.map((doc) => RecipeModel.fromMap(doc.data(), doc.id)).toList();
      return allRecipes.where((r) => r.searchTr.contains(q) || r.searchEn.contains(q)).toList();
    } catch (e) { debugPrint("Arama hatası: $e"); return []; }
  }

  String _buildSearchString(String title, List<String> ingredients) {
    return [title, ...ingredients].join(' ').toLowerCase()
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()]'), '');
  }

  Future<void> addRecipe(RecipeModel recipe,
      {File? imageFile, Uint8List? imageBytes, String? imageUrl}) async {
    String? finalImageUrl = imageUrl ?? recipe.imageUrl;
    if (finalImageUrl == null) {
      if (kIsWeb && imageBytes != null) finalImageUrl = await ImgBBService.uploadImageBytes(imageBytes);
      else if (imageFile != null) finalImageUrl = await ImgBBService.uploadImage(imageFile);
    }
    final r = RecipeModel(
      id: recipe.id, userId: recipe.userId, userEmail: recipe.userEmail,
      title: recipe.title, description: recipe.description,
      ingredients: recipe.ingredients, steps: recipe.steps, category: recipe.category,
      imageUrl: finalImageUrl, createdAt: recipe.createdAt,
      cookingTimeMinutes: recipe.cookingTimeMinutes, servings: recipe.servings,
      difficulty: recipe.difficulty, calories: recipe.calories, dietTags: recipe.dietTags,
      originalLanguage: recipe.originalLanguage, translations: recipe.translations,
      featured: recipe.featured, featuredWeek: recipe.featuredWeek,
      searchTr: _buildSearchString(recipe.localizedTitle('tr'), recipe.localizedIngredients('tr')),
      searchEn: _buildSearchString(recipe.localizedTitle('en'), recipe.localizedIngredients('en')),
    );
    await _firestore.collection('recipes').doc(recipe.id).set(r.toMap());
  }

  Future<void> updateRecipe(RecipeModel recipe, {File? newImageFile, Uint8List? newImageBytes}) async {
    String? imageUrl = recipe.imageUrl;
    if (kIsWeb && newImageBytes != null) imageUrl = await ImgBBService.uploadImageBytes(newImageBytes);
    else if (newImageFile != null) imageUrl = await ImgBBService.uploadImage(newImageFile);

    await _firestore.collection('recipes').doc(recipe.id).update({
      'title': recipe.title, 'description': recipe.description,
      'ingredients': recipe.ingredients, 'steps': recipe.steps, 'category': recipe.category,
      'imageUrl': imageUrl, 'cookingTimeMinutes': recipe.cookingTimeMinutes,
      'servings': recipe.servings, 'difficulty': recipe.difficulty,
      'calories': recipe.calories, 'dietTags': recipe.dietTags,
      'searchTr': _buildSearchString(recipe.localizedTitle('tr'), recipe.localizedIngredients('tr')),
      'searchEn': _buildSearchString(recipe.localizedTitle('en'), recipe.localizedIngredients('en')),
    });
  }

  Future<void> deleteRecipe(String recipeId) async {
    try { await _storage.ref('recipes/$recipeId').delete(); } catch (_) {}
    await _firestore.collection('recipes').doc(recipeId).delete();
  }

  String generateId() => _uuid.v4();

  // ─── Bildirim gönderme yardımcısı ────────────────────────────────────────
  Future<void> _notifyRecipeOwner({
    required String recipeId,
    required String fromUserId,
    required String type,
    String? commentText,
    double? rating,
  }) async {
    try {
      final recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();
      if (!recipeDoc.exists) return;
      final data = recipeDoc.data()!;
      final ownerId = data['userId'] as String? ?? '';
      final recipeTitle = data['title'] as String? ?? '';

      if (ownerId.isEmpty || ownerId == fromUserId) return;

      final user = FirebaseAuth.instance.currentUser;
      String fromName = 'Someone';
      try {
        final uDoc = await _firestore.collection('users').doc(fromUserId).get();
        fromName = uDoc.data()?['displayName'] as String? ??
                   user?.displayName ??
                   user?.email?.split('@').first ??
                   'Someone';
      } catch (_) {}

      await _notifService.sendNotification(
        toUserId: ownerId,
        fromUserName: fromName,
        type: type,
        recipeId: recipeId,
        recipeTitle: recipeTitle,
        commentText: commentText,
        rating: rating,
      );
    } catch (e) {
      debugPrint('Bildirim hatası ($type): $e');
    }
  }

  // ─── Favori işlemleri ────────────────────────────────────────────────────
  Future<void> toggleFavorite(String userId, String recipeId, bool isCurrentlyFavorite) async {
    final userRef = _firestore.collection('users').doc(userId);
    final recipeRef = _firestore.collection('recipes').doc(recipeId);

    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({'favoriteRecipeIds': [], 'email': '', 'displayName': ''});
    }

    if (isCurrentlyFavorite) {
      await userRef.update({'favoriteRecipeIds': FieldValue.arrayRemove([recipeId])});
      await recipeRef.update({'favoriteCount': FieldValue.increment(-1)});
    } else {
      await userRef.update({'favoriteRecipeIds': FieldValue.arrayUnion([recipeId])});
      await recipeRef.update({'favoriteCount': FieldValue.increment(1)});

      await _notifyRecipeOwner(
        recipeId: recipeId, fromUserId: userId, type: 'favorite',
      );
    }
  }

  Future<List<RecipeModel>> getFavoriteRecipes(List<String> recipeIds) async {
    if (recipeIds.isEmpty) return [];
    final snapshot = await _firestore.collection('recipes')
        .where(FieldPath.documentId, whereIn: recipeIds).get();
    return snapshot.docs.map((d) => RecipeModel.fromMap(d.data(), d.id)).toList();
  }

  // ─── Yorum işlemleri ─────────────────────────────────────────────────────
  Future<void> addComment({
    required String recipeId, required String userId, required String userEmail,
    required String userName, required String text, required double rating,
  }) async {
    final commentId = _uuid.v4();
    await _firestore.collection('recipes').doc(recipeId).collection('comments').doc(commentId).set({
      'userId': userId, 'userEmail': userEmail, 'userName': userName,
      'text': text, 'rating': rating, 'createdAt': FieldValue.serverTimestamp(),
    });
    await _updateAverageRating(recipeId);

    await _notifyRecipeOwner(
      recipeId: recipeId, fromUserId: userId, type: 'comment',
      commentText: text, rating: rating,
    );
  }

  Future<void> deleteComment(String recipeId, String commentId) async {
    await _firestore.collection('recipes').doc(recipeId).collection('comments').doc(commentId).delete();
    await _updateAverageRating(recipeId);
  }

  Stream<QuerySnapshot> getComments(String recipeId) {
    return _firestore.collection('recipes').doc(recipeId).collection('comments')
        .orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> _updateAverageRating(String recipeId) async {
    final comments = await _firestore.collection('recipes').doc(recipeId).collection('comments').get();
    if (comments.docs.isEmpty) {
      await _firestore.collection('recipes').doc(recipeId).update({'averageRating': 0.0, 'ratingCount': 0});
      return;
    }
    double total = 0;
    for (final doc in comments.docs) total += (doc.data()['rating'] ?? 0).toDouble();
    await _firestore.collection('recipes').doc(recipeId).update({
      'averageRating': total / comments.docs.length, 'ratingCount': comments.docs.length,
    });
  }

  Future<void> updateComment({
    required String recipeId, required String commentId,
    required String text, required double rating,
  }) async {
    await _firestore.collection('recipes').doc(recipeId).collection('comments').doc(commentId)
        .update({'text': text, 'rating': rating});
    await _updateAverageRating(recipeId);
  }

  Future<bool> isAdmin(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['role'] == 'admin';
  }

  Stream<QuerySnapshot> getAllUsers() => _firestore.collection('users').snapshots();

  Future<void> migrateExistingRecipes() async {
    try {
      final snapshot = await _firestore.collection('recipes').get();
      final docs = snapshot.docs;
      for (int i = 0; i < docs.length; i += 499) {
        final batch = _firestore.batch();
        final chunk = docs.sublist(i, (i + 499) > docs.length ? docs.length : (i + 499));
        for (var doc in chunk) {
          final data = doc.data();
          final originalLang = data['originalLanguage'] as String? ?? 'en';
          final title = data['title'] as String? ?? '';
          final ingredients = List<String>.from(data['ingredients'] ?? []);
          final translations = Map<String, dynamic>.from(data['translations'] ?? {});
          final trData = Map<String, dynamic>.from(translations['tr'] ?? {});
          final enData = Map<String, dynamic>.from(translations['en'] ?? {});
          final trTitle = trData['title'] as String? ?? (originalLang == 'tr' ? title : '');
          final trIngredients = List<String>.from(trData['ingredients'] ?? (originalLang == 'tr' ? ingredients : []));
          final enTitle = enData['title'] as String? ?? (originalLang == 'en' ? title : title);
          final enIngredients = List<String>.from(enData['ingredients'] ?? ingredients);
          batch.update(_firestore.collection('recipes').doc(doc.id), {
            'searchTr': _buildSearchString(trTitle, trIngredients),
            'searchEn': _buildSearchString(enTitle, enIngredients),
          });
        }
        await batch.commit();
      }
    } catch (e) { debugPrint('Migration hatası: $e'); }
  }
}