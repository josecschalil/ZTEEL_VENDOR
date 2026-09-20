import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/services/vendor_service.dart';

/// ─────────────────────────────────────────────────────────────────
/// Design tokens
///
/// These mirror the app-wide design system. If you already have an
/// AppColors class, replace this block with your real imports/fields —
/// just make sure the hex values line up so every screen stays visually
/// consistent.
/// ─────────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const primaryDark = Color(0xFF0F172A);
  static const accent = Color(0xFF10B981); // emerald
  static const accentLight = Color(0xFFECFDF5);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
}

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
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.initialIsAvailable ?? true;
    _isVeg = widget.initialIsVeg ?? false;
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _priceController = TextEditingController(
        text: widget.initialPrice != null
            ? widget.initialPrice!.toStringAsFixed(2)
            : '');
    _descController = TextEditingController(
        text: VendorService.cleanDescription(widget.initialDescription));
    _selectedCategoryId = widget.initialCategoryId;
    _imageUrl = widget.initialImageUrl;

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

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
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _pickedImageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not pick image: $e', isError: true);
    }
  }

  void _showSnack(String message,
      {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError
            ? _C.error
            : (isSuccess ? _C.primaryDark : _C.textSecondary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();
    final description = _descController.text.trim();

    if (name.isEmpty) {
      _showSnack('Please enter an item name.', isError: true);
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null || price < 0) {
      _showSnack('Please enter a valid price.', isError: true);
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      _showSnack('Please select or create a menu category first.',
          isError: true);
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
      _showSnack(
        widget.itemId != null
            ? 'Item updated successfully!'
            : 'Item created successfully!',
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    } else {
      _showSnack(res['error'] ?? 'Failed to save item', isError: true);
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInPageHeader(isEditing),
                    const SizedBox(height: 20),
                    _buildHeroImageSection(),
                    const SizedBox(height: 20),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildItemNameField(),
                          const SizedBox(height: 18),
                          _buildPriceAndCategoryRow(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDietaryToggle(),
                    const SizedBox(height: 16),
                    _sectionCard(child: _buildDescriptionField()),
                    const SizedBox(height: 28),
                    _buildSaveButton(isEditing),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Simple In-Page Header ───────────────────────────────────────
  Widget _buildInPageHeader(bool isEditing) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: _C.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          isEditing ? 'Edit Food Item' : 'New Food Item',
          style: const TextStyle(
            color: _C.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ─── Shared surfaces ─────────────────────────────────────────────
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
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

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
          image: imgProvider != null
              ? DecorationImage(image: imgProvider, fit: BoxFit.cover)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (imgProvider == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _C.accentLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_a_photo_outlined,
                          color: _C.accent, size: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to add item image',
                      style: TextStyle(
                        color: _C.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'JPG or PNG, up to 5MB',
                      style: TextStyle(
                        color: _C.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (imgProvider != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _C.primaryDark.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 12),
                      SizedBox(width: 5),
                      Text(
                        'Change Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPriceFieldContent()),
        const SizedBox(width: 12),
        Expanded(child: _buildCategoryDropdownContent()),
      ],
    );
  }

  Widget _buildPriceFieldContent() {
    return _labeledField(
      label: 'PRICE (\$)',
      child: _styledInput(
        controller: _priceController,
        hint: '0.00',
        maxLines: 1,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefix: Text(
          '\$',
          style: TextStyle(
            color: _C.accent,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdownContent() {
    return _labeledField(
      label: 'CATEGORY',
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: _isLoadingCategories
            ? Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _C.accent),
                ),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  dropdownColor: _C.surface,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: _C.textSecondary, size: 20),
                  style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  hint: Text('Select Category',
                      style: TextStyle(color: _C.textMuted, fontSize: 13)),
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
    );
  }

  // ─── Dietary & Availability Toggles ─────────────────────────────
  Widget _buildDietaryToggle() {
    return Row(
      children: [
        Expanded(
          child: _togglePill(
            active: _isVeg,
            activeIcon: Icons.eco_rounded,
            inactiveIcon: Icons.restaurant_menu_rounded,
            activeLabel: 'Vegetarian',
            inactiveLabel: 'Non-Veg',
            onTap: () => setState(() => _isVeg = !_isVeg),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _togglePill(
            active: _isAvailable,
            activeIcon: Icons.check_circle_rounded,
            inactiveIcon: Icons.visibility_off_rounded,
            activeLabel: 'Available',
            inactiveLabel: 'Hidden',
            onTap: () => setState(() => _isAvailable = !_isAvailable),
          ),
        ),
      ],
    );
  }

  Widget _togglePill({
    required bool active,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String activeLabel,
    required String inactiveLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: active ? _C.accentLight : _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? _C.accent : _C.border),
        ),
        child: Row(
          children: [
            Icon(
              active ? activeIcon : inactiveIcon,
              color: active ? _C.accent : _C.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                active ? activeLabel : inactiveLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? _C.accent : _C.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
  Widget _buildSaveButton(bool isEditing) {
    return GestureDetector(
      onTap: _isSaving ? null : _saveItem,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _isSaving ? 0.7 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _C.primaryDark,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _C.primaryDark.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEditing ? Icons.check_rounded : Icons.add_rounded,
                        color: _C.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Save Changes' : 'Create Item',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _C.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
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
        color: _C.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
          color: _C.textPrimary,
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: _C.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _C.textMuted, fontSize: 13),
          prefixIcon: prefix != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 0),
                  child: prefix,
                )
              : null,
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
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
