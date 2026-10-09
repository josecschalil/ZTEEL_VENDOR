import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/app_typography.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/services/realtime_order_service.dart';
import 'package:frontend/services/shop_status_service.dart';
import 'package:frontend/services/vendor_cache_service.dart';
import 'categoryItemsScreen.dart';
import 'orderScreen.dart';
import 'orderDetailScreen.dart';
import 'NotificationScreen.dart';
import '../services/vendor_notification_service.dart';
import 'reviewsScreen.dart';
import 'performanceAnalysisScreen.dart';
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
  final String imageUrl;

  const MenuCategory({
    this.id = '',
    required this.name,
    this.label = '',
    this.icon = Icons.restaurant_outlined,
    this.count = 0,
    this.itemCount = 0,
    this.items = const [],
    this.imageUrl = '',
  });
}

class OrderItem {
  final String id;
  final String rawQrCode;
  final String platform;
  final String description;
  final String timeAgo;
  final String status;
  final OrderStatus statusType;
  final double amount;
  final int itemCount;
  final String imageUrl;
  final Map<String, dynamic> rawSession;

  const OrderItem({
    required this.id,
    this.rawQrCode = '',
    required this.platform,
    required this.description,
    required this.timeAgo,
    required this.status,
    required this.statusType,
    required this.amount,
    required this.itemCount,
    this.imageUrl = '',
    this.rawSession = const {},
  });
}

enum OrderStatus { pending, completed, expired }

// ─── Main Restaurant Dashboard Screen ────────────────────────────────────────

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  final _shopStatus = ShopStatusService.instance;

  String _vendorName = 'Vendor Partner';
  String _vendorCategory = 'ZTEEL Partner';
  String? _vendorAvatarUrl;

  List<MenuCategory> _categories = [];
  bool _isLoadingCategories = true;
  String? _categoryError;

  List<OrderItem> _orders = [];
  bool _isLoadingOrders = true;
  String? _orderError;

  double _todayRevenue = 0.0;
  int _pendingCount = 0;
  StreamSubscription<VendorOrderEvent>? _realtimeSubscription;
  bool _cacheRefreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _shopStatus.ensureLoaded();
    _fetchDashboardData();
    _realtimeSubscription = VendorOrderRealtimeService.instance.events.listen(
      (_) => _fetchOrders(silent: true, forceRefresh: true),
    );
    VendorCacheService.revision.addListener(_onCacheRevision);
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    VendorCacheService.revision.removeListener(_onCacheRevision);
    super.dispose();
  }

  bool _isFetching = false;

  void _onCacheRevision() {
    if (_cacheRefreshScheduled) return;
    _cacheRefreshScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      _cacheRefreshScheduled = false;
      if (mounted) _fetchDashboardData(silent: true);
    });
  }

  Future<void> _fetchDashboardData({
    bool silent = false,
    bool isBackgroundPoll = false,
    bool forceRefresh = false,
  }) async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      if (isBackgroundPoll) {
        // Only fetch fast-changing data during rapid polling
        await _fetchOrders(silent: silent, forceRefresh: forceRefresh);
      } else {
        await Future.wait([
          _fetchVendorProfile(silent: silent, forceRefresh: forceRefresh),
          _fetchCategories(silent: silent, forceRefresh: forceRefresh),
          _fetchOrders(silent: silent, forceRefresh: forceRefresh),
        ]);
      }
    } finally {
      if (mounted) _isFetching = false;
    }
  }

  Future<void> _fetchVendorProfile(
      {bool silent = false, bool forceRefresh = false}) async {
    final profileRes =
        await VendorService.getVendorProfile(forceRefresh: forceRefresh);
    if (!mounted) return;
    if (profileRes['success'] == true && profileRes['data'] != null) {
      final pData = profileRes['data'] as Map<String, dynamic>;
      setState(() {
        _vendorName =
            pData['business_name']?.toString().trim() ?? 'Vendor Partner';
        _vendorCategory =
            pData['category']?.toString().trim() ?? 'ZTEEL Partner';
        _vendorAvatarUrl = pData['icon_image']?.toString();
      });
    }
  }

  Future<void> _fetchCategories(
      {bool silent = false, bool forceRefresh = false}) async {
    if (!silent && _categories.isEmpty) {
      setState(() {
        _isLoadingCategories = true;
        _categoryError = null;
      });
    }

    final catRes =
        await VendorService.getMenuCategories(forceRefresh: forceRefresh);
    if (!mounted) return;

    if (catRes['success'] == true && catRes['data'] != null) {
      final rawList = catRes['data'] as List<dynamic>;
      final allItemsRes =
          await VendorService.getMenuItems(forceRefresh: forceRefresh);
      if (!mounted) return;
      final allItems =
          allItemsRes['success'] == true && allItemsRes['data'] is List
              ? allItemsRes['data'] as List<dynamic>
              : const <dynamic>[];
      List<MenuCategory> categoryList = [];

      for (final cat in rawList) {
        if (cat is Map<String, dynamic>) {
          final catId = cat['id']?.toString() ?? '';
          final catName = cat['name']?.toString() ?? 'Category';

          List<MenuItem> itemList = [];

          for (final it in allItems) {
            if (it is Map &&
                it['category']?.toString() != catId &&
                (it['category'] is! Map ||
                    (it['category'] as Map)['id']?.toString() != catId)) {
              continue;
            }
            if (it is Map<String, dynamic>) {
              final priceNum = it['price'];
              final rawPrice = (priceNum is num)
                  ? priceNum.toDouble()
                  : double.tryParse(priceNum?.toString() ?? '0') ?? 0.0;
              final priceStr = '₹${rawPrice.toStringAsFixed(0)}';

              itemList.add(MenuItem(
                id: it['id']?.toString() ?? '',
                name: it['name']?.toString() ?? 'Item',
                imageUrl: ApiConfig.getImageUrl(it['image']?.toString()) ?? '',
                price: priceStr,
                rawPrice: rawPrice,
                description: it['description']?.toString() ?? '',
                isVegetarian: it['is_vegetarian'] as bool? ?? false,
                isAvailable: it['is_available'] as bool? ?? true,
              ));
            }
          }

          String categoryImg = '';
          for (final it in itemList) {
            if (it.imageUrl.trim().isNotEmpty) {
              categoryImg = it.imageUrl.trim();
              break;
            }
          }
          if (categoryImg.isEmpty && cat['image'] != null) {
            categoryImg = ApiConfig.getImageUrl(cat['image']?.toString()) ?? '';
          }

          categoryList.add(MenuCategory(
            id: catId,
            name: catName,
            label: catName,
            icon: _getCategoryIcon(catName),
            count: itemList.length,
            itemCount: itemList.length,
            items: itemList,
            imageUrl: categoryImg,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _categories = categoryList;
          _isLoadingCategories = false;
          _categoryError = null;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _categoryError = catRes['error']?.toString();
        });
      }
    }
  }

  Future<void> _fetchOrders(
      {bool silent = false, bool forceRefresh = false}) async {
    if (!silent && _orders.isEmpty) {
      setState(() {
        _isLoadingOrders = true;
        _orderError = null;
      });
    }

    final redRes =
        await VendorService.getVendorRedemptions(forceRefresh: forceRefresh);
    if (!mounted) return;

    if (redRes['success'] == true && redRes['data'] != null) {
      final list = redRes['data'] as List<dynamic>;

      List<OrderItem> parsedOrders = [];
      double totalRev = 0.0;
      int pending = 0;

      for (final r in list) {
        if (r is Map<String, dynamic>) {
          final id = _formatOrderNumber(r);
          final qrCode = r['qr_code']?.toString() ?? '';
          final statusType = _parseStatusType(r);
          final statusText = _statusLabel(statusType);
          final amount = _parseOrderAmount(r);
          final itemCount = _parseItemCount(r);
          final desc = _formatOrderDescription(r);
          final imageUrl = _firstOrderItemImage(r);
          final timeAgo = _formatTimeAgo(
              r['created_at']?.toString() ?? r['confirmed_at']?.toString());
          final customerName = r['customer_name']?.toString();
          final platform =
              (customerName != null && customerName.trim().isNotEmpty)
                  ? customerName.trim()
                  : 'ZTEEL Order';

          bool isToday = false;
          final dateStr =
              r['confirmed_at']?.toString() ?? r['created_at']?.toString();
          if (dateStr != null) {
            final parsedDate = DateTime.tryParse(dateStr)?.toLocal();
            if (parsedDate != null) {
              final now = DateTime.now();
              isToday = parsedDate.year == now.year &&
                  parsedDate.month == now.month &&
                  parsedDate.day == now.day;
            }
          }

          if (statusType == OrderStatus.completed && isToday) {
            totalRev += amount;
          } else if (statusType == OrderStatus.pending) {
            pending++;
          }

          parsedOrders.add(OrderItem(
            id: id,
            rawQrCode: qrCode,
            platform: platform,
            description: desc,
            timeAgo: timeAgo,
            status: statusText,
            statusType: statusType,
            amount: amount,
            itemCount: itemCount,
            imageUrl: imageUrl,
            rawSession: r,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _orders = parsedOrders;
          _todayRevenue = totalRev;
          _pendingCount = pending;
          _isLoadingOrders = false;
          _orderError = null;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
          _orderError = redRes['error']?.toString();
        });
      }
    }
  }

  String _formatOrderNumber(Map<String, dynamic> session) {
    final rawOrderNum = session['order_number']?.toString();
    if (rawOrderNum != null && rawOrderNum.isNotEmpty) {
      return rawOrderNum.startsWith('#') ? rawOrderNum : '#$rawOrderNum';
    }
    final qrCode = session['qr_code']?.toString() ?? '';
    if (qrCode.isNotEmpty) {
      final clean = qrCode.replaceAll('-', '').toUpperCase();
      return '#$clean';
    }
    return '#UNKNOWN';
  }

  OrderStatus _parseStatusType(Map<String, dynamic> session) {
    final status = (session['status'] ?? 'pending').toString().toLowerCase();
    if (status == 'confirmed' ||
        status == 'completed' ||
        status == 'delivered') {
      return OrderStatus.completed;
    }
    if (status == 'expired' || status == 'cancelled' || status == 'rejected') {
      return OrderStatus.expired;
    }
    final expiresAt = session['expires_at']?.toString();
    if (expiresAt != null && expiresAt.isNotEmpty) {
      final exp = DateTime.tryParse(expiresAt);
      if (exp != null && exp.isBefore(DateTime.now())) {
        return OrderStatus.expired;
      }
    }
    return OrderStatus.pending;
  }

  String _statusLabel(OrderStatus type) {
    switch (type) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.expired:
        return 'Expired';
    }
  }

  double _parseOrderAmount(Map<String, dynamic> session) {
    final finalTotal = session['final_total'] ?? session['subtotal'];
    if (finalTotal is num) return finalTotal.toDouble();
    return double.tryParse(finalTotal?.toString() ?? '0.0') ?? 0.0;
  }

  int _parseItemCount(Map<String, dynamic> session) {
    final items = (session['items'] as List<dynamic>?) ?? [];
    int count = 0;
    for (final it in items) {
      if (it is Map<String, dynamic>) {
        count += int.tryParse(it['quantity']?.toString() ?? '1') ?? 1;
      }
    }
    return count > 0 ? count : 1;
  }

  String _firstOrderItemImage(Map<String, dynamic> session) {
    final items = session['items'] as List<dynamic>? ?? const [];
    for (final item in items) {
      if (item is! Map) continue;
      final rawImage = item['image']?.toString() ??
          item['image_url']?.toString() ??
          '';
      final imageUrl = ApiConfig.getImageUrl(rawImage);
      if (imageUrl != null && imageUrl.isNotEmpty) return imageUrl;
    }
    return '';
  }

  String _formatOrderDescription(Map<String, dynamic> session) {
    final items = (session['items'] as List<dynamic>?) ?? [];
    if (items.isEmpty) {
      final reward = session['reward'] as Map<String, dynamic>?;
      final giftName = reward?['gift_item_name_snapshot']?.toString();
      if (giftName != null && giftName.isNotEmpty) {
        return 'Free Reward: $giftName';
      }
      return 'Redemption Order';
    }
    final names = <String>[];
    for (final it in items) {
      if (it is Map<String, dynamic>) {
        final qty = it['quantity']?.toString() ?? '1';
        final name = it['item_name_snapshot']?.toString() ??
            it['name']?.toString() ??
            'Dish';
        names.add('${qty}x $name');
      }
    }
    return names.join(', ');
  }

  String _formatTimeAgo(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return 'Recently';
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

  void _openAllCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllCategoriesScreen(
          categories: _categories,
          onRefreshCategories: () => _fetchCategories(silent: true),
        ),
      ),
    );
    if (mounted) {
      _fetchCategories(silent: true);
    }
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
      mappedItems.add(const OrderLineItem(
        name: 'Order Items',
        note: '',
        quantity: 'x1',
        imageUrl: '',
        unitPrice: '₹0.00 each',
        lineTotal: '₹0.00',
        appliedOffer: null,
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
            _fetchDashboardData(silent: true);
          },
        ),
      ),
    );
    if (result == true && mounted) {
      _fetchDashboardData(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTypography.lightTheme(),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: AppTypography.fontFamily),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: RefreshIndicator(
              onRefresh: () => _fetchDashboardData(forceRefresh: true),
              color: const Color(0xFF0F172A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  children: [
                    _HeroCard(
                      vendorName: _vendorName,
                      vendorCategory: _vendorCategory,
                      vendorAvatarUrl: _vendorAvatarUrl,
                      todayRevenue: _todayRevenue,
                      pendingCount: _pendingCount,
                      onNotificationTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                    Stack(
                      children: [
                        Container(
                          height: 50,
                          color: const Color(0xFF0F172A),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              _QuickActionsBar(
                                onMenuTap: _openAllCategories,
                                onOrdersTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const OrdersScreen()),
                                  );
                                },
                                onReviewsTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ReviewsScreen()),
                                  );
                                },
                                onRatingsTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const PerformanceAnalysisScreen()),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              _MajorCategoriesSection(
                                categories: _categories,
                                isLoading: _isLoadingCategories,
                                errorMessage: _categoryError,
                                onSeeAll: _openAllCategories,
                                onRetry: () => _fetchCategories(),
                              ),
                              const SizedBox(height: 24),
                              _LatestOrdersSection(
                                orders: _orders,
                                isLoading: _isLoadingOrders,
                                errorMessage: _orderError,
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const OrdersScreen()),
                                  );
                                },
                                onOrderTap: (order) {
                                  if (order.rawSession.isNotEmpty) {
                                    _openSessionDetails(order.rawSession);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const OrdersScreen()),
                                    );
                                  }
                                },
                                onRetry: () => _fetchOrders(),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String vendorName;
  final String vendorCategory;
  final String? vendorAvatarUrl;
  final double todayRevenue;
  final int pendingCount;
  final VoidCallback? onNotificationTap;

  const _HeroCard({
    required this.vendorName,
    required this.vendorCategory,
    this.vendorAvatarUrl,
    required this.todayRevenue,
    required this.pendingCount,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      padding: EdgeInsets.only(
        top: topPadding + 20,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Column(
        children: [
          _HeroHeader(
            vendorName: vendorName,
            vendorCategory: vendorCategory,
            avatarUrl: vendorAvatarUrl,
            onNotificationTap: onNotificationTap,
          ),
          const SizedBox(height: 8),
          _HeroRevenueBadge(),
          const SizedBox(height: 4),
          _HeroRevenueAmount(amount: todayRevenue),
          const SizedBox(height: 4),
          _HeroLiveIndicator(pendingCount: pendingCount),
          const SizedBox(height: 16),
          _HeroMetricsCapsule(pendingCount: pendingCount),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String vendorName;
  final String vendorCategory;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;

  const _HeroHeader({
    required this.vendorName,
    required this.vendorCategory,
    this.avatarUrl,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedImg = ApiConfig.getImageUrl(avatarUrl);
    final hasImg = resolvedImg != null && resolvedImg.isNotEmpty;

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
                color: const Color(0xFF1E293B),
              ),
              child: ClipOval(
                child: hasImg
                    ? Image.network(
                        resolvedImg,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      )
                    : const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 22,
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
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '$vendorName · $vendorCategory',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
              onTap: onNotificationTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            ValueListenableBuilder<List<VendorNotification>>(
              valueListenable: VendorNotificationService.notifications,
              builder: (_, notifications, __) {
                final unread = notifications.where((item) => !item.read).length;
                if (unread == 0) return const SizedBox.shrink();
                return Positioned(
                  top: 3,
                  right: 1,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0F172A), width: 1.5),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              },
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
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Today's Revenue",
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 248, 249, 249)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color.fromARGB(255, 249, 250, 250)
                      .withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Live',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color.fromARGB(255, 247, 249, 248),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRevenueAmount extends StatelessWidget {
  final double amount;
  const _HeroRevenueAmount({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Text(
      '₹${amount.toStringAsFixed(2)}',
      style: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -1,
      ),
    );
  }
}

class _HeroLiveIndicator extends StatelessWidget {
  final int pendingCount;
  const _HeroLiveIndicator({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final statusText = pendingCount > 0
        ? 'Kitchen Live · $pendingCount Open Order${pendingCount == 1 ? '' : 's'}'
        : 'Kitchen Ready · Open for Orders';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _PulsingDot(color: Color(0xFF34D399)),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HeroMetricsCapsule extends StatelessWidget {
  final int pendingCount;
  const _HeroMetricsCapsule({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final ticketText =
        '$pendingCount ${pendingCount == 1 ? 'Ticket' : 'Tickets'}';

    return Container(
      padding: const EdgeInsets.all(10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.receipt_outlined,
                iconBg: Colors.white.withValues(alpha: 0.1),
                iconColor: Colors.white,
                label: 'LIVE ORDERS',
                value: ticketText,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShopStatusSwitchTile(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopStatusSwitchTile extends StatelessWidget {
  final _shopStatus = ShopStatusService.instance;

  static const _amber = Color(0xFFF59E0B);
  static const _amberPale = Color(0xFFFCD34D);
  static const _amberLine = Color(0xFFFDE68A);

  _ShopStatusSwitchTile();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _shopStatus.status,
      builder: (context, isOpen, _) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _shopStatus.toggle(!isOpen);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isOpen
                  ? _amber.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOpen
                    ? _amberLine.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOpen
                        ? _amber.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    isOpen
                        ? Icons.storefront_rounded
                        : Icons.storefront_outlined,
                    size: 15,
                    color: isOpen ? _amberPale : Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SHOP STATUS',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isOpen ? 'Open' : 'Closed',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isOpen ? _amberPale : Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _CustomShopSwitch(isOpen: isOpen),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CustomShopSwitch extends StatelessWidget {
  final bool isOpen;

  static const _amber = Color(0xFFF59E0B);
  static const _amberLine = Color(0xFFFDE68A);
  static const _amberDeep = Color(0xFF92400E);

  const _CustomShopSwitch({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: 28,
      height: 16,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isOpen ? _amber : const Color(0xFF334155),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOpen
              ? _amberLine.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        alignment: isOpen ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isOpen ? Icons.check_rounded : Icons.power_settings_new_rounded,
              size: 8,
              color: isOpen ? _amberDeep : const Color(0xFF64748B),
            ),
          ),
        ),
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

  const _MetricTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Center(
              child: Icon(icon, size: 15, color: iconColor),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
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
        icon: Icons.bar_chart_outlined,
        label: 'Analysis',
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
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
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onSeeAll;
  final VoidCallback? onRetry;

  const _MajorCategoriesSection({
    required this.categories,
    this.isLoading = false,
    this.errorMessage,
    this.onSeeAll,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _SectionHeader(title: 'Major Categories', onSeeAll: onSeeAll),
          if (isLoading)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF0F172A),
              ),
            )
          else if (errorMessage != null && categories.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.orange, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Retry',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          else if (categories.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.category_outlined,
                      size: 32, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  const Text(
                    'No Categories Created',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Organize your dishes into categories for customers.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onSeeAll,
                    icon: const Icon(Icons.add,
                        size: 16, color: Color(0xFF0F172A)),
                    label: const Text(
                      'Manage Categories',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            )
          else
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

  String? get _resolvedImageUrl {
    if (category.imageUrl.trim().isNotEmpty) {
      return category.imageUrl.trim();
    }
    for (final item in category.items) {
      if (item.imageUrl.trim().isNotEmpty) {
        return item.imageUrl.trim();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolvedImageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          category.icon,
                          size: 20,
                          color: const Color(0xFF334155),
                        ),
                      )
                    : Icon(
                        category.icon,
                        size: 20,
                        color: const Color(0xFF334155),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${category.count} items',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
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
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onSeeAll;
  final ValueChanged<OrderItem>? onOrderTap;
  final VoidCallback? onRetry;

  const _LatestOrdersSection({
    required this.orders,
    this.isLoading = false,
    this.errorMessage,
    this.onSeeAll,
    this.onOrderTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _SectionHeader(title: 'Latest Orders', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          if (isLoading)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF0F172A),
              ),
            )
          else if (errorMessage != null && orders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.orange, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Retry',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          else if (orders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 36, color: Color(0xFF94A3B8)),
                  SizedBox(height: 10),
                  Text(
                    'No Orders Yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Orders placed and verified with your QR code will appear here in real-time.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...orders.take(3).map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OrderCard(
                    order: o,
                    onTap: () => onOrderTap?.call(o),
                  ),
                )),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final VoidCallback? onTap;

  const _OrderCard({
    required this.order,
    this.onTap,
  });

  Color get _iconBg {
    switch (order.statusType) {
      case OrderStatus.pending:
        return const Color(0xFFFEF3C7);
      case OrderStatus.completed:
        return const Color(0xFFD1FAE5).withValues(alpha: 0.6);
      case OrderStatus.expired:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get _iconColor {
    switch (order.statusType) {
      case OrderStatus.pending:
        return const Color(0xFFD97706);
      case OrderStatus.completed:
        return const Color(0xFF059669);
      case OrderStatus.expired:
        return const Color(0xFF64748B);
    }
  }

  Color get _borderColor {
    switch (order.statusType) {
      case OrderStatus.pending:
        return const Color(0xFFFDE68A).withValues(alpha: 0.8);
      case OrderStatus.completed:
        return const Color(0xFFD1FAE5).withValues(alpha: 0.8);
      case OrderStatus.expired:
        return const Color(0xFFE2E8F0).withValues(alpha: 0.8);
    }
  }

  IconData get _icon {
    switch (order.statusType) {
      case OrderStatus.pending:
        return Icons.receipt_long_outlined;
      case OrderStatus.completed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.expired:
        return Icons.cancel_outlined;
    }
  }

  Widget _buildThumbnail() {
    if (order.imageUrl.isEmpty) return _buildThumbnailFallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        order.imageUrl,
        width: 48,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildThumbnailFallback(),
      ),
    );
  }

  Widget _buildThumbnailFallback() {
    return Container(
      width: 48,
      height: 52,
      decoration: BoxDecoration(
        color: _iconBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Icon(_icon, size: 19, color: _iconColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildThumbnail(),
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
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '· ${order.platform}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
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
                  '₹${order.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.itemCount} items',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderItem order;

  const _StatusBadge({required this.order});

  Color get _dotColor {
    switch (order.statusType) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.completed:
        return const Color(0xFF10B981);
      case OrderStatus.expired:
        return const Color(0xFF94A3B8);
    }
  }

  Color get _textColor {
    switch (order.statusType) {
      case OrderStatus.pending:
        return const Color(0xFF92400E);
      case OrderStatus.completed:
        return const Color(0xFF065F46);
      case OrderStatus.expired:
        return const Color(0xFF64748B);
    }
  }

  Color get _bgColor {
    switch (order.statusType) {
      case OrderStatus.pending:
        return const Color(0xFFFFFBEB);
      case OrderStatus.completed:
        return const Color(0xFFECFDF5);
      case OrderStatus.expired:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get _borderColor {
    switch (order.statusType) {
      case OrderStatus.pending:
        return const Color(0xFFFDE68A);
      case OrderStatus.completed:
        return const Color(0xFFD1FAE5);
      case OrderStatus.expired:
        return const Color(0xFFE2E8F0).withValues(alpha: 0.6);
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
                color: Color(0xFF0F172A),
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
                color: Colors.grey.shade600,
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

  const _PulsingDot({required this.color});

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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
