// lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';
import '../../utils/app_constants.dart';

class NotificationsScreen extends StatefulWidget {
  final AppStrings strings;

  const NotificationsScreen({super.key, required this.strings});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notifService = NotificationService();
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  String _buildMessage(Map<String, dynamic> data, bool isEnglish) {
    final type = data['type'] as String? ?? '';
    final from = data['fromUserName'] as String? ?? '';
    final title = data['recipeTitle'] as String? ?? '';
    switch (type) {
      case 'favorite':
        return isEnglish
            ? '$from favorited your recipe "$title"'
            : '$from tarifini favorilere ekledi: "$title"';
      case 'rating':
        final r = (data['rating'] as num?)?.toStringAsFixed(1) ?? '';
        return isEnglish
            ? '$from rated your recipe "$title" — $r ⭐'
            : '$from tarifini puanladı: "$title" — $r ⭐';
      case 'comment':
        final c = data['commentText'] as String? ?? '';
        return isEnglish
            ? '$from commented on "$title": "$c"'
            : '$from "$title" tarifine yorum yaptı: "$c"';
      default:
        return isEnglish ? 'New notification' : 'Yeni bildirim';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'favorite': return Icons.favorite_rounded;
      case 'rating':   return Icons.star_rounded;
      case 'comment':  return Icons.chat_bubble_rounded;
      default:         return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'favorite': return Colors.red;
      case 'rating':   return Colors.amber;
      case 'comment':  return AppColors.primary;
      default:         return AppColors.textGrey;
    }
  }

  String _timeAgo(Timestamp? ts, bool isEnglish) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return isEnglish ? 'just now' : 'şimdi';
    if (diff.inMinutes < 60) return isEnglish ? '${diff.inMinutes}m ago' : '${diff.inMinutes}dk önce';
    if (diff.inHours < 24)  return isEnglish ? '${diff.inHours}h ago' : '${diff.inHours}sa önce';
    if (diff.inDays < 7)    return isEnglish ? '${diff.inDays}d ago' : '${diff.inDays}g önce';
    return isEnglish ? '${diff.inDays ~/ 7}w ago' : '${diff.inDays ~/ 7}h önce';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        title: Text(
          s.isEnglish ? 'Notifications' : 'Bildirimler',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextDark : AppColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _notifService.markAllAsRead(_uid),
            child: Text(
              s.isEnglish ? 'Mark all read' : 'Tümünü oku',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notifService.getNotifications(_uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  s.isEnglish ? 'No notifications yet' : 'Henüz bildirim yok',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextDark : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.isEnglish
                      ? 'When someone favorites or comments on\nyour recipes, you\'ll see it here'
                      : 'Biri tarifinizi favorilediğinde veya\nyorum yaptığında burada görünür',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                ),
              ]),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1, indent: 72,
              color: isDark ? const Color(0xFF3D3530) : AppColors.outline.withOpacity(0.5),
            ),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] as bool? ?? false;
              final type  = data['type'] as String? ?? '';
              final ts    = data['createdAt'] as Timestamp?;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _notifService.deleteNotification(_uid, doc.id),
                child: InkWell(
                  onTap: () {
                    if (!isRead) _notifService.markAsRead(_uid, doc.id);
                  },
                  child: Container(
                    color: isRead
                        ? Colors.transparent
                        : AppColors.primary.withOpacity(0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İkon
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _colorForType(type).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconForType(type), color: _colorForType(type), size: 22),
                        ),
                        const SizedBox(width: 12),
                        // Metin
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _buildMessage(data, s.isEnglish),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                                  color: isDark ? AppColors.darkTextDark : AppColors.textDark,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _timeAgo(ts, s.isEnglish),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextGrey : AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}