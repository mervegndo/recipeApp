// lib/screens/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final AppStrings strings;
  final bool isGuest;

  const SearchScreen({
    super.key,
    required this.strings,
    required this.isGuest,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _recipeService = RecipeService();

  // ─── Mod ─────────────────────────────────────────────────────────────────
  String _mode = 'name'; // 'name' | 'ingredient'

  // ─── İSME GÖRE ───────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  String _nameQuery = '';
  String _selectedCategory = 'all';
  List<RecipeModel> _nameResults = [];
  bool _isNameSearching = false;

  // ─── MALZEMEYE GÖRE ───────────────────────────────────────────────────────
  final _ingCtrl = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isFetchingSuggestions = false;
  final List<Map<String, dynamic>> _selectedIngredients = [];
  List<RecipeModel> _ingResults = [];
  bool _isIngSearching = false;
  bool _ingHasSearched = false;

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ingCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // İSME GÖRE ARAMA
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _performNameSearch(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) {
      setState(() { _nameResults = []; _isNameSearching = false; });
      return;
    }
    setState(() => _isNameSearching = true);
    try {
      final res = await _recipeService.searchRecipes(
        q,
        langCode: widget.strings.isEnglish ? 'en' : 'tr',
        // FIX: 'all' iken null gönder, Firestore filtre hatası olmasın
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      if (mounted) setState(() { _nameResults = res; _isNameSearching = false; });
    } catch (_) {
      if (mounted) setState(() => _isNameSearching = false);
    }
  }

  void _onCategoryChanged(String key) {
    setState(() => _selectedCategory = key);
    if (_nameQuery.isNotEmpty) _performNameSearch(_nameQuery);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MALZEMEYE GÖRE ARAMA
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _fetchSuggestions(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) { setState(() => _suggestions = []); return; }
    setState(() => _isFetchingSuggestions = true);
    try {
      final field = widget.strings.isEnglish ? 'searchEn' : 'searchTr';
      final snap = await FirebaseFirestore.instance
          .collection('ingredients')
          .where(field, isGreaterThanOrEqualTo: q)
          .where(field, isLessThanOrEqualTo: '$q\uf8ff')
          .limit(12)
          .get();
      final sel = _selectedIngredients.map((e) => e['searchEn'] as String).toSet();
      final list = snap.docs.map((d) => d.data()).where((d) => !sel.contains(d['searchEn'])).toList();
      if (mounted) setState(() => _suggestions = list);
    } catch (_) {} finally {
      if (mounted) setState(() => _isFetchingSuggestions = false);
    }
  }

  void _selectIngredient(Map<String, dynamic> ing) {
    setState(() {
      _selectedIngredients.add(ing);
      _suggestions = [];
      _ingCtrl.clear();
    });
    if (_ingHasSearched) _searchByIngredients();
  }

  void _removeIngredient(int i) {
    setState(() => _selectedIngredients.removeAt(i));
    if (_ingHasSearched) _searchByIngredients();
  }

  Future<void> _searchByIngredients() async {
    if (_selectedIngredients.isEmpty) {
      setState(() { _ingResults = []; _ingHasSearched = false; });
      return;
    }
    setState(() { _isIngSearching = true; _ingHasSearched = true; });
    try {
      final snap = await FirebaseFirestore.instance.collection('recipes').limit(300).get();
      final all = snap.docs.map((d) => RecipeModel.fromMap(d.data(), d.id)).toList();
      final filtered = all.where((r) {
        final hay = r.ingredients.join(' ').toLowerCase();
        return _selectedIngredients.every((ing) {
          final en   = (ing['searchEn']    as String? ?? '').toLowerCase();
          final tr   = (ing['searchTr']    as String? ?? '').toLowerCase();
          final orig = (ing['nameOriginal'] as String? ?? '').toLowerCase();
          return hay.contains(en) || hay.contains(tr) || hay.contains(orig);
        });
      }).toList();
      if (mounted) setState(() { _ingResults = filtered; _isIngSearching = false; });
    } catch (_) {
      if (mounted) setState(() => _isIngSearching = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Başlık ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
            child: Text(
              s.isEnglish ? 'Discover Recipes' : 'Tarif Keşfet',
              style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5,
                color: isDark ? AppColors.darkTextDark : AppColors.textDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text(
              s.isEnglish ? 'Search by name or ingredient' : 'İsim veya malzemeye göre ara',
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
            ),
          ),

          // ── Mod tab butonları ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                _ModeTab(
                  label: s.isEnglish ? 'By Name' : 'İsme göre ara',
                  icon: Icons.search_rounded,
                  isSelected: _mode == 'name',
                  isDark: isDark,
                  onTap: () => setState(() { _mode = 'name'; _suggestions = []; }),
                ),
                const SizedBox(width: 10),
                _ModeTab(
                  label: s.isEnglish ? 'By Ingredient' : 'Malzemelere göre',
                  icon: Icons.kitchen_outlined,
                  isSelected: _mode == 'ingredient',
                  isDark: isDark,
                  onTap: () => setState(() => _mode = 'ingredient'),
                ),
              ],
            ),
          ),

          // ── Arama kutusu ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _buildSearchBox(isDark, s),
          ),

          // ── Kategoriler (sadece 'name' modunda) ──────────────────────────
          if (_mode == 'name')
            _buildCategoryRow(isDark, s),

          // ── Kaydırılabilir içerik ─────────────────────────────────────────
          Expanded(
            child: _mode == 'name'
                ? _buildNameContent(isDark, s)
                : _buildIngredientContent(isDark, s),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Arama kutusu
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchBox(bool isDark, AppStrings s) {
    final ctrl = _mode == 'name' ? _nameCtrl : _ingCtrl;
    final hasText = _mode == 'name' ? _nameQuery.isNotEmpty : _ingCtrl.text.isNotEmpty;
    final hint = _mode == 'name'
        ? (s.isEnglish ? 'Search by name...'      : 'İsme göre ara...')
        : (s.isEnglish ? 'Type an ingredient...'  : 'Malzeme ara...');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF3D3530) : AppColors.outline),
        boxShadow: isDark ? [] : [BoxShadow(color: AppColors.textDark.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: ctrl,
        autofocus: false,
        onChanged: (v) {
          if (_mode == 'name') {
            setState(() => _nameQuery = v);
            _performNameSearch(v);
          } else {
            setState(() {});
            _fetchSuggestions(v);
          }
        },
        style: TextStyle(color: isDark ? AppColors.darkTextDark : AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
          prefixIcon: (_mode == 'ingredient' && _isFetchingSuggestions)
              ? Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
              : Icon(Icons.search_rounded, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
          suffixIcon: hasText
              ? IconButton(
            icon: Icon(Icons.close_rounded, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
            onPressed: () {
              ctrl.clear();
              if (_mode == 'name') setState(() { _nameQuery = ''; _nameResults = []; });
              else setState(() => _suggestions = []);
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Kategori satırı
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCategoryRow(bool isDark, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 86,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categoryIcons.length,
          itemBuilder: (ctx, idx) {
            final cat = _categoryIcons[idx];
            final isSel = _selectedCategory == cat['key'];
            return GestureDetector(
              onTap: () => _onCategoryChanged(cat['key']),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: isSel
                            ? const LinearGradient(colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight)
                            : null,
                        color: isSel ? null : (isDark ? AppColors.darkCard : AppColors.surface),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSel ? Colors.transparent : (isDark ? const Color(0xFF3D3530) : AppColors.outline),
                        ),
                        boxShadow: isSel
                            ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]
                            : [],
                      ),
                      child: Icon(cat['icon'] as IconData,
                          color: isSel ? Colors.white : (isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                          size: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.isEnglish ? cat['labelEn'] : cat['label'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? AppColors.primary : (isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // İSME GÖRE İÇERİK
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildNameContent(bool isDark, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text(
            _nameQuery.isNotEmpty
                ? (s.isEnglish ? 'Results' : 'Sonuçlar')
                : (s.isEnglish ? 'All Recipes' : 'Tüm Tarifler'),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextDark : AppColors.textDark),
          ),
        ),
        Expanded(child: _nameQuery.isNotEmpty ? _buildNameResults(isDark, s) : _buildAllRecipes(isDark, s)),
      ],
    );
  }

  Widget _buildNameResults(bool isDark, AppStrings s) {
    if (_isNameSearching) return const Center(child: CircularProgressIndicator());
    if (_nameResults.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off_rounded, size: 64, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
        const SizedBox(height: 16),
        Text(
          s.isEnglish ? 'No results for "$_nameQuery"' : '"$_nameQuery" için sonuç bulunamadı',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
        ),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _nameResults.length,
      itemBuilder: (ctx, i) => RecipeCard(
        recipe: _nameResults[i], isEnglish: s.isEnglish,
        onTap: () => Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: _nameResults[i], isGuest: widget.isGuest, strings: widget.strings),
        )),
      ),
    );
  }

  Widget _buildAllRecipes(bool isDark, AppStrings s) {
    return StreamBuilder<List<RecipeModel>>(
      stream: _selectedCategory == 'all'
          ? _recipeService.getAllRecipes()
          : _recipeService.getRecipesByCategory(_selectedCategory),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snap.hasData || snap.data!.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.search_off_rounded, size: 64, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
            const SizedBox(height: 16),
            Text(s.noRecipes, style: TextStyle(color: isDark ? AppColors.darkTextGrey : AppColors.textGrey, fontSize: 16)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: snap.data!.length,
          itemBuilder: (ctx2, i) => RecipeCard(
            recipe: snap.data![i], isEnglish: s.isEnglish,
            onTap: () => Navigator.push(ctx2, MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipe: snap.data![i], isGuest: widget.isGuest, strings: widget.strings),
            )),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // MALZEMEYE GÖRE İÇERİK
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildIngredientContent(bool isDark, AppStrings s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
      children: [
        // Öneri listesi
        if (_suggestions.isNotEmpty)
          _buildSuggestionsBox(isDark, s),

        // Seçili malzemeler + Ara butonu
        if (_selectedIngredients.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(children: [
              Text(
                s.isEnglish ? 'Selected' : 'Seçili Malzemeler',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextDark : AppColors.textDark),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                child: Text('${_selectedIngredients.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() { _selectedIngredients.clear(); _ingResults = []; _ingHasSearched = false; }),
                child: Text(s.isEnglish ? 'Clear all' : 'Temizle',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: _selectedIngredients.asMap().entries.map((e) {
                final name = widget.strings.isEnglish
                    ? (e.value['nameEn'] as String? ?? e.value['nameOriginal'])
                    : (e.value['nameTr'] as String? ?? e.value['nameOriginal']);
                return _IngChip(label: name ?? '', onRemove: () => _removeIngredient(e.key));
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isIngSearching ? null : _searchByIngredients,
                icon: _isIngSearching
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.restaurant_menu_rounded, size: 18),
                label: Text(s.isEnglish ? 'Find Recipes' : 'Tarifleri Bul',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],

        // Sonuç sayısı
        if (_ingHasSearched)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              s.isEnglish
                  ? '${_ingResults.length} recipe${_ingResults.length == 1 ? '' : 's'} found'
                  : '${_ingResults.length} tarif bulundu',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextDark : AppColors.textDark),
            ),
          ),

        // Sonuçlar
        if (_isIngSearching)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else if (!_ingHasSearched)
          _buildIngEmpty(isDark, s)
        else if (_ingResults.isEmpty)
            _buildIngNoResults(isDark, s)
          else
            ..._ingResults.map((r) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RecipeCard(
                recipe: r, isEnglish: s.isEnglish,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(recipe: r, isGuest: widget.isGuest, strings: widget.strings),
                )),
              ),
            )),
      ],
    );
  }

  Widget _buildSuggestionsBox(bool isDark, AppStrings s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF3D3530) : AppColors.outline),
        boxShadow: isDark ? [] : [BoxShadow(color: AppColors.textDark.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _suggestions.asMap().entries.map((e) {
          final i = e.key;
          final ing = e.value;
          final name = widget.strings.isEnglish
              ? (ing['nameEn'] as String? ?? ing['nameOriginal'])
              : (ing['nameTr'] as String? ?? ing['nameOriginal']);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0) Divider(height: 1, color: isDark ? const Color(0xFF3D3530) : AppColors.outline.withOpacity(0.5)),
              InkWell(
                onTap: () => _selectIngredient(ing),
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(14))
                    : i == _suggestions.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(14))
                    : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.eco_outlined, color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name ?? '',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextDark : AppColors.textDark))),
                    const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                  ]),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIngEmpty(bool isDark, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.kitchen_outlined, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          widget.strings.isEnglish ? 'Add ingredients above' : 'Yukarıdan malzeme ekle',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextDark : AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Text(
          widget.strings.isEnglish
              ? 'Find recipes that use all your selected ingredients'
              : 'Seçtiğin malzemeleri içeren tarifleri buluyoruz',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
        ),
      ]),
    );
  }

  Widget _buildIngNoResults(bool isDark, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded, size: 64, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
        const SizedBox(height: 16),
        Text(
          s.isEnglish ? 'No recipes found with these ingredients' : 'Bu malzemelerle tarif bulunamadı',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextDark : AppColors.textDark),
        ),
        const SizedBox(height: 6),
        Text(s.isEnglish ? 'Try removing some ingredients' : 'Bazı malzemeleri kaldırmayı dene',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
      ]),
    );
  }
}

// ─── Mod tab butonu ──────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label, required this.icon,
    required this.isSelected, required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: isSelected ? null : (isDark ? AppColors.darkCard : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF3D3530) : AppColors.outline),
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextGrey : AppColors.textGrey)),
            const SizedBox(width: 6),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : (isDark ? AppColors.darkTextGrey : AppColors.textGrey)))),
          ]),
        ),
      ),
    );
  }
}

// ─── Malzeme chip ────────────────────────────────────────────────────────────

class _IngChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _IngChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}