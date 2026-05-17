// lib/screens/recipe/recipe_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../services/notification_service.dart';
import '../../services/history_service.dart';
import '../../utils/app_constants.dart';
import '../profile/user_profile_screen.dart';
import 'edit_recipe_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;
  final bool isGuest;
  final bool isAdmin;
  final AppStrings strings;
  /// Misafir "Giriş Yap" butonuna basınca çağrılır.
  final VoidCallback? onExitGuest;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.isGuest = false,
    this.isAdmin = false,
    required this.strings,
    this.onExitGuest,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _recipeService     = RecipeService();
  final _notifService      = NotificationService();
  final _historyService    = HistoryService();
  final _commentController = TextEditingController();

  bool   _isFavorite        = false;
  bool   _isOwner           = false;
  bool   _isFeatured        = false;
  double _userRating        = 0;
  int    _servingMultiplier = 1;

  @override
  void initState() {
    super.initState();
    _servingMultiplier = widget.recipe.servings;
    _isFeatured = widget.recipe.featured;
    _checkFavoriteAndOwnership();
    _recordHistory();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _recordHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _historyService.addToHistory(
      userId: user.uid,
      recipeId: widget.recipe.id,
      title: widget.recipe.title,
      imageUrl: widget.recipe.imageUrl,
      category: widget.recipe.category,
    );
  }

  Future<void> _checkFavoriteAndOwnership() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isOwner = user.uid == widget.recipe.userId);
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).get();
    if (doc.exists) {
      final favs = List<String>.from(doc.data()?['favoriteRecipeIds'] ?? []);
      setState(() => _isFavorite = favs.contains(widget.recipe.id));
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.isGuest) { _showGuestDialog(); return; }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _recipeService.toggleFavorite(user.uid, widget.recipe.id, _isFavorite);
    setState(() => _isFavorite = !_isFavorite);
  }

  // ─── Featured toggle ──────────────────────────────────────────────────────

  String _currentWeekKey() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final diff = now.difference(startOfYear);
    final week = ((diff.inDays + startOfYear.weekday - 1) / 7).ceil();
    return '${now.year}-${week.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleFeatured(RecipeModel recipe) async {
    final newVal = !_isFeatured;
    await FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipe.id)
        .update({
      'featured': newVal,
      'featuredWeek': newVal ? _currentWeekKey() : null,
    });
    if (mounted) setState(() => _isFeatured = newVal);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newVal
            ? (widget.strings.isEnglish
            ? 'Added to Featured This Week!'
            : 'Haftanın Öne Çıkanlarına eklendi!')
            : (widget.strings.isEnglish
            ? 'Removed from Featured This Week'
            : 'Haftanın Öne Çıkanlarından kaldırıldı')),
        backgroundColor: newVal ? Colors.amber.shade700 : Colors.grey,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  // ─── Guest dialog ─────────────────────────────────────────────────────────

  void _showGuestDialog() {
    final s = widget.strings;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.loginRequired),
        content: Text(s.loginRequiredMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _goToLogin(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.login),
          ),
        ],
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onExitGuest?.call();
  }

  // ─── Paylaş ──────────────────────────────────────────────────────────────

  void _showShareSheet(RecipeModel recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(
              s.isEnglish ? 'Share Recipe' : 'Tarifi Paylaş',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextDark : AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              recipe.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _ShareOption(
                icon: Icons.link_rounded,
                label: s.isEnglish ? 'Copy Link' : 'Linki Kopyala',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(
                      text: 'https://gusto.app/recipe/${recipe.id}'));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        s.isEnglish ? 'Link copied!' : 'Link kopyalandı!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ));
                },
              ),
              _ShareOption(
                icon: Icons.ios_share_rounded,
                label: s.isEnglish ? 'Share' : 'Paylaş',
                color: const Color(0xFF5F5E5E),
                onTap: () {
                  Navigator.pop(context);
                  final text = s.isEnglish
                      ? 'Check out "${recipe.title}" on Gusto!\nhttps://gusto.app/recipe/${recipe.id}'
                      : '"${recipe.title}" tarifine Gusto\'dan bak!\nhttps://gusto.app/recipe/${recipe.id}';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                    Text(s.isEnglish ? 'Copied!' : 'Kopyalandı!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ));
                },
              ),
            ]),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  // ─── Yorum gönder ────────────────────────────────────────────────────────

  Future<void> _submitComment(RecipeModel recipe) async {
    if (widget.isGuest) { _showGuestDialog(); return; }
    if (_commentController.text.trim().isEmpty) return;
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.strings.isEnglish
            ? 'Please give a rating!'
            : 'Lütfen bir puan verin!'),
      ));
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).get();
    final displayName = userDoc.data()?['displayName'] as String?
        ?? user.displayName
        ?? user.email?.split('@').first
        ?? 'User';
    final commentText = _commentController.text.trim();

    await _recipeService.addComment(
      recipeId: recipe.id,
      userId: user.uid,
      userEmail: user.email ?? '',
      userName: displayName,
      text: commentText,
      rating: _userRating,
    );

    _commentController.clear();
    setState(() => _userRating = 0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.strings.commentAdded),
        backgroundColor: Colors.green,
      ));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final s        = widget.strings;
    final langCode = s.isEnglish ? 'en' : 'tr';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .snapshots(),
      builder: (ctx, snap) {
        final data   = snap.data?.data() as Map<String, dynamic>?;
        final recipe = data != null
            ? RecipeModel.fromMap(data, widget.recipe.id)
            : widget.recipe;

        final localIngredients = recipe.localizedIngredients(langCode);

        return Scaffold(
          backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── App bar ─────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor:
                isDark ? AppColors.darkBackground : Colors.white,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                actions: [
                  // Paylaş
                  GestureDetector(
                    onTap: () => _showShareSheet(recipe),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.ios_share_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  // Favori
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle),
                      child: Icon(
                        _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isFavorite ? Colors.red : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  // Admin — Haftanın Öne Çıkanlarına ekle/çıkar
                  if (widget.isAdmin)
                    GestureDetector(
                      onTap: () => _toggleFeatured(recipe),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle),
                        child: Icon(
                          _isFeatured
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                    ),
                  // Düzenle / Sil (sahip veya admin)
                  if (_isOwner || widget.isAdmin)
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.more_vert_rounded,
                            color: Colors.white, size: 18),
                      ),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditRecipeScreen(
                                  recipe: recipe,
                                  strings: widget.strings),
                            ),
                          );
                        } else if (val == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(s.deleteRecipeTitle),
                              content: Text(s.deleteRecipeConfirm),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(s.cancel)),
                                ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: Text(s.delete)),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _recipeService.deleteRecipe(recipe.id);
                            if (mounted) Navigator.pop(context);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              const Icon(Icons.edit_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(s.edit),
                            ])),
                        PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(s.delete,
                                  style: const TextStyle(color: Colors.red)),
                            ])),
                      ],
                    ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: recipe.imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: recipe.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _imagePlaceholder(isDark),
                  )
                      : _imagePlaceholder(isDark),
                ),
              ),

              // ── İçerik ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık  (kategori chip KALDIRILDI)
                        Text(
                          recipe.localizedTitle(langCode),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextDark
                                  : AppColors.textDark),
                        ),
                        const SizedBox(height: 10),

                        // Yıldızlar
                        Row(children: [
                          ...List.generate(
                            5,
                                (i) => Icon(
                              i < recipe.averageRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            recipe.ratingCount > 0
                                ? '${recipe.averageRating.toStringAsFixed(1)} (${s.ratingCount(recipe.ratingCount)})'
                                : s.noRating,
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextGrey
                                    : AppColors.textGrey),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Meta (süre, porsiyon, zorluk, kalori)
                        _buildMetaRow(recipe, s, isDark),
                        const SizedBox(height: 16),

                        // Diyet etiketleri
                        if (recipe.dietTags.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: recipe.dietTags
                                .map((t) => _dietTag(t, s, isDark))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Favori sayısı
                        Row(children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            s.favoriteCount(recipe.favoriteCount),
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextGrey
                                    : AppColors.textGrey),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Yazar kartı
                        _buildAuthorCard(recipe, isDark, s),
                        const SizedBox(height: 20),

                        // Açıklama
                        Text(
                          recipe.localizedDescription(langCode),
                          style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: isDark
                                  ? AppColors.darkTextGrey
                                  : AppColors.textMedium),
                        ),
                        const SizedBox(height: 24),

                        // Porsiyon seçici
                        _buildServingSelector(s, isDark, recipe),
                        const SizedBox(height: 20),

                        // Malzemeler
                        _buildSection(
                          title:
                          '🥕 ${s.ingredients} (${localIngredients.length})',
                          isDark: isDark,
                          children: localIngredients
                              .map((i) =>
                              _buildBulletItem(_scaleIngredient(i), isDark))
                              .toList(),
                        ),
                        const SizedBox(height: 24),

                        // Yapılış adımları
                        _buildSection(
                          title: '👨‍🍳 ${s.steps}',
                          isDark: isDark,
                          children: recipe
                              .localizedSteps(langCode)
                              .asMap()
                              .entries
                              .map((e) => Padding(
                            padding:
                            const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.15),
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: isDark
                                            ? AppColors.darkTextDark
                                            : AppColors.textDark),
                                  ),
                                ),
                              ],
                            ),
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),

                        // Yorum bölümü
                        _buildCommentSection(recipe, isDark, s),

                        // Yorumlar listesi
                        _buildCommentsList(recipe, isDark, s),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Image placeholder ───────────────────────────────────────────────────

  Widget _imagePlaceholder(bool isDark) => Container(
    color: isDark ? AppColors.darkCard : AppColors.surfaceContainer,
    child: const Center(
        child: Icon(Icons.restaurant_outlined,
            size: 64, color: AppColors.textGrey)),
  );

  // ─── Meta row ────────────────────────────────────────────────────────────

  Widget _buildMetaRow(RecipeModel recipe, AppStrings s, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        _infoBox(Icons.access_time_outlined, '${recipe.cookingTimeMinutes}',
            s.isEnglish ? 'min' : 'dk',
            isDark: isDark),
        _vDivider(isDark),
        _infoBox(Icons.people_outline, '$_servingMultiplier',
            s.isEnglish ? 'serv.' : 'kişi',
            isDark: isDark),
        _vDivider(isDark),
        _infoBox(Icons.bar_chart_rounded,
            _difficultyLabel(recipe.difficulty), s.difficulty,
            isDark: isDark, color: _difficultyColor(recipe.difficulty)),
        if (recipe.calories != null) ...[
          _vDivider(isDark),
          _infoBox(Icons.local_fire_department_outlined,
              '${recipe.calories}', s.calories,
              isDark: isDark),
        ],
      ]),
    );
  }

  Widget _infoBox(IconData icon, String value, String label,
      {required bool isDark, Color? color}) {
    return Expanded(
        child: Column(children: [
          Icon(icon,
              size: 20,
              color: color ??
                  (isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color ??
                      (isDark ? AppColors.darkTextDark : AppColors.textDark))),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color:
                  isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
        ]));
  }

  Widget _vDivider(bool isDark) => Container(
    width: 1,
    height: 40,
    color: isDark
        ? const Color(0xFF3D3530)
        : AppColors.outline,
  );

  // ─── Porsiyon seçici ─────────────────────────────────────────────────────

  Widget _buildServingSelector(
      AppStrings s, bool isDark, RecipeModel recipe) {
    return Row(children: [
      Text(s.isEnglish ? 'Servings:' : 'Porsiyon:',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color:
              isDark ? AppColors.darkTextDark : AppColors.textDark)),
      const Spacer(),
      GestureDetector(
        onTap: _servingMultiplier > 1
            ? () => setState(() => _servingMultiplier--)
            : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _servingMultiplier > 1
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Icon(Icons.remove_rounded,
              color: _servingMultiplier > 1
                  ? AppColors.primary
                  : AppColors.textGrey,
              size: 18),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('$_servingMultiplier',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ),
      GestureDetector(
        onTap: () => setState(() => _servingMultiplier++),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: const Icon(Icons.add_rounded,
              color: AppColors.primary, size: 18),
        ),
      ),
    ]);
  }

  // ─── Section başlığı + içerik ─────────────────────────────────────────────

  Widget _buildSection(
      {required String title,
        required bool isDark,
        required List<Widget> children}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
              isDark ? AppColors.darkTextDark : AppColors.textDark)),
      const SizedBox(height: 12),
      ...children,
    ]);
  }

  Widget _buildBulletItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? AppColors.darkTextDark
                        : AppColors.textDark))),
      ]),
    );
  }

  // ─── Diyet tag ────────────────────────────────────────────────────────────

  Widget _dietTag(String tag, AppStrings s, bool isDark) {
    final labels = {
      'vegetarian': s.isEnglish ? '🥦 Vegetarian' : '🥦 Vejetaryen',
      'vegan': '🌱 Vegan',
      'diet': s.isEnglish ? '🥗 Diet' : '🥗 Diyet',
      'protein': '💪 Protein',
      'carb': s.isEnglish ? '🍞 Carbs' : '🍞 Karbonhidrat',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Text(labels[tag] ?? tag,
          style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w600)),
    );
  }

  // ─── Yazar kartı ──────────────────────────────────────────────────────────

  Widget _buildAuthorCard(
      RecipeModel recipe, bool isDark, AppStrings s) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(recipe.userId)
          .snapshots(),
      builder: (ctx, snap) {
        final ud = snap.data?.data() as Map<String, dynamic>?;
        final photoUrl = ud?['photoUrl'] as String?;
        final name = ud?['displayName'] as String? ??
            recipe.userEmail.split('@').first;

        return GestureDetector(
          onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => UserProfileScreen(
                    userId: recipe.userId,
                    userName: name,
                    userEmail: recipe.userEmail,
                    strings: widget.strings,
                    isGuest: widget.isGuest,
                  ))),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard
                  : AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarText(name))
                      : _avatarText(name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark
                                    ? AppColors.darkTextDark
                                    : AppColors.textDark)),
                        Text(
                          s.isEnglish
                              ? 'Tap to see all recipes'
                              : 'Tüm tarifleri görmek için tıkla',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.primary),
                        ),
                      ])),
              Icon(Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.darkTextGrey
                      : AppColors.textGrey),
            ]),
          ),
        );
      },
    );
  }

  Widget _avatarText(String name) => Container(
    color: Colors.white.withOpacity(0.2),
    child: Center(
        child: Text(
          (name.isNotEmpty ? name : 'U')[0].toUpperCase(),
          style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        )),
  );

  // ─── Yorum bölümü ─────────────────────────────────────────────────────────

  Widget _buildCommentSection(
      RecipeModel recipe, bool isDark, AppStrings s) {
    if (widget.isGuest) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          s.isEnglish ? 'Rate & Comment' : 'Yorum Yap',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
              isDark ? AppColors.darkTextDark : AppColors.textDark),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Text(s.yourRating,
              style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextGrey
                      : AppColors.textGrey)),
          ...List.generate(
              5,
                  (i) => GestureDetector(
                onTap: _showGuestDialog,
                child: const Icon(Icons.star_outline_rounded,
                    color: Colors.amber, size: 30),
              )),
        ]),
        const SizedBox(height: 16),
        Divider(
            color:
            isDark ? const Color(0xFF3D3530) : AppColors.outline),
        const SizedBox(height: 12),
        Text(s.loginRequired,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextDark
                    : AppColors.textDark)),
        const SizedBox(height: 6),
        Text(s.loginRequiredMsg,
            style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? AppColors.darkTextGrey
                    : AppColors.textGrey)),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _goToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.login,
                style:
                const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 24),
      ]);
    }

    return _buildCommentForm(recipe, isDark, s);
  }

  Widget _buildCommentForm(
      RecipeModel recipe, bool isDark, AppStrings s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        s.isEnglish ? 'Rate & Comment' : 'Puan ver & Yorum yap',
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
            isDark ? AppColors.darkTextDark : AppColors.textDark),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Text(s.yourRating,
            style: TextStyle(
                color: isDark
                    ? AppColors.darkTextGrey
                    : AppColors.textGrey)),
        ...List.generate(
            5,
                (i) => GestureDetector(
              onTap: () => setState(() => _userRating = i + 1.0),
              child: Icon(
                i < _userRating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 30,
              ),
            )),
      ]),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            minLines: 1,
            maxLines: 3,
            decoration:
            InputDecoration(hintText: s.writeComment),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _submitComment(recipe),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.send_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  // ─── Yorumlar listesi ─────────────────────────────────────────────────────

  Widget _buildCommentsList(
      RecipeModel recipe, bool isDark, AppStrings s) {
    return StreamBuilder<QuerySnapshot>(
      stream: _recipeService.getComments(recipe.id),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('💬 ', style: TextStyle(fontSize: 18)),
                Text(s.comments,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextDark
                            : AppColors.textDark)),
              ]),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                Text(s.noComments,
                    style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextGrey
                            : AppColors.textGrey))
              else
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rating =
                      (data['rating'] as num?)?.toDouble() ?? 0;
                  final userName =
                      data['userName'] as String? ?? 'Kullanıcı';
                  final text = data['text'] as String? ?? '';
                  final ts = data['createdAt'] as Timestamp?;
                  final date = ts != null
                      ? '${ts.toDate().day}.${ts.toDate().month}.${ts.toDate().year}'
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? const Color(0xFF3D3530)
                              : AppColors.outline),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(userName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextDark
                                        : AppColors.textDark)),
                            const Spacer(),
                            Text(date,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextGrey
                                        : AppColors.textGrey)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            ...List.generate(
                                5,
                                    (i) => Icon(
                                  i < rating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                )),
                          ]),
                          if (text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(text,
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors.darkTextGrey
                                        : AppColors.textMedium)),
                          ],
                        ]),
                  );
                }),
            ]);
      },
    );
  }

  // ─── Yardımcılar ─────────────────────────────────────────────────────────

  String _difficultyLabel(String d) {
    if (d == 'easy') return widget.strings.easy;
    if (d == 'medium') return widget.strings.medium;
    return widget.strings.hard;
  }

  Color _difficultyColor(String d) {
    if (d == 'easy') return Colors.green;
    if (d == 'medium') return Colors.orange;
    return Colors.red;
  }

  String _scaleIngredient(String ingredient) {
    final orig = widget.recipe.servings;
    if (orig == _servingMultiplier || orig == 0) return ingredient;
    final ratio = _servingMultiplier / orig;
    return ingredient.replaceAllMapped(RegExp(r'(\d+(?:[.,]\d+)?)'), (m) {
      final v =
      double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (v == null) return m.group(0)!;
      final scaled = v * ratio;
      if (scaled == scaled.roundToDouble())
        return scaled.toInt().toString();
      return scaled.toStringAsFixed(1);
    });
  }
}

// ─── Share Option widget ──────────────────────────────────────────────────────

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}