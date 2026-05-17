// lib/screens/meal_planner/meal_planner_screen.dart
//
// Düzeltmeler:
//  • _loadPlan() artık yüklemeden önce _plan'ı temizliyor — hafta geçişlerinde
//    eski veriler kalmıyor
//  • Firestore'dan tek seferlik okuma (realtime stream değil) —
//    her açılışta güncel veri yükleniyor
//  • _previousWeek / _nextWeek artık önce state'i günceller sonra yükler

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../recipe/recipe_detail_screen.dart';

class MealPlannerScreen extends StatefulWidget {
  final AppStrings strings;
  const MealPlannerScreen({super.key, required this.strings});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final _recipeService = RecipeService();
  final _db = FirebaseFirestore.instance;
  late final String _uid;
  late final String _langCode;

  Map<String, String> _plan = {};
  Map<String, RecipeModel> _recipeCache = {};
  bool _isLoading = true;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _uid      = FirebaseAuth.instance.currentUser?.uid ?? '';
    _langCode = widget.strings.isEnglish ? 'en' : 'tr';
    _weekStart = _getWeekStart(DateTime.now());
    _loadPlan();
  }

  DateTime _getWeekStart(DateTime date) {
    final diff = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - diff);
  }

  String _dayKey(DateTime date, String meal) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_$meal';

  Future<void> _loadPlan() async {
    if (_uid.isEmpty) return;

    // Yükleme başlamadan önce mevcut planı temizle
    if (mounted) {
      setState(() {
        _isLoading = true;
        _plan = {};         // ← KRİTİK: hafta değişince eski veriyi sil
        _recipeCache = {};  // ← Cache de temizleniyor
      });
    }

    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .collection('mealPlan')
          .doc('plan')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Tüm plan'ı yükle (haftalık filtre UI'da yapılıyor)
        final newPlan = data.map((k, v) => MapEntry(k, v.toString()));

        // Bu haftaya ait tarif ID'lerini bul
        final thisWeekIds = <String>{};
        final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
        for (final day in days) {
          for (final mealKey in ['breakfast', 'lunch', 'dinner']) {
            final key = _dayKey(day, mealKey);
            if (newPlan.containsKey(key)) {
              thisWeekIds.add(newPlan[key]!);
            }
          }
        }

        // Sadece bu hafta gereken tarifleri önbelleğe al
        for (final recipeId in thisWeekIds) {
          if (!_recipeCache.containsKey(recipeId)) {
            final snap = await _db.collection('recipes').doc(recipeId).get();
            if (snap.exists) {
              _recipeCache[recipeId] = RecipeModel.fromMap(snap.data()!, snap.id);
            }
          }
        }

        if (mounted) setState(() => _plan = newPlan);
      }
    } catch (e) {
      debugPrint('MealPlanner _loadPlan error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _savePlan() async {
    if (_uid.isEmpty) return;
    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('mealPlan')
          .doc('plan')
          .set(_plan);
    } catch (e) {
      debugPrint('MealPlanner _savePlan error: $e');
    }
  }

  Future<void> _assignMeal(DateTime date, String mealType) async {
    final s = widget.strings;
    final allRecipes = await _recipeService.getAllRecipes().first;
    if (!mounted) return;

    final selected = await showModalBottomSheet<RecipeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipePickerSheet(recipes: allRecipes, strings: s),
    );

    if (selected != null && mounted) {
      final key = _dayKey(date, mealType);
      setState(() {
        _plan[key] = selected.id;
        _recipeCache[selected.id] = selected;
      });
      await _savePlan();
    }
  }

  Future<void> _removeMeal(String key) async {
    setState(() => _plan.remove(key));
    await _savePlan();
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
    _loadPlan();
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
    _loadPlan();
  }

  String _weekLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    final months = widget.strings.isEnglish
        ? ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
        : ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'];
    return '${_weekStart.day} ${months[_weekStart.month - 1]} — ${end.day} ${months[end.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final dayNames = s.isEnglish
        ? ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
        : ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];
    final mealTypes = s.isEnglish
        ? ['Breakfast','Lunch','Dinner']
        : ['Kahvaltı','Öğle','Akşam'];
    final mealKeys = ['breakfast','lunch','dinner'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        title: Text(
          s.isEnglish ? 'Meal Planner' : 'Haftalık Menü',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextDark : AppColors.textDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
        // ── Hafta navigasyonu ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF3D3530) : AppColors.outline,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousWeek,
                icon: const Icon(Icons.chevron_left_rounded),
                color: isDark ? AppColors.darkTextDark : AppColors.textDark,
              ),
              Text(
                _weekLabel(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextDark : AppColors.textDark,
                ),
              ),
              IconButton(
                onPressed: _nextWeek,
                icon: const Icon(Icons.chevron_right_rounded),
                color: isDark ? AppColors.darkTextDark : AppColors.textDark,
              ),
            ],
          ),
        ),

        // ── Plan listesi ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: days.length,
            itemBuilder: (ctx, di) {
              final day = days[di];
              final isToday = _isSameDay(day, DateTime.now());

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday
                        ? AppColors.primary.withOpacity(0.4)
                        : (isDark ? const Color(0xFF3D3530) : AppColors.outline),
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(children: [
                  // Gün başlığı
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primary
                              : (isDark
                              ? const Color(0xFF3D3530)
                              : AppColors.outline.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? Colors.white
                                  : (isDark
                                  ? AppColors.darkTextDark
                                  : AppColors.textDark),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dayNames[di],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? AppColors.primary
                              : (isDark
                              ? AppColors.darkTextDark
                              : AppColors.textDark),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s.isEnglish ? 'Today' : 'Bugün',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ),

                  // Öğünler
                  ...List.generate(3, (mi) {
                    final key      = _dayKey(day, mealKeys[mi]);
                    final recipeId = _plan[key];
                    final recipe   = recipeId != null
                        ? _recipeCache[recipeId]
                        : null;
                    final recipeTitle = recipe?.localizedTitle(_langCode);

                    return Column(children: [
                      Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0xFF3D3530)
                            : AppColors.outline.withOpacity(0.5),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(children: [
                          SizedBox(
                            width: 62,
                            child: Text(
                              mealTypes[mi],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextGrey
                                    : AppColors.textGrey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: recipe == null
                                ? GestureDetector(
                              onTap: () =>
                                  _assignMeal(day, mealKeys[mi]),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withOpacity(0.06),
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Row(children: [
                                  Icon(Icons.add_rounded,
                                      size: 16,
                                      color: AppColors.primary
                                          .withOpacity(0.7)),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.isEnglish
                                        ? 'Add recipe'
                                        : 'Tarif ekle',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primary
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ]),
                              ),
                            )
                                : GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailScreen(
                                    recipe: recipe,
                                    strings: widget.strings,
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFCB490E),
                                      Color(0xFFE8784A)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                                child: Text(
                                  recipeTitle ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (recipe != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _removeMeal(key),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkTextGrey
                                    : AppColors.textGrey,
                              ),
                            ),
                          ],
                        ]),
                      ),
                    ]);
                  }),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Tarif seçici bottom sheet ────────────────────────────────────────────────

class _RecipePickerSheet extends StatefulWidget {
  final List<RecipeModel> recipes;
  final AppStrings strings;
  const _RecipePickerSheet({required this.recipes, required this.strings});

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final langCode = widget.strings.isEnglish ? 'en' : 'tr';
    final filtered = _query.isEmpty
        ? widget.recipes
        : widget.recipes
        .where((r) => r
        .localizedTitle(langCode)
        .toLowerCase()
        .contains(_query.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: widget.strings.isEnglish
                  ? 'Search recipe...'
                  : 'Tarif ara...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkCard
                  : AppColors.surfaceContainer,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
            child: Text(
              widget.strings.isEnglish
                  ? 'No recipes found'
                  : 'Tarif bulunamadı',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextGrey
                    : AppColors.textGrey,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final recipe = filtered[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: recipe.imageUrl != null
                      ? Image.network(
                    recipe.imageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    width: 52,
                    height: 52,
                    color: isDark
                        ? AppColors.darkCard
                        : AppColors.surfaceContainer,
                    child: const Icon(Icons.restaurant_rounded,
                        color: AppColors.textGrey),
                  ),
                ),
                title: Text(
                  recipe.localizedTitle(langCode),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextDark
                        : AppColors.textDark,
                  ),
                ),
                subtitle: Text(
                  AppCategories.getLabelByKey(
                    recipe.category,
                    isEnglish: widget.strings.isEnglish,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextGrey
                        : AppColors.textGrey,
                  ),
                ),
                onTap: () => Navigator.pop(context, recipe),
              );
            },
          ),
        ),
      ]),
    );
  }
}