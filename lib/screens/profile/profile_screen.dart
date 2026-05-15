// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/recipe_model.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppStrings strings;

  const ProfileScreen({super.key, required this.strings});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _recipeService = RecipeService();
  final _authService = AuthService();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _changeProfilePhoto() async {
    final s = widget.strings;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: Text(s.isEnglish ? 'Take Photo' : 'Fotoğraf Çek'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: Text(s.isEnglish ? 'Choose from Gallery' : 'Galeriden Seç'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: source, imageQuality: 75, maxWidth: 512);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');
      await ref.putFile(File(picked.path));
      final downloadUrl = await ref.getDownloadURL();
      await user.updatePhotoURL(downloadUrl);
      await user.reload();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.strings.isEnglish
                ? 'Failed to update photo. Please try again.'
                : 'Fotoğraf güncellenemedi. Lütfen tekrar deneyin.'),
            backgroundColor: const Color(0xFFE65100),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    // AppBar başlığı: tam ad
    final fullName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : s.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await _authService.logout(),
            tooltip: s.logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Profil header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: isDark
                  ? []
                  : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04), blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                // Profil fotoğrafı – tıklanabilir
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _changeProfilePhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFFF8C69)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isUploadingPhoto
                            ? const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                        )
                            : ClipOval(
                          child: user?.photoURL != null
                              ? Image.network(
                            user!.photoURL!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _initialsWidget(user),
                          )
                              : _initialsWidget(user),
                        ),
                      ),
                      // Kamera ikonu
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user?.displayName != null && user!.displayName!.isNotEmpty)
                            ? user.displayName!
                            : (s.isEnglish ? 'User' : 'Kullanıcı'),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textGrey,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _isUploadingPhoto ? null : _changeProfilePhoto,
                        child: Text(
                          s.isEnglish
                              ? 'Change profile photo'
                              : 'Profil fotoğrafını değiştir',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sekmeler
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor:
            isDark ? AppColors.darkTextGrey : AppColors.textGrey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: s.myRecipes),
              Tab(text: s.favorites),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyRecipesTab(user?.uid),
                _buildFavoritesTab(user?.uid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsWidget(User? user) {
    return Center(
      child: Text(
        (user?.displayName ?? 'U')[0].toUpperCase(),
        style: const TextStyle(
            fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMyRecipesTab(String? userId) {
    if (userId == null) {
      return Center(
          child: Text(widget.strings.isEnglish ? 'Not logged in' : 'Giriş yapılmadı'));
    }

    return StreamBuilder<List<RecipeModel>>(
      stream: _recipeService.getUserRecipes(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final recipes = snapshot.data ?? [];
        if (recipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline,
                    size: 64, color: AppColors.textGrey),
                const SizedBox(height: 16),
                Text(widget.strings.noRecipes,
                    style:
                    const TextStyle(color: AppColors.textGrey, fontSize: 16)),
              ],
            ),
          );
        }
        return _buildRecipeList(recipes);
      },
    );
  }

  Widget _buildFavoritesTab(String? userId) {
    if (userId == null) {
      return Center(
          child: Text(widget.strings.isEnglish ? 'Not logged in' : 'Giriş yapılmadı'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = userSnapshot.data!.data() as Map<String, dynamic>?;
        final favoriteIds =
        List<String>.from(data?['favoriteRecipeIds'] ?? []);

        if (favoriteIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border,
                    size: 64, color: AppColors.textGrey),
                const SizedBox(height: 16),
                Text(widget.strings.noFavorites,
                    style:
                    const TextStyle(color: AppColors.textGrey, fontSize: 16)),
              ],
            ),
          );
        }

        // getFavoriteRecipes Future döndürüyor → FutureBuilder kullan
        return FutureBuilder<List<RecipeModel>>(
          future: _recipeService.getFavoriteRecipes(favoriteIds),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildRecipeList(snapshot.data!);
          },
        );
      },
    );
  }

  Widget _buildRecipeList(List<RecipeModel> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) => RecipeCard(
        recipe: recipes[index],
        isEnglish: widget.strings.isEnglish,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(
              recipe: recipes[index],
              strings: widget.strings,
            ),
          ),
        ),
      ),
    );
  }
}