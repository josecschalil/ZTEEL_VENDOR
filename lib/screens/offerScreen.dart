import 'package:flutter/material.dart';
import 'package:frontend/screens/MilestoneScreen.dart';
import 'package:frontend/screens/createOfferScreen.dart';

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
  final bool isBestseller;
  final bool isFeatured;
  final Color categoryColor;

  const Offer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.duration,
    required this.status,
    this.isBestseller = false,
    this.isFeatured = false,
    this.categoryColor = kOrange,
  });
}

const List<Offer> kOffers = [
  Offer(
    id: '1',
    title: 'Golden Hour Feast',
    subtitle: '40% OFF across the entire Main Course menu.',
    category: 'All Main Courses',
    duration: 'Oct 01 – Oct 31',
    status: OfferStatus.live,
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
    categoryColor: kOrange,
  ),
  Offer(
    id: '3',
    title: 'Sweet Midnight',
    subtitle: 'Complimentary dessert for orders above \$100.',
    category: 'Desserts',
    duration: 'Ongoing',
    status: OfferStatus.live,
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
  int _navIndex = 1;
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
                      child: _buildFeaturedCard(),
                    ),
                    const SizedBox(height: 16),
                    ..._buildOfferList(),
                    const SizedBox(height: 16),
                    _buildBoostBanner(),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _FilterChip(
            label: 'All Active',
            count: 4,
            selected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Drafts',
            count: 2,
            selected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
          const Spacer(),
          // Create Offer CTA
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreateOfferScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }

  // ── Featured Hero Card ──────────────────────────────────────────────────────
  Widget _buildFeaturedCard() {
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
                          _buildLiveTag(),
                        ],
                      ),
                      const Spacer(),
                      // Title
                      const Text(
                        'Golden Hour Feast',
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

  Widget _buildLiveTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kGreen.withOpacity(0.5)),
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
          const Text(
            'LIVE',
            style: TextStyle(
              color: kGreen,
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
    final nonFeatured = kOffers.where((o) => !o.isFeatured).toList();
    return nonFeatured.map((offer) => _OfferListCard(offer: offer)).toList();
  }

  // ── Boost / Analytics Banner ────────────────────────────────────────────────
  Widget _buildBoostBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    Icons.rocket_launch_rounded,
                    color: kOrange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maximize Your Reach',
                      style: TextStyle(
                        color: kOrange,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      'Boost for upcoming Friday',
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
            // Stat row
            Row(
              children: [
                _StatChip(label: '3.4×', sublabel: 'More Engagement'),
                const SizedBox(width: 10),
                _StatChip(label: 'Fri', sublabel: 'Peak Weekend'),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Promoted offers receive 3.4× more engagement during weekend service. Consider boosting \'Golden Hour Feast\' for this Friday.',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 12.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const MilestoneRewardsScreen()),
                );
              },
              child: Container(
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
                    Icon(Icons.bar_chart_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'View Analytics',
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation ───────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      (Icons.grid_view_rounded, 'Dashboard'),
      (Icons.local_offer_rounded, 'Offers'),
      (Icons.receipt_long_rounded, 'Orders'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        border: Border(
          top: BorderSide(color: kCardBorder.withOpacity(0.6), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _navIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _navIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? kOrange.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].$1,
                    size: 22,
                    color: active ? kOrange : kTextMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      color: active ? kOrange : kTextMuted,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
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

  const _OfferListCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final isLive = offer.status == OfferStatus.live;
    final statusColor = isLive ? kGreen : kGold;
    final statusLabel = isLive ? 'LIVE' : 'SCHEDULED';

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
              // Thumbnail
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
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.title,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
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
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      offer.subtitle,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Meta row
                    Row(
                      children: [
                        _MetaLabel(label: 'Category'),
                        const Spacer(),
                        Text(
                          offer.category,
                          style: TextStyle(
                            color: offer.categoryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MetaLabel(label: 'Ends in'),
                        const Spacer(),
                        Text(
                          offer.duration,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
