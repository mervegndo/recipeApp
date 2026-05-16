// lib/screens/recipe/recipe_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
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
  final _recipeService = RecipeService();
  final _commentController = TextEditingController();
  bool _isFavorite = false;
  bool _isOwner = false;
  double _userRating = 0;

  // Porsiyon ayarlayıcı — başlangıç değeri tarihin orijinal porsiyonu
  int _servingMultiplier = 1;

  @override
  void initState() {
    super.initState();
    _servingMultiplier = widget.recipe.servings;
    _checkFavoriteAndOwnership();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteAndOwnership() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isOwner = user.uid == widget.recipe.userId);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      final favorites =
      List<String>.from(doc.data()?['favoriteRecipeIds'] ?? []);
      setState(() => _isFavorite = favorites.contains(widget.recipe.id));
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.isGuest) {
      _showGuestWarning();
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _recipeService.toggleFavorite(
        user.uid, widget.recipe.id, _isFavorite);
    setState(() => _isFavorite = !_isFavorite);
  }

  void _showGuestWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.strings.guestWarning),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _submitComment() async {
    if (widget.isGuest) {
      _showGuestWarning();
      return;
    }
    if (_commentController.text.trim().isEmpty) return;
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.strings.isEnglish
              ? 'Please give a rating!'
              : 'Lütfen bir puan verin!'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;

    // Firestore'dan güncel displayName
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final displayName = userDoc.data()?['displayName'] as String? ??
        user.displayName ??
        user.email?.split('@').first ??
        'User';

    await _recipeService.addComment(
      recipeId: widget.recipe.id,
      userId: user.uid,
      userEmail: user.email ?? '',
      userName: displayName,
      text: _commentController.text.trim(),
      rating: _userRating,
    );

    _commentController.clear();
    setState(() => _userRating = 0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.strings.commentAdded),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Malzeme miktarını seçili porsiyon sayısına göre ölçekler.
  String _scaleIngredient(String ingredient) {
    final originalServings = widget.recipe.servings;
    if (originalServings == _servingMultiplier || originalServings == 0) {
      return ingredient;
    }
    final ratio = _servingMultiplier / originalServings;

    return ingredient.replaceAllMapped(
      RegExp(r'(\d+(?:[.,]\d+)?)'),
          (match) {
        final original =
        double.tryParse(match.group(1)!.replaceAll(',', '.'));
        if (original == null) return match.group(0)!;
        final scaled = original * ratio;
        if (scaled == scaled.roundToDouble()) {
          return scaled.toInt().toString();
        }
        return scaled.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;
    final langCode = s.isEnglish ? 'en' : 'tr';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .snapshots(),
      builder: (context, recipeSnap) {
        RecipeModel recipe = widget.recipe;
        if (recipeSnap.hasData && recipeSnap.data!.exists) {
          final data = recipeSnap.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            recipe = RecipeModel.fromMap(data, widget.recipe.id);
          }
        }

        final localIngredients = recipe.localizedIngredients(langCode);

        return Scaffold(
          backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── AppBar ──
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.background,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (!widget.isGuest)
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  if (_isOwner)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditRecipeScreen(
                            recipe: recipe,
                            strings: widget.strings,
                          ),
                        ),
                      ),
                    ),
                  if (_isOwner || widget.isAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(s.deleteRecipeTitle),
                            content: Text(s.deleteRecipeConfirm),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: Text(s.cancel),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: Text(s.delete,
                                    style: const TextStyle(
                                        color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && mounted) {
                          await _recipeService
                              .deleteRecipe(widget.recipe.id);
                          if (mounted) Navigator.pop(context);
                        }
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: recipe.imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: recipe.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholderHeader(),
                  )
                      : _placeholderHeader(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Kategori chip ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                          (AppColors.categoryColors[recipe.category] ??
                              AppColors.textGrey)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${AppCategories.getEmojiByKey(recipe.category)} ${AppCategories.getLabelByKey(recipe.category, isEnglish: s.isEnglish)}',
                          style: TextStyle(
                            color: AppColors.categoryColors[recipe.category] ??
                                AppColors.textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Başlık ──
                      Text(
                        recipe.localizedTitle(langCode),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextDark
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Puan yıldızları ──
                      Row(
                        children: [
                          ...List.generate(
                            5,
                                (i) => Icon(
                              i < recipe.averageRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            recipe.ratingCount > 0
                                ? '${recipe.averageRating.toStringAsFixed(1)} (${s.ratingCount(recipe.ratingCount)})'
                                : s.noRating,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextGrey
                                  : AppColors.textGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Süre / Porsiyon / Zorluk / Kalori kutusu ──
                      // FIX: tüm Text'ler isDark'a bağlı — karanlık temada görünür
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _infoBox(
                              Icons.access_time_outlined,
                              '${recipe.cookingTimeMinutes}',
                              s.isEnglish ? 'min' : 'dk',
                              isDark: isDark,
                            ),
                            _vDivider(isDark),
                            _infoBox(
                              Icons.people_outline,
                              '$_servingMultiplier',
                              s.isEnglish ? 'serv.' : 'kişi',
                              isDark: isDark,
                            ),
                            _vDivider(isDark),
                            _infoBox(
                              Icons.bar_chart_rounded,
                              _difficultyLabel(recipe.difficulty),
                              s.difficulty,
                              isDark: isDark,
                              color: _difficultyColor(recipe.difficulty),
                            ),
                            if (recipe.calories != null) ...[
                              _vDivider(isDark),
                              _infoBox(
                                Icons.local_fire_department_outlined,
                                '${recipe.calories}',
                                s.calories,
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Diyet etiketleri ──
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

                      // ── Favori sayısı ──
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            s.favoriteCount(recipe.favoriteCount),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextGrey
                                  : AppColors.textGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Kullanıcı kartı — Firestore realtime ──
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(recipe.userId)
                            .snapshots(),
                        builder: (context, userSnap) {
                          final userData = userSnap.data?.data()
                          as Map<String, dynamic>?;
                          final photoUrl =
                          userData?['photoUrl'] as String?;
                          final displayName =
                              userData?['displayName'] as String? ??
                                  recipe.userEmail.split('@').first;

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(
                                  userId: recipe.userId,
                                  userName: displayName,
                                  userEmail: recipe.userEmail,
                                  strings: widget.strings,
                                  isGuest: widget.isGuest,
                                ),
                              ),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                // FIX: dark modda görünür arka plan
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  // Avatar (fotoğraf varsa göster)
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFCB490E),
                                          Color(0xFFE8784A)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: photoUrl != null &&
                                          photoUrl.isNotEmpty
                                          ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _avatarText(displayName),
                                      )
                                          : _avatarText(displayName),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            // FIX: dark tema
                                            color: isDark
                                                ? AppColors.darkTextDark
                                                : AppColors.textDark,
                                          ),
                                        ),
                                        Text(
                                          s.isEnglish
                                              ? 'Tap to see all recipes'
                                              : 'Tüm tarifleri görmek için tıkla',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios,
                                      color: AppColors.primary, size: 14),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Açıklama ──
                      Text(
                        recipe.localizedDescription(langCode),
                        style: TextStyle(
                          fontSize: 15,
                          // FIX: dark modda görünür
                          color: isDark
                              ? AppColors.darkTextGrey
                              : AppColors.textDark,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Porsiyon ayarlayıcı ──
                      _buildServingSelector(s, isDark),
                      const SizedBox(height: 16),

                      // ── Malzemeler (ölçeklenmiş) ──
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

                      // ── Yapılış ──
                      _buildSection(
                        title: '👨‍🍳 ${s.steps}',
                        isDark: isDark,
                        children: recipe
                            .localizedSteps(langCode)
                            .asMap()
                            .entries
                            .map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                  AppColors.primary.withOpacity(0.15),
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                          ? AppColors.darkTextGrey
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // ── Yorum / Puan ekle ──
                      if (!widget.isGuest) ...[
                        Text(
                          s.isEnglish
                              ? 'Rate & Comment'
                              : 'Puan ver & Yorum yap',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextDark
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              s.yourRating,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextGrey
                                    : AppColors.textGrey,
                              ),
                            ),
                            ...List.generate(
                              5,
                                  (i) => GestureDetector(
                                onTap: () =>
                                    setState(() => _userRating = i + 1.0),
                                child: Icon(
                                  i < _userRating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: s.writeComment,
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextGrey
                                        : AppColors.textGrey,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? AppColors.darkCard
                                      : AppColors.surfaceContainer,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextDark
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _submitComment,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.send_rounded,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Yorumlar başlığı ──
                      Text(
                        '💬 ${s.comments}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextDark
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Yorumlar listesi ──
              StreamBuilder<QuerySnapshot>(
                stream: _recipeService.getComments(widget.recipe.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: Text(
                          s.noComments,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textGrey,
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data =
                          doc.data() as Map<String, dynamic>;
                          final rating =
                          (data['rating'] ?? 0).toDouble();
                          final userName =
                              data['userName'] as String? ??
                                  (data['userEmail'] as String? ?? '')
                                      .split('@')
                                      .first;
                          final isOwnComment =
                              FirebaseAuth.instance.currentUser?.uid ==
                                  data['userId'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.darkTextDark
                                            : AppColors.textDark,
                                      ),
                                    ),
                                    const Spacer(),
                                    ...List.generate(
                                      5,
                                          (i) => Icon(
                                        i < rating
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ),
                                    if (isOwnComment || widget.isAdmin)
                                      GestureDetector(
                                        onTap: () =>
                                            _recipeService.deleteComment(
                                                widget.recipe.id, doc.id),
                                        child: const Padding(
                                          padding:
                                          EdgeInsets.only(left: 8),
                                          child: Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                              color: Colors.red),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['text'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.darkTextGrey
                                        : AppColors.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: snapshot.data!.docs.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  //  Porsiyon ayarlayıcı widget
  // ════════════════════════════════════════════════════════
  Widget _buildServingSelector(AppStrings s, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF3D3530) : AppColors.outline,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.isEnglish ? 'Servings' : 'Porsiyon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextDark : AppColors.textDark,
              ),
            ),
          ),
          // Azalt
          GestureDetector(
            onTap: _servingMultiplier > 1
                ? () => setState(() => _servingMultiplier--)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _servingMultiplier > 1
                    ? AppColors.primary.withOpacity(0.12)
                    : (isDark
                    ? AppColors.darkSurface
                    : AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _servingMultiplier > 1
                      ? AppColors.primary.withOpacity(0.4)
                      : (isDark
                      ? const Color(0xFF3D3530)
                      : AppColors.outline),
                ),
              ),
              child: Icon(
                Icons.remove,
                size: 16,
                color: _servingMultiplier > 1
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextGrey : AppColors.textGrey),
              ),
            ),
          ),
          // Sayı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_servingMultiplier',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          // Artır
          GestureDetector(
            onTap: _servingMultiplier < 99
                ? () => setState(() => _servingMultiplier++)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: const Icon(Icons.add, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Yardımcı widget'lar
  // ════════════════════════════════════════════════════════

  Widget _avatarText(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextDark : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildBulletItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.darkTextGrey : AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderHeader() {
    return Container(
      color: const Color(0xFFF5F0EA),
      child: const Center(
          child:
          Icon(Icons.restaurant, size: 80, color: AppColors.textGrey)),
    );
  }

  Widget _infoBox(
      IconData icon,
      String value,
      String label, {
        Color? color,
        required bool isDark,
      }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            // FIX: const AppColors.textDark → isDark kontrolü
            color: color ??
                (isDark ? AppColors.darkTextDark : AppColors.textDark),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            // FIX: const AppColors.textGrey → isDark kontrolü
            color: isDark ? AppColors.darkTextGrey : AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _vDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      color: isDark ? const Color(0xFF3D3530) : const Color(0xFFE0E0E0),
    );
  }

  Widget _dietTag(String tag, AppStrings s, bool isDark) {
    final labels = {
      'vegetarian': s.isEnglish ? '🥦 Vegetarian' : '🥦 Vejetaryen',
      'vegan': '🌱 Vegan',
      'diet': s.isEnglish ? '🥗 Diet' : '🥗 Diyet',
      'protein': '💪 Protein',
      'carb': s.isEnglish ? '🍞 Carbs' : '🍞 Karbonhidrat',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        labels[tag] ?? tag,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextGrey : AppColors.textMedium,
        ),
      ),
    );
  }

  String _difficultyLabel(String difficulty) {
    final s = widget.strings;
    switch (difficulty) {
      case 'easy':
        return s.easy;
      case 'hard':
        return s.hard;
      default:
        return s.medium;
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}