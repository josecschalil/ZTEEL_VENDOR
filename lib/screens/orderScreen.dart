import 'package:flutter/material.dart';
import 'package:frontend/screens/orderDetailScreen.dart';
import 'package:frontend/screens/scan_qr.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedTab = 0; // 0=Pending, 1=Completed, 2=Expired
  bool _order1Completed = false;
  bool _order2Completed = false;

  static const Color bgDark = Color(0xFF1A0E0A);
  static const Color cardBg = Color(0xFF251510);
  static const Color orange = Color(0xFFE8622A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9E7E72);

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
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
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
                      ..._buildOrderCardsForSelectedTab(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildScanQRButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
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
                color: Color(0xFF3D1F10),
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
                color: textWhite,
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
            color: const Color(0xFF2A1810),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: orange,
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
            color: textWhite,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your culinary journey with us.',
          style: TextStyle(
            color: textGrey,
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
        color: const Color(0xFF251510),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: selected ? textWhite : textGrey,
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

  List<Widget> _buildOrderCardsForSelectedTab() {
    if (_selectedTab == 2) {
      return [
        _buildEmptyState('No expired orders right now.'),
      ];
    }

    final showCompleted = _selectedTab == 1;
    final cards = <Widget>[];

    if (_order1Completed == showCompleted) {
      cards.add(_buildOrderCard1());
      cards.add(const SizedBox(height: 16));
    }

    if (_order2Completed == showCompleted) {
      cards.add(_buildOrderCard2());
      cards.add(const SizedBox(height: 16));
    }

    if (cards.isEmpty) {
      return [
        _buildEmptyState(
          showCompleted
              ? 'No completed orders yet.'
              : 'No pending orders at the moment.',
        )
      ];
    }

    cards.removeLast();
    return cards;
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3A2015)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: textGrey,
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
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
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
                  color: textGrey,
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
                    color: orange,
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
                  color: const Color(0xFF3A2015),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=200',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.restaurant, color: orange, size: 24),
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
                        color: textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Extra spice, No onions',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                'x1',
                style: TextStyle(
                  color: textGrey,
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
                  color: const Color(0xFF3A2015),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=200',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.local_bar, color: orange, size: 24),
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
                        color: textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Standard serve',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                'x2',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: const Color(0xFF3A2015), thickness: 1),
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
                        ? const Color(0xFF3D1F10)
                        : const Color(0xFF1F3A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3A2015)),
                  ),
                  child: Text(
                    _order1Completed ? 'Mark Pending' : 'Mark Completed',
                    style: TextStyle(
                      color:
                          _order1Completed ? orange : const Color(0xFF4CAF6E),
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
                    style: TextStyle(color: textGrey, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '\$48.50',
                    style: TextStyle(
                      color: orange,
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
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
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
                  color: textGrey,
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
                    color: orange,
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
                  color: const Color(0xFF3A2015),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.eco, color: orange, size: 24),
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
                        color: textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Vegan option',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                'x3',
                style: TextStyle(
                  color: textGrey,
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
                  color: const Color(0xFF3A2015),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1544025162-d76694265947?w=200',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.rice_bowl, color: orange, size: 24),
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
                        color: textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'No mushrooms',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                'x1',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: const Color(0xFF3A2015), thickness: 1),
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
                        ? const Color(0xFF3D1F10)
                        : const Color(0xFF1F3A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3A2015)),
                  ),
                  child: Text(
                    _order2Completed ? 'Mark Pending' : 'Mark Completed',
                    style: TextStyle(
                      color:
                          _order2Completed ? orange : const Color(0xFF4CAF6E),
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
                    style: TextStyle(color: textGrey, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '\$62.00',
                    style: TextStyle(
                      color: orange,
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

  Widget _buildScanQRButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 48),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const QRScannerScreen()));
        },
        backgroundColor: orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.qr_code_scanner, color: textWhite, size: 20),
        label: const Text(
          'Scan QR',
          style: TextStyle(
            color: textWhite,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
