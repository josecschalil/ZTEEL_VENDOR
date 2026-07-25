part of 'dashboard.dart';

// ── All Categories Screen ────────────────────────────────────────────────────
class AllCategoriesScreen extends StatelessWidget {
  final List<MenuCategory> categories;
  final VoidCallback onAddCategory;

  const AllCategoriesScreen({
    super.key,
    required this.categories,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = categories.fold(0, (s, c) => s + c.itemCount);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        floatingActionButton: GestureDetector(
          onTap: onAddCategory,
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
              // ── Top bar ──
              Container(
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
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          border: Border.all(
                              color: AppColors.border, width: 0.8),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textSecondary, size: 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'All Categories',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.orangeDim,
                        border: Border.all(
                            color: AppColors.orangeBorder, width: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${categories.length} categories',
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Body ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Summary banner ──
                      Container(
                        margin:
                            const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                                color:
                                    AppColors.textWhite.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: AppColors.textWhite,
                                  size: 23),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Menu Categories',
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${categories.length} categories · $totalItems items total',
                                  style: TextStyle(
                                    color: AppColors.textWhite
                                        .withValues(alpha: 0.75),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ── Category list ──
                      ...categories
                          .map((cat) => _AllCategoryCard(category: cat)),
                      const SizedBox(height: 40),
                    ],
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

  const _AllCategoryCard({required this.category});

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
                    Container(
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
                              border: Border.all(
                                  color: AppColors.orangeBorder,
                                  width: 0.8),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.orangeDim,
                              border: Border.all(
                                  color: AppColors.orangeBorder,
                                  width: 0.5),
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
                    Container(height: 0.8, color: AppColors.border),
                    // Items or empty state
                    if (category.items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 18),
                        color: AppColors.surface,
                        child: const Row(
                          children: [
                            Icon(Icons.inbox_outlined,
                                color: AppColors.textMuted, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'No items added yet',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12.5),
                            ),
                          ],
                        ),
                      )
                    else
                      ...category.items.asMap().entries.map((entry) {
                        final isLast =
                            entry.key == category.items.length - 1;
                        return Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: isLast
                                ? null
                                : const Border(
                                    bottom: BorderSide(
                                        color: AppColors.border,
                                        width: 0.6)),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceRaised,
                                  border: Border.all(
                                      color: AppColors.border,
                                      width: 0.5),
                                  borderRadius:
                                      BorderRadius.circular(9),
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    color: AppColors.textSecondary,
                                    size: 14),
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