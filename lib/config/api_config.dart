/// Global API Configuration for ZTEEL Vendor App
class ApiConfig {
  /// Base URL of the backend.
  static String baseUrl = 'https://api.zteel.in';

  // ── Auth Endpoints ────────────────────────────────────────────────────────
  static String get sendOtpUrl => '$baseUrl/api/v1/auth/send-otp/';
  static String get vendorVerifyOtpUrl =>
      '$baseUrl/api/v1/auth/vendor/verify-otp/';
  static String get tokenRefreshUrl => '$baseUrl/api/v1/auth/refresh/';
  static String get meUrl => '$baseUrl/api/v1/auth/me/';
  static String get logoutUrl => '$baseUrl/api/v1/auth/logout/';
  static String get deleteAccountUrl => '$baseUrl/api/v1/auth/delete-account/';

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
    final parsed = Uri.tryParse(path);
    if (parsed != null && parsed.hasScheme) {
      // Production API responses may contain legacy `http://zteel.in/media/...`
      // URLs. Loading those from the HTTPS vendor web app is mixed content, so
      // keep media on the configured secure API origin.
      final api = Uri.parse(baseUrl);
      final isKnownApiHost = {
        'zteel.in',
        'api.zteel.in',
        '68.233.116.23',
      }.contains(parsed.host);
      if (isKnownApiHost &&
          (parsed.scheme != api.scheme ||
              parsed.host != api.host ||
              parsed.port != api.port)) {
        return api
            .replace(path: parsed.path, query: parsed.hasQuery ? parsed.query : null)
            .toString();
      }
      return path;
    }
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }
    return '$baseUrl/$path';
  }
}
