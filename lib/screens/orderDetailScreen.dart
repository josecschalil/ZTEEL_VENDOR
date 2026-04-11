import 'package:flutter/material.dart';

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

  static const Color bgDark = Color(0xFF1A0E0A);
  static const Color cardBg = Color(0xFF251510);
  static const Color orange = Color(0xFFE8622A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9E7E72);
  static const Color border = Color(0xFF3A2015);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: textWhite),
        title: const Text(
          'Order Details',
          style: TextStyle(color: textWhite, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(),
                const SizedBox(height: 14),
                const Text(
                  'Items',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...items.map(_buildItemCard),
                const SizedBox(height: 12),
                _buildSummaryBlock(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderId,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Offer savings included',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1F3A2E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2D6446)),
            ),
            child: const Text(
              'Mark Complete',
              style: TextStyle(
                color: Color(0xFF4CAF6E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(OrderLineItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: const Color(0xFF3A2015),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant,
                        color: orange,
                        size: 24,
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
                        style: const TextStyle(
                          color: textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.quantity,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 13,
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
                    color: textGrey,
                    fontSize: 11,
                  ),
                ),
                Text(
                  item.lineTotal,
                  style: const TextStyle(
                    color: orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (item.appliedOffer != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Offer: ${item.appliedOffer!}',
                  style: const TextStyle(
                    color: Color(0xFF4CAF6E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotalAmount, textWhite),
          const SizedBox(height: 8),
          _buildSummaryRow('Savings', savingsAmount, const Color(0xFF4CAF6E)),
          const SizedBox(height: 8),
          const Divider(color: border, height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0E0A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: milestoneUnlocked
                    ? const Color(0xFF2D6446)
                    : const Color(0xFF3A2015),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  milestoneUnlocked
                      ? Icons.emoji_events_rounded
                      : Icons.lock_clock_rounded,
                  size: 16,
                  color: milestoneUnlocked ? const Color(0xFF4CAF6E) : textGrey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestoneUnlocked
                            ? 'Milestone Reward Unlocked'
                            : 'Milestone Reward Not Unlocked',
                        style: TextStyle(
                          color: milestoneUnlocked
                              ? const Color(0xFF4CAF6E)
                              : textGrey,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        milestoneMessage,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0E0A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Text(
              offersSummary,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D180D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: orange.withOpacity(0.45)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total amount',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  totalAmount,
                  style: const TextStyle(
                    color: orange,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: textGrey, fontSize: 12),
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
