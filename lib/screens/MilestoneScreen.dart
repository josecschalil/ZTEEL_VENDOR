import 'package:flutter/material.dart';

// ── Design tokens ──────────────────────────────────────────────
const Color bgDark = Color(0xFF160C05);
const Color cardBg = Color(0xFF231208);
const Color fieldBg = Color(0xFF1C0E06);
const Color accent = Color(0xFFE05E20);
const Color accentLight = Color(0xFFFF7A38);
const Color textPrimary = Color(0xFFF2E0CC);
const Color textSecond = Color(0xFF8A6A50);
const Color divider = Color(0xFF321A08);
const Color navBg = Color(0xFF1A0D05);

// ── Main screen ────────────────────────────────────────────────
class MilestoneRewardsScreen extends StatefulWidget {
  const MilestoneRewardsScreen({super.key});

  @override
  State<MilestoneRewardsScreen> createState() => _MilestoneRewardsScreenState();
}

class _MilestoneRewardsScreenState extends State<MilestoneRewardsScreen> {
  bool level1Enabled = true;
  bool level2Enabled = true;
  int level1RewardType = 0; // 0=PERCENT, 1=ITEM, 2=CASH
  int level2RewardType = 1;
  double level1Percent = 15;
  double level2Percent = 10;
  final TextEditingController _level1CashCtrl =
      TextEditingController(text: '12.00');
  final TextEditingController _level2CashCtrl =
      TextEditingController(text: '20.00');
  String level1Item = 'Garlic Bread';
  String level2Item = 'Paneer Tikka';

  final List<String> _rewardItems = const [
    'Garlic Bread',
    'Paneer Tikka',
    'Saffron Samosa',
    'Butter Naan',
    'Rose Falooda',
    'Mango Lassi',
    'Mini Gulab Jamun',
    'Chili Potato Bites',
  ];

  @override
  void dispose() {
    _level1CashCtrl.dispose();
    _level2CashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildTopBar(),
                    const SizedBox(height: 28),
                    _buildPageHeader(),
                    const SizedBox(height: 28),
                    // Level 01 card
                    _buildMilestoneCard(
                      level: 'LEVEL 01',
                      enabled: level1Enabled,
                      onToggle: (v) => setState(() => level1Enabled = v),
                      spendTarget: '25.00',
                      selectedRewardType: level1RewardType,
                      onRewardTypeChanged: (i) =>
                          setState(() => level1RewardType = i),
                      rewardDetailWidget: _buildRewardDetail(
                        selectedRewardType: level1RewardType,
                        percentValue: level1Percent,
                        onPercentChanged: (v) =>
                            setState(() => level1Percent = v),
                        cashController: _level1CashCtrl,
                        selectedItem: level1Item,
                        onItemTap: () => _openItemPicker(
                          currentItem: level1Item,
                          onSelected: (item) =>
                              setState(() => level1Item = item),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Level 02 card
                    _buildMilestoneCard(
                      level: 'LEVEL 02',
                      enabled: level2Enabled,
                      onToggle: (v) => setState(() => level2Enabled = v),
                      spendTarget: '50.00',
                      selectedRewardType: level2RewardType,
                      onRewardTypeChanged: (i) =>
                          setState(() => level2RewardType = i),
                      rewardDetailWidget: _buildRewardDetail(
                        selectedRewardType: level2RewardType,
                        percentValue: level2Percent,
                        onPercentChanged: (v) =>
                            setState(() => level2Percent = v),
                        cashController: _level2CashCtrl,
                        selectedItem: level2Item,
                        onItemTap: () => _openItemPicker(
                          currentItem: level2Item,
                          onSelected: (item) =>
                              setState(() => level2Item = item),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAddMilestoneButton(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF3A1A08),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
          ),
          child: const Icon(Icons.person, color: accent, size: 24),
        ),
        const SizedBox(width: 10),
        const Text(
          'Midnight Saffron',
          style: TextStyle(
            color: accent,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: divider, width: 1),
          ),
          child:
              const Icon(Icons.notifications_outlined, color: accent, size: 20),
        ),
      ],
    );
  }

  // ── Page header ───────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestone Rewards',
          style: TextStyle(
            color: textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure automated rewards for your loyal\ncustomers based on their spend.',
          style: TextStyle(
            color: textSecond,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Milestone card ────────────────────────────────────────────
  Widget _buildMilestoneCard({
    required String level,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required String spendTarget,
    required int selectedRewardType,
    required ValueChanged<int> onRewardTypeChanged,
    required Widget rewardDetailWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: accent, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              _buildToggle(enabled, onToggle),
            ],
          ),
          const SizedBox(height: 16),

          // Spend target label
          _buildLabel('SPEND TARGET'),
          const SizedBox(height: 6),
          _buildSpendField(spendTarget),
          const SizedBox(height: 14),

          // Reward type label
          _buildLabel('REWARD TYPE'),
          const SizedBox(height: 8),
          _buildRewardTypePicker(selectedRewardType, onRewardTypeChanged),
          const SizedBox(height: 14),

          // Reward detail label
          _buildLabel('REWARD DETAIL'),
          const SizedBox(height: 8),
          rewardDetailWidget,
        ],
      ),
    );
  }

  // ── Toggle ────────────────────────────────────────────────────
  Widget _buildToggle(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? accent : const Color(0xFF3A1A08),
          border: Border.all(
            color: value ? accentLight : divider,
            width: 1,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // ── Label ─────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: textSecond,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
      ),
    );
  }

  // ── Spend field ───────────────────────────────────────────────
  Widget _buildSpendField(String amount) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider, width: 1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: '\$ ',
                style: TextStyle(
                  color: textSecond,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: amount,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reward type picker ────────────────────────────────────────
  Widget _buildRewardTypePicker(int selected, ValueChanged<int> onChanged) {
    const labels = ['PERCENT', 'ITEM', 'CASH'];
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider, width: 1),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: isSelected ? Colors.white : textSecond,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Text detail field ─────────────────────────────────────────
  Widget _buildRewardDetail({
    required int selectedRewardType,
    required double percentValue,
    required ValueChanged<double> onPercentChanged,
    required TextEditingController cashController,
    required String selectedItem,
    required VoidCallback onItemTap,
  }) {
    if (selectedRewardType == 0) {
      return _buildPercentDetail(
        value: percentValue,
        onChanged: onPercentChanged,
      );
    }
    if (selectedRewardType == 1) {
      return _buildItemDetail(
        selectedItem: selectedItem,
        onTap: onItemTap,
      );
    }
    return _buildCashDetail(controller: cashController);
  }

  Widget _buildPercentDetail({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider, width: 1),
      ),
      child: Row(
        children: [
          _stepperButton(
            icon: Icons.remove,
            onTap: () => onChanged((value - 1).clamp(1, 100).toDouble()),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${value.toInt()}% OFF TOTAL BILL',
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          _stepperButton(
            icon: Icons.add,
            onTap: () => onChanged((value + 1).clamp(1, 100).toDouble()),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF2B1409),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: divider, width: 1),
        ),
        child: Icon(icon, color: textPrimary, size: 18),
      ),
    );
  }

  Widget _buildCashDetail({required TextEditingController controller}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        decoration: const InputDecoration(
          prefixText: '\$ ',
          prefixStyle: TextStyle(
            color: textSecond,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          hintText: 'Reward cash amount',
          hintStyle: TextStyle(color: textSecond, fontSize: 13),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildItemDetail({
    required String selectedItem,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: divider, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedItem,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: textSecond, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _openItemPicker({
    required String currentItem,
    required ValueChanged<String> onSelected,
  }) async {
    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _rewardItems
                .where(
                  (item) =>
                      item.toLowerCase().contains(query.trim().toLowerCase()),
                )
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
                  border: Border.all(color: divider, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Reward Item',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: fieldBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: divider, width: 1),
                        ),
                        child: TextField(
                          autofocus: true,
                          style: const TextStyle(
                              color: textPrimary, fontSize: 13.5),
                          decoration: const InputDecoration(
                            prefixIcon:
                                Icon(Icons.search, color: textSecond, size: 18),
                            hintText: 'Search menu item',
                            hintStyle:
                                TextStyle(color: textSecond, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (v) => setModalState(() => query = v),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 260,
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching items',
                                  style: TextStyle(
                                    color: textSecond,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: divider.withOpacity(0.6),
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final selected = item == currentItem;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    title: Text(
                                      item,
                                      style: TextStyle(
                                        color: selected
                                            ? accentLight
                                            : textPrimary,
                                        fontSize: 13.5,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    trailing: selected
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: accent,
                                            size: 18,
                                          )
                                        : null,
                                    onTap: () {
                                      onSelected(item);
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

  // ── Dropdown detail ───────────────────────────────────────────
  Widget _buildDropdownDetail(String text) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: textSecond, size: 22),
        ],
      ),
    );
  }

  // ── Add milestone button ──────────────────────────────────────
  Widget _buildAddMilestoneButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withOpacity(0.5),
          width: 1.5,
          // Dashed border via custom painter
        ),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: accent.withOpacity(0.45),
          borderRadius: 12,
          dashWidth: 8,
          dashSpace: 5,
          strokeWidth: 1.5,
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: textSecond, size: 18),
              SizedBox(width: 8),
              Text(
                '+ Add Another Milestone',
                style: TextStyle(
                  color: textSecond,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'SAVE REWARDS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      _NavItem(
          icon: Icons.grid_view_rounded, label: 'DASHBOARD', active: false),
      _NavItem(
          icon: Icons.local_offer_outlined, label: 'OFFERS', active: false),
      _NavItem(icon: Icons.star_outlined, label: 'REWARDS', active: true),
      _NavItem(icon: Icons.store_outlined, label: 'VENDORS', active: false),
    ];

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) => _buildNavItem(item)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          item.icon,
          color: item.active ? accent : textSecond,
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: TextStyle(
            color: item.active ? accent : textSecond,
            fontSize: 9,
            fontWeight: item.active ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ── Data class ────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  final bool active;
  const _NavItem(
      {required this.icon, required this.label, required this.active});
}

// ── Dashed border painter ─────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
              size.width - strokeWidth, size.height - strokeWidth),
          Radius.circular(borderRadius),
        ),
      );

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final extracted = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extracted, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
