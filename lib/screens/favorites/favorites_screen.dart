// lib/screens/favorites/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final AppStrings strings;
  final bool isGuest;

  const FavoritesScreen({super.key, required this.strings, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = strings;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        title: Text(
          s.favorites,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextDark : AppColors.textDark,
          ),
        ),
      ),
      body: user == null
          ? _buildEmpty(isDark, s, context)
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());

          final data = userSnap.data?.data() as Map<String, dynamic>?;
          final favoriteIds = List<String>.from(data?['favoriteRecipeIds'] ?? []);

          if (favoriteIds.isEmpty) {
            return _buildEmpty(isDark, s, context);
          }

          return FutureBuilder<List<RecipeModel>>(
            future: RecipeService().getFavoriteRecipes(favoriteIds),
            builder: (context, recipeSnap) {
              if (!recipeSnap.hasData) return const Center(child: CircularProgressIndicator());
              final recipes = recipeSnap.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      s.isEnglish
                          ? '${recipes.length} favorite recipe${recipes.length == 1 ? '' : 's'}'
                          : '${recipes.length} favori tarif',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextGrey : AppColors.textGrey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: recipes.length,
                      itemBuilder: (ctx, i) => RecipeCard(
                        recipe: recipes[i],
                        isEnglish: s.isEnglish,
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                            recipe: recipes[i], isGuest: isGuest, strings: s,
                          ),
                        )),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(bool isDark, AppStrings s, BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.favorite_border_rounded, size: 40, color: Colors.red),
        ),
        const SizedBox(height: 16),
        Text(
          s.noFavorites,
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextDark : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.isEnglish
              ? 'Recipes you favorite will appear here'
              : 'Favorilediğin tarifler burada görünecek',
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
        ),
      ]),
    );
  }
}