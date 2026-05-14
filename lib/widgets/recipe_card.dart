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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3D3530)
                : AppColors.outline,
            width: 1,
          ),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraf
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15)),
                  child: recipe.imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: recipe.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholder(isDark),
                  )
                      : _placeholder(isDark),
                ),

                // Puan badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard.withOpacity(0.9)
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB347), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          recipe.ratingCount > 0
                              ? recipe.averageRating.toStringAsFixed(1)
                              : '-',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextDark
                                : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Admin sil
                if (onDelete != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(7),
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

            // İçerik
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (AppColors.categoryColors[recipe.category] ??
                          AppColors.primary)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${AppCategories.getEmojiByKey(recipe.category)} ${AppCategories.getLabelByKey(recipe.category, isEnglish: isEnglish)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color:
                        AppColors.categoryColors[recipe.category] ??
                            AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Başlık
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextDark
                          : AppColors.textDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Açıklama
                  Text(
                    recipe.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextGrey
                          : AppColors.textGrey,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Divider
                  Divider(
                    color: isDark
                        ? const Color(0xFF3D3530)
                        : AppColors.outline,
                    height: 1,
                  ),
                  const SizedBox(height: 12),

                  // Alt bilgi: süre, porsiyon, zorluk
                  Row(
                    children: [
                      _metaChip(
                        Icons.access_time_outlined,
                        '${recipe.cookingTimeMinutes} ${isEnglish ? 'min' : 'dk'}',
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _metaChip(
                        Icons.people_outline,
                        '${recipe.servings} ${isEnglish ? 'serv.' : 'kişi'}',
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _metaChip(
                        Icons.bar_chart_rounded,
                        _difficultyLabel(recipe.difficulty, isEnglish),
                        isDark,
                        color: _difficultyColor(recipe.difficulty),
                      ),
                      const Spacer(),

                      // Favori
                      Row(
                        children: [
                          Icon(Icons.favorite_border,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextGrey
                                  : AppColors.textGrey),
                          const SizedBox(width: 4),
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

                  // Diyet etiketleri
                  if (recipe.dietTags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: recipe.dietTags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _dietLabel(tag, isEnglish),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
      height: 200,
      width: double.infinity,
      color: isDark
          ? AppColors.darkCard
          : AppColors.surfaceContainerHigh,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu,
              size: 48,
              color: isDark
                  ? AppColors.darkTextGrey
                  : AppColors.textGrey),
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

  Widget _metaChip(IconData icon, String label, bool isDark,
      {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13,
            color: color ??
                (isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
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
      case 'easy': return isEnglish ? 'Easy' : 'Kolay';
      case 'hard': return isEnglish ? 'Hard' : 'Zor';
      default: return isEnglish ? 'Medium' : 'Orta';
    }
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'easy': return const Color(0xFF2E7D32);
      case 'hard': return const Color(0xFFBA1A1A);
      default: return const Color(0xFFE65100);
    }
  }
}