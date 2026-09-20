import 'package:flutter/foundation.dart';
import 'package:frontend/services/vendor_service.dart';

/// Singleton that holds the live shop open/close state.
///
/// All screens subscribe to [status] via [ValueListenableBuilder] so that
/// toggling on any screen updates every other screen that is currently alive.
class ShopStatusService {
  ShopStatusService._();
  static final ShopStatusService instance = ShopStatusService._();

  /// `true` = OPEN, `false` = CLOSED.
  final ValueNotifier<bool> status = ValueNotifier<bool>(true);

  bool _initialized = false;

  /// Fetches the real status from the backend (no-op if already done once).
  /// Call from any screen's [initState].
  Future<void> ensureLoaded() async {
    if (_initialized) return;
    await _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final res = await VendorService.getVendorProfile();
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      status.value = data['is_open_now'] as bool? ?? true;
    }
    _initialized = true;
  }

  /// Optimistically toggles the status and persists to backend.
  /// Returns `true` if the API call succeeded.
  Future<bool> toggle(bool newOpen) async {
    final previous = status.value;
    // Optimistic update — all listening widgets rebuild immediately.
    status.value = newOpen;

    final override = newOpen ? 'open' : 'closed';
    final res = await VendorService.updateAvailabilityOverride(override);

    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      // Confirm with the value the server reports.
      status.value = data['is_open_now'] as bool? ?? newOpen;
      return true;
    } else {
      // Revert on failure.
      status.value = previous;
      return false;
    }
  }
}
