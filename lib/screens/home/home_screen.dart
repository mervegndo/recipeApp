// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/add_recipe_screen.dart';
import '../recipe/recipe_detail_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recipeService = RecipeService();
  final _searchController = TextEditingController();

  String _selectedCategory = 'all';
  String _searchQuery = '';
  int _currentIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? _buildHomeTab() : const ProfileScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
              ),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba 👋',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                    ),
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ?? 'Şef',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Icon(Icons.restaurant_menu,
                    color: AppColors.primary, size: 32),
              ],
            ),
          ),

          // Arama
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tarif ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Kategori filtresi
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('all', 'Tümü', '🍴'),
                ...AppCategories.categories.map(
                  (c) => _buildCategoryChip(c['key']!, c['label']!, c['emoji']!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tarif listesi
          Expanded(
            child: StreamBuilder<List<RecipeModel>>(
              stream: _selectedCategory == 'all'
                  ? _recipeService.getAllRecipes()
                  : _recipeService.getRecipesByCategory(_selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                var recipes = snapshot.data!;

                // Arama filtresi
                if (_searchQuery.isNotEmpty) {
                  recipes = recipes
                      .where((r) =>
                          r.title.toLowerCase().contains(_searchQuery) ||
                          r.ingredients.any((i) =>
                              i.toLowerCase().contains(_searchQuery)))
                      .toList();
                }

                if (recipes.isEmpty) {
                  return _buildEmptyState(
                      message: '"$_searchQuery" için sonuç bulunamadı');
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    return RecipeCard(
                      recipe: recipes[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RecipeDetailScreen(recipe: recipes[index]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label, String emoji) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$emoji $label'),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = key),
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textGrey,
          fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_meals, size: 64, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(
            message ?? 'Henüz tarif yok\nİlk tarifi sen ekle!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
