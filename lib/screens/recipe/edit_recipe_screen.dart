// lib/screens/recipe/edit_recipe_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../services/imgbb_service.dart';
import '../../utils/app_constants.dart';

class EditRecipeScreen extends StatefulWidget {
  final RecipeModel recipe;
  final AppStrings strings;

  const EditRecipeScreen({
    super.key,
    required this.recipe,
    required this.strings,
  });

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipeService = RecipeService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _ingredientController;
  late TextEditingController _stepController;
  late TextEditingController _cookingTimeController;
  late TextEditingController _servingsController;
  late TextEditingController _caloriesController;

  late String _selectedCategory;
  late String _selectedDifficulty;
  late List<String> _ingredients;
  late List<String> _steps;
  late List<String> _selectedDietTags;
  File? _newImageFile;
  Uint8List? _newImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _titleController = TextEditingController(text: r.title);
    _descriptionController = TextEditingController(text: r.description);
    _ingredientController = TextEditingController();
    _stepController = TextEditingController();
    _cookingTimeController =
        TextEditingController(text: r.cookingTimeMinutes.toString());
    _servingsController = TextEditingController(text: r.servings.toString());
    _caloriesController =
        TextEditingController(text: r.calories?.toString() ?? '');
    _selectedCategory = r.category;
    _selectedDifficulty = r.difficulty;
    _ingredients = List.from(r.ingredients);
    _steps = List.from(r.steps);
    _selectedDietTags = List.from(r.dietTags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _stepController.dispose();
    _cookingTimeController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _newImageBytes = bytes);
      } else {
        setState(() => _newImageFile = File(picked.path));
      }
    }
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _ingredients.add(text);
        _ingredientController.clear();
      });
    }
  }

  void _addStep() {
    final text = _stepController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _steps.add(text);
        _stepController.clear();
      });
    }
  }

  void _toggleDietTag(String tag) {
    setState(() {
      if (_selectedDietTags.contains(tag)) {
        _selectedDietTags.remove(tag);
      } else {
        _selectedDietTags.add(tag);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      _showError(widget.strings.isEnglish
          ? 'Add at least one ingredient'
          : 'En az bir malzeme ekleyin');
      return;
    }
    if (_steps.isEmpty) {
      _showError(widget.strings.isEnglish
          ? 'Add at least one step'
          : 'En az bir adım ekleyin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Yeni fotoğraf varsa ImgBB'ye yükle
      String? imageUrl = widget.recipe.imageUrl;
      if (kIsWeb && _newImageBytes != null) {
        imageUrl = await ImgBBService.uploadImageBytes(_newImageBytes!);
      } else if (_newImageFile != null) {
        imageUrl = await ImgBBService.uploadImage(_newImageFile!);
      }

      final updatedRecipe = RecipeModel(
        id: widget.recipe.id,
        userId: widget.recipe.userId,
        userEmail: widget.recipe.userEmail,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        ingredients: _ingredients,
        steps: _steps,
        category: _selectedCategory,
        imageUrl: imageUrl,
        createdAt: widget.recipe.createdAt,
        cookingTimeMinutes: int.tryParse(_cookingTimeController.text) ?? 0,
        servings: int.tryParse(_servingsController.text) ?? 1,
        difficulty: _selectedDifficulty,
        calories: _caloriesController.text.isNotEmpty
            ? int.tryParse(_caloriesController.text)
            : null,
        dietTags: _selectedDietTags,
        favoriteCount: widget.recipe.favoriteCount,
        averageRating: widget.recipe.averageRating,
        ratingCount: widget.recipe.ratingCount,
      );

      await _recipeService.updateRecipe(updatedRecipe);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.strings.recipeUpdated),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _newImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(_newImageBytes!, fit: BoxFit.cover),
      );
    } else if (_newImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_newImageFile!, fit: BoxFit.cover),
      );
    } else if (widget.recipe.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: widget.recipe.imageUrl!,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _imagePlaceholder(),
        ),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_outlined,
            size: 48, color: AppColors.textGrey),
        const SizedBox(height: 8),
        Text(widget.strings.changePhoto,
            style: const TextStyle(color: AppColors.textGrey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.isEnglish ? 'Edit Recipe' : 'Tarifi Düzenle'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : Text(s.save,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Fotoğraf
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 20),

            // Başlık
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: s.recipeName),
              validator: (v) => v == null || v.isEmpty
                  ? (s.isEnglish
                  ? 'Recipe name cannot be empty'
                  : 'Tarif adı boş olamaz')
                  : null,
            ),
            const SizedBox(height: 16),

            // Açıklama
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(labelText: s.description),
              validator: (v) => v == null || v.isEmpty
                  ? (s.isEnglish
                  ? 'Description cannot be empty'
                  : 'Açıklama boş olamaz')
                  : null,
            ),
            const SizedBox(height: 16),

            // Kategori
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(labelText: s.category),
              items: AppCategories.categories
                  .map((c) => DropdownMenuItem(
                value: c['key'],
                child: Text(
                    '${c['emoji']} ${s.isEnglish ? c['labelEn']! : c['label']!}'),
              ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategory = v ?? 'breakfast'),
            ),
            const SizedBox(height: 16),

            // Süre ve Porsiyon
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cookingTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                      s.isEnglish ? 'Duration (min)' : 'Süre (dk)',
                      prefixIcon: const Icon(Icons.access_time_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.servings,
                      prefixIcon: const Icon(Icons.people_outline),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Zorluk
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: InputDecoration(labelText: s.difficulty),
              items: [
                DropdownMenuItem(
                    value: 'easy', child: Text('😊 ${s.easy}')),
                DropdownMenuItem(
                    value: 'medium', child: Text('😐 ${s.medium}')),
                DropdownMenuItem(
                    value: 'hard', child: Text('😤 ${s.hard}')),
              ],
              onChanged: (v) =>
                  setState(() => _selectedDifficulty = v ?? 'medium'),
            ),
            const SizedBox(height: 16),

            // Kalori
            TextFormField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: s.isEnglish
                    ? 'Calories (optional)'
                    : 'Kalori (isteğe bağlı)',
                prefixIcon:
                const Icon(Icons.local_fire_department_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Diyet etiketleri
            Text(s.dietTags,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                {'key': 'vegetarian', 'label': s.isEnglish ? '🥦 Vegetarian' : '🥦 Vejetaryen'},
                {'key': 'vegan', 'label': '🌱 Vegan'},
                {'key': 'diet', 'label': s.isEnglish ? '🥗 Diet' : '🥗 Diyet'},
                {'key': 'protein', 'label': '💪 Protein'},
                {'key': 'carb', 'label': s.isEnglish ? '🍞 Carbs' : '🍞 Karbonhidrat'},
              ].map((opt) {
                final isSelected = _selectedDietTags.contains(opt['key']);
                return FilterChip(
                  label: Text(opt['label']!),
                  selected: isSelected,
                  onSelected: (_) => _toggleDietTag(opt['key']!),
                  selectedColor: AppColors.secondary.withOpacity(0.2),
                  checkmarkColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.textGrey,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Malzemeler
            _buildSectionTitle(s.ingredients, _ingredients.length),
            ..._ingredients.asMap().entries.map((e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text('${e.key + 1}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary)),
              ),
              title: Text(e.value),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () =>
                    setState(() => _ingredients.removeAt(e.key)),
              ),
            )),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ingredientController,
                    decoration: InputDecoration(hintText: s.addIngredient),
                    onFieldSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: _addIngredient, child: Text(s.add)),
              ],
            ),
            const SizedBox(height: 24),

            // Yapılış adımları
            _buildSectionTitle(s.steps, _steps.length),
            ..._steps.asMap().entries.map((e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.secondary.withOpacity(0.15),
                child: Text('${e.key + 1}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.secondary)),
              ),
              title: Text(e.value),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => setState(() => _steps.removeAt(e.key)),
              ),
            )),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stepController,
                    decoration: InputDecoration(hintText: s.addStep),
                    onFieldSubmitted: (_) => _addStep(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addStep, child: Text(s.add)),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}