import 'package:flutter/material.dart';

import '../config/api_config.dart';
import 'orderDetailScreen.dart';

/// Builds the order detail view from the vendor API/realtime order shape.
/// Keeping this outside an individual tab lets notification taps open the
/// correct order even when the Orders screen has not been created yet.
OrderDetailScreen orderDetailScreenForSession(Map<String, dynamic> session) {
  final rawOrderNumber = session['order_number']?.toString() ?? '';
  final qrCode = session['qr_code']?.toString() ?? '';
  final orderId = rawOrderNumber.isNotEmpty
      ? (rawOrderNumber.startsWith('#') ? rawOrderNumber : '#$rawOrderNumber')
      : (qrCode.isNotEmpty ? '#${qrCode.replaceAll('-', '').toUpperCase()}' : '#UNKNOWN');
  final finalTotal = session['final_total']?.toString() ??
      session['subtotal']?.toString() ??
      '0.00';
  final subtotal = session['subtotal']?.toString() ?? '0.00';
  final discount = session['total_discount']?.toString() ?? '0.00';
  final reward = session['reward'] is Map
      ? Map<String, dynamic>.from(session['reward'] as Map)
      : null;
  final hasReward = reward != null &&
      (reward['name_snapshot'] != null ||
          reward['gift_item_name_snapshot'] != null ||
          reward['discount_amount'] != null);
  final rewardName = reward?['name_snapshot']?.toString() ?? 'Milestone Reward';
  final giftName = reward?['gift_item_name_snapshot']?.toString();
  final rewardDiscount = reward?['discount_amount']?.toString();
  final milestoneMessage = !hasReward
      ? 'No milestone reward applied for this order.'
      : giftName != null && giftName.isNotEmpty
      ? '$rewardName (Free item: $giftName)'
      : rewardDiscount != null && (double.tryParse(rewardDiscount) ?? 0) > 0
      ? '$rewardName (Saved ₹$rewardDiscount)'
      : rewardName;

  final offers = (session['applied_offers'] is List)
      ? (session['applied_offers'] as List)
          .whereType<Map>()
          .map((offer) => Map<String, dynamic>.from(offer))
          .toList()
      : <Map<String, dynamic>>[];
  final offersSummary = offers.isEmpty
      ? '[No Offers Applied]'
      : 'Offers applied: ${offers.map((offer) {
          final title = offer['title_snapshot']?.toString() ?? 'Offer';
          final amount = offer['discount_amount']?.toString();
          return amount != null && (double.tryParse(amount) ?? 0) > 0
              ? '$title (Saved ₹$amount)'
              : title;
        }).join(', ')}';

  final rawItems = (session['items'] is List)
      ? (session['items'] as List)
      : const <dynamic>[];
  final items = rawItems.whereType<Map>().map((item) {
    final entry = Map<String, dynamic>.from(item);
    final components = entry['components'] is List
        ? (entry['components'] as List).whereType<Map>()
        : const <Map>[];
    final note = components.isNotEmpty
        ? 'Includes: ${components.map((component) => '${component['quantity'] ?? 1}x ${component['item_name_snapshot'] ?? ''}').join(', ')}'
        : entry['is_reward_item'] == true
        ? '🎁 Free Milestone Reward'
        : '';
    return OrderLineItem(
      name: entry['item_name_snapshot']?.toString() ?? 'Item',
      note: note,
      quantity: 'x${entry['quantity'] ?? 1}',
      imageUrl: ApiConfig.getImageUrl(
            entry['image']?.toString() ?? entry['image_url']?.toString(),
          ) ??
          '',
      unitPrice: '₹${entry['unit_price_snapshot'] ?? '0.00'} each',
      lineTotal: '₹${entry['line_total'] ?? '0.00'}',
      appliedOffer: offers.isEmpty ? null : offers.first['title_snapshot']?.toString(),
    );
  }).toList();

  return OrderDetailScreen(
    orderId: orderId,
    qrCode: qrCode,
    status: session['status']?.toString().toLowerCase() ?? 'pending',
    customerName: session['customer_name']?.toString(),
    totalAmount: '₹$finalTotal',
    subtotalAmount: '₹$subtotal',
    savingsAmount: '-₹$discount',
    offersSummary: offersSummary,
    milestoneUnlocked: hasReward,
    milestoneMessage: milestoneMessage,
    items: items.isEmpty
        ? [
            OrderLineItem(
              name: 'Order Item',
              note: '',
              quantity: 'x1',
              imageUrl: '',
              unitPrice: '₹$finalTotal',
              lineTotal: '₹$finalTotal',
            ),
          ]
        : items,
  );
}
