// lib/screens/shopping/shopping_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_constants.dart';

class ShoppingListScreen extends StatefulWidget {
  final AppStrings strings;
  const ShoppingListScreen({super.key, required this.strings});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _db = FirebaseFirestore.instance;
  final _textCtrl = TextEditingController();
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  CollectionReference get _col =>
      _db.collection('users').doc(_uid).collection('shoppingList');

  Future<void> _addItem(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await _col.add({'text': t, 'checked': false, 'createdAt': FieldValue.serverTimestamp()});
    _textCtrl.clear();
  }

  Future<void> _toggle(String docId, bool current) async {
    await _col.doc(docId).update({'checked': !current});
  }

  Future<void> _delete(String docId) async {
    await _col.doc(docId).delete();
  }

  Future<void> _clearChecked(List<QueryDocumentSnapshot> docs) async {
    final batch = _db.batch();
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      if (data['checked'] == true) batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        title: Text(
          s.isEnglish ? 'Shopping List' : 'Alışveriş Listesi',
          style: TextStyle(fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextDark : AppColors.textDark),
        ),
      ),
      body: Column(children: [
        // Giriş alanı
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF3D3530) : AppColors.outline),
                ),
                child: TextField(
                  controller: _textCtrl,
                  onSubmitted: _addItem,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: isDark ? AppColors.darkTextDark : AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: s.isEnglish ? 'Add item...' : 'Ürün ekle...',
                    hintStyle: TextStyle(color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                    prefixIcon: Icon(Icons.add_shopping_cart_outlined,
                        color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _addItem(_textCtrl.text),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCB490E), Color(0xFFE8784A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
            ),
          ]),
        ),

        // Liste
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _col.orderBy('createdAt').snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data?.docs ?? [];
              final unchecked = docs.where((d) => (d.data() as Map)['checked'] != true).toList();
              final checked   = docs.where((d) => (d.data() as Map)['checked'] == true).toList();

              if (docs.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_basket_outlined, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.isEnglish ? 'Your list is empty' : 'Listeniz boş',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextDark : AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.isEnglish ? 'Add items above' : 'Yukarıdan ürün ekleyin',
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                  ),
                ]));
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  // Eklenmemiş ürünler
                  if (unchecked.isNotEmpty) ...[
                    Text(
                      s.isEnglish ? 'To Buy (${unchecked.length})' : 'Alınacaklar (${unchecked.length})',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                    ),
                    const SizedBox(height: 8),
                    ...unchecked.map((d) => _buildItem(d, isDark)),
                    const SizedBox(height: 16),
                  ],

                  // Alınmış ürünler
                  if (checked.isNotEmpty) ...[
                    Row(children: [
                      Text(
                        s.isEnglish ? 'Done (${checked.length})' : 'Alındı (${checked.length})',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _clearChecked(docs),
                        child: Text(
                          s.isEnglish ? 'Clear done' : 'Temizle',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    ...checked.map((d) => _buildItem(d, isDark)),
                  ],
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildItem(QueryDocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final text    = data['text'] as String? ?? '';
    final checked = data['checked'] as bool? ?? false;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _delete(doc.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: checked
                ? Colors.transparent
                : (isDark ? const Color(0xFF3D3530) : AppColors.outline),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: GestureDetector(
            onTap: () => _toggle(doc.id, checked),
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: checked ? AppColors.primary : (isDark ? AppColors.darkTextGrey : AppColors.textGrey),
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          title: Text(
            text,
            style: TextStyle(
              decoration: checked ? TextDecoration.lineThrough : null,
              color: checked
                  ? (isDark ? AppColors.darkTextGrey : AppColors.textGrey)
                  : (isDark ? AppColors.darkTextDark : AppColors.textDark),
              fontSize: 15,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, size: 18,
                color: isDark ? AppColors.darkTextGrey : AppColors.textGrey),
            onPressed: () => _delete(doc.id),
          ),
        ),
      ),
    );
  }
}