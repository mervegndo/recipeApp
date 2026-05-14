// lib/screens/search/search_screen.dart

import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final AppStrings strings;
  final bool isGuest;

  const SearchScreen({
    super.key,
    required this.strings,
    required this.isGuest,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _recipeService = RecipeService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categoryIcons = [
    {'key': 'all', 'label': 'Tümü', 'labelEn': 'All', 'icon': Icons.restaurant_menu},
    {'key': 'breakfast', 'label': 'Kahvaltı', 'labelEn': 'Breakfast', 'icon': Icons.free_breakfast_outlined},
    {'key': 'lunch', 'label': 'Öğle', 'labelEn': 'Lunch', 'icon': Icons.lunch_dining_outlined},
    {'key': 'dinner', 'label': 'Akşam', 'labelEn': 'Dinner', 'icon': Icons.dinner_dining_outlined},
    {'key': 'dessert', 'label': 'Tatlı', 'labelEn': 'Dessert', 'icon': Icons.cake_outlined},
    {'key': 'snack', 'label': 'Atıştırmalık', 'labelEn': 'Snack', 'icon': Icons.fastfood_outlined},
    {'key': 'other', 'label': 'Diğer', 'labelEn': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              s.isEnglish ? 'Discover Recipes' : 'Tarif Keşfet',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextDark : AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              s.isEnglish
                  ? 'Search by name or ingredient'
                  : 'İsim veya malzemeye göre ara',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextGrey : AppColors.textGrey,
              ),
            ),
          ),

          // Arama kutusu
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF3D3530) : AppColors.outline,
                ),
                boxShadow: isDark
                    ? []
                    : [
                  BoxShadow(
                    color: AppColors.textDark.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: s.search,
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextGrey : AppColors.textGrey,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Kategoriler
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              s.isEnglish ? 'Popular Categories' : 'Kategoriler',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextDark : AppColors.textDark,
              ),
            ),
          ),

          // Kategori grid — 2 satır, yatay scroll
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categoryIcons.length,
              itemBuilder: (context, index) {
                final cat = _categoryIcons[index];
                final isSelected = _selectedCategory == cat['key'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['key']),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                ? AppColors.darkCard
                                : AppColors.surfaceContainer),
                            borderRadius: BorderRadius.circular(18),
                            border: isSelected
                                ? null
                                : Border.all(
                                color: isDark
                                    ? const Color(0xFF3D3530)
                                    : AppColors.outline),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                                : [],
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textMedium),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.isEnglish
                              ? cat['labelEn'] as String
                              : cat['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Sonuçlar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              _searchQuery.isNotEmpty
                  ? (s.isEnglish ? 'Results' : 'Sonuçlar')
                  : (s.isEnglish ? 'All Recipes' : 'Tüm Tarifler'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextDark : AppColors.textDark,
              ),
            ),
          ),

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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
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
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var recipes = snapshot.data!;

                if (_searchQuery.isNotEmpty) {
                  recipes = recipes
                      .where((r) =>
                  r.title.toLowerCase().contains(_searchQuery) ||
                      r.description.toLowerCase().contains(_searchQuery) ||
                      r.ingredients.any(
                              (i) => i.toLowerCase().contains(_searchQuery)))
                      .toList();
                }

                if (recipes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64,
                            color: isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textGrey),
                        const SizedBox(height: 16),
                        Text(
                          s.isEnglish
                              ? 'No results found for "$_searchQuery"'
                              : '"$_searchQuery" için sonuç bulunamadı',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) => RecipeCard(
                    recipe: recipes[index],
                    isEnglish: s.isEnglish,
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
              },
            ),
          ),
        ],
      ),
    );
  }
}