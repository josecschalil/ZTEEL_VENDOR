import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/app_colors.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/services/shop_status_service.dart';
import 'package:frontend/widgets/app_top_bar.dart';
import 'categoryItemsScreen.dart';
import 'editFoodItemScreen.dart';
import 'offerScreen.dart';
import 'orderScreen.dart';
part 'dashboard_all_categories.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

class MenuItem {
  final String id;
  final String imageUrl;
  final String name;
  final String price;
  final double rawPrice;
  final String description;
  final bool isVegetarian;
  final bool isAvailable;

  const MenuItem({
    this.id = '',
    required this.imageUrl,
    required this.name,
    required this.price,
    this.rawPrice = 0.0,
    this.description = '',
    this.isVegetarian = false,
    this.isAvailable = true,
  });
}

class MenuCategory {
  final String id;
  final String name;
  final String label;
  final IconData icon;
  final int count;
  final int itemCount;
  final List<MenuItem> items;

  const MenuCategory({
    this.id = '',
    this.name = '',
    this.label = '',
    this.icon = Icons.restaurant_outlined,
    this.count = 0,
    this.itemCount = 0,
    this.items = const [],
  });
}

class OrderItem {
  final String id;
  final String platform;
  final String description;
  final String timeAgo;
  final String status;
  final OrderStatus statusType;
  final double amount;
  final int itemCount;

  const OrderItem({
    required this.id,
    required this.platform,
    required this.description,
    required this.timeAgo,
    required this.status,
    required this.statusType,
    required this.amount,
    required this.itemCount,
  });
}

enum OrderStatus { cooking, ready, completed }

// ─── Main Restaurant Dashboard Screen ────────────────────────────────────────

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  final _shopStatus = ShopStatusService.instance;

  static const List<MenuCategory> _defaultCategories = [
    MenuCategory(
      id: 'default_pizza',
      icon: Icons.local_pizza_outlined,
      label: 'Pizza',
      name: 'Pizza',
      count: 14,
      itemCount: 14,
    ),
    MenuCategory(
      id: 'default_pasta',
      icon: Icons.restaurant_outlined,
      label: 'Pasta',
      name: 'Pasta',
      count: 10,
      itemCount: 10,
    ),
    MenuCategory(
      id: 'default_burgers',
      icon: Icons.lunch_dining_outlined,
      label: 'Burgers',
      name: 'Burgers',
      count: 8,
      itemCount: 8,
    ),
    MenuCategory(
      id: 'default_salads',
      icon: Icons.eco_outlined,
      label: 'Salads',
      name: 'Salads',
      count: 6,
      itemCount: 6,
    ),
    MenuCategory(
      id: 'default_desserts',
      icon: Icons.cake_outlined,
      label: 'Desserts',
      name: 'Desserts',
      count: 9,
      itemCount: 9,
    ),
    MenuCategory(
      id: 'default_drinks',
      icon: Icons.coffee_outlined,
      label: 'Drinks',
      name: 'Drinks',
      count: 16,
      itemCount: 16,
    ),
  ];

  static const List<OrderItem> _orders = [
    OrderItem(
      id: '#FD-4092',
      platform: 'DoorDash',
      description: '2x Margherita Pizza',
      timeAgo: '4m ago',
      status: 'Cooking',
      statusType: OrderStatus.cooking,
      amount: 38.50,
      itemCount: 2,
    ),
    OrderItem(
      id: '#FD-4091',
      platform: 'UberEats',
      description: 'Truffle Pasta Bowl, Tiramisu',
      timeAgo: '12m ago',
      status: 'Ready for Pickup',
      statusType: OrderStatus.ready,
      amount: 24.00,
      itemCount: 2,
    ),
    OrderItem(
      id: '#FD-4089',
      platform: 'Dine-In (T3)',
      description: 'Artisan Burger, Caesar Salad',
      timeAgo: '25m ago',
      status: 'Completed',
      statusType: OrderStatus.completed,
      amount: 42.20,
      itemCount: 3,
    ),
  ];

  List<MenuCategory> _categories = _defaultCategories;

  @override
  void initState() {
    super.initState();
    _shopStatus.ensureLoaded();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final catRes = await VendorService.getMenuCategories();
    if (!mounted) return;

    if (catRes['success'] == true && catRes['data'] != null) {
      final rawList = catRes['data'] as List<dynamic>;
      if (rawList.isNotEmpty) {
        List<MenuCategory> categoryList = [];
        for (final cat in rawList) {
          if (cat is Map<String, dynamic>) {
            final catId = cat['id']?.toString() ?? '';
            final catName = cat['name']?.toString() ?? 'Category';

            final itemRes = await VendorService.getMenuItems(categoryId: catId);
            List<MenuItem> itemList = [];

            if (itemRes['success'] == true && itemRes['data'] != null) {
              final rawItems = itemRes['data'] as List<dynamic>;
              for (final it in rawItems) {
                if (it is Map<String, dynamic>) {
                  final priceNum = it['price'];
                  final rawPrice = (priceNum is num)
                      ? priceNum.toDouble()
                      : double.tryParse(priceNum?.toString() ?? '0') ?? 0.0;
                  final priceStr = '₹${rawPrice.toStringAsFixed(0)}';

                  itemList.add(MenuItem(
                    id: it['id']?.toString() ?? '',
                    name: it['name']?.toString() ?? 'Item',
                    imageUrl:
                        ApiConfig.getImageUrl(it['image']?.toString()) ?? '',
                    price: priceStr,
                    rawPrice: rawPrice,
                    description: it['description']?.toString() ?? '',
                    isVegetarian: it['is_vegetarian'] as bool? ?? false,
                    isAvailable: it['is_available'] as bool? ?? true,
                  ));
                }
              }
            }

            categoryList.add(MenuCategory(
              id: catId,
              name: catName,
              label: catName,
              icon: _getCategoryIcon(catName),
              count: itemList.length,
              itemCount: itemList.length,
              items: itemList,
            ));
          }
        }
        if (mounted && categoryList.isNotEmpty) {
          setState(() {
            _categories = categoryList;
          });
        }
      }
    }
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('pizza')) return Icons.local_pizza_outlined;
    if (lower.contains('pasta') || lower.contains('noodle')) {
      return Icons.restaurant_outlined;
    }
    if (lower.contains('burger') || lower.contains('sandwich')) {
      return Icons.lunch_dining_outlined;
    }
    if (lower.contains('salad') || lower.contains('veg')) {
      return Icons.eco_outlined;
    }
    if (lower.contains('dessert') ||
        lower.contains('cake') ||
        lower.contains('sweet')) {
      return Icons.cake_outlined;
    }
    if (lower.contains('drink') ||
        lower.contains('beverage') ||
        lower.contains('tea') ||
        lower.contains('coffee')) {
      return Icons.coffee_outlined;
    }
    return Icons.restaurant_menu_outlined;
  }

  void _openAllCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllCategoriesScreen(
          categories: _categories,
          onAddCategory: () {},
          onRefreshCategories: _fetchCategories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: RefreshIndicator(
          onRefresh: _fetchCategories,
          color: AppColors.primaryDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              children: [
                _HeroCard(
                  onNotificationTap: () {},
                ),
                const SizedBox(height: 16),
                _QuickActionsBar(
                  onMenuTap: _openAllCategories,
                  onOrdersTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    );
                  },
                  onReviewsTap: () {},
                  onRatingsTap: () {},
                ),
                const SizedBox(height: 20),
                _MajorCategoriesSection(
                  categories: _categories,
                  onSeeAll: _openAllCategories,
                ),
                const SizedBox(height: 20),
                _LatestOrdersSection(
                  orders: _orders,
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final VoidCallback? onNotificationTap;

  const _HeroCard({this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: EdgeInsets.only(
        top: topPadding + 20,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Column(
        children: [
          _HeroHeader(onNotificationTap: onNotificationTap),
          const SizedBox(height: 8),
          _HeroRevenueBadge(),
          const SizedBox(height: 4),
          _HeroRevenueAmount(),
          const SizedBox(height: 4),
          _HeroLiveIndicator(),
          const SizedBox(height: 16),
          _HeroMetricsCapsule(),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final VoidCallback? onNotificationTap;

  const _HeroHeader({this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar with green dot
        Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textSecondary, width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCJFaKH2gw6QTTTf7UQJaJ6dWTW8bKkZDbrqQIP8UKXo4Yy6Z1lDi8lshjutI674H-xwyCrUpvrwv5WHrUt7cDSjcea9QPspaLdD-dq7jg390lJzD6FLgPekAulmMiEev8BjYymGjocIdnP5gK6MQLQk-R54NZpujjY5WLzQrupWVkdOufzyzs_fckJPbZwpK8B7zwa2kei7529jCzrESInxs7WiAWboj1mQJ0RcoB070a6cnvoWDVYig',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, color: AppColors.white54),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkSurface, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white.withValues(alpha: 0.5),
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                'Chef Marco · Artisan Trattoria',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        // Notification button
        Stack(
          children: [
            GestureDetector(
              onTap: onNotificationTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.white.withValues(alpha: 0.1)),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 18,
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            Positioned(
              top: 9,
              right: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.darkSurface, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroRevenueBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 30),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Today's Revenue",
            style: TextStyle(
              fontSize: 11,
              color: AppColors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.successLight.withValues(alpha: 0.3)),
            ),
            child: const Text(
              '+18.4%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.successLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRevenueAmount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      '\$2,142.50',
      style: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
        letterSpacing: -1,
      ),
    );
  }
}

class _HeroLiveIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _PulsingDot(color: AppColors.successLight),
        const SizedBox(width: 6),
        Text(
          'Kitchen Live · Open Orders',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HeroMetricsCapsule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              icon: Icons.receipt_outlined,
              iconBg: AppColors.white.withValues(alpha: 0.1),
              iconColor: AppColors.white,
              label: 'LIVE ORDERS',
              value: '18 Tickets',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              icon: null,
              iconBg: AppColors.success.withValues(alpha: 0.2),
              iconColor: AppColors.success,
              label: 'AVG PREP',
              value: '14.2m',
              valueColor: AppColors.successLight,
              subtitle: '· On Pace',
              isPulse: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData? icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;
  final bool isPulse;

  const _MetricTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.isPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Center(
              child: isPulse
                  ? _PulsingDot(color: iconColor, size: 10)
                  : Icon(icon, size: 16, color: iconColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.8,
                  ),
                ),
                if (subtitle == null)
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? AppColors.white,
                      letterSpacing: -0.3,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: valueColor ?? AppColors.white,
                        ),
                      ),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActionsBar extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onReviewsTap;
  final VoidCallback? onRatingsTap;

  const _QuickActionsBar({
    this.onMenuTap,
    this.onOrdersTap,
    this.onReviewsTap,
    this.onRatingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.menu_book_outlined,
        label: 'Menu',
        onTap: onMenuTap,
      ),
      _QuickAction(
        icon: Icons.assignment_turned_in_outlined,
        label: 'Orders',
        onTap: onOrdersTap,
      ),
      _QuickAction(
        icon: Icons.chat_bubble_outline,
        label: 'Reviews',
        onTap: onReviewsTap,
      ),
      _QuickAction(
        icon: Icons.star_outline,
        label: 'Ratings',
        onTap: onRatingsTap,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: actions
            .map((a) => Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: actions.indexOf(a) == 0 ? 0 : 5),
                    child: _QuickActionButton(action: a),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(action.icon, size: 17, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkSurfaceRaised,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Major Categories ─────────────────────────────────────────────────────────

class _MajorCategoriesSection extends StatelessWidget {
  final List<MenuCategory> categories;
  final VoidCallback? onSeeAll;

  const _MajorCategoriesSection({
    required this.categories,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _SectionHeader(title: 'Major Categories', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length > 6 ? 6 : categories.length,
            itemBuilder: (_, i) => _CategoryCard(
              category: categories[i],
              onTap: () {
                if (categories[i].id.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryItemsScreen(
                        categoryId: categories[i].id,
                        categoryName: categories[i].name,
                      ),
                    ),
                  );
                } else {
                  onSeeAll?.call();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final MenuCategory category;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(category.icon, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.darkSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${category.count} items',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Latest Orders ────────────────────────────────────────────────────────────

class _LatestOrdersSection extends StatelessWidget {
  final List<OrderItem> orders;
  final VoidCallback? onSeeAll;

  const _LatestOrdersSection({
    required this.orders,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _SectionHeader(title: 'Latest Orders', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          ...orders.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OrderCard(order: o),
              )),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;

  const _OrderCard({required this.order});

  Color get _iconBg {
    switch (order.statusType) {
      case OrderStatus.ready:
        return AppColors.success.withValues(alpha: 0.08);
      default:
        return AppColors.surfaceRaised;
    }
  }

  Color get _iconColor {
    switch (order.statusType) {
      case OrderStatus.ready:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _borderColor {
    switch (order.statusType) {
      case OrderStatus.ready:
        return AppColors.successTint.withValues(alpha: 0.6);
      default:
        return AppColors.border.withValues(alpha: 0.8);
    }
  }

  IconData get _icon {
    switch (order.statusType) {
      case OrderStatus.ready:
        return Icons.restaurant_outlined;
      case OrderStatus.completed:
        return Icons.lunch_dining_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: order.statusType == OrderStatus.ready
                    ? AppColors.successTint.withValues(alpha: 0.6)
                    : AppColors.border,
              ),
            ),
            child: Icon(_icon, size: 18, color: _iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· ${order.platform}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  order.description,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                _StatusBadge(order: order),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${order.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${order.itemCount} items',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderItem order;

  const _StatusBadge({required this.order});

  Color get _dotColor {
    switch (order.statusType) {
      case OrderStatus.cooking:
        return AppColors.warning;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.completed:
        return AppColors.textMuted;
    }
  }

  Color get _textColor {
    switch (order.statusType) {
      case OrderStatus.cooking:
        return AppColors.warning;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.completed:
        return AppColors.textSecondary;
    }
  }

  Color get _bgColor {
    switch (order.statusType) {
      case OrderStatus.cooking:
        return AppColors.warningTint;
      case OrderStatus.ready:
        return AppColors.successTint;
      case OrderStatus.completed:
        return AppColors.surfaceRaised;
    }
  }

  Color get _borderColor {
    switch (order.statusType) {
      case OrderStatus.cooking:
        return AppColors.border;
      case OrderStatus.ready:
        return AppColors.successTint;
      case OrderStatus.completed:
        return AppColors.border.withValues(alpha: 0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _borderColor),
          ),
          child: Text(
            '${order.timeAgo} · ${order.status}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.darkSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              'See All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.iconMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingDot({required this.color, this.size = 8});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
