// lib/screens/profile/profile_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/recipe_model.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../services/imgbb_service.dart';
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

  // ── Profili Düzenle bottom sheet ──
  void _openEditProfile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(
        user: user,
        strings: s,
        isDark: isDark,
        onSaved: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.background,
        title: Text(s.profile),
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
          // ── Profil Header Kartı ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: StreamBuilder<List<RecipeModel>>(
              stream: _recipeService.getUserRecipes(user?.uid ?? ''),
              builder: (context, recipeSnapshot) {
                final recipes = recipeSnapshot.data ?? [];
                final recipeCount = recipes.length;
                final totalFavorites = recipes.fold<int>(
                    0, (sum, r) => sum + r.favoriteCount);

                // Fotoğraf URL'sini FirebaseAuth'tan al
                final photoUrl = FirebaseAuth
                    .instance.currentUser?.photoURL;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 2),
                            ),
                            child: ClipOval(
                              child: photoUrl != null
                                  ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(user),
                              )
                                  : _avatarFallback(user),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // İsim
                          Text(
                            user?.displayName ?? 'Kullanıcı',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // E-posta
                          Row(
                            children: [
                              const Icon(Icons.email_outlined,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // İstatistikler
                          Row(
                            children: [
                              _statBox(
                                value: recipeSnapshot.connectionState ==
                                    ConnectionState.waiting
                                    ? '...'
                                    : '$recipeCount',
                                label: s.isEnglish ? 'RECIPE' : 'TARİF',
                              ),
                              const SizedBox(width: 12),
                              _statBox(
                                value: recipeSnapshot.connectionState ==
                                    ConnectionState.waiting
                                    ? '...'
                                    : totalFavorites >= 1000
                                    ? '${(totalFavorites / 1000).toStringAsFixed(1)}K'
                                    : '$totalFavorites',
                                label:
                                s.isEnglish ? 'FAVORITES' : 'FAVORİ',
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Profili Düzenle — sağ üst köşe
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _openEditProfile(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_outlined,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  s.isEnglish ? 'Edit' : 'Düzenle',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Sekmeler ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor:
              isDark ? AppColors.darkTextGrey : AppColors.textGrey,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: s.myRecipes),
                Tab(text: s.favorites),
              ],
            ),
          ),

          const SizedBox(height: 8),

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

  Widget _avatarFallback(User? user) {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          (user?.displayName?.isNotEmpty == true
              ? user!.displayName!
              : 'U')[0]
              .toUpperCase(),
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _statBox({required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRecipesTab(String? userId) {
    if (userId == null) return const Center(child: Text('Giriş yapılmadı'));
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
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 16)),
              ],
            ),
          );
        }
        return _buildRecipeList(recipes);
      },
    );
  }

  Widget _buildFavoritesTab(String? userId) {
    if (userId == null) return const Center(child: Text('Giriş yapılmadı'));
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data =
        userSnapshot.data!.data() as Map<String, dynamic>?;
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
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 16)),
              ],
            ),
          );
        }
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

// ────────────────────────────────────────────────────────────
//  Profili Düzenle — Bottom Sheet
// ────────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final User? user;
  final AppStrings strings;
  final bool isDark;
  final VoidCallback onSaved;

  const _EditProfileSheet({
    required this.user,
    required this.strings,
    required this.isDark,
    required this.onSaved,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  File? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (picked == null) return;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    } else {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // 1. Fotoğraf yükleme (varsa)
      String? photoUrl = user.photoURL;
      if (kIsWeb && _imageBytes != null) {
        photoUrl = await ImgBBService.uploadImageBytes(_imageBytes!);
      } else if (_imageFile != null) {
        photoUrl = await ImgBBService.uploadImage(_imageFile!);
      }

      // 2. Firebase Auth güncelle
      await user.updateDisplayName(name);
      if (photoUrl != null && photoUrl != user.photoURL) {
        await user.updatePhotoURL(photoUrl);
      }
      await user.reload();

      // 3. Firestore güncelle
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'displayName': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });

      widget.onSaved();
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.strings.isEnglish
                ? 'Profile updated! ✅'
                : 'Profil güncellendi! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final currentPhotoUrl = widget.user?.photoURL;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutacak çizgi
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            s.isEnglish ? 'Edit Profile' : 'Profili Düzenle',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Fotoğraf seçici
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.4),
                        width: 2),
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                  child: ClipOval(
                    child: _buildAvatarPreview(currentPhotoUrl),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.isEnglish ? 'Tap to change photo' : 'Fotoğraf değiştirmek için dokun',
            style: const TextStyle(
                color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // İsim alanı
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: s.isEnglish ? 'Full Name' : 'Ad Soyad',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),

          // Kaydet butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : Text(s.save),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview(String? currentPhotoUrl) {
    // Web'de seçilen yeni fotoğraf
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    }
    // Mobilde seçilen yeni fotoğraf
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    }
    // Mevcut fotoğraf
    if (currentPhotoUrl != null) {
      return Image.network(currentPhotoUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          (widget.user?.displayName?.isNotEmpty == true
              ? widget.user!.displayName!
              : 'U')[0]
              .toUpperCase(),
          style: const TextStyle(
              fontSize: 32,
              color: AppColors.primary,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}