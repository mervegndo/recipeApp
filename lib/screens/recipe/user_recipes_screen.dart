// lib/screens/profile/user_recipes_screen.dart

import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';

class UserRecipesScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final AppStrings strings;
  final bool isGuest;

  const UserRecipesScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.strings,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipeService = RecipeService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.isEnglish
              ? '$userName\'s Recipes'
              : '$userName\'in Tarifleri',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Kullanıcı mini profil bandı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: isDark
                  ? []
                  : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  backgroundImage: userPhotoUrl != null
                      ? NetworkImage(userPhotoUrl!)
                      : null,
                  child: userPhotoUrl == null
                      ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      strings.isEnglish ? 'Shared recipes' : 'Paylaştığı tarifler',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextGrey
                              : AppColors.textGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tarif listesi
          Expanded(
            child: StreamBuilder<List<RecipeModel>>(
              stream: recipeService.getUserRecipes(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final recipes = snapshot.data ?? [];
                if (recipes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu_outlined,
                            size: 64, color: AppColors.textGrey),
                        const SizedBox(height: 16),
                        Text(
                          strings.isEnglish
                              ? 'No recipes yet'
                              : 'Henüz tarif paylaşılmamış',
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) => RecipeCard(
                    recipe: recipes[index],
                    isEnglish: strings.isEnglish,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(
                          recipe: recipes[index],
                          strings: strings,
                          isGuest: isGuest,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}