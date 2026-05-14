// lib/screens/admin/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../recipe/recipe_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  final AppStrings strings;

  const AdminScreen({super.key, required this.strings});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _recipeService = RecipeService();
  final _firestore = FirebaseFirestore.instance;
  final _userSearchController = TextEditingController();
  String _userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text(s.adminPanel,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              icon: const Icon(Icons.restaurant_menu, size: 18),
              text: s.isEnglish ? 'Recipes' : 'Tarifler',
            ),
            Tab(
              icon: const Icon(Icons.comment_outlined, size: 18),
              text: s.isEnglish ? 'Comments' : 'Yorumlar',
            ),
            Tab(
              icon: const Icon(Icons.people_outline, size: 18),
              text: s.isEnglish ? 'Users' : 'Kullanıcılar',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecipesTab(isDark),
          _buildCommentsTab(isDark),
          _buildUsersTab(isDark),
        ],
      ),
    );
  }

  // ---- TARİFLER ----
  Widget _buildRecipesTab(bool isDark) {
    return StreamBuilder<List<RecipeModel>>(
      stream: _recipeService.getAllRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(widget.strings.noRecipes,
                style: const TextStyle(color: AppColors.textGrey)),
          );
        }

        final recipes = snapshot.data!;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox(
                    icon: Icons.restaurant_menu,
                    value: '${recipes.length}',
                    label: widget.strings.isEnglish ? 'Total' : 'Toplam',
                  ),
                  _statBox(
                    icon: Icons.star_rounded,
                    value: recipes.isNotEmpty
                        ? (recipes
                        .map((r) => r.averageRating)
                        .reduce((a, b) => a + b) /
                        recipes.length)
                        .toStringAsFixed(1)
                        : '0',
                    label: widget.strings.isEnglish ? 'Avg Rating' : 'Ort. Puan',
                  ),
                  _statBox(
                    icon: Icons.favorite,
                    value:
                    '${recipes.map((r) => r.favoriteCount).fold(0, (a, b) => a + b)}',
                    label: widget.strings.isEnglish ? 'Favorites' : 'Favori',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recipes.length,
                itemBuilder: (context, index) =>
                    _recipeAdminCard(recipes[index], isDark),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _recipeAdminCard(RecipeModel recipe, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF3D3530) : AppColors.outline),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: recipe.imageUrl != null
              ? Image.network(recipe.imageUrl!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _miniPlaceholder(isDark))
              : _miniPlaceholder(isDark),
        ),
        title: Text(recipe.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.person_outline,
                  size: 12, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(recipe.userEmail,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.star_rounded,
                  size: 12, color: Color(0xFFFFB347)),
              const SizedBox(width: 4),
              Text(recipe.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textGrey)),
              const SizedBox(width: 12),
              const Icon(Icons.favorite, size: 12, color: Colors.red),
              const SizedBox(width: 4),
              Text('${recipe.favoriteCount}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textGrey)),
            ]),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined,
                  color: AppColors.primary, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(
                    recipe: recipe,
                    isAdmin: true,
                    strings: widget.strings,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 20),
              onPressed: () => _confirmDeleteRecipe(recipe),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRecipe(RecipeModel recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.strings.deleteRecipeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.strings.deleteRecipeConfirm),
            const SizedBox(height: 8),
            Text('"${recipe.title}"',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(widget.strings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _recipeService.deleteRecipe(recipe.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.strings.isEnglish
              ? 'Recipe deleted!'
              : 'Tarif silindi!'),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  // ---- YORUMLAR ----
  Widget _buildCommentsTab(bool isDark) {
    return StreamBuilder<List<RecipeModel>>(
      stream: _recipeService.getAllRecipes(),
      builder: (context, recipesSnapshot) {
        if (!recipesSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final recipes = recipesSnapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return StreamBuilder<QuerySnapshot>(
              stream: _recipeService.getComments(recipe.id),
              builder: (context, commentSnapshot) {
                if (!commentSnapshot.hasData ||
                    commentSnapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final comments = commentSnapshot.data!.docs;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        const Icon(Icons.restaurant_menu,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(recipe.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('${comments.length}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined,
                              color: AppColors.primary, size: 20),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                recipe: recipe,
                                isAdmin: true,
                                strings: widget.strings,
                              ),
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ]),
                    ),
                    ...comments.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _commentAdminCard(
                          recipe.id, doc.id, data, isDark);
                    }),
                    const Divider(),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _commentAdminCard(String recipeId, String commentId,
      Map<String, dynamic> data, bool isDark) {
    final userName = data['userName'] ?? 'U';
    final initial =
    userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDark ? const Color(0xFF3D3530) : AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(initial,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(
                      5,
                          (i) => Icon(
                        i < (data['rating'] ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFFFB347),
                        size: 12,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(data['text'] ?? '',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextGrey
                            : AppColors.textGrey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 18),
            onPressed: () =>
                _confirmDeleteComment(recipeId, commentId, data),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteComment(String recipeId, String commentId,
      Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            widget.strings.isEnglish ? 'Delete Comment' : 'Yorumu Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.strings.isEnglish
                ? 'Are you sure you want to delete this comment?'
                : 'Bu yorumu silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('"${data['text'] ?? ''}"',
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, fontSize: 13)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(widget.strings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _recipeService.deleteComment(recipeId, commentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.strings.isEnglish
              ? 'Comment deleted!'
              : 'Yorum silindi!'),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  // ---- KULLANICILAR ----
  Widget _buildUsersTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              widget.strings.isEnglish
                  ? 'No users yet'
                  : 'Henüz kullanıcı yok',
              style: const TextStyle(color: AppColors.textGrey),
            ),
          );
        }

        final allUsers = snapshot.data!.docs;

        // Filtreleme — stream dışında yapılıyor, setState tetiklemez
        final admins = allUsers
            .where((doc) =>
        (doc.data() as Map<String, dynamic>)['role'] == 'admin')
            .toList();
        final regularUsers = allUsers
            .where((doc) =>
        (doc.data() as Map<String, dynamic>)['role'] != 'admin')
            .toList();

        final filteredRegular = _userSearchQuery.isEmpty
            ? regularUsers
            : regularUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name =
          (data['displayName'] ?? '').toLowerCase();
          final email = (data['email'] ?? '').toLowerCase();
          return name.contains(_userSearchQuery) ||
              email.contains(_userSearchQuery);
        }).toList();

        final filteredAdmins = _userSearchQuery.isEmpty
            ? admins
            : admins.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name =
          (data['displayName'] ?? '').toLowerCase();
          final email = (data['email'] ?? '').toLowerCase();
          return name.contains(_userSearchQuery) ||
              email.contains(_userSearchQuery);
        }).toList();

        return Column(
          children: [
            // Özet
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox(
                    icon: Icons.people,
                    value: '${allUsers.length}',
                    label: widget.strings.isEnglish
                        ? 'Total'
                        : 'Toplam',
                  ),
                  _statBox(
                    icon: Icons.admin_panel_settings,
                    value: '${admins.length}',
                    label: 'Admin',
                  ),
                  _statBox(
                    icon: Icons.person,
                    value: '${regularUsers.length}',
                    label: widget.strings.isEnglish ? 'Users' : 'Üye',
                  ),
                ],
              ),
            ),

            // Arama
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _userSearchController,
                onChanged: (v) {
                  _userSearchQuery = v.toLowerCase();
                  // StreamBuilder'ı yeniden çalıştırmak için setState
                  // ama stream'i yeniden başlatmamak için sadece
                  // local değişkeni güncelliyoruz
                  (context as Element).markNeedsBuild();
                },
                decoration: InputDecoration(
                  hintText: widget.strings.isEnglish
                      ? 'Search by name or email...'
                      : 'İsim veya e-posta ile ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _userSearchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _userSearchController.clear();
                      _userSearchQuery = '';
                      (context as Element).markNeedsBuild();
                    },
                  )
                      : null,
                ),
              ),
            ),

            // Liste
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Adminler
                  if (filteredAdmins.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Admin (${filteredAdmins.length})',
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    ...filteredAdmins.map((doc) => _userCard(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                        true,
                        isDark)),
                    const SizedBox(height: 16),
                  ],

                  // Normal kullanıcılar
                  if (filteredRegular.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${widget.strings.isEnglish ? 'Users' : 'Kullanıcılar'} (${filteredRegular.length})',
                        style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextGrey
                                : AppColors.textGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    ...filteredRegular.map((doc) => _userCard(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                        false,
                        isDark)),
                  ],

                  if (filteredAdmins.isEmpty && filteredRegular.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          widget.strings.isEnglish
                              ? 'No users found'
                              : 'Kullanıcı bulunamadı',
                          style: const TextStyle(
                              color: AppColors.textGrey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _userCard(String userId, Map<String, dynamic> data,
      bool isAdmin, bool isDark) {
    final displayName = data['displayName'] ?? '';
    final email = data['email'] ?? '';
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : email.isNotEmpty
        ? email[0].toUpperCase()
        : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin
              ? Colors.red.withOpacity(0.3)
              : (isDark ? const Color(0xFF3D3530) : AppColors.outline),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isAdmin
                ? Colors.red.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.1),
            child: Text(initial,
                style: TextStyle(
                    color: isAdmin ? Colors.red : AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      displayName.isNotEmpty ? displayName : 'Kullanıcı',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('ADMIN',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                Text(email,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (!isAdmin)
            TextButton(
              onPressed: () => _makeAdmin(userId, displayName),
              child: Text(
                widget.strings.isEnglish ? 'Make Admin' : 'Admin Yap',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _makeAdmin(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            widget.strings.isEnglish ? 'Make Admin' : 'Admin Yap'),
        content: Text(
          widget.strings.isEnglish
              ? 'Give admin rights to "$userName"?'
              : '"$userName" kullanıcısına admin yetkisi verilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
                widget.strings.isEnglish ? 'Confirm' : 'Onayla'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'role': 'admin'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.strings.isEnglish
              ? 'Admin rights granted!'
              : 'Admin yetkisi verildi!'),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  Widget _statBox(
      {required IconData icon,
        required String value,
        required String label}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _miniPlaceholder(bool isDark) {
    return Container(
      width: 56,
      height: 56,
      color: isDark ? AppColors.darkCard : AppColors.surfaceContainerHigh,
      child: const Icon(Icons.restaurant_menu,
          size: 24, color: AppColors.textGrey),
    );
  }
}