import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Color Palette (shared with SetupShopScreen) ──────────────────
class SBColors {
  static const bg = Color(0xFF160D00);
  static const surface = Color(0xFF231508);
  static const surfaceElevated = Color(0xFF2C1A08);
  static const saffron = Color(0xFFE8622A);
  static const saffronLight = Color(0xFFF07340);
  static const saffronDim = Color(0x33E8622A);
  static const gold = Color(0xFFD4A85A);
  static const textPrimary = Color(0xFFF5EDD8);
  static const textSecondary = Color(0xFF9B7E60);
  static const textMuted = Color(0xFF5C3E28);
  static const border = Color(0xFF3A2010);
  static const borderAccent = Color(0xFF6B3A18);
  static const vegGreen = Color(0xFF3DBE6E);
  static const danger = Color(0xFFE84848);
}

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
      backgroundColor: SBColors.bg,
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
                    _buildPriceField(),
                    const SizedBox(height: 20),
                    _buildCategoryDropdown(),
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
            _buildBottomNav(),
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
          color: SBColors.bg,
          border: Border(
            bottom: BorderSide(color: SBColors.border, width: 0.5),
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
                  colors: [Color(0xFF4DD9C0), Color(0xFF3B8BEB)],
                ),
              ),
              child: const Center(
                child: Text(
                  'Sto',
                  style: TextStyle(
                    color: Colors.white,
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
                color: SBColors.textPrimary,
                fontSize: 16,
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
                    color: SBColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SBColors.border),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: SBColors.saffron,
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
                      color: SBColors.saffron,
                      shape: BoxShape.circle,
                      border: Border.all(color: SBColors.bg, width: 1.5),
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
                color: SBColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SBColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: SBColors.textSecondary,
                size: 16,
              ),
            ),
          ),
          const Text(
            'Edit Food Item',
            style: TextStyle(
              color: SBColors.textPrimary,
              fontSize: 22,
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
              ? SBColors.saffron.withOpacity(0.12)
              : SBColors.surfaceElevated,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isAvailable
                ? SBColors.saffron.withOpacity(0.5)
                : SBColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AVAILABLE',
              style: TextStyle(
                color: _isAvailable ? SBColors.saffron : SBColors.textSecondary,
                fontSize: 10,
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
                color: SBColors.surfaceElevated,
                border: Border.all(color: SBColors.border),
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
                            Color(0xFF3A2008),
                            Color(0xFF1A0C02),
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
                              color: SBColors.saffron.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: SBColors.saffron.withOpacity(0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: SBColors.saffron,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to change main photo',
                            style: TextStyle(
                              color: SBColors.textSecondary,
                              fontSize: 12.5,
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
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
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
          color: SBColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SBColors.borderAccent.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: SBColors.textSecondary, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: SBColors.textSecondary,
                fontSize: 10,
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
              color: SBColors.saffron,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Category Dropdown ───────────────────────────────────────────
  Widget _buildCategoryDropdown() {
    return _labeledField(
      label: 'CATEGORY',
      child: Container(
        decoration: BoxDecoration(
          color: SBColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SBColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCategory,
            dropdownColor: const Color(0xFF2C1A08),
            iconEnabledColor: SBColors.saffron,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            style: const TextStyle(
              color: SBColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
            items: _categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
        ),
      ),
    );
  }

  // ─── Dietary Toggle ──────────────────────────────────────────────
  Widget _buildDietaryToggle() {
    return _labeledField(
      label: 'DIETARY TYPE',
      child: Row(
        children: [
          Expanded(
              child:
                  _dietBtn(true, Icons.eco_rounded, 'Veg', SBColors.vegGreen)),
          const SizedBox(width: 12),
          Expanded(
            child: _dietBtn(
              false,
              Icons.restaurant_menu_rounded,
              'Non-Veg',
              SBColors.danger,
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
          color: active ? color.withOpacity(0.12) : SBColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color.withOpacity(0.55) : SBColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? color : SBColors.textMuted, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: active ? color : SBColors.textSecondary,
                fontSize: 13.5,
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
          color: SBColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SBColors.border),
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
                      color: SBColors.textPrimary,
                      fontSize: 13.5,
                    ),
                    cursorColor: SBColors.saffron,
                    onSubmitted: _addTag,
                    decoration: InputDecoration(
                      hintText: 'Add tag...',
                      hintStyle: TextStyle(
                        color: SBColors.textMuted,
                        fontSize: 13.5,
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
                      color: SBColors.saffronDim,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: SBColors.saffron,
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
        color: SBColors.saffron,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
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
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 10, color: Colors.white),
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
              colors: [Color(0xFFE8622A), Color(0xFFD44A14)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: SBColors.saffron.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Save Item',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.5,
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
        color: SBColors.surface,
        border: Border(top: BorderSide(color: SBColors.border, width: 0.5)),
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
                        color: active ? SBColors.saffron : SBColors.textMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          color: active ? SBColors.saffron : SBColors.textMuted,
                          fontSize: 9.5,
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
  Widget _labeledField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: SBColors.saffron,
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
        color: SBColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SBColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: SBColors.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        cursorColor: SBColors.saffron,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: SBColors.textMuted.withOpacity(0.8), fontSize: 14),
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
        color: value ? SBColors.saffron : SBColors.textMuted,
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
