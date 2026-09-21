import 'package:flutter/material.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
//
// Identical tokens to createOfferScreen.dart, so viewing an order reads as
// the same surface as creating an offer.
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

// ─── Screen ──────────────────────────────────────────────────────────────────
//
// Rebuilt around the same rhythm as CreateOfferScreen: a dark live-preview
// card up top, then labelled sections each in their own card, with the
// primary action pinned to the bottom bar so it's always reachable.
//
// Every original feature is preserved — the order header, per-item image /
// name / note / offer "missing data" highlighting, the subtotal / savings /
// offers summary, the milestone banner, and the total amount.
class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final String totalAmount;
  final String subtotalAmount;
  final String savingsAmount;
  final String offersSummary;
  final bool milestoneUnlocked;
  final String milestoneMessage;
  final List<OrderLineItem> items;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.subtotalAmount,
    required this.savingsAmount,
    required this.offersSummary,
    required this.milestoneUnlocked,
    required this.milestoneMessage,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Pal.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
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
                    const _SectionLabel('Items'),
                    const SizedBox(height: 10),
                    _buildItemsCard(),
                    const SizedBox(height: 18),
                    const _SectionLabel('Order summary'),
                    const SizedBox(height: 10),
                    _buildSummaryCard(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _Pal.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$orderId · ${items.length} ${items.length == 1 ? "item" : "items"}',
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
            child: const Icon(Icons.receipt_long_rounded,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Savings applied · $savingsAmount off',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 10),
                _PreviewChip(
                  icon: Icons.restaurant_menu_rounded,
                  label:
                      '${items.length} ${items.length == 1 ? "item" : "items"}',
                ),
              ],
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
              totalAmount,
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

  // ── Items ──────────────────────────────────────────────────────────────────

  Widget _buildItemsCard() {
    return _Card(
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _ItemRow(item: items[i]),
            if (i != items.length - 1) ...[
              const SizedBox(height: 12),
              const Divider(color: _Pal.line, height: 1),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  // ── Summary ────────────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final offersMissing = offersSummary.startsWith('[');

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow('Subtotal', subtotalAmount, _Pal.ink),
          const SizedBox(height: 10),
          _SummaryRow('Savings', savingsAmount, _Pal.green),
          const SizedBox(height: 14),
          const Divider(color: _Pal.line, height: 1),
          const SizedBox(height: 14),
          _NoticeBox(
            icon: milestoneUnlocked
                ? Icons.emoji_events_rounded
                : Icons.lock_clock_rounded,
            title: milestoneUnlocked
                ? 'Milestone reward unlocked'
                : 'Milestone reward not unlocked',
            message: milestoneMessage,
            tone:
                milestoneUnlocked ? _NoticeTone.positive : _NoticeTone.neutral,
          ),
          const SizedBox(height: 10),
          _NoticeBox(
            icon: Icons.local_offer_outlined,
            title: offersMissing ? 'Offers unavailable' : 'Offers applied',
            message: offersSummary,
            tone: offersMissing ? _NoticeTone.negative : _NoticeTone.neutral,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _Pal.ink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total amount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  totalAmount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom action bar ──────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
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
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _Pal.ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Mark complete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The customer is notified as soon as you mark this order complete.',
            textAlign: TextAlign.center,
            style: TextStyle(
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

// ─── Shared pieces (mirrors createOfferScreen.dart) ──────────────────────────

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

// ─── Item row ─────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final OrderLineItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isImgMissing = item.imageUrl.isEmpty;
    final isNameMissing = item.name.startsWith('[');
    final isNoteMissing = item.note.startsWith('[');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    isImgMissing ? _Pal.red.withValues(alpha: 0.08) : _Pal.wash,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isImgMissing
                      ? _Pal.red.withValues(alpha: 0.4)
                      : _Pal.line,
                ),
              ),
              child: ClipOval(
                child: isImgMissing
                    ? const Icon(Icons.restaurant, color: _Pal.red, size: 18)
                    : Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.restaurant,
                          color: _Pal.red,
                          size: 18,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isNameMissing ? _Pal.red : _Pal.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isNoteMissing ? _Pal.red : _Pal.ink500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.quantity,
              style: const TextStyle(
                color: _Pal.ink600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.unitPrice,
              style: const TextStyle(
                color: _Pal.ink400,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              item.lineTotal,
              style: const TextStyle(
                color: _Pal.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (item.appliedOffer != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _OfferChip(
              label: item.appliedOffer!,
              isError: item.appliedOffer!.startsWith('['),
            ),
          ),
        ],
      ],
    );
  }
}

class _OfferChip extends StatelessWidget {
  final String label;
  final bool isError;
  const _OfferChip({required this.label, required this.isError});

  @override
  Widget build(BuildContext context) {
    final tint = isError ? _Pal.red : _Pal.green;
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 10, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'Offer: $label',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary pieces ───────────────────────────────────────────────────────────

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
            fontSize: 12,
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

enum _NoticeTone { positive, negative, neutral }

class _NoticeBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final _NoticeTone tone;

  const _NoticeBox({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    late final Color iconColor;
    late final Color titleColor;
    late final Color bg;
    late final Color border;

    switch (tone) {
      case _NoticeTone.positive:
        iconColor = _Pal.green;
        titleColor = _Pal.green;
        bg = _Pal.green.withValues(alpha: 0.08);
        border = _Pal.green.withValues(alpha: 0.3);
        break;
      case _NoticeTone.negative:
        iconColor = _Pal.red;
        titleColor = _Pal.red;
        bg = _Pal.red.withValues(alpha: 0.08);
        border = _Pal.red.withValues(alpha: 0.3);
        break;
      case _NoticeTone.neutral:
        iconColor = _Pal.ink700;
        titleColor = _Pal.ink;
        bg = _Pal.wash;
        border = _Pal.line;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _Pal.surface,
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
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
}
