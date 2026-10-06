import 'package:flutter/material.dart';
import 'package:frontend/services/vendor_service.dart';

// ─── Color tokens (same as profile / orders / categories screens) ────────────
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
  static const red = Color(0xFFE11D48);
  static const white = Colors.white;
  static const transparent = Colors.transparent;
}

class _MilestoneData {
  String? id;
  bool enabled;
  final TextEditingController spendCtrl;
  int rewardType; // 0=PERCENT, 1=ITEM, 2=CASH
  double percent;
  final TextEditingController cashCtrl;
  String selectedItem;
  String? selectedItemId;

  _MilestoneData({
    this.id,
    required this.enabled,
    required this.spendCtrl,
    required this.rewardType,
    required this.percent,
    required this.cashCtrl,
    required this.selectedItem,
    this.selectedItemId,
  });

  void dispose() {
    spendCtrl.dispose();
    cashCtrl.dispose();
  }
}

// ── Main screen ─────────────────────────────────────────────────────────────
class MilestoneRewardsScreen extends StatefulWidget {
  const MilestoneRewardsScreen({super.key});

  @override
  State<MilestoneRewardsScreen> createState() => _MilestoneRewardsScreenState();
}

class _MilestoneRewardsScreenState extends State<MilestoneRewardsScreen> {
  List<Map<String, dynamic>> _menuItems = [];
  List<String> _rewardItems = [];
  List<_MilestoneData> _milestones = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final m in _milestones) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final itemsRes = await VendorService.getMenuItems();
    final milestonesRes = await VendorService.getRewardMilestones();

    List<Map<String, dynamic>> itemObjs = [];
    List<String> itemNames = [];
    if (itemsRes['success'] == true && itemsRes['data'] != null) {
      for (final item in itemsRes['data'] as List<dynamic>) {
        if (item is Map<String, dynamic>) {
          itemObjs.add(item);
          itemNames.add(item['name']?.toString() ?? 'Food Item');
        }
      }
    }

    List<_MilestoneData> loaded = [];
    if (milestonesRes['success'] == true && milestonesRes['data'] != null) {
      final rawList = milestonesRes['data'] as List<dynamic>;
      for (int i = 0; i < rawList.length; i++) {
        final m = rawList[i];
        if (m is Map<String, dynamic>) {
          final id = m['id']?.toString();
          final isActive = m['is_active'] as bool? ?? true;
          final threshold = m['threshold_amount']?.toString() ?? '25.00';
          final discountType = m['discount_type']?.toString() ?? 'none';
          final discountValStr = m['discount_value']?.toString() ?? '0';
          final discountVal = double.tryParse(discountValStr) ?? 0.0;
          final hasFreeItem = m['has_free_item'] as bool? ?? false;

          int type = 0;
          double percent = 15;
          String cash = '10.00';
          String itemName = itemNames.isNotEmpty ? itemNames.first : 'Free Item';
          String? itemId;

          if (hasFreeItem) {
            type = 1; // ITEM
            final options = m['reward_options'] as List<dynamic>?;
            if (options != null && options.isNotEmpty) {
              final firstOpt = options.first as Map<String, dynamic>?;
              itemId = firstOpt?['menu_item_id']?.toString() ?? firstOpt?['id']?.toString();
              final name = firstOpt?['name']?.toString();
              if (name != null && name.isNotEmpty) {
                itemName = name;
              } else if (itemId != null) {
                final match = itemObjs.firstWhere(
                  (it) => it['id']?.toString() == itemId,
                  orElse: () => {},
                );
                if (match['name'] != null) itemName = match['name'].toString();
              }
            }
          } else if (discountType == 'flat') {
            type = 2; // CASH
            cash = discountVal.toStringAsFixed(2);
          } else {
            type = 0; // PERCENT
            percent = discountVal > 0 ? discountVal : 15;
          }

          loaded.add(_MilestoneData(
            id: id,
            enabled: isActive,
            spendCtrl: TextEditingController(text: threshold),
            rewardType: type,
            percent: percent,
            cashCtrl: TextEditingController(text: cash),
            selectedItem: itemName,
            selectedItemId: itemId,
          ));
        }
      }
    }


    if (!mounted) return;
    setState(() {
      _menuItems = itemObjs;
      _rewardItems = itemNames.isNotEmpty
          ? itemNames
          : const [
              'Garlic Bread',
              'Paneer Tikka',
              'Saffron Samosa',
              'Butter Naan',
              'Rose Falooda',
              'Mango Lassi',
              'Mini Gulab Jamun',
              'Chili Potato Bites',
            ];
      _milestones = loaded;
      _isLoading = false;
    });
  }

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
        backgroundColor: isError ? _K.red : _K.dark,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addMilestone() {
    double nextTarget = 75.00;
    if (_milestones.isNotEmpty) {
      final lastVal = double.tryParse(_milestones.last.spendCtrl.text.trim()) ?? 50.0;
      nextTarget = lastVal + 25.0;
    }
    final nextLevelNum = _milestones.length + 1;
    final defaultItem = _rewardItems.isNotEmpty ? _rewardItems.first : 'Reward Item';
    final defaultItemId = _menuItems.isNotEmpty ? _menuItems.first['id']?.toString() : null;

    setState(() {
      _milestones.add(_MilestoneData(
        enabled: true,
        spendCtrl: TextEditingController(text: nextTarget.toStringAsFixed(2)),
        rewardType: 0,
        percent: 15,
        cashCtrl: TextEditingController(text: '15.00'),
        selectedItem: defaultItem,
        selectedItemId: defaultItemId,
      ));
    });
    _toast('Added LEVEL ${nextLevelNum.toString().padLeft(2, '0')}');
  }

  Future<void> _deleteMilestone(int index) async {
    final m = _milestones[index];
    if (m.id == null || m.id!.isEmpty) {
      setState(() {
        _milestones.removeAt(index);
      });
      return;
    }

    setState(() => _isLoading = true);
    final res = await VendorService.deleteRewardMilestone(m.id!);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _milestones.removeAt(index);
      });
      _toast('Milestone deleted.');
    } else {
      _toast(res['error']?.toString() ?? 'Failed to delete milestone.', isError: true);
    }
  }

  Future<void> _saveRewards() async {
    if (_milestones.isEmpty) return;

    final thresholds = <double>[];
    for (int i = 0; i < _milestones.length; i++) {
      final m = _milestones[i];
      final spend = double.tryParse(m.spendCtrl.text.trim());
      if (spend == null || spend <= 0) {
        _toast(
          'Please enter a valid spend target for LEVEL ${(i + 1).toString().padLeft(2, '0')}.',
          isError: true,
        );
        return;
      }
      if (thresholds.isNotEmpty && spend <= thresholds.last) {
        _toast(
          'Spend targets must be ascending. LEVEL ${(i + 1).toString().padLeft(2, '0')} must be greater than previous levels.',
          isError: true,
        );
        return;
      }
      thresholds.add(spend);

      if (m.rewardType == 1) {
        if (m.selectedItemId == null || m.selectedItemId!.isEmpty) {
          _toast(
            'Please select a valid menu item for LEVEL ${(i + 1).toString().padLeft(2, '0')}.',
            isError: true,
          );
          return;
        }
      } else if (m.rewardType == 2) {
        final cash = double.tryParse(m.cashCtrl.text.trim());
        if (cash == null || cash <= 0) {
          _toast(
            'Please enter a valid cash discount for LEVEL ${(i + 1).toString().padLeft(2, '0')}.',
            isError: true,
          );
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    bool allSuccess = true;
    String? firstError;

    for (int i = 0; i < _milestones.length; i++) {
      final m = _milestones[i];
      final spend = double.parse(m.spendCtrl.text.trim());
      final levelName = 'Level ${(i + 1).toString().padLeft(2, '0')} Milestone';

      Map<String, dynamic> payload = {
        'name': levelName,
        'threshold_amount': spend,
        'is_active': m.enabled,
      };

      if (m.rewardType == 0) {
        payload['discount_type'] = 'percent';
        payload['discount_value'] = m.percent;
        payload['has_free_item'] = false;
        payload['reward_option_item_ids'] = [];
      } else if (m.rewardType == 1) {
        payload['discount_type'] = 'none';
        payload['discount_value'] = 0;
        payload['has_free_item'] = true;
        if (m.selectedItemId != null) {
          payload['reward_option_item_ids'] = [m.selectedItemId!];
        }
      } else {
        final cashVal = double.parse(m.cashCtrl.text.trim());
        payload['discount_type'] = 'flat';
        payload['discount_value'] = cashVal;
        payload['has_free_item'] = false;
        payload['reward_option_item_ids'] = [];
      }

      final Map<String, dynamic> res;
      if (m.id != null && m.id!.isNotEmpty) {
        res = await VendorService.updateRewardMilestone(id: m.id!, data: payload);
      } else {
        res = await VendorService.createRewardMilestone(payload);
        if (res['success'] == true && res['data'] != null && res['data']['id'] != null) {
          m.id = res['data']['id'].toString();
        }
      }

      if (res['success'] != true) {
        allSuccess = false;
        firstError = res['error']?.toString() ??
            'Failed to save Level ${(i + 1).toString().padLeft(2, '0')}';
        break;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (allSuccess) {
      _toast('Milestone rewards saved successfully.');
      Navigator.of(context).pop(true);
    } else {
      _toast(firstError ?? 'Could not save some milestones.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final activeCount = _milestones.length;

    return Scaffold(
      backgroundColor: _K.bg,
      body: Column(
        children: [
          _buildHeroTopBar(topPadding, activeCount),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _K.dark,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(_milestones.length, (index) {
                          final m = _milestones[index];
                          final levelLabel =
                              'LEVEL ${(index + 1).toString().padLeft(2, '0')}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildMilestoneCard(
                              level: levelLabel,

                              onDelete: () => _deleteMilestone(index),
                              spendController: m.spendCtrl,
                              selectedRewardType: m.rewardType,
                              onRewardTypeChanged: (i) =>
                                  setState(() => m.rewardType = i),
                              rewardDetailWidget: _buildRewardDetail(
                                selectedRewardType: m.rewardType,
                                percentValue: m.percent,
                                onPercentChanged: (v) =>
                                    setState(() => m.percent = v),
                                cashController: m.cashCtrl,
                                selectedItem: m.selectedItem,
                                onItemTap: () => _openItemPicker(
                                  currentItem: m.selectedItem,
                                  onSelected: (item, itemId) => setState(() {
                                    m.selectedItem = item;
                                    m.selectedItemId = itemId;
                                  }),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 2),
                        _buildAddMilestoneButton(),
                        const SizedBox(height: 22),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Dark hero top bar (matches profile / orders / categories) ───────────

  Widget _buildHeroTopBar(double topPadding, int activeCount) {
    return Container(
      decoration: const BoxDecoration(
        color: _K.dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      padding: EdgeInsets.only(
          top: topPadding + 20, left: 20, right: 20, bottom: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiered Customer Rewards',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.4),
                ),
                const Text(
                  'Milestone Rewards',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _K.emerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _K.emerald.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                              color: _K.emerald, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(
                        '$activeCount active levels',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _K.emeraldLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.star_outline_rounded,
                size: 18, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  // ─── Milestone card ─────────────────────────────────────────────────────

  Widget _buildMilestoneCard({
    required String level,
    required VoidCallback onDelete,
    required TextEditingController spendController,
    required int selectedRewardType,
    required ValueChanged<int> onRewardTypeChanged,
    required Widget rewardDetailWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _K.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _K.border, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _K.surfaceRaised,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _K.borderMid),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    color: _K.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: _K.textSecondary),
                onPressed: onDelete,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildLabel('SPEND TARGET'),
          const SizedBox(height: 6),
          _buildSpendField(spendController),
          const SizedBox(height: 14),

          _buildLabel('REWARD TYPE'),
          const SizedBox(height: 8),
          _buildRewardTypePicker(selectedRewardType, onRewardTypeChanged),
          const SizedBox(height: 14),

          _buildLabel('REWARD DETAIL'),
          const SizedBox(height: 8),
          rewardDetailWidget,
        ],
      ),
    );
  }

  // ─── Toggle — slate-900 fill when active ─────────────────────────────────



  // ─── Label ────────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _K.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
      ),
    );
  }

  // ─── Spend field ────────────────────────────────────────────────────────

  Widget _buildSpendField(TextEditingController controller) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _K.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _K.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        cursorColor: _K.emerald,
        style: const TextStyle(
          color: _K.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          prefixText: '\$ ',
          prefixStyle: TextStyle(
            color: _K.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          hintText: '0.00',
          hintStyle: TextStyle(color: _K.textMuted, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ─── Reward type picker — slate-900 selected pill ──────────────────────────

  Widget _buildRewardTypePicker(int selected, ValueChanged<int> onChanged) {
    const labels = ['PERCENT', 'ITEM', 'CASH'];
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: _K.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _K.border, width: 1),
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
                  color: isSelected ? _K.dark : _K.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: isSelected ? _K.white : _K.textSecondary,
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

  // ─── Reward detail dispatcher ─────────────────────────────────────────────

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
          value: percentValue, onChanged: onPercentChanged);
    }
    if (selectedRewardType == 1) {
      return _buildItemDetail(selectedItem: selectedItem, onTap: onItemTap);
    }
    return _buildCashDetail(controller: cashController);
  }

  Widget _buildPercentDetail(
      {required double value, required ValueChanged<double> onChanged}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _K.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _K.border, width: 1),
      ),
      child: Row(
        children: [
          _stepperButton(
              icon: Icons.remove,
              onTap: () => onChanged((value - 1).clamp(1, 100).toDouble())),
          Expanded(
            child: Center(
              child: Text(
                '${value.toInt()}% OFF TOTAL BILL',
                style: const TextStyle(
                  color: _K.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          _stepperButton(
              icon: Icons.add,
              onTap: () => onChanged((value + 1).clamp(1, 100).toDouble())),
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
          color: _K.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _K.border, width: 1),
        ),
        child: Icon(icon, color: _K.textPrimary, size: 18),
      ),
    );
  }

  Widget _buildCashDetail({required TextEditingController controller}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _K.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _K.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        cursorColor: _K.emerald,
        style: const TextStyle(
          color: _K.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        decoration: const InputDecoration(
          prefixText: '\$ ',
          prefixStyle: TextStyle(
              color: _K.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700),
          hintText: 'Reward cash amount',
          hintStyle: TextStyle(color: _K.textMuted, fontSize: 13),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildItemDetail(
      {required String selectedItem, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _K.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _K.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedItem,
                style: const TextStyle(
                    color: _K.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: _K.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  // ─── Item picker bottom sheet ──────────────────────────────────────────────

  Future<void> _openItemPicker({
    required String currentItem,
    required void Function(String name, String? id) onSelected,
  }) async {
    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _K.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _rewardItems
                .where((item) =>
                    item.toLowerCase().contains(query.trim().toLowerCase()))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _K.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _K.border, width: 1),
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
                            color: _K.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _K.surfaceRaised,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _K.border, width: 1),
                        ),
                        child: TextField(
                          autofocus: true,
                          cursorColor: _K.emerald,
                          style: const TextStyle(
                              color: _K.textPrimary, fontSize: 13.5),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search,
                                color: _K.textSecondary, size: 18),
                            hintText: 'Search menu item',
                            hintStyle:
                                TextStyle(color: _K.textMuted, fontSize: 13),
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
                                      color: _K.textMuted, fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(color: _K.border, height: 1),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final selected = item == currentItem;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    title: Text(
                                      item,
                                      style: TextStyle(
                                        color: selected
                                            ? _K.emerald
                                            : _K.textPrimary,
                                        fontSize: 13.5,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    trailing: selected
                                        ? const Icon(Icons.check_circle_rounded,
                                            color: _K.emerald, size: 18)
                                        : null,
                                    onTap: () {
                                      final match = _menuItems.firstWhere(
                                        (it) => it['name'] == item,
                                        orElse: () => {},
                                      );
                                      final itemId = match['id']?.toString();
                                      onSelected(item, itemId);
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

  // ─── Add milestone button — dashed, slate outline ─────────────────────────

  Widget _buildAddMilestoneButton() {
    if (_milestones.length >= 3) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _addMilestone,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: CustomPaint(
          painter: const _DashedBorderPainter(
            color: _K.borderMid,
            borderRadius: 12,
            dashWidth: 8,
            dashSpace: 5,
            strokeWidth: 1.5,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline, color: _K.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  _milestones.isEmpty ? '+ Add Milestone' : '+ Add Another Milestone',
                  style: const TextStyle(
                      color: _K.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Save button — slate-900 filled pill ──────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveRewards,
        style: ElevatedButton.styleFrom(
          backgroundColor: _K.dark,
          foregroundColor: _K.white,
          disabledBackgroundColor: _K.dark.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'SAVE REWARDS',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.4),
              ),
      ),
    );
  }
}

// ── Dashed border painter ───────────────────────────────────────────────────

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
