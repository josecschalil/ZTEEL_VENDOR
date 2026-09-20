import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArtisanTrattoApp extends StatelessWidget {
  const ArtisanTrattoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artisan Trattoria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
      ),
      home: const KitchenDashboard(),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class MenuCategory {
  final IconData icon;
  final String label;
  final int count;
  const MenuCategory(
      {required this.icon, required this.label, required this.count});
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

// ─── Main Dashboard Screen ────────────────────────────────────────────────────

class KitchenDashboard extends StatefulWidget {
  const KitchenDashboard({super.key});

  @override
  State<KitchenDashboard> createState() => _KitchenDashboardState();
}

class _KitchenDashboardState extends State<KitchenDashboard> {
  int _selectedNavIndex = 0;

  static const List<MenuCategory> _categories = [
    MenuCategory(icon: Icons.local_pizza_outlined, label: 'Pizza', count: 14),
    MenuCategory(icon: Icons.restaurant_outlined, label: 'Pasta', count: 10),
    MenuCategory(icon: Icons.lunch_dining_outlined, label: 'Burgers', count: 8),
    MenuCategory(icon: Icons.eco_outlined, label: 'Salads', count: 6),
    MenuCategory(icon: Icons.cake_outlined, label: 'Desserts', count: 9),
    MenuCategory(icon: Icons.coffee_outlined, label: 'Drinks', count: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _HeroCard(),
                const SizedBox(height: 16),
                _QuickActionsBar(),
                const SizedBox(height: 20),
                _MajorCategoriesSection(categories: _categories),
                const SizedBox(height: 20),
                _LatestOrdersSection(orders: _orders),
                const SizedBox(height: 120), // bottom nav clearance
              ],
            ),
          ),
          // Bottom navigation (pinned)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomNav(
              selectedIndex: _selectedNavIndex,
              onTap: (i) => setState(() => _selectedNavIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: topPadding + 20,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Column(
        children: [
          _HeroHeader(),
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
                border: Border.all(color: const Color(0xFF334155), width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCJFaKH2gw6QTTTf7UQJaJ6dWTW8bKkZDbrqQIP8UKXo4Yy6Z1lDi8lshjutI674H-xwyCrUpvrwv5WHrUt7cDSjcea9QPspaLdD-dq7jg390lJzD6FLgPekAulmMiEev8BjYymGjocIdnP5gK6MQLQk-R54NZpujjY5WLzQrupWVkdOufzyzs_fckJPbZwpK8B7zwa2kei7529jCzrESInxs7WiAWboj1mQJ0RcoB070a6cnvoWDVYig',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, color: Colors.white54),
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
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0F172A), width: 2),
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
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                'Chef Marco · Artisan Trattoria',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
              onTap: () {},
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(Icons.notifications_outlined,
                    size: 18, color: Colors.white.withOpacity(0.9)),
              ),
            ),
            Positioned(
              top: 9,
              right: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFF0F172A), width: 1.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Today's Revenue",
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: const Color(0xFF34D399).withOpacity(0.3)),
            ),
            child: const Text(
              '+18.4%',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6EE7B7)),
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
        color: Colors.white,
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
        _PulsingDot(color: const Color(0xFF34D399)),
        const SizedBox(width: 6),
        Text(
          'Kitchen Live · Open Orders',
          style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              icon: Icons.receipt_outlined,
              iconBg: Colors.white.withOpacity(0.1),
              iconColor: Colors.white,
              label: 'LIVE ORDERS',
              value: '18 Tickets',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              icon: null,
              iconBg: const Color(0xFF10B981).withOpacity(0.2),
              iconColor: const Color(0xFF10B981),
              label: 'AVG PREP',
              value: '14.2m',
              valueColor: const Color(0xFF6EE7B7),
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 0.8,
                  ),
                ),
                if (subtitle == null)
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? Colors.white,
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
                          color: valueColor ?? Colors.white,
                        ),
                      ),
                      Text(
                        subtitle!,
                        style: TextStyle(
                            fontSize: 10, color: Colors.white.withOpacity(0.6)),
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
  static const List<_QuickAction> _actions = [
    _QuickAction(icon: Icons.menu_book_outlined, label: 'Menu'),
    _QuickAction(icon: Icons.assignment_turned_in_outlined, label: 'Orders'),
    _QuickAction(icon: Icons.chat_bubble_outline, label: 'Reviews'),
    _QuickAction(icon: Icons.star_outline, label: 'Ratings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _actions
            .map((a) => Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: _actions.indexOf(a) == 0 ? 0 : 5),
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
  const _QuickAction({required this.icon, required this.label});
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(action.icon, size: 17, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
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
  const _MajorCategoriesSection({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _SectionHeader(title: 'Major Categories', onSeeAll: () {}),
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
            itemCount: categories.length,
            itemBuilder: (_, i) => _CategoryCard(category: categories[i]),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final MenuCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.8)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 2,
                      offset: Offset(0, 1)),
                ],
              ),
              child:
                  Icon(category.icon, size: 20, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              '${category.count} items',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8)),
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
  const _LatestOrdersSection({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _SectionHeader(title: 'Latest Orders', onSeeAll: () {}),
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
        return const Color(0xFF10B981).withOpacity(0.08);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get _iconColor {
    switch (order.statusType) {
      case OrderStatus.ready:
        return const Color(0xFF059669);
      default:
        return const Color(0xFF475569);
    }
  }

  Color get _borderColor {
    switch (order.statusType) {
      case OrderStatus.ready:
        return const Color(0xFFD1FAE5).withOpacity(0.6);
      default:
        return const Color(0xFFE2E8F0).withOpacity(0.8);
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
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
                    ? const Color(0xFFD1FAE5).withOpacity(0.6)
                    : const Color(0xFFE2E8F0),
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
                          color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· ${order.platform}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  order.description,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569)),
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
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                '${order.itemCount} items',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8)),
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
        return const Color(0xFFF59E0B);
      case OrderStatus.ready:
        return const Color(0xFF10B981);
      case OrderStatus.completed:
        return const Color(0xFF94A3B8);
    }
  }

  Color get _textColor {
    switch (order.statusType) {
      case OrderStatus.cooking:
        return const Color(0xFF92400E);
      case OrderStatus.ready:
        return const Color(0xFF065F46);
      case OrderStatus.completed:
        return const Color(0xFF64748B);
    }
  }

  Color get _bgColor {
    switch (order.statusType) {
      case OrderStatus.cooking:
        return const Color(0xFFFFFBEB);
      case OrderStatus.ready:
        return const Color(0xFFECFDF5);
      case OrderStatus.completed:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get _borderColor {
    switch (order.statusType) {
      case OrderStatus.cooking:
        return const Color(0xFFE2E8F0);
      case OrderStatus.ready:
        return const Color(0xFFD1FAE5);
      case OrderStatus.completed:
        return const Color(0xFFE2E8F0).withOpacity(0.6);
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
                fontSize: 10, fontWeight: FontWeight.w600, color: _textColor),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomPadding),
      decoration: const BoxDecoration(
        color: Color(0xF5FFFFFF),
        border: Border(top: BorderSide(color: Color(0x14E2E8F0))),
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              isActive: selectedIndex == 0,
              onTap: () => onTap(0)),
          _NavItem(
              icon: Icons.kitchen,
              label: 'Kitchen',
              isActive: selectedIndex == 1,
              onTap: () => onTap(1)),
          // Center scan button
          GestureDetector(
            onTap: () {},
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 12,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner_outlined,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          _NavItem(
              icon: Icons.bar_chart_outlined,
              label: 'Reports',
              isActive: selectedIndex == 3,
              onTap: () => onTap(3)),
          _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              isActive: selectedIndex == 4,
              onTap: () => onTap(4)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 3),
              Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                      color: Color(0xFF0F172A), shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
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
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3),
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
                  color: Colors.grey.shade600),
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
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
          decoration:
              BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// The chef hat icon isn't in default Icons, so we provide a workaround:
extension on Icons {
  static const IconData chef_hat =
      IconData(0xe53d, fontFamily: 'MaterialIcons');
}
