// lib/screens/spin/spin_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';
import '../recipe/recipe_detail_screen.dart';

class SpinScreen extends StatefulWidget {
  final AppStrings strings;
  final bool isGuest;

  const SpinScreen({
    super.key,
    required this.strings,
    required this.isGuest,
  });

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen>
    with SingleTickerProviderStateMixin {
  final _recipeService = RecipeService();
  late AnimationController _controller;
  late Animation<double> _animation;

  List<RecipeModel> _allRecipes = [];
  List<RecipeModel> _activeRecipes = [];
  int _optionCount = 6;

  RecipeModel? _selectedRecipe;
  bool _isSpinning = false;
  double _currentAngle = 0;
  int _lastTickSlice = -1;

  final List<Color> _sliceColors = [
    const Color(0xFFA53600),
    const Color(0xFFCB490E),
    const Color(0xFFFF8C69),
    const Color(0xFFFFB59B),
    const Color(0xFF8D7167),
    const Color(0xFF594139),
    const Color(0xFFE1BFB4),
    const Color(0xFFD7CCC8),
    const Color(0xFFBCAAA4),
    const Color(0xFF8D6E63),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _controller.addListener(_onAnimationTick);
    _loadRecipes();
  }

  void _onAnimationTick() {
    if (!_isSpinning || _activeRecipes.isEmpty) return;
    final angle = _animation.value % (2 * pi);
    final sliceAngle = (2 * pi) / _activeRecipes.length;
    final currentSlice = (angle / sliceAngle).floor() % _activeRecipes.length;
    if (currentSlice != _lastTickSlice) {
      _lastTickSlice = currentSlice;
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _loadRecipes() async {
    _recipeService.getAllRecipes().listen((recipes) {
      if (mounted) {
        setState(() {
          _allRecipes = recipes;
          if (_activeRecipes.isEmpty && recipes.isNotEmpty) {
            _randomizeRecipes();
          }
        });
      }
    });
  }

  void _randomizeRecipes() {
    if (_allRecipes.isEmpty) return;
    final random = Random();
    final List<RecipeModel> shuffled = List.from(_allRecipes)..shuffle(random);
    setState(() {
      _activeRecipes = shuffled.take(min(_optionCount, shuffled.length)).toList();
    });
  }

  void _spin() {
    if (_isSpinning || _activeRecipes.isEmpty) return;
    setState(() {
      _isSpinning = true;
      _selectedRecipe = null;
      _lastTickSlice = -1;
    });

    final random = Random();
    final extraSpins = 5 + random.nextInt(5);
    final selectedIndex = random.nextInt(_activeRecipes.length);
    final sliceAngle = (2 * pi) / _activeRecipes.length;

    final targetAngle = _currentAngle +
        (extraSpins * 2 * pi) +
        (2 * pi -
            ((selectedIndex * sliceAngle + sliceAngle / 2) +
                _currentAngle % (2 * pi)) %
                (2 * pi));

    _animation = Tween<double>(
      begin: _currentAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.reset();
    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _currentAngle = targetAngle;
          _selectedRecipe = _activeRecipes[selectedIndex];
          _isSpinning = false;
        });
        HapticFeedback.mediumImpact();
        _showResult(_activeRecipes[selectedIndex]);
      }
    });
  }

  void _showResult(RecipeModel recipe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SpinResultSheet(
        recipe: recipe,
        strings: widget.strings,
        isGuest: widget.isGuest,
        onRespin: () {
          Navigator.pop(context);
          _spin();
        },
      ),
    );
  }

  void _showRecipeSelection() async {
    final langCode = widget.strings.isEnglish ? 'en' : 'tr';
    final List<RecipeModel> tempSelected = List.from(_activeRecipes);
    String searchQuery = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          final filteredRecipes = searchQuery.isEmpty
              ? _allRecipes
              : _allRecipes
              .where((r) => r
              .localizedTitle(langCode)
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: AppColors.outline,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.strings.selectRecipes,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(
                            widget.strings
                                .selectedRecipesCountLabel(tempSelected.length),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: widget.strings.isEnglish
                              ? 'Search...'
                              : 'Ara...',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (v) =>
                            setDialogState(() => searchQuery = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredRecipes.length,
                    itemBuilder: (_, i) {
                      final recipe = filteredRecipes[i];
                      final isSelected =
                      tempSelected.any((r) => r.id == recipe.id);
                      final displayTitle = recipe.localizedTitle(langCode);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.outline.withOpacity(0.5))),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: recipe.imageUrl != null
                                ? Image.network(
                              recipe.imageUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _thumbPlaceholder(),
                            )
                                : _thumbPlaceholder(),
                          ),
                          title: Text(displayTitle,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                              color: AppColors.primary)
                              : const Icon(Icons.circle_outlined,
                              color: AppColors.outline),
                          onTap: () {
                            setDialogState(() {
                              if (isSelected) {
                                tempSelected
                                    .removeWhere((r) => r.id == recipe.id);
                              } else if (tempSelected.length < 10) {
                                tempSelected.add(recipe);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: tempSelected.length >= 2
                          ? () {
                        setState(() {
                          _activeRecipes = tempSelected;
                          _optionCount = _activeRecipes.length;
                        });
                        Navigator.pop(context);
                      }
                          : null,
                      child: Text(widget.strings.save),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    width: 48,
    height: 48,
    color: AppColors.surfaceContainer,
    child: const Icon(Icons.restaurant_outlined,
        size: 24, color: AppColors.textGrey),
  );

  @override
  void dispose() {
    _controller.removeListener(_onAnimationTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;
    final langCode = s.isEnglish ? 'en' : 'tr';

    final cardBg = isDark ? AppColors.darkCard : AppColors.surfaceContainer;
    final borderColor =
    isDark ? const Color(0xFF3D3530) : AppColors.outline.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.isEnglish ? '🎡 What to Cook?' : '🎡 Ne Pişirsem?'),
      ),
      body: _allRecipes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Başlık
            Text(
              s.isEnglish ? 'Spin the wheel!' : 'Çarkı çevir!',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 32),

            // ── Çark ────────────────────────────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                // Dış halka / glow
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCard : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(isDark ? 0.15 : 0.08),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
                GestureDetector(
                  onVerticalDragUpdate: (d) => setState(() {
                    if (!_isSpinning)
                      _currentAngle += d.delta.dy * 0.015;
                  }),
                  onVerticalDragEnd: (d) {
                    if (!_isSpinning &&
                        d.primaryVelocity != null &&
                        d.primaryVelocity! > 300) _spin();
                  },
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => Transform.rotate(
                      angle:
                      _isSpinning ? _animation.value : _currentAngle,
                      child: CustomPaint(
                        size: const Size(280, 280),
                        painter: _WheelPainter(
                          recipes: _activeRecipes,
                          colors: _sliceColors,
                          langCode: langCode,
                        ),
                      ),
                    ),
                  ),
                ),
                // Ok
                Positioned(
                  top: -5,
                  child: Container(
                    width: 30,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(15)),
                    ),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white),
                  ),
                ),
                // Merkez
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: AppColors.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.restaurant,
                      color: AppColors.primary),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ── Kontrol Paneli — Drawer stili kart ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slider başlık
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.chooseOptionCount,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextDark
                                : AppColors.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_optionCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Slider
                    Row(
                      children: [
                        Text('2',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextGrey
                                    : AppColors.textGrey)),
                        Expanded(
                          child: Slider(
                            value: _optionCount.toDouble(),
                            min: 2,
                            max: min(10, _allRecipes.length.toDouble()),
                            divisions:
                            max(1, min(10, _allRecipes.length) - 2),
                            activeColor: AppColors.primary,
                            inactiveColor:
                            AppColors.primary.withOpacity(0.2),
                            onChanged: _isSpinning
                                ? null
                                : (v) => setState(() {
                              _optionCount = v.toInt();
                              _randomizeRecipes();
                            }),
                          ),
                        ),
                        Text('${min(10, _allRecipes.length)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextGrey
                                    : AppColors.textGrey)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // İki buton — Drawer stili
                    Row(
                      children: [
                        Expanded(
                          child: _DrawerStyleButton(
                            icon: Icons.list_alt_rounded,
                            label: s.selectRecipes,
                            isDark: isDark,
                            onTap: _isSpinning
                                ? null
                                : _showRecipeSelection,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DrawerStyleButton(
                            icon: Icons.auto_awesome_rounded,
                            label: s.imFeelingLucky,
                            isDark: isDark,
                            onTap:
                            _isSpinning ? null : _randomizeRecipes,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── ÇEVİR Butonu — gradient ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _isSpinning
                      ? null
                      : const LinearGradient(
                    colors: [
                      Color(0xFFA53600),
                      Color(0xFFCB490E),
                      Color(0xFFE8784A),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  color: _isSpinning
                      ? (isDark ? AppColors.darkCard : AppColors.outline)
                      : null,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isSpinning
                      ? []
                      : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSpinning ? null : _spin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white54,
                    disabledBackgroundColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _isSpinning
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                      : Text(
                    s.isEnglish ? '🎡  SPIN!' : '🎡  ÇEVİR!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              s.selectedRecipesCountLabel(_activeRecipes.length),
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextGrey
                      : AppColors.textGrey),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── Drawer stili küçük buton ──────────────────────────────────────────────────
class _DrawerStyleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _DrawerStyleButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.transparent
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? AppColors.outline.withOpacity(0.4)
                : AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDisabled
                  ? (isDark ? AppColors.darkTextGrey : AppColors.textGrey)
                  : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? (isDark ? AppColors.darkTextGrey : AppColors.textGrey)
                      : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Çark Painter — lokalize başlıklar ────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final List<RecipeModel> recipes;
  final List<Color> colors;
  final String langCode;

  _WheelPainter({
    required this.recipes,
    required this.colors,
    required this.langCode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (recipes.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = (2 * pi) / recipes.length;

    for (int i = 0; i < recipes.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sliceAngle - pi / 2,
        sliceAngle,
        true,
        paint,
      );

      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sliceAngle - pi / 2,
        sliceAngle,
        true,
        linePaint,
      );

      // Lokalize tarif adı
      final title = recipes[i].localizedTitle(langCode);
      final textAngle = i * sliceAngle - pi / 2 + sliceAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: title.length > 12 ? '${title.substring(0, 12)}…' : title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: radius * 0.6);
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.recipes != recipes ||
          old.colors != colors ||
          old.langCode != langCode;
}

// ── Sonuç Bottom Sheet ────────────────────────────────────────────────────────
class _SpinResultSheet extends StatelessWidget {
  final RecipeModel recipe;
  final AppStrings strings;
  final bool isGuest;
  final VoidCallback onRespin;

  const _SpinResultSheet({
    required this.recipe,
    required this.strings,
    required this.isGuest,
    required this.onRespin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = strings;
    final langCode = s.isEnglish ? 'en' : 'tr';

    final categoryLabel = AppCategories.getLabelByKey(
      recipe.category,
      isEnglish: s.isEnglish,
    ).toUpperCase();

    final displayTitle = recipe.localizedTitle(langCode);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkTextGrey.withOpacity(0.4)
                  : AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Kart
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Görsel
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: recipe.imageUrl != null
                      ? Image.network(
                    recipe.imageUrl!,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _imagePlaceholder(isDark),
                  )
                      : _imagePlaceholder(isDark),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori
                      Text(
                        categoryLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryContainer,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Lokalize tarif adı
                      Text(
                        displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextDark
                              : AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Süre + Kalori
                      Row(
                        children: [
                          Icon(Icons.access_time_outlined,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextGrey
                                  : AppColors.textGrey),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.cookingTimeMinutes} ${s.isEnglish ? 'min' : 'dk'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextGrey
                                  : AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (recipe.calories != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.local_fire_department_outlined,
                                size: 14,
                                color: isDark
                                    ? AppColors.darkTextGrey
                                    : AppColors.textGrey),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.calories} kcal',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextGrey
                                    : AppColors.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Butonlar
          Row(
            children: [
              // Tekrar — drawer stili
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: onRespin,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.autorenew_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          s.isEnglish ? 'Re-spin' : 'Tekrar',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Tarifi Gör — gradient
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(
                          recipe: recipe,
                          isGuest: isGuest,
                          strings: strings,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFCB490E).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.viewRecipe,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color:
        isDark ? AppColors.darkCard : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.restaurant_outlined,
          size: 32,
          color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
    );
  }
}