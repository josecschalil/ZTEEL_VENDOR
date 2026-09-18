part of 'dashboard.dart';

// ── All Categories Screen ────────────────────────────────────────────────────
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

  @override
  void initState() {
    super.initState();
    _categoryList = List.of(widget.categories);
  }

  @override
  void didUpdateWidget(covariant AllCategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories) {
      setState(() {
        _categoryList = List.of(widget.categories);
      });
    }
  }

  void _triggerRefresh() {
    widget.onRefreshCategories?.call();
  }

  Future<void> _fetchCategoriesFromApi() async {
    final catRes = await VendorService.getMenuCategories();
    if (!mounted) return;

    if (catRes['success'] == true && catRes['data'] != null) {
      final rawList = catRes['data'] as List<dynamic>;
      List<MenuCategory> categoryList = [];

      for (final cat in rawList) {
        if (cat is Map<String, dynamic>) {
          final catId = cat['id']?.toString() ?? '';
          final catName = cat['name']?.toString() ?? 'Category';

          final itemRes = await VendorService.getMenuItems(categoryId: catId);
          List<MenuItem> itemList = [];

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
                  description: VendorService.cleanDescription(it['description']?.toString()),
                  isVegetarian: VendorService.parseIsVegetarian(it),
                  isAvailable: it['is_available'] as bool? ?? true,
                ));
              }
            }
          }

          categoryList.add(MenuCategory(
            id: catId,
            name: catName,
            itemCount: itemList.length,
            items: itemList,
          ));
        }
      }

      setState(() {
        _categoryList = categoryList;
      });
      _triggerRefresh();
    }
  }

  Future<void> _showEditCategoryDialog(MenuCategory category) async {
    final controller = TextEditingController(text: category.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Category', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Category Name',
            labelStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('Save', style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final newName = controller.text.trim();
      final res = await VendorService.updateMenuCategory(id: category.id, name: newName);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Category updated!'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
        ));
        _triggerRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['error'] ?? 'Failed to update category'),
          backgroundColor: AppColors.orangeDim,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _confirmDeleteCategory(MenuCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Category', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${category.name}"? All food items inside this category will also be deleted.',
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
      final res = await VendorService.deleteMenuCategory(category.id);
      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _categoryList.removeWhere((c) => c.id == category.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Category "${category.name}" deleted.'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
        ));
        _triggerRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['error'] ?? 'Cannot delete category.'),
          backgroundColor: AppColors.orangeDim,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _categoryList.fold(0, (s, c) => s + c.itemCount);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        floatingActionButton: GestureDetector(
          onTap: widget.onAddCategory,
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
                  'Add Category',
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
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppTopBar(
                title: 'All Categories',
                showBackButton: true,
                badgeText: '${_categoryList.length} categories',
              ),
              // ── Body ──
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.orange,
                  onRefresh: _fetchCategoriesFromApi,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Summary banner ──
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFEF5A4C),
                                Color(0xFFD63A2C),
                              ],
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
                                child: const Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: AppColors.textWhite,
                                    size: 23),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Menu Categories',
                                      style: TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_categoryList.length} categories setup · $totalItems total items',
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
                        ),
                        const SizedBox(height: 20),
                        // ── Category list ──
                        if (_categoryList.isEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Text(
                                'No categories added yet. Tap "Add Category" below to create one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ..._categoryList.map((cat) => _AllCategoryCard(
                                category: cat,
                                onEdit: () => _showEditCategoryDialog(cat),
                                onDelete: () => _confirmDeleteCategory(cat),
                                onTap: () async {
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
                                  _fetchCategoriesFromApi();
                                },
                              )),
                        const SizedBox(height: 40),
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
}

// ── Individual category card ─────────────────────────────────────────────────
class _AllCategoryCard extends StatelessWidget {
  final MenuCategory category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const _AllCategoryCard({
    required this.category,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 0.8),
        borderRadius: BorderRadius.circular(20),
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left gradient accent strip
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEF5A4C), Color(0xFFF07B6F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    // Header
                    InkWell(
                      onTap: onTap,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: AppColors.surfaceRaised,
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.orangeTint,
                                border: Border.all(color: AppColors.orangeBorder, width: 0.8),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: AppColors.orange,
                                  size: 17),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category.name,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (onEdit != null)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
                                onPressed: onEdit,
                                tooltip: 'Edit Category',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            if (onDelete != null)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 18),
                                onPressed: onDelete,
                                tooltip: 'Delete Category',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.orangeDim,
                                border: Border.all(color: AppColors.orangeBorder, width: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${category.itemCount} items',
                                style: const TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(height: 0.8, color: AppColors.border),
                    // Items or empty state
                    if (category.items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                        color: AppColors.surface,
                        child: const Row(
                          children: [
                            Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'No items added yet',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                            ),
                          ],
                        ),
                      )
                    else
                      ...category.items.asMap().entries.map((entry) {
                        final isLast = entry.key == category.items.length - 1;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: isLast
                                ? null
                                : const Border(
                                    bottom: BorderSide(color: AppColors.border, width: 0.6)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  color: AppColors.surfaceRaised,
                                  child: Image.network(
                                    entry.value.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.surfaceRaised,
                                        child: const Center(
                                          child: Icon(
                                            Icons.restaurant_rounded,
                                            color: AppColors.orange,
                                            size: 18,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.value.name,
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      entry.value.price,
                                      style: const TextStyle(
                                        color: AppColors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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