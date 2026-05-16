// lib/screens/profile/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
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
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _recipeService = RecipeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.background,
        title: Text(
          widget.userName,
          style: TextStyle(
            fontSize: 17,
            color: isDark ? AppColors.darkTextDark : AppColors.textDark,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextDark : AppColors.textDark,
        ),
      ),
      body: Column(
        children: [
          // ── Profil Header ──
          StreamBuilder<List<RecipeModel>>(
            stream: _recipeService.getUserRecipes(widget.userId),
            builder: (context, recipeSnapshot) {
              final recipes = recipeSnapshot.data ?? [];
              final recipeCount = recipes.length;
              final totalFavorites =
              recipes.fold<int>(0, (sum, r) => sum + r.favoriteCount);

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  final userData =
                  userSnapshot.data?.data() as Map<String, dynamic>?;
                  final photoUrl = userData?['photoUrl'] as String?;
                  final displayName =
                      userData?['displayName'] as String? ?? widget.userName;

                  return Padding(
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
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(displayName),
                              )
                                  : _avatarFallback(displayName),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // İsim
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
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
                                widget.userEmail,
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
                                label: s.isEnglish ? 'FAVORITES' : 'FAVORİ',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ── Sekmeler ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor:
              isDark ? AppColors.darkTextGrey : AppColors.textGrey,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: s.isEnglish ? 'Recipes' : 'Tarifler'),
                Tab(text: s.isEnglish ? 'Favorites' : 'Favoriler'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Tab İçerikleri ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecipesTab(isDark, s),
                _buildFavoritesTab(isDark, s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarifler sekmesi ──
  Widget _buildRecipesTab(bool isDark, AppStrings s) {
    return StreamBuilder<List<RecipeModel>>(
      stream: _recipeService.getUserRecipes(widget.userId),
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
                Icon(Icons.restaurant_menu_outlined,
                    size: 64,
                    color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                const SizedBox(height: 16),
                Text(
                  s.noRecipes,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextGrey : AppColors.textGrey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        return _buildRecipeList(recipes);
      },
    );
  }

  // ── Favoriler sekmesi ──
  Widget _buildFavoritesTab(bool isDark, AppStrings s) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = userSnapshot.data!.data() as Map<String, dynamic>?;
        final favoriteIds =
        List<String>.from(data?['favoriteRecipeIds'] ?? []);

        if (favoriteIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border,
                    size: 64,
                    color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                const SizedBox(height: 16),
                Text(
                  s.isEnglish
                      ? 'No favorites yet'
                      : 'Henüz favori yok',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextGrey : AppColors.textGrey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<RecipeModel>>(
          future: _recipeService.getFavoriteRecipes(favoriteIds),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildRecipeList(snapshot.data!);
          },
        );
      },
    );
  }

  Widget _buildRecipeList(List<RecipeModel> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) => RecipeCard(
        recipe: recipes[index],
        isEnglish: widget.strings.isEnglish,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(
              recipe: recipes[index],
              isGuest: widget.isGuest,
              strings: widget.strings,
            ),
          ),
        ),
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