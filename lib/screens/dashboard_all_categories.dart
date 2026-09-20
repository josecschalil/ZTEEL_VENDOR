part of 'dashboard.dart';

// ─── Color tokens ─────────────────────────────────────────────────────────────
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
  static const emeraldBg = Color(0xFFECFDF5);
  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFEF2F2);
  static const amber = Color(0xFFF59E0B);
  static const amberBg = Color(0xFFFFFBEB);
  static const amberText = Color(0xFFB45309);
  static const amberLight = Color(0xFFFCD34D);
  static const white = Colors.white;
}

enum _CatSort { menuOrder, name, mostDishes }

enum _CatAction { open, rename, delete }

String _catCount(int n, String one, String many) => '$n ${n == 1 ? one : many}';

// ── All Categories Screen ─────────────────────────────────────────────────────
// Redesigned with square cards displaying the first food item's image as background.
class AllCategoriesScreen extends StatefulWidget {
  final List<MenuCategory> categories;
  final VoidCallback onAddCategory;
  final VoidCallback? onRefreshCategories;

  const AllCategoriesScreen({
    super.key,
    required this.categories,
    required this.onAddCategory,
    this.onRefreshCategories,
  });

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  late List<MenuCategory> _categoryList;
  _CatSort _sort = _CatSort.menuOrder;

  @override
  void initState() {
    super.initState();
    _categoryList = List.of(widget.categories);
  }

  @override
  void didUpdateWidget(covariant AllCategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories) {
      setState(() => _categoryList = List.of(widget.categories));
    }
  }

  // ── Derived data ───────────────────────────────────────────────────────────
  int get _totalDishes => _categoryList.fold<int>(0, (s, c) => s + c.itemCount);

  int get _emptyCount => _categoryList.where((c) => c.itemCount == 0).length;

  List<MenuCategory> get _visible {
    final list = List<MenuCategory>.of(_categoryList);
    int byName(MenuCategory a, MenuCategory b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    switch (_sort) {
      case _CatSort.name:
        list.sort(byName);
        break;
      case _CatSort.mostDishes:
        list.sort((a, b) {
          final c = b.itemCount.compareTo(a.itemCount);
          return c != 0 ? c : byName(a, b);
        });
        break;
      case _CatSort.menuOrder:
        break;
    }
    return list;
  }

  String _sortLabel(_CatSort s) {
    switch (s) {
      case _CatSort.menuOrder:
        return 'Menu order';
      case _CatSort.name:
        return 'A to Z';
      case _CatSort.mostDishes:
        return 'Most dishes';
    }
  }

  // ── Data Fetching ──────────────────────────────────────────────────────────
  void _triggerRefresh() => widget.onRefreshCategories?.call();

  Future<MenuCategory> _loadCategory(Map<String, dynamic> cat) async {
    final catId = cat['id']?.toString() ?? '';
    final catName = cat['name']?.toString() ?? 'Category';

    final itemRes = await VendorService.getMenuItems(categoryId: catId);
    final itemList = <MenuItem>[];

    if (itemRes['success'] == true && itemRes['data'] != null) {
      final rawItems = itemRes['data'] as List<dynamic>;
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          final p = double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
          itemList.add(MenuItem(
            id: it['id']?.toString() ?? '',
            imageUrl: ApiConfig.getImageUrl(it['image']?.toString()) ?? '',
            name: it['name']?.toString() ?? 'Food Item',
            price: '\$${p.toStringAsFixed(2)}',
            rawPrice: p,
            description:
                VendorService.cleanDescription(it['description']?.toString()),
            isVegetarian: VendorService.parseIsVegetarian(it),
            isAvailable: it['is_available'] as bool? ?? true,
          ));
        }
      }
    }

    return MenuCategory(
      id: catId,
      name: catName,
      itemCount: itemList.length,
      items: itemList,
    );
  }

  Future<void> _fetchCategoriesFromApi() async {
    final catRes = await VendorService.getMenuCategories();
    if (!mounted) return;

    if (catRes['success'] == true && catRes['data'] != null) {
      final rawList = catRes['data'] as List<dynamic>;
      final loaded = await Future.wait([
        for (final cat in rawList)
          if (cat is Map<String, dynamic>) _loadCategory(cat),
      ]);
      if (!mounted) return;

      setState(() => _categoryList = loaded);
      _triggerRefresh();
    } else {
      _showSnack(
          catRes['error']?.toString() ?? 'Could not refresh categories.');
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _openCategory(MenuCategory cat) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryItemsScreen(
          categoryId: cat.id,
          categoryName: cat.name,
          totalItems: cat.itemCount,
        ),
      ),
    );
    if (mounted) _fetchCategoriesFromApi();
  }

  Future<void> _renameCategory(MenuCategory category) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _CatRenameDialog(initial: category.name),
    );
    if (newName == null || newName == category.name) return;

    final res =
        await VendorService.updateMenuCategory(id: category.id, name: newName);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        final idx = _categoryList.indexWhere((c) => c.id == category.id);
        if (idx != -1) {
          _categoryList[idx] = MenuCategory(
            id: category.id,
            name: newName,
            itemCount: category.itemCount,
            items: category.items,
          );
        }
      });
      _showSnack('Category renamed.', success: true);
      _triggerRefresh();
    } else {
      _showSnack(res['error']?.toString() ?? 'Could not rename category.');
    }
  }

  Future<void> _deleteCategory(MenuCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CatDeleteDialog(
        name: category.name,
        dishCount: category.itemCount,
      ),
    );
    if (confirmed != true) return;

    final res = await VendorService.deleteMenuCategory(category.id);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() => _categoryList.removeWhere((c) => c.id == category.id));
      _showSnack('"${category.name}" deleted.', success: true);
      _triggerRefresh();
    } else {
      _showSnack(res['error']?.toString() ?? 'Could not delete category.');
    }
  }

  Future<void> _showActions(MenuCategory cat) async {
    HapticFeedback.selectionClick();
    final action = await showModalBottomSheet<_CatAction>(
      context: context,
      backgroundColor: _K.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _K.borderMid,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _CatMonogram(
                      name: cat.name, filled: cat.itemCount > 0, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _K.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _catCount(cat.itemCount, 'dish', 'dishes'),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _K.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _CatSheetAction(
                icon: Icons.restaurant_menu_rounded,
                title: 'Open category',
                subtitle: 'View and manage its dishes',
                onTap: () => Navigator.pop(ctx, _CatAction.open),
              ),
              const SizedBox(height: 10),
              _CatSheetAction(
                icon: Icons.edit_outlined,
                title: 'Rename',
                subtitle: 'Change how it appears on your menu',
                onTap: () => Navigator.pop(ctx, _CatAction.rename),
              ),
              const SizedBox(height: 10),
              _CatSheetAction(
                icon: Icons.delete_outline_rounded,
                title: 'Delete category',
                subtitle: cat.itemCount > 0
                    ? 'Also removes its ${_catCount(cat.itemCount, 'dish', 'dishes')}'
                    : 'This category is empty',
                danger: true,
                onTap: () => Navigator.pop(ctx, _CatAction.delete),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _CatAction.open:
        _openCategory(cat);
        break;
      case _CatAction.rename:
        _renameCategory(cat);
        break;
      case _CatAction.delete:
        _deleteCategory(cat);
        break;
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? _K.dark : _K.textSecondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final list = _visible;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _K.bg,
        body: Column(
          children: [
            _buildHero(topPadding),
            Expanded(
              child: RefreshIndicator(
                color: _K.dark,
                onRefresh: _fetchCategoriesFromApi,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      if (_categoryList.isEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildGridHeader(),
                        _buildSquareGrid(list),
                      ],
                      SizedBox(height: bottomPadding + 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero: dark rounded header with summary stats ──────────────────────────

  Widget _buildHero(double topPadding) {
    return Container(
      decoration: const BoxDecoration(
        color: _K.dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: CustomPaint(
          painter: const _CatRingsPainter(
            color: Color(0x0FFFFFFF),
            anchor: Offset(0.95, 0),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
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
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu Directory',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: widget.onAddCategory,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 9, 16, 9),
                        decoration: BoxDecoration(
                          color: _K.emerald,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _K.emerald.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                size: 18, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      _heroStat('${_categoryList.length}', 'Categories'),
                      _heroDivider(),
                      _heroStat('$_totalDishes', 'Dishes'),
                      _heroDivider(),
                      _heroStat(
                        '$_emptyCount',
                        'Empty',
                        valueColor: _emptyCount > 0 ? _K.amberLight : null,
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

  Widget _heroStat(String value, String label, {Color? valueColor}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.1,
              color: valueColor ?? Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() => Container(
      width: 1, height: 26, color: Colors.white.withValues(alpha: 0.12));

  // ─── Grid Header & Sort ───────────────────────────────────────────────────

  Widget _buildGridHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Categories',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _K.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Tap any card to view items',
                  style: TextStyle(fontSize: 11.5, color: _K.textMuted),
                ),
              ],
            ),
          ),
          _buildSortPill(),
        ],
      ),
    );
  }

  Widget _buildSortPill() {
    return PopupMenuButton<_CatSort>(
      tooltip: 'Sort',
      initialValue: _sort,
      color: _K.surface,
      elevation: 6,
      shadowColor: const Color(0x330F172A),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _K.border),
      ),
      onSelected: (s) => setState(() => _sort = s),
      itemBuilder: (_) => [
        for (final s in _CatSort.values)
          PopupMenuItem<_CatSort>(
            value: s,
            height: 44,
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: s == _sort
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: _K.emerald)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  _sortLabel(s),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: s == _sort ? FontWeight.w700 : FontWeight.w600,
                    color: _K.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        decoration: BoxDecoration(
          color: _K.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _K.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded,
                size: 14, color: _K.textSecondary),
            const SizedBox(width: 5),
            Text(
              _sortLabel(_sort),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _K.textSecondary,
              ),
            ),
            const Icon(Icons.expand_more_rounded,
                size: 16, color: _K.textMuted),
          ],
        ),
      ),
    );
  }

  // ─── Square Grid Layout ───────────────────────────────────────────────────

  Widget _buildSquareGrid(List<MenuCategory> list) {
    // We include the "Add Category" tile at the end of the grid.
    final totalCards = list.length + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.0, // Strict square cards
        ),
        itemCount: totalCards,
        itemBuilder: (context, index) {
          if (index < list.length) {
            final category = list[index];
            return _CatSquareCard(
              key: ValueKey(
                  'cat_${category.id.isNotEmpty ? category.id : category.name}_$index'),
              category: category,
              onTap: () => _openCategory(category),
              onMore: () => _showActions(category),
            );
          } else {
            return _AddCategorySquareCard(
              onTap: widget.onAddCategory,
            );
          }
        },
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
        decoration: BoxDecoration(
          color: _K.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _K.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _K.surfaceRaised,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _K.border),
              ),
              child: const Icon(Icons.category_outlined,
                  color: _K.textMuted, size: 26),
            ),
            const SizedBox(height: 16),
            const Text(
              'No categories yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _K.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Categories group your dishes, like Starters, Mains or Desserts. Create your first category to start organizing your menu.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12.5, color: _K.textMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onAddCategory,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Category',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _K.dark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Square Category Card ─────────────────────────────────────────────────────
// Uses the image of the first food item in the category as the full card background.
class _CatSquareCard extends StatelessWidget {
  final MenuCategory category;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _CatSquareCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.onMore,
  });

  String? get _firstFoodImageUrl {
    for (final item in category.items) {
      if (item.imageUrl.trim().isNotEmpty) {
        return item.imageUrl.trim();
      }
    }
    return null;
  }

  String get _firstFoodName {
    for (final item in category.items) {
      if (item.name.trim().isNotEmpty) {
        return item.name.trim();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final count = category.itemCount;
    final imageUrl = _firstFoodImageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final firstDish = _firstFoodName;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background: First Food Image OR Fallback Gradient ───────────
            if (hasImage)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackBackground(),
              )
            else
              _buildFallbackBackground(),

            // ── Dark Gradient Scrim for Readability ─────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // ── Content Overlay ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Count Badge + Action Button
                  Row(
                    children: [
                      // Dish count chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: count > 0
                              ? Colors.black.withValues(alpha: 0.5)
                              : _K.amber.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: count > 0
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.transparent,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          count > 0 ? '$count dishes' : 'Empty',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: count > 0 ? Colors.white : Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // ⋯ Actions Menu Button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onMore,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Bottom: Category Name & Subtitle Preview
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    firstDish.isNotEmpty
                        ? firstDish
                        : (count == 0 ? 'No items yet' : 'Tap to manage'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),

            // ── InkWell Ripple for whole card tap ───────────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                onLongPress: onMore,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBackground() {
    final t = category.name.trim();
    final letter =
        t.isEmpty ? '?' : String.fromCharCode(t.runes.first).toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF334155), // slate-700
            Color(0xFF0F172A), // slate-900
          ],
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

// ── Add Category Square Card ─────────────────────────────────────────────────

class _AddCategorySquareCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCategorySquareCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter:
          const _CatDashedPainter(color: _K.borderMid, radius: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _K.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _K.emeraldBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _K.emerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(Icons.add_rounded,
                      size: 22, color: _K.emerald),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add Category',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _K.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'New group',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _K.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small UI Pieces ──────────────────────────────────────────────────────────

/// Monogram tile used in action sheet header.
class _CatMonogram extends StatelessWidget {
  final String name;
  final bool filled;
  final double size;

  const _CatMonogram({
    required this.name,
    required this.filled,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    final letter =
        t.isEmpty ? '?' : String.fromCharCode(t.runes.first).toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? _K.dark : _K.surfaceRaised,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: filled ? null : Border.all(color: _K.border),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: filled ? Colors.white : _K.textMuted,
        ),
      ),
    );
  }
}

class _CatSheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback onTap;

  const _CatSheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = danger ? _K.red : _K.textPrimary;
    return Container(
      decoration: BoxDecoration(
        color: danger ? _K.redBg : _K.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: danger ? _K.red.withValues(alpha: 0.2) : _K.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: danger ? _K.surface : _K.surfaceRaised,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                        color:
                            danger ? _K.red.withValues(alpha: 0.2) : _K.border),
                  ),
                  child: Icon(icon,
                      size: 18, color: danger ? _K.red : _K.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 11.5, color: _K.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: _K.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _CatRingsPainter extends CustomPainter {
  final Color color;
  final Offset anchor;
  const _CatRingsPainter({required this.color, required this.anchor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * anchor.dx, size.height * anchor.dy);
    final base = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final f in const [0.5, 0.8, 1.1]) {
      canvas.drawCircle(center, base * f, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CatRingsPainter old) =>
      old.color != color || old.anchor != anchor;
}

class _CatDashedPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _CatDashedPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 0.75;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          inset, inset, size.width - inset * 2, size.height - inset * 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dash = 7.0;
    const gap = 5.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CatDashedPainter old) =>
      old.color != color || old.radius != radius;
}

// ── Dialogs ───────────────────────────────────────────────────────────────────

class _CatRenameDialog extends StatefulWidget {
  final String initial;
  const _CatRenameDialog({required this.initial});

  @override
  State<_CatRenameDialog> createState() => _CatRenameDialogState();
}

class _CatRenameDialogState extends State<_CatRenameDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void initState() {
    super.initState();
    _ctrl.selection =
        TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _ctrl.text.trim();
    if (t.isNotEmpty) Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    color: _K.surfaceRaised,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _K.border),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: _K.textSecondary),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Rename category',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _K.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: _K.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _K.border),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _K.textPrimary),
                cursorColor: _K.emerald,
                decoration: const InputDecoration(
                  hintText: 'Category name',
                  hintStyle: TextStyle(
                      color: _K.textMuted, fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _ctrl,
                    builder: (_, v, __) => ElevatedButton(
                      onPressed: v.text.trim().isEmpty ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _K.dark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _K.borderMid,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Save',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
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

class _CatDeleteDialog extends StatelessWidget {
  final String name;
  final int dishCount;
  const _CatDeleteDialog({required this.name, required this.dishCount});

  @override
  Widget build(BuildContext context) {
    final detail = dishCount > 0
        ? 'The ${_catCount(dishCount, 'dish', 'dishes')} inside will be removed too.'
        : 'This category is empty.';

    return Dialog(
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
                  'Delete category',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _K.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Delete "$name"? $detail This can\'t be undone.',
              style: const TextStyle(
                  fontSize: 13, color: _K.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
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
                    onPressed: () => Navigator.pop(context, true),
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
    );
  }
}
