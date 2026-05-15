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

  // Ses için: bir önceki dilim indeksini takip et
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

    // Her animasyon tick'te ses çal
    _controller.addListener(_onAnimationTick);

    _loadRecipes();
  }

  /// Çark dönünce her dilim geçişinde tık sesi çıkar
  void _onAnimationTick() {
    if (!_isSpinning || _activeRecipes.isEmpty) return;

    final angle = _animation.value % (2 * pi);
    final sliceAngle = (2 * pi) / _activeRecipes.length;
    final currentSlice = (angle / sliceAngle).floor() % _activeRecipes.length;

    if (currentSlice != _lastTickSlice) {
      _lastTickSlice = currentSlice;
      // Flutter'ın built-in haptic feedback (ses + titreşim)
      HapticFeedback.selectionClick();
      // Ayrıca system click sesi
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
        (2 * pi - ((selectedIndex * sliceAngle + sliceAngle / 2) + _currentAngle % (2 * pi))) % (2 * pi);

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
        // Bitiş sesi
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
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(widget.strings.luckyRecipeTitle,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            const SizedBox(height: 16),
            if (recipe.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(recipe.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text(recipe.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                              recipe: recipe,
                              isGuest: widget.isGuest,
                              strings: widget.strings)));
                },
                child: Text(widget.strings.viewRecipe,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRecipeSelection() async {
    final List<RecipeModel> tempSelected = List.from(_activeRecipes);
    String searchQuery = "";

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredRecipes = _allRecipes
              .where((r) =>
              r.title.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.strings.selectRecipes,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(
                          '${tempSelected.length}/${_optionCount} ${widget.strings.isEnglish ? 'selected' : 'seçildi'}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (v) => setDialogState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: widget.strings.isEnglish
                          ? 'Search...'
                          : 'Ara...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                    ),
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
                                ? Image.network(recipe.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover)
                                : Container(
                                width: 50,
                                height: 50,
                                color: AppColors.outline,
                                child:
                                const Icon(Icons.restaurant)),
                          ),
                          title: Text(recipe.title,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          trailing: Checkbox(
                            value: isSelected,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true &&
                                    tempSelected.length < _optionCount)
                                  tempSelected.add(recipe);
                                else if (val == false)
                                  tempSelected
                                      .removeWhere((r) => r.id == recipe.id);
                              });
                            },
                          ),
                          onTap: () {
                            setDialogState(() {
                              if (!isSelected &&
                                  tempSelected.length < _optionCount)
                                tempSelected.add(recipe);
                              else if (isSelected)
                                tempSelected
                                    .removeWhere((r) => r.id == recipe.id);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
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
              ],
            ),
          );
        },
      ),
    );
  }

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

    return Scaffold(
      appBar: AppBar(
          title: Text(s.isEnglish ? '🎡 What to Cook?' : '🎡 Ne Pişirsem?')),
      body: _allRecipes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
                s.isEnglish ? 'Spin the wheel!' : 'Çarkı çevir!',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            const SizedBox(height: 32),

            // Çark Alanı
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.darkCard
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20)
                        ])),
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
                        angle: _isSpinning
                            ? _animation.value
                            : _currentAngle,
                        child: CustomPaint(
                            size: const Size(280, 280),
                            painter: _WheelPainter(
                                recipes: _activeRecipes,
                                colors: _sliceColors))),
                  ),
                ),
                Positioned(
                    top: -5,
                    child: Container(
                        width: 30,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(15))),
                        child: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white))),
                Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary, width: 3)),
                    child: const Icon(Icons.restaurant,
                        color: AppColors.primary)),
              ],
            ),

            const SizedBox(height: 80),

            // Kontroller
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Slider başlığı + seçili sayı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.chooseOptionCount,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
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
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Slider + uç değerler
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
                          onChanged: _isSpinning
                              ? null
                              : (v) => setState(() {
                            _optionCount = v.toInt();
                            _randomizeRecipes();
                          }),
                        ),
                      ),
                      Text(
                          '${min(10, _allRecipes.length)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextGrey
                                  : AppColors.textGrey)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: _isSpinning
                                  ? null
                                  : _showRecipeSelection,
                              icon: const Icon(Icons.list_alt, size: 18),
                              label: Text(s.selectRecipes,
                                  style:
                                  const TextStyle(fontSize: 13)))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed:
                              _isSpinning ? null : _randomizeRecipes,
                              icon: const Icon(Icons.auto_awesome,
                                  size: 18),
                              label: Text(s.imFeelingLucky,
                                  style:
                                  const TextStyle(fontSize: 13)))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSpinning ? null : _spin,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    child: _isSpinning
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : Text(
                        s.isEnglish ? '🎡 SPIN!' : '🎡 ÇEVİR!',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                      s.selectedRecipesCountLabel(_activeRecipes.length),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<RecipeModel> recipes;
  final List<Color> colors;

  _WheelPainter({required this.recipes, required this.colors});

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

      // Tarif adı
      final textAngle = i * sliceAngle - pi / 2 + sliceAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: recipes[i].title.length > 12
              ? '${recipes[i].title.substring(0, 12)}…'
              : recipes[i].title,
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
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.recipes != recipes || old.colors != colors;
}