// lib/screens/recipe/add_recipe_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../services/imgbb_service.dart';
import '../../utils/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart';

class AddRecipeScreen extends StatefulWidget {
  final AppStrings strings;
  const AddRecipeScreen({super.key, required this.strings});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipeService = RecipeService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedUnit = 'cup';

  final List<Map<String, String>> _unitOptions = [
    {'key': 'tsp', 'en': 'tsp', 'tr': 'çay kaşığı'},
    {'key': 'tbsp', 'en': 'tbsp', 'tr': 'yemek kaşığı'},
    {'key': 'cup', 'en': 'cup', 'tr': 'bardak'},
    {'key': 'glass', 'en': 'glass', 'tr': 'su bardağı'},
    {'key': 'piece', 'en': 'piece', 'tr': 'adet'},
    {'key': 'g', 'en': 'g', 'tr': 'g'},
    {'key': 'kg', 'en': 'kg', 'tr': 'kg'},
    {'key': 'ml', 'en': 'ml', 'tr': 'ml'},
    {'key': 'L', 'en': 'L', 'tr': 'L'},
    {'key': 'pinch', 'en': 'pinch', 'tr': 'tutam'},
  ];
  final _stepController = TextEditingController();
  final _cookingTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _caloriesController = TextEditingController();

  String _selectedCategory = 'breakfast';
  String _selectedDifficulty = 'medium';
  final List<String> _ingredients = [];
  final List<String> _steps = [];
  final List<String> _selectedDietTags = [];
  File? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  final _ingredientFocusNode = FocusNode();
  final translator = GoogleTranslator();

  @override
  void dispose() {
    _ingredientFocusNode.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _amountController.dispose();
    _stepController.dispose();
    _cookingTimeController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1920, imageQuality: 100);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _imageBytes = bytes);
      } else {
        setState(() => _imageFile = File(picked.path));
      }
    }
  }

  Future<void> _addIngredient() async {
    final ingredientName = _ingredientController.text.trim();
    if (ingredientName.isEmpty) return;
    final amount = _amountController.text.trim();
    if (amount.isEmpty) return;

    setState(() {
      final selectedUnitData =
      _unitOptions.firstWhere((unit) => unit['key'] == _selectedUnit);
      final unitLabel = widget.strings.isEnglish
          ? selectedUnitData['en']!
          : selectedUnitData['tr']!;
      _ingredients.add('$amount $unitLabel $ingredientName');
      _amountController.clear();
      _ingredientController.clear();
      _selectedUnit = 'cup';
    });

    try {
      final ingredientRef =
      FirebaseFirestore.instance.collection('ingredients');

      final translationToEn = await translator.translate(
        ingredientName,
        to: 'en',
      );

      final translationToTr = await translator.translate(
        ingredientName,
        to: 'tr',
      );

      final ingredientEn = translationToEn.text.toLowerCase();
      final ingredientTr = translationToTr.text.toLowerCase();

      final existing = await ingredientRef
          .where('searchEn', isEqualTo: ingredientEn)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await ingredientRef.add({
          'nameOriginal': ingredientName,
          'nameEn': ingredientEn,
          'nameTr': ingredientTr,
          'searchEn': ingredientEn,
          'searchTr': ingredientTr,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _showError('Ingredient saved locally, but database update failed: $e');
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

  Future<void> _saveRecipe() async {
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
      final user = FirebaseAuth.instance.currentUser!;

      String? imageUrl;
      if (kIsWeb && _imageBytes != null) {
        imageUrl = await ImgBBService.uploadImageBytes(_imageBytes!);
      } else if (_imageFile != null) {
        imageUrl = await ImgBBService.uploadImage(_imageFile!);
      }

      final recipe = RecipeModel(
        id: _recipeService.generateId(),
        userId: user.uid,
        userEmail: user.email ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        ingredients: _ingredients,
        steps: _steps,
        category: _selectedCategory,
        createdAt: DateTime.now(),
        cookingTimeMinutes: int.tryParse(_cookingTimeController.text) ?? 0,
        servings: int.tryParse(_servingsController.text) ?? 1,
        difficulty: _selectedDifficulty,
        calories: _caloriesController.text.isNotEmpty
            ? int.tryParse(_caloriesController.text)
            : null,
        dietTags: _selectedDietTags,
        imageUrl: imageUrl,
        // ✅ Cloud Function'ın hangi dile çevireceğini belirler
        originalLanguage: widget.strings.isEnglish ? 'en' : 'tr',
      );

      await _recipeService.addRecipe(recipe);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.strings.recipeAdded),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.addRecipe),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRecipe,
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
                {
                  'key': 'vegetarian',
                  'label': s.isEnglish ? '🥦 Vegetarian' : '🥦 Vejetaryen'
                },
                {'key': 'vegan', 'label': '🌱 Vegan'},
                {
                  'key': 'diet',
                  'label': s.isEnglish ? '🥗 Diet' : '🥗 Diyet'
                },
                {'key': 'protein', 'label': '💪 Protein'},
                {
                  'key': 'carb',
                  'label': s.isEnglish ? '🍞 Carbs' : '🍞 Karbonhidrat'
                },
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
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: s.isEnglish ? 'Amount' : 'Miktar',
                          hintText: '1',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          labelText: s.isEnglish ? 'Unit' : 'Birim',
                        ),
                        items: _unitOptions.map((unit) {
                          return DropdownMenuItem<String>(
                            value: unit['key'],
                            child: Text(
                              s.isEnglish ? unit['en']! : unit['tr']!,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value ?? 'cup';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RawAutocomplete<String>(
                  textEditingController: _ingredientController,
                  focusNode: _ingredientFocusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    final query = textEditingValue.text.trim().toLowerCase();
                    if (query.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    final snapshot = await FirebaseFirestore.instance
                        .collection('ingredients')
                        .where(
                      s.isEnglish ? 'searchEn' : 'searchTr',
                      isGreaterThanOrEqualTo: query,
                    )
                        .where(
                      s.isEnglish ? 'searchEn' : 'searchTr',
                      isLessThanOrEqualTo: '$query\uf8ff',
                    )
                        .limit(10)
                        .get();
                    return snapshot.docs.map((doc) {
                      return s.isEnglish
                          ? doc['nameEn'].toString()
                          : doc['nameTr'].toString();
                    }).toList();
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: s.addIngredient,
                      ),
                      onFieldSubmitted: (_) => _addIngredient(),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 250,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _addIngredient,
                    child: Text(s.add),
                  ),
                ),
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

  Widget _buildImagePreview() {
    if (kIsWeb && _imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
      );
    } else if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_imageFile!, fit: BoxFit.cover),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_outlined,
            size: 48, color: AppColors.textGrey),
        const SizedBox(height: 8),
        Text(widget.strings.addPhoto,
            style: const TextStyle(color: AppColors.textGrey)),
      ],
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
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}