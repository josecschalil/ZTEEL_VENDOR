import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/vendor_cache_service.dart';

class AuthService {
  static const String _keyAccess = 'access_token';
  static const String _keyRefresh = 'refresh_token';
  static const String _keyPhone = 'phone_number';
  static const String _keyIsOnboarded = 'is_onboarded';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyBusinessName = 'business_name';

  static const _storage = FlutterSecureStorage();
  static Completer<String?>? _refreshCompleter;

  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      return '+$cleaned';
    }
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }
    if (phone.startsWith('+')) {
      return phone;
    }
    return '+91$cleaned';
  }

  /// Decode JWT payload without third-party dependencies and check expiration.
  static bool isTokenExpired(String? token, {int thresholdSeconds = 60}) {
    if (token == null || token.trim().isEmpty) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      var normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = map['exp'] as int?;
      if (exp == null) return false;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate.subtract(Duration(seconds: thresholdSeconds)));
    } catch (_) {
      return false;
    }
  }

  /// Save login session to persistent local storage
  static Future<void> saveSession({
    required String access,
    required String refresh,
    required String phone,
    required bool isOnboarded,
    String? businessName,
  }) async {
    await VendorCacheService.beginSession(phone);
    if (access.isNotEmpty) await _storage.write(key: _keyAccess, value: access);
    if (refresh.isNotEmpty) await _storage.write(key: _keyRefresh, value: refresh);
    
    final prefs = await SharedPreferences.getInstance();
    if (phone.isNotEmpty) await prefs.setString(_keyPhone, phone);
    await prefs.setBool(_keyIsOnboarded, isOnboarded);
    await prefs.setBool(_keyIsLoggedIn, true);
    if (businessName != null && businessName.isNotEmpty) {
      await prefs.setString(_keyBusinessName, businessName);
    }
  }

  /// Retrieve raw stored access token without refresh check
  static Future<String?> getRawAccessToken() async {
    return await _storage.read(key: _keyAccess);
  }

  /// Retrieve stored refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefresh);
  }

  /// Get a guaranteed valid access token, auto-refreshing via refresh token if expired.
  static Future<String?> getValidAccessToken() async {
    final access = await _storage.read(key: _keyAccess);
    final refresh = await _storage.read(key: _keyRefresh);

    // If access token is still fresh, return it directly
    if (access != null && access.isNotEmpty && !isTokenExpired(access)) {
      return access;
    }

    // If access token is expired or missing, but we have a refresh token, refresh it
    if (refresh != null && refresh.isNotEmpty) {
      final refreshed = await refreshSession(force: true);
      if (refreshed != null && refreshed.isNotEmpty) {
        return refreshed;
      }
    }

    // Return whatever access token we have as fallback (e.g. offline)
    return access;
  }

  /// Refreshes the JWT session using the stored refresh token.
  /// Deduplicates concurrent calls via a Completer mutex to prevent race conditions.
  static Future<String?> refreshSession({bool force = false}) async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final refresh = await _storage.read(key: _keyRefresh);
      final currentAccess = await _storage.read(key: _keyAccess);

      if (refresh == null || refresh.isEmpty) {
        completer.complete(currentAccess);
        return currentAccess;
      }

      if (!force && currentAccess != null && !isTokenExpired(currentAccess)) {
        completer.complete(currentAccess);
        return currentAccess;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.tokenRefreshUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['access']?.toString();
        final newRefresh = data['refresh']?.toString();

        if (newAccess != null && newAccess.isNotEmpty) {
          await _storage.write(key: _keyAccess, value: newAccess);
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await _storage.write(key: _keyRefresh, value: newRefresh);
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyIsLoggedIn, true);
          completer.complete(newAccess);
          return newAccess;
        }
      }

      // If server or network error, do NOT logout. Return currentAccess for offline resilience.
      completer.complete(currentAccess);
      return currentAccess;
    } catch (_) {
      // Network error or timeout: keep existing token
      final currentAccess = await _storage.read(key: _keyAccess);
      completer.complete(currentAccess);
      return currentAccess;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Check if user has an active saved login session.
  /// Persistently true unless explicitly logged out or app data wiped.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccess = ((await _storage.read(key: _keyAccess))?.trim().isNotEmpty ?? false);
    final hasRefresh = ((await _storage.read(key: _keyRefresh))?.trim().isNotEmpty ?? false);
    final loggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (hasAccess || hasRefresh) {
      if (!loggedIn) {
        await prefs.setBool(_keyIsLoggedIn, true);
      }
      return true;
    }
    return loggedIn;
  }

  /// Check if the vendor has completed shop onboarding
  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsOnboarded) ?? false;
  }

  /// Update the onboarding state in persistent storage
  static Future<void> setOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsOnboarded, value);
  }

  /// Clear session on explicit logout
  static Future<void> logout() async {
    final refresh = await _storage.read(key: _keyRefresh);

    if (refresh != null && refresh.isNotEmpty) {
      try {
        await http.post(
          Uri.parse(ApiConfig.logoutUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refresh}),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {
        // Ignore network errors on logout
      }
    }

    await VendorCacheService.clearActiveVendorData();
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyIsOnboarded);
    await prefs.remove(_keyBusinessName);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  /// Sends OTP to the provided mobile number via backend.
  static Future<Map<String, dynamic>> sendOtp(String rawPhone) async {
    final phone = formatPhoneNumber(rawPhone);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phone}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'phone_number': phone,
          'dev_otp': data['dev_otp']?.toString(),
          'detail': data['detail'] ?? 'OTP sent successfully.',
        };
      } else {
        return {
          'success': false,
          'error': data['detail'] ??
              data['phone_number']?.first ??
              'Failed to send OTP.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error while reaching backend: $e',
      };
    }
  }

  /// Verifies vendor OTP with backend.
  static Future<Map<String, dynamic>> verifyVendorOtp({
    required String rawPhone,
    required String otp,
  }) async {
    final phone = formatPhoneNumber(rawPhone);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.vendorVerifyOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phone,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final access = data['access']?.toString() ?? '';
        final refresh = data['refresh']?.toString() ?? '';
        final isOnboarded = data['is_onboarded'] as bool? ?? false;
        final businessName = data['business_name']?.toString() ?? '';

        if (access.isNotEmpty) {
          await saveSession(
            access: access,
            refresh: refresh,
            phone: phone,
            isOnboarded: isOnboarded,
            businessName: businessName,
          );
        }

        return {
          'success': true,
          'access': access,
          'refresh': refresh,
          'role': data['role'],
          'is_onboarded': isOnboarded,
          'created': data['created'] ?? false,
        };
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Invalid OTP or verification failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error while verifying OTP: $e',
      };
    }
  }
}
