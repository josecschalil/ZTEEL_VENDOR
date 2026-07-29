import 'package:flutter/material.dart';
import 'package:frontend/screens/orderDetailScreen.dart';
import 'package:frontend/screens/scan_qr.dart';
import 'package:frontend/app_colors.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;
  int _selectedTab = 0;
  bool _order1Completed = false;
  bool _order2Completed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      _pageController.animateToPage(
        _tabController.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  static const List<OrderLineItem> _order1Items = [
    OrderLineItem(
      name: 'Saffron Infused Risotto',
      note: 'Extra spice, No onions',
      quantity: 'x1',
      imageUrl:
          'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=200',
      unitPrice: '\$22.00 each',
      lineTotal: '\$22.00',
      appliedOffer: '20% OFF Dinner Offer',
    ),
    OrderLineItem(
      name: 'Midnight Spritz',
      note: 'Standard serve',
      quantity: 'x2',
      imageUrl:
          'https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=200',
      unitPrice: '\$9.50 each',
      lineTotal: '\$19.00',
      appliedOffer: 'BOGO Beverage Promo',
    ),
    OrderLineItem(
      name: 'Classic Garlic Bread',
      note: 'Add cheese dip',
      quantity: 'x1',
      imageUrl:
          'https://images.unsplash.com/photo-1573140247632-f8fd74997d5c?w=200',
      unitPrice: '\$7.50 each',
      lineTotal: '\$7.50',
    ),
  ];

  static const List<OrderLineItem> _order2Items = [
    OrderLineItem(
      name: 'Bistro Signature Salad',
      note: 'Vegan option',
      quantity: 'x3',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
      unitPrice: '\$12.00 each',
      lineTotal: '\$36.00',
      appliedOffer: '15% OFF Healthy Bowl Offer',
    ),
    OrderLineItem(
      name: 'Herbed Rice Bowl',
      note: 'No mushrooms',
      quantity: 'x1',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?w=200',
      unitPrice: '\$14.00 each',
      lineTotal: '\$14.00',
    ),
    OrderLineItem(
      name: 'Citrus Sparkling Water',
      note: 'No ice',
      quantity: 'x2',
      imageUrl:
          'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=200',
      unitPrice: '\$6.00 each',
      lineTotal: '\$12.00',
      appliedOffer: '2 for \$10 Drink Offer',
    ),
  ];

  void _openOrder1Details() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OrderDetailScreen(
          orderId: 'ORDER #SB-9021',
          totalAmount: '\$48.50',
          subtotalAmount: '\$58.50',
          savingsAmount: '-\$10.00',
          offersSummary:
              'Offers applied: 20% OFF Dinner Offer, BOGO Beverage Promo',
          milestoneUnlocked: true,
          milestoneMessage: 'Guest crossed the \$45 spend milestone.',
          items: _order1Items,
        ),
      ),
    );
  }

  void _openOrder2Details() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OrderDetailScreen(
          orderId: 'ORDER #SB-8842',
          totalAmount: '\$62.00',
          subtotalAmount: '\$72.00',
          savingsAmount: '-\$10.00',
          offersSummary:
              'Offers applied: 15% OFF Healthy Bowl Offer, 2 for \$10 Drink Offer',
          milestoneUnlocked: false,
          milestoneMessage:
              'Spend is \$8 short of the next \$70 milestone reward.',
          items: _order2Items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Sticky header (top bar + title + tab bar) ──────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildTopBar(),
                  const SizedBox(height: 28),
                  _buildPageHeader(),
                  const SizedBox(height: 24),
                  _buildTabBar(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // ── Swipeable tab pages ────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _selectedTab = index);
                  _tabController.animateTo(index);
                },
                children: [
                  _buildTabPage(_pendingPageContent()),
                  _buildTabPage(_completedPageContent()),
                  _buildTabPage(_expiredPageContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Wraps a list of widgets in a scrollable page
  Widget _buildTabPage(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ── Tab content builders ───────────────────────────────────
  List<Widget> _pendingPageContent() {
    final cards = <Widget>[];
    if (!_order1Completed) {
      cards.add(_buildOrderCard1());
      cards.add(const SizedBox(height: 16));
    }
    if (!_order2Completed) {
      cards.add(_buildOrderCard2());
      cards.add(const SizedBox(height: 16));
    }
    if (cards.isEmpty) {
      return [_buildEmptyState('No pending orders at the moment.')];
    }
    if (cards.last is SizedBox) cards.removeLast();
    return cards;
  }

  List<Widget> _completedPageContent() {
    final cards = <Widget>[];
    if (_order1Completed) {
      cards.add(_buildOrderCard1());
      cards.add(const SizedBox(height: 16));
    }
    if (_order2Completed) {
      cards.add(_buildOrderCard2());
      cards.add(const SizedBox(height: 16));
    }
    if (cards.isEmpty) {
      return [_buildEmptyState('No completed orders yet.')];
    }
    if (cards.last is SizedBox) cards.removeLast();
    return cards;
  }

  List<Widget> _expiredPageContent() {
    return [_buildEmptyState('No expired orders right now.')];
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceWarm,
                image: DecorationImage(
                  image: NetworkImage(
                      'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=200'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Saffron Bistro',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.orange,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Orders',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your culinary journey with us.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    const tabs = ['Pending', 'Completed', 'Expired'];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() => _selectedTab = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? AppColors.orange : AppColors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: selected
                        ? const Color.fromARGB(255, 252, 252, 252)
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOrderCard1() {
    return GestureDetector(
      onTap: _openOrder1Details,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ORDER #SB-9021',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: _openOrder1Details,
                  child: const Text(
                    'Show Details',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Item 1
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: AppColors.border,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=200',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.restaurant,
                          color: AppColors.orange, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saffron Infused Risotto',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Extra spice, No onions',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  'x1',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Item 2
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: AppColors.border,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=200',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.local_bar,
                          color: AppColors.orange, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Midnight Spritz',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Standard serve',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  'x2',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: AppColors.border, thickness: 1),
            const SizedBox(height: 14),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _order1Completed = !_order1Completed),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _order1Completed
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : AppColors.green,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _order1Completed ? 'Mark Pending' : 'Mark Completed',
                      style: TextStyle(
                        color: _order1Completed
                            ? AppColors.orange
                            : const Color.fromARGB(255, 255, 255, 255),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total amount',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '\$48.50',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard2() {
    return GestureDetector(
      onTap: _openOrder2Details,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ORDER #SB-8842',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: _openOrder2Details,
                  child: const Text(
                    'Show Details',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Item
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: AppColors.border,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.eco,
                          color: AppColors.orange, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bistro Signature Salad',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Vegan option',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  'x3',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: AppColors.border,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1544025162-d76694265947?w=200',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.rice_bowl,
                          color: AppColors.orange, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Herbed Rice Bowl',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'No mushrooms',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'x1',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: AppColors.border, thickness: 1),
            const SizedBox(height: 14),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _order2Completed = !_order2Completed),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _order2Completed
                          ? AppColors.surfaceWarm
                          : AppColors.green,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _order2Completed ? 'Mark Pending' : 'Mark Completed',
                      style: TextStyle(
                        color: _order2Completed
                            ? AppColors.orange
                            : const Color.fromARGB(255, 254, 254, 254),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total amount',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '\$62.00',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
