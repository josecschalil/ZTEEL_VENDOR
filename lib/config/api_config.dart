import 'package:flutter/foundation.dart';

/// Global API Configuration for ZTEEL Vendor App
class ApiConfig {
  /// Base URL of the backend.
  static String baseUrl = 'http://20.235.180.249:8000';

  // ── Auth Endpoints ────────────────────────────────────────────────────────
  static String get sendOtpUrl => '$baseUrl/api/v1/auth/send-otp/';
  static String get vendorVerifyOtpUrl => '$baseUrl/api/v1/auth/vendor/verify-otp/';
  static String get tokenRefreshUrl => '$baseUrl/api/v1/auth/refresh/';
  static String get meUrl => '$baseUrl/api/v1/auth/me/';
  static String get logoutUrl => '$baseUrl/api/v1/auth/logout/';

  // ── Vendor Profile & Setup Endpoints ─────────────────────────────────────
  static String get vendorProfileUrl => '$baseUrl/api/v1/vendor/profile/';
  static String get vendorBusinessHoursUrl => '$baseUrl/api/v1/vendor/hours/';
  static String get vendorMenuCategoriesUrl => '$baseUrl/api/v1/vendor/menu-categories/';
  static String vendorMenuCategoryDetailUrl(String id) => '$baseUrl/api/v1/vendor/menu-categories/$id/';
  static String get vendorMenuItemsUrl => '$baseUrl/api/v1/vendor/menu-items/';
  static String vendorMenuItemDetailUrl(String id) => '$baseUrl/api/v1/vendor/menu-items/$id/';
  static String get vendorOffersUrl => '$baseUrl/api/v1/vendor/offers/';
  static String vendorOfferDetailUrl(String id) => '$baseUrl/api/v1/vendor/offers/$id/';
  static String get vendorRedemptionsUrl => '$baseUrl/api/v1/vendor/redemptions/';
  static String vendorScanRedemptionUrl(String qrCode) => '$baseUrl/api/v1/vendor/redemptions/$qrCode/scan/';

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

