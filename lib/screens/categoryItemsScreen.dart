import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/screens/editFoodItemScreen.dart';
import 'package:frontend/screens/foodItemDetailScreen.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/app_colors.dart';

// ─── Color tokens (same palette as dashboard / profile / orders) ─────────────
// NOTE: `_K` is private to each library. If you want one source of truth,
// move this class into a shared file (e.g. theme/tokens.dart) and make it public.
class _K {
  static const bg = AppColors.bg;
  static const surface = AppColors.surface;
  static const surfaceRaised = AppColors.surfaceRaised;
  static const dark = AppColors.primaryDark;
  static const border = AppColors.border;
  static const borderMid = AppColors.borderStrong;
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
  static const textMuted = AppColors.textMuted;
  static const emerald = AppColors.success;
  static const emeraldLight = AppColors.successLight;
  static const emeraldBg = AppColors.successTint;
  static const red = AppColors.danger;
  static const redBg = AppColors.dangerTint;
  static const amber = AppColors.warning;
}

// ─── Models / enums (public API unchanged) ───────────────────────────────────

enum ItemStatus { available, notAvailable }

enum ItemTag { none, bestseller, veg }

enum ItemFilter { all, available, unavailable }

enum _CardAction { edit, delete }

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

  FoodItem copyWith({ItemStatus? status}) => FoodItem(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        status: status ?? this.status,
        tag: tag,
      );
}

// ─── Screen ──────────────────────────────────────────────────────────────────

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
  final Set<String> _busyIds = {};

  bool _searchFocused = false;
  String _query = '';
  ItemFilter _selectedFilter = ItemFilter.all;

  List<FoodItem> _items = [];
  bool _isLoading = true;

  // ── Entry animation (one calm reveal: hero → visibility card → dishes) ─────
  late final AnimationController _entryAc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final List<Animation<double>> _fades = List.generate(3, (i) {
    final start = i * 0.12;
    return CurvedAnimation(
      parent: _entryAc,
      curve:
          Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
    );
  });

  late final List<Animation<Offset>> _slides = List.generate(3, (i) {
    final start = i * 0.12;
    return Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _entryAc,
        curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic),
      ),
    );
  });

  Widget _reveal(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  // ── Derived data ───────────────────────────────────────────────────────────
  int get _availableCount =>
      _items.where((i) => i.status == ItemStatus.available).length;

  int get _unavailableCount => _items.length - _availableCount;

  bool get _isFiltering =>
      _query.trim().isNotEmpty || _selectedFilter != ItemFilter.all;

  List<FoodItem> get _filtered {
    Iterable<FoodItem> items = _items;

    if (_selectedFilter == ItemFilter.available) {
      items = items.where((i) => i.status == ItemStatus.available);
    } else if (_selectedFilter == ItemFilter.unavailable) {
      items = items.where((i) => i.status == ItemStatus.notAvailable);
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((i) =>
          i.name.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q));
    }
    return items.toList();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (mounted) setState(() => _searchFocused = _searchFocus.hasFocus);
    });
    _searchCtrl.addListener(() {
      if (_query != _searchCtrl.text) {
        setState(() => _query = _searchCtrl.text);
      }
    });
    _entryAc.forward();
    _fetchItems();
  }

  @override
  void dispose() {
    _entryAc.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────
  Future<void> _fetchItems() async {
    final res = await VendorService.getMenuItems(
      categoryId: widget.categoryId.isNotEmpty ? widget.categoryId : null,
    );
    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final rawList = res['data'] as List<dynamic>;
      final fetched = <FoodItem>[];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final isAvail = item['is_available'] as bool? ?? true;
          final isVeg = VendorService.parseIsVegetarian(item);
          final desc =
              VendorService.cleanDescription(item['description']?.toString());
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
      _showSnack(res['error']?.toString() ??
          'Could not load items. Pull down to retry.');
    }
  }

  void _replaceItem(FoodItem updated) {
    setState(() {
      final idx = _items.indexWhere((e) => e.id == updated.id);
      if (idx != -1) _items[idx] = updated;
    });
  }

  /// Optimistic toggle: the switch flips instantly, and rolls back on failure.
  Future<void> _toggleItemAvailability(FoodItem item) async {
    if (_busyIds.contains(item.id)) return;
    final makeAvailable = item.status != ItemStatus.available;

    _busyIds.add(item.id);
    _replaceItem(item.copyWith(
      status: makeAvailable ? ItemStatus.available : ItemStatus.notAvailable,
    ));
    HapticFeedback.selectionClick();

    final res = await VendorService.updateMenuItem(
      id: item.id,
      isAvailable: makeAvailable,
    );
    _busyIds.remove(item.id);
    if (!mounted) return;

    if (res['success'] == true) {
      _showSnack(
        makeAvailable
            ? '"${item.name}" is live again.'
            : '"${item.name}" is hidden from customers.',
        success: true,
      );
    } else {
      _replaceItem(item); // roll back
      _showSnack(res['error']?.toString() ?? 'Could not update availability.');
    }
  }

  Future<void> _deleteItem(FoodItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _K.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _K.redBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _K.red.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: _K.red),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delete item',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _K.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Delete "${item.name}"? This can\'t be undone.',
                style: const TextStyle(
                    fontSize: 13, color: _K.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _K.textSecondary,
                        side: const BorderSide(color: _K.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _K.red,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Delete',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final res = await VendorService.deleteMenuItem(item.id);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() => _items.removeWhere((e) => e.id == item.id));
      _showSnack('"${item.name}" deleted.', success: true);
    } else {
      _showSnack(res['error']?.toString() ?? 'Could not delete item.');
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  Future<void> _openDetail(FoodItem item) async {
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
          isAvailable: item.status == ItemStatus.available,
          isVeg: item.tag == ItemTag.veg,
          isBestseller: item.tag == ItemTag.bestseller,
        ),
      ),
    );
    if (updated == true && mounted) _fetchItems();
  }

  Future<void> _openEdit(FoodItem item) async {
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
          initialIsAvailable: item.status == ItemStatus.available,
          initialImageUrl: item.imageUrl,
        ),
      ),
    );
    if (updated == true && mounted) _fetchItems();
  }

  Future<void> _addItem() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditFoodItemScreen(initialCategoryId: widget.categoryId),
      ),
    );
    if (created == true && mounted) _fetchItems();
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() => _selectedFilter = ItemFilter.all);
  }

  void _showSnack(String msg, {bool success = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? _K.dark : _K.textSecondary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final list = _filtered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _K.bg,
        floatingActionButton: _buildFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              _reveal(0, _buildHero(top)),
              Expanded(
                child: RefreshIndicator(
                  color: _K.dark,
                  onRefresh: _fetchItems,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _reveal(
                          1,
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: _buildVisibilityCard(),
                          ),
                        ),
                        _buildSectionHeader(list.length),
                        _reveal(2, _buildContent(list)),
                        const SizedBox(height: 110), // FAB clearance
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero: title + search live together in the dark header ─────────────────

  Widget _buildHero(double top) {
    return Container(
      decoration: const BoxDecoration(
        color: _K.dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 22),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.white.withValues(alpha: 0.1)),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.white.withValues(alpha: 0.9)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white.withValues(alpha: 0.5),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant_menu_rounded,
                        size: 12, color: AppColors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      '${_items.length} dishes',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSearch(),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: _searchFocused ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchFocused
              ? _K.emeraldLight.withValues(alpha: 0.7)
              : AppColors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        textInputAction: TextInputAction.search,
        cursorColor: _K.emeraldLight,
        style: const TextStyle(
            color: AppColors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search dishes in ${widget.categoryName}',
          hintStyle: TextStyle(
            color: AppColors.white.withValues(alpha: 0.4),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(Icons.search_rounded,
              color: AppColors.white.withValues(alpha: 0.55), size: 19),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: AppColors.white.withValues(alpha: 0.6), size: 17),
                  onPressed: _searchCtrl.clear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  // ─── Visibility card: a live meter that doubles as the filter ──────────────

  Widget _buildVisibilityCard() {
    final total = _items.length;
    final live = _availableCount;
    final frac = total == 0 ? 0.0 : live / total;
    final pct = (frac * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _K.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _K.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _K.emeraldBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _K.emerald.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.visibility_outlined,
                    size: 16, color: _K.emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visible to customers',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _K.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      total == 0
                          ? 'No dishes yet'
                          : '$live of $total dishes are live',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _K.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                total == 0 ? '–' : '$pct%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: total == 0 ? _K.textMuted : _K.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _K.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _K.border),
            ),
            child: Row(
              children: [
                _buildSegment('All', total, ItemFilter.all, null),
                _buildSegment('Live', live, ItemFilter.available, _K.emerald),
                _buildSegment('Hidden', _unavailableCount,
                    ItemFilter.unavailable, _K.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
      String label, int count, ItemFilter filter, Color? dotColor) {
    final selected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _K.dark : AppColors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? (filter == ItemFilter.available
                            ? _K.emeraldLight
                            : AppColors.white.withValues(alpha: 0.6))
                        : dotColor,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.white : _K.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.6)
                      : _K.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(int shown) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Dishes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _K.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (!_isLoading)
            Text(
              _isFiltering
                  ? '$shown of ${_items.length}'
                  : '${_items.length} total',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _K.textMuted),
            ),
        ],
      ),
    );
  }

  // ─── Content (loading / empty / masonry grid) ──────────────────────────────

  Widget _buildContent(List<FoodItem> list) {
    if (_isLoading) {
      return _Pulse(
        child: _masonry(
          List.generate(4, (i) => _SkeletonTile(twoLines: i.isEven)),
        ),
      );
    }
    if (list.isEmpty) return _buildEmpty(hasItems: _items.isNotEmpty);

    return _masonry(
      list
          .map((item) => _ItemTile(
                item: item,
                onOpen: () => _openDetail(item),
                onToggle: () => _toggleItemAvailability(item),
                onEdit: () => _openEdit(item),
                onDelete: () => _deleteItem(item),
              ))
          .toList(),
    );
  }

  /// Two columns on phones, more on wider screens. Cards keep their natural
  /// height, so short and long descriptions sit together without dead space.
  Widget _masonry(List<Widget> tiles) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 600 ? 3 : 2);
      final buckets = List.generate(cols, (_) => <Widget>[]);
      for (var i = 0; i < tiles.length; i++) {
        buckets[i % cols].add(tiles[i]);
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cols; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: Column(children: buckets[i])),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildEmpty({required bool hasItems}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
        decoration: BoxDecoration(
          color: _K.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _K.border),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _K.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _K.border),
              ),
              child: Icon(
                hasItems
                    ? Icons.search_off_rounded
                    : Icons.restaurant_menu_rounded,
                color: _K.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasItems ? 'No dishes match' : 'This category is empty',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _K.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              hasItems
                  ? 'Try a different search or switch the filter back to All.'
                  : 'Add your first dish so customers can start ordering from it.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: _K.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            if (hasItems)
              OutlinedButton(
                onPressed: _clearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _K.textSecondary,
                  side: const BorderSide(color: _K.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                ),
                child: const Text('Clear filters',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              )
            else
              ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _K.dark,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                ),
                child: const Text('Add first dish',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }

  // ─── FAB: slate pill with an emerald plus ──────────────────────────────────

  Widget _buildFab() {
    return GestureDetector(
      onTap: _addItem,
      child: Container(
        height: 50,
        padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
        decoration: BoxDecoration(
          color: _K.dark,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: _K.emerald, shape: BoxShape.circle),
              child:
                  const Icon(Icons.add_rounded, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Add Item',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Item tile ───────────────────────────────────────────────────────────────
// Image-first card. Price sits on the photo, the switch sits at the bottom
// (the one action a vendor does most), and edit / delete live in a small menu.

class _ItemTile extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemTile({
    required this.item,
    required this.onOpen,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _live => item.status == ItemStatus.available;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _K.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _K.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Material(
          color: _K.surface,
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildMedia(), _buildBody()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => const Center(
        child: Icon(Icons.restaurant_rounded, color: _K.textMuted, size: 28),
      );

  Widget _buildMedia() {
    return AspectRatio(
      aspectRatio: 1.15,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: _K.surfaceRaised,
            child: item.imageUrl.isEmpty
                ? _placeholder()
                : Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  ),
          ),
          if (!_live) ...[
            Container(color: AppColors.darkSurface.withValues(alpha: 0.58)),
            Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.visibility_off_outlined,
                    size: 17, color: AppColors.white),
              ),
            ),
          ],
          // Badges
          Positioned(
            top: 8,
            left: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.tag == ItemTag.veg) const _VegMark(),
                if (item.tag == ItemTag.bestseller)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: _K.amber,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 11, color: AppColors.white),
                        SizedBox(width: 3),
                        Text('Best',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Overflow menu
          Positioned(top: 6, right: 6, child: _buildMenu()),
          // Price tag
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.darkSurface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    PopupMenuItem<_CardAction> entry(
        _CardAction v, IconData icon, String label, Color color) {
      return PopupMenuItem<_CardAction>(
        value: v,
        height: 44,
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );
    }

    return PopupMenuButton<_CardAction>(
      tooltip: 'Options',
      padding: EdgeInsets.zero,
      color: _K.surface,
      elevation: 0,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _K.border),
      ),
      onSelected: (a) => a == _CardAction.edit ? onEdit() : onDelete(),
      itemBuilder: (_) => [
        entry(_CardAction.edit, Icons.edit_outlined, 'Edit', _K.textPrimary),
        entry(
            _CardAction.delete, Icons.delete_outline_rounded, 'Delete', _K.red),
      ],
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_horiz_rounded,
            size: 18, color: _K.textPrimary),
      ),
    );
  }

  Widget _buildBody() {
    final hasDesc = item.description.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.25,
              color: _live ? _K.textPrimary : _K.textSecondary,
            ),
          ),
          if (hasDesc) ...[
            const SizedBox(height: 3),
            Text(
              item.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11.5, color: _K.textMuted, height: 1.4),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _live ? _K.emerald : _K.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _live ? 'Live' : 'Hidden',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _live ? _K.emerald : _K.textMuted,
                ),
              ),
              const Spacer(),
              _MiniToggle(value: _live, onTap: onToggle),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Small pieces ────────────────────────────────────────────────────────────

class _VegMark extends StatelessWidget {
  const _VegMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: _K.emerald, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Container(
          width: 6,
          height: 6,
          decoration:
              const BoxDecoration(color: _K.emerald, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  const _MiniToggle({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      label: 'Availability',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 38,
            height: 22,
            padding: const EdgeInsets.all(2),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? _K.emerald : _K.borderMid,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Loading skeleton ────────────────────────────────────────────────────────

class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _a = Tween<double>(begin: 0.5, end: 1.0)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _a, child: widget.child);
}

class _SkeletonTile extends StatelessWidget {
  final bool twoLines;
  const _SkeletonTile({required this.twoLines});

  Widget _bar(double factor, {double h = 10}) => FractionallySizedBox(
        widthFactor: factor,
        child: Container(
          height: h,
          decoration: BoxDecoration(
            color: _K.surfaceRaised,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _K.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _K.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          children: [
            const AspectRatio(
              aspectRatio: 1.15,
              child: ColoredBox(color: _K.surfaceRaised),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Column(
                children: [
                  _bar(0.75, h: 12),
                  const SizedBox(height: 8),
                  _bar(0.95),
                  if (twoLines) ...[const SizedBox(height: 6), _bar(0.6)],
                  const SizedBox(height: 14),
                  _bar(0.45, h: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
