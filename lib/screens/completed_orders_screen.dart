import 'package:flutter/material.dart';

import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/screens/orderDetailScreen.dart';
import 'package:frontend/config/api_config.dart';

/// Completed orders belonging to one Performance date-range selection.
/// Each request retrieves only one filtered page from the server.
class CompletedOrdersScreen extends StatefulWidget {
  const CompletedOrdersScreen({
    super.key,
    required this.range,
    required this.rangeLabel,
  });

  final DateTimeRange range;
  final String rangeLabel;

  @override
  State<CompletedOrdersScreen> createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  static const _pageSize = 20;

  var _page = 1;
  var _total = 0;
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = const [];

  late DateTimeRange _currentRange;
  late String _currentRangeLabel;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.range;
    _currentRangeLabel = widget.rangeLabel;
    _loadPage();
  }

  Future<void> _loadPage({int? page}) async {
    final requestedPage = page ?? _page;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await VendorService.getCompletedRedemptionsPage(
      confirmedAfter: _currentRange.start,
      confirmedBefore: _currentRange.end,
      page: requestedPage,
      pageSize: _pageSize,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _page = requestedPage;
        _total = (result['count'] as num?)?.toInt() ?? 0;
        _orders = data is List
            ? data
                .whereType<Map>()
                .map((order) => Map<String, dynamic>.from(order))
                .toList()
            : const [];
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['error']?.toString() ?? 'Unable to load orders.';
        _loading = false;
      });
    }
  }

  bool _showInlineCalendar = false;
  bool _selectingStart = true;
  DateTime? _customStart;
  DateTime? _customEnd;

  void _applyRange(DateTimeRange range, String label) {
    if (!mounted) return;
    setState(() {
      _currentRange = range;
      _currentRangeLabel = label;
      _page = 1;
    });
    _loadPage(page: 1);
  }

  Widget _inlineCalendar() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectingStart = true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _selectingStart ? const Color(0xFFF1F5F9) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _selectingStart ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(_customStart != null ? _formatDateCompact(_customStart!) : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectingStart = false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: !_selectingStart ? const Color(0xFFF1F5F9) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: !_selectingStart ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Date', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(_customEnd != null ? _formatDateCompact(_customEnd!) : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: Color(0xFF0F172A)),
                ),
                child: CalendarDatePicker(
                  initialDate: _selectingStart ? (_customStart ?? DateTime.now()) : (_customEnd ?? DateTime.now()),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  onDateChanged: (date) {
                    setState(() {
                      if (_selectingStart) {
                        _customStart = date;
                        if (_customEnd != null && _customStart!.isAfter(_customEnd!)) _customEnd = _customStart;
                      } else {
                        _customEnd = date;
                        if (_customStart != null && _customEnd!.isBefore(_customStart!)) _customStart = _customEnd;
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _showInlineCalendar = false),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _customStart == null || _customEnd == null ? null : () {
                    setState(() => _showInlineCalendar = false);
                    final start = DateTime(_customStart!.year, _customStart!.month, _customStart!.day);
                    final end = DateTime(_customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59, 999);
                    _applyRange(
                      DateTimeRange(start: start, end: end),
                      '${_formatDateCompact(_customStart!)} - ${_formatDateCompact(_customEnd!)}'
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Apply Range', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      );

  String _formatDateCompact(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  int get _pageCount => _total == 0 ? 1 : (_total + _pageSize - 1) ~/ _pageSize;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F2937), Color(0xFF111827)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(children: [
            _header(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  child: Column(
                    children: [
                      if (_showInlineCalendar) _inlineCalendar(),
                      Expanded(child: _body()),
                      if (!_loading && _error == null) _pagination(),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      );

  Widget _header() => SizedBox(
        width: double.infinity,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 20, 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text('Completed orders',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5)),
                ),
                const Icon(Icons.verified_rounded, color: Colors.white),
              ]),
              const SizedBox(height: 15),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == '7days') {
                    setState(() => _showInlineCalendar = false);
                    final now = DateTime.now();
                    _applyRange(DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now), 'Last 7 days');
                  } else if (val == '30days') {
                    setState(() => _showInlineCalendar = false);
                    final now = DateTime.now();
                    _applyRange(DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now), 'Last 30 days');
                  } else if (val == 'custom') {
                    setState(() {
                      _customStart = _currentRange.start;
                      _customEnd = _currentRange.end;
                      _selectingStart = true;
                      _showInlineCalendar = true;
                    });
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: '7days', child: Text('Last 7 days', style: TextStyle(fontWeight: FontWeight.w600))),
                  PopupMenuItem(value: '30days', child: Text('Last 30 days', style: TextStyle(fontWeight: FontWeight.w600))),
                  PopupMenuItem(value: 'custom', child: Text('Custom range', style: TextStyle(fontWeight: FontWeight.w600))),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: .14)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(_currentRangeLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.white),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              Text('Orders are grouped by their completion date.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .68),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );

  Widget _body() {
    if (_loading && _orders.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F172A)));
    }
    if (_error != null && _orders.isEmpty) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn’t load completed orders',
        detail: _error!,
        actionLabel: 'Try again',
        onAction: _loadPage,
      );
    }
    if (_orders.isEmpty) {
      return _MessageState(
        icon: Icons.receipt_long_outlined,
        title: 'No completed orders',
        detail: 'There were no completed orders in this date range.',
        actionLabel: 'Refresh',
        onAction: _loadPage,
      );
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final order in _orders) {
      final date = _orderDate(order);
      final key =
          date == null ? 'unknown' : '${date.year}-${date.month}-${date.day}';
      (grouped[key] ??= []).add(order);
    }
    return RefreshIndicator(
      color: const Color(0xFF0F172A),
      onRefresh: _loadPage,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        children: [
          for (final entry in grouped.entries) ...[
            _DateHeading(
                date: _orderDate(entry.value.first), count: entry.value.length),
            const SizedBox(height: 9),
            for (final order in entry.value) ...[
              _CompletedOrderTile(order: order),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _pagination() => Container(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(children: [
          _PageButton(
            icon: Icons.chevron_left_rounded,
            label: 'Previous',
            enabled: _page > 1,
            onTap: () => _loadPage(page: _page - 1),
          ),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Page $_page of $_pageCount',
                  style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('$_total ${_total == 1 ? 'order' : 'orders'}',
                  style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            label: 'Next',
            trailing: true,
            enabled: _page < _pageCount,
            onTap: () => _loadPage(page: _page + 1),
          ),
        ]),
      );
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.trailing = false,
  });

  final IconData icon;
  final String label;
  final bool enabled, trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: enabled ? onTap : null,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          disabledForegroundColor: const Color(0xFFCBD5E1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        ),
        icon: trailing ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        iconAlignment: trailing ? IconAlignment.end : IconAlignment.start,
      );
}

class _DateHeading extends StatelessWidget {
  const _DateHeading({required this.date, required this.count});
  final DateTime? date;
  final int count;

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(_dateLabel(date),
            style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
        const SizedBox(width: 8),
        Text('$count ${count == 1 ? 'order' : 'orders'}',
            style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]);
}

class _CompletedOrderTile extends StatelessWidget {
  const _CompletedOrderTile({required this.order});
  final Map<String, dynamic> order;

  void _navigateToDetails(BuildContext context, Map<String, dynamic> order) {
    final rawOrderNum = order['order_number']?.toString();
    final orderIdStr = (rawOrderNum != null && rawOrderNum.isNotEmpty)
        ? (rawOrderNum.startsWith('#') ? rawOrderNum : '#$rawOrderNum')
        : (order['id']?.toString() ?? '');
    final qrCode = order['qr_code']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'completed';
    final customerName = order['customer_name']?.toString() ?? '';
    final finalTotal = order['final_total']?.toString() ?? '0.00';
    final subtotal = order['subtotal']?.toString() ?? '0.00';
    final discount = order['total_discount']?.toString() ?? '0.00';
    final milestoneMsg = order['milestone_message']?.toString() ?? '';
    final hasReward = order['milestone_unlocked'] == true;

    final offersList = (order['applied_offers'] as List<dynamic>?) ?? [];
    final offersSummaryStr = offersList.isNotEmpty
        ? 'Offers applied: ${offersList.map((o) {
            final title = o['title_snapshot']?.toString() ?? 'Offer';
            final dAmount = o['discount_amount']?.toString();
            if (dAmount != null &&
                double.tryParse(dAmount) != null &&
                double.tryParse(dAmount)! > 0) {
              return '$title (Saved ₹$dAmount)';
            }
            return title;
          }).join(', ')}'
        : '[No Offers Applied]';

    final rawItems = (order['items'] as List<dynamic>?) ?? [];
    List<OrderLineItem> mappedItems = [];
    if (rawItems.isEmpty) {
      mappedItems.add(OrderLineItem(
        name: 'Order Item',
        note: '',
        quantity: 'x1',
        imageUrl: '',
        unitPrice: '₹$finalTotal',
        lineTotal: '₹$finalTotal',
        appliedOffer: offersList.isNotEmpty
            ? offersList.first['title_snapshot']?.toString()
            : null,
      ));
    } else {
      mappedItems = rawItems.map((item) {
        final iMap = item as Map<String, dynamic>;
        final iName = iMap['item_name_snapshot']?.toString() ?? '';
        final nameStr = iName.isNotEmpty ? iName : 'Item';

        final components = iMap['components'] as List<dynamic>?;
        String noteStr = '';
        if (components != null && components.isNotEmpty) {
          final compList = components
              .map((c) => '${c['quantity'] ?? 1}x ${c['item_name_snapshot'] ?? ''}')
              .join(', ');
          noteStr = 'Includes: $compList';
        } else if (iMap['is_reward_item'] == true) {
          noteStr = '🎁 Free Milestone Reward';
        }

        final qty = iMap['quantity']?.toString() ?? '1';
        final uPrice = iMap['unit_price_snapshot']?.toString() ?? '0.00';
        final lTotal = iMap['line_total']?.toString() ?? '0.00';
        final imgUrl = ApiConfig.getImageUrl(
                iMap['image']?.toString() ?? iMap['image_url']?.toString()) ?? '';

        return OrderLineItem(
          name: nameStr,
          note: noteStr,
          quantity: 'x$qty',
          imageUrl: imgUrl,
          unitPrice: '₹$uPrice each',
          lineTotal: '₹$lTotal',
          appliedOffer: offersList.isNotEmpty
              ? offersList.first['title_snapshot']?.toString()
              : null,
        );
      }).toList();
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: orderIdStr,
          qrCode: qrCode,
          status: status,
          customerName: customerName.isNotEmpty ? customerName : null,
          totalAmount: '₹$finalTotal',
          subtotalAmount: '₹$subtotal',
          savingsAmount: '-₹$discount',
          offersSummary: offersSummaryStr,
          milestoneUnlocked: hasReward,
          milestoneMessage: milestoneMsg,
          items: mappedItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = order['items'];
    final lines =
        items is List ? items.whereType<Map>().toList() : const <Map>[];
    final itemCount = lines.fold<int>(0, (total, item) {
      return total + (int.tryParse(item['quantity']?.toString() ?? '') ?? 1);
    });
    final itemNames = lines
        .take(2)
        .map((item) => item['item_name_snapshot']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .join(' · ');
    final orderNumber = order['order_number']?.toString().trim();
    final date = _orderDate(order);

    final firstItemImg = lines.isNotEmpty 
        ? ApiConfig.getImageUrl(lines.first['image']?.toString() ?? lines.first['image_url']?.toString())
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetails(context, order),
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                ),
                child: firstItemImg != null && firstItemImg.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                        child: Image.network(
                          firstItemImg,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.receipt_rounded,
                              color: Color(0xFF94A3B8),
                              size: 28),
                        ),
                      )
                    : const Icon(Icons.receipt_rounded,
                        color: Color(0xFF94A3B8), size: 28),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          orderNumber == null || orderNumber.isEmpty
                              ? 'Completed order'
                              : orderNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w800),
                        ),
              ),
              const SizedBox(width: 8),
              Text(_rupees(_asDouble(order['final_total'])),
                  style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 3),
            Text(
              (order['customer_name']?.toString().trim().isNotEmpty ?? false)
                  ? order['customer_name'].toString().trim()
                  : 'Customer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            if (itemNames.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(itemNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.shopping_bag_outlined,
                  size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text('$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              const Icon(Icons.schedule_rounded,
                  size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(_timeLabel(date),
                  style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      ),
    ]),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
  });
  final IconData icon;
  final String title, detail, actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 38, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 13),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 12.5, height: 1.4)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ]),
        ),
      );
}

DateTime? _orderDate(Map<String, dynamic> order) {
  final raw = order['confirmed_at'] ?? order['created_at'];
  return raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'Unknown date';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
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
    'Dec'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _timeLabel(DateTime? date) {
  if (date == null) return 'Completed';
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
}

double _asDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;

String _rupees(double value) {
  final text = value.round().abs().toString();
  var grouped = text;
  if (text.length > 3) {
    var rest = text.substring(0, text.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},${text.substring(text.length - 3)}';
  }
  return '${value < 0 ? '-' : ''}₹$grouped';
}
