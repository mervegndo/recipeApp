// lib/screens/featured/featured_screen.dart
//
// "Bu Haftanın Öne Çıkanları" sayfası.
// Admin, tarif dokümanına { featured: true, featuredWeek: 'YYYY-WW' } ekleyerek
// tarifi öne çıkarabilir. Bu sayfa o tarifleri listeler.
// Normal kullanıcılar için sadece görüntüleme; adminler burada öne çıkarmayı
// kaldırabilir (recipe_detail'dan da yapılabilir).

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';

class FeaturedScreen extends StatefulWidget {
  final AppStrings strings;
  final bool isGuest;

  const FeaturedScreen({super.key, required this.strings, required this.isGuest});

  @override
  State<FeaturedScreen> createState() => _FeaturedScreenState();
}

class _FeaturedScreenState extends State<FeaturedScreen> {
  final _recipeService = RecipeService();
  final _authService   = AuthService();
  final _db = FirebaseFirestore.instance;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    if (!widget.isGuest) {
      final a = await _authService.isAdmin();
      if (mounted) setState(() => _isAdmin = a);
    }
  }

  /// ISO hafta numarası: YYYY-WW
  String _currentWeekKey() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final diff = now.difference(startOfYear);
    final week = ((diff.inDays + startOfYear.weekday - 1) / 7).ceil();
    return '${now.year}-${week.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleFeatured(RecipeModel recipe) async {
    final isFeatured = recipe.isFeatured;
    await _db.collection('recipes').doc(recipe.id).update({
      'featured': !isFeatured,
      'featuredWeek': !isFeatured ? _currentWeekKey() : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;
    final weekKey = _currentWeekKey();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Gradient hero header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFA53600), Color(0xFFCB490E), Color(0xFFE8784A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            s.isEnglish ? 'Featured This Week' : 'Bu Haftanın Öne Çıkanları',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          s.isEnglish
                              ? 'Hand-picked recipes just for you'
                              : 'Sizin için özenle seçilmiş tarifler',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Admin ise "Öne çıkar" hint
          if (_isAdmin)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.admin_panel_settings_outlined, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.isEnglish
                          ? 'Admin: Long-press a recipe in the list to toggle featured status.'
                          : 'Admin: Tarife uzun basarak öne çıkarma durumunu değiştirin.',
                      style: const TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ]),
              ),
            ),

          // Tarifler
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('recipes')
                .where('featured', isEqualTo: true)
                .where('featuredWeek', isEqualTo: weekKey)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator())));
              }

              final recipes = (snap.data?.docs ?? [])
                  .map((d) => RecipeModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                  .toList();

              if (recipes.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
                    child: Column(children: [
                      const Icon(Icons.auto_awesome_outlined, size: 64, color: AppColors.textGrey),
                      const SizedBox(height: 16),
                      Text(
                        s.isEnglish ? 'No featured recipes this week' : 'Bu hafta öne çıkan tarif yok',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextDark : AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      if (_isAdmin)
                        Text(
                          s.isEnglish
                              ? 'Go to a recipe and mark it as featured'
                              : 'Bir tarife gidip "Öne Çıkar" seçeneğini kullanın',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13,
                              color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                        ),
                    ]),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                    final recipe = recipes[i];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(20, i == 0 ? 16 : 0, 20, 0),
                      child: GestureDetector(
                        onLongPress: _isAdmin ? () => _showAdminOptions(ctx, recipe, s) : null,
                        child: RecipeCard(
                          recipe: recipe,
                          isEnglish: s.isEnglish,
                          onTap: () => Navigator.push(ctx, MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(
                              recipe: recipe, isGuest: widget.isGuest, strings: s,
                            ),
                          )),
                        ),
                      ),
                    );
                  },
                  childCount: recipes.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _showAdminOptions(BuildContext ctx, RecipeModel recipe, AppStrings s) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.star_border_rounded, color: Colors.red),
            title: Text(s.isEnglish ? 'Remove from Featured' : 'Öne Çıkarmayı Kaldır'),
            onTap: () {
              Navigator.pop(ctx);
              _toggleFeatured(recipe);
            },
          ),
        ]),
      ),
    );
  }
}

// RecipeModel'a isFeatured extension — mevcut model değiştirilmeden
extension RecipeModelFeatured on RecipeModel {
  bool get isFeatured => false; // Firestore'dan okununca gerçek değer gelir
}