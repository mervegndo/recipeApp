// lib/screens/recipe/add_recipe_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_constants.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipeService = RecipeService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _stepController = TextEditingController();

  String _selectedCategory = 'breakfast';
  final List<String> _ingredients = [];
  final List<String> _steps = [];
  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (picked != null) setState(() => _imageFile = File(picked.path));
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

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      _showError('En az bir malzeme ekleyin');
      return;
    }
    if (_steps.isEmpty) {
      _showError('En az bir adım ekleyin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
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
      );

      await _recipeService.addRecipe(recipe, imageFile: _imageFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarif başarıyla eklendi! 🎉'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Tarif'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRecipe,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Kaydet',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Fotoğraf seçme
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 48, color: AppColors.textGrey),
                          SizedBox(height: 8),
                          Text('Fotoğraf Ekle (isteğe bağlı)',
                              style: TextStyle(color: AppColors.textGrey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Başlık
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tarif Adı *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Tarif adı boş olamaz' : null,
            ),
            const SizedBox(height: 16),

            // Açıklama
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Açıklama *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Açıklama boş olamaz' : null,
            ),
            const SizedBox(height: 16),

            // Kategori
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: AppCategories.categories
                  .map((c) => DropdownMenuItem(
                        value: c['key'],
                        child: Text('${c['emoji']} ${c['label']}'),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategory = v ?? 'breakfast'),
            ),
            const SizedBox(height: 24),

            // Malzemeler
            _buildSectionTitle('Malzemeler', _ingredients.length),
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
                    decoration:
                        const InputDecoration(hintText: 'Malzeme ekle...'),
                    onFieldSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: _addIngredient, child: const Text('Ekle')),
              ],
            ),
            const SizedBox(height: 24),

            // Yapılış adımları
            _buildSectionTitle('Yapılış Adımları', _steps.length),
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
                    decoration:
                        const InputDecoration(hintText: 'Adım ekle...'),
                    onFieldSubmitted: (_) => _addStep(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: _addStep, child: const Text('Ekle')),
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
