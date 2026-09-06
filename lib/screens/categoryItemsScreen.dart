import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/app_colors.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/screens/editFoodItemScreen.dart';
import 'package:frontend/screens/foodItemDetailScreen.dart';
import 'package:frontend/services/vendor_service.dart';

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

class CategoryItemsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final int totalItems;

  const CategoryItemsScreen({
    super.key,
    this.categoryId = '',
    this.categoryName = 'Category Items',
    this.totalItems = 0,
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

  List<FoodItem> _items = [];
  bool _isLoading = true;

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
      _items.where((i) => i.status == ItemStatus.available).length;

  int get _unavailableCount =>
      _items.where((i) => i.status == ItemStatus.notAvailable).length;

  List<FoodItem> get _filtered {
    Iterable<FoodItem> items = _items;

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
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    final res = await VendorService.getMenuItems(
      categoryId: widget.categoryId.isNotEmpty ? widget.categoryId : null,
    );
    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final rawList = res['data'] as List<dynamic>;
      List<FoodItem> fetched = [];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final isAvail = item['is_available'] as bool? ?? true;
          final isVeg = VendorService.parseIsVegetarian(item);
          final desc = VendorService.cleanDescription(item['description']?.toString());
          final p = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
          fetched.add(FoodItem(
            id: item['id']?.toString() ?? '',
            name: item['name']?.toString() ?? '',
            description: desc,
            price: p,
            imageUrl: ApiConfig.getImageUrl(item['image']?.toString()) ?? '',
            status: isAvail ? ItemStatus.available : ItemStatus.notAvailable,
            tag: isVeg ? ItemTag.veg : ItemTag.none,
          ));
        }
      }
      setState(() {
        _items = fetched;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleItemAvailability(FoodItem item) async {
    final newStatus = item.status != ItemStatus.available;
    final res = await VendorService.updateMenuItem(
      id: item.id,
      isAvailable: newStatus,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      _fetchItems();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newStatus ? '"${item.name}" is now available!' : '"${item.name}" is now hidden.'),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] ?? 'Failed to update availability.'),
        backgroundColor: AppColors.orangeDim,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteItem(FoodItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Item', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${item.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Delete', style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await VendorService.deleteMenuItem(item.id);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${item.name}" deleted.'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
        ));
        _fetchItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['error'] ?? 'Failed to delete item'),
          backgroundColor: AppColors.orangeDim,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
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
                  child: RefreshIndicator(
                    onRefresh: _fetchItems,
                    color: AppColors.orange,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: CircularProgressIndicator(color: AppColors.orange),
                              ),
                            )
                          else if (_filtered.isEmpty)
                            _reveal(3, _buildEmptyState())
                          else
                            _reveal(3, _buildItemGrid()),
                        ],
                      ),
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
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                border: Border.all(color: AppColors.border, width: 0.8),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary, size: 15),
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
              '${_items.length} items',
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

  // ── Featured Summary Card ─────────────────────────────────────────────────────
  Widget _buildFeaturedSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF5A4C), Color(0xFFD63A2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.textWhite.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.restaurant_rounded,
                color: AppColors.textWhite, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_items.length} items · $_availableCount available',
                  style: TextStyle(
                    color: AppColors.textWhite.withValues(alpha: 0.75),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Bar ────────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip('All (${_items.length})', ItemFilter.all),
          const SizedBox(width: 8),
          _buildFilterChip('Available ($_availableCount)', ItemFilter.available),
          const SizedBox(width: 8),
          _buildFilterChip('Hidden ($_unavailableCount)', ItemFilter.unavailable),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ItemFilter filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange : AppColors.surfaceRaised,
          border: Border.all(
            color: isSelected ? AppColors.orange : AppColors.border,
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searchFocused ? AppColors.orange : AppColors.border,
            width: _searchFocused ? 1.5 : 0.8,
          ),
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
          ),
          cursorColor: AppColors.orange,
          decoration: InputDecoration(
            hintText: 'Search food items...',
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textMuted, size: 19),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 17),
                    onPressed: () => _searchCtrl.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
    );
  }

  // ── Item Grid ─────────────────────────────────────────────────────────────────
  Widget _buildItemGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _filtered.map((item) => _buildFoodItemCard(item)).toList(),
      ),
    );
  }

  Widget _buildFoodItemCard(FoodItem item) {
    final isAvail = item.status == ItemStatus.available;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodItemDetailScreen(
                itemId: item.id,
                itemName: item.name,
                description: item.description,
                price: item.price,
                imageUrl: item.imageUrl,
                categoryId: widget.categoryId,
                categoryName: widget.categoryName,
                isAvailable: isAvail,
                isVeg: item.tag == ItemTag.veg,
                isBestseller: item.tag == ItemTag.bestseller,
              ),
            ),
          );
          if (updated == true && mounted) {
            _fetchItems();
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 76,
                  height: 76,
                  color: AppColors.surfaceRaised,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.restaurant_rounded,
                          color: AppColors.orange, size: 28),
                    ),
                  ),
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
                            item.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (item.tag == ItemTag.veg)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.greenDim,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.greenBorder, width: 0.5),
                            ),
                            child: const Text(
                              'VEG',
                              style: TextStyle(
                                color: AppColors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _toggleItemAvailability(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAvail ? AppColors.greenDim : AppColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isAvail ? AppColors.greenBorder : AppColors.border, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAvail ? Icons.check_circle_rounded : Icons.do_not_disturb_on_rounded,
                                  size: 12,
                                  color: isAvail ? AppColors.green : AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAvail ? 'Available' : 'Hidden',
                                  style: TextStyle(
                                    color: isAvail ? AppColors.green : AppColors.textMuted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditFoodItemScreen(
                                  itemId: item.id,
                                  initialCategoryId: widget.categoryId,
                                  initialName: item.name,
                                  initialPrice: item.price,
                                  initialDescription: item.description,
                                  initialIsVeg: item.tag == ItemTag.veg,
                                  initialIsAvailable: isAvail,
                                  initialImageUrl: item.imageUrl,
                                ),
                              ),
                            );
                            if (updated == true && mounted) {
                              _fetchItems();
                            }
                          },
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          tooltip: 'Edit Item',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 18),
                          onPressed: () => _deleteItem(item),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          tooltip: 'Delete Item',
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

  // ── Empty State ───────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.restaurant_menu_outlined,
                color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            const Text(
              'No food items found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap "Add Item" below to add a new dish to this category.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Floating Action Button ───────────────────────────────────────────────────
  Widget _buildAddItemButton() {
    return GestureDetector(
      onTap: () async {
        final created = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditFoodItemScreen(
              initialCategoryId: widget.categoryId,
            ),
          ),
        );
        if (created == true && mounted) {
          _fetchItems();
        }
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
}
