import 'package:flutter/material.dart';

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  // Target Selection
  int _targetTab = 0; // 0=Items, 1=Categories, 2=All Menu
  final List<String> _allItems = const [
    'Saffron Glazed Salmon',
    'Velvet Butter Chicken',
    'Royal Lamb Biryani',
    'Tandoori Paneer Tikka',
    'Crispy Saffron Samosas',
    'Sweet Midnight Kulfi',
    'Golden Garlic Prawns',
  ];
  final List<String> _allCategories = const [
    'Starters',
    'Main Courses',
    'Desserts',
    'Beverages',
    'Chef Specials',
    'Family Meals',
  ];
  final List<String> _selectedItems = ['Saffron Glazed Salmon'];
  final List<String> _selectedCategories = ['Main Courses'];

  // Offer Discount
  double _discountPercent = 25;

  // Validity
  String _startTime = '18:00';
  String _endTime = '23:00';
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final List<bool> _days = [
    true,
    false,
    true,
    false,
    true,
    true,
    false
  ]; // M T W T F S S

  // Colors
  static const Color bgDark = Color(0xFF1A0E0A);
  static const Color cardBg = Color(0xFF251510);
  static const Color orange = Color(0xFFE8622A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9E7E72);

  double _s(BuildContext context, double value) {
    final scale = (MediaQuery.of(context).size.width / 390).clamp(0.9, 1.08);
    return value * scale;
  }

  double _fs(BuildContext context, double value) {
    final textScale = MediaQuery.of(context).textScaleFactor.clamp(0.9, 1.1);
    return _s(context, value) * textScale;
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
            colorScheme: const ColorScheme.dark(
              primary: orange,
              surface: cardBg,
              onSurface: textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
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
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3A2015)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCategory ? 'Select Category' : 'Select Item',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: _fs(context, 14),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A0E0A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          autofocus: true,
                          onChanged: (v) => setModalState(() => query = v),
                          style: TextStyle(
                            color: textWhite,
                            fontSize: _fs(context, 13),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search,
                              color: textGrey,
                              size: _s(context, 18),
                            ),
                            hintText:
                                isCategory ? 'Search category' : 'Search item',
                            hintStyle: TextStyle(
                              color: textGrey,
                              fontSize: _fs(context, 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 260,
                        child: results.isEmpty
                            ? Center(
                                child: Text(
                                  'No results found',
                                  style: TextStyle(
                                    color: textGrey,
                                    fontSize: _fs(context, 12),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  final label = results[index];
                                  final alreadySelected =
                                      selected.contains(label);
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    title: Text(
                                      label,
                                      style: TextStyle(
                                        color: alreadySelected
                                            ? orange
                                            : textWhite,
                                        fontWeight: alreadySelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: _fs(context, 13),
                                      ),
                                    ),
                                    trailing: alreadySelected
                                        ? const Icon(Icons.check_circle,
                                            color: orange, size: 18)
                                        : null,
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: _s(context, 14)),
                    _buildTopBar(),
                    SizedBox(height: _s(context, 24)),
                    _buildPageHeader(),
                    SizedBox(height: _s(context, 24)),
                    _buildTargetSelectionCard(),
                    SizedBox(height: _s(context, 14)),
                    _buildOfferTypeCard(),
                    SizedBox(height: _s(context, 14)),
                    _buildValidityCard(),
                    SizedBox(height: _s(context, 24)),
                    _buildSaveButton(),
                    SizedBox(height: _s(context, 10)),
                    Center(
                      child: Text(
                        'Changes will be visible to customers immediately after\nsaving.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: textGrey,
                            fontSize: _fs(context, 11.5),
                            height: 1.45),
                      ),
                    ),
                    SizedBox(height: _s(context, 22)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        // Logo
        Container(
          width: _s(context, 40),
          height: _s(context, 40),
          decoration: BoxDecoration(
            color: orange,
            borderRadius: BorderRadius.circular(_s(context, 11)),
          ),
          child: Icon(Icons.restaurant_menu,
              color: Colors.white, size: _s(context, 21)),
        ),
        SizedBox(width: _s(context, 10)),
        Expanded(
          child: Text(
            'SAFFRON BISTRO',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textWhite,
              fontSize: _fs(context, 15),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(width: _s(context, 10)),
        CircleAvatar(
          radius: _s(context, 17),
          backgroundColor: const Color(0xFF3D2010),
          backgroundImage: const NetworkImage(
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
          ),
        ),
      ],
    );
  }

  // ── Page Header ──────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit, color: orange, size: _s(context, 13)),
            SizedBox(width: _s(context, 6)),
            Text(
              'OFFER MANAGEMENT',
              style: TextStyle(
                color: orange,
                fontSize: _fs(context, 10.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: _s(context, 7)),
        Text(
          'Create New Offer',
          style: TextStyle(
            color: textWhite,
            fontSize: _fs(context, 27),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: _s(context, 5)),
        Text(
          'Design an irresistible promotional experience for\nyour premium clientele.',
          style: TextStyle(
            color: textGrey,
            fontSize: _fs(context, 12.5),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ── Target Selection Card ────────────────────────────────────
  Widget _buildTargetSelectionCard() {
    final tabs = ['Items', 'Categories', 'All Menu'];
    return Container(
      padding: EdgeInsets.all(_s(context, 18)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(_s(context, 16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(Icons.track_changes, color: orange, size: _s(context, 20)),
              SizedBox(width: _s(context, 9)),
              Text(
                'Target Selection',
                style: TextStyle(
                  color: textWhite,
                  fontSize: _fs(context, 17),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: _s(context, 16)),

          // Tabs
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(tabs.length, (i) {
              final selected = _targetTab == i;
              return GestureDetector(
                onTap: () => setState(() => _targetTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? orange : const Color(0xFF3A2015),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        tabs[i],
                        style: TextStyle(
                          color: selected ? Colors.white : textGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: _fs(context, 13),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: _s(context, 16)),

          if (_targetTab == 0)
            _buildSelectionListCard(
              title: 'Selected Items',
              values: _selectedItems,
              onAdd: () => _openSearchSelectSheet(isCategory: false),
              onRemove: (v) => setState(() => _selectedItems.remove(v)),
              emptyHint: 'No items selected yet',
            ),
          if (_targetTab == 1)
            _buildSelectionListCard(
              title: 'Selected Categories',
              values: _selectedCategories,
              onAdd: () => _openSearchSelectSheet(isCategory: true),
              onRemove: (v) => setState(() => _selectedCategories.remove(v)),
              emptyHint: 'No categories selected yet',
            ),
          if (_targetTab == 2) _buildAllMenuSelectedCard(),
        ],
      ),
    );
  }

  Widget _buildSelectionListCard({
    required String title,
    required List<String> values,
    required VoidCallback onAdd,
    required ValueChanged<String> onRemove,
    required String emptyHint,
  }) {
    return Container(
      padding: EdgeInsets.all(_s(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E0A),
        borderRadius: BorderRadius.circular(_s(context, 11)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textWhite,
                  fontSize: _fs(context, 13),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C180F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3A2015)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_drop_down_rounded,
                          color: orange, size: 18),
                      Text(
                        'Search & Add',
                        style: TextStyle(
                          color: orange,
                          fontSize: _fs(context, 11),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (values.isEmpty)
            Text(
              emptyHint,
              style: TextStyle(
                color: textGrey,
                fontSize: _fs(context, 12),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.map((v) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1810),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF3A2015)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        v,
                        style: TextStyle(
                          color: textWhite,
                          fontSize: _fs(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => onRemove(v),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: orange,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAllMenuSelectedCard() {
    return Container(
      padding: EdgeInsets.all(_s(context, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E0A),
        borderRadius: BorderRadius.circular(_s(context, 11)),
        border: Border.all(color: const Color(0xFF3A2015)),
      ),
      child: Row(
        children: [
          Container(
            width: _s(context, 44),
            height: _s(context, 44),
            decoration: BoxDecoration(
              color: orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu_book_rounded, color: orange, size: 22),
          ),
          SizedBox(width: _s(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Whole Menu Selected',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: _fs(context, 14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: _s(context, 2)),
                Text(
                  'Offer will apply to all items and categories.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: _fs(context, 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Offer Type Card ──────────────────────────────────────────
  Widget _buildOfferTypeCard() {
    return Container(
      padding: EdgeInsets.all(_s(context, 18)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(_s(context, 16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_outlined,
                  color: orange, size: _s(context, 20)),
              SizedBox(width: _s(context, 9)),
              Text(
                'Offer Discount',
                style: TextStyle(
                  color: textWhite,
                  fontSize: _fs(context, 17),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: _s(context, 16)),
          Container(
            padding: EdgeInsets.all(_s(context, 14)),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0E0A),
              borderRadius: BorderRadius.circular(_s(context, 11)),
              border: Border.all(color: const Color(0xFF3A2015)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Percentage Discount',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: _fs(context, 14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: orange.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: orange.withOpacity(0.4)),
                      ),
                      child: Text(
                        '${_discountPercent.toInt()}%',
                        style: TextStyle(
                          color: orange,
                          fontSize: _fs(context, 12),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _s(context, 6)),
                Text(
                  'Set the discount amount applied to selected targets.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: _fs(context, 11.5),
                  ),
                ),
                SizedBox(height: _s(context, 10)),
                Container(
                  height: _s(context, 48),
                  padding: EdgeInsets.symmetric(horizontal: _s(context, 8)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0E0A),
                    borderRadius: BorderRadius.circular(_s(context, 10)),
                    border: Border.all(color: const Color(0xFF3A2015)),
                  ),
                  child: Row(
                    children: [
                      _discountStepperButton(
                        icon: Icons.remove,
                        onTap: () => setState(() {
                          _discountPercent =
                              (_discountPercent - 1).clamp(5, 70).toDouble();
                        }),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${_discountPercent.toInt()}% OFF TOTAL BILL',
                            style: TextStyle(
                              color: textWhite,
                              fontSize: _fs(context, 13),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      _discountStepperButton(
                        icon: Icons.add,
                        onTap: () => setState(() {
                          _discountPercent =
                              (_discountPercent + 1).clamp(5, 70).toDouble();
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _discountStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _s(context, 34),
        height: _s(context, 34),
        decoration: BoxDecoration(
          color: const Color(0xFF2B1409),
          borderRadius: BorderRadius.circular(_s(context, 8)),
          border: Border.all(color: const Color(0xFF3A2015)),
        ),
        child: Icon(icon, color: textWhite, size: _s(context, 18)),
      ),
    );
  }

  // ── Validity Card ────────────────────────────────────────────
  Widget _buildValidityCard() {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final startTimes = ['16:00', '17:00', '18:00', '19:00', '20:00'];
    final endTimes = ['21:00', '22:00', '23:00', '00:00', '01:00'];

    return Container(
      padding: EdgeInsets.all(_s(context, 18)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(_s(context, 16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: orange, size: _s(context, 20)),
              SizedBox(width: _s(context, 9)),
              Text(
                'Validity',
                style: TextStyle(
                  color: textWhite,
                  fontSize: _fs(context, 17),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: _s(context, 18)),

          // Time pickers row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START TIME',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: _fs(context, 9.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _timeDropdown(_startTime, startTimes, (v) {
                      if (v != null) setState(() => _startTime = v);
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'END TIME',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: _fs(context, 9.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _timeDropdown(_endTime, endTimes, (v) {
                      if (v != null) setState(() => _endTime = v);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Recurrence
          Text(
            'RECURRENCE',
            style: TextStyle(
              color: textGrey,
              fontSize: _fs(context, 9.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final selected = _days[i];
              return GestureDetector(
                onTap: () => setState(() => _days[i] = !_days[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? orange : const Color(0xFF3A2015),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayLabels[i],
                    style: TextStyle(
                      color: selected ? Colors.white : textGrey,
                      fontSize: _fs(context, 13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Text(
            'END DATE',
            style: TextStyle(
              color: textGrey,
              fontSize: _fs(context, 9.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickEndDate,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0E0A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3A2015)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(_endDate),
                      style: TextStyle(
                        color: textWhite,
                        fontSize: _fs(context, 13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: textGrey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeDropdown(
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E0A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        onChanged: onChanged,
        isExpanded: true,
        dropdownColor: const Color(0xFF251510),
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: textGrey, size: 20),
        style: const TextStyle(
          color: textWhite,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        items: items.map((t) {
          return DropdownMenuItem(
            value: t,
            child: Text(t),
          );
        }).toList(),
      ),
    );
  }

  // ── Save Button ──────────────────────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: _s(context, 48),
        decoration: BoxDecoration(
          color: orange,
          borderRadius: BorderRadius.circular(_s(context, 12)),
        ),
        alignment: Alignment.center,
        child: Text(
          'SAVE OFFER',
          style: TextStyle(
            color: Colors.white,
            fontSize: _fs(context, 13.5),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────
}
