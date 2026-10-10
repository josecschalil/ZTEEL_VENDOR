import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/screens/editFoodItemScreen.dart';
import 'package:frontend/screens/foodItemDetailScreen.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/services/vendor_cache_service.dart';

// ─── Color tokens (same palette as dashboard / profile / orders) ─────────────
// NOTE: `_K` is private to each library. If you want one source of truth,
// move this class into a shared file (e.g. theme/tokens.dart) and make it public.
class _K {
  static const bg = Color(0xFFF8FAFC); // slate-50
  static const surface = Colors.white;
  static const surfaceRaised = Color(0xFFF1F5F9); // slate-100
  static const dark = Color(0xFF0F172A); // slate-900
  static const border = Color(0xFFE2E8F0); // slate-200
  static const borderMid = Color(0xFFCBD5E1); // slate-300
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B); // slate-500
  static const textMuted = Color(0xFF94A3B8); // slate-400
  static const emerald = Color(0xFF10B981);
  static const emeraldLight = Color(0xFF6EE7B7);
  static const emeraldBg = Color(0xFFECFDF5);
  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFEF2F2);
  static const amber = Color(0xFFF59E0B);
}

// ─── Models / enums (public API unchanged) ───────────────────────────────────

enum ItemStatus { available, notAvailable }

enum ItemFilter { all, available, unavailable }

enum _CardAction { edit, delete }

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final ItemStatus status;
  final bool isVeg;
  final bool isBestseller;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.status = ItemStatus.available,
    this.isVeg = false,
    this.isBestseller = false,
  });

  FoodItem copyWith({ItemStatus? status}) => FoodItem(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        status: status ?? this.status,
        isVeg: isVeg,
        isBestseller: isBestseller,
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
  bool _cacheRefreshScheduled = false;

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
    VendorCacheService.revision.addListener(_onCacheRevision);
  }

  @override
  void dispose() {
    _entryAc.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    VendorCacheService.revision.removeListener(_onCacheRevision);
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────
  void _onCacheRevision() {
    if (_cacheRefreshScheduled) return;
    _cacheRefreshScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      _cacheRefreshScheduled = false;
      if (mounted) _fetchItems();
    });
  }

  Future<void> _fetchItems({bool forceRefresh = false}) async {
    final res = await VendorService.getMenuItems(
      categoryId: widget.categoryId.isNotEmpty ? widget.categoryId : null,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final rawList = res['data'] as List<dynamic>;
      final fetched = <FoodItem>[];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final isAvail = item['is_available'] as bool? ?? true;
          final isVeg = VendorService.parseIsVegetarian(item);
          final isBestseller = item['is_bestseller'] as bool? ?? false;
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
            isVeg: isVeg,
            isBestseller: isBestseller,
          ));
        }
      }
      setState(() {
        _items = fetched.map((serverItem) {
          if (_busyIds.contains(serverItem.id)) {
            // Keep the optimistic local state while the API call is in flight
            return _items.firstWhere((e) => e.id == serverItem.id,
                orElse: () => serverItem);
          }
          return serverItem;
        }).toList();
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

    if (res['success'] != true) {
      _replaceItem(item); // roll back
      _showSnack(res['error']?.toString() ?? 'Could not update availability.');
    } else {
      // Force refresh to pull the updated state from the server and prevent stale cache flip-flops
      _fetchItems(forceRefresh: true);
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
                        foregroundColor: Colors.white,
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
          isVeg: item.isVeg,
          isBestseller: item.isBestseller,
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
          initialIsVeg: item.isVeg,
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

    return Scaffold(
      backgroundColor: _K.bg,
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          color: _K.dark,
          onRefresh: () => _fetchItems(forceRefresh: true),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryHeroDelegate(
                  topPadding: top,
                  expandedHeight: top + 130.0,
                  collapsedHeight: top + 64.0,
                  builder: (context, shrinkOffset, progress) {
                    return _buildHeroAnim(top, progress);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _reveal(
                  1,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildVisibilityCard(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader(list.length),
              ),
              SliverToBoxAdapter(
                child: _reveal(2, _buildContent(list)),
              ),
              SliverToBoxAdapter(
                child:
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAnim(double top, double progress) {
    final bgColor = Color.lerp(_K.dark, Colors.white, progress)!;
    final titleOpacity = (1.0 - (progress * 2)).clamp(0.0, 1.0);

    // Search bar background: dark translucent -> iOS light grey
    final searchBg = Color.lerp(
        _searchFocused
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.02),
        const Color(0xFFF2F2F7),
        progress)!;

    // Search bar border: subtle white -> transparent
    final searchBorder = Color.lerp(
        _searchFocused
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        Colors.transparent,
        progress)!;

    final searchTextColor = Color.lerp(Colors.white, _K.textPrimary, progress)!;
    final searchHintColor = Color.lerp(
        Colors.white.withValues(alpha: 0.8), _K.textMuted, progress)!;
    final searchIconColor = Color.lerp(
        Colors.white.withValues(alpha: 0.75), _K.textMuted, progress)!;
    final backIconColor =
        Color.lerp(Colors.white.withValues(alpha: 0.9), _K.dark, progress)!;
    final backBgColor = Color.lerp(
        Colors.white.withValues(alpha: 0.1), Colors.transparent, progress)!;
    final backBorderColor = Color.lerp(
        Colors.white.withValues(alpha: 0.1), Colors.transparent, progress)!;

    final radius = Radius.circular(lerpDouble(36, 0, progress)!);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.only(bottomLeft: radius, bottomRight: radius),
        // Just a very subtle 1px border at the bottom when scrolled, rather than shadow, for a clean appbar
        border: progress > 0.9
            ? Border(bottom: BorderSide(color: _K.border, width: 0.5))
            : null,
        boxShadow: progress > 0.9
            ? []
            : [
                const BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 20,
                    offset: Offset(0, 8))
              ],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 10, 20, 10),
      child: Stack(
        children: [
          // Row with Title and Back button (Fades out)
          Opacity(
            opacity: titleOpacity,
            child: Row(
              children: [
                const SizedBox(width: 54), // Spacing for back button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5),
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
                          color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu_rounded,
                          size: 12, color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        ' dishes',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar (Slides up and expands, shrinks right side to make room for Cancel)
          Positioned(
            left: lerpDouble(0, 48, progress),
            right: lerpDouble(0, 68, progress),
            top: lerpDouble(58, 3, progress),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius:
                    BorderRadius.circular(10), // Standard slightly rounded pill
                border: Border.all(color: searchBorder, width: 1.2),
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                cursorColor: const Color(0xFF475569), // Strict slate-600
                style: TextStyle(
                    color: searchTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search for Menu Items',
                  hintStyle: TextStyle(
                      color: searchHintColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: searchIconColor, size: 19),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.cancel,
                              color: searchIconColor.withValues(alpha: 0.5),
                              size: 18),
                          onPressed: _searchCtrl.clear,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 36, minHeight: 36),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: lerpDouble(12, 8, progress)!),
                ),
              ),
            ),
          ),

          // Cancel Button (Fades in)
          Positioned(
            right: 0,
            top: lerpDouble(58, 3, progress),
            child: Opacity(
              opacity: progress,
              child: IgnorePointer(
                ignoring: progress < 0.5,
                child: SizedBox(
                  height: 36, // Match the search bar height
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      _searchCtrl.clear();
                      _searchFocus.unfocus();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: const Color(0xFF475569), // Strict slate-600
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Back Button (Always stays, but changes colors)
          Positioned(
            left:
                -8, // Slight alignment correction to match standard iOS spacing
            top: 2,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: backBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: backBorderColor),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: backIconColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
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
            color: selected ? _K.dark : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                        color: Color(0x260F172A),
                        blurRadius: 8,
                        offset: Offset(0, 3))
                  ]
                : null,
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
                            : Colors.white.withValues(alpha: 0.6))
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
                  color: selected ? Colors.white : _K.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.6)
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
                  foregroundColor: Colors.white,
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
          boxShadow: [
            BoxShadow(
              color: _K.dark.withValues(alpha: 0.30),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded,
                  color: _K.textPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Add Item',
              style: TextStyle(
                color: Colors.white,
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
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
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
            Container(color: _K.dark.withValues(alpha: 0.58)),
            Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.visibility_off_outlined,
                    size: 17, color: Colors.white),
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
                if (item.isVeg) const _VegMark(),
                if (item.isBestseller)
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
                        Icon(Icons.star_rounded, size: 11, color: Colors.white),
                        SizedBox(width: 3),
                        Text('Best',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
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
                color: _K.dark.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
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
      elevation: 6,
      shadowColor: const Color(0x330F172A),
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
          color: Colors.white.withValues(alpha: 0.92),
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
        color: Colors.white.withValues(alpha: 0.95),
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 3,
                      offset: Offset(0, 1)),
                ],
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

class _CategoryHeroDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final Widget Function(
      BuildContext context, double shrinkOffset, double progress) builder;
  final double expandedHeight;
  final double collapsedHeight;

  _CategoryHeroDelegate({
    required this.topPadding,
    required this.builder,
    required this.expandedHeight,
    required this.collapsedHeight,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (maxExtent == minExtent)
        ? 0.0
        : (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return SizedBox.expand(
      child: builder(context, shrinkOffset, progress),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant _CategoryHeroDelegate oldDelegate) => true;
}
