/// Global API Configuration for ZTEEL Vendor App
class ApiConfig {
  /// Base URL of the backend.
  static String baseUrl = 'http://68.233.116.23:8000';

  // ── Auth Endpoints ────────────────────────────────────────────────────────
  static String get sendOtpUrl => '$baseUrl/api/v1/auth/send-otp/';
  static String get vendorVerifyOtpUrl =>
      '$baseUrl/api/v1/auth/vendor/verify-otp/';
  static String get tokenRefreshUrl => '$baseUrl/api/v1/auth/refresh/';
  static String get meUrl => '$baseUrl/api/v1/auth/me/';
  static String get logoutUrl => '$baseUrl/api/v1/auth/logout/';

  // ── Vendor Profile & Setup Endpoints ─────────────────────────────────────
  static String get vendorProfileUrl => '$baseUrl/api/v1/vendor/profile/';
  static String get vendorCacheManifestUrl =>
      '$baseUrl/api/v1/vendor/cache-manifest/';
  static String get vendorBusinessHoursUrl => '$baseUrl/api/v1/vendor/hours/';
  static String get vendorMenuCategoriesUrl =>
      '$baseUrl/api/v1/vendor/menu-categories/';
  static String vendorMenuCategoryDetailUrl(String id) =>
      '$baseUrl/api/v1/vendor/menu-categories/$id/';
  static String get vendorMenuItemsUrl => '$baseUrl/api/v1/vendor/menu-items/';
  static String vendorMenuItemDetailUrl(String id) =>
      '$baseUrl/api/v1/vendor/menu-items/$id/';
  static String get vendorOffersUrl => '$baseUrl/api/v1/vendor/offers/';
  static String get vendorOfferMasterStatusUrl =>
      '$baseUrl/api/v1/vendor/offers/master-status/';
  static String vendorOfferDetailUrl(String id) =>
      '$baseUrl/api/v1/vendor/offers/$id/';
  static String get vendorRewardMilestonesUrl =>
      '$baseUrl/api/v1/vendor/reward-milestones/';
  static String vendorRewardMilestoneDetailUrl(String id) =>
      '$baseUrl/api/v1/vendor/reward-milestones/$id/';
  static String get vendorRedemptionsUrl =>
      '$baseUrl/api/v1/vendor/redemptions/';
  static String vendorScanRedemptionUrl(String qrCode) =>
      '$baseUrl/api/v1/vendor/redemptions/$qrCode/scan/';
  static String vendorRejectRedemptionUrl(String qrCode) =>
      '$baseUrl/api/v1/vendor/redemptions/$qrCode/reject/';
  static String get vendorReviewsUrl => '$baseUrl/api/v1/vendor/reviews/';

  // ── Realtime order endpoints ──────────────────────────────────────────────
  static String get vendorRealtimeTicketUrl =>
      '$baseUrl/api/v1/realtime/vendor-ticket/';

  /// Builds `ws://` locally and `wss://` for HTTPS deployments.
  static Uri vendorOrdersSocketUri(
    String ticket, {
    String? after,
    String? afterEventId,
  }) {
    final api = Uri.parse(baseUrl);
    return api.replace(
      scheme: api.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/v1/vendor/orders/',
      queryParameters: {
        'ticket': ticket,
        if (after != null && after.isNotEmpty) 'after': after,
        if (afterEventId != null && afterEventId.isNotEmpty)
          'after_event_id': afterEventId,
      },
    );
  }

  /// Helper to convert relative media path to full backend URL
  static String? getImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }
    return '$baseUrl/$path';
  }
}
