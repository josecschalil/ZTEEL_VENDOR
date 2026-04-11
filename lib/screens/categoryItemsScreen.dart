import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/editFoodItemScreen.dart';

// Offers-aligned palette
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
const kRed = Color(0xFFE84242);

enum ItemStatus { available, notAvailable }

enum ItemTag { none, bestseller, veg }

enum ItemFilter { all, available, unavailable }

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
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
  ItemFilter _selectedFilter = ItemFilter.all;

  late final AnimationController _entryAc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  double _staggerStart(int i) => (i * 0.08).clamp(0.0, 0.86);

  Animation<double> _fade(int i) => CurvedAnimation(
        parent: _entryAc,
        curve: Interval(
          _staggerStart(i),
          (_staggerStart(i) + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      );

  Animation<Offset> _slide(int i) =>
      Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryAc,
          curve: Interval(
            _staggerStart(i),
            (_staggerStart(i) + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );

  Widget _reveal(int i, Widget child) => FadeTransition(
        opacity: _fade(i),
        child: SlideTransition(position: _slide(i), child: child),
      );

  int get _availableCount =>
      _demoItems.where((i) => i.status == ItemStatus.available).length;

  int get _unavailableCount =>
      _demoItems.where((i) => i.status == ItemStatus.notAvailable).length;

  List<FoodItem> get _filtered {
    Iterable<FoodItem> items = _demoItems;

    if (_selectedFilter == ItemFilter.available) {
      items = items.where((item) => item.status == ItemStatus.available);
    } else if (_selectedFilter == ItemFilter.unavailable) {
      items = items.where((item) => item.status == ItemStatus.notAvailable);
    }

    if (_query.isNotEmpty) {
      items = items.where(
        (item) =>
            item.name.toLowerCase().contains(_query.toLowerCase()) ||
            item.description.toLowerCase().contains(_query.toLowerCase()),
      );
    }

    return items.toList();
  }

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(
      () => setState(() => _searchFocused = _searchFocus.hasFocus),
    );
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text),
    );
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
        backgroundColor: kBg,
        floatingActionButton: _buildAddItemButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            bottom: true,
            child: Column(
              children: [
                _reveal(0, _buildTopBar()),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _reveal(1, _buildHeader()),
                        _reveal(2, _buildFeaturedSummaryCard()),
                        const SizedBox(height: 16),
                        _reveal(3, _buildFilterBar()),
                        const SizedBox(height: 14),
                        _reveal(3, _buildSearchBar()),
                        const SizedBox(height: 10),
                        if (_filtered.isEmpty)
                          _reveal(4, _buildEmptyState())
                        else
                          ..._filtered.asMap().entries.map(
                                (entry) => _reveal(
                                  4 + (entry.key % 3),
                                  _buildItemCard(entry.value),
                                ),
                              ),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kCardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kTextPrimary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.categoryName,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.25,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kCardBorder),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: kTextPrimary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.categoryName,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 29,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Curate dishes, update availability, and keep the menu performance-ready.',
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 166,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3D1A05),
                      Color(0xFF6B2E08),
                      Color(0xFF5C2004),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTag('MENU HEALTH', kOrange, Colors.white),
                        const SizedBox(width: 8),
                        _buildTag(
                          '${_filtered.length} VISIBLE',
                          Colors.black.withOpacity(0.35),
                          kTextPrimary,
                          borderColor: Colors.white.withOpacity(0.22),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'Keep your best dishes in focus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMetaStat('Total', '${widget.totalItems}'),
                        const SizedBox(width: 10),
                        _buildMetaStat('Available', '$_availableCount'),
                        const SizedBox(width: 10),
                        _buildMetaStat('Hidden', '$_unavailableCount'),
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

  Widget _buildMetaStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFFE0C5A8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All Items',
              count: _demoItems.length,
              selected: _selectedFilter == ItemFilter.all,
              onTap: () => setState(() => _selectedFilter = ItemFilter.all),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'Available',
              count: _availableCount,
              selected: _selectedFilter == ItemFilter.available,
              onTap: () =>
                  setState(() => _selectedFilter = ItemFilter.available),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'Not Available',
              count: _unavailableCount,
              selected: _selectedFilter == ItemFilter.unavailable,
              onTap: () =>
                  setState(() => _selectedFilter = ItemFilter.unavailable),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searchFocused ? kOrange : kCardBorder,
            width: _searchFocused ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search_rounded,
              color: _searchFocused ? kOrange : kTextSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                cursorColor: kOrange,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search in ${widget.categoryName}...',
                  hintStyle: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  _searchFocus.unfocus();
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.close_rounded,
                    color: kTextSecondary,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(FoodItem item) {
    final isAvailable = item.status == ItemStatus.available;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(14),
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    (isAvailable ? kOrange : kGold).withOpacity(0.6),
                    (isAvailable ? kOrange : kGold).withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child:
                    Text(item.imageUrl, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: kOrange,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      _buildStatusPill(
                        label: isAvailable ? 'AVAILABLE' : 'NOT AVAILABLE',
                        dotColor: isAvailable ? kGreen : kTextSecondary,
                        borderColor: isAvailable
                            ? kGreen.withOpacity(0.35)
                            : kCardBorder,
                        textColor: isAvailable ? kGreen : kTextSecondary,
                      ),
                      if (item.tag != ItemTag.none) ...[
                        const SizedBox(width: 8),
                        _buildTagPill(item.tag),
                      ],
                      const Spacer(),
                      _buildIconButton(
                        icon: Icons.edit_rounded,
                        onTap: () {},
                        color: kTextSecondary,
                      ),
                      const SizedBox(width: 7),
                      _buildIconButton(
                        icon: Icons.delete_outline_rounded,
                        onTap: () {},
                        color: kRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color dotColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 8.8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(ItemTag tag) {
    final label = tag == ItemTag.bestseller ? 'BESTSELLER' : 'VEG';
    final color = tag == ItemTag.bestseller ? kOrange : kGold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kCardBorder),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kCardBorder),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No matching items found.',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try a different search query or switch filters.',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EditFoodItemScreen()),
          );
        },
        backgroundColor: kOrange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Add Item',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(
    String label,
    Color bg,
    Color text, {
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: borderColor == null ? null : Border.all(color: borderColor),
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
}

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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kOrange : kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kOrange : kCardBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kOrange.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
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
                    fontSize: 9,
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
