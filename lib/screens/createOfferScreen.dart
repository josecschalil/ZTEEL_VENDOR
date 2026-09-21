import 'package:flutter/material.dart';
import 'package:frontend/services/vendor_service.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
//
// Identical tokens to offerScreen.dart, so creating an offer and browsing
// the list it feeds into read as one continuous surface.
class _Pal {
  const _Pal._();

  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const wash = Color(0xFFF1F5F9);
  static const line = Color(0xFFE2E8F0);

  static const ink = Color(0xFF0F172A);
  static const ink700 = Color(0xFF334155);
  static const ink600 = Color(0xFF475569);
  static const ink500 = Color(0xFF64748B);
  static const ink400 = Color(0xFF94A3B8);

  static const green = Color(0xFF10B981);
  static const red = Color(0xFFE11D48);

  static const cardShadow = BoxShadow(
    color: Color(0x06000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
}

enum _Target { items, categories, allMenu }

// ─── Screen ──────────────────────────────────────────────────────────────────
//
// Rebuilt around one job per section instead of one dense card holding
// everything: a live preview up top, then details, targeting, discount and
// validity as their own clearly labelled cards, with Save pinned to the
// bottom so it's always reachable while scrolling a long form.
//
// Every feature from the original screen is preserved — live menu/category
// loading, search-and-add pickers, the Items / Categories / All menu scopes,
// the 5–70% discount stepper, start/end time, day-of-week recurrence, the
// end-date picker, validation before save, and the create-offer API call.
class CreateOfferScreen extends StatefulWidget {
  final String? offerId;
  final Map<String, dynamic>? initialData;

  const CreateOfferScreen({
    super.key,
    this.offerId,
    this.initialData,
  });

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  bool get isEditing => widget.offerId != null && widget.offerId!.isNotEmpty;

  _Target _target = _Target.items;
  List<String> _allItems = [];
  List<String> _allCategories = [];
  List<Map<String, dynamic>> _menuItemsData = [];
  List<Map<String, dynamic>> _categoriesData = [];

  final List<String> _selectedItems = [];
  final List<String> _selectedCategories = [];

  bool _isLoadingData = true;
  bool _isSaving = false;

  double _discountPercent = 25;

  String _startTime = '18:00';
  String _endTime = '23:00';
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final List<bool> _days = [true, false, true, false, true, true, false];

  static const List<String> _startTimes = [
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];
  static const List<String> _endTimes = [
    '21:00',
    '22:00',
    '23:00',
    '00:00',
    '01:00',
  ];
  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    String initialTitle = 'Special Discount Offer';
    String initialDesc = 'Limited time promotional discount on selected items';

    if (widget.initialData != null) {
      final data = widget.initialData!;
      if (data['title'] != null && data['title'].toString().isNotEmpty) {
        initialTitle = data['title'].toString();
      }
      if (data['description'] != null) {
        initialDesc = data['description'].toString();
      }
      if (data['discount_percentage'] != null) {
        final d = double.tryParse(data['discount_percentage'].toString());
        if (d != null) _discountPercent = d;
      }
      if (data['ends_at'] != null) {
        try {
          _endDate = DateTime.parse(data['ends_at'].toString()).toLocal();
        } catch (_) {}
      }
      final scope = data['scope_type']?.toString();
      if (scope == 'item_set') {
        _target = _Target.items;
      } else if (scope == 'category_set') {
        _target = _Target.categories;
      } else if (scope == 'all_menu') {
        _target = _Target.allMenu;
      }
    }

    _titleController = TextEditingController(text: initialTitle);
    _descController = TextEditingController(text: initialDesc);
    _loadMenuData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadMenuData() async {
    setState(() => _isLoadingData = true);
    final itemsRes = await VendorService.getMenuItems();
    final catRes = await VendorService.getMenuCategories();
    if (!mounted) return;

    List<String> itemNames = [];
    List<Map<String, dynamic>> itemObjs = [];
    if (itemsRes['success'] == true && itemsRes['data'] != null) {
      for (final item in itemsRes['data'] as List<dynamic>) {
        if (item is Map<String, dynamic>) {
          itemNames.add(item['name']?.toString() ?? 'Food Item');
          itemObjs.add(item);
        }
      }
    }

    List<String> catNames = [];
    List<Map<String, dynamic>> catObjs = [];
    if (catRes['success'] == true && catRes['data'] != null) {
      for (final cat in catRes['data'] as List<dynamic>) {
        if (cat is Map<String, dynamic>) {
          catNames.add(cat['name']?.toString() ?? 'Category');
          catObjs.add(cat);
        }
      }
    }

    setState(() {
      _allItems = itemNames;
      _allCategories = catNames;
      _menuItemsData = itemObjs;
      _categoriesData = catObjs;
      _selectedItems.clear();
      _selectedCategories.clear();

      if (isEditing && widget.initialData != null) {
        final data = widget.initialData!;
        final targets = data['targets'] as Map<String, dynamic>?;
        final rawItemIds = (targets?['item_ids'] as List?) ?? (data['item_ids'] as List?) ?? [];
        final rawCatIds = (targets?['category_ids'] as List?) ?? (data['category_ids'] as List?) ?? [];

        final itemIdsSet = rawItemIds.map((e) => e.toString()).toSet();
        final catIdsSet = rawCatIds.map((e) => e.toString()).toSet();

        for (final item in itemObjs) {
          if (itemIdsSet.contains(item['id']?.toString())) {
            _selectedItems.add(item['name']?.toString() ?? 'Food Item');
          }
        }

        for (final cat in catObjs) {
          if (catIdsSet.contains(cat['id']?.toString())) {
            _selectedCategories.add(cat['name']?.toString() ?? 'Category');
          }
        }
      } else {
        if (itemNames.isNotEmpty) _selectedItems.add(itemNames.first);
        if (catNames.isNotEmpty) _selectedCategories.add(catNames.first);
      }
      _isLoadingData = false;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String get _targetSummary {
    switch (_target) {
      case _Target.items:
        if (_selectedItems.isEmpty) return 'No items selected';
        return _selectedItems.length == 1
            ? _selectedItems.first
            : '${_selectedItems.length} items selected';
      case _Target.categories:
        if (_selectedCategories.isEmpty) return 'No categories selected';
        return _selectedCategories.length == 1
            ? _selectedCategories.first
            : '${_selectedCategories.length} categories selected';
      case _Target.allMenu:
        return 'Whole menu';
    }
  }

  // ── Feedback ───────────────────────────────────────────────────────────────

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? _Pal.red : _Pal.ink,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(now) ? now : _endDate,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _Pal.ink,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _Pal.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _openOptionSheet({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelect,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: _Pal.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _Pal.line),
            ),
            padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _Pal.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _Pal.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ...options.map((opt) {
                  final selected = opt == current;
                  return ListTile(
                    dense: true,
                    onTap: () {
                      onSelect(opt);
                      Navigator.of(context).pop();
                    },
                    title: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? _Pal.ink : _Pal.ink700,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded,
                            color: _Pal.ink, size: 18)
                        : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSearchSelectSheet({required bool isCategory}) async {
    final source = isCategory ? _allCategories : _allItems;
    final selected = isCategory ? _selectedCategories : _selectedItems;
    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final results = source
                .where(
                    (v) => v.toLowerCase().contains(query.trim().toLowerCase()))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _Pal.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _Pal.line),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: _Pal.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      isCategory ? 'Select a category' : 'Select an item',
                      style: const TextStyle(
                        color: _Pal.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _Pal.wash,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        autofocus: true,
                        onChanged: (v) => setModalState(() => query = v),
                        style: const TextStyle(color: _Pal.ink, fontSize: 13),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: _Pal.ink400, size: 19),
                          hintText:
                              isCategory ? 'Search categories' : 'Search items',
                          hintStyle: const TextStyle(
                              color: _Pal.ink400, fontSize: 12.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 280,
                      child: results.isEmpty
                          ? const Center(
                              child: Text(
                                'No results found',
                                style: TextStyle(
                                    color: _Pal.ink500, fontSize: 12.5),
                              ),
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final label = results[index];
                                final already = selected.contains(label);
                                return ListTile(
                                  dense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  title: Text(
                                    label,
                                    style: TextStyle(
                                      color: already ? _Pal.ink : _Pal.ink700,
                                      fontWeight: already
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: already
                                      ? const Icon(Icons.check_circle_rounded,
                                          color: _Pal.green, size: 18)
                                      : const Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: _Pal.ink400,
                                          size: 18),
                                  onTap: () {
                                    setState(() {
                                      if (!selected.contains(label)) {
                                        selected.add(label);
                                      }
                                    });
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _saveOffer() async {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : '${_discountPercent.toInt()}% OFF Offer';
    final desc = _descController.text.trim();

    String scopeType = 'all_menu';
    List<String> itemIds = [];
    List<String> categoryIds = [];

    if (_target == _Target.items) {
      scopeType = 'item_set';
      for (final name in _selectedItems) {
        final obj = _menuItemsData.firstWhere(
          (m) => m['name'] == name,
          orElse: () => {},
        );
        if (obj['id'] != null) itemIds.add(obj['id'].toString());
      }
      if (itemIds.isEmpty && _allItems.isNotEmpty) {
        _toast('Select at least one menu item.', isError: true);
        return;
      }
    } else if (_target == _Target.categories) {
      scopeType = 'category_set';
      for (final name in _selectedCategories) {
        final obj = _categoriesData.firstWhere(
          (c) => c['name'] == name,
          orElse: () => {},
        );
        if (obj['id'] != null) categoryIds.add(obj['id'].toString());
      }
      if (categoryIds.isEmpty && _allCategories.isNotEmpty) {
        _toast('Select at least one category.', isError: true);
        return;
      }
    }

    final startDate = DateTime.now();
    final endDate = _endDate;

    Map<String, dynamic> offerData = {
      'title': title,
      'description': desc,
      'scope_type': scopeType,
      'discount_percentage': _discountPercent,
      'validity_type': 'date_range',
      'starts_at': startDate.toUtc().toIso8601String(),
      'ends_at': endDate.toUtc().toIso8601String(),
      'is_active': true,
    };

    if (scopeType == 'item_set' && itemIds.isNotEmpty) {
      offerData['item_ids'] = itemIds;
    }
    if (scopeType == 'category_set' && categoryIds.isNotEmpty) {
      offerData['category_ids'] = categoryIds;
    }

    setState(() => _isSaving = true);
    final Map<String, dynamic> res;
    if (isEditing) {
      res = await VendorService.updateOffer(
        id: widget.offerId!,
        data: offerData,
      );
    } else {
      res = await VendorService.createOffer(offerData);
    }
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      _toast(isEditing ? 'Offer updated successfully.' : 'Offer created successfully.');
      Navigator.of(context).pop(true);
    } else {
      _toast(
        res['error']?.toString() ??
            (isEditing ? 'Could not update the offer.' : 'Could not create the offer.'),
        isError: true,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Pal.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Preview'),
                    const SizedBox(height: 10),
                    _buildPreviewCard(),
                    const SizedBox(height: 22),
                    const _SectionLabel('Offer details'),
                    const SizedBox(height: 10),
                    _buildDetailsCard(),
                    const SizedBox(height: 18),
                    const _SectionLabel('Applies to'),
                    const SizedBox(height: 10),
                    _buildTargetCard(),
                    const SizedBox(height: 18),
                    const _SectionLabel('Discount'),
                    const SizedBox(height: 10),
                    _buildDiscountCard(),
                    const SizedBox(height: 18),
                    const _SectionLabel('Validity'),
                    const SizedBox(height: 10),
                    _buildValidityCard(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _Pal.wash,
                shape: BoxShape.circle,
                border: Border.all(color: _Pal.line),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: _Pal.ink700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit offer' : 'Create offer',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _Pal.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isEditing
                      ? 'Update promotion details'
                      : 'New promotion for your menu',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _Pal.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Live preview ───────────────────────────────────────────────────────────

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Pal.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer_rounded,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([_titleController, _descController]),
              builder: (context, _) {
                final title = _titleController.text.trim().isEmpty
                    ? 'Untitled offer'
                    : _titleController.text.trim();
                final desc = _descController.text.trim();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _PreviewChip(
                      icon: Icons.restaurant_menu_rounded,
                      label: _targetSummary,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              '${_discountPercent.toInt()}%',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Offer details ──────────────────────────────────────────────────────────

  Widget _buildDetailsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('OFFER TITLE'),
          const SizedBox(height: 6),
          _InputBox(
            child: TextField(
              controller: _titleController,
              style: const TextStyle(
                  color: _Pal.ink, fontSize: 13.5, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'e.g. Weekend special discount',
                hintStyle: TextStyle(color: _Pal.ink400, fontSize: 12.5),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('DESCRIPTION'),
          const SizedBox(height: 6),
          _InputBox(
            child: TextField(
              controller: _descController,
              maxLines: 2,
              style: const TextStyle(
                  color: _Pal.ink, fontSize: 13.5, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'e.g. Enjoy 25% off on all main course items',
                hintStyle: TextStyle(color: _Pal.ink400, fontSize: 12.5),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Target selection ───────────────────────────────────────────────────────

  Widget _buildTargetCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SegmentedTabs(
            labels: const ['Items', 'Categories', 'All menu'],
            selectedIndex: _target.index,
            onChanged: (i) => setState(() => _target = _Target.values[i]),
          ),
          const SizedBox(height: 14),
          if (_isLoadingData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: _Pal.ink),
                ),
              ),
            )
          else if (_target == _Target.items)
            _buildSelectionList(
              values: _selectedItems,
              onAdd: () => _openSearchSelectSheet(isCategory: false),
              onRemove: (v) => setState(() => _selectedItems.remove(v)),
              emptyHint: _allItems.isEmpty
                  ? 'No menu items found yet.'
                  : 'No items selected yet.',
            )
          else if (_target == _Target.categories)
            _buildSelectionList(
              values: _selectedCategories,
              onAdd: () => _openSearchSelectSheet(isCategory: true),
              onRemove: (v) => setState(() => _selectedCategories.remove(v)),
              emptyHint: _allCategories.isEmpty
                  ? 'No categories found yet.'
                  : 'No categories selected yet.',
            )
          else
            _buildAllMenuNotice(),
        ],
      ),
    );
  }

  Widget _buildSelectionList({
    required List<String> values,
    required VoidCallback onAdd,
    required ValueChanged<String> onRemove,
    required String emptyHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                values.isEmpty ? emptyHint : '${values.length} selected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: values.isEmpty ? _Pal.ink500 : _Pal.ink700,
                ),
              ),
            ),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _Pal.wash,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _Pal.line),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: _Pal.ink700),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _Pal.ink700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                    (v) => _SelectedChip(label: v, onRemove: () => onRemove(v)))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAllMenuNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Pal.wash,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _Pal.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _Pal.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _Pal.line),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: _Pal.ink700, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Whole menu selected',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _Pal.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'This offer will apply to every item and category.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: _Pal.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Discount ───────────────────────────────────────────────────────────────

  Widget _buildDiscountCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Applied to the total bill for the selected targets.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: _Pal.ink500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                onTap: () => setState(() {
                  _discountPercent =
                      (_discountPercent - 1).clamp(5, 70).toDouble();
                }),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_discountPercent.toInt()}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _Pal.ink,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'OFF TOTAL BILL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _Pal.ink400,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: () => setState(() {
                  _discountPercent =
                      (_discountPercent + 1).clamp(5, 70).toDouble();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Validity ───────────────────────────────────────────────────────────────

  Widget _buildValidityCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('START TIME'),
                    const SizedBox(height: 6),
                    _PickerField(
                      value: _startTime,
                      onTap: () => _openOptionSheet(
                        title: 'Start time',
                        options: _startTimes,
                        current: _startTime,
                        onSelect: (v) => setState(() => _startTime = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('END TIME'),
                    const SizedBox(height: 6),
                    _PickerField(
                      value: _endTime,
                      onTap: () => _openOptionSheet(
                        title: 'End time',
                        options: _endTimes,
                        current: _endTime,
                        onSelect: (v) => setState(() => _endTime = v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _FieldLabel('REPEATS ON'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final selected = _days[i];
              return GestureDetector(
                onTap: () => setState(() => _days[i] = !_days[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? _Pal.ink : _Pal.wash,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? _Pal.ink : _Pal.line,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _dayLabels[i],
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _Pal.ink500,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('ENDS ON'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickEndDate,
            child: _InputBox(
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 17, color: _Pal.ink700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(_endDate),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Pal.ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 19, color: _Pal.ink400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom action bar ──────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: _Pal.surface,
        border:
            Border(top: BorderSide(color: _Pal.line.withValues(alpha: 0.8))),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isSaving ? null : _saveOffer,
            child: Container(
              width: double.infinity,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isSaving ? _Pal.ink.withValues(alpha: 0.6) : _Pal.ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.2),
                    )
                  : Text(
                      isEditing ? 'Save changes' : 'Save offer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEditing
                ? 'Updated details will be reflected immediately.'
                : 'Changes go live for customers as soon as you save.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: _Pal.ink400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared pieces ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _Pal.ink,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Pal.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Pal.line.withValues(alpha: 0.8)),
        boxShadow: const [_Pal.cardShadow],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _Pal.ink500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final Widget child;
  const _InputBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _Pal.wash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Pal.line),
      ),
      child: child,
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _Pal.wash,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _Pal.line.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
                decoration: BoxDecoration(
                  color: selected ? _Pal.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? const <BoxShadow>[_Pal.cardShadow]
                      : const <BoxShadow>[],
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? _Pal.ink : _Pal.ink500,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _SelectedChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: _Pal.wash,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Pal.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _Pal.ink700,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 14, color: _Pal.ink400),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _Pal.wash,
          shape: BoxShape.circle,
          border: Border.all(color: _Pal.line),
        ),
        child: Icon(icon, size: 18, color: _Pal.ink700),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const _PickerField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _InputBox(
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _Pal.ink,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: _Pal.ink400),
          ],
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PreviewChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
