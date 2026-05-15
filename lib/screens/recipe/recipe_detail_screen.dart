// lib/screens/recipe/recipe_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
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

  // Kişi sayısı scaler
  late int _currentServings;

  // Tarif sahibinin profil bilgileri
  String? _ownerDisplayName;
  String? _ownerPhotoUrl;
  bool _ownerLoading = true;

  @override
  void initState() {
    super.initState();
    _currentServings = widget.recipe.servings > 0 ? widget.recipe.servings : 1;
    _checkFavoriteAndOwnership();
    _loadOwnerProfile();
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
      if (mounted) {
        setState(() => _isFavorite = favorites.contains(widget.recipe.id));
      }
    }
  }

  Future<void> _loadOwnerProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipe.userId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _ownerDisplayName = data['displayName'] as String?;
          _ownerPhotoUrl = data['photoUrl'] as String?;
          _ownerLoading = false;
        });
      } else if (mounted) {
        setState(() => _ownerLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _ownerLoading = false);
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
    if (mounted) setState(() => _isFavorite = !_isFavorite);
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
    await _recipeService.addComment(
      recipeId: widget.recipe.id,
      userId: user.uid,
      userEmail: user.email ?? '',
      userName: user.displayName ?? user.email?.split('@').first ?? '',
      text: _commentController.text.trim(),
      rating: _userRating,
    );

    _commentController.clear();
    if (mounted) setState(() => _userRating = 0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.strings.commentAdded),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.strings.deleteRecipeTitle),
        content: Text(widget.strings.deleteRecipeConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(widget.strings.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(widget.strings.delete,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _recipeService.deleteRecipe(widget.recipe.id);
      if (mounted) Navigator.pop(context);
    }
  }

  // Malzeme miktarını kişi sayısına göre ölçekle
  String _scaleIngredient(String ingredient) {
    final baseServings =
    widget.recipe.servings > 0 ? widget.recipe.servings : 1;
    if (_currentServings == baseServings) return ingredient;

    final ratio = _currentServings / baseServings;

    // Sayı + birim formatını bul ve ölçekle (örn: "200g", "2 tbsp", "3 adet")
    return ingredient.replaceAllMapped(
      RegExp(r'(\d+(?:[.,]\d+)?)'),
          (match) {
        final original = double.tryParse(
            match.group(1)!.replaceAll(',', '.'));
        if (original == null) return match.group(0)!;
        final scaled = original * ratio;
        // Tam sayıysa tam göster, değilse 1 ondalık
        if (scaled == scaled.roundToDouble()) {
          return scaled.toInt().toString();
        } else {
          return scaled.toStringAsFixed(1);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final s = widget.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor =
    isDark ? AppColors.darkTextDark : AppColors.textDark;
    final subColor =
    isDark ? AppColors.darkTextGrey : AppColors.textGrey;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final surfaceColor =
    isDark ? AppColors.darkSurface : AppColors.surfaceContainer;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---- Büyük fotoğraf header ----
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white),
                onPressed: _toggleFavorite,
              ),
              if (_isOwner || widget.isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
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
                  icon:
                  const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: _deleteRecipe,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: recipe.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholderHeader(isDark),
              )
                  : _placeholderHeader(isDark),
            ),
          ),

          // ---- İçerik ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori etiketi
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: (AppColors.categoryColors[recipe.category] ??
                          AppColors.textGrey)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${AppCategories.getEmojiByKey(recipe.category)} ${AppCategories.getLabelByKey(recipe.category, isEnglish: s.isEnglish)}',
                      style: TextStyle(
                        color:
                        AppColors.categoryColors[recipe.category] ??
                            AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Başlık
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Puan
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
                        style: TextStyle(color: subColor, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Süre / Porsiyon / Zorluk / Kalori kutusu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3D3530)
                            : AppColors.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoBox(
                          Icons.access_time_outlined,
                          '${recipe.cookingTimeMinutes} ${s.isEnglish ? 'min' : 'dk'}',
                          s.duration,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        _vDivider(isDark),
                        _infoBox(
                          Icons.people_outline,
                          '${recipe.servings} ${s.isEnglish ? 'serv.' : 'kişi'}',
                          s.servings,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        _vDivider(isDark),
                        _infoBox(
                          Icons.bar_chart,
                          _difficultyLabel(recipe.difficulty, s),
                          s.difficulty,
                          textColor: _difficultyColor(recipe.difficulty),
                          subColor: subColor,
                          iconColor: _difficultyColor(recipe.difficulty),
                        ),
                        if (recipe.calories != null) ...[
                          _vDivider(isDark),
                          _infoBox(
                            Icons.local_fire_department_outlined,
                            '${recipe.calories} kcal',
                            s.calories,
                            textColor: Colors.orange,
                            subColor: subColor,
                            iconColor: Colors.orange,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Diyet etiketleri
                  if (recipe.dietTags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                      recipe.dietTags.map((tag) => _dietTag(tag, s)).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Favori sayısı
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        s.favoriteCount(recipe.favoriteCount),
                        style: TextStyle(color: subColor, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---- Tarif sahibi kartı ----
                  _buildOwnerCard(isDark, textColor, subColor, cardColor),
                  const SizedBox(height: 20),

                  // ---- Açıklama ----
                  Text(
                    recipe.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ---- Kişi sayısı scaler ----
                  _buildServingsScaler(s, isDark, textColor, subColor, cardColor),
                  const SizedBox(height: 20),

                  // ---- Malzemeler ----
                  _buildSectionTitle(
                    '🥕 ${s.ingredients} ($_currentServings ${s.isEnglish ? 'servings' : 'kişi için'})',
                    textColor,
                  ),
                  const SizedBox(height: 12),
                  ...recipe.ingredients
                      .map((i) => _buildBulletItem(
                    _scaleIngredient(i),
                    isDark,
                    textColor,
                  ))
                      .toList(),
                  const SizedBox(height: 28),

                  // ---- Yapılış ----
                  _buildSectionTitle('👨‍🍳 ${s.steps}', textColor),
                  const SizedBox(height: 12),
                  ...recipe.steps.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                            AppColors.primary.withOpacity(0.12),
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
                                  color: textColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 28),

                  // ---- Yorumlar ----
                  _buildCommentsSection(s, isDark, textColor, subColor, cardColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Kişi sayısı ayarlayıcı ----
  Widget _buildServingsScaler(
      AppStrings s,
      bool isDark,
      Color textColor,
      Color subColor,
      Color cardColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3D3530) : AppColors.outline,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.people_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.isEnglish ? 'Adjust servings' : 'Kişi sayısını ayarla',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
          // Azalt butonu
          GestureDetector(
            onTap: () {
              if (_currentServings > 1) {
                setState(() => _currentServings--);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _currentServings > 1
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.remove, color: Colors.white, size: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$_currentServings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          // Artır butonu
          GestureDetector(
            onTap: () {
              if (_currentServings < 50) {
                setState(() => _currentServings++);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Tarif sahibi kartı ----
  Widget _buildOwnerCard(
      bool isDark,
      Color textColor,
      Color subColor,
      Color cardColor,
      ) {
    final displayName = _ownerDisplayName?.isNotEmpty == true
        ? _ownerDisplayName!
        : widget.recipe.userEmail.split('@').first;
    final avatarLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3D3530) : AppColors.outline,
        ),
      ),
      child: Row(
        children: [
          // Avatar — fotoğraf varsa göster, yoksa gradient harf
          ClipOval(
            child: _ownerLoading
                ? Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFF8C69)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
                : (_ownerPhotoUrl != null && _ownerPhotoUrl!.isNotEmpty)
                ? CachedNetworkImage(
              imageUrl: _ownerPhotoUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  _avatarFallback(avatarLetter),
            )
                : _avatarFallback(avatarLetter),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.strings.isEnglish
                      ? 'Tap to see all recipes'
                      : 'Tüm tarifleri görmek için tıkla',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: subColor),
        ],
      ),
    );
  }

  Widget _avatarFallback(String letter) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF8C69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ---- Yorumlar bölümü ----
  Widget _buildCommentsSection(
      AppStrings s,
      bool isDark,
      Color textColor,
      Color subColor,
      Color cardColor,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('💬 ${s.comments}', textColor),
        const SizedBox(height: 16),

        // Misafir uyarısı
        if (widget.isGuest) ...[
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.isEnglish
                          ? 'Login to leave a comment and rate this recipe'
                          : 'Yorum yapmak ve puan vermek için giriş yapın',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: AppColors.primary, size: 14),
                ],
              ),
            ),
          ),
        ],

        // Yorum formu
        if (!widget.isGuest) ...[
          Row(
            children: [
              Text(s.yourRating,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: textColor)),
              ...List.generate(5, (i) {
                return GestureDetector(
                  onTap: () =>
                      setState(() => _userRating = i + 1.0),
                  child: Icon(
                    i < _userRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: s.writeComment,
                    hintStyle: TextStyle(color: subColor),
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitComment,
                child: Text(s.send),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Yorum listesi
        StreamBuilder<QuerySnapshot>(
          stream: _recipeService.getComments(widget.recipe.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(s.noComments,
                      style: TextStyle(color: subColor)),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final isCommentOwner =
                    FirebaseAuth.instance.currentUser?.uid ==
                        data['userId'];
                final commentName = (data['userName'] as String?)
                    ?.isNotEmpty ==
                    true
                    ? data['userName'] as String
                    : (data['userEmail'] as String? ?? '')
                    .split('@')
                    .first;
                final commentLetter = commentName.isNotEmpty
                    ? commentName[0].toUpperCase()
                    : '?';
                final rating = (data['rating'] ?? 0).toDouble();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3D3530)
                          : AppColors.outline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Yorum sahibi avatarı
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  Color(0xFFFF8C69)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                commentLetter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  commentName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                        (i) => Icon(
                                      i < rating.round()
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCommentOwner || widget.isAdmin)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                              onPressed: () => _recipeService.deleteComment(
                                  widget.recipe.id, doc.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['text'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ---- Yardımcı widgetlar ----

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildBulletItem(String text, bool isDark, Color textColor) {
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
              style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderHeader(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCard : const Color(0xFFF5F0EA),
      child: Center(
        child: Icon(Icons.restaurant,
            size: 80,
            color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
      ),
    );
  }

  Widget _infoBox(
      IconData icon,
      String value,
      String label, {
        required Color textColor,
        required Color subColor,
        Color? iconColor,
      }) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: subColor),
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

  Widget _dietTag(String tag, AppStrings s) {
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
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text(
        labels[tag] ?? tag,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _difficultyLabel(String d, AppStrings s) {
    switch (d) {
      case 'easy':
        return s.easy;
      case 'hard':
        return s.hard;
      default:
        return s.medium;
    }
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'easy':
        return const Color(0xFF2E7D32);
      case 'hard':
        return const Color(0xFFBA1A1A);
      default:
        return const Color(0xFFE65100);
    }
  }
}