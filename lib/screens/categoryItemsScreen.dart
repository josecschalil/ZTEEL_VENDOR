import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/editFoodItemScreen.dart';

// ── Design tokens ──────────────────────────────
const _bg = Color(0xFF0F0A07);
const _surface = Color(0xFF16100A);
const _surfaceRaised = Color(0xFF1C1410);
const _orange = Color(0xFFE87722);
const _orangeDim = Color(0x29E87722);
const _orangeBorder = Color(0x40E87722);
const _white = Color(0xFFF0EBE3);
const _grey1 = Color(0xFF8A7E74);
const _grey2 = Color(0xFF2A2018);
const _grey3 = Color(0xFF3A2E24);
const _green = Color(0xFF4ade80);
const _greenDim = Color(0x1A4ade80);
const _greenBorder = Color(0x404ade80);
const _red = Color(0xFFE84242);
const _redDim = Color(0x29E84242);

// ── Models ─────────────────────────────────────
enum ItemStatus { available, notAvailable }

enum ItemTag { none, bestseller, veg }

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl; // emoji fallback used in demo
  final ItemStatus status;
  final ItemTag tag;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.status = ItemStatus.available,
    this.tag = ItemTag.none,
  });
}

// ── Demo data ──────────────────────────────────
const _demoItems = [
  FoodItem(
    id: '1',
    name: 'Crispy Calamari',
    description:
        'Lightly battered squid rings served with zesty house-made tartare sauce and lemon wedges.',
    price: 14.50,
    imageUrl: '🦑',
    status: ItemStatus.available,
    tag: ItemTag.bestseller,
  ),
  FoodItem(
    id: '2',
    name: 'Truffle Bruschetta',
    description:
        'Toasted sourdough topped with wild mushrooms, truffle oil, and fresh herbs.',
    price: 12.00,
    imageUrl: '🍄',
    status: ItemStatus.notAvailable,
    tag: ItemTag.none,
  ),
  FoodItem(
    id: '3',
    name: 'Roasted Pumpkin Soup',
    description:
        'Velvety slow-roasted pumpkin soup with a touch of nutmeg and cream.',
    price: 10.50,
    imageUrl: '🎃',
    status: ItemStatus.available,
    tag: ItemTag.veg,
  ),
  FoodItem(
    id: '4',
    name: 'Honey-Glazed Wings',
    description:
        '6-piece jumbo wings tossed in a sweet and spicy glaze served with ranch dip.',
    price: 12.50,
    imageUrl: '🍗',
    status: ItemStatus.available,
    tag: ItemTag.none,
  ),
  FoodItem(
    id: '5',
    name: 'Saffron Samosas',
    description:
        'Golden crispy pastry filled with spiced potato and peas, served with mint chutney.',
    price: 9.00,
    imageUrl: '🥟',
    status: ItemStatus.available,
    tag: ItemTag.veg,
  ),
  FoodItem(
    id: '6',
    name: 'Tandoori Paneer Tikka',
    description:
        'Marinated paneer cubes grilled in tandoor with bell peppers and onions.',
    price: 14.00,
    imageUrl: '🍢',
    status: ItemStatus.available,
    tag: ItemTag.veg,
  ),
];

// ── Screen ─────────────────────────────────────
class CategoryItemsScreen extends StatefulWidget {
  final String categoryName;
  final int totalItems;

  const CategoryItemsScreen({
    super.key,
    this.categoryName = 'Signature Starters',
    this.totalItems = 8,
  });

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchFocused = false;
  String _query = '';
  int _navIndex = 0;

  late final AnimationController _entryAc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  Animation<double> _fade(int i) => CurvedAnimation(
        parent: _entryAc,
        curve: Interval(i * 0.07, 0.55 + i * 0.08, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(int i) =>
      Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryAc,
          curve:
              Interval(i * 0.07, 0.55 + i * 0.08, curve: Curves.easeOutCubic),
        ),
      );

  Widget _reveal(int i, Widget child) => FadeTransition(
        opacity: _fade(i),
        child: SlideTransition(position: _slide(i), child: child),
      );

  List<FoodItem> get _filtered => _query.isEmpty
      ? _demoItems
      : _demoItems
          .where((item) =>
              item.name.toLowerCase().contains(_query.toLowerCase()) ||
              item.description.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(
        () => setState(() => _searchFocused = _searchFocus.hasFocus));
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _entryAc.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        floatingActionButton: FadeTransition(
          opacity: _fade(5),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditFoodItemScreen()),
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(15),
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _buildBottomNav(),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Top bar ──────────────────────────
                _reveal(0, _buildTopBar()),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Hero ─────────────────────────────
                        _reveal(1, _buildHero()),
                        const SizedBox(height: 20),
                        // ── Search + filter ───────────────────
                        _reveal(2, _buildSearchBar()),
                        const SizedBox(height: 20),
                        // ── Items list ───────────────────────
                        ..._filtered.asMap().entries.map((e) {
                          return _reveal(
                            3 + (e.key % 3),
                            _buildItemCard(e.value),
                          );
                        }),
                        // Empty state
                        if (_filtered.isEmpty) _buildEmptyState(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(
          bottom: BorderSide(color: Color(0x0FFFFFFF), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _grey3, width: 0.5),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _white, size: 14),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.categoryName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _white,
            ),
          ),
          const Spacer(),
          // Notification bell
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _grey3, width: 0.5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: _grey1, size: 17),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: _orange, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _surfaceRaised,
              border: Border.all(color: _orangeBorder, width: 0.5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.person_rounded, color: _grey1, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────
  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      height: 200,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _grey3, width: 0.5),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background pattern
          ..._buildHeroPattern(),
          // Dark gradient overlay bottom-to-top
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0xCC0F0A07),
                ],
                stops: [0.3, 1.0],
              ),
            ),
          ),
          // Item count pill — top right
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _bg.withOpacity(0.85),
                border: Border.all(color: _grey3, width: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: _orange, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.totalItems} ITEMS',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom text
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: _orangeBorder, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'MANAGEMENT MODE',
                    style: TextStyle(
                      color: _orange,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.categoryName,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHeroPattern() {
    // Decorative concentric circles as background
    return [
      Positioned(
        right: -40,
        top: -40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _orangeBorder, width: 0.5),
          ),
        ),
      ),
      Positioned(
        right: -10,
        top: -10,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _orangeBorder, width: 0.5),
          ),
        ),
      ),
      Positioned(
        right: 20,
        top: 20,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _orangeDim,
            border: Border.all(color: _orangeBorder, width: 0.5),
          ),
        ),
      ),
      Positioned(
        left: -30,
        bottom: -30,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _grey3, width: 0.5),
          ),
        ),
      ),
    ];
  }

  // ── Search bar ───────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(
                  color: _searchFocused ? _orangeBorder : _grey3,
                  width: _searchFocused ? 1.0 : 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded,
                      color: _searchFocused ? _orange : _grey1, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      style: const TextStyle(
                          color: _white, fontSize: 14, height: 1.0),
                      cursorColor: _orange,
                      cursorWidth: 1.5,
                      decoration: InputDecoration(
                        hintText:
                            'Search ${widget.categoryName.toLowerCase()}...',
                        hintStyle: const TextStyle(color: _grey1, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        _searchFocus.unfocus();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child:
                            Icon(Icons.close_rounded, color: _grey1, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filter button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _grey3, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: _grey1, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Item card ─────────────────────────────────
  Widget _buildItemCard(FoodItem item) {
    final isAvailable = item.status == ItemStatus.available;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _grey3, width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image section (left) ──────────────
            Stack(
              children: [
                Container(
                  width: 110,
                  height: 120,
                  color: _surfaceRaised,
                  child: Center(
                    child: Text(
                      item.imageUrl,
                      style: const TextStyle(fontSize: 44),
                    ),
                  ),
                ),
                // Tag badge (top-left of image)
                if (item.tag != ItemTag.none)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildTagBadge(item.tag),
                  ),
                // Veg badge (bottom-left of image)
                if (item.tag == ItemTag.veg)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _greenDim,
                        border: Border.all(color: _greenBorder, width: 0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'VEG',
                        style: TextStyle(
                          color: _green,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Content section (right) ───────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: _white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: _grey1,
                        fontSize: 12,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // Status + actions row
                    Row(
                      children: [
                        // Availability badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAvailable ? _greenDim : _surfaceRaised,
                            border: Border.all(
                              color: isAvailable ? _greenBorder : _grey3,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAvailable ? 'AVAILABLE' : 'NOT AVAILABLE',
                            style: TextStyle(
                              color: isAvailable ? _green : _grey1,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Edit button
                        _buildActionBtn(Icons.edit_outlined, onTap: () {}),
                        const SizedBox(width: 8),
                        // Delete button
                        _buildActionBtn(
                          Icons.delete_outline_rounded,
                          onTap: () {},
                          isDestructive: true,
                        ),
                      ],
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

  Widget _buildTagBadge(ItemTag tag) {
    if (tag == ItemTag.bestseller) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          color: _orange,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(8),
          ),
        ),
        child: const Text(
          'BESTSELLER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionBtn(
    IconData icon, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDestructive ? _redDim : _surfaceRaised,
          border: Border.all(
            color: isDestructive ? _red.withOpacity(0.3) : _grey3,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? _red : _grey1,
          size: 14,
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _grey3, width: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.search_off_rounded, color: _grey1, size: 26),
          ),
          const SizedBox(height: 16),
          const Text('No items found',
              style: TextStyle(
                  color: _white, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Try a different search term',
              style: TextStyle(color: _grey1, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.grid_view_rounded, 'Dashboard'),
      (Icons.local_offer_outlined, 'Offers'),
      (Icons.receipt_long_outlined, 'Orders'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: Color(0x0FFFFFFF), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: items.asMap().entries.map((e) {
              final index = e.key;
              final icon = e.value.$1;
              final label = e.value.$2;
              final isActive = _navIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _navIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: isActive ? _orange : _grey1, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: isActive ? _orange : _grey1,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
