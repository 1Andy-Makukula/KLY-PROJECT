/// =============================================================================
/// KithLy Global Protocol - EDIT PRODUCT SHEET (Phase IV-Extension)
/// edit_product_sheet.dart - Product Add/Edit Form
/// =============================================================================
///
/// Bottom sheet form for creating or editing products.
/// Protocol Link: If stock is updated > 50%, clears urgent flags via
/// DashboardProvider.confirmProductStock().
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/alpha_theme.dart';
import '../../state_machine/product_provider.dart';
import '../../state_machine/dashboard_provider.dart';

/// Edit/Add Product Bottom Sheet
class EditProductSheet extends StatefulWidget {
  /// If null, we're in "Add" mode. Otherwise "Edit" mode.
  final ProductModel? product;

  const EditProductSheet({super.key, this.product});

  @override
  State<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<EditProductSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;
  late String _selectedCategory;
  late bool _isHidden;

  bool get _isEditMode => widget.product != null;

  static const _categories = [
    'General',
    'Beverages',
    'Bakery',
    'Groceries',
    'Tools',
    'Medicine',
    'Electronics',
    'Clothing',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.priceZmw.toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _stockController = TextEditingController(
      text: p != null ? p.stockLevel.toString() : '',
    );
    _selectedCategory = p?.category ?? 'General';
    _isHidden = p?.isHidden ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final description = _descriptionController.text.trim();

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and valid price are required')),
      );
      return;
    }

    final productProvider = context.read<ProductProvider>();

    if (_isEditMode) {
      // Update existing
      final updated = widget.product!.copyWith(
        name: name,
        priceZmw: price,
        stockLevel: stock,
        description: description,
        category: _selectedCategory,
        isHidden: _isHidden,
      );
      productProvider.updateProduct(updated);

      // Protocol Link: stock > 50% clears urgent flags
      if (stock > 50) {
        try {
          context.read<DashboardProvider>().confirmProductStock(name);
        } catch (_) {
          // DashboardProvider may not be in ancestor tree
        }
      }
    } else {
      // Add new
      final newProduct = ProductModel(
        skuId: 'SKU-${DateTime.now().millisecondsSinceEpoch}',
        shopId: 'shop-1', // Default shop for now
        shopName: 'My Shop',
        shopCity: 'Lusaka',
        name: name,
        priceZmw: price,
        stockLevel: stock,
        description: description,
        category: _selectedCategory,
        isHidden: _isHidden,
      );
      productProvider.addProduct(newProduct);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AlphaTheme.backgroundCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AlphaTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _isEditMode ? 'Edit Product' : 'Add Product',
              style: const TextStyle(
                color: AlphaTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Name
            _buildField(
              controller: _nameController,
              label: 'Product Name',
              icon: Icons.label_outline_rounded,
            ),
            const SizedBox(height: 16),

            // Price + Stock row
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _priceController,
                    label: 'Price (ZMW)',
                    icon: Icons.payments_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _stockController,
                    label: 'Stock Level',
                    icon: Icons.inventory_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            _buildField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Category dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AlphaTheme.backgroundDark,
                borderRadius: AlphaTheme.buttonRadius,
                border: Border.all(
                  color: AlphaTheme.textMuted.withOpacity(0.2),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AlphaTheme.backgroundCard,
                  style: const TextStyle(
                    color: AlphaTheme.textPrimary,
                    fontSize: 14,
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AlphaTheme.textMuted,
                  ),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hidden toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AlphaTheme.backgroundDark,
                borderRadius: AlphaTheme.buttonRadius,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_off_outlined,
                    color: AlphaTheme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Hide from customers',
                      style: TextStyle(
                        color: AlphaTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _isHidden,
                    onChanged: (v) => setState(() => _isHidden = v),
                    activeColor: AlphaTheme.accentAmber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AlphaTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AlphaTheme.buttonRadius,
                ),
              ),
              child: Text(
                _isEditMode ? 'Save Changes' : 'Add Product',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AlphaTheme.textPrimary, fontSize: 14),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AlphaTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AlphaTheme.textMuted, size: 20),
        filled: true,
        fillColor: AlphaTheme.backgroundDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AlphaTheme.textMuted.withOpacity(0.2),
          ),
          borderRadius: AlphaTheme.buttonRadius,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AlphaTheme.accentBlue),
          borderRadius: AlphaTheme.buttonRadius,
        ),
      ),
    );
  }
}
