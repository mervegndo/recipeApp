// lib/widgets/recipe_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe_model.dart';
import '../utils/app_constants.dart';

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isEnglish;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onDelete,
    this.isEnglish = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = isEnglish ? 'en' : 'tr';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), // 16 → 12: daha kompakt
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3D3530) : AppColors.outline,
            width: 1,
          ),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.06),
              blurRadius: 16, // 24 → 16
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fotoğraf ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
                  child: recipe.imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: recipe.imageUrl!,
                    height: 170, // 200 → 170: daha kompakt
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholder(isDark),
                  )
                      : _placeholder(isDark),
                ),

                // Puan badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          recipe.ratingCount > 0
                              ? recipe.averageRating.toStringAsFixed(1)
                              : '-',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextDark
                                : AppColors.textDark,
                          ),
                        ),
                        if (recipe.ratingCount > 0) ...[
                          const SizedBox(width: 2),
                          Text(
                            '(${recipe.ratingCount})',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkTextGrey
                                  : AppColors.textGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Admin sil butonu
                if (onDelete != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            ),

            // ── İçerik ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12), // 14 → 12/10
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori chip
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (AppColors.categoryColors[recipe.category] ??
                          AppColors.primary)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${AppCategories.getEmojiByKey(recipe.category)} ${AppCategories.getLabelByKey(recipe.category, isEnglish: isEnglish)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.categoryColors[recipe.category] ??
                            AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6), // 8 → 6

                  // Başlık (lokalize)
                  Text(
                    recipe.localizedTitle(langCode),
                    style: TextStyle(
                      fontSize: 16, // 18 → 16: kompakt
                      fontWeight: FontWeight.w600,
                      color:
                      isDark ? AppColors.darkTextDark : AppColors.textDark,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3), // 4 → 3

                  // Açıklama (lokalize)
                  Text(
                    recipe.localizedDescription(langCode),
                    style: TextStyle(
                      fontSize: 12, // 13 → 12: kompakt
                      color:
                      isDark ? AppColors.darkTextGrey : AppColors.textGrey,
                      height: 1.35,
                    ),
                    maxLines: 1, // 2 → 1: daha az boşluk
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10), // 12 → 10

                  // Divider
                  Divider(
                    color:
                    isDark ? const Color(0xFF3D3530) : AppColors.outline,
                    height: 1,
                  ),
                  const SizedBox(height: 10), // 12 → 10

                  // Alt bilgi: süre, porsiyon, zorluk + favori
                  Row(
                    children: [
                      _metaChip(
                        Icons.access_time_outlined,
                        '${recipe.cookingTimeMinutes} ${isEnglish ? 'min' : 'dk'}',
                        isDark,
                      ),
                      const SizedBox(width: 10),
                      _metaChip(
                        Icons.people_outline,
                        '${recipe.servings} ${isEnglish ? 'serv.' : 'kişi'}',
                        isDark,
                      ),
                      const SizedBox(width: 10),
                      _metaChip(
                        Icons.bar_chart_rounded,
                        _difficultyLabel(recipe.difficulty, isEnglish),
                        isDark,
                        color: _difficultyColor(recipe.difficulty),
                      ),
                      const Spacer(),

                      // Favori sayısı
                      Row(
                        children: [
                          Icon(Icons.favorite_border,
                              size: 13,
                              color: isDark
                                  ? AppColors.darkTextGrey
                                  : AppColors.textGrey),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.favoriteCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextGrey
                                  : AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      height: 170, // 200 → 170
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surfaceContainerHigh,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 36,
            color: isDark ? AppColors.darkTextGrey : AppColors.textGrey,
          ),
          const SizedBox(height: 8),
          Text(
            'No photo',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextGrey : AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, bool isDark, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12,
            color: color ??
                (isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color ??
                (isDark ? AppColors.darkTextGrey : AppColors.textGrey),
          ),
        ),
      ],
    );
  }

  String _dietLabel(String tag, bool isEnglish) {
    final labels = {
      'vegetarian': isEnglish ? '🥦 Vegetarian' : '🥦 Vejetaryen',
      'vegan': '🌱 Vegan',
      'diet': isEnglish ? '🥗 Diet' : '🥗 Diyet',
      'protein': '💪 Protein',
      'carb': isEnglish ? '🍞 Carbs' : '🍞 Karbonhidrat',
    };
    return labels[tag] ?? tag;
  }

  String _difficultyLabel(String d, bool isEnglish) {
    switch (d) {
      case 'easy':
        return isEnglish ? 'Easy' : 'Kolay';
      case 'hard':
        return isEnglish ? 'Hard' : 'Zor';
      default:
        return isEnglish ? 'Medium' : 'Orta';
    }
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'easy':
        return const Color(0xFF2E7D32);
      case 'hard':
        return const Color(0xFFBA1A1A);
      default:
        return const Color(0xFFE65100);
    }
  }
}