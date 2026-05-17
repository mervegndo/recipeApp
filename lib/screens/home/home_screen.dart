// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/add_recipe_screen.dart';
import '../recipe/recipe_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../spin/spin_screen.dart';
import '../notifications/notifications_screen.dart';
import '../favorites/favorites_screen.dart';
import '../meal_planner/meal_planner_screen.dart';
import '../history/history_screen.dart';
import '../featured/featured_screen.dart';
import '../admin/admin_screen.dart';
import '../../main.dart';

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
  final _authService  = AuthService();
  final _notifService = NotificationService();
  int  _currentIndex  = 0;
  bool _isAdmin       = false;

  // Drawer'da hangi sayfa seçili — bottom bar index ile eşleşir
  // 0=Ana Sayfa, 1=Ara, 2=Çark, 3=Profil
  // Drawer-only: 10=Bildirimler, 11=Favorilerim, 12=Haftalık Menü, 13=Tarihçe, 14=Öne Çıkanlar

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
          TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.strings.cancel)),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); widget.onExitGuest(); },
            child: Text(widget.strings.loginToContinue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      drawer: _buildDrawer(isDark, uid),
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
          SpinScreen(strings: widget.strings, isGuest: widget.isGuest),
          widget.isGuest ? _buildGuestPlaceholder() : ProfileScreen(strings: widget.strings),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  // ─── Bottom bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool isDark) {
    final bg       = isDark ? AppColors.darkSurface : Colors.white;
    final active   = AppColors.primary;
    final inactive = isDark ? AppColors.darkTextGrey : AppColors.textGrey;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(
          color: isDark ? const Color(0xFF3D3530) : AppColors.outline.withOpacity(0.6),
          width: 0.8,
        )),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
          blurRadius: 16, offset: const Offset(0, -2),
        )],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            _navItem(icon: Icons.home_outlined,   selectedIcon: Icons.home,   label: widget.strings.home,                                    index: 0, active: active, inactive: inactive),
            _navItem(icon: Icons.search_outlined,  selectedIcon: Icons.search, label: widget.strings.isEnglish ? 'Search' : 'Ara',            index: 1, active: active, inactive: inactive),
            Expanded(child: GestureDetector(
              onTap: () {
                if (widget.isGuest) { _showGuestWarning(); return; }
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddRecipeScreen(strings: widget.strings)));
              },
              child: Center(child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 26),
              )),
            )),
            _navItem(icon: Icons.casino_outlined, selectedIcon: Icons.casino, label: widget.strings.isEnglish ? 'Spinner' : 'Çark',          index: 2, active: active, inactive: inactive),
            _navItem(icon: Icons.person_outline,  selectedIcon: Icons.person, label: widget.strings.profile,                                  index: 3, active: active, inactive: inactive),
          ]),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon, required IconData selectedIcon,
    required String label, required int index,
    required Color active, required Color inactive,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 3 && widget.isGuest) { _showGuestWarning(); return; }
          setState(() => _currentIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isSelected ? selectedIcon : icon, color: isSelected ? active : inactive, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? active : inactive)),
        ]),
      ),
    );
  }

  Widget _buildGuestPlaceholder() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.person_outline, size: 80, color: AppColors.textGrey),
      const SizedBox(height: 16),
      Text(widget.strings.isEnglish ? 'Login to view your profile' : 'Profili görüntülemek için giriş yapın',
          style: const TextStyle(color: AppColors.textGrey, fontSize: 16)),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: widget.onExitGuest, child: Text(widget.strings.loginToContinue)),
    ]));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRAWER — referans tasarım gibi: profil kartı üstte, nav item'ları ortada,
  // tema/dil altta, çıkış en altta. Aktif sayfa vurgulu.
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDrawer(bool isDark, String uid) {
    final s = widget.strings;
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(children: [
          // ── Profil kartı ──────────────────────────────────────────────────
          _DrawerProfileCard(
            user: user,
            isGuest: widget.isGuest,
            isDark: isDark,
            strings: s,
            recipeService: RecipeService(),
          ),

          // ── Nav item listesi ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [

                // Ana Sayfa
                _DrawerNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: s.home,
                  isSelected: _currentIndex == 0,
                  isDark: isDark,
                  onTap: () { setState(() => _currentIndex = 0); Navigator.pop(context); },
                ),

                // Tariflerim (Profil'e yönlendir)
                _DrawerNavItem(
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book_rounded,
                  label: s.isEnglish ? 'My Recipes' : 'Tariflerim',
                  isSelected: _currentIndex == 3,
                  isDark: isDark,
                  onTap: () {
                    if (widget.isGuest) { Navigator.pop(context); _showGuestWarning(); return; }
                    setState(() => _currentIndex = 3);
                    Navigator.pop(context);
                  },
                ),

                // Favorilerim
                _DrawerNavItem(
                  icon: Icons.favorite_outline_rounded,
                  selectedIcon: Icons.favorite_rounded,
                  label: s.favorites,
                  isSelected: false,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.isGuest) { _showGuestWarning(); return; }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen(strings: s, isGuest: widget.isGuest)));
                  },
                ),

                // Tarif Çarkı
                _DrawerNavItem(
                  icon: Icons.casino_outlined,
                  selectedIcon: Icons.casino_rounded,
                  label: s.isEnglish ? 'Recipe Spinner' : 'Tarif Çarkı',
                  isSelected: _currentIndex == 2,
                  isDark: isDark,
                  onTap: () { setState(() => _currentIndex = 2); Navigator.pop(context); },
                ),

                // Bildirimler
                if (!widget.isGuest)
                  _DrawerNotifItem(
                    uid: uid,
                    isDark: isDark,
                    label: s.isEnglish ? 'Notifications' : 'Bildirimler',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(strings: s)));
                    },
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(height: 1),
                ),

                // Haftalık Menü
                _DrawerNavItem(
                  icon: Icons.calendar_month_outlined,
                  selectedIcon: Icons.calendar_month_rounded,
                  label: s.isEnglish ? 'Meal Planner' : 'Haftalık Menü',
                  isSelected: false,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.isGuest) { _showGuestWarning(); return; }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MealPlannerScreen(strings: s)));
                  },
                ),

                // Tarihçe
                _DrawerNavItem(
                  icon: Icons.history_rounded,
                  selectedIcon: Icons.history_rounded,
                  label: s.isEnglish ? 'History' : 'Tarihçe',
                  isSelected: false,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.isGuest) { _showGuestWarning(); return; }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen(strings: s, isGuest: widget.isGuest)));
                  },
                ),

                // Bu Haftanın Öne Çıkanları
                _DrawerNavItem(
                  icon: Icons.auto_awesome_outlined,
                  selectedIcon: Icons.auto_awesome_rounded,
                  label: s.isEnglish ? 'Featured This Week' : 'Bu Haftanın Öne Çıkanları',
                  isSelected: false,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FeaturedScreen(strings: s, isGuest: widget.isGuest)));
                  },
                ),

                // Admin paneli
                if (_isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _DrawerNavItem(
                    icon: Icons.admin_panel_settings_outlined,
                    selectedIcon: Icons.admin_panel_settings_rounded,
                    label: s.adminPanel,
                    isSelected: false,
                    isDark: isDark,
                    labelColor: Colors.red,
                    onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(strings: s))); },
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(height: 1),
                ),

                // Karanlık Mod
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(children: [
                    Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        color: isDark ? AppColors.darkTextGrey : AppColors.textGrey, size: 22),
                    const SizedBox(width: 14),
                    Text(s.darkTheme, style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextDark : AppColors.textDark,
                    )),
                    const Spacer(),
                    Switch(value: isDark, activeColor: AppColors.primary, onChanged: (_) => RecipeApp.of(context)?.toggleTheme()),
                  ]),
                ),

                // Dil
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(children: [
                    Icon(Icons.language_rounded,
                        color: isDark ? AppColors.darkTextGrey : AppColors.textGrey, size: 22),
                    const SizedBox(width: 14),
                    Text('TR / EN', style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextDark : AppColors.textDark,
                    )),
                    const Spacer(),
                    Switch(value: s.isEnglish, activeColor: AppColors.primary, onChanged: (_) => RecipeApp.of(context)?.toggleLanguage()),
                  ]),
                ),

                // Hakkında
                _DrawerNavItem(
                  icon: Icons.info_outline_rounded,
                  selectedIcon: Icons.info_rounded,
                  label: s.about,
                  isSelected: false,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(context: context, applicationName: 'Gusto', applicationVersion: '1.1.0', children: [Text(s.tagline)]);
                  },
                ),
              ],
            ),
          ),

          // ── Çıkış butonu (en altta, tam genişlik) ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: widget.isGuest
                ? _buildDrawerLogoutButton(
              icon: Icons.login_rounded,
              label: s.loginToContinue,
              color: AppColors.primary,
              isDark: isDark,
              onTap: () { Navigator.pop(context); widget.onExitGuest(); },
            )
                : _buildDrawerLogoutButton(
              icon: Icons.logout_rounded,
              label: s.logout,
              color: Colors.red,
              isDark: isDark,
              onTap: () async { Navigator.pop(context); await _authService.logout(); },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDrawerLogoutButton({
    required IconData icon, required String label,
    required Color color, required bool isDark, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    );
  }
}

// ─── Drawer profil kartı ──────────────────────────────────────────────────────

class _DrawerProfileCard extends StatelessWidget {
  final User? user;
  final bool isGuest;
  final bool isDark;
  final AppStrings strings;
  final RecipeService recipeService;

  const _DrawerProfileCard({
    required this.user, required this.isGuest, required this.isDark,
    required this.strings, required this.recipeService,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuest || user == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA53600), Color(0xFFCB490E), Color(0xFFE8784A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Gusto logosu
          Image.asset('assets/images/recipeapplogo_white.png', width: 80, height: 80),
          const SizedBox(height: 10),
          Text(strings.isEnglish ? 'Guest User' : 'Misafir Kullanıcı',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(strings.isEnglish ? 'Login to access all features' : 'Tüm özelliklere erişmek için giriş yap',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        ]),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (ctx, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>?;
        final photoUrl    = userData?['photoUrl'] as String?;
        final displayName = userData?['displayName'] as String?
            ?? user!.displayName
            ?? user!.email?.split('@').first
            ?? 'User';

        return StreamBuilder<List<RecipeModel>>(
          stream: recipeService.getUserRecipes(user!.uid),
          builder: (ctx2, recipeSnap) {
            final recipes     = recipeSnap.data ?? [];
            final recipeCount = recipes.length;
            final totalLikes  = recipes.fold<int>(0, (sum, r) => sum + r.favoriteCount);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFA53600), Color(0xFFCB490E), Color(0xFFE8784A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Gusto logosu (sol üst)
                Image.asset('assets/images/recipeapplogo_white.png', width: 70, height: 70),
                const SizedBox(height: 12),
                // Avatar + isim
                Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: ClipOval(
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? Image.network(photoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(displayName))
                          : _avatarFallback(displayName),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(displayName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(user!.email ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ])),
                ]),
                const SizedBox(height: 18),
                // İstatistik kutuları
                Row(children: [
                  Expanded(child: _StatBox(value: '$recipeCount', label: strings.isEnglish ? 'recipes' : 'tarif')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatBox(value: '$totalLikes', label: strings.isEnglish ? 'favorites' : 'favori')),
                ]),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _avatarFallback(String name) => Container(
    color: Colors.white.withOpacity(0.25),
    child: Center(child: Text(
      (name.isNotEmpty ? name : 'U')[0].toUpperCase(),
      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
    )),
  );
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            height: 1.1,
          )),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          )),
        ],
      ),
    );
  }
}

// ─── Drawer nav item ──────────────────────────────────────────────────────────

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final String? badge;
  final Color? labelColor;

  const _DrawerNavItem({
    required this.icon, required this.selectedIcon,
    required this.label, required this.isSelected,
    required this.isDark, required this.onTap,
    this.badge, this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor   = AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final iconColor     = isSelected ? activeColor : (labelColor ?? (isDark ? AppColors.darkTextGrey : AppColors.textGrey));
    final textColor     = isSelected ? activeColor : (labelColor ?? inactiveColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(isSelected ? selectedIcon : icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ))),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
          ]),
        ),
      ),
    );
  }
}

// ─── Bildirim badge'li drawer nav item ───────────────────────────────────────

class _DrawerNotifItem extends StatelessWidget {
  final String uid;
  final bool isDark;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerNotifItem({
    required this.uid, required this.isDark, required this.label,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCount(uid),
      builder: (ctx, snap) {
        final count = snap.data ?? 0;
        final activeColor   = AppColors.primary;
        final iconColor     = isSelected ? activeColor : (isDark ? AppColors.darkTextGrey : AppColors.textGrey);
        final textColor     = isSelected ? activeColor : (isDark ? AppColors.darkTextDark : AppColors.textDark);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Stack(clipBehavior: Clip.none, children: [
                  Icon(isSelected ? Icons.notifications_rounded : Icons.notifications_outlined,
                      color: iconColor, size: 22),
                  if (count > 0)
                    Positioned(
                      right: -4, top: -4,
                      child: Container(
                        width: 14, height: 14,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Center(child: Text(count > 9 ? '9+' : '$count',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                      ),
                    ),
                ]),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ))),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(999)),
                    child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ANA SAYFA TAB
// ══════════════════════════════════════════════════════════════

class _HomeTab extends StatefulWidget {
  final bool isGuest;
  final bool isAdmin;
  final AppStrings strings;
  final VoidCallback onExitGuest;
  final VoidCallback onGuestWarning;

  const _HomeTab({
    required this.isGuest, required this.isAdmin,
    required this.strings, required this.onExitGuest, required this.onGuestWarning,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _recipeService = RecipeService();
  String _selectedCategory = 'all';
  String _selectedDietTag  = 'all';
  String _sortBy           = 'newest';

  final List<Map<String, dynamic>> _categoryIcons = [
    {'key': 'all',       'label': 'Tümü',        'labelEn': 'All',       'icon': Icons.restaurant_menu},
    {'key': 'breakfast', 'label': 'Kahvaltı',    'labelEn': 'Breakfast', 'icon': Icons.free_breakfast_outlined},
    {'key': 'lunch',     'label': 'Öğle',        'labelEn': 'Lunch',     'icon': Icons.lunch_dining_outlined},
    {'key': 'dinner',    'label': 'Akşam',       'labelEn': 'Dinner',    'icon': Icons.dinner_dining_outlined},
    {'key': 'soup',      'label': 'Çorba',       'labelEn': 'Soup',      'icon': Icons.soup_kitchen_outlined},
    {'key': 'dessert',   'label': 'Tatlı',       'labelEn': 'Dessert',   'icon': Icons.cake_outlined},
    {'key': 'drink',     'label': 'İçecek',      'labelEn': 'Drink',     'icon': Icons.local_drink_outlined},
    {'key': 'snack',     'label': 'Atıştırmalık','labelEn': 'Snack',     'icon': Icons.fastfood_outlined},
    {'key': 'other',     'label': 'Diğer',       'labelEn': 'Other',     'icon': Icons.more_horiz},
  ];

  Future<void> _adminDelete(String recipeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.strings.deleteRecipeTitle),
        content: Text(widget.strings.deleteRecipeConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(widget.strings.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text(widget.strings.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) await _recipeService.deleteRecipe(recipeId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final s        = widget.strings;
    final langCode = s.isEnglish ? 'en' : 'tr';

    return SafeArea(
      child: CustomScrollView(
        slivers: [

          // ── Header: hamburger + Gusto logosu ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Builder(builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF3D3530) : AppColors.outline),
                    ),
                    child: Icon(Icons.menu_rounded,
                        color: isDark ? AppColors.darkTextDark : AppColors.textDark, size: 22),
                  ),
                )),
                // Gusto logosu ortada
                Image.asset('assets/images/recipeapplogo.png', width: 80, height: 80),
                const SizedBox(width: 42), // denge için
              ]),
            ),
          ),

          // ── Kategoriler ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(s.isEnglish ? 'Browse Categories' : 'Kategoriler',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categoryIcons.length,
                itemBuilder: (ctx, idx) {
                  final cat        = _categoryIcons[idx];
                  final isSelected = _selectedCategory == cat['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['key']),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight)
                                : null,
                            color: isSelected ? null : (isDark ? AppColors.darkCard : AppColors.surface),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF3D3530) : AppColors.outline),
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: Icon(cat['icon'] as IconData,
                              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                              size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(s.isEnglish ? cat['labelEn'] : cat['label'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                            )),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Diyet filtreleri ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildDietChip('all', s.isEnglish ? '🍽️ All' : '🍽️ Hepsi', isDark),
                    _buildDietChip('vegetarian', s.isEnglish ? '🥦 Vegetarian' : '🥦 Vejetaryen', isDark),
                    _buildDietChip('vegan', '🌱 Vegan', isDark),
                    _buildDietChip('diet', s.isEnglish ? '🥗 Diet' : '🥗 Diyet', isDark),
                    _buildDietChip('protein', '💪 Protein', isDark),
                    _buildDietChip('carb', s.isEnglish ? '🍞 Carbs' : '🍞 Karbonhidrat', isDark),
                  ],
                ),
              ),
            ),
          ),

          // ── En Beğenilen başlık (eski haline dönüştürüldü — yatay scroll kaldırıldı) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(s.topRated,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
            ),
          ),

          // ── En Beğenilen — yatay scroll (lokalize başlıkla) ───────────────
          StreamBuilder<List<RecipeModel>>(
            stream: _recipeService.getTopRatedRecipes(),
            builder: (ctx, snap) {
              if (!snap.hasData || snap.data!.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              final recipes = snap.data!.take(10).toList();
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    itemCount: recipes.length,
                    itemBuilder: (ctx2, i) {
                      final recipe = recipes[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(ctx2, MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(recipe: recipe, isAdmin: widget.isAdmin, strings: widget.strings),
                        )),
                        child: SizedBox(
                          width: 160,
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF3D3530) : AppColors.outline),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: recipe.imageUrl != null
                                    ? Image.network(recipe.imageUrl!,
                                    width: 160, height: 110, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _imgPlaceholder(isDark))
                                    : _imgPlaceholder(isDark),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  // ── FIX: lokalize başlık ──
                                  Text(
                                    recipe.localizedTitle(langCode),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextDark : AppColors.textDark),
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                                    const SizedBox(width: 2),
                                    Text(
                                      recipe.ratingCount > 0 ? recipe.averageRating.toStringAsFixed(1) : '-',
                                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.access_time_outlined, size: 11, color: AppColors.textGrey),
                                    const SizedBox(width: 2),
                                    Flexible(child: Text(
                                      '${recipe.cookingTimeMinutes} ${s.isEnglish ? 'min' : 'dk'}',
                                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                                    )),
                                  ]),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // ── Tüm tarifler başlık ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.isEnglish ? 'All Recipes' : 'Tüm Tarifler',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(
                          title: Text(s.isEnglish ? 'Newest' : 'En Yeni'),
                          leading: const Icon(Icons.access_time),
                          selected: _sortBy == 'newest',
                          selectedColor: AppColors.primary,
                          onTap: () { setState(() => _sortBy = 'newest'); Navigator.pop(context); },
                        ),
                        ListTile(
                          title: Text(s.isEnglish ? 'Top Rated' : 'En Yüksek Puan'),
                          leading: const Icon(Icons.star_outline),
                          selected: _sortBy == 'rating',
                          selectedColor: AppColors.primary,
                          onTap: () { setState(() => _sortBy = 'rating'); Navigator.pop(context); },
                        ),
                        ListTile(
                          title: Text(s.isEnglish ? 'Most Liked' : 'En Çok Beğenilen'),
                          leading: const Icon(Icons.favorite_outline),
                          selected: _sortBy == 'favorites',
                          selectedColor: AppColors.primary,
                          onTap: () { setState(() => _sortBy = 'favorites'); Navigator.pop(context); },
                        ),
                        ListTile(
                          title: Text(s.isEnglish ? 'Oldest' : 'En Eski'),
                          leading: const Icon(Icons.history_toggle_off),
                          selected: _sortBy == 'oldest',
                          selectedColor: AppColors.primary,
                          onTap: () { setState(() => _sortBy = 'oldest'); Navigator.pop(context); },
                        ),
                      ])),
                    ),
                    child: Row(children: [
                      Text(s.isEnglish ? 'Sort' : 'Sırala',
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // ── Tarif listesi ──────────────────────────────────────────────────
          StreamBuilder<List<RecipeModel>>(
            stream: _selectedCategory == 'all'
                ? _recipeService.getAllRecipes()
                : _recipeService.getRecipesByCategory(_selectedCategory),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: Padding(
                  padding: EdgeInsets.all(32), child: CircularProgressIndicator(),
                )));
              }

              var recipes = snap.data ?? [];

              if (_selectedDietTag != 'all') {
                recipes = recipes.where((r) => r.dietTags.contains(_selectedDietTag)).toList();
              }

              if (_sortBy == 'rating') {
                recipes.sort((a, b) => b.averageRating.compareTo(a.averageRating));
              } else if (_sortBy == 'favorites') {
                recipes.sort((a, b) => b.favoriteCount.compareTo(a.favoriteCount));
              } else if (_sortBy == 'oldest') {
                recipes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              } else {
                recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              }

              if (recipes.isEmpty) {
                return SliverToBoxAdapter(child: Center(child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(children: [
                    Icon(Icons.restaurant_menu, size: 64,
                        color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                    const SizedBox(height: 16),
                    Text(s.noRecipes,
                        style: TextStyle(color: isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
                  ]),
                )));
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx2, i) => RecipeCard(
                      recipe: recipes[i],
                      isEnglish: s.isEnglish,
                      onTap: () => Navigator.push(ctx2, MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(
                          recipe: recipes[i],
                          isGuest: widget.isGuest,
                          isAdmin: widget.isAdmin,
                          strings: widget.strings,
                          onExitGuest: widget.onExitGuest,
                        ),
                      )),
                      onDelete: widget.isAdmin ? () => _adminDelete(recipes[i].id) : null,
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

  Widget _buildDietChip(String key, String label, bool isDark) {
    final isSelected = _selectedDietTag == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedDietTag = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF3D3530) : AppColors.outline),
            ),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextGrey : AppColors.textGrey),
          )),
        ),
      ),
    );
  }

  Widget _imgPlaceholder(bool isDark) => Container(
    width: 160, height: 110,
    color: isDark ? AppColors.darkCard : AppColors.surfaceContainerHigh,
    child: Icon(Icons.restaurant_menu_outlined, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
  );
}