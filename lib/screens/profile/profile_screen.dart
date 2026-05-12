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
  const ProfileScreen({super.key});

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

  Future<void> _logout() async {
    await _authService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Column(
        children: [
          // Profil bilgileri
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (user?.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Kullanıcı',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sekmeler
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Tariflerim'),
              Tab(text: 'Favorilerim'),
            ],
          ),

          // Tab içerikleri
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 48, color: AppColors.textGrey),
                SizedBox(height: 12),
                Text('Henüz tarif eklemediniz',
                    style: TextStyle(color: AppColors.textGrey)),
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

        final data = userSnapshot.data!.data() as Map<String, dynamic>?;
        final favoriteIds =
            List<String>.from(data?['favoriteRecipeIds'] ?? []);

        if (favoriteIds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 48, color: AppColors.textGrey),
                SizedBox(height: 12),
                Text('Henüz favori tarif yok',
                    style: TextStyle(color: AppColors.textGrey)),
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipe: recipes[index])),
        ),
      ),
    );
  }
}
