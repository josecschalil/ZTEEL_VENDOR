import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/editFoodItemScreen.dart';
import 'package:frontend/screens/foodItemDetailScreen.dart';
import 'package:frontend/app_colors.dart';

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
    imageUrl: 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=600',
    status: ItemStatus.available,
    tag: ItemTag.bestseller,
  ),
  FoodItem(
    id: '2',
    name: 'Truffle Bruschetta',
    description:
        'Toasted sourdough topped with wild mushrooms, truffle oil, and fresh herbs.',
    price: 12.00,
    imageUrl:
        'https://images.unsplash.com/photo-1572695157366-5e585ab2b69f?w=600',
    status: ItemStatus.notAvailable,
    tag: ItemTag.none,
  ),
  FoodItem(
    id: '3',
    name: 'Roasted Pumpkin Soup',
    description:
        'Velvety slow-roasted pumpkin soup with a touch of nutmeg and cream.',
    price: 10.50,
    imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',
    status: ItemStatus.available,
    tag: ItemTag.veg,
  ),
  FoodItem(
    id: '4',
    name: 'Honey-Glazed Wings',
    description:
        '6-piece jumbo wings tossed in a sweet and spicy glaze served with ranch dip.',
    price: 12.50,
    imageUrl: 'https://images.unsplash.com/photo-1562967916-eb82221dfb92?w=600',
    status: ItemStatus.available,
    tag: ItemTag.none,
  ),
  FoodItem(
    id: '5',
    name: 'Saffron Samosas',
    description:
        'Golden crispy pastry filled with spiced potato and peas, served with mint chutney.',
    price: 9.00,
    imageUrl:
        'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',
    status: ItemStatus.available,
    tag: ItemTag.veg,
  ),
  FoodItem(
    id: '6',
    name: 'Tandoori Paneer Tikka',
    description:
        'Marinated paneer cubes grilled in tandoor with bell peppers and onions.',
    price: 14.00,
    imageUrl:
        'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=600',
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
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
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
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _reveal(1, _buildFeaturedSummaryCard()),
                        const SizedBox(height: 16),
                        _reveal(2, _buildFilterBar()),
                        const SizedBox(height: 12),
                        _reveal(2, _buildSearchBar()),
                        const SizedBox(height: 16),
                        if (_filtered.isEmpty)
                          _reveal(3, _buildEmptyState())
                        else
                          _reveal(3, _buildItemGrid()),
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

  // ── Top Bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.categoryName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.orangeDim,
              border: Border.all(color: AppColors.orangeBorder, width: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.totalItems} items',
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Featured Summary Banner ───────────────────────────────────────────────
  Widget _buildFeaturedSummaryCard() {
    final heroImageUrl = _filtered.isNotEmpty
        ? _filtered.first.imageUrl
        : _demoItems.first.imageUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  heroImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: AppColors.orange),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.black.withValues(alpha: 0.18),
                        AppColors.black.withValues(alpha: 0.58),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // ── Decorative rings ──
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textWhite.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textWhite.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // ── Content ──
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTag(
                          'CATEGORY',
                          AppColors.textWhite.withValues(alpha: 0.2),
                          AppColors.textWhite,
                        ),
                        const SizedBox(width: 8),
                        _buildTag(
                          '${_filtered.length} VISIBLE',
                          AppColors.textWhite.withValues(alpha: 0.14),
                          AppColors.textWhite,
                          borderColor:
                              AppColors.textWhite.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.categoryName,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMetaStat('Total', '${widget.totalItems}'),
                        const SizedBox(width: 8),
                        _buildMetaStat('Available', '$_availableCount'),
                        const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textWhite.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textWhite.withValues(alpha: 0.18),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.textWhite.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Bar ──────────────────────────────────────────────────────────────
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
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Available',
              count: _availableCount,
              selected: _selectedFilter == ItemFilter.available,
              onTap: () =>
                  setState(() => _selectedFilter = ItemFilter.available),
            ),
            const SizedBox(width: 8),
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

  // ── Search Bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searchFocused ? AppColors.orange : AppColors.border,
            width: _searchFocused ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search_rounded,
              color: _searchFocused ? AppColors.orange : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                cursorColor: AppColors.orange,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search items in category...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
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
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Item Grid ───────────────────────────────────────────────────────────────
  Widget _buildItemGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.88,
        ),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          return _buildSquareItemCard(_filtered[index]);
        },
      ),
    );
  }

  // ── Square Item Card ────────────────────────────────────────────────────────
  Widget _buildSquareItemCard(FoodItem item) {
    final isAvailable = item.status == ItemStatus.available;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FoodItemDetailScreen(
              itemName: item.name,
              description: item.description,
              price: item.price,
              imageUrl: item.imageUrl,
              categoryName: widget.categoryName,
              isAvailable: isAvailable,
              isVeg: item.tag == ItemTag.veg,
              isBestseller: item.tag == ItemTag.bestseller,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ── Image / Emoji Top Section ──
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.surfaceRaised,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.surfaceRaised,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surfaceRaised,
                          child: const Center(
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.orange,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Tag pill top-left if present
                  if (item.tag != ItemTag.none)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildTagPill(item.tag),
                    ),
                  // Action buttons top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _buildIconButton(
                          icon: Icons.edit_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EditFoodItemScreen(),
                              ),
                            );
                          },
                          color: AppColors.textSecondary,
                          bgColor: AppColors.surface.withValues(alpha: 0.9),
                          borderColor: AppColors.border,
                        ),
                        const SizedBox(width: 4),
                        _buildIconButton(
                          icon: Icons.delete_outline_rounded,
                          onTap: () {},
                          color: AppColors.red,
                          bgColor: AppColors.surface.withValues(alpha: 0.9),
                          borderColor: AppColors.red.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Divider ──
            Container(height: 0.8, color: AppColors.border),
            // ── Card Bottom Info ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _buildStatusDotPill(isAvailable),
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

  Widget _buildStatusDotPill(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.greenDim : AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? AppColors.greenBorder : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.green : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'ON' : 'OFF',
            style: TextStyle(
              color: isAvailable ? AppColors.green : AppColors.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(ItemTag tag) {
    final isBestseller = tag == ItemTag.bestseller;
    final label = isBestseller ? 'BESTSELLER' : 'VEG';
    final textColor = isBestseller ? AppColors.orange : AppColors.green;
    final bgColor = isBestseller ? AppColors.orangeDim : AppColors.greenDim;
    final borderColor =
        isBestseller ? AppColors.orangeBorder : AppColors.greenBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
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
    required Color bgColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Icon(icon, color: color, size: 13),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No matching items found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try a different search query or switch filters.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Floating Action Button ───────────────────────────────────────────────────
  Widget _buildAddItemButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditFoodItemScreen()),
        );
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF5A4C), Color(0xFFF07B6F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.38),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: AppColors.textWhite, size: 20),
            SizedBox(width: 7),
            Text(
              'Add Item',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
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
        border: borderColor == null
            ? null
            : Border.all(color: borderColor, width: 0.5),
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

// ── Filter Chip ──────────────────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFEF5A4C), Color(0xFFF07B6F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.orange : AppColors.border,
            width: 0.8,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.3),
                    blurRadius: 10,
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
                color: selected ? AppColors.textWhite : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.textWhite.withValues(alpha: 0.22)
                    : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color:
                      selected ? AppColors.textWhite : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
