import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'vendor_cache_service.dart';

/// A vendor-scoped local inbox. It always records incoming orders, even when
/// the operating system notification permission is denied.
class VendorNotification {
  const VendorNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    this.orderId,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String? orderId;

  VendorNotification copyWith({bool? read}) => VendorNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        createdAt: createdAt,
        read: read ?? this.read,
        orderId: orderId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        'created_at': createdAt.toUtc().toIso8601String(),
        'read': read,
        if (orderId != null) 'order_id': orderId,
      };

  static VendorNotification? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id']?.toString() ?? '';
    final createdAt = DateTime.tryParse(value['created_at']?.toString() ?? '');
    if (id.isEmpty || createdAt == null) return null;
    return VendorNotification(
      id: id,
      type: value['type']?.toString() ?? 'account',
      title: value['title']?.toString() ?? 'Notification',
      message: value['message']?.toString() ?? '',
      createdAt: createdAt.toLocal(),
      read: value['read'] == true,
      orderId: value['order_id']?.toString(),
    );
  }
}

class VendorNotificationService {
  VendorNotificationService._();

  static const _cacheKey = 'notifications';
  static const _maxInboxItems = 250;

  static const MethodChannel _nativeNotifications =
      MethodChannel('zteel/vendor_notifications');
  static final ValueNotifier<List<VendorNotification>> notifications =
      ValueNotifier<List<VendorNotification>>(<VendorNotification>[]);
  static final ValueNotifier<bool?> notificationsPermitted =
      ValueNotifier<bool?>(null);
  static final StreamController<void> _orderTapEvents =
      StreamController<void>.broadcast();
  static final List<String> _pendingOrderTapIds = <String>[];

  static Future<void>? _initializing;
  static Future<void> _writeTail = Future<void>.value();

  static int get unreadCount =>
      notifications.value.where((notification) => !notification.read).length;

  static Future<void> initialize() => _initializing ??= _initialize();

  static Future<void> _initialize() async {
    await VendorCacheService.initialize();
    _nativeNotifications.setMethodCallHandler(_handleNativeNotificationCall);
    await _loadInbox();
    try {
      final launchPayload =
          await _nativeNotifications.invokeMethod<String>('getLaunchOrder');
      _queueOrderTapFromPayload(launchPayload);
    } catch (_) {
      // Desktop and web builds have no native notification launch payload.
    }
  }

  /// A signal that an OS or in-app notification requested an order screen.
  /// Consume the associated id with [takePendingOrderTap].
  static Stream<void> get orderTapEvents => _orderTapEvents.stream;

  static String? takePendingOrderTap() {
    if (_pendingOrderTapIds.isEmpty) return null;
    return _pendingOrderTapIds.removeAt(0);
  }

  /// Used by notification cards as well as the native notification bridge.
  static void openOrder(String? orderId) {
    if (orderId == null || orderId.isEmpty) return;
    if (_pendingOrderTapIds.contains(orderId)) return;
    _pendingOrderTapIds.add(orderId);
    _orderTapEvents.add(null);
  }

  static Future<void> _handleNativeNotificationCall(MethodCall call) async {
    if (call.method == 'openOrder') {
      _queueOrderTapFromPayload(call.arguments);
    }
  }

  static void _queueOrderTapFromPayload(Object? payload) {
    if (payload is Map) {
      openOrder(payload['order_id']?.toString());
      return;
    }
    if (payload is! String || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        openOrder(decoded['order_id']?.toString());
      }
    } catch (_) {
      // A malformed native payload must not affect notification delivery.
    }
  }

  /// Requests OS permission only for a signed-in vendor. A declined request
  /// intentionally leaves the in-app inbox fully functional.
  static Future<bool> requestPermission() async {
    await initialize();
    try {
      final status = await Permission.notification.request();
      final granted = status.isGranted || status.isLimited || status.isProvisional;
      notificationsPermitted.value = granted;
      return granted;
    } catch (_) {
      notificationsPermitted.value = false;
      return false;
    }
  }

  static Future<void> reload() async {
    await initialize();
    await _loadInbox();
  }

  static Future<void> _loadInbox() async {
    final raw = await VendorCacheService.readList(_cacheKey) ?? <dynamic>[];
    final restored = raw
        .map(VendorNotification.fromJson)
        .whereType<VendorNotification>()
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    notifications.value = List<VendorNotification>.unmodifiable(restored);
  }

  static Future<void> recordNewOrder({
    required String eventId,
    required String orderId,
    required Map<String, dynamic> order,
    DateTime? occurredAt,
  }) {
    final orderNumber = order['order_number']?.toString() ?? 'new';
    final amount = order['final_total']?.toString();
    final message = amount == null || amount.isEmpty
        ? 'A new order is ready to review.'
        : 'A new order worth ₹$amount is ready to review.';
    final item = VendorNotification(
      id: eventId,
      type: 'order',
      title: 'New order #$orderNumber',
      message: message,
      createdAt: occurredAt?.toLocal() ?? DateTime.now(),
      read: false,
      orderId: orderId,
    );
    return _enqueue(() async {
      final isNew = notifications.value.every((existing) => existing.id != item.id);
      final next = <VendorNotification>[
        item,
        ...notifications.value.where((existing) => existing.id != item.id),
      ].take(_maxInboxItems).toList();
      await _store(next);
      if (isNew) await _showOrderNotification(item);
    });
  }

  static Future<void> markRead(String id) => _enqueue(() async {
        await _store([
          for (final item in notifications.value)
            item.id == id ? item.copyWith(read: true) : item,
        ]);
      });

  static Future<void> markAllRead() => _enqueue(() async {
        await _store([
          for (final item in notifications.value) item.copyWith(read: true),
        ]);
      });

  static Future<void> dismiss(String id) => _enqueue(() async {
        await _store(
          notifications.value.where((item) => item.id != id).toList(),
        );
      });

  static Future<void> _enqueue(Future<void> Function() operation) {
    final result = _writeTail.then((_) => operation());
    _writeTail = result.catchError((_) {});
    return result;
  }

  static Future<void> _store(List<VendorNotification> items) async {
    final sorted = List<VendorNotification>.from(items)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    notifications.value = List<VendorNotification>.unmodifiable(sorted);
    await VendorCacheService.write(
      _cacheKey,
      sorted.map((item) => item.toJson()).toList(),
    );
  }

  static Future<void> _showOrderNotification(VendorNotification item) async {
    // A declined or unavailable permission must never prevent the inbox write.
    if (notificationsPermitted.value != true) return;
    try {
      await _nativeNotifications.invokeMethod<void>('showNewOrder', {
        'id': item.id.hashCode & 0x7fffffff,
        'title': item.title,
        'message': item.message,
        'payload': jsonEncode({'type': item.type, 'order_id': item.orderId}),
      });
    } catch (_) {
      // OS notification delivery is best effort; the persisted inbox remains
      // the authoritative in-app record.
    }
  }
}
