// lib/services/history_service.dart
//
// Kullanıcının son baktığı tarifleri Firestore'a kaydeder.
// Kayıt: users/{uid}/recipeHistory/{recipeId}
//   - recipeId, title, imageUrl, category, viewedAt

import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryService {
  final _db = FirebaseFirestore.instance;

  Future<void> addToHistory({
    required String userId,
    required String recipeId,
    required String title,
    String? imageUrl,
    String? category,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('recipeHistory')
          .doc(recipeId) // Aynı tarif çift girmesin, üzerine yaz
          .set({
        'recipeId': recipeId,
        'title': title,
        'imageUrl': imageUrl,
        'category': category,
        'viewedAt': FieldValue.serverTimestamp(),
      });

      // 50'den fazla geçmiş varsa en eskiyi sil
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('recipeHistory')
          .orderBy('viewedAt', descending: true)
          .get();
      if (snap.docs.length > 50) {
        for (final doc in snap.docs.sublist(50)) {
          await doc.reference.delete();
        }
      }
    } catch (_) {}
  }

  Stream<QuerySnapshot> getHistory(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('recipeHistory')
        .orderBy('viewedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> clearHistory(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('recipeHistory')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> removeFromHistory(String userId, String recipeId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('recipeHistory')
        .doc(recipeId)
        .delete();
  }
}