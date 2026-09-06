import 'package:flutter/material.dart';
import 'package:frontend/app_colors.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/screens/orderDetailScreen.dart';
import 'package:frontend/services/vendor_service.dart';

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
          content: Text('Order $qrCode marked as completed!'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Failed to update order status'),
          backgroundColor: AppColors.orangeDim,
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
      .where((r) =>
          ['expired', 'cancelled'].contains((r['status'] ?? '').toString().toLowerCase()))
      .toList();

  void _openSessionDetails(Map<String, dynamic> session) {
    final qrCode = session['qr_code']?.toString() ?? '';
    final orderIdStr = qrCode.isNotEmpty ? 'ORDER #$qrCode' : '[Missing Order ID]';

    final finalTotal = session['final_total']?.toString() ?? session['subtotal']?.toString() ?? '0.00';
    final subtotal = session['subtotal']?.toString() ?? '0.00';
    final discount = session['total_discount']?.toString() ?? '0.00';

    final offersList = (session['applied_offers'] as List<dynamic>?) ?? [];
    String offersSummaryStr = '';
    if (offersList.isNotEmpty) {
      offersSummaryStr = 'Offers applied: ' +
          offersList.map((o) => o['title_snapshot']?.toString() ?? 'Offer').join(', ');
    } else {
      offersSummaryStr = '[No Offers Applied]';
    }

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
              .map((c) => '${c['quantity'] ?? 1}x ${c['item_name_snapshot'] ?? ''}')
              .join(', ');
        }
        if (noteStr.isEmpty) noteStr = '[No Note / Component]';

        final qty = iMap['quantity']?.toString() ?? '1';
        final uPrice = iMap['unit_price_snapshot']?.toString() ?? '0.00';
        final lTotal = iMap['line_total']?.toString() ?? '0.00';
        final imgUrl = ApiConfig.getImageUrl(iMap['image']?.toString() ?? iMap['image_url']?.toString()) ?? '';

        return OrderLineItem(
          name: nameStr,
          note: noteStr,
          quantity: 'x$qty',
          imageUrl: imgUrl,
          unitPrice: '₹$uPrice each',
          lineTotal: '₹$lTotal',
          appliedOffer: offersList.isNotEmpty ? offersList.first['title_snapshot']?.toString() : null,
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
          milestoneMessage: 'Order status: ${(session['status'] ?? '').toString().toUpperCase()}',
          items: mappedItems,
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
                  _buildTabPage(_pendingOrders, 'No pending orders at the moment.'),
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

  Widget _buildTabPage(List<dynamic> sessionList, String emptyMessage) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.orange,
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
                        color: AppColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.red, fontSize: 12),
                      ),
                    ),
                  ],
                  _buildEmptyState(emptyMessage),
                ]
              : sessionList.map((session) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildOrderCardFromSession(session as Map<String, dynamic>),
                  );
                }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isVendorNameMissing = _vendorName.isEmpty;
    final iconUrl = ApiConfig.getImageUrl(_vendorIconUrl);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconUrl == null ? AppColors.red.withOpacity(0.15) : AppColors.surfaceWarm,
                border: iconUrl == null ? Border.all(color: AppColors.red) : null,
                image: iconUrl != null
                    ? DecorationImage(
                        image: NetworkImage(iconUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: iconUrl == null
                  ? const Icon(Icons.storefront_rounded, color: AppColors.red, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              isVendorNameMissing ? '[Missing Vendor Name]' : _vendorName,
              style: TextStyle(
                color: isVendorNameMissing ? AppColors.red : AppColors.textPrimary,
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

  Widget _buildOrderCardFromSession(Map<String, dynamic> session) {
    final qrCode = session['qr_code']?.toString() ?? '';
    final isQrMissing = qrCode.isEmpty;
    final orderIdStr = isQrMissing ? '[Missing Order QR]' : 'ORDER #$qrCode';

    final status = (session['status'] ?? '').toString().toLowerCase();
    final isConfirmed = status == 'confirmed';

    final finalTotal = session['final_total']?.toString() ?? session['subtotal']?.toString() ?? '';
    final isTotalMissing = finalTotal.isEmpty;

    final items = (session['items'] as List<dynamic>?) ?? [];
    final isItemsMissing = items.isEmpty;

    final isCardHasMissingData = isQrMissing || isTotalMissing || isItemsMissing;

    return GestureDetector(
      onTap: () => _openSessionDetails(session),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCardHasMissingData ? AppColors.red : AppColors.border,
            width: isCardHasMissingData ? 1.5 : 0.8,
          ),
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
                  orderIdStr,
                  style: TextStyle(
                    color: isQrMissing ? AppColors.red : AppColors.textSecondary,
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
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items list or missing item row
            if (isItemsMissing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.red),
                      ),
                      child: const Icon(Icons.fastfood_rounded, color: AppColors.red, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      '[Missing Items Data]',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...items.map((item) => _buildSessionItemRow(item as Map<String, dynamic>)),

            const SizedBox(height: 18),
            Divider(color: AppColors.border, thickness: 1),
            const SizedBox(height: 14),

            // Footer row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isConfirmed && status == 'pending')
                  GestureDetector(
                    onTap: () => _confirmOrder(qrCode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.green),
                      ),
                      child: const Text(
                        'Mark Completed',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isConfirmed ? AppColors.surfaceRaised : AppColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isConfirmed ? AppColors.green : AppColors.red),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: isConfirmed ? AppColors.green : AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total amount',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTotalMissing ? '₹0.00' : '₹$finalTotal',
                      style: TextStyle(
                        color: isTotalMissing ? AppColors.red : AppColors.orange,
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

  Widget _buildSessionItemRow(Map<String, dynamic> item) {
    final name = item['item_name_snapshot']?.toString() ?? '';
    final isNameMissing = name.isEmpty;

    final imgUrl = ApiConfig.getImageUrl(item['image']?.toString() ?? item['image_url']?.toString());
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
                color: isImgMissing ? AppColors.red.withOpacity(0.12) : AppColors.border,
                borderRadius: BorderRadius.circular(10),
                border: isImgMissing ? Border.all(color: AppColors.red, width: 1.2) : null,
              ),
              child: isImgMissing
                  ? const Icon(Icons.restaurant, color: AppColors.red, size: 24)
                  : Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.red.withOpacity(0.12),
                        child: const Icon(Icons.restaurant, color: AppColors.red, size: 24),
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
                    color: isNameMissing ? AppColors.red : AppColors.textPrimary,
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
                    color: isNoteMissing ? AppColors.red : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'x$qty',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
