// lib/screens/spin/spin_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
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
  List<RecipeModel> _recipes = [];
  RecipeModel? _selectedRecipe;
  bool _isSpinning = false;
  double _currentAngle = 0;

  final List<Color> _sliceColors = [
    const Color(0xFFA53600),
    const Color(0xFFCB490E),
    const Color(0xFFFF8C69),
    const Color(0xFFFFB59B),
    const Color(0xFF8D7167),
    const Color(0xFF594139),
    const Color(0xFFE1BFB4),
    const Color(0xFFF4ECE6),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    _recipeService.getAllRecipes().listen((recipes) {
      if (mounted) setState(() => _recipes = recipes);
    });
  }

  void _spin() {
    if (_isSpinning || _recipes.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _selectedRecipe = null;
    });

    final random = Random();
    final extraSpins = 5 + random.nextInt(5);
    final selectedIndex = random.nextInt(_recipes.length);
    final sliceAngle = (2 * pi) / _recipes.length;
    final targetAngle = _currentAngle +
        (extraSpins * 2 * pi) +
        (2 * pi - (selectedIndex * sliceAngle + sliceAngle / 2));

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
          _currentAngle = targetAngle % (2 * pi);
          _selectedRecipe = _recipes[selectedIndex];
          _isSpinning = false;
        });
        _showResult(_recipes[selectedIndex]);
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.strings.isEnglish
                  ? '🎉 Tonight you cook!'
                  : '🎉 Bu gece bunu pişiriyorsun!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (recipe.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  recipe.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.restaurant_menu,
                        size: 48, color: AppColors.textGrey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              recipe.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_outlined,
                    size: 16, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text(
                  '${recipe.cookingTimeMinutes} ${widget.strings.isEnglish ? 'min' : 'dk'}',
                  style: const TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.bar_chart,
                    size: 16, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text(
                  recipe.difficulty == 'easy'
                      ? widget.strings.easy
                      : recipe.difficulty == 'hard'
                      ? widget.strings.hard
                      : widget.strings.medium,
                  style: const TextStyle(color: AppColors.textGrey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _spin();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      widget.strings.isEnglish ? 'Spin Again' : 'Tekrar Çevir',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                            recipe: recipe,
                            isGuest: widget.isGuest,
                            strings: widget.strings,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      widget.strings.isEnglish ? 'View Recipe' : 'Tarifi Gör',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.isEnglish ? '🎡 What to Cook?' : '🎡 Ne Pişirsem?'),
      ),
      body: _recipes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu,
                size: 64, color: AppColors.textGrey),
            const SizedBox(height: 16),
            Text(
              s.isEnglish
                  ? 'No recipes yet to spin!'
                  : 'Çarkı çevirmek için tarif yok!',
              style: const TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              s.isEnglish
                  ? "Can't decide? Let fate decide!"
                  : 'Ne pişireceğine karar veremiyor musun?',
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.darkTextGrey
                    : AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s.isEnglish ? 'Spin the wheel!' : 'Çarkı çevir!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),

            // Çarkıfelek
            Stack(
              alignment: Alignment.center,
              children: [
                // Ok
                Positioned(
                  top: 0,
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),

                // Çark
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _isSpinning
                            ? _animation.value
                            : _currentAngle,
                        child: CustomPaint(
                          size: const Size(300, 300),
                          painter: _WheelPainter(
                            recipes: _recipes,
                            colors: _sliceColors,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Merkez daire
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Çevir butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: _isSpinning ? null : _spin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: _isSpinning
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  s.isEnglish ? '🎡 Spin!' : '🎡 Çevir!',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              '${_recipes.length} ${s.isEnglish ? 'recipes in the wheel' : 'tarif çarkta'}',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextGrey
                    : AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 40),
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
          text: recipes[i].title.length > 10
              ? '${recipes[i].title.substring(0, 10)}...'
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
      textPainter.layout(maxWidth: 80);
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }

    // Dış çerçeve
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}