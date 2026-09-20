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
      setState(() {
        _redemptions = redRes['data'] as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = redRes['error']?.toString() ?? 'Failed to load orders';
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
