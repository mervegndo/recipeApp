// lib/screens/history/history_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/history_service.dart';
import '../../services/recipe_service.dart';
import '../../models/recipe_model.dart';
import '../../utils/app_constants.dart';
import '../recipe/recipe_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final AppStrings strings;
  final bool isGuest;

  const HistoryScreen({super.key, required this.strings, required this.isGuest});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = HistoryService();
  final _recipeService  = RecipeService();
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  String _timeAgo(Timestamp? ts, bool isEnglish) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1)  return isEnglish ? 'just now' : 'şimdi';
    if (diff.inMinutes < 60) return isEnglish ? '${diff.inMinutes}m ago' : '${diff.inMinutes}dk önce';
    if (diff.inHours < 24)   return isEnglish ? '${diff.inHours}h ago' : '${diff.inHours}sa önce';
    if (diff.inDays < 7)     return isEnglish ? '${diff.inDays}d ago' : '${diff.inDays}g önce';
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
          s.isEnglish ? 'Recently Viewed' : 'Tarihçe',
          style: TextStyle(fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextDark : AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(s.isEnglish ? 'Clear History?' : 'Tarihçeyi Temizle?'),
                  content: Text(s.isEnglish
                      ? 'All viewing history will be deleted.'
                      : 'Tüm görüntüleme geçmişi silinecek.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false),
                        child: Text(s.cancel)),
                    TextButton(onPressed: () => Navigator.pop(context, true),
                        child: Text(s.isEnglish ? 'Clear' : 'Temizle',
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) _historyService.clearHistory(_uid);
            },
            child: Text(s.isEnglish ? 'Clear' : 'Temizle',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historyService.getHistory(_uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                s.isEnglish ? 'No viewing history yet' : 'Henüz tarih yok',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextDark : AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                s.isEnglish ? 'Recipes you view will appear here' : 'Baktığın tarifler burada görünecek',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
              ),
            ]));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final recipeId = data['recipeId'] as String? ?? '';
              final title    = data['title'] as String? ?? '';
              final imageUrl = data['imageUrl'] as String?;
              final category = data['category'] as String? ?? '';
              final ts       = data['viewedAt'] as Timestamp?;

              return Dismissible(
                key: Key(docs[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _historyService.removeFromHistory(_uid, recipeId),
                child: GestureDetector(
                  onTap: () async {
                    // Tarifi Firestore'dan çek ve detay ekranına git
                    final recipeDoc = await FirebaseFirestore.instance
                        .collection('recipes').doc(recipeId).get();
                    if (recipeDoc.exists && mounted) {
                      final recipe = RecipeModel.fromMap(recipeDoc.data()!, recipeDoc.id);
                      Navigator.push(ctx, MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(
                          recipe: recipe, isGuest: widget.isGuest, strings: s,
                        ),
                      ));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF3D3530) : AppColors.outline),
                    ),
                    child: Row(children: [
                      // Fotoğraf
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                        child: imageUrl != null
                            ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 80, height: 80,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                            : _placeholder(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextDark : AppColors.textDark,
                                  )),
                              const SizedBox(height: 4),
                              Text(
                                '${AppCategories.getEmojiByKey(category)} ${AppCategories.getLabelByKey(category, isEnglish: s.isEnglish)}',
                                style: TextStyle(fontSize: 12,
                                    color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey, size: 20),
                            const SizedBox(height: 4),
                            Text(_timeAgo(ts, s.isEnglish),
                                style: TextStyle(fontSize: 11,
                                    color: isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 80, height: 80,
    color: AppColors.surfaceContainer,
    child: const Icon(Icons.restaurant_outlined, color: AppColors.textGrey),
  );
}