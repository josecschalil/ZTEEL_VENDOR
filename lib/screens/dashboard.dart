import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/app_colors.dart';
import 'categoryItemsScreen.dart';
part 'dashboard_all_categories.dart';

// ── Data models ─────────────────────────────────────────────────────────────
class MenuItem {
  final String imageUrl;
  final String name;
  final String price;
  const MenuItem(this.imageUrl, this.name, this.price);
}

class MenuCategory {
  final String name;
  final int itemCount;
  final List<MenuItem> items;
  const MenuCategory(this.name, this.itemCount, this.items);
}

const _initialCategories = [
  MenuCategory('Signature Starters', 12, [
    MenuItem(
      'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300',
      'Crispy Saffron Samosas',
      '\$12.50',
    ),
    MenuItem(
      'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=300',
      'Tandoori Paneer Tikka',
      '\$14.00',
    ),
  ]),
  MenuCategory('Main Entrées', 18, [
    MenuItem(
      'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=300',
      'Velvet Butter Chicken',
      '\$22.00',
    ),
    MenuItem(
      'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=300',
      'Royal Lamb Biryani',
      '\$26.50',
    ),
  ]),
  MenuCategory('Desserts', 8, [
    MenuItem(
      'https://images.unsplash.com/photo-1470124182917-cc6e71b22ecc?w=300',
      'Saffron Crème Brûlée',
      '\$9.50',
    ),
    MenuItem(
      'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=300',
      'Kulfi Rose Sundae',
      '\$8.00',
    ),
  ]),
];
const _bars = [0.38, 0.52, 0.44, 0.60, 0.48, 1.0];
const _barLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// ── Widget ───────────────────────────────────────────────────────────────────
class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard>
    with TickerProviderStateMixin {
  final TextEditingController _categoryNameController = TextEditingController();
  final List<MenuCategory> _categories = List.of(_initialCategories);

  // ── Entry stagger ────────────────────────────────
  late final AnimationController _entryAc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  // ── Live status pulse ────────────────────────────
  late final AnimationController _pulseAc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  // ── Bar chart fill ───────────────────────────────
  late final AnimationController _barAc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  // ── Helpers ──────────────────────────────────────
  Animation<double> _fade(int i) => CurvedAnimation(
        parent: _entryAc,
        curve: Interval(
          (i * 0.08).clamp(0.0, 0.9),
          (0.55 + i * 0.08).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      );

  Animation<Offset> _slide(int i) =>
      Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryAc,
          curve: Interval(
            (i * 0.08).clamp(0.0, 0.9),
            (0.55 + i * 0.08).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );

  Widget _reveal(int i, Widget child) => FadeTransition(
        opacity: _fade(i),
        child: SlideTransition(position: _slide(i), child: child),
      );

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _formattedDate {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _entryAc.dispose();
    _pulseAc.dispose();
    _barAc.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: true,
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
                      const SizedBox(height: 28),
                      _reveal(
                          2,
                          _buildSectionHeader(
                            title: 'Overview',
                            subtitle: "Today's performance snapshot",
                            badge: 'LIVE',
                          )),
                      const SizedBox(height: 14),
                      _reveal(2, _buildStatsGrid()),
                      const SizedBox(height: 32),
                      _reveal(3, _buildMenuSectionHeader()),
                      const SizedBox(height: 16),
                      ..._categories.asMap().entries.map(
                            (e) =>
                                _reveal(4 + e.key, _buildCategoryCard(e.value)),
                          ),
                      const SizedBox(height: 32),
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

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Brand avatar ──
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF5A4C), Color(0xFFE87722)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: AppColors.textWhite, size: 22),
          ),
          const SizedBox(width: 11),
          // ── Brand name ──
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Zteeel Vendor',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          // ── OPEN pill with pulse ──
          AnimatedBuilder(
            animation: _pulseAc,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.greenDim,
                border: Border.all(color: AppColors.greenBorder, width: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.green
                          .withValues(alpha: 0.5 + 0.5 * _pulseAc.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green
                              .withValues(alpha: 0.45 * _pulseAc.value),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'OPEN',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── Notification icon with badge ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  border: Border.all(color: AppColors.border, width: 0.8),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.textSecondary, size: 19),
              ),
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Hero banner ──────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      height: 172,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Decorative ring geometry ──
          Positioned(
            right: -55,
            top: -55,
            child: _ring(210, 0.09),
          ),
          Positioned(
            right: -15,
            top: -15,
            child: _ring(135, 0.1),
          ),
          Positioned(
            right: 32,
            top: 32,
            child: _ring(55, 0.12),
          ),
          // ── Soft blob ──
          Positioned(
            right: 20,
            bottom: 30,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.textWhite.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 56,
            bottom: 18,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textWhite.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // ── Content ──
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textWhite.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.textWhite.withValues(alpha: 0.22),
                          width: 0.6),
                    ),
                    child: const Text(
                      'DASHBOARD',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Greeting
                  Text(
                    '$_greeting, Chef',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Date + revenue row
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: AppColors.textWhite.withValues(alpha: 0.7),
                          size: 11),
                      const SizedBox(width: 5),
                      Text(
                        _formattedDate,
                        style: TextStyle(
                          color: AppColors.textWhite.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Mini revenue pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.textWhite.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.textWhite.withValues(alpha: 0.18),
                              width: 0.6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.trending_up_rounded,
                                color:
                                    AppColors.textWhite.withValues(alpha: 0.9),
                                size: 13),
                            const SizedBox(width: 5),
                            Text(
                              '\$1,482 today',
                              style: TextStyle(
                                color:
                                    AppColors.textWhite.withValues(alpha: 0.95),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.textWhite.withValues(alpha: opacity), width: 1),
        ),
      );

  // ── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orangeDim,
                border: Border.all(color: AppColors.orangeBorder, width: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Stats grid ────────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildRevenueCard(),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatChip(
                    label: 'Active Orders',
                    value: '14',
                    sub: 'in progress',
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatChip(
                    label: 'New Reviews',
                    value: '8',
                    sub: 'this week',
                    icon: Icons.star_rounded,
                    accentColor: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.attach_money_rounded,
                    color: AppColors.textWhite, size: 18),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Today',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'compared to yesterday',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.greenBorder, width: 0.5),
                ),
                child: const Text(
                  '+12.4%',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Revenue number ──
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$1,482',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 5, left: 3),
                child: Text(
                  '.50',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'collected',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Animated bar chart ──
          AnimatedBuilder(
            animation: _barAc,
            builder: (_, __) => SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _bars.asMap().entries.map((e) {
                  final isActive = e.value == 1.0;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      height: 44 * e.value * _barAc.value,
                      decoration: BoxDecoration(
                        color:
                            isActive ? AppColors.orange : AppColors.orangeDim,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Day labels ──
          Row(
            children: _barLabels.map((d) {
              return Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accentColor, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            sub,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu section header ───────────────────────────────────────────────────
  Widget _buildMenuSectionHeader() {
    final totalItems = _categories.fold(0, (s, c) => s + c.itemCount);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menu Categories',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_categories.length} categories · $totalItems items',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openAllCategoriesPage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.orangeDim,
                border: Border.all(color: AppColors.orangeBorder, width: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.orange, size: 9.5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _openAllCategoriesPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllCategoriesScreen(
          categories: List.of(_categories),
          onAddCategory: _openCreateCategoryModal,
        ),
      ),
    );
  }

  // ── Create category modal ─────────────────────────────────────────────────
  void _openCreateCategoryModal() {
    _categoryNameController.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 44,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Gradient header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.orangeTint, AppColors.bg],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF5A4C), Color(0xFFF07B6F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.category_rounded,
                                color: AppColors.textWhite, size: 21),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Category',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Organize your menu offerings',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Input + CTA ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category Name',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 14),
                              child: Icon(Icons.label_outline_rounded,
                                  color: AppColors.orange, size: 18),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _categoryNameController,
                                autofocus: true,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                cursorColor: AppColors.orange,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Signature Starters',
                                  hintStyle: TextStyle(
                                      color: AppColors.textMuted, fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                ),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _createCategory(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Gradient CTA button
                      GestureDetector(
                        onTap: _createCategory,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF5A4C), Color(0xFFF07B6F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded,
                                  color: AppColors.textWhite, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Create Category',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createCategory() {
    final name = _categoryNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _categories.insert(0, MenuCategory(name, 0, const []));
    });
    Navigator.of(context).pop();
  }

// ── Category card ─────────────────────────────────────────────────────────
  Widget _buildCategoryCard(MenuCategory cat) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left gradient accent strip ──
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEF5A4C), Color(0xFFF07B6F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    // ── Category header (Prominent 16px Bold) ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
                      color: AppColors.surfaceRaised,
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.orangeTint,
                              border: Border.all(
                                  color: AppColors.orangeBorder, width: 0.8),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu_rounded,
                              color: AppColors.orange,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.orangeDim,
                              border: Border.all(
                                  color: AppColors.orangeBorder, width: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${cat.itemCount} items',
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Divider ──
                    Container(height: 0.8, color: AppColors.border),
                    // ── Item rows ──
                    ...cat.items.asMap().entries.map((e) {
                      final isLast = e.key == cat.items.length - 1;
                      return _buildItemRow(e.value, isLast: isLast);
                    }),
                    // ── Show more footer ──
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryItemsScreen(
                            categoryName: cat.name,
                            totalItems: cat.itemCount,
                          ),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: const BoxDecoration(
                          border: Border(
                            top:
                                BorderSide(color: AppColors.border, width: 0.8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Show All Items',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.orange, size: 17),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Item row (Clean secondary hierarchy: 13.5px Medium item name, 12.5px Bold orange price) ──
  Widget _buildItemRow(MenuItem item, {required bool isLast}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              color: AppColors.surfaceRaised,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceRaised,
                    child: const Center(
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.orange,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.price,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.edit_outlined,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
