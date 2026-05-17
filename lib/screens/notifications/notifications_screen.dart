// lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/notification_service.dart';
import '../../utils/app_constants.dart';
import '../recipe/recipe_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final AppStrings strings;

  const NotificationsScreen({super.key, required this.strings});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notifService = NotificationService();
  late final String _uid;

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

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
        final r = (data['rating'] as num?)?.toStringAsFixed(1);
        final ratingPart = r != null ? ' ($r ⭐)' : '';
        return isEnglish
            ? '$from commented on "$title"$ratingPart: "$c"'
            : '$from "$title" tarifine yorum yaptı$ratingPart: "$c"';
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

  void _enterSelectionMode([String? firstId]) {
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
      if (firstId != null) _selectedIds.add(firstId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final isEnglish = widget.strings.isEnglish;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEnglish ? 'Delete selected?' : 'Seçilenleri sil?'),
        content: Text(isEnglish
            ? '${_selectedIds.length} notification(s) will be deleted.'
            : '${_selectedIds.length} bildirim silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isEnglish ? 'Cancel' : 'İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isEnglish ? 'Delete' : 'Sil',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.delete(FirebaseFirestore.instance
            .collection('users').doc(_uid)
            .collection('notifications').doc(id));
      }
      await batch.commit();
      final count = _selectedIds.length;
      _exitSelectionMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEnglish ? '$count deleted' : '$count bildirim silindi'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEnglish ? 'Delete failed' : 'Silme başarısız'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _openRecipe(Map<String, dynamic> data, String notifId, bool isRead) async {
    final recipeId = data['recipeId'] as String? ?? '';
    if (recipeId.isEmpty) return;

    if (!isRead) _notifService.markAsRead(_uid, notifId);

    try {
      final doc = await FirebaseFirestore.instance.collection('recipes').doc(recipeId).get();
      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.strings.isEnglish
                ? 'Recipe not found or deleted'
                : 'Tarif bulunamadı veya silinmiş'),
            backgroundColor: Colors.orange,
          ));
        }
        return;
      }
      final recipe = RecipeModel.fromMap(doc.data()!, doc.id);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: recipe, strings: widget.strings),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.strings.isEnglish ? 'Could not open recipe' : 'Tarif açılamadı'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _deleteAll() async {
    final isEnglish = widget.strings.isEnglish;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEnglish ? 'Delete all notifications?' : 'Tüm bildirimleri sil?'),
        content: Text(isEnglish
            ? 'This will permanently delete all your notifications.'
            : 'Tüm bildirimleriniz kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isEnglish ? 'Cancel' : 'İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isEnglish ? 'Delete All' : 'Tümünü Sil',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(_uid).collection('notifications').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) batch.delete(doc.reference);
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEnglish ? 'All notifications deleted' : 'Tüm bildirimler silindi'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEnglish ? 'Delete failed' : 'Silme başarısız'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return WillPopScope(
      onWillPop: () async {
        if (_selectionMode) { _exitSelectionMode(); return false; }
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          leading: _selectionMode
              ? IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode)
              : null,
          title: Text(
            _selectionMode
                ? (s.isEnglish ? '${_selectedIds.length} selected' : '${_selectedIds.length} seçildi')
                : (s.isEnglish ? 'Notifications' : 'Bildirimler'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextDark : AppColors.textDark,
            ),
          ),
          actions: _selectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: s.isEnglish ? 'Delete selected' : 'Seçilenleri sil',
                    onPressed: _deleteSelected,
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.checklist_rounded),
                    tooltip: s.isEnglish ? 'Select' : 'Seç',
                    onPressed: () => _enterSelectionMode(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                    tooltip: s.isEnglish ? 'Delete all' : 'Tümünü sil',
                    onPressed: _deleteAll,
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
                final isSelected = _selectedIds.contains(doc.id);

                final tile = InkWell(
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelect(doc.id);
                    } else {
                      _openRecipe(data, doc.id, isRead);
                    }
                  },
                  onLongPress: () {
                    if (!_selectionMode) _enterSelectionMode(doc.id);
                  },
                  child: Container(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.12)
                        : (isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectionMode) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? AppColors.primary : AppColors.textGrey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _colorForType(type).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconForType(type), color: _colorForType(type), size: 22),
                        ),
                        const SizedBox(width: 12),
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
                        if (!_selectionMode) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.textGrey),
                            onPressed: () => _notifService.deleteNotification(_uid, doc.id),
                            tooltip: s.isEnglish ? 'Delete' : 'Sil',
                          ),
                        ],
                        if (!isRead && !_selectionMode)
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );

                if (_selectionMode) return tile;

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
                  child: tile,
                );
              },
            );
          },
        ),
      ),
    );
  }
}