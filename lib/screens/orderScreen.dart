import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/app_colors.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/screens/orderDetailScreen.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/services/shop_status_service.dart';
import 'package:frontend/widgets/app_top_bar.dart';

// ─── Color tokens (mirrors profile_edit_screen.dart _Dt) ─────────────────────
class _C {
  static const bg = Color(0xFFF8FAFC); // slate-50
  static const surface = Colors.white;
  static const surfaceRaised = Color(0xFFF1F5F9); // slate-100
  static const dark = Color(0xFF0F172A); // slate-900
  static const border = Color(0xFFE2E8F0); // slate-200
  static const textPrimary = Color(0xFF0F172A); // slate-900
  static const textSecondary = Color(0xFF64748B); // slate-500
  static const textMuted = Color(0xFF94A3B8); // slate-400
  static const emerald = Color(0xFF10B981); // emerald-500
  static const emeraldLight = Color(0xFF6EE7B7); // emerald-300
  static const emeraldBg = Color(0xFFECFDF5); // emerald-50
  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFEF2F2);
  static const transparent = Colors.transparent;
}

// ─── Sample Dummy Orders (Pending, Completed, Expired) ───────────────────────
final List<Map<String, dynamic>> kDummyOrders = [
  // 1. Pending Order
  {
    'id': '7b8f9e21-4d1a-4f5c-8b1a-9a8b7c6d5e4f',
    'qr_code': 'ORD-942810',
    'status': 'pending',
    'customer_name': 'Rahul Sharma',
    'vendor_name': 'Artisan Trattoria',
    'subtotal': '650.00',
    'item_discount': '130.00',
    'eligible_subtotal': '650.00',
    'milestone_discount': '0.00',
    'total_discount': '130.00',
    'final_total': '520.00',
    'created_at': '2026-09-20T21:55:00Z',
    'expires_at': '2026-09-20T22:25:00Z',
    'confirmed_at': null,
    'items': [
      {
        'id': 'item-101',
        'menu_item_id': 'mi-001',
        'item_name_snapshot': 'Paneer Tikka Platter',
        'unit_price_snapshot': '280.00',
        'quantity': 1,
        'line_subtotal': '280.00',
        'line_discount': '56.00',
        'line_total': '224.00',
        'is_reward_item': false,
        'image':
            'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=500&auto=format&fit=crop&q=80',
        'components': [
          {
            'item_name_snapshot': 'Mint Chutney & Salad',
            'quantity': 1,
          }
        ],
      },
      {
        'id': 'item-102',
        'menu_item_id': 'mi-002',
        'item_name_snapshot': 'Butter Naan',
        'unit_price_snapshot': '45.00',
        'quantity': 2,
        'line_subtotal': '90.00',
        'line_discount': '18.00',
        'line_total': '72.00',
        'is_reward_item': false,
        'image':
            'https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?w=500&auto=format&fit=crop&q=80',
        'components': [],
      },
      {
        'id': 'item-103',
        'menu_item_id': 'mi-003',
        'item_name_snapshot': 'Dal Makhani Special',
        'unit_price_snapshot': '280.00',
        'quantity': 1,
        'line_subtotal': '280.00',
        'line_discount': '56.00',
        'line_total': '224.00',
        'is_reward_item': false,
        'image':
            'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500&auto=format&fit=crop&q=80',
        'components': [],
      },
    ],
    'applied_offers': [
      {
        'id': 'offer-apply-01',
        'offer_id': 'off-001',
        'title_snapshot': '20% OFF Special Dinner',
        'scope_type_snapshot': 'all_menu',
        'percentage_snapshot': 20.0,
        'maximum_discount_snapshot': 200.0,
        'qualifying_subtotal': '650.00',
        'discount_amount': '130.00',
      }
    ],
  },

  // 2. Completed Order
  {
    'id': '3c9d8e72-1b2f-4a3d-9c8b-7a6b5c4d3e2f',
    'qr_code': 'ORD-618402',
    'status': 'confirmed',
    'customer_name': 'Ananya Nair',
    'vendor_name': 'Artisan Trattoria',
    'subtotal': '890.00',
    'item_discount': '222.50',
    'eligible_subtotal': '890.00',
    'milestone_discount': '50.00',
    'total_discount': '272.50',
    'final_total': '617.50',
    'created_at': '2026-09-20T19:15:00Z',
    'expires_at': '2026-09-20T19:45:00Z',
    'confirmed_at': '2026-09-20T19:28:14Z',
    'items': [
      {
        'id': 'item-201',
        'menu_item_id': 'mi-004',
        'item_name_snapshot': 'Classic Chicken Biryani',
        'unit_price_snapshot': '320.00',
        'quantity': 2,
        'line_subtotal': '640.00',
        'line_discount': '160.00',
        'line_total': '480.00',
        'is_reward_item': false,
        'image':
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&auto=format&fit=crop&q=80',
        'components': [
          {
            'item_name_snapshot': 'Raita & Salan',
            'quantity': 2,
          }
        ],
      },
      {
        'id': 'item-202',
        'menu_item_id': 'mi-005',
        'item_name_snapshot': 'Mango Lassi',
        'unit_price_snapshot': '125.00',
        'quantity': 2,
        'line_subtotal': '250.00',
        'line_discount': '62.50',
        'line_total': '187.50',
        'is_reward_item': false,
        'image':
            'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=500&auto=format&fit=crop&q=80',
        'components': [],
      },
    ],
    'applied_offers': [
      {
        'id': 'offer-apply-02',
        'offer_id': 'off-002',
        'title_snapshot': '25% OFF Weekend Feast',
        'scope_type_snapshot': 'all_menu',
        'percentage_snapshot': 25.0,
        'maximum_discount_snapshot': 300.0,
        'qualifying_subtotal': '890.00',
        'discount_amount': '222.50',
      }
    ],
    'reward': {
      'name_snapshot': 'Loyalty Stamp Reward',
      'discount_amount': '50.00',
    },
  },

  // 3. Expired Order
  {
    'id': '1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d',
    'qr_code': 'ORD-305194',
    'status': 'expired',
    'customer_name': 'Karthik Menon',
    'vendor_name': 'Artisan Trattoria',
    'subtotal': '420.00',
    'item_discount': '63.00',
    'eligible_subtotal': '420.00',
    'milestone_discount': '0.00',
    'total_discount': '63.00',
    'final_total': '357.00',
    'created_at': '2026-09-20T17:00:00Z',
    'expires_at': '2026-09-20T17:30:00Z',
    'confirmed_at': null,
    'items': [
      {
        'id': 'item-301',
        'menu_item_id': 'mi-006',
        'item_name_snapshot': 'Crispy Veg Spring Rolls',
        'unit_price_snapshot': '180.00',
        'quantity': 1,
        'line_subtotal': '180.00',
        'line_discount': '27.00',
        'line_total': '153.00',
        'is_reward_item': false,
        'image':
            'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop&q=80',
        'components': [
          {
            'item_name_snapshot': 'Sweet Chili Sauce',
            'quantity': 1,
          }
        ],
      },
      {
        'id': 'item-302',
        'menu_item_id': 'mi-007',
        'item_name_snapshot': 'Cold Coffee with Ice Cream',
        'unit_price_snapshot': '120.00',
        'quantity': 2,
        'line_subtotal': '240.00',
        'line_discount': '36.00',
        'line_total': '204.00',
        'is_reward_item': false,
        'image':
            'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=500&auto=format&fit=crop&q=80',
        'components': [],
      },
    ],
    'applied_offers': [
      {
        'id': 'offer-apply-03',
        'offer_id': 'off-003',
        'title_snapshot': '15% OFF Starters & Beverages',
        'scope_type_snapshot': 'category_set',
        'percentage_snapshot': 15.0,
        'maximum_discount_snapshot': 100.0,
        'qualifying_subtotal': '420.00',
        'discount_amount': '63.00',
      }
    ],
  },
];

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

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _redemptions = [];
  String _vendorName = '';
  String? _vendorIconUrl;

  final _shopStatus = ShopStatusService.instance;

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
    _fetchData();
    _shopStatus.ensureLoaded();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final profileRes = await VendorService.getVendorProfile();
    if (profileRes['success'] == true && profileRes['data'] != null) {
      final pData = profileRes['data'] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _vendorName = pData['business_name']?.toString() ?? '';
          _vendorIconUrl = pData['icon_image']?.toString();
        });
      }
    }

    final redRes = await VendorService.getVendorRedemptions();
    if (!mounted) return;

    if (redRes['success'] == true && redRes['data'] != null) {
      final list = redRes['data'] as List<dynamic>;
      setState(() {
        _redemptions = list.isNotEmpty
            ? list
            : kDummyOrders.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _redemptions =
            kDummyOrders.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmOrder(String qrCode) async {
    if (qrCode.isEmpty) return;
    final res = await VendorService.scanVendorRedemption(qrCode);
    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order $qrCode marked as completed!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _C.dark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _fetchData();
    } else {
      // If mock/dummy order, update status locally
      final idx = _redemptions.indexWhere((r) => r['qr_code'] == qrCode);
      if (idx != -1) {
        setState(() {
          _redemptions[idx]['status'] = 'confirmed';
          _redemptions[idx]['confirmed_at'] =
              DateTime.now().toIso8601String();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order $qrCode marked as completed!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _C.dark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['error'] ?? 'Failed to update order status',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _C.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  List<dynamic> get _pendingOrders => _redemptions
      .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'pending')
      .toList();

  List<dynamic> get _completedOrders => _redemptions
      .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'confirmed')
      .toList();

  List<dynamic> get _expiredOrders => _redemptions
      .where((r) => ['expired', 'cancelled']
          .contains((r['status'] ?? '').toString().toLowerCase()))
      .toList();

  void _openSessionDetails(Map<String, dynamic> session) {
    final qrCode = session['qr_code']?.toString() ?? '';
    final orderIdStr =
        qrCode.isNotEmpty ? 'ORDER #$qrCode' : '[Missing Order ID]';

    final finalTotal = session['final_total']?.toString() ??
        session['subtotal']?.toString() ??
        '0.00';
    final subtotal = session['subtotal']?.toString() ?? '0.00';
    final discount = session['total_discount']?.toString() ?? '0.00';

    final offersList = (session['applied_offers'] as List<dynamic>?) ?? [];
    final offersSummaryStr = offersList.isNotEmpty
        ? 'Offers applied: ' +
            offersList
                .map((o) => o['title_snapshot']?.toString() ?? 'Offer')
                .join(', ')
        : '[No Offers Applied]';

    final rawItems = (session['items'] as List<dynamic>?) ?? [];
    List<OrderLineItem> mappedItems = [];
    if (rawItems.isEmpty) {
      mappedItems.add(const OrderLineItem(
        name: '[Missing Item Name]',
        note: '[No Note / Component]',
        quantity: 'x0',
        imageUrl: '',
        unitPrice: '₹0.00 each',
        lineTotal: '₹0.00',
        appliedOffer: '[No Applied Offer]',
      ));
    } else {
      mappedItems = rawItems.map((item) {
        final iMap = item as Map<String, dynamic>;
        final iName = iMap['item_name_snapshot']?.toString() ?? '';
        final nameStr = iName.isNotEmpty ? iName : '[Missing Item Name]';

        final components = iMap['components'] as List<dynamic>?;
        String noteStr = '';
        if (components != null && components.isNotEmpty) {
          noteStr = components
              .map((c) =>
                  '${c['quantity'] ?? 1}x ${c['item_name_snapshot'] ?? ''}')
              .join(', ');
        }
        if (noteStr.isEmpty) noteStr = '[No Note / Component]';

        final qty = iMap['quantity']?.toString() ?? '1';
        final uPrice = iMap['unit_price_snapshot']?.toString() ?? '0.00';
        final lTotal = iMap['line_total']?.toString() ?? '0.00';
        final imgUrl = ApiConfig.getImageUrl(
                iMap['image']?.toString() ?? iMap['image_url']?.toString()) ??
            '';

        return OrderLineItem(
          name: nameStr,
          note: noteStr,
          quantity: 'x$qty',
          imageUrl: imgUrl,
          unitPrice: '₹$uPrice each',
          lineTotal: '₹$lTotal',
          appliedOffer: offersList.isNotEmpty
              ? offersList.first['title_snapshot']?.toString()
              : null,
        );
      }).toList();
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: orderIdStr,
          totalAmount: '₹$finalTotal',
          subtotalAmount: '₹$subtotal',
          savingsAmount: '-₹$discount',
          offersSummary: offersSummaryStr,
          milestoneUnlocked: false,
          milestoneMessage:
              'Order status: ${(session['status'] ?? '').toString().toUpperCase()}',
          items: mappedItems,
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            // ── Dark rectangular hero top bar ─────────────────────────────────
            ValueListenableBuilder<bool>(
              valueListenable: _shopStatus.status,
              builder: (_, isOpen, __) => _buildHeroTopBar(isOpen: isOpen),
            ),
            // ── Tab Bar ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: _buildTabBar(),
            ),
            // ── Swipeable tab pages ───────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _selectedTab = index);
                  _tabController.animateTo(index);
                },
                children: [
                  _buildTabPage(
                      _pendingOrders, 'No pending orders at the moment.'),
                  _buildTabPage(_completedOrders, 'No completed orders yet.'),
                  _buildTabPage(_expiredOrders, 'No expired orders right now.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dark rectangular hero top bar ────────────────────────────────────────

  Widget _buildHeroTopBar({required bool isOpen}) {
    final topPadding = MediaQuery.of(context).padding.top;
    final avatarUrl = ApiConfig.getImageUrl(_vendorIconUrl);

    return Container(
      decoration: const BoxDecoration(
        color: _C.dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: topPadding + 16,
        left: 20,
        right: 20,
        bottom: 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Avatar + Vendor Info + Notification / Refresh ──
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF334155), width: 2),
                ),
                child: ClipOval(
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _AvatarFallback(),
                        )
                      : const _AvatarFallback(),
                ),
              ),
              const SizedBox(width: 12),
              // Vendor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDER MANAGEMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _vendorName.isNotEmpty ? _vendorName : 'Zteeel Vendor',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Refresh button
              Stack(
                children: [
                  GestureDetector(
                    onTap: _fetchData,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  if (_pendingOrders.isNotEmpty)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _C.emerald,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.dark, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Main Heading: Your Orders & Subtitle ──
          const Text(
            'Your Orders',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Track your culinary journey with us.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab pages ────────────────────────────────────────────────────────────

  Widget _buildTabPage(List<dynamic> sessionList, String emptyMessage) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: _C.dark),
        ),
      );
    }

    return RefreshIndicator(
      color: _C.dark,
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sessionList.isEmpty
              ? [
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _C.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: _C.red, fontSize: 12),
                      ),
                    ),
                  ],
                  _buildEmptyState(emptyMessage),
                ]
              : sessionList
                  .map((session) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildOrderCardFromSession(
                            session as Map<String, dynamic>),
                      ))
                  .toList(),
        ),
      ),
    );
  }

  // ─── Tab bar ─────────────────────────────────────────────────────────────
  // Layout identical to original; only selected color changes orange → dark

  Widget _buildTabBar() {
    const tabs = ['Pending', 'Completed', 'Expired'];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.surfaceRaised, // was AppColors.surface
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
                  color: selected ? _C.dark : _C.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: selected ? Colors.white : _C.textSecondary,
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

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: _C.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Order card ───────────────────────────────────────────────────────────
  // Structure, padding, radii — untouched. Colors only.

  Widget _buildOrderCardFromSession(Map<String, dynamic> session) {
    final qrCode = session['qr_code']?.toString() ?? '';
    final isQrMissing = qrCode.isEmpty;
    final orderIdStr = isQrMissing ? '[Missing Order QR]' : 'ORDER #$qrCode';

    final status = (session['status'] ?? '').toString().toLowerCase();
    final isConfirmed = status == 'confirmed';

    final finalTotal = session['final_total']?.toString() ??
        session['subtotal']?.toString() ??
        '';
    final isTotalMissing = finalTotal.isEmpty;

    final items = (session['items'] as List<dynamic>?) ?? [];
    final isItemsMissing = items.isEmpty;

    final isCardHasMissingData =
        isQrMissing || isTotalMissing || isItemsMissing;

    return GestureDetector(
      onTap: () => _openSessionDetails(session),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCardHasMissingData ? _C.red : _C.border,
            width: isCardHasMissingData ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderIdStr,
                  style: TextStyle(
                    color: isQrMissing ? _C.red : _C.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: () => _openSessionDetails(session),
                  child: const Text(
                    'Show Details',
                    style: TextStyle(
                      color: _C.dark, // was AppColors.orange
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Items list ──────────────────────────────────────────────────
            if (isItemsMissing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _C.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.red),
                      ),
                      child: const Icon(Icons.fastfood_rounded,
                          color: _C.red, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      '[Missing Items Data]',
                      style: TextStyle(
                        color: _C.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...items.map(
                  (item) => _buildSessionItemRow(item as Map<String, dynamic>)),

            const SizedBox(height: 18),
            Divider(color: _C.border, thickness: 1),
            const SizedBox(height: 14),

            // ── Footer row ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Action / status badge
                if (!isConfirmed && status == 'pending')
                  GestureDetector(
                    onTap: () => _confirmOrder(qrCode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _C.emerald, // was AppColors.green
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.emerald),
                      ),
                      child: const Text(
                        'Mark Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isConfirmed
                          ? _C.emeraldBg // was AppColors.surfaceRaised
                          : _C.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isConfirmed ? _C.emerald : _C.red,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: isConfirmed ? _C.emerald : _C.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total amount',
                      style: TextStyle(color: _C.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTotalMissing ? '₹0.00' : '₹$finalTotal',
                      style: TextStyle(
                        color: isTotalMissing
                            ? _C.red
                            : _C.dark, // was AppColors.orange
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

  // ─── Item row ─────────────────────────────────────────────────────────────
  // Untouched except red references use _C.red

  Widget _buildSessionItemRow(Map<String, dynamic> item) {
    final name = item['item_name_snapshot']?.toString() ?? '';
    final isNameMissing = name.isEmpty;

    final imgUrl = ApiConfig.getImageUrl(
        item['image']?.toString() ?? item['image_url']?.toString());
    final isImgMissing = imgUrl == null || imgUrl.isEmpty;

    final qty = item['quantity']?.toString() ?? '1';

    final components = item['components'] as List<dynamic>?;
    String noteStr = '';
    if (components != null && components.isNotEmpty) {
      noteStr = components
          .map((c) => '${c['quantity'] ?? 1}x ${c['item_name_snapshot'] ?? ''}')
          .join(', ');
    }
    final isNoteMissing = noteStr.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isImgMissing ? _C.red.withOpacity(0.12) : _C.border,
                borderRadius: BorderRadius.circular(10),
                border:
                    isImgMissing ? Border.all(color: _C.red, width: 1.2) : null,
              ),
              child: isImgMissing
                  ? const Icon(Icons.restaurant, color: _C.red, size: 24)
                  : Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _C.red.withOpacity(0.12),
                        child: const Icon(Icons.restaurant,
                            color: _C.red, size: 24),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNameMissing ? '[Missing Item Name]' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isNameMissing ? _C.red : _C.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isNoteMissing ? '[No Note / Component]' : noteStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isNoteMissing ? _C.red : _C.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'x$qty',
            style: const TextStyle(
              color: _C.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widget ────────────────────────────────────────────────────────

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Icon(Icons.storefront_rounded,
          color: Color(0xFF475569), size: 24),
    );
  }
}
