import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/screens/orderDetailScreen.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/services/shop_status_service.dart';

// ─── Color tokens (mirrors profile_edit_screen.dart _Dt) ─────────────────────
class _C {
  static const bg = Color(0xFFF8FAFC); // slate-50
  static const surface = Colors.white;
  static const surfaceRaised = Color(0xFFF1F5F9); // slate-100
  static const dark = Color(0xFF0F172A); // slate-900
  static const border = Color(0xFFE2E8F0); // slate-200
  static const textPrimary = Color(0xFF0F172A); // slate-900
  static const textSecondary = Color(0xFF64748B); // slate-500
  static const emerald = Color(0xFF10B981); // emerald-500
  static const emeraldBg = Color(0xFFECFDF5); // emerald-50
  static const red = Color(0xFFEF4444);
  static const transparent = Colors.transparent;
}



class OrdersScreen extends StatefulWidget {
  final int initialTabIndex;
  const OrdersScreen({super.key, this.initialTabIndex = 0});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;
  late int _selectedTab;

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _redemptions = [];
  String _vendorName = '';
  String? _vendorIconUrl;
  Timer? _poller;

  final _shopStatus = ShopStatusService.instance;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _pageController = PageController(initialPage: widget.initialTabIndex);
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
    _startPolling();
    _shopStatus.ensureLoaded();
  }

  void _switchToTab(int index) {
    if (index >= 0 && index < 3 && mounted) {
      setState(() => _selectedTab = index);
      _tabController.animateTo(index);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (!mounted) return;
      _fetchData(silent: true);
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent && _redemptions.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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
        _redemptions = list;
        _isLoading = false;
        _errorMessage = null;
      });
    } else if (_redemptions.isEmpty) {
      setState(() {
        _errorMessage = 'Failed to load orders. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmOrder(String qrCode) async {
    if (qrCode.isEmpty) return;
    final res = await VendorService.scanVendorRedemption(qrCode);
    if (!mounted) return;

    final orderNum = _formatOrderNumber({'qr_code': qrCode});

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order $orderNum marked as completed!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _C.dark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      await _fetchData(silent: true);
      _switchToTab(1);
    } else {
      // If mock/dummy order, update status locally
      final idx = _redemptions.indexWhere((r) => r['qr_code'] == qrCode);
      if (idx != -1) {
        setState(() {
          _redemptions[idx]['status'] = 'confirmed';
          _redemptions[idx]['confirmed_at'] = DateTime.now().toIso8601String();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order $orderNum marked as completed!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _C.dark,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
        _switchToTab(1);
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

  bool _isExpiredSession(Map<String, dynamic> r) {
    final status = (r['status'] ?? '').toString().toLowerCase();
    if (status == 'expired' || status == 'cancelled') return true;
    if (status == 'pending') {
      final expiresAtStr = r['expires_at']?.toString();
      if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
        final exp = DateTime.tryParse(expiresAtStr);
        if (exp != null && exp.isBefore(DateTime.now())) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isPendingSession(Map<String, dynamic> r) {
    final status = (r['status'] ?? '').toString().toLowerCase();
    if (status != 'pending') return false;
    return !_isExpiredSession(r);
  }

  bool _isCompletedSession(Map<String, dynamic> r) {
    final status = (r['status'] ?? '').toString().toLowerCase();
    return status == 'confirmed' ||
        status == 'completed' ||
        status == 'delivered';
  }

  List<dynamic> get _pendingOrders => _redemptions
      .where((r) => _isPendingSession(r as Map<String, dynamic>))
      .toList();

  List<dynamic> get _completedOrders => _redemptions
      .where((r) => _isCompletedSession(r as Map<String, dynamic>))
      .toList();

  List<dynamic> get _expiredOrders => _redemptions
      .where((r) => _isExpiredSession(r as Map<String, dynamic>))
      .toList();

  String _formatOrderNumber(Map<String, dynamic> session) {
    final rawOrderNum = session['order_number']?.toString();
    if (rawOrderNum != null && rawOrderNum.isNotEmpty) {
      return rawOrderNum.startsWith('#') ? rawOrderNum : '#$rawOrderNum';
    }
    final qrCode = session['qr_code']?.toString() ?? '';
    if (qrCode.isNotEmpty) {
      final clean = qrCode.replaceAll('-', '').toUpperCase();
      final code = clean.length >= 8 ? clean.substring(0, 8) : clean;
      return '#$code';
    }
    return '#C571267D';
  }

  Future<void> _openSessionDetails(Map<String, dynamic> session) async {
    final qrCode = session['qr_code']?.toString() ?? '';
    final orderIdStr = _formatOrderNumber(session);

    final customerName = session['customer_name']?.toString() ?? '';
    final status = (session['status'] ?? 'pending').toString().toLowerCase();

    final finalTotal = session['final_total']?.toString() ??
        session['subtotal']?.toString() ??
        '0.00';
    final subtotal = session['subtotal']?.toString() ?? '0.00';
    final discount = session['total_discount']?.toString() ?? '0.00';

    final reward = session['reward'] as Map<String, dynamic>?;
    final hasReward = reward != null &&
        (reward['name_snapshot'] != null ||
            reward['gift_item_name_snapshot'] != null ||
            reward['discount_amount'] != null);
    String milestoneMsg = 'No milestone reward applied for this order.';
    if (hasReward) {
      final rName = reward['name_snapshot']?.toString() ?? 'Milestone Reward';
      final rDisc = reward['discount_amount']?.toString();
      final giftName = reward['gift_item_name_snapshot']?.toString();
      if (giftName != null && giftName.isNotEmpty) {
        milestoneMsg = '$rName (Free item: $giftName)';
      } else if (rDisc != null &&
          double.tryParse(rDisc) != null &&
          double.tryParse(rDisc)! > 0) {
        milestoneMsg = '$rName (Saved ₹$rDisc)';
      } else {
        milestoneMsg = rName;
      }
    }

    final offersList = (session['applied_offers'] as List<dynamic>?) ?? [];
    final offersSummaryStr = offersList.isNotEmpty
        ? 'Offers applied: ${offersList.map((o) {
            final title = o['title_snapshot']?.toString() ?? 'Offer';
            final dAmount = o['discount_amount']?.toString();
            if (dAmount != null &&
                double.tryParse(dAmount) != null &&
                double.tryParse(dAmount)! > 0) {
              return '$title (Saved ₹$dAmount)';
            }
            return title;
          }).join(', ')}'
        : '[No Offers Applied]';

    final rawItems = (session['items'] as List<dynamic>?) ?? [];
    List<OrderLineItem> mappedItems = [];
    if (rawItems.isEmpty) {
      mappedItems.add(OrderLineItem(
        name: 'Order Item',
        note: '',
        quantity: 'x1',
        imageUrl: '',
        unitPrice: '₹$finalTotal',
        lineTotal: '₹$finalTotal',
        appliedOffer: offersList.isNotEmpty
            ? offersList.first['title_snapshot']?.toString()
            : null,
      ));
    } else {
      mappedItems = rawItems.map((item) {
        final iMap = item as Map<String, dynamic>;
        final iName = iMap['item_name_snapshot']?.toString() ?? '';
        final nameStr = iName.isNotEmpty ? iName : 'Item';

        final components = iMap['components'] as List<dynamic>?;
        String noteStr = '';
        if (components != null && components.isNotEmpty) {
          final compList = components
              .map((c) =>
                  '${c['quantity'] ?? 1}x ${c['item_name_snapshot'] ?? ''}')
              .join(', ');
          noteStr = 'Includes: $compList';
        } else if (iMap['is_reward_item'] == true) {
          noteStr = '🎁 Free Milestone Reward';
        }

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

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: orderIdStr,
          qrCode: qrCode,
          status: status,
          customerName: customerName.isNotEmpty ? customerName : null,
          totalAmount: '₹$finalTotal',
          subtotalAmount: '₹$subtotal',
          savingsAmount: '-₹$discount',
          offersSummary: offersSummaryStr,
          milestoneUnlocked: hasReward,
          milestoneMessage: milestoneMsg,
          items: mappedItems,
          onOrderCompleted: () {
            _fetchData(silent: true);
            _switchToTab(1);
          },
        ),
      ),
    );
    await _fetchData(silent: true);
    if (result == true && mounted) {
      _switchToTab(1);
    }
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
                      _vendorName.isNotEmpty ? _vendorName : 'ZTEEL Vendor',
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
                        color: _C.red.withValues(alpha: 0.1),
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
    final isQrMissing = qrCode.isEmpty && session['order_number'] == null;
    final orderIdStr =
        isQrMissing ? '[Missing Order QR]' : _formatOrderNumber(session);

    final status = (session['status'] ?? '').toString().toLowerCase();
    final isConfirmed = status == 'confirmed';
    final isExpired = status == 'expired';

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (session['customer_name'] != null &&
                          session['customer_name']
                              .toString()
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          session['customer_name'].toString().trim(),
                          style: const TextStyle(
                            color: _C.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
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
                        color: _C.red.withValues(alpha: 0.12),
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
            const Divider(color: _C.border, thickness: 1),
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
                        color: _C.emerald,
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
                else if (!isConfirmed && isExpired)
                  GestureDetector(
                    onTap: () => _confirmOrder(qrCode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD97706)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Complete Expired',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                          : _C.red.withValues(alpha: 0.1),
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
    final unitPrice = item['unit_price_snapshot']?.toString() ?? '';

    final components = item['components'] as List<dynamic>?;
    final isReward = item['is_reward_item'] == true;

    Widget subtitleWidget;
    if (isReward) {
      subtitleWidget = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_giftcard_rounded, size: 12, color: _C.emerald),
          SizedBox(width: 4),
          Text(
            'Free Milestone Reward',
            style: TextStyle(
              color: _C.emerald,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (components != null && components.isNotEmpty) {
      final compStr = components
          .map((c) => '${c['quantity'] ?? 1}x ${c['item_name_snapshot'] ?? ''}')
          .join(', ');
      subtitleWidget = Row(
        children: [
          const Icon(Icons.layers_outlined, size: 12, color: _C.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Combo: $compStr',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _C.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    } else if (unitPrice.isNotEmpty && double.tryParse(unitPrice) != null) {
      final uPriceVal = double.parse(unitPrice).toStringAsFixed(2);
      subtitleWidget = Row(
        children: [
          Text(
            '₹$uPriceVal each',
            style: const TextStyle(
              color: _C.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      subtitleWidget = const Text(
        'Standard item',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _C.textSecondary,
          fontSize: 11,
        ),
      );
    }

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
                color:
                    isImgMissing ? _C.border.withValues(alpha: 0.5) : _C.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: isImgMissing
                  ? const Icon(Icons.restaurant_rounded,
                      color: _C.textSecondary, size: 24)
                  : Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _C.border.withValues(alpha: 0.5),
                        child: const Icon(Icons.restaurant_rounded,
                            color: _C.textSecondary, size: 24),
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
                  isNameMissing ? 'Menu Item' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isNameMissing ? _C.textSecondary : _C.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                subtitleWidget,
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
