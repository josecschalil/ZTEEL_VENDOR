import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/app_colors.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/vendor_service.dart';

class EditFoodItemScreen extends StatefulWidget {
  final String? itemId;
  final String? initialCategoryId;
  final String? initialName;
  final double? initialPrice;
  final String? initialDescription;
  final bool? initialIsVeg;
  final bool? initialIsAvailable;
  final String? initialImageUrl;

  const EditFoodItemScreen({
    super.key,
    this.itemId,
    this.initialCategoryId,
    this.initialName,
    this.initialPrice,
    this.initialDescription,
    this.initialIsVeg,
    this.initialIsAvailable,
    this.initialImageUrl,
  });

  @override
  State<EditFoodItemScreen> createState() => _EditFoodItemScreenState();
}

class _EditFoodItemScreenState extends State<EditFoodItemScreen>
    with TickerProviderStateMixin {
  late bool _isAvailable;
  late bool _isVeg;
  int _selectedNavIndex = 1;

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;

  List<Map<String, String>> _categories = [];
  String? _selectedCategoryId;
  File? _pickedImageFile;
  String? _imageUrl;
  bool _isLoadingCategories = true;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.initialIsAvailable ?? true;
    _isVeg = widget.initialIsVeg ?? false;
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _priceController = TextEditingController(text: widget.initialPrice != null ? widget.initialPrice!.toStringAsFixed(2) : '');
    _descController = TextEditingController(text: VendorService.cleanDescription(widget.initialDescription));
    _selectedCategoryId = widget.initialCategoryId;
    _imageUrl = widget.initialImageUrl;

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final res = await VendorService.getMenuCategories();
    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final list = res['data'] as List<dynamic>;
      List<Map<String, String>> catList = [];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          catList.add({
            'id': item['id']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Category',
          });
        }
      }
      setState(() {
        _categories = catList;
        if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
          if (catList.isNotEmpty) {
            _selectedCategoryId = catList.first['id'];
          }
        } else {
          final exists = catList.any((c) => c['id'] == _selectedCategoryId);
          if (!exists && catList.isNotEmpty) {
            _selectedCategoryId = catList.first['id'];
          }
        }
        _isLoadingCategories = false;
      });
    } else {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _pickedImageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not pick image: $e'),
        backgroundColor: AppColors.orangeDim,
      ));
    }
  }

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();
    final description = _descController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter an item name.'),
        backgroundColor: AppColors.orangeDim,
      ));
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid price.'),
        backgroundColor: AppColors.orangeDim,
      ));
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select or create a menu category first.'),
        backgroundColor: AppColors.orangeDim,
      ));
      return;
    }

    setState(() => _isSaving = true);

    Map<String, dynamic> res;
    if (widget.itemId != null && widget.itemId!.isNotEmpty) {
      res = await VendorService.updateMenuItem(
        id: widget.itemId!,
        name: name,
        categoryId: _selectedCategoryId,
        price: price,
        description: description,
        isVegetarian: _isVeg,
        isAvailable: _isAvailable,
        image: _pickedImageFile,
      );
    } else {
      res = await VendorService.createMenuItem(
        name: name,
        categoryId: _selectedCategoryId!,
        price: price,
        description: description,
        isVegetarian: _isVeg,
        isAvailable: _isAvailable,
        image: _pickedImageFile,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.itemId != null ? 'Item updated successfully!' : 'Item created successfully!'),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] ?? 'Failed to save item'),
        backgroundColor: AppColors.orangeDim,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemId != null && widget.itemId!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildTopBar(isEditing),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(isEditing),
                    const SizedBox(height: 18),
                    _buildHeroImageSection(),
                    const SizedBox(height: 26),
                    _buildItemNameField(),
                    const SizedBox(height: 20),
                    _buildPriceAndCategoryRow(),
                    const SizedBox(height: 20),
                    _buildDietaryToggle(),
                    const SizedBox(height: 20),
                    _buildDescriptionField(),
                    const SizedBox(height: 28),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────
  Widget _buildTopBar(bool isEditing) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary,
                  size: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEditing ? 'Edit Item' : 'New Food Item',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Page Header ─────────────────────────────────────────────────
  Widget _buildPageHeader(bool isEditing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'UPDATE FOOD ITEM' : 'ADD NEW FOOD ITEM',
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEditing ? 'Modify dish details or pricing' : 'Create a fresh dish for your menu',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Image Section ──────────────────────────────────────────
  Widget _buildHeroImageSection() {
    ImageProvider? imgProvider;
    if (_pickedImageFile != null) {
      imgProvider = FileImage(_pickedImageFile!);
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      imgProvider = NetworkImage(_imageUrl!);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            image: imgProvider != null
                ? DecorationImage(image: imgProvider, fit: BoxFit.cover)
                : null,
          ),
          child: Stack(
            children: [
              if (imgProvider == null)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: AppColors.orange, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'Tap to add item image',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        imgProvider != null ? 'Change Photo' : 'Upload',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Item Name ───────────────────────────────────────────────────
  Widget _buildItemNameField() {
    return _labeledField(
      label: 'ITEM NAME',
      child: _styledInput(
        controller: _nameController,
        hint: 'e.g. Saffron Truffle Risotto',
        maxLines: 1,
      ),
    );
  }

  // ─── Price & Category ────────────────────────────────────────────
  Widget _buildPriceAndCategoryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildPriceFieldContent(padded: false)),
          const SizedBox(width: 12),
          Expanded(child: _buildCategoryDropdownContent(padded: false)),
        ],
      ),
    );
  }

  Widget _buildPriceFieldContent({required bool padded}) {
    return _labeledField(
      label: 'PRICE (\$)',
      child: _styledInput(
        controller: _priceController,
        hint: '0.00',
        maxLines: 1,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefix: const Padding(
          padding: EdgeInsets.only(right: 6),
          child: Text(
            '\$',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      padded: padded,
    );
  }

  Widget _buildCategoryDropdownContent({required bool padded}) {
    return _labeledField(
      label: 'CATEGORY',
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: _isLoadingCategories
            ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange)))
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceRaised,
                  iconEnabledColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  hint: const Text('Select Category', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['id'],
                      child: Text(
                        cat['name']!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategoryId = val);
                    }
                  },
                ),
              ),
      ),
      padded: padded,
    );
  }

  // ─── Dietary & Availability Toggles ─────────────────────────────
  Widget _buildDietaryToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isVeg = !_isVeg),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isVeg ? AppColors.green : AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(_isVeg ? Icons.eco_rounded : Icons.restaurant_menu_rounded, color: _isVeg ? AppColors.green : AppColors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(_isVeg ? 'Vegetarian' : 'Non-Veg', style: TextStyle(color: _isVeg ? AppColors.green : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAvailable = !_isAvailable),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isAvailable ? AppColors.orange : AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(_isAvailable ? Icons.check_circle_rounded : Icons.cancel_outlined, color: _isAvailable ? AppColors.orange : AppColors.textMuted, size: 20),
                    const SizedBox(width: 8),
                    Text(_isAvailable ? 'Available' : 'Hidden', style: TextStyle(color: _isAvailable ? AppColors.orange : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Description ─────────────────────────────────────────────────
  Widget _buildDescriptionField() {
    return _labeledField(
      label: 'DESCRIPTION',
      child: _styledInput(
        controller: _descController,
        hint: 'Describe the dish, ingredients, and preparation...',
        maxLines: 4,
      ),
    );
  }

  // ─── Save Button ─────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveItem,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.orange, AppColors.orange],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    widget.itemId != null ? 'Save Changes' : 'Create Item',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Shared Helpers ───────────────────────────────────────────────
  Widget _labeledField({
    required String label,
    required Widget child,
    bool padded = true,
  }) {
    return Padding(
      padding: padded ? const EdgeInsets.symmetric(horizontal: 20) : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _styledInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          height: 1.5,
        ),
        cursorColor: AppColors.orange,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 13),
          prefixIcon: prefix != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 0),
                  child: prefix,
                )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: EdgeInsets.symmetric(
            horizontal: prefix != null ? 6 : 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
