import 'package:flutter/material.dart';
import 'package:frontend/screens/MilestoneScreen.dart';
import 'package:frontend/screens/createOfferScreen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────
const kBg = Color(0xFF130A04);
const kSurface = Color(0xFF1F1108);
const kCard = Color(0xFF261509);
const kCardBorder = Color(0xFF3A1E0A);
const kOrange = Color(0xFFE8622A);
const kOrangeLight = Color(0xFFF07840);
const kGold = Color(0xFFD4A853);
const kGreen = Color(0xFF4CAF6E);
const kTextPrimary = Color(0xFFF5E6D3);
const kTextSecondary = Color(0xFF9A7A5F);
const kTextMuted = Color(0xFF5C3E28);

// ─── Data Models ──────────────────────────────────────────────────────────────
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
  final bool isFeatured;
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
    this.categoryColor = kOrange,
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
    categoryColor: kOrange,
  ),
  Offer(
    id: '3',
    title: 'Sweet Midnight',
    subtitle: 'Complimentary dessert for orders above \$100.',
    category: 'Desserts',
    duration: 'Ongoing',
    status: OfferStatus.live,
    isActive: false,
    categoryColor: kGold,
  ),
];

// ─── Main Screen ─────────────────────────────────────────────────────────────
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late final List<Offer> _offers;
  late AnimationController _heroController;
  late Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _offers = kOffers
        .map(
          (offer) => Offer(
            id: offer.id,
            title: offer.title,
            subtitle: offer.subtitle,
            category: offer.category,
            duration: offer.duration,
            status: offer.status,
            isActive: offer.isActive,
            isBestseller: offer.isBestseller,
            isFeatured: offer.isFeatured,
            categoryColor: offer.categoryColor,
          ),
        )
        .toList();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _heroFade = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      bottomNavigationBar: const VendorBottomNav(currentTab: VendorTab.offers),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildFilterBar(),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _heroFade,
                      child: _buildFeaturedCard(_featuredOffer),
                    ),
                    const SizedBox(height: 16),
                    ..._buildOfferList(),
                    const SizedBox(height: 16),
                    _buildBoostBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Offer get _featuredOffer {
    return _offers.firstWhere(
      (offer) => offer.isFeatured,
      orElse: () => _offers.first,
    );
  }

  // ── Top App Bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Logo
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kOrange,
            ),
            child: const Center(
              child: Text(
                'SB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Zteel Offers',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          // Notification Bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kCardBorder),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: kTextPrimary,
                  size: 20,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: kOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Page Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Active Offers',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(width: 10),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Manage your seasonal promotions and exclusive member discounts from one cinematic dashboard.',
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  // ── Filter / Tab Bar ────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    final activeCount = _offers.where((offer) => offer.isActive).length;
    final nonActiveCount = _offers.length - activeCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All Active',
              count: activeCount,
              selected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'Non Active',
              count: nonActiveCount,
              selected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
            const SizedBox(width: 10),
            // Create Offer CTA
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateOfferScreen()));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kOrangeLight, kOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kOrange.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text(
                      'Create Offer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Featured Hero Card ──────────────────────────────────────────────────────
  Widget _buildFeaturedCard(Offer offer) {
    final statusLabel = offer.isActive ? 'ACTIVE' : 'NON ACTIVE';
    final statusColor = offer.isActive ? kGreen : kTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image placeholder (rich gradient simulating food photo)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF3D1A05),
                        Color(0xFF6B2E08),
                        Color(0xFF8B3A0A),
                        Color(0xFF5C2004),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                ),
                // Decorative food-like overlay circles
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFAA4510).withOpacity(0.4),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 10,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF7A300A).withOpacity(0.5),
                    ),
                  ),
                ),
                // Dark gradient overlay bottom
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tags row
                      Row(
                        children: [
                          _buildTag(
                            '★ BESTSELLER',
                            kOrange,
                            Colors.white,
                          ),
                          const SizedBox(width: 8),
                          _buildStateTag(statusLabel, statusColor),
                        ],
                      ),
                      const Spacer(),
                      // Title
                      const Text(
                        'Golden Hour Feast',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '40% OFF across the entire Main Course menu.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFE0C5A8),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Meta row
                      Row(
                        children: [
                          _buildMetaChip(Icons.restaurant_menu_rounded,
                              'All Main Courses'),
                          const SizedBox(width: 10),
                          _buildMetaChip(
                              Icons.calendar_today_rounded, 'Oct 01 – Oct 31'),
                          const Spacer(),
                          // Edit button
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
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

  Widget _buildTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildStateTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: kGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kGold, size: 11),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Offer List ──────────────────────────────────────────────────────────────
  List<Widget> _buildOfferList() {
    final filteredOffers = _offers
        .where((offer) => offer.isFeatured == false)
        .where((offer) => _selectedTab == 0 ? offer.isActive : !offer.isActive)
        .toList();

    if (filteredOffers.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kCardBorder),
            ),
            child: const Text(
              'No offers in this section yet.',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ];
    }

    return filteredOffers
        .map(
          (offer) => _OfferListCard(
            offer: offer,
            onStatusRequested: () async {
              final nextValue = !offer.isActive;
              final confirmed = await _confirmOfferStatusChange(
                offer: offer,
                nextValue: nextValue,
              );

              if (!confirmed) {
                return;
              }

              setState(() => offer.isActive = nextValue);
            },
          ),
        )
        .toList();
  }

  Future<bool> _confirmOfferStatusChange({
    required Offer offer,
    required bool nextValue,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kCard,
          title: Text(
            nextValue ? 'Activate offer?' : 'Deactivate offer?',
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            nextValue
                ? 'This offer will move to the active list and be treated as active.'
                : 'This offer will move to the non-active list and stop being treated as active.',
            style: const TextStyle(
              color: kTextSecondary,
              height: 1.45,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: kTextSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  // ── Boost / Analytics Banner ────────────────────────────────────────────────
  Widget _buildBoostBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MilestoneRewardsScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                kOrange.withOpacity(0.12),
                kGold.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: kOrange.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: kOrange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Milestone Rewards',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kOrange,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'Configure spend-based rewards for loyal guests',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Set spend milestones and assign rewards that keep customers coming back. Tap to open the milestone reward setup.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 12.5,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kOrangeLight, kOrange],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kOrange.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Open Milestone Rewards',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Navigation ───────────────────────────────────────────────────────
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? kOrange : kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kOrange : kCardBorder,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kOrange.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : kTextSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.2)
                    : kTextMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : kTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferListCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onStatusRequested;

  const _OfferListCard({
    required this.offer,
    required this.onStatusRequested,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = offer.status == OfferStatus.live;
    final statusColor = isLive ? kGreen : kGold;
    final statusLabel = isLive ? 'LIVE' : 'SCHEDULED';
    final actionLabel = offer.isActive ? 'Mark Inactive' : 'Mark Active';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kCardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      offer.categoryColor.withOpacity(0.6),
                      offer.categoryColor.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  isLive ? Icons.cake_rounded : Icons.lunch_dining_rounded,
                  color: offer.categoryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLive)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusActionChip(
                          label: actionLabel,
                          active: offer.isActive,
                          onTap: onStatusRequested,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      offer.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MetaLabel(label: 'Category'),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            offer.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: offer.categoryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MetaLabel(label: 'Ends in'),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            offer.duration,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }
}

class _StatusActionChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _StatusActionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              active ? kGreen.withOpacity(0.12) : kTextMuted.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? kGreen.withOpacity(0.35) : kCardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? kGreen : kTextSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? kGreen : kTextSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.swap_horiz_rounded,
              size: 13,
              color: active ? kGreen : kTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  final String label;

  const _MetaLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: kTextMuted,
        fontSize: 11.5,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String sublabel;

  const _StatChip({required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kOrange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kOrange,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
