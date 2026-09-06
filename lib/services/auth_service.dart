import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/config/api_config.dart';

class AuthService {
  static const String _keyAccess = 'access_token';
  static const String _keyRefresh = 'refresh_token';
  static const String _keyPhone = 'phone_number';
  static const String _keyIsOnboarded = 'is_onboarded';
  static const String _keyIsLoggedIn = 'is_logged_in';

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

  /// Save login session to persistent local storage
  static Future<void> saveSession({
    required String access,
    required String refresh,
    required String phone,
    required bool isOnboarded,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess, access);
    await prefs.setString(_keyRefresh, refresh);
    await prefs.setString(_keyPhone, phone);
    await prefs.setBool(_keyIsOnboarded, isOnboarded);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Check if user has an active saved login session
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final access = prefs.getString(_keyAccess);
    return loggedIn && access != null && access.isNotEmpty;
  }

  /// Check if the vendor has completed shop onboarding
  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsOnboarded) ?? false;
  }

  /// Clear session on logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyIsOnboarded);
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
      );

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
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final access = data['access']?.toString() ?? '';
        final refresh = data['refresh']?.toString() ?? '';
        final isOnboarded = data['is_onboarded'] as bool? ?? false;

        if (access.isNotEmpty) {
          await saveSession(
            access: access,
            refresh: refresh,
            phone: phone,
            isOnboarded: isOnboarded,
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
