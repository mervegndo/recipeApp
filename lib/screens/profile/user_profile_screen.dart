// lib/screens/profile/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final AppStrings strings;
  final bool isGuest;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.strings,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = strings;
    final recipeService = RecipeService();

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.background,
        title: Text(
          userName,
          style: const TextStyle(fontSize: 17),
        ),
      ),
      body: StreamBuilder<List<RecipeModel>>(
        stream: recipeService.getUserRecipes(userId),
        builder: (context, recipeSnapshot) {
          final recipes = recipeSnapshot.data ?? [];
          final recipeCount = recipes.length;
          final totalFavorites =
          recipes.fold<int>(0, (sum, r) => sum + r.favoriteCount);

          // Kullanıcının Firestore profilinden fotoğraf URL'sini çek
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (context, userSnapshot) {
              final userData =
              userSnapshot.data?.data() as Map<String, dynamic>?;
              final photoUrl = userData?['photoUrl'] as String?;

              return CustomScrollView(
                slivers: [
                  // ── Profil Kartı ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 2),
                              ),
                              child: ClipOval(
                                child: photoUrl != null
                                    ? Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _avatarFallback(userName),
                                )
                                    : _avatarFallback(userName),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // İsim
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // E-posta
                            Row(
                              children: [
                                const Icon(Icons.email_outlined,
                                    color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  userEmail,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // İstatistikler
                            Row(
                              children: [
                                _statBox(
                                  value: recipeSnapshot.connectionState ==
                                      ConnectionState.waiting
                                      ? '...'
                                      : '$recipeCount',
                                  label: s.isEnglish ? 'RECIPE' : 'TARİF',
                                ),
                                const SizedBox(width: 12),
                                _statBox(
                                  value: recipeSnapshot.connectionState ==
                                      ConnectionState.waiting
                                      ? '...'
                                      : totalFavorites >= 1000
                                      ? '${(totalFavorites / 1000).toStringAsFixed(1)}K'
                                      : '$totalFavorites',
                                  label: s.isEnglish
                                      ? 'FAVORITES'
                                      : 'FAVORİ',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Tarifler başlığı ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            s.isEnglish ? 'Recipes' : 'Tarifler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextDark
                                  : AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          if (recipeCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$recipeCount',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Tarif Listesi ──
                  if (recipeSnapshot.connectionState ==
                      ConnectionState.waiting)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (recipes.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu_outlined,
                                size: 64,
                                color: isDark
                                    ? AppColors.darkTextGrey
                                    : AppColors.textGrey),
                            const SizedBox(height: 16),
                            Text(
                              s.noRecipes,
                              style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextGrey
                                      : AppColors.textGrey,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => RecipeCard(
                            recipe: recipes[index],
                            isEnglish: s.isEnglish,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailScreen(
                                  recipe: recipes[index],
                                  isGuest: isGuest,
                                  strings: strings,
                                ),
                              ),
                            ),
                          ),
                          childCount: recipes.length,
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

  Widget _avatarFallback(String name) {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          (name.isNotEmpty ? name : 'U')[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _statBox({required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}