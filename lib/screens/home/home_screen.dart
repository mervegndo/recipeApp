// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe_model.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/add_recipe_screen.dart';
import '../recipe/recipe_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../spin/spin_screen.dart';
import '../../main.dart';
import '../admin/admin_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  final VoidCallback onExitGuest;
  final AppStrings strings;

  const HomeScreen({
    super.key,
    required this.isGuest,
    required this.onExitGuest,
    required this.strings,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  int _currentIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    if (!widget.isGuest) {
      final admin = await _authService.isAdmin();
      if (mounted) setState(() => _isAdmin = admin);
    }
  }

  void _showGuestWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.strings.loginRequired),
        content: Text(widget.strings.loginRequiredMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onExitGuest();
            },
            child: Text(widget.strings.loginToContinue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: _buildDrawer(isDark),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            isGuest: widget.isGuest,
            isAdmin: _isAdmin,
            strings: widget.strings,
            onExitGuest: widget.onExitGuest,
            onGuestWarning: _showGuestWarning,
          ),
          SearchScreen(strings: widget.strings, isGuest: widget.isGuest),
          widget.isGuest
              ? _buildGuestPlaceholder()
              : ProfileScreen(strings: widget.strings),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          if (i == 2 && widget.isGuest) {
            _showGuestWarning();
            return;
          }
          setState(() => _currentIndex = i);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: widget.strings.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: widget.strings.isEnglish ? 'Search' : 'Ara',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: widget.strings.profile,
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          if (widget.isGuest) {
            _showGuestWarning();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddRecipeScreen(strings: widget.strings),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildGuestPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline,
              size: 80, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(
            widget.strings.isEnglish
                ? 'Login to view your profile'
                : 'Profili görüntülemek için giriş yapın',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onExitGuest,
            child: Text(widget.strings.loginToContinue),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(bool isDark) {
    final s = widget.strings;
    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFFCB490E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/recipeapplogo.png',
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(height: 12),
                  const Text('Lezzet Rehberi',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text(
                    widget.isGuest
                        ? (s.isEnglish ? 'Guest' : 'Misafir')
                        : (FirebaseAuth.instance.currentUser?.email ?? ''),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            if (_isAdmin)
              _drawerTile(
                icon: Icons.admin_panel_settings,
                label: s.adminPanel,
                color: Colors.red,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminScreen(strings: widget.strings),
                    ),
                  );
                },
              ),


            // Dark tema toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                      color: isDark
                          ? AppColors.darkTextGrey
                          : AppColors.textGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.darkTheme,
                        style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextDark
                                : AppColors.textDark,
                            fontSize: 15)),
                  ),
                  Switch(
                    value: isDark,
                    activeColor: AppColors.primary,
                    onChanged: (_) => RecipeApp.of(context)?.toggleTheme(),
                  ),
                ],
              ),
            ),

            // Dil toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.language,
                      color: isDark
                          ? AppColors.darkTextGrey
                          : AppColors.textGrey),
                  const SizedBox(width: 12),
                  Text('🇹🇷 TR',
                      style: TextStyle(
                        color: !s.isEnglish
                            ? AppColors.primary
                            : (isDark
                            ? AppColors.darkTextGrey
                            : AppColors.textGrey),
                        fontWeight: !s.isEnglish
                            ? FontWeight.bold
                            : FontWeight.normal,
                      )),
                  Switch(
                    value: s.isEnglish,
                    activeColor: AppColors.primary,
                    onChanged: (_) =>
                        RecipeApp.of(context)?.toggleLanguage(),
                  ),
                  Text('🇬🇧 EN',
                      style: TextStyle(
                        color: s.isEnglish
                            ? AppColors.primary
                            : (isDark
                            ? AppColors.darkTextGrey
                            : AppColors.textGrey),
                        fontWeight: s.isEnglish
                            ? FontWeight.bold
                            : FontWeight.normal,
                      )),
                ],
              ),
            ),

            const Divider(height: 24),

            _drawerTile(
              icon: Icons.info_outline,
              label: s.about,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Lezzet Rehberi',
                  applicationVersion: '1.0.0',
                  children: [Text(s.tagline)],
                );
              },
            ),

            _drawerTile(
              icon: Icons.privacy_tip_outlined,
              label: s.privacy,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(s.privacy),
                    content: const SingleChildScrollView(
                      child: Text(
                        'Bu uygulama, kullanıcıların yemek tariflerini paylaşması amacıyla geliştirilmiştir. '
                            'Kişisel verileriniz yalnızca uygulama işlevleri için kullanılmakta olup '
                            'üçüncü şahıslarla paylaşılmamaktadır.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(s.cancel),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),
            const Divider(),

            if (widget.isGuest)
              _drawerTile(
                icon: Icons.login,
                label: s.loginToContinue,
                color: AppColors.primary,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  widget.onExitGuest();
                },
              )
            else
              _drawerTile(
                icon: Icons.logout,
                label: s.logout,
                color: Colors.red,
                isDark: isDark,
                onTap: () async {
                  Navigator.pop(context);
                  await _authService.logout();
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: color ??
              (isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
      title: Text(label,
          style: TextStyle(
            color: color ??
                (isDark ? AppColors.darkTextDark : AppColors.textDark),
            fontWeight:
            color != null ? FontWeight.bold : FontWeight.normal,
          )),
      onTap: onTap,
    );
  }
}

// ---- ANA SAYFA TAB ----
class _HomeTab extends StatefulWidget {
  final bool isGuest;
  final bool isAdmin;
  final AppStrings strings;
  final VoidCallback onExitGuest;
  final VoidCallback onGuestWarning;

  const _HomeTab({
    required this.isGuest,
    required this.isAdmin,
    required this.strings,
    required this.onExitGuest,
    required this.onGuestWarning,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _recipeService = RecipeService();
  String _selectedCategory = 'all';
  String _selectedDietTag = 'all';
  String _sortBy = 'newest';

  final List<Map<String, dynamic>> _categoryIcons = [
    {'key': 'all', 'label': 'Tümü', 'labelEn': 'All', 'icon': Icons.restaurant_menu},
    {'key': 'breakfast', 'label': 'Kahvaltı', 'labelEn': 'Breakfast', 'icon': Icons.free_breakfast_outlined},
    {'key': 'lunch', 'label': 'Öğle', 'labelEn': 'Lunch', 'icon': Icons.lunch_dining_outlined},
    {'key': 'dinner', 'label': 'Akşam', 'labelEn': 'Dinner', 'icon': Icons.dinner_dining_outlined},
    {'key': 'dessert', 'label': 'Tatlı', 'labelEn': 'Dessert', 'icon': Icons.cake_outlined},
    {'key': 'snack', 'label': 'Atıştırmalık', 'labelEn': 'Snack', 'icon': Icons.fastfood_outlined},
    {'key': 'other', 'label': 'Diğer', 'labelEn': 'Other', 'icon': Icons.more_horiz},
  ];

  Future<void> _adminDelete(String recipeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.strings.deleteRecipeTitle),
        content: Text(widget.strings.deleteRecipeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.strings.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _recipeService.deleteRecipe(recipeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF3D3530) : AppColors.outline,
                          ),
                        ),
                        child: Icon(
                          Icons.menu_rounded,
                          color: isDark ? AppColors.darkTextDark : AppColors.textDark,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  // Logo + isim ortada
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/recipeapplogo.png',
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lezzet Rehberi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // Çarkıfelek butonu
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpinScreen(
                          strings: widget.strings,
                          isGuest: widget.isGuest,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.casino_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            s.isEnglish ? 'What to\nCook?' : 'Bugün ne\npişirsem?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Karşılama
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isGuest
                        ? (s.isEnglish ? 'Welcome 👋' : 'Hoş Geldiniz 👋')
                        : (s.isEnglish
                        ? 'Hello, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Chef'} 👋'
                        : 'Merhaba, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Şef'} 👋'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextGrey
                          : AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.isEnglish
                        ? 'What would you like\nto cook today?'
                        : 'Bugün ne pişirmek\nistersiniz?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextDark
                          : AppColors.textDark,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Kategoriler başlığı
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                s.isEnglish ? 'Browse Categories' : 'Kategoriler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextDark : AppColors.textDark,
                ),
              ),
            ),
          ),

          // Kategori grid
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categoryIcons.length,
                itemBuilder: (context, index) {
                  final cat = _categoryIcons[index];
                  final isSelected = _selectedCategory == cat['key'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat['key']),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                  ? AppColors.darkCard
                                  : AppColors.surfaceContainer),
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                  color: isDark
                                      ? const Color(0xFF3D3530)
                                      : AppColors.outline),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withOpacity(0.3),
                                  blurRadius: 8,
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
                              size: 26,
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
          ),

          // Diyet filtreleri
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                children: [
                  _buildDietChip('all',
                      s.isEnglish ? '🍽️ All' : '🍽️ Hepsi', isDark),
                  _buildDietChip('vegetarian',
                      s.isEnglish ? '🥦 Vegetarian' : '🥦 Vejetaryen', isDark),
                  _buildDietChip('vegan', '🌱 Vegan', isDark),
                  _buildDietChip('diet',
                      s.isEnglish ? '🥗 Diet' : '🥗 Diyet', isDark),
                  _buildDietChip('protein', '💪 Protein', isDark),
                  _buildDietChip('carb',
                      s.isEnglish ? '🍞 Carbs' : '🍞 Karbonhidrat', isDark),
                ],
              ),
            ),
          ),

          // En Popüler başlık
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.topRated,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextDark
                          : AppColors.textDark,
                    ),
                  ),
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFB347), size: 18),
                ],
              ),
            ),
          ),

          // Popüler tarifler - yatay scroll
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: StreamBuilder<List<RecipeModel>>(
                stream: _recipeService.getTopRatedRecipes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        s.isEnglish
                            ? 'No rated recipes yet'
                            : 'Henüz değerlendirilmiş tarif yok',
                        style: const TextStyle(color: AppColors.textGrey),
                      ),
                    );
                  }
                  final recipes = snapshot.data!.take(10).toList();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(
                              recipe: recipe,
                              isGuest: widget.isGuest,
                              isAdmin: widget.isAdmin,
                              strings: widget.strings,
                            ),
                          ),
                        ),
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3D3530)
                                  : AppColors.outline,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                child: recipe.imageUrl != null
                                    ? Image.network(
                                  recipe.imageUrl!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _imagePlaceholder(isDark),
                                )
                                    : _imagePlaceholder(isDark),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.darkTextDark
                                            : AppColors.textDark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            color: Color(0xFFFFB347),
                                            size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          recipe.averageRating
                                              .toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.darkTextGrey
                                                : AppColors.textGrey,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.access_time_outlined,
                                            size: 12,
                                            color: isDark
                                                ? AppColors.darkTextGrey
                                                : AppColors.textGrey),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${recipe.cookingTimeMinutes} ${s.isEnglish ? 'min' : 'dk'}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.darkTextGrey
                                                : AppColors.textGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Son Tarifler başlık
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.isEnglish ? 'Recent Recipes' : 'Son Tarifler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextDark
                          : AppColors.textDark,
                    ),
                  ),
                  Text(
                    s.isEnglish ? 'See All' : 'Tümünü Gör',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Son tarifler listesi
          StreamBuilder<List<RecipeModel>>(
            stream: _selectedCategory == 'all'
                ? _recipeService.getAllRecipes()
                : _recipeService.getRecipesByCategory(_selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(s.noRecipes,
                        style:
                        const TextStyle(color: AppColors.textGrey)),
                  ),
                );
              }

              var recipes = snapshot.data!;

              if (_selectedDietTag != 'all') {
                recipes = recipes
                    .where((r) => r.dietTags.contains(_selectedDietTag))
                    .toList();
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
                            isGuest: widget.isGuest,
                            isAdmin: widget.isAdmin,
                            strings: widget.strings,
                          ),
                        ),
                      ),
                      onDelete: widget.isAdmin
                          ? () => _adminDelete(recipes[index].id)
                          : null,
                    ),
                    childCount: recipes.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      height: 120,
      width: double.infinity,
      color: isDark ? AppColors.darkCard : AppColors.surfaceContainerHigh,
      child: Icon(Icons.restaurant_menu,
          size: 32,
          color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
    );
  }

  Widget _buildDietChip(String key, String label, bool isDark) {
    final isSelected = _selectedDietTag == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedDietTag = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textGrey.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                  ? AppColors.darkTextGrey
                  : AppColors.textGrey),
              fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}