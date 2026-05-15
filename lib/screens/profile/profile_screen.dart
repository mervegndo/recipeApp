// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppStrings strings;

  const ProfileScreen({super.key, required this.strings});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _recipeService = RecipeService();
  final _authService = AuthService();

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
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    // Görünecek isim: displayName varsa onu, yoksa email'in @ öncesi, o da yoksa boş
    final displayName = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName!
        : (user?.email?.split('@').first ?? '');

    // Avatar baş harfi
    final avatarLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : '?');

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await _authService.logout(),
            tooltip: s.logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Profil header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: isDark
                  ? []
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFFFF8C69)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      avatarLetter,
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textGrey,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sekmeler
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor:
            isDark ? AppColors.darkTextGrey : AppColors.textGrey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: s.myRecipes),
              Tab(text: s.favorites),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyRecipesTab(user?.uid),
                _buildFavoritesTab(user?.uid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRecipesTab(String? userId) {
    if (userId == null) return const Center(child: Text('Giriş yapılmadı'));

    return StreamBuilder<List<RecipeModel>>(
      stream: _recipeService.getUserRecipes(userId),
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
                const Icon(Icons.add_circle_outline,
                    size: 64, color: AppColors.textGrey),
                const SizedBox(height: 16),
                Text(widget.strings.noRecipes,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 16)),
              ],
            ),
          );
        }
        return _buildRecipeList(recipes);
      },
    );
  }

  Widget _buildFavoritesTab(String? userId) {
    if (userId == null) return const Center(child: Text('Giriş yapılmadı'));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data =
        userSnapshot.data!.data() as Map<String, dynamic>?;
        final favoriteIds =
        List<String>.from(data?['favoriteRecipeIds'] ?? []);

        if (favoriteIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border,
                    size: 64, color: AppColors.textGrey),
                const SizedBox(height: 16),
                Text(widget.strings.noFavorites,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 16)),
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
              strings: widget.strings,
            ),
          ),
        ),
      ),
    );
  }
}