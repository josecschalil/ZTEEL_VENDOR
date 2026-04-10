import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'categoryItemsScreen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';

part 'dashboard_all_categories.dart';

// ── Design tokens ──────────────────────────────
const _bg = Color(0xFF1A0E0A);
const _surface = Color(0xFF251510);
const _surfaceRaised = Color(0xFF2D1A10);
const _orange = Color(0xFFE8622A);
const _orangeDim = Color(0x29E8622A);
const _orangeBorder = Color(0x40E8622A);
const _white = Color(0xFFFFFFFF);
const _grey1 = Color(0xFF9E7E72);
const _grey2 = Color(0xFF3A2015);
const _grey3 = Color(0xFF2A1810);
const _green = Color(0xFF4ade80);
const _greenDim = Color(0x1A4ade80);
const _greenBorder = Color(0x404ade80);

// ── Data models ────────────────────────────────
class MenuItem {
  final String emoji;
  final String name;
  final String price;
  const MenuItem(this.emoji, this.name, this.price);
}

class MenuCategory {
  final String name;
  final int itemCount;
  final List<MenuItem> items;
  const MenuCategory(this.name, this.itemCount, this.items);
}

const _initialCategories = [
  MenuCategory('Signature Starters', 12, [
    MenuItem('🥟', 'Crispy Saffron Samosas', '\$12.50'),
    MenuItem('🍢', 'Tandoori Paneer Tikka', '\$14.00'),
  ]),
  MenuCategory('Main Entrées', 18, [
    MenuItem('🍛', 'Velvet Butter Chicken', '\$22.00'),
    MenuItem('🍚', 'Royal Lamb Biryani', '\$26.50'),
  ]),
  MenuCategory('Desserts', 8, [
    MenuItem('🍮', 'Saffron Crème Brûlée', '\$9.50'),
    MenuItem('🍨', 'Kulfi Rose Sundae', '\$8.00'),
  ]),
];

const _bars = [0.38, 0.52, 0.44, 0.60, 0.48, 1.0];

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard>
    with TickerProviderStateMixin {
  final TextEditingController _categoryNameController = TextEditingController();
  final List<MenuCategory> _categories = List.of(_initialCategories);

  late final AnimationController _entryAc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  Animation<double> _fade(int i) => CurvedAnimation(
        parent: _entryAc,
        curve: Interval(i * 0.08, 0.6 + i * 0.07, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(int i) =>
      Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryAc,
          curve: Interval(i * 0.08, 0.6 + i * 0.07, curve: Curves.easeOutCubic),
        ),
      );

  Widget _reveal(int i, Widget child) => FadeTransition(
        opacity: _fade(i),
        child: SlideTransition(position: _slide(i), child: child),
      );

  @override
  void dispose() {
    _categoryNameController.dispose();
    _entryAc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        // ── FAB: Scaffold handles positioning above the bottom nav ──
        floatingActionButton: FadeTransition(
          opacity: _fade(4),
          child: GestureDetector(
            onTap: _openCreateCategoryModal,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        // ── Bottom nav: Scaffold.bottomNavigationBar stays fixed ──
        bottomNavigationBar:
            const VendorBottomNav(currentTab: VendorTab.dashboard),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _reveal(0, _buildTopBar()),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _reveal(1, _buildHero()),
                      const SizedBox(height: 24),
                      _reveal(2, _buildSectionLabel('Overview')),
                      const SizedBox(height: 12),
                      _reveal(2, _buildStatsGrid()),
                      const SizedBox(height: 28),
                      _reveal(3, _buildMenuSection()),
                      const SizedBox(height: 24),
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

  // ── Top bar ───────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(
          bottom: BorderSide(color: Color(0x0FFFFFFF), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _orangeBorder, width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: _orange, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Saffron Bistro',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: _white),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _greenDim,
              border: Border.all(color: _greenBorder, width: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: _green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('OPEN',
                    style: TextStyle(
                        color: _green,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _grey3,
              border: Border.all(color: _grey2, width: 0.5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: _grey1, size: 17),
          ),
        ],
      ),
    );
  }

  // ── Hero banner ───────────────────────────────
  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      height: 150,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _grey2, width: 0.5),
      ),
      child: Stack(
        children: [
          // Decorative concentric circles (clipped by parent)
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _orangeBorder, width: 0.5),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _orangeBorder, width: 0.5),
              ),
            ),
          ),
          Positioned(
            right: 25,
            top: 25,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _orangeBorder, width: 0.5),
              ),
            ),
          ),
          // Text content pinned to bottom-left
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: _orangeBorder, width: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DASHBOARD',
                      style: TextStyle(
                          color: _orange,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome back, Chef',
                    style: TextStyle(
                      color: _white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Thursday, 10 April 2026',
                    style: TextStyle(color: _grey1, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: _grey1,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  // ── Stats grid ────────────────────────────────
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        // Makes both columns the same height naturally
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Revenue card ──
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1A0F),
                  border: Border.all(color: _orangeBorder, width: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Revenue today',
                            style: TextStyle(color: _grey1, fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _greenDim,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('+12.4%',
                              style: TextStyle(
                                  color: _green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('\$1,482',
                        style: TextStyle(
                            color: _orange,
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5)),
                    const Text('.50 collected',
                        style: TextStyle(color: _grey1, fontSize: 11)),
                    const Spacer(),
                    // Bar chart pinned to bottom of card
                    SizedBox(
                      height: 48,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _bars.map((h) {
                          final isActive = h == 1.0;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 48 * h,
                              decoration: BoxDecoration(
                                color: isActive ? _orange : _orangeDim,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ── Active orders + Reviews stacked ──
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _buildSmallStat(
                      label: 'Active orders',
                      value: '14',
                      sub: 'in progress',
                      icon: Icons.receipt_long_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildSmallStat(
                      label: 'New reviews',
                      value: '8',
                      sub: 'this week',
                      icon: Icons.star_border_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _grey2, width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: _grey1, fontSize: 11)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _orangeDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _orangeBorder, width: 0.5),
                ),
                child: Icon(icon, color: _orange, size: 14),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: _white,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5)),
              Text(sub, style: const TextStyle(color: _grey1, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Menu section ──────────────────────────────
  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Menu categories',
                      style: TextStyle(
                          color: _white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 3),
                  Text('Manage your culinary offerings',
                      style: TextStyle(color: _grey1, fontSize: 12)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _openAllCategoriesPage,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('VIEW ALL',
                      style: TextStyle(
                          color: _orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._categories.map((cat) => _buildCategoryCard(cat)),
      ],
    );
  }

  void _openAllCategoriesPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllCategoriesScreen(categories: List.of(_categories)),
      ),
    );
  }

  void _openCreateCategoryModal() {
    _categoryNameController.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _grey2, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _grey3,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Create new category',
                    style: TextStyle(
                      color: _white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add a new category to organize your menu.',
                    style: TextStyle(color: _grey1, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _grey2, width: 0.5),
                    ),
                    child: TextField(
                      controller: _categoryNameController,
                      autofocus: true,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: _orange,
                      decoration: const InputDecoration(
                        hintText: 'Category name',
                        hintStyle: TextStyle(color: _grey1, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _createCategory(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _createCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Create new category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _createCategory() {
    final categoryName = _categoryNameController.text.trim();
    if (categoryName.isEmpty) return;

    setState(() {
      _categories.insert(0, MenuCategory(categoryName, 0, const []));
    });

    Navigator.of(context).pop();
  }

  Widget _buildCategoryCard(MenuCategory cat) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _grey2, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      // ClipRRect so child backgrounds don't bleed outside rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            // ── Category header — warmer, darker background ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: const Color(0xFF1E1208),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _orangeDim,
                      border: Border.all(color: _orangeBorder, width: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant_menu_rounded,
                        color: _orange, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _orangeDim,
                      border: Border.all(color: _orangeBorder, width: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cat.itemCount} items',
                      style: const TextStyle(
                          color: _orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // ── Hard divider between header and items ──
            Container(height: 0.5, color: Color(0xFF3A2015)),

            // ── Item rows on surface background ──
            ...cat.items.asMap().entries.map((e) {
              final isLast = e.key == cat.items.length - 1;
              return _buildItemRow(e.value, isLast: isLast);
            }),

            // ── Show more ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: Color(0xFF3A2015), width: 0.5)),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryItemsScreen(
                          categoryName: 'Signature Starters',
                          totalItems: 12,
                        ),
                      ));
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text(
                  'SHOW MORE',
                  style: TextStyle(
                    color: _grey1,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(MenuItem item, {required bool isLast}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _surface,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFF3A2015), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _surfaceRaised,
              border: Border.all(color: _grey2, width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        color: _white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(item.price,
                    style: const TextStyle(color: _grey1, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _surfaceRaised,
              border: Border.all(color: _grey2, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.edit_outlined, color: _grey1, size: 14),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────
}
