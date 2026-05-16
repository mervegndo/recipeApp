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

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.isGuest = false,
    this.isAdmin = false,
    required this.strings,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _recipeService  = RecipeService();
  final _notifService   = NotificationService();
  final _historyService = HistoryService();
  final _commentController = TextEditingController();

  bool   _isFavorite = false;
  bool   _isOwner    = false;
  double _userRating  = 0;
  int    _servingMultiplier = 1;

  @override
  void initState() {
    super.initState();
    _servingMultiplier = widget.recipe.servings;
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
    if (widget.isGuest) { _showGuestWarning(); return; }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _recipeService.toggleFavorite(user.uid, widget.recipe.id, _isFavorite);
    final nowFavorite = !_isFavorite;
    setState(() => _isFavorite = nowFavorite);

    if (nowFavorite && !_isOwner) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final fromName = userDoc.data()?['displayName'] as String?
          ?? user.displayName ?? user.email?.split('@').first ?? 'Someone';
      await _notifService.sendNotification(
        toUserId: widget.recipe.userId,
        fromUserName: fromName,
        type: 'favorite',
        recipeId: widget.recipe.id,
        recipeTitle: widget.recipe.title,
      );
    }
  }

  void _showGuestWarning() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.strings.guestWarning),
      backgroundColor: AppColors.primary,
    ));
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
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(s.isEnglish ? 'Share Recipe' : 'Tarifi Paylaş',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
            const SizedBox(height: 6),
            Text(recipe.title, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _ShareOption(
                icon: Icons.link_rounded,
                label: s.isEnglish ? 'Copy Link' : 'Linki Kopyala',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  final link = 'https://gusto.app/recipe/${recipe.id}';
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(s.isEnglish ? 'Link copied!' : 'Link kopyalandı!'),
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
                    content: Text(s.isEnglish ? 'Copied to clipboard!' : 'Panoya kopyalandı!'),
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

  // ─── Yorum ───────────────────────────────────────────────────────────────

  Future<void> _submitComment(RecipeModel recipe) async {
    if (widget.isGuest) { _showGuestWarning(); return; }
    if (_commentController.text.trim().isEmpty) return;
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.strings.isEnglish ? 'Please give a rating!' : 'Lütfen bir puan verin!'),
      ));
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final displayName = userDoc.data()?['displayName'] as String?
        ?? user.displayName ?? user.email?.split('@').first ?? 'User';
    final commentText = _commentController.text.trim();

    await _recipeService.addComment(
      recipeId: recipe.id, userId: user.uid,
      userEmail: user.email ?? '', userName: displayName,
      text: commentText, rating: _userRating,
    );

    if (!_isOwner) {
      await _notifService.sendNotification(
        toUserId: recipe.userId, fromUserName: displayName,
        type: 'comment', recipeId: recipe.id, recipeTitle: recipe.title,
        commentText: commentText, rating: _userRating,
      );
    }

    _commentController.clear();
    setState(() => _userRating = 0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.strings.commentAdded), backgroundColor: Colors.green,
      ));
    }
  }

  // ─── Porsiyon ölçek ───────────────────────────────────────────────────────

  String _scaleIngredient(String ingredient) {
    final orig = widget.recipe.servings;
    if (orig == _servingMultiplier || orig == 0) return ingredient;
    final ratio = _servingMultiplier / orig;
    return ingredient.replaceAllMapped(RegExp(r'(\d+(?:[.,]\d+)?)'), (m) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (v == null) return m.group(0)!;
      final scaled = v * ratio;
      return scaled == scaled.roundToDouble()
          ? scaled.toInt().toString()
          : scaled.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    });
  }

  String _currentWeekKey() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final week = ((now.difference(startOfYear).inDays + startOfYear.weekday - 1) / 7).ceil();
    return '${now.year}-${week.toString().padLeft(2, '0')}';
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final s        = widget.strings;
    final langCode = s.isEnglish ? 'en' : 'tr';
    final bgColor  = isDark ? AppColors.darkBackground : AppColors.background;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes').doc(widget.recipe.id).snapshots(),
      builder: (context, recipeSnap) {
        RecipeModel recipe = widget.recipe;
        if (recipeSnap.hasData && recipeSnap.data!.exists) {
          final data = recipeSnap.data!.data() as Map<String, dynamic>?;
          if (data != null) recipe = RecipeModel.fromMap(data, widget.recipe.id);
        }

        final localIngredients = recipe.localizedIngredients(langCode);

        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            slivers: [

              // ── AppBar ─────────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  // Paylaş butonu (her zaman)
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                    onPressed: () => _showShareSheet(recipe),
                    tooltip: s.isEnglish ? 'Share' : 'Paylaş',
                  ),
                  // Favori
                  if (!widget.isGuest)
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  // Düzenle
                  if (_isOwner)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EditRecipeScreen(recipe: recipe, strings: widget.strings),
                      )),
                    ),
                  // Sil
                  if (_isOwner || widget.isAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(s.deleteRecipeTitle),
                            content: Text(s.deleteRecipeConfirm),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
                              TextButton(onPressed: () => Navigator.pop(context, true),
                                  child: Text(s.delete, style: const TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (ok == true && mounted) {
                          await _recipeService.deleteRecipe(widget.recipe.id);
                          if (mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  // Admin: öne çıkar
                  if (widget.isAdmin)
                    IconButton(
                      icon: Icon(
                        recipe.featured ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: recipe.featured ? Colors.amber : Colors.white,
                      ),
                      tooltip: recipe.featured
                          ? (s.isEnglish ? 'Remove from Featured' : 'Öne Çıkarmayı Kaldır')
                          : (s.isEnglish ? 'Feature This Week' : 'Bu Hafta Öne Çıkar'),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('recipes').doc(recipe.id).update({
                          'featured': !recipe.featured,
                          'featuredWeek': !recipe.featured ? _currentWeekKey() : null,
                        });
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: recipe.imageUrl != null
                      ? CachedNetworkImage(
                      imageUrl: recipe.imageUrl!, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholderHeader(isDark))
                      : _placeholderHeader(isDark),
                ),
              ),

              // ── İçerik ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Kategori chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: (AppColors.categoryColors[recipe.category] ?? AppColors.textGrey).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${AppCategories.getEmojiByKey(recipe.category)} ${AppCategories.getLabelByKey(recipe.category, isEnglish: s.isEnglish)}',
                          style: TextStyle(
                            color: AppColors.categoryColors[recipe.category] ?? AppColors.textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Başlık
                      Text(recipe.localizedTitle(langCode),
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
                      const SizedBox(height: 10),

                      // Yıldızlar
                      Row(children: [
                        ...List.generate(5, (i) => Icon(
                          i < recipe.averageRating.round()
                              ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber, size: 22,
                        )),
                        const SizedBox(width: 8),
                        Text(
                          recipe.ratingCount > 0
                              ? '${recipe.averageRating.toStringAsFixed(1)} (${s.ratingCount(recipe.ratingCount)})'
                              : s.noRating,
                          style: TextStyle(fontSize: 13,
                              color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Meta kutular (süre / kişi / zorluk / kalori)
                      _buildMetaRow(recipe, s, isDark),
                      const SizedBox(height: 16),

                      // Diyet etiketleri
                      if (recipe.dietTags.isNotEmpty) ...[
                        Wrap(spacing: 8, runSpacing: 4,
                            children: recipe.dietTags.map((t) => _dietTag(t, s, isDark)).toList()),
                        const SizedBox(height: 16),
                      ],

                      // Favori sayısı
                      Row(children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Text(s.favoriteCount(recipe.favoriteCount),
                            style: TextStyle(fontSize: 13,
                                color: isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
                      ]),
                      const SizedBox(height: 16),

                      // Yazar kartı
                      _buildAuthorCard(recipe, isDark, s),
                      const SizedBox(height: 20),

                      // Açıklama
                      Text(recipe.localizedDescription(langCode),
                          style: TextStyle(fontSize: 15, height: 1.6,
                              color: isDark ? AppColors.darkTextGrey : AppColors.textMedium)),
                      const SizedBox(height: 24),

                      // Porsiyon ayarlayıcı
                      _buildServingSelector(s, isDark, recipe),
                      const SizedBox(height: 20),

                      // Malzemeler
                      _buildSection(
                        title: '🥕 ${s.ingredients} (${localIngredients.length})',
                        isDark: isDark,
                        children: localIngredients
                            .map((i) => _buildBulletItem(_scaleIngredient(i), isDark))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Yapılış
                      _buildSection(
                        title: '👨‍🍳 ${s.steps}',
                        isDark: isDark,
                        children: recipe.localizedSteps(langCode).asMap().entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primary.withOpacity(0.15),
                                child: Text('${e.key + 1}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(e.value,
                                  style: TextStyle(fontSize: 14, height: 1.5,
                                      color: isDark ? AppColors.darkTextDark : AppColors.textDark))),
                            ]),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Yorum formu
                      if (!widget.isGuest) _buildCommentForm(recipe, isDark, s),

                      // Yorumlar listesi
                      _buildCommentsList(recipe, isDark, s),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
            s.isEnglish ? 'min' : 'dk', isDark: isDark),
        _vDivider(isDark),
        _infoBox(Icons.people_outline, '$_servingMultiplier',
            s.isEnglish ? 'serv.' : 'kişi', isDark: isDark),
        _vDivider(isDark),
        _infoBox(Icons.bar_chart_rounded, _difficultyLabel(recipe.difficulty),
            s.difficulty, isDark: isDark, color: _difficultyColor(recipe.difficulty)),
        if (recipe.calories != null) ...[
          _vDivider(isDark),
          _infoBox(Icons.local_fire_department_outlined,
              '${recipe.calories}', s.calories, isDark: isDark),
        ],
      ]),
    );
  }

  Widget _infoBox(IconData icon, String value, String label,
      {required bool isDark, Color? color}) {
    return Expanded(child: Column(children: [
      Icon(icon, size: 20, color: color ?? (isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: color ?? (isDark ? AppColors.darkTextDark : AppColors.textDark))),
      Text(label, style: TextStyle(
          fontSize: 11, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
    ]));
  }

  Widget _vDivider(bool isDark) => Container(
    width: 1, height: 40,
    color: isDark ? const Color(0xFF3D3530) : AppColors.outline,
  );

  // ─── Porsiyon selector ────────────────────────────────────────────────────

  Widget _buildServingSelector(AppStrings s, bool isDark, RecipeModel recipe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(Icons.people_outline,
            color: isDark ? AppColors.darkTextGrey : AppColors.textGrey, size: 20),
        const SizedBox(width: 10),
        Text(s.servings, style: TextStyle(
            fontWeight: FontWeight.w600, fontSize: 15,
            color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
        const Spacer(),
        GestureDetector(
          onTap: _servingMultiplier > 1 ? () => setState(() => _servingMultiplier--) : null,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _servingMultiplier > 1
                  ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Icon(Icons.remove_rounded,
                color: _servingMultiplier > 1 ? AppColors.primary : AppColors.textGrey, size: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$_servingMultiplier',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        GestureDetector(
          onTap: () => setState(() => _servingMultiplier++),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
          ),
        ),
      ]),
    );
  }

  // ─── Section ─────────────────────────────────────────────────────────────

  Widget _buildSection({required String title, required bool isDark, required List<Widget> children}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
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
            width: 8, height: 8,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text,
            style: TextStyle(fontSize: 14, height: 1.5,
                color: isDark ? AppColors.darkTextDark : AppColors.textDark))),
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
          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
    );
  }

  // ─── Yazar kartı ──────────────────────────────────────────────────────────

  Widget _buildAuthorCard(RecipeModel recipe, bool isDark, AppStrings s) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(recipe.userId).snapshots(),
      builder: (ctx, snap) {
        final ud = snap.data?.data() as Map<String, dynamic>?;
        final photoUrl = ud?['photoUrl'] as String?;
        final name = ud?['displayName'] as String? ?? recipe.userEmail.split('@').first;

        return GestureDetector(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(
            builder: (_) => UserProfileScreen(
              userId: recipe.userId, userName: name,
              userEmail: recipe.userEmail, strings: widget.strings, isGuest: widget.isGuest,
            ),
          )),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(photoUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarText(name))
                      : _avatarText(name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                    color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
                Text(s.isEnglish ? 'Tap to see all recipes' : 'Tüm tarifleri görmek için tıkla',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              ])),
              Icon(Icons.chevron_right_rounded,
                  color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
            ]),
          ),
        );
      },
    );
  }

  Widget _avatarText(String name) => Container(
    color: Colors.white.withOpacity(0.2),
    child: Center(child: Text(
      (name.isNotEmpty ? name : 'U')[0].toUpperCase(),
      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
    )),
  );

  // ─── Yorum formu ─────────────────────────────────────────────────────────

  Widget _buildCommentForm(RecipeModel recipe, bool isDark, AppStrings s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.isEnglish ? 'Rate & Comment' : 'Puan ver & Yorum yap',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
      const SizedBox(height: 10),
      Row(children: [
        Text(s.yourRating,
            style: TextStyle(color: isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
        ...List.generate(5, (i) => GestureDetector(
          onTap: () => setState(() => _userRating = i + 1.0),
          child: Icon(
            i < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber, size: 30,
          ),
        )),
      ]),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: TextField(
          controller: _commentController,
          minLines: 1, maxLines: 3,
          decoration: InputDecoration(hintText: s.writeComment),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _submitComment(recipe),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  // ─── Yorumlar listesi ─────────────────────────────────────────────────────

  Widget _buildCommentsList(RecipeModel recipe, bool isDark, AppStrings s) {
    return StreamBuilder<QuerySnapshot>(
      stream: _recipeService.getComments(recipe.id),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('💬 ', style: TextStyle(fontSize: 18)),
            Text(s.comments, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
          ]),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            Text(s.noComments,
                style: TextStyle(color: isDark ? AppColors.darkTextGrey : AppColors.textGrey))
          else
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final rating = (data['rating'] as num?)?.toDouble() ?? 0;
              final currentUser = FirebaseAuth.instance.currentUser;
              final isMyComment = currentUser?.uid == data['userId'];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(data['userName'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                            color: isDark ? AppColors.darkTextDark : AppColors.textDark)),
                    const Spacer(),
                    Row(children: List.generate(5, (i) => Icon(
                      i < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 14, color: Colors.amber,
                    ))),
                    if (isMyComment || widget.isAdmin)
                      GestureDetector(
                        onTap: () => _recipeService.deleteComment(recipe.id, doc.id),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Text(data['text'] ?? '',
                      style: TextStyle(fontSize: 13,
                          color: isDark ? AppColors.darkTextGrey : AppColors.textMedium)),
                ]),
              );
            }),
        ]);
      },
    );
  }

  Widget _placeholderHeader(bool isDark) => Container(
    color: isDark ? AppColors.darkCard : AppColors.surfaceContainerHigh,
    child: Center(child: Icon(Icons.restaurant_menu_outlined, size: 64,
        color: isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
  );

  String _difficultyLabel(String d) {
    final s = widget.strings;
    switch (d) {
      case 'easy': return s.easy;
      case 'hard': return s.hard;
      default:     return s.medium;
    }
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'easy': return const Color(0xFF2E7D32);
      case 'hard': return const Color(0xFFBA1A1A);
      default:     return const Color(0xFFE65100);
    }
  }
}

// ─── Paylaşım seçenek butonu ──────────────────────────────────────────────────

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShareOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}