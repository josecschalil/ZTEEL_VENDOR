import 'package:flutter/material.dart';

import 'package:frontend/services/vendor_service.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
//
// Same slate / white tokens as createOfferScreen.dart (plus amber, which is
// only used for "pending" and the milestone reward).
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
  static const amber = Color(0xFFF59E0B);
  static const amberInk = Color(0xFFB45309);

  static const cardShadow = BoxShadow(
    color: Color(0x06000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
}

class OrderLineItem {
  final String name;
  final String note;
  final String quantity;
  final String imageUrl;
  final String unitPrice;
  final String lineTotal;
  final String? appliedOffer;

  const OrderLineItem({
    required this.name,
    required this.note,
    required this.quantity,
    required this.imageUrl,
    required this.unitPrice,
    required this.lineTotal,
    this.appliedOffer,
  });
}

String _itemsLabel(int n) => '$n ${n == 1 ? 'item' : 'items'}';

// ─── Screen ──────────────────────────────────────────────────────────────────
//
// Layout, top to bottom:
//   1. Dark ticket  – customer, status and the total on a perforated stub
//   2. Progress     – placed → awaiting → completed (or expired / cancelled)
//   3. Items        – one card, thumbnails with quantity and line totals
//   4. Offers       – applied promotion + milestone reward (only if present)
//   5. Breakdown    – item total, discount, total payable
//   Bottom bar      – total + the primary action, always reachable
//
// The public API (constructor, OrderLineItem, onOrderCompleted, pop(true))
// is unchanged.
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final String qrCode;
  final String status;
  final String? customerName;
  final String totalAmount;
  final String subtotalAmount;
  final String savingsAmount;
  final String offersSummary;
  final bool milestoneUnlocked;
  final String milestoneMessage;
  final List<OrderLineItem> items;
  final VoidCallback? onOrderCompleted;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.qrCode = '',
    this.status = 'pending',
    this.customerName,
    required this.totalAmount,
    required this.subtotalAmount,
    required this.savingsAmount,
    required this.offersSummary,
    required this.milestoneUnlocked,
    required this.milestoneMessage,
    required this.items,
    this.onOrderCompleted,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late String _currentStatus;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status.toLowerCase();
  }

  // ── Derived values ─────────────────────────────────────────────────────────

  String get _cleanOffers => widget.offersSummary.trim();

  bool get _hasOffers =>
      _cleanOffers.isNotEmpty &&
      !_cleanOffers.startsWith('[') &&
      !_cleanOffers.toLowerCase().startsWith('no ');

  bool get _hasMilestone =>
      widget.milestoneUnlocked &&
      widget.milestoneMessage.trim().isNotEmpty &&
      !widget.milestoneMessage.startsWith('[');

  bool get _hasSavings {
    final raw = widget.savingsAmount.replaceAll('₹', '').replaceAll(',', '');
    return (double.tryParse(raw.trim()) ?? 0.0) > 0.0;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _toast(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Future<void> _handleMarkComplete() async {
    if (widget.qrCode.isEmpty) {
      _toast('Missing Order QR code for completion.', _Pal.red);
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await VendorService.scanVendorRedemption(widget.qrCode);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      setState(() => _currentStatus = 'confirmed');
      widget.onOrderCompleted?.call();
      _toast('Order ${widget.orderId} marked as completed!', _Pal.ink);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      });
    } else {
      _toast(res['error'] ?? 'Failed to update order status', _Pal.red);
    }
  }

  Future<void> _handleReject() async {
    if (widget.qrCode.isEmpty || _isSubmitting) return;
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject this order?'),
        content: const Text(
          'This cannot be undone. The customer will be notified that the order was rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep order'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _Pal.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reject order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (shouldReject != true || !mounted) return;

    setState(() => _isSubmitting = true);
    final res = await VendorService.rejectVendorRedemption(widget.qrCode);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      setState(() => _currentStatus = 'rejected');
      widget.onOrderCompleted?.call();
      _toast('Order ${widget.orderId} rejected.', _Pal.red);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      });
    } else {
      _toast(res['error']?.toString() ?? 'Failed to reject order.', _Pal.red);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Pal.bg,
      // In the bottomNavigationBar slot so snackbars float above it.
      bottomNavigationBar: _buildBottomBar(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Items',
                        trailing: _itemsLabel(widget.items.length)),
                    const SizedBox(height: 10),
                    _buildItemsCard(),
                    if (_hasOffers || _hasMilestone) ...[
                      const SizedBox(height: 22),
                      const _SectionLabel('Offers and rewards'),
                      const SizedBox(height: 10),
                      _buildRewards(),
                    ],
                    const SizedBox(height: 22),
                    const _SectionLabel('Payment breakdown'),
                    const SizedBox(height: 10),
                    _buildBreakdownCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
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
          const Text(
            'Order details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _Pal.ink,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return _Card(
      child: Column(
        children: [
          for (int i = 0; i < widget.items.length; i++) ...[
            _ItemRow(item: widget.items[i]),
            if (i != widget.items.length - 1) ...[
              const SizedBox(height: 14),
              const Divider(color: _Pal.line, height: 1),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }

  // ── 4. Offers and rewards ──────────────────────────────────────────────────

  Widget _buildRewards() {
    return Column(
      children: [
        if (_hasOffers)
          _RewardTile(
            icon: Icons.local_offer_rounded,
            accent: _Pal.green,
            labelColor: _Pal.green,
            title: 'Applied promotion',
            message: _cleanOffers,
          ),
        if (_hasOffers && _hasMilestone) const SizedBox(height: 10),
        if (_hasMilestone)
          _RewardTile(
            icon: Icons.emoji_events_rounded,
            accent: _Pal.amber,
            labelColor: _Pal.amberInk,
            title: 'Milestone reward unlocked',
            message: widget.milestoneMessage,
          ),
      ],
    );
  }

  // ── 5. Breakdown ───────────────────────────────────────────────────────────

  Widget _buildBreakdownCard() {
    return _Card(
      child: Column(
        children: [
          _SummaryRow('Item total', widget.subtotalAmount, _Pal.ink),
          if (_hasSavings) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.discount_outlined, size: 14, color: _Pal.green),
                    SizedBox(width: 6),
                    Text(
                      'Special discount',
                      style: TextStyle(
                        color: _Pal.green,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${widget.savingsAmount}',
                  style: const TextStyle(
                    color: _Pal.green,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: _Pal.line, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total payable',
                style: TextStyle(
                  color: _Pal.ink700,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.totalAmount,
                style: const TextStyle(
                  color: _Pal.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom action bar ──────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    final isPending = _currentStatus == 'pending';
    final isConfirmed = _currentStatus == 'confirmed';
    final isExpired = _currentStatus == 'expired';
    final isRejected = _currentStatus == 'rejected';
    final canComplete = isPending && !_isSubmitting;

    final label = isPending
        ? 'Mark complete'
        : isConfirmed
            ? 'Order completed'
            : isExpired
                ? 'Order expired'
                : isRejected
                    ? 'Order rejected'
                : 'Order cancelled';
    final icon = isPending
        ? Icons.check_rounded
        : isConfirmed
            ? Icons.check_circle_rounded
            : isExpired
                ? Icons.timer_off_rounded
                : isRejected
                    ? Icons.cancel_rounded
                : Icons.block_rounded;
    final bg = isPending
        ? _Pal.ink
        : isConfirmed
            ? _Pal.green
            : isExpired
                ? _Pal.wash
                : isRejected
                    ? _Pal.wash
                : _Pal.wash;
    final fg =
        (isPending || isConfirmed) ? Colors.white : _Pal.ink500;

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
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _Pal.ink400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.totalAmount,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: _Pal.ink,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          if (isPending) ...[
            Material(
              color: _Pal.wash,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: _Pal.red),
              ),
              child: InkWell(
                onTap: _isSubmitting ? null : _handleReject,
                child: const SizedBox(
                  height: 52,
                  width: 52,
                  child: Icon(Icons.close_rounded, color: _Pal.red),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Material(
              color: bg,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: (isPending || isConfirmed)
                    ? BorderSide.none
                    : const BorderSide(color: _Pal.line),
              ),
              child: InkWell(
                onTap: canComplete ? _handleMarkComplete : null,
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: fg, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: TextStyle(
                                  color: fg,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
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
  final String? trailing;
  const _SectionLabel(this.title, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _Pal.ink,
            letterSpacing: -0.2,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _Pal.ink400,
            ),
          ),
      ],
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

// ─── Item row ────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final OrderLineItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isImgMissing = item.imageUrl.isEmpty;
    final isNameMissing = item.name.startsWith('[');
    final hasOffer = item.appliedOffer != null &&
        item.appliedOffer!.trim().isNotEmpty &&
        !item.appliedOffer!.startsWith('[');
    final hasNote = item.note.trim().isNotEmpty && !item.note.startsWith('[');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isImgMissing ? _Pal.red.withValues(alpha: 0.08) : _Pal.wash,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isImgMissing ? _Pal.red.withValues(alpha: 0.4) : _Pal.line,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: isImgMissing
                ? const Icon(Icons.restaurant, color: _Pal.red, size: 20)
                : Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant,
                      color: _Pal.red,
                      size: 20,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isNameMissing ? _Pal.red : _Pal.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: _Pal.wash,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _Pal.line),
                    ),
                    child: Text(
                      item.quantity,
                      style: const TextStyle(
                        color: _Pal.ink600,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.unitPrice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _Pal.ink400,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasOffer) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _Pal.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer_rounded,
                          size: 10, color: _Pal.green),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.appliedOffer!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _Pal.green,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (hasNote) ...[
                const SizedBox(height: 6),
                Text(
                  item.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _Pal.ink500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          item.lineTotal,
          style: const TextStyle(
            color: _Pal.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Reward tile ─────────────────────────────────────────────────────────────

class _RewardTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color labelColor;
  final String title;
  final String message;
  const _RewardTile({
    required this.icon,
    required this.accent,
    required this.labelColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _Pal.ink,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary row ─────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _SummaryRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _Pal.ink500,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
