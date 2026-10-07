import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';
import 'vendor_cache_service.dart';
import 'vendor_notification_service.dart';
import 'vendor_service.dart';

/// Connection status exposed for diagnostics and future non-visual indicators.
enum VendorRealtimeState { stopped, connecting, connected, reconnecting }

/// A versioned order event sent by the backend's durable outbox.
class VendorOrderEvent {
  const VendorOrderEvent({
    required this.eventId,
    required this.type,
    required this.orderId,
    required this.revision,
    required this.order,
    required this.occurredAt,
  });

  final String eventId;
  final String type;
  final String orderId;
  final int revision;
  final Map<String, dynamic> order;
  final DateTime? occurredAt;

  bool get isNewOrder => type == 'order.created';

  static VendorOrderEvent? tryParse(Object? raw) {
    try {
      final dynamic decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final data = map['data'];
      final aggregate = map['aggregate'];
      if (data is! Map || aggregate is! Map || data['order'] is! Map) return null;

      final eventId = map['event_id']?.toString() ?? '';
      final orderId = aggregate['id']?.toString() ?? '';
      final type = map['type']?.toString() ?? '';
      if (eventId.isEmpty || orderId.isEmpty || !type.startsWith('order.')) {
        return null;
      }

      return VendorOrderEvent(
        eventId: eventId,
        type: type,
        orderId: orderId,
        revision: int.tryParse(aggregate['revision']?.toString() ?? '') ?? 0,
        order: Map<String, dynamic>.from(data['order'] as Map),
        occurredAt: DateTime.tryParse(map['occurred_at']?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }
}

/// A compact invalidation event for non-order vendor data. It contains no
/// business payload; the client re-fetches the permission-scoped resource.
class VendorResourceChangeEvent {
  const VendorResourceChangeEvent({
    required this.eventId,
    required this.resource,
    required this.action,
    required this.revision,
    required this.occurredAt,
  });

  final String eventId;
  final String resource;
  final String action;
  final int revision;
  final DateTime? occurredAt;

  static VendorResourceChangeEvent? tryParse(Object? raw) {
    try {
      final dynamic decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      if (map['type']?.toString() != 'vendor.resource_changed') return null;
      final aggregate = map['aggregate'];
      final data = map['data'];
      if (aggregate is! Map || data is! Map || data['order'] is! Map) {
        return null;
      }
      final payload = Map<String, dynamic>.from(data['order'] as Map);
      final eventId = map['event_id']?.toString() ?? '';
      final resource = payload['resource']?.toString() ?? '';
      if (eventId.isEmpty || resource.isEmpty) return null;
      return VendorResourceChangeEvent(
        eventId: eventId,
        resource: resource,
        action: payload['action']?.toString() ?? 'updated',
        revision: int.tryParse(aggregate['revision']?.toString() ?? '') ?? 0,
        occurredAt: DateTime.tryParse(map['occurred_at']?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Shared, idempotent in-memory view of live vendor orders.
///
/// Screens can consume this without owning sockets or racing each other's
/// polling. A later UI migration can replace REST refreshes with this store
/// without changing the socket protocol.
class VendorLiveOrderStore {
  VendorLiveOrderStore._();

  static final VendorLiveOrderStore instance = VendorLiveOrderStore._();

  final ValueNotifier<Map<String, Map<String, dynamic>>> orders =
      ValueNotifier<Map<String, Map<String, dynamic>>>({});
  final ValueNotifier<VendorOrderEvent?> latestEvent =
      ValueNotifier<VendorOrderEvent?>(null);

  final LinkedHashSet<String> _seenEventIds = LinkedHashSet<String>();
  static const int _eventCacheLimit = 1000;

  /// Returns true only when the event advanced local state.
  bool apply(VendorOrderEvent event) {
    if (_seenEventIds.contains(event.eventId)) return false;
    _seenEventIds.add(event.eventId);
    if (_seenEventIds.length > _eventCacheLimit) {
      _seenEventIds.remove(_seenEventIds.first);
    }

    final current = orders.value[event.orderId];
    final currentRevision = int.tryParse(
          current?['realtime_revision']?.toString() ?? '',
        ) ??
        0;
    if (event.revision <= currentRevision) return false;

    final next = Map<String, Map<String, dynamic>>.from(orders.value);
    next[event.orderId] = Map<String, dynamic>.from(event.order);
    orders.value = next;
    latestEvent.value = event;
    return true;
  }

  void reset() {
    _seenEventIds.clear();
    orders.value = {};
    latestEvent.value = null;
  }
}

/// One authenticated socket per app process, resilient to intermittent mobile
/// connectivity. It deliberately owns no widgets and makes no UI changes.
class VendorOrderRealtimeService with WidgetsBindingObserver {
  VendorOrderRealtimeService._();

  static final VendorOrderRealtimeService instance =
      VendorOrderRealtimeService._();

  final ValueNotifier<VendorRealtimeState> state =
      ValueNotifier<VendorRealtimeState>(VendorRealtimeState.stopped);
  final VendorLiveOrderStore store = VendorLiveOrderStore.instance;
  final StreamController<VendorOrderEvent> _events =
      StreamController<VendorOrderEvent>.broadcast();

  Stream<VendorOrderEvent> get events => _events.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _resourceSyncTimer;
  bool _running = false;
  bool _intentionallyDisconnected = false;
  int _failedAttempts = 0;
  final Random _random = Random();
  String? _vendorId;
  DateTime? _lastEventAt;
  String? _lastEventId;
  final Map<String, int> _resourceRevisions = <String, int>{};
  final Set<String> _pendingResources = <String>{};
  bool _resourceSyncInFlight = false;
  int _resourceSyncFailures = 0;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _intentionallyDisconnected = false;
    WidgetsBinding.instance.addObserver(this);
    // Starts only after vendor authentication/onboarding, which is the right
    // point to request notification access. The inbox works if this is denied.
    unawaited(VendorNotificationService.requestPermission());
    await _connect();
  }

  Future<void> stop() async {
    _running = false;
    _intentionallyDisconnected = true;
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _resourceSyncTimer?.cancel();
    _resourceSyncTimer = null;
    _pendingResources.clear();
    _resourceRevisions.clear();
    _resourceSyncFailures = 0;
    await _closeSocket();
    state.value = VendorRealtimeState.stopped;
    store.reset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (!_running) return;
    if (appState == AppLifecycleState.resumed) {
      _intentionallyDisconnected = false;
      _failedAttempts = 0;
      _connect();
      if (_pendingResources.isNotEmpty) _scheduleResourceSync();
    } else if (appState == AppLifecycleState.inactive ||
        appState == AppLifecycleState.paused ||
        appState == AppLifecycleState.detached) {
      // Background networking is not reliable on mobile. FCM will cover the
      // offline/background alert path; release this foreground-only socket.
      _intentionallyDisconnected = true;
      _closeSocket();
      state.value = VendorRealtimeState.stopped;
    }
  }

  Future<void> _connect() async {
    if (!_running || _channel != null) return;
    _reconnectTimer?.cancel();
    state.value = _failedAttempts == 0
        ? VendorRealtimeState.connecting
        : VendorRealtimeState.reconnecting;

    try {
      final ticketResponse = await VendorService.authPost(
        Uri.parse(ApiConfig.vendorRealtimeTicketUrl),
      );
      if (ticketResponse.statusCode < 200 || ticketResponse.statusCode >= 300) {
        throw StateError('Unable to obtain a realtime connection ticket.');
      }
      final decoded = jsonDecode(ticketResponse.body);
      final ticket = decoded is Map ? decoded['ticket']?.toString() ?? '' : '';
      final vendorId = decoded is Map ? decoded['vendor_id']?.toString() ?? '' : '';
      if (ticket.isEmpty) throw StateError('Realtime ticket was missing.');
      if (vendorId.isEmpty) throw StateError('Realtime vendor identity was missing.');
      await VendorCacheService.setActiveVendor(vendorId);
      await VendorNotificationService.reload();
      await _loadCursor(vendorId);

      final channel = WebSocketChannel.connect(
        ApiConfig.vendorOrdersSocketUri(
          ticket,
          after: _lastEventAt?.toUtc().toIso8601String(),
          afterEventId: _lastEventId,
        ),
      );
      _channel = channel;
      _socketSubscription = channel.stream.listen(
        _onSocketMessage,
        onError: (_, __) => _onSocketClosed(),
        onDone: _onSocketClosed,
        cancelOnError: true,
      );
      await channel.ready.timeout(const Duration(seconds: 10));
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        try {
          _channel?.sink.add(jsonEncode({'type': 'realtime.ping'}));
        } catch (_) {
          _onSocketClosed();
        }
        // The socket is the low-latency path. This compact manifest check is
        // deliberately silent and recovers any resource event that was lost
        // across a short network, worker, or process interruption.
        if (_running && !_intentionallyDisconnected) {
          unawaited(VendorService.refreshEssentialData());
        }
      });
    } catch (_) {
      await _closeSocket();
      _scheduleReconnect();
    }
  }

  void _onSocketMessage(dynamic message) {
    final event = VendorOrderEvent.tryParse(message);
    if (event != null) {
      _failedAttempts = 0;
      state.value = VendorRealtimeState.connected;
      if (store.apply(event)) {
        unawaited(VendorCacheService.upsertOrder(event.order));
        _saveCursor(eventId: event.eventId, occurredAt: event.occurredAt);
        _events.add(event);
      }
      return;
    }

    final resourceEvent = VendorResourceChangeEvent.tryParse(message);
    if (resourceEvent != null) {
      _failedAttempts = 0;
      state.value = VendorRealtimeState.connected;
      final currentRevision = _resourceRevisions[resourceEvent.resource] ?? 0;
      if (resourceEvent.revision > currentRevision) {
        _resourceRevisions[resourceEvent.resource] = resourceEvent.revision;
        _pendingResources.add(resourceEvent.resource);
        _scheduleResourceSync();
      }
      _saveCursor(
        eventId: resourceEvent.eventId,
        occurredAt: resourceEvent.occurredAt,
      );
      return;
    }

    // `realtime.subscribed` is the protocol acknowledgement, not an event.
    if (message is String && message.contains('realtime.subscribed')) {
      _failedAttempts = 0;
      state.value = VendorRealtimeState.connected;
    }
  }

  void _scheduleResourceSync({Duration delay = const Duration(milliseconds: 250)}) {
    if (_resourceSyncTimer != null || _resourceSyncInFlight) return;
    _resourceSyncTimer = Timer(delay, () async {
      _resourceSyncTimer = null;
      if (!_running ||
          _intentionallyDisconnected ||
          _resourceSyncInFlight ||
          _pendingResources.isEmpty) {
        return;
      }
      _resourceSyncInFlight = true;
      final resources = Set<String>.from(_pendingResources);
      _pendingResources.clear();
      var synced = false;
      try {
        synced = await VendorService.refreshResources(resources);
      } catch (_) {
        // Treat unexpected parsing/client errors like a transient network
        // failure. The resource invalidation remains queued below.
        synced = false;
      } finally {
        _resourceSyncInFlight = false;
        // Do not spin background retries or resurrect a logged-out session.
        // Resume will reconcile through the manifest and re-schedule pending
        // resources above.
        if (!_running || _intentionallyDisconnected) return;
        if (!synced) {
          _pendingResources.addAll(resources);
          _resourceSyncFailures += 1;
        } else {
          _resourceSyncFailures = 0;
        }
        if (_pendingResources.isNotEmpty) {
          final retrySeconds = min(60, 1 << min(_resourceSyncFailures, 6));
          _scheduleResourceSync(
            delay: synced
                ? const Duration(milliseconds: 250)
                : Duration(seconds: retrySeconds),
          );
        }
      }
    });
  }

  void _onSocketClosed() {
    _closeSocket();
    if (!_intentionallyDisconnected) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_running || _intentionallyDisconnected || _reconnectTimer != null) return;
    _failedAttempts += 1;
    final exponentialSeconds = min(60, 1 << min(_failedAttempts, 6));
    final jitterMillis = _random.nextInt(1000);
    state.value = VendorRealtimeState.reconnecting;
    _reconnectTimer = Timer(Duration(seconds: exponentialSeconds, milliseconds: jitterMillis), () {
      _reconnectTimer = null;
      _connect();
    });
  }

  Future<void> _closeSocket() async {
    final channel = _channel;
    _channel = null;
    final subscription = _socketSubscription;
    _socketSubscription = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await subscription?.cancel();
    await channel?.sink.close();
  }

  Future<void> _loadCursor(String vendorId) async {
    if (_vendorId == vendorId) return;
    _vendorId = vendorId;
    final preferences = await SharedPreferences.getInstance();
    _lastEventAt = DateTime.tryParse(
      preferences.getString('vendor_realtime_cursor_$vendorId') ?? '',
    );
    _lastEventId = preferences.getString('vendor_realtime_cursor_event_$vendorId');
  }

  void _saveCursor({required String eventId, required DateTime? occurredAt}) {
    if (occurredAt == null || _vendorId == null) return;
    final isOlder = _lastEventAt != null && occurredAt.isBefore(_lastEventAt!);
    final isSameOrOlderId = _lastEventAt != null &&
        occurredAt.isAtSameMomentAs(_lastEventAt!) &&
        _lastEventId != null &&
        eventId.compareTo(_lastEventId!) <= 0;
    if (isOlder || isSameOrOlderId) return;
    _lastEventAt = occurredAt;
    _lastEventId = eventId;
    SharedPreferences.getInstance().then(
      (preferences) async {
        await preferences.setString(
          'vendor_realtime_cursor_$_vendorId',
          occurredAt.toUtc().toIso8601String(),
        );
        await preferences.setString(
          'vendor_realtime_cursor_event_$_vendorId',
          eventId,
        );
      },
    );
  }
}
