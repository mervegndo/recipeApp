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

  @override
  void initState() {
    super.initState();
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
    await _recipeService.addComment(
      recipeId: widget.recipe.id,
      userId: user.uid,
      userEmail: user.email ?? '',
      userName: user.displayName ?? 'Kullanıcı',
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

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final s = widget.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
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
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: _deleteRecipe,
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
                  // Kategori
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
                        color: AppColors.categoryColors[recipe.category] ??
                            AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Başlık
                  Text(recipe.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
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
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Süre, porsiyon, zorluk, kalori
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark
                          ? []
                          : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoBox(
                            Icons.access_time_outlined,
                            '${recipe.cookingTimeMinutes} ${s.isEnglish ? 'min' : 'dk'}',
                            s.duration),
                        _divider(),
                        _infoBox(
                            Icons.people_outline,
                            '${recipe.servings} ${s.isEnglish ? 'serv.' : 'kişi'}',
                            s.servings),
                        _divider(),
                        _infoBox(
                            Icons.bar_chart,
                            _difficultyLabel(recipe.difficulty),
                            s.difficulty,
                            color: _difficultyColor(recipe.difficulty)),
                        if (recipe.calories != null) ...[
                          _divider(),
                          _infoBox(
                              Icons.local_fire_department_outlined,
                              '${recipe.calories} kcal',
                              s.calories,
                              color: Colors.orange),
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
                      children: recipe.dietTags
                          .map((tag) => _dietTag(tag, s))
                          .toList(),
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
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Kullanıcı
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Text(recipe.userEmail,
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Açıklama
                  Text(recipe.description,
                      style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textDark,
                          height: 1.5)),
                  const SizedBox(height: 24),

                  // Malzemeler
                  _buildSection(
                    title:
                    '🥕 ${s.ingredients} (${recipe.ingredients.length})',
                    children: recipe.ingredients
                        .map((i) => _buildBulletItem(i))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Yapılış
                  _buildSection(
                    title: '👨‍🍳 ${s.steps}',
                    children: recipe.steps.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                              AppColors.primary.withOpacity(0.1),
                              child: Text('${e.key + 1}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(e.value,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.5)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  _buildCommentsSection(s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('💬 ${s.comments}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.strings.isEnglish
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

        // Giriş yapmış kullanıcı için yorum formu
        if (!widget.isGuest) ...[
          Row(
            children: [
              Text(s.yourRating,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              ...List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _userRating = i + 1.0),
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
                  decoration: InputDecoration(hintText: s.writeComment),
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
                      style: const TextStyle(color: AppColors.textGrey)),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final isCommentOwner =
                    FirebaseAuth.instance.currentUser?.uid == data['userId'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkCard
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              (data['userName'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['userName'] ?? 'Kullanıcı',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Row(
                                  children: List.generate(
                                    5,
                                        (i) => Icon(
                                      i < (data['rating'] ?? 0)
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
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(data['text'] ?? '',
                          style: const TextStyle(fontSize: 14)),
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

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _placeholderHeader() {
    return Container(
      color: const Color(0xFFF5F0EA),
      child: const Center(
          child: Icon(Icons.restaurant, size: 80, color: AppColors.textGrey)),
    );
  }

  Widget _infoBox(IconData icon, String value, String label,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color ?? AppColors.textDark)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _divider() {
    return Container(
        width: 1, height: 40, color: const Color(0xFFE0E0E0));
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
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(labels[tag] ?? tag,
          style: const TextStyle(
              fontSize: 12, color: AppColors.secondary)),
    );
  }

  String _difficultyLabel(String d) {
    switch (d) {
      case 'easy':
        return widget.strings.easy;
      case 'hard':
        return widget.strings.hard;
      default:
        return widget.strings.medium;
    }
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'easy':
        return Colors.green;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}