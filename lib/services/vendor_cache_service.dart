import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encrypted, vendor-scoped persistent cache for data that is safe to view
/// offline. Network writes are never inferred from this cache.
///
/// Values are stored as JSON envelopes rather than Hive objects so migrations
/// remain backwards-compatible with API response shape changes.
class VendorCacheEntry<T> {
  const VendorCacheEntry({
    required this.value,
    required this.savedAt,
  });

  final T value;
  final DateTime savedAt;

  bool isFresh(Duration maxAge) =>
      DateTime.now().toUtc().difference(savedAt) <= maxAge;
}

class VendorCacheService {
  VendorCacheService._();

  static const _boxName = 'vendor_offline_cache_v1';
  static const _encryptionKeyName = 'vendor_offline_cache_key_v1';
  static const _activeVendorPreference = 'vendor_cache_active_vendor_id';
  static const _sessionOwnerPreference = 'vendor_cache_session_owner';
  static const _schemaVersion = 1;
  static const _storage = FlutterSecureStorage();

  static Future<void>? _initializing;
  static Box<String>? _box;
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static Future<void> initialize() => _initializing ??= _open();

  static Future<void> _open() async {
    await Hive.initFlutter();
    var encodedKey = await _storage.read(key: _encryptionKeyName);
    if (encodedKey == null || encodedKey.isEmpty) {
      encodedKey = base64UrlEncode(Hive.generateSecureKey());
      await _storage.write(key: _encryptionKeyName, value: encodedKey);
    }
    final Uint8List encryptionKey = base64Url.decode(base64Url.normalize(encodedKey));
    try {
      _box = await Hive.openBox<String>(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (_) {
      // A partially written cache or a key restored without its box must not
      // prevent sign-in. It is safe to rebuild cache-only data from the API.
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<String>(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    }
  }

  static Future<String?> _activeVendorId() async {
    final preferences = await SharedPreferences.getInstance();
    final id = preferences.getString(_activeVendorPreference)?.trim();
    return id == null || id.isEmpty ? null : id;
  }

  static Future<void> setActiveVendor(String vendorId) async {
    if (vendorId.trim().isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_activeVendorPreference, vendorId.trim());
  }

  /// Prevents a cached vendor's data being exposed after a different account
  /// authenticates on the same device.
  static Future<void> beginSession(String phone) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final previousOwner = preferences.getString(_sessionOwnerPreference);
    if (previousOwner != null && previousOwner != normalizedPhone) {
      final previousVendor = preferences.getString(_activeVendorPreference);
      if (previousVendor != null && previousVendor.isNotEmpty) {
        await _deleteVendorData(previousVendor);
      }
      await preferences.remove(_activeVendorPreference);
    }
    await preferences.setString(_sessionOwnerPreference, normalizedPhone);
  }

  static String _key(String vendorId, String resource) =>
      'v:$vendorId:$resource';

  static Future<VendorCacheEntry<dynamic>?> read(String resource) async {
    await initialize();
    final vendorId = await _activeVendorId();
    if (vendorId == null) return null;
    final raw = _box?.get(_key(vendorId, resource));
    if (raw == null) return null;
    try {
      final envelope = jsonDecode(raw);
      if (envelope is! Map || envelope['schema'] != _schemaVersion) return null;
      final savedAt = DateTime.tryParse(envelope['saved_at']?.toString() ?? '');
      if (savedAt == null || !envelope.containsKey('value')) return null;
      return VendorCacheEntry<dynamic>(
        value: envelope['value'],
        savedAt: savedAt.toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> readMap(String resource) async {
    final entry = await read(resource);
    final value = entry?.value;
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static Future<List<dynamic>?> readList(String resource) async {
    final entry = await read(resource);
    final value = entry?.value;
    return value is List ? List<dynamic>.from(value) : null;
  }

  static Future<VendorCacheEntry<dynamic>?> readEntry(String resource) =>
      read(resource);

  static Future<void> write(String resource, Object value) async {
    await initialize();
    final vendorId = await _activeVendorId();
    if (vendorId == null) return;
    // JSON round-trip rejects unsupported values before they reach storage and
    // detaches callers from the cached object graph.
    final detachedValue = jsonDecode(jsonEncode(value));
    await _box?.put(
      _key(vendorId, resource),
      jsonEncode({
        'schema': _schemaVersion,
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'value': detachedValue,
      }),
    );
    revision.value++;
  }

  static Future<void> writeProfile(Map<String, dynamic> profile) async {
    final vendorId = profile['id']?.toString().trim() ?? '';
    if (vendorId.isEmpty) return;
    await setActiveVendor(vendorId);
    await write('profile', profile);
  }

  static Future<void> upsertListRecord(
    String resource,
    Map<String, dynamic> record,
  ) async {
    final id = record['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final current = await readList(resource) ?? <dynamic>[];
    final next = List<dynamic>.from(current);
    final index = next.indexWhere(
      (value) => value is Map && value['id']?.toString() == id,
    );
    if (index >= 0) {
      next[index] = record;
    } else {
      next.insert(0, record);
    }
    await write(resource, next);
  }

  static Future<void> removeListRecord(String resource, String id) async {
    final current = await readList(resource);
    if (current == null) return;
    await write(
      resource,
      current
          .where((value) => value is! Map || value['id']?.toString() != id)
          .toList(),
    );
  }

  /// Persists a bounded recent order history. The server remains authoritative
  /// for confirmation, expiration, and all QR-code state transitions.
  static Future<void> upsertOrder(Map<String, dynamic> order) async {
    final id = order['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final current = await readList('orders') ?? <dynamic>[];
    final next = List<dynamic>.from(current);
    final index = next.indexWhere(
      (value) => value is Map && value['id']?.toString() == id,
    );
    if (index >= 0) {
      next[index] = order;
    } else {
      next.insert(0, order);
    }
    next.sort((left, right) {
      final leftTime = left is Map ? left['created_at']?.toString() ?? '' : '';
      final rightTime = right is Map ? right['created_at']?.toString() ?? '' : '';
      return rightTime.compareTo(leftTime);
    });
    await write('orders', next.take(500).toList());
  }

  static Future<void> invalidate(String resource) async {
    await initialize();
    final vendorId = await _activeVendorId();
    if (vendorId == null) return;
    await _box?.delete(_key(vendorId, resource));
    revision.value++;
  }

  /// Causes cache-backed screens to rebuild their current snapshot. This is
  /// useful after a connectivity transition: the JSON may be unchanged, but
  /// failed network image providers need another chance to resolve.
  static void notifyVisibleDataMayHaveChanged() {
    revision.value++;
  }

  /// Used only on explicit logout. This is a privacy boundary, not a normal
  /// cache eviction path.
  static Future<void> clearActiveVendorData() async {
    await initialize();
    final preferences = await SharedPreferences.getInstance();
    final vendorId = await _activeVendorId();
    if (vendorId != null) {
      await _deleteVendorData(vendorId);
    }
    await preferences.remove(_activeVendorPreference);
    await preferences.remove(_sessionOwnerPreference);
    revision.value++;
  }

  static Future<void> _deleteVendorData(String vendorId) async {
    final prefix = 'v:$vendorId:';
    final keys = _box?.keys
            .whereType<String>()
            .where((key) => key.startsWith(prefix))
            .toList() ??
        const <String>[];
    await _box?.deleteAll(keys);
  }
}
