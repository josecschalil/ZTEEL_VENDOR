import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/MilestoneScreen.dart';
import 'package:frontend/screens/createOfferScreen.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/services/shop_status_service.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
//
// Mirrors the dashboard exactly: a slate-tinted neutral ramp, one deep navy
// used for the hero and for primary actions, emerald for "running", amber for
// "scheduled"/"featured". Nothing else earns a colour.
class _Pal {
  const _Pal._();

  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const wash = Color(0xFFF1F5F9);
  static const line = Color(0xFFE2E8F0);

  static const ink = Color(0xFF0F172A);
  static const ink800 = Color(0xFF1E293B);
  static const ink700 = Color(0xFF334155);
  static const ink600 = Color(0xFF475569);
  static const ink500 = Color(0xFF64748B);
  static const ink400 = Color(0xFF94A3B8);

  static const green = Color(0xFF10B981);
  static const greenBright = Color(0xFF34D399);
  static const greenPale = Color(0xFF6EE7B7);
  static const greenDeep = Color(0xFF065F46);
  static const greenInk = Color(0xFF059669);
  static const greenSoft = Color(0xFFECFDF5);
  static const greenLine = Color(0xFFD1FAE5);

  static const amber = Color(0xFFF59E0B);
  static const amberPale = Color(0xFFFCD34D);
  static const amberDeep = Color(0xFF92400E);
  static const amberSoft = Color(0xFFFFFBEB);
  static const amberLine = Color(0xFFFDE68A);

  static const red = Color(0xFFE11D48);
  static const redSoft = Color(0xFFFFF1F2);

  static const cardShadow = BoxShadow(
    color: Color(0x06000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
}

// ─── Data Models ─────────────────────────────────────────────────────────────
enum OfferStatus { live, scheduled, draft }

class Offer {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String duration;
  final OfferStatus status;
  bool isActive;
  final bool isBestseller;
  bool isFeatured;
  final Color categoryColor;

  Offer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.duration,
    required this.status,
    required this.isActive,
    this.isBestseller = false,
    this.isFeatured = false,
    this.categoryColor = _Pal.amber,
  });
}

final List<Offer> kOffers = [
  Offer(
    id: '1',
    title: 'Golden Hour Feast',
    subtitle: '40% OFF across the entire Main Course menu.',
    category: 'All Main Courses',
    duration: 'Oct 01 – Oct 31',
    status: OfferStatus.live,
    isActive: true,
    isBestseller: true,
    isFeatured: true,
  ),
  Offer(
    id: '2',
    title: 'Sunset Starters',
    subtitle: 'Buy one, get one on all cold appetizers.',
    category: 'Starters',
    duration: '12 Days left',
    status: OfferStatus.scheduled,
    isActive: true,
  ),
  Offer(
    id: '3',
    title: 'Sweet Midnight',
    subtitle: 'Complimentary dessert for orders above \$100.',
    category: 'Desserts',
    duration: 'Ongoing',
    status: OfferStatus.live,
    isActive: false,
  ),
];

// ─── Main Screen ─────────────────────────────────────────────────────────────
//
// Rebuilt on the dashboard's layout grammar: a dark navy hero card with the
// headline number and two metric tiles, a white quick-action row, then
// sectioned white cards on a slate background.
//
// Everything the old screen did still lives here — shop open/closed toggle,
// notifications, featured promo (persisted), active/inactive tabs, per-offer
// feature + activate toggles with confirmation, the details sheet, the empty
// state, milestone rewards and pull-to-refresh — just redistributed so each
// job has one obvious home instead of competing inside the same card.
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  static const String _heroImageUrl =
      'https://images.unsplash.com/photo-1544025162-d76694265947?w=1000&auto=format&fit=crop&q=80';
  static const int _notificationCount = 2;

  int _selectedTab = 0;
  List<Offer> _offers = [];
  bool _isLoading = true;

  final _shopStatus = ShopStatusService.instance;

  late AnimationController _heroController;
  late Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _heroFade = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOut,
    );
    _fetchOffers();
    _shopStatus.ensureLoaded();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _fetchOffers() async {
    setState(() => _isLoading = true);
    final res = await VendorService.getOffers();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final savedFeaturedId = prefs.getString('featured_offer_id') ?? '';

    if (res['success'] == true && res['data'] != null) {
      final rawList = res['data'] as List<dynamic>;
      List<Offer> fetched = [];

      bool hasFeaturedMatch = false;
      if (savedFeaturedId.isNotEmpty) {
        hasFeaturedMatch =
            rawList.any((item) => item['id']?.toString() == savedFeaturedId);
      }

      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is Map<String, dynamic>) {
          final id = item['id']?.toString() ?? '';
          final title = item['title']?.toString() ?? 'Special Offer';
          final desc = item['description']?.toString() ?? '';
          final discountStr = item['discount_percentage']?.toString() ?? '0';
          final discount = double.tryParse(discountStr)?.toInt() ?? 0;
          final scope = item['scope_type']?.toString() ?? 'all_menu';
          final isActive = item['is_active'] as bool? ?? true;
          final isAvail = item['is_available'] as bool? ?? true;

          String subtitle =
              desc.isNotEmpty ? desc : '$discount% OFF promo discount';
          String category = 'All Menu';
          if (scope == 'item_set') {
            final targets = item['targets'] as Map<String, dynamic>?;
            final count = (targets?['item_ids'] as List?)?.length ?? 0;
            category = count > 0 ? '$count Selected Items' : 'Item Set';
          } else if (scope == 'category_set') {
            final targets = item['targets'] as Map<String, dynamic>?;
            final count = (targets?['category_ids'] as List?)?.length ?? 0;
            category = count > 0 ? '$count Categories' : 'Category Set';
          }

          String duration = 'Ongoing';
          if (item['starts_at'] != null && item['ends_at'] != null) {
            try {
              final start = DateTime.parse(item['starts_at'].toString());
              final end = DateTime.parse(item['ends_at'].toString());
              const months = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec'
              ];
              duration =
                  '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}';
            } catch (_) {}
          }

          final isFeatured =
              hasFeaturedMatch ? (id == savedFeaturedId) : (i == 0);

          fetched.add(Offer(
            id: id,
            title: title,
            subtitle: subtitle,
            category: category,
            duration: duration,
            status:
                (isActive && isAvail) ? OfferStatus.live : OfferStatus.draft,
            isActive: isActive,
            isBestseller: i == 0,
            isFeatured: isFeatured,
          ));
        }
      }
      setState(() {
        _offers = fetched;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Offer? get _featuredOffer {
    if (_offers.isEmpty) return null;
    return _offers.firstWhere(
      (offer) => offer.isFeatured,
      orElse: () => _offers.first,
    );
  }

  int get _activeCount => _offers.where((o) => o.isActive).length;
  int get _inactiveCount => _offers.length - _activeCount;
  int get _liveCount =>
      _offers.where((o) => o.isActive && o.status == OfferStatus.live).length;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _setAsFeatured(Offer offer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('featured_offer_id', offer.id);

    setState(() {
      for (final o in _offers) {
        o.isFeatured = (o.id == offer.id);
      }
    });

    _heroController.reset();
    _heroController.forward();

    if (!mounted) return;
    _toast('"${offer.title}" is now your featured promotion');
  }

  Future<void> _goToCreateOffer() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateOfferScreen()),
    );
    if (created == true && mounted) {
      _fetchOffers();
    }
  }

  void _openMilestones() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MilestoneRewardsScreen()),
    );
  }

  Future<void> _toggleShopStatus(bool nextOpen) async {
    final ok = await _shopStatus.toggle(nextOpen);
    if (!mounted) return;
    if (!ok) {
      _toast('Could not update shop status. Try again.', isError: true);
    }
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? _Pal.red : _Pal.ink,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _requestStatusChange(Offer offer) async {
    final nextValue = !offer.isActive;
    final confirmed = await _confirmOfferStatusChange(
      offer: offer,
      nextValue: nextValue,
    );
    if (!confirmed || !mounted) return;
    setState(() => offer.isActive = nextValue);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final featured = _featuredOffer;
    final showFeatured = !_isLoading && _selectedTab == 0 && featured != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _Pal.bg,
        body: RefreshIndicator(
          onRefresh: _fetchOffers,
          color: _Pal.ink,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              children: [
                _buildHero(),
                const SizedBox(height: 16),
                _buildQuickActions(featured),
                const SizedBox(height: 22),
                if (showFeatured) ...[
                  _SectionHeader(
                    title: 'Featured promotion',
                    actionLabel: 'View details',
                    onAction: () => _showOfferDetailsModal(featured),
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _heroFade,
                    child: _buildFeaturedCard(featured),
                  ),
                  const SizedBox(height: 24),
                ],
                _SectionHeader(
                  title: 'All promotions',
                  actionLabel: 'New offer',
                  onAction: _goToCreateOffer,
                ),
                const SizedBox(height: 12),
                _buildTabs(),
                const SizedBox(height: 14),
                _buildListArea(),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Loyalty rewards'),
                const SizedBox(height: 12),
                _buildMilestoneCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    final topPadding = MediaQuery.of(context).padding.top;
    final featured = _featuredOffer;

    return Container(
      decoration: const BoxDecoration(
        color: _Pal.ink,
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
        bottom: 26,
      ),
      child: Column(
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Promotions running',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _Pal.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _Pal.greenBright.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$_liveCount live',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _Pal.greenPale,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$_activeCount',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                TextSpan(
                  text:
                      _activeCount == 1 ? '  offer active' : '  offers active',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.55),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _PulsingDot(color: _Pal.greenBright),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  featured == null
                      ? 'No featured promotion picked yet'
                      : 'Featured · ${featured.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.confirmation_number_outlined,
                  iconBg: Colors.white.withValues(alpha: 0.1),
                  iconColor: Colors.white,
                  label: 'TOTAL OFFERS',
                  value: '${_offers.length} created',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  icon: Icons.pause_rounded,
                  iconBg: _Pal.amber.withValues(alpha: 0.18),
                  iconColor: _Pal.amberPale,
                  label: 'PAUSED',
                  value: '$_inactiveCount',
                  subtitle: _inactiveCount == 1 ? ' offer' : ' offers',
                  valueColor: _Pal.amberPale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Icon(
            Icons.local_offer_rounded,
            size: 19,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zteeel Vendor',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                'Offers & deals',
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
        ValueListenableBuilder<bool>(
          valueListenable: _shopStatus.status,
          builder: (_, isOpen, __) => _ShopStatusPill(
            isOpen: isOpen,
            onTap: () => _toggleShopStatus(!isOpen),
          ),
        ),
        const SizedBox(width: 8),
        _NotificationButton(count: _notificationCount, onTap: () {}),
      ],
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions(Offer? featured) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.add_rounded,
              label: 'New offer',
              primary: true,
              onTap: _goToCreateOffer,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.star_outline_rounded,
              label: 'Featured',
              onTap: featured == null
                  ? _goToCreateOffer
                  : () => _showOfferDetailsModal(featured),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.local_fire_department_outlined,
              label: 'Milestones',
              onTap: _openMilestones,
            ),
          ),
        ],
      ),
    );
  }

  // ── Featured promotion ─────────────────────────────────────────────────────

  Widget _buildFeaturedCard(Offer offer) {
    final statusLabel = offer.isActive ? 'Live now' : 'Paused';
    final statusColor = offer.isActive ? _Pal.greenInk : _Pal.ink500;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _showOfferDetailsModal(offer),
        child: Container(
          decoration: BoxDecoration(
            color: _Pal.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _Pal.line.withValues(alpha: 0.8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 148,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: _Pal.ink,
                        child: Image.network(
                          _heroImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : const SizedBox.shrink(),
                          errorBuilder: (context, error, stack) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _Pal.ink.withValues(alpha: 0.10),
                                _Pal.ink.withValues(alpha: 0.82),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.22),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded,
                                          size: 11, color: _Pal.amberPale),
                                      SizedBox(width: 4),
                                      Text(
                                        'Featured',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _setAsFeatured(offer),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _Pal.ink.withValues(alpha: 0.35),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: _Pal.amberPale,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              offer.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: _Pal.ink600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          _MetaChip(
                            icon: Icons.restaurant_menu_rounded,
                            label: offer.category,
                          ),
                          _MetaChip(
                            icon: Icons.calendar_today_rounded,
                            label: offer.duration,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tabs + list ────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _Pal.wash,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Pal.line.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SegmentTab(
                label: 'Active',
                count: _activeCount,
                selected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
            ),
            Expanded(
              child: _SegmentTab(
                label: 'Paused',
                count: _inactiveCount,
                selected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListArea() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 44),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: _Pal.ink,
            ),
          ),
        ),
      );
    }

    final filtered = _offers
        .where((offer) => _selectedTab == 0 ? offer.isActive : !offer.isActive)
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: filtered
            .map(
              (offer) => _OfferCard(
                offer: offer,
                onTap: () => _showOfferDetailsModal(offer),
                onSetFeatured: () => _setAsFeatured(offer),
                onToggleActive: () => _requestStatusChange(offer),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isActiveTab = _selectedTab == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: _Pal.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Pal.line.withValues(alpha: 0.8)),
          boxShadow: const [_Pal.cardShadow],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _Pal.wash,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 21,
                color: _Pal.ink600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isActiveTab ? 'Nothing running right now' : 'No paused offers',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _Pal.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isActiveTab
                  ? 'Create a promotion to start pulling in repeat orders.'
                  : 'Offers you pause will be collected here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: _Pal.ink500,
              ),
            ),
            if (isActiveTab) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _goToCreateOffer,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: _Pal.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Create offer',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Milestone rewards ──────────────────────────────────────────────────────

  Widget _buildMilestoneCard() {
    const filledStamps = 3;
    const totalStamps = 6;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _openMilestones,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _Pal.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Pal.line.withValues(alpha: 0.8)),
            boxShadow: const [_Pal.cardShadow],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: _Pal.wash,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 19,
                      color: _Pal.ink700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Milestone rewards',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _Pal.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Reward regulars once they cross a spend threshold.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: _Pal.ink500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: _Pal.ink400),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  ...List.generate(totalStamps, (i) {
                    final filled = i < filledStamps;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? _Pal.ink : _Pal.wash,
                          border: Border.all(
                            color: filled ? _Pal.ink : _Pal.line,
                          ),
                        ),
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          size: 13,
                          color: filled ? Colors.white : _Pal.ink400,
                        ),
                      ),
                    );
                  }),
                  Expanded(
                    child: Text(
                      '$filledStamps of $totalStamps collected',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _Pal.ink400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Details sheet ──────────────────────────────────────────────────────────

  void _showOfferDetailsModal(Offer offer) {
    final statusStyle = _statusStyleFor(offer);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: const BoxDecoration(
          color: _Pal.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _Pal.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: offer.isActive ? _Pal.greenSoft : _Pal.wash,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: offer.isActive ? _Pal.greenLine : _Pal.line,
                      ),
                    ),
                    child: Icon(
                      Icons.local_offer_outlined,
                      size: 20,
                      color: offer.isActive ? _Pal.greenInk : _Pal.ink600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _Pal.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _StatusPill(style: statusStyle),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                offer.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: _Pal.ink600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _Pal.wash,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Pal.line),
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Applies to', value: offer.category),
                    const _DetailDivider(),
                    _DetailRow(label: 'Valid for', value: offer.duration),
                    const _DetailDivider(),
                    _DetailRow(
                      label: 'Visibility',
                      value: offer.isActive
                          ? 'Shown to customers'
                          : 'Hidden from customers',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  if (!offer.isFeatured) {
                    _setAsFeatured(offer);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: offer.isFeatured ? _Pal.amberSoft : _Pal.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: offer.isFeatured ? _Pal.amberLine : _Pal.line,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        offer.isFeatured
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 17,
                        color: offer.isFeatured ? _Pal.amber : _Pal.ink700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        offer.isFeatured
                            ? 'Featured on your storefront'
                            : 'Feature on your storefront',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color:
                              offer.isFeatured ? _Pal.amberDeep : _Pal.ink700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _Pal.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _Pal.line),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _Pal.ink700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _requestStatusChange(offer);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: offer.isActive ? _Pal.redSoft : _Pal.ink,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: offer.isActive ? _Pal.red : _Pal.ink,
                          ),
                        ),
                        child: Text(
                          offer.isActive ? 'Pause offer' : 'Activate offer',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: offer.isActive ? _Pal.red : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Confirmation + API write ───────────────────────────────────────────────

  Future<bool> _confirmOfferStatusChange({
    required Offer offer,
    required bool nextValue,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _Pal.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _Pal.line),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          title: Text(
            nextValue ? 'Activate this offer?' : 'Pause this offer?',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _Pal.ink,
              letterSpacing: -0.3,
            ),
          ),
          content: Text(
            nextValue
                ? 'Customers will see "${offer.title}" on your storefront straight away.'
                : '"${offer.title}" stops applying to new orders and moves to your paused list.',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: _Pal.ink600,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _Pal.ink500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: nextValue ? _Pal.ink : _Pal.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                nextValue ? 'Activate' : 'Pause',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final res = await VendorService.updateOffer(
          id: offer.id, data: {'is_active': nextValue});
      if (res['success'] == true) {
        _fetchOffers();
        return true;
      } else {
        if (mounted) {
          _toast(
            res['error']?.toString() ?? 'Could not update the offer status',
            isError: true,
          );
        }
        return false;
      }
    }
    return false;
  }
}

// ─── Status styling ──────────────────────────────────────────────────────────

class _StatusStyle {
  final String label;
  final Color dot;
  final Color text;
  final Color bg;
  final Color border;

  const _StatusStyle({
    required this.label,
    required this.dot,
    required this.text,
    required this.bg,
    required this.border,
  });
}

_StatusStyle _statusStyleFor(Offer offer) {
  if (!offer.isActive) {
    return const _StatusStyle(
      label: 'Paused',
      dot: _Pal.ink400,
      text: _Pal.ink500,
      bg: _Pal.wash,
      border: _Pal.line,
    );
  }
  switch (offer.status) {
    case OfferStatus.live:
      return const _StatusStyle(
        label: 'Live',
        dot: _Pal.green,
        text: _Pal.greenDeep,
        bg: _Pal.greenSoft,
        border: _Pal.greenLine,
      );
    case OfferStatus.scheduled:
      return const _StatusStyle(
        label: 'Scheduled',
        dot: _Pal.amber,
        text: _Pal.amberDeep,
        bg: _Pal.amberSoft,
        border: _Pal.amberLine,
      );
    case OfferStatus.draft:
      return const _StatusStyle(
        label: 'Draft',
        dot: _Pal.ink400,
        text: _Pal.ink600,
        bg: _Pal.wash,
        border: _Pal.line,
      );
  }
}

class _StatusPill extends StatelessWidget {
  final _StatusStyle style;

  const _StatusPill({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(color: style.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: style.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Offer card ──────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onTap;
  final VoidCallback onSetFeatured;
  final VoidCallback onToggleActive;

  const _OfferCard({
    required this.offer,
    required this.onTap,
    required this.onSetFeatured,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final style = _statusStyleFor(offer);
    final isActive = offer.isActive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Pal.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? _Pal.greenLine.withValues(alpha: 0.7)
                : _Pal.line.withValues(alpha: 0.8),
          ),
          boxShadow: const [_Pal.cardShadow],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isActive ? _Pal.greenSoft : _Pal.wash,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? _Pal.greenLine.withValues(alpha: 0.7)
                      : _Pal.line,
                ),
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 18,
                color: isActive ? _Pal.greenInk : _Pal.ink600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _Pal.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    offer.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: _Pal.ink600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusPill(style: style),
                      _MetaChip(
                        icon: Icons.restaurant_menu_rounded,
                        label: offer.category,
                      ),
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label: offer.duration,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                _CircleAction(
                  icon: offer.isFeatured
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  onTap: onSetFeatured,
                  bg: offer.isFeatured ? _Pal.amberSoft : _Pal.wash,
                  border: offer.isFeatured ? _Pal.amberLine : _Pal.line,
                  iconColor: offer.isFeatured ? _Pal.amber : _Pal.ink400,
                  tooltip: 'Feature this offer',
                ),
                const SizedBox(height: 8),
                _CircleAction(
                  icon: Icons.power_settings_new_rounded,
                  onTap: onToggleActive,
                  bg: isActive ? _Pal.greenSoft : _Pal.wash,
                  border: isActive ? _Pal.greenLine : _Pal.line,
                  iconColor: isActive ? _Pal.greenInk : _Pal.ink400,
                  tooltip: isActive ? 'Pause offer' : 'Activate offer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color border;
  final Color iconColor;
  final String tooltip;

  const _CircleAction({
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.border,
    required this.iconColor,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: _Pal.ink400),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: _Pal.ink600,
          ),
        ),
      ],
    );
  }
}

// ─── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _Pal.ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _Pal.ink500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Segmented tabs ──────────────────────────────────────────────────────────

class _SegmentTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _Pal.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? const <BoxShadow>[_Pal.cardShadow]
              : const <BoxShadow>[],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? _Pal.ink : _Pal.ink500,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 18,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: selected ? _Pal.ink : _Pal.line,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _Pal.ink500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick action button ─────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _Pal.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Pal.line),
          boxShadow: const [_Pal.cardShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary ? _Pal.ink : _Pal.wash,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 17,
                color: primary ? Colors.white : _Pal.ink700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _Pal.ink800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero pieces ─────────────────────────────────────────────────────────────

class _ShopStatusPill extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _ShopStatusPill({required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tint = isOpen ? _Pal.greenBright : _Pal.amberPale;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tint.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              isOpen ? 'Open' : 'Closed',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _Pal.red,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _Pal.ink, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;

  const _MetricTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(icon, size: 16, color: iconColor),
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
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.8,
                  ),
                ),
                if (subtitle == null)
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: valueColor ?? Colors.white,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
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

// ─── Detail sheet rows ───────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _Pal.ink500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _Pal.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: _Pal.line.withValues(alpha: 0.7));
  }
}
