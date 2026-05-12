// lib/screens/recipe/recipe_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _recipeService = RecipeService();
  bool _isFavorite = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteAndOwnership();
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _recipeService.toggleFavorite(
        user.uid, widget.recipe.id, _isFavorite);
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tarifi Sil'),
        content: const Text('Bu tarifi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil',
                  style: TextStyle(color: Colors.red))),
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Fotoğraflı app bar
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
              if (_isOwner)
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
                      '${AppCategories.getEmojiByKey(recipe.category)} ${AppCategories.getLabelByKey(recipe.category)}',
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

                  // Kullanıcı & tarih
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
                          fontSize: 15, color: AppColors.textDark, height: 1.5)),
                  const SizedBox(height: 24),

                  // Malzemeler
                  _buildSection(
                    title: '🥕 Malzemeler (${recipe.ingredients.length})',
                    children: recipe.ingredients
                        .map((i) => _buildBulletItem(i))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Yapılış
                  _buildSection(
                    title: '👨‍🍳 Yapılış',
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
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
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
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
}
