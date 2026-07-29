import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/app_colors.dart';

class EditFoodItemScreen extends StatefulWidget {
  const EditFoodItemScreen({super.key});

  @override
  State<EditFoodItemScreen> createState() => _EditFoodItemScreenState();
}

class _EditFoodItemScreenState extends State<EditFoodItemScreen>
    with TickerProviderStateMixin {
  bool _isAvailable = true;
  bool _isVeg = true;
  int _selectedNavIndex = 1; // Orders tab

  final _nameController =
      TextEditingController(text: 'Saffron Truffle Risotto');
  final _priceController = TextEditingController(text: '28.50');
  final _descController = TextEditingController(
    text:
        'Creamy Arborio rice slow-cooked with premium Persian saffron threads, finished with white truffle oil and shavings of 24–month aged Parmigiano-Reggiano.',
  );
  final _tagController = TextEditingController();

  String _selectedCategory = 'Main Course';
  List<String> _tags = ['Signature', 'Gluten-Free', 'Truffle'];

  final _categories = [
    'Main Course',
    'Starter',
    'Dessert',
    'Drinks',
    'Sides',
    'Special',
  ];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() => _tags.add(t));
      _tagController.clear();
    }
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 18),
                    _buildHeroImageSection(),
                    const SizedBox(height: 22),
                    _buildPhotoAnglePickers(),
                    const SizedBox(height: 26),
                    _buildItemNameField(),
                    const SizedBox(height: 20),
                    _buildPriceAndCategoryRow(),
                    const SizedBox(height: 20),
                    _buildDietaryToggle(),
                    const SizedBox(height: 20),
                    _buildTagsSection(),
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
  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.green, AppColors.gold],
                ),
              ),
              child: const Center(
                child: Text(
                  'Sto',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Saffron Bistro',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Notification bell with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.orange,
                    size: 19,
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Page Header ─────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ),
          const Text(
            'Edit Food Item',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // Availability toggle
          _buildAvailabilityToggle(),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isAvailable = !_isAvailable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _isAvailable
              ? AppColors.textWhite
              : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isAvailable
                ? AppColors.border
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AVAILABLE',
              style: TextStyle(
                color:
                    _isAvailable ? AppColors.orange : AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            _MiniToggle(value: _isAvailable),
          ],
        ),
      ),
    );
  }

  // ─── Hero Image ──────────────────────────────────────────────────
  Widget _buildHeroImageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // Image container
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.surfaceRaised,
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Simulated food image with gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.9,
                          colors: [
                            AppColors.border,
                            AppColors.bg,
                          ],
                        ),
                      ),
                    ),
                    // Food illustration placeholder
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.orange.withOpacity(0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.orange,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to change main photo',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Edit overlay badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 227, 226, 225),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.textPrimary.withOpacity(0.15),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              color: AppColors.textPrimary,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Photo Angle Pickers ─────────────────────────────────────────
  Widget _buildPhotoAnglePickers() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
              child: _anglePickerBtn(Icons.photo_camera_outlined, 'SIDE VIEW')),
          const SizedBox(width: 12),
          Expanded(
              child: _anglePickerBtn(Icons.camera_alt_outlined, 'TOP DOWN')),
        ],
      ),
    );
  }

  Widget _anglePickerBtn(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderAccent.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
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

  // ─── Price ───────────────────────────────────────────────────────
  Widget _buildPriceField() {
    return _buildPriceFieldContent(padded: true);
  }

  Widget _buildPriceFieldContent({required bool padded}) {
    return _labeledField(
      label: 'PRICE (\$)',
      child: _styledInput(
        controller: _priceController,
        hint: '0.00',
        maxLines: 1,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefix: Padding(
          padding: const EdgeInsets.only(right: 6),
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

  // ─── Category Dropdown ───────────────────────────────────────────
  Widget _buildCategoryDropdown() {
    return _buildCategoryDropdownContent(padded: true);
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
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCategory,
            isExpanded: true,
            dropdownColor: AppColors.surfaceRaised,
            iconEnabledColor: AppColors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
            items: _categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
        ),
      ),
      padded: padded,
    );
  }

  // ─── Dietary Toggle ──────────────────────────────────────────────
  Widget _buildDietaryToggle() {
    return _labeledField(
      label: 'DIETARY TYPE',
      child: Row(
        children: [
          Expanded(
              child: _dietBtn(true, Icons.eco_rounded, 'Veg', AppColors.green)),
          const SizedBox(width: 12),
          Expanded(
            child: _dietBtn(
              false,
              Icons.restaurant_menu_rounded,
              'Non-Veg',
              AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dietBtn(bool isVeg, IconData icon, String label, Color color) {
    final active = _isVeg == isVeg;
    return GestureDetector(
      onTap: () => setState(() => _isVeg = isVeg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color.withOpacity(0.55) : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? color : AppColors.textMuted, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: active ? color : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tags ────────────────────────────────────────────────────────
  Widget _buildTagsSection() {
    return _labeledField(
      label: 'KEYWORDS / SEARCH TAGS',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._tags.map((tag) => _tagChip(tag)),
              ],
            ),
            const SizedBox(height: 8),
            // Add tag input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                    ),
                    cursorColor: AppColors.orange,
                    onSubmitted: _addTag,
                    decoration: InputDecoration(
                      hintText: 'Add tag...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _addTag(_tagController.text),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.orangeDim,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.orange,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(String tag) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color:
                    const Color.fromARGB(255, 255, 255, 255).withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 10, color: Color.fromARGB(255, 255, 255, 255)),
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
        maxLines: 5,
      ),
    );
  }

  // ─── Save Button ─────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.orange, AppColors.orange],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Save Item',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom Nav ───────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.grid_view_rounded, 'DASHBOARD'),
      (Icons.receipt_long_rounded, 'ORDERS'),
      (Icons.local_offer_outlined, 'OFFERS'),
      (Icons.person_rounded, 'PROFILE'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = _selectedNavIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedNavIndex = i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].$1,
                        size: 22,
                        color: active ? AppColors.orange : AppColors.textMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          color:
                              active ? AppColors.orange : AppColors.textMuted,
                          fontSize: 9,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
      padding:
          padded ? const EdgeInsets.symmetric(horizontal: 20) : EdgeInsets.zero,
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
              color: AppColors.textMuted.withOpacity(0.8), fontSize: 13),
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

// ─── Mini Toggle Widget ───────────────────────────────────────────────────────
class _MiniToggle extends StatelessWidget {
  final bool value;
  const _MiniToggle({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 34,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: value ? AppColors.textWhite : AppColors.textMuted,
        border: value ? Border.all(color: AppColors.border) : null,
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: value ? 17 : 2,
            top: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? AppColors.orange : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
