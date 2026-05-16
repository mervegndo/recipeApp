// lib/services/notification_service.dart
//
// Kullanıcıya bildirim gönderme ve okuma servisi.
// Firestore'da her kullanıcının altında 'notifications' koleksiyonu tutulur.
//
// Bildirim türleri:
//   favorite  — Birisi tarifini favoriledi
//   rating    — Birisi tarifini puanladı
//   comment   — Birisi tarife yorum yaptı

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  // ─── Bildirim gönder ──────────────────────────────────────────────────────

  /// Tarif sahibine bildirim yaz.
  Future<void> sendNotification({
    required String toUserId,      // Bildirim alacak kullanıcı
    required String fromUserName,  // Eylemi yapan kullanıcı adı
    required String type,          // 'favorite' | 'rating' | 'comment'
    required String recipeId,
    required String recipeTitle,
    String? commentText,
    double? rating,
  }) async {
    // Kendi kendine bildirim gönderme
    if (toUserId.isEmpty) return;

    await _db
        .collection('users')
        .doc(toUserId)
        .collection('notifications')
        .add({
      'type': type,
      'fromUserName': fromUserName,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'commentText': commentText,
      'rating': rating,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Bildirimleri oku ─────────────────────────────────────────────────────

  Stream<QuerySnapshot> getNotifications(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Okunmamış bildirim sayısı stream'i
  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ─── Okundu işaretle ─────────────────────────────────────────────────────

  Future<void> markAsRead(String userId, String notificationId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
}