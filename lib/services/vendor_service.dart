import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/auth_service.dart';

class VendorService {
  static Future<String?> _getAccessToken() async {
    return await AuthService.getValidAccessToken();
  }

  /// Centralized authenticated request runner with automatic 401 token refresh & retry.
  static Future<http.Response> _sendWithAuth(
    Future<http.Response> Function(String token) requestFn,
  ) async {
    var token = await AuthService.getValidAccessToken();
    if (token == null || token.isEmpty) {
      token = await AuthService.refreshSession(force: true);
    }
    if (token == null || token.isEmpty) {
      return http.Response(
        jsonEncode({'detail': 'No active session found. Please sign in.'}),
        401,
      );
    }

    var response = await requestFn(token);

    // If 401 Unauthorized, perform token refresh and retry once
    if (response.statusCode == 401) {
      final newToken = await AuthService.refreshSession(force: true);
      if (newToken != null && newToken.isNotEmpty) {
        response = await requestFn(newToken);
      }
    }

    return response;
  }

  static Future<http.Response> authGet(Uri uri, {Map<String, String>? headers}) {
    return _sendWithAuth((token) => http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      },
    ).timeout(const Duration(seconds: 15)));
  }

  static Future<http.Response> authPost(Uri uri, {Map<String, String>? headers, Object? body}) {
    return _sendWithAuth((token) => http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      },
      body: body is String ? body : (body != null ? jsonEncode(body) : null),
    ).timeout(const Duration(seconds: 15)));
  }

  static Future<http.Response> authPatch(Uri uri, {Map<String, String>? headers, Object? body}) {
    return _sendWithAuth((token) => http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      },
      body: body is String ? body : (body != null ? jsonEncode(body) : null),
    ).timeout(const Duration(seconds: 15)));
  }

  static Future<http.Response> authPut(Uri uri, {Map<String, String>? headers, Object? body}) {
    return _sendWithAuth((token) => http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      },
      body: body is String ? body : (body != null ? jsonEncode(body) : null),
    ).timeout(const Duration(seconds: 15)));
  }

  static Future<http.Response> authDelete(Uri uri, {Map<String, String>? headers, Object? body}) {
    return _sendWithAuth((token) => http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      },
      body: body is String ? body : (body != null ? jsonEncode(body) : null),
    ).timeout(const Duration(seconds: 15)));
  }

  static String _extractApiError(dynamic data, [String fallback = 'Operation failed.']) {
    if (data is Map) {
      if (data['detail'] != null && data['detail'].toString().isNotEmpty) {
        return data['detail'].toString();
      }
      if (data['error'] != null && data['error'].toString().isNotEmpty) {
        return data['error'].toString();
      }
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        return data['message'].toString();
      }
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    } else if (data is String && data.isNotEmpty) {
      return data;
    }
    return fallback;
  }

  /// Fetch vendor profile from backend
  static Future<Map<String, dynamic>> getVendorProfile() async {
    try {
      final response = await authGet(Uri.parse(ApiConfig.vendorProfileUrl));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        data['icon_image'] = ApiConfig.getImageUrl(data['icon_image']?.toString());
        data['cover_image'] = ApiConfig.getImageUrl(data['cover_image']?.toString());

        final businessName = data['business_name']?.toString().trim() ?? '';
        final isOnboarded = data['is_onboarded'] as bool? ?? false;
        if (businessName.isNotEmpty || isOnboarded) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('business_name', businessName);
          await AuthService.setOnboarded(true);
        }

        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': _extractApiError(data, 'Failed to fetch vendor profile.')};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Check if the logged in vendor phone number already has shop data created
  static Future<bool> hasExistingShopData() async {
    final localOnboarded = await AuthService.isOnboarded();
    if (localOnboarded) return true;

    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('business_name')?.trim() ?? '';
    if (cachedName.isNotEmpty) {
      await AuthService.setOnboarded(true);
      return true;
    }

    final res = await getVendorProfile();
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      final businessName = data['business_name']?.toString().trim() ?? '';
      final isOnboarded = data['is_onboarded'] as bool? ?? false;
      if (businessName.isNotEmpty || isOnboarded) {
        await prefs.setString('business_name', businessName);
        await AuthService.setOnboarded(true);
        return true;
      }
    } else {
      // If network error occurred, but user is logged in, do not kick them to SetupShopScreen
      final loggedIn = await AuthService.isLoggedIn();
      final err = res['error']?.toString() ?? '';
      if (loggedIn && (err.contains('Network') || err.contains('SocketException') || err.contains('Timeout'))) {
        return true;
      }
    }
    return false;
  }

  /// Update vendor profile (business_name, address, category, lat, long, shop_description, images)
  static Future<Map<String, dynamic>> updateVendorProfile({
    required String businessName,
    required String shopDescription,
    required String address,
    required String category,
    required double latitude,
    required double longitude,
    File? iconImage,
    File? coverImage,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final uri = Uri.parse(ApiConfig.vendorProfileUrl);

      if (iconImage != null || coverImage != null) {
        // Multipart request for image upload support
        final request = http.MultipartRequest('PATCH', uri);
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['business_name'] = businessName;
        request.fields['shop_description'] = shopDescription;
        request.fields['address'] = address;
        request.fields['category'] = category.toLowerCase();
        request.fields['latitude'] = latitude.toString();
        request.fields['longitude'] = longitude.toString();

        if (iconImage != null) {
          request.files.add(await http.MultipartFile.fromPath('icon_image', iconImage.path));
        }
        if (coverImage != null) {
          request.files.add(await http.MultipartFile.fromPath('cover_image', coverImage.path));
        }

        final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
        final response = await http.Response.fromStream(streamedResponse);
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 200 || response.statusCode == 201) {
          final isOnboarded = data['is_onboarded'] as bool? ?? true;
          // Refresh local onboarding state
          await AuthService.saveSession(
            access: token,
            refresh: (await SharedPreferences.getInstance()).getString('refresh_token') ?? '',
            phone: (await SharedPreferences.getInstance()).getString('phone_number') ?? '',
            isOnboarded: isOnboarded,
            businessName: businessName,
          );
          return {'success': true, 'data': data};
        } else {
          return {'success': false, 'error': _extractApiError(data, 'Failed to update shop profile.')};
        }
      } else {
        // JSON request
        final response = await http.patch(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'business_name': businessName,
            'shop_description': shopDescription,
            'address': address,
            'category': category.toLowerCase(),
            'latitude': latitude,
            'longitude': longitude,
          }),
        ).timeout(const Duration(seconds: 15));

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode == 200 || response.statusCode == 201) {
          final isOnboarded = data['is_onboarded'] as bool? ?? true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_onboarded', isOnboarded);
          await prefs.setString('business_name', businessName);
          return {'success': true, 'data': data};
        } else {
          return {'success': false, 'error': _extractApiError(data, 'Failed to update shop profile.')};
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Error saving shop profile: $e'};
    }
  }

  /// Remove icon image or cover image from the vendor profile
  static Future<Map<String, dynamic>> removeVendorImage({
    bool removeIcon = false,
    bool removeCover = false,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final Map<String, dynamic> body = {};
      if (removeIcon) body['icon_image'] = null;
      if (removeCover) body['cover_image'] = null;

      final response = await http.patch(
        Uri.parse(ApiConfig.vendorProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          if (data is Map<String, dynamic>) 'data': data,
        };
      } else {
        if (data != null) {
          return {
            'success': false,
            'error': _extractApiError(data, 'Failed to remove image.')
          };
        } else {
          return {
            'success': false,
            'error': 'Server returned status ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Error removing image: $e'};
    }
  }

  /// Update the vendor's shop open/closed override.
  /// [override] should be one of: "open", "closed", "auto".
  static Future<Map<String, dynamic>> updateAvailabilityOverride(String override) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.patch(
        Uri.parse(ApiConfig.vendorProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'availability_override': override}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['detail'] ?? data.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Update vendor business hours schedule
  static Future<Map<String, dynamic>> updateBusinessHours(List<Map<String, dynamic>> daysSchedule) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.vendorBusinessHoursUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'days': daysSchedule}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['detail'] ?? 'Failed to update business hours.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error saving business hours: $e'};
    }
  }

  /// Immediately upload an icon or cover image as soon as selected
  static Future<Map<String, dynamic>> uploadSingleImage({
    File? iconImage,
    File? coverImage,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final uri = Uri.parse(ApiConfig.vendorProfileUrl);
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $token';

      if (iconImage != null) {
        request.files.add(await http.MultipartFile.fromPath('icon_image', iconImage.path));
      }
      if (coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath('cover_image', coverImage.path));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'icon_image': ApiConfig.getImageUrl(data['icon_image']?.toString()),
          'cover_image': ApiConfig.getImageUrl(data['cover_image']?.toString()),
          'data': data,
        };
      } else {
        return {'success': false, 'error': _extractApiError(data, 'Failed to upload image.')};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error uploading image: $e'};
    }
  }

  // ── Menu Categories CRUD ──────────────────────────────────────────────────

  static Future<List<dynamic>> _fetchAllPages(String initialUrl, String token) async {
    List<dynamic> allResults = [];
    String? nextUrl = initialUrl;

    while (nextUrl != null) {
      final response = await http.get(
        Uri.parse(nextUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          allResults.addAll(data);
          break;
        } else if (data is Map<String, dynamic>) {
          allResults.addAll(data['results'] ?? []);
          nextUrl = data['next']?.toString();
        } else {
          break;
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Failed to fetch list.');
      }
    }
    return allResults;
  }

  /// Get all menu categories for vendor
  static Future<Map<String, dynamic>> getMenuCategories() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final list = await _fetchAllPages(ApiConfig.vendorMenuCategoriesUrl, token);
      return {'success': true, 'data': list};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a menu category
  static Future<Map<String, dynamic>> createMenuCategory({
    required String name,
    int order = 0,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.vendorMenuCategoriesUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'order': order,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        String errorMsg = 'Failed to create category';
        if (data is Map && data.containsKey('name')) {
          final errs = data['name'];
          errorMsg = (errs is List) ? errs.join(', ') : errs.toString();
        } else if (data is Map && data.containsKey('detail')) {
          errorMsg = data['detail'].toString();
        }
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error creating category: $e'};
    }
  }

  /// Update a menu category
  static Future<Map<String, dynamic>> updateMenuCategory({
    required String id,
    required String name,
    int order = 0,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.patch(
        Uri.parse(ApiConfig.vendorMenuCategoryDetailUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'order': order,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        String errorMsg = 'Failed to update category';
        if (data is Map && data.containsKey('name')) {
          final errs = data['name'];
          errorMsg = (errs is List) ? errs.join(', ') : errs.toString();
        } else if (data is Map && data.containsKey('detail')) {
          errorMsg = data['detail'].toString();
        }
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error updating category: $e'};
    }
  }

  /// Delete a menu category
  static Future<Map<String, dynamic>> deleteMenuCategory(String id) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.vendorMenuCategoryDetailUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        String err = data['detail'] ?? 'Failed to delete category.';
        if (data is List && data.isNotEmpty) err = data.first.toString();
        return {'success': false, 'error': err};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error deleting category: $e'};
    }
  }

  // ── Menu Items Tag & Description Helpers ───────────────────────────

  /// Encodes description with veg/non-veg metadata tag so it persists without backend schema changes
  static String encodeDescription(String? desc, bool? isVegetarian) {
    final clean = cleanDescription(desc);
    if (isVegetarian == null) return clean;
    return isVegetarian ? '$clean [VEG]'.trim() : '$clean [NON-VEG]'.trim();
  }

  /// Strips [VEG] or [NON-VEG] tag from description for UI display
  static String cleanDescription(String? desc) {
    if (desc == null) return '';
    return desc.replaceAll(RegExp(r'\s*\[(VEG|NON-VEG)\]'), '').trim();
  }

  /// Parses vegetarian boolean state from item map
  static bool parseIsVegetarian(Map<String, dynamic> item) {
    if (item['is_vegetarian'] is bool) {
      return item['is_vegetarian'] as bool;
    }
    final desc = item['description']?.toString() ?? '';
    if (desc.contains('[VEG]')) return true;
    if (desc.contains('[NON-VEG]')) return false;
    return false;
  }

  // ── Menu Items CRUD ────────────────────────────────────────────────────────

  /// Get menu items (optionally filtered by category_id)
  static Future<Map<String, dynamic>> getMenuItems({String? categoryId}) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      var urlStr = ApiConfig.vendorMenuItemsUrl;
      if (categoryId != null && categoryId.isNotEmpty) {
        urlStr += '?category_id=$categoryId';
      }

      final list = await _fetchAllPages(urlStr, token);

      if (categoryId != null && categoryId.isNotEmpty) {
        final filtered = list.where((item) {
          if (item is Map<String, dynamic>) {
            final catField = item['category'];
            if (catField is String) return catField == categoryId;
            if (catField is Map) return catField['id']?.toString() == categoryId;
          }
          return false;
        }).toList();
        return {'success': true, 'data': filtered};
      }

      return {'success': true, 'data': list};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a new menu item
  static Future<Map<String, dynamic>> createMenuItem({
    required String name,
    required String categoryId,
    required double price,
    String description = '',
    bool isVegetarian = false,
    bool isAvailable = true,
    File? image,
  }) async {
    try {
      final response = await _sendWithAuth((token) async {
        final uri = Uri.parse(ApiConfig.vendorMenuItemsUrl);
        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['name'] = name;
        request.fields['category'] = categoryId;
        request.fields['price'] = price.toStringAsFixed(2);
        request.fields['description'] = encodeDescription(description, isVegetarian);
        request.fields['is_vegetarian'] = isVegetarian.toString();
        request.fields['is_available'] = isAvailable.toString();

        if (image != null) {
          request.files.add(await http.MultipartFile.fromPath('image', image.path));
        }

        final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
        return await http.Response.fromStream(streamedResponse);
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error creating menu item: $e'};
    }
  }

  /// Update an existing menu item
  static Future<Map<String, dynamic>> updateMenuItem({
    required String id,
    String? name,
    String? categoryId,
    double? price,
    String? description,
    bool? isVegetarian,
    bool? isAvailable,
    File? image,
  }) async {
    try {
      final response = await _sendWithAuth((token) async {
        final uri = Uri.parse(ApiConfig.vendorMenuItemDetailUrl(id));
        final request = http.MultipartRequest('PATCH', uri);
        request.headers['Authorization'] = 'Bearer $token';

        if (name != null) request.fields['name'] = name;
        if (categoryId != null) request.fields['category'] = categoryId;
        if (price != null) request.fields['price'] = price.toStringAsFixed(2);
        if (description != null && isVegetarian != null) {
          request.fields['description'] = encodeDescription(description, isVegetarian);
        } else if (description != null) {
          request.fields['description'] = description;
        }
        if (isVegetarian != null) request.fields['is_vegetarian'] = isVegetarian.toString();
        if (isAvailable != null) request.fields['is_available'] = isAvailable.toString();

        if (image != null) {
          request.files.add(await http.MultipartFile.fromPath('image', image.path));
        }

        final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
        return await http.Response.fromStream(streamedResponse);
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error updating menu item: $e'};
    }
  }

  /// Delete a menu item
  static Future<Map<String, dynamic>> deleteMenuItem(String id) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.vendorMenuItemDetailUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        String err = data['detail'] ?? 'Failed to delete menu item.';
        if (data is List && data.isNotEmpty) err = data.first.toString();
        return {'success': false, 'error': err};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error deleting menu item: $e'};
    }
  }

  // ── Offers CRUD ────────────────────────────────────────────────────────────

  /// Get vendor offers
  static Future<Map<String, dynamic>> getOffers() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final list = await _fetchAllPages(ApiConfig.vendorOffersUrl, token);
      return {'success': true, 'data': list};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a new offer
  static Future<Map<String, dynamic>> createOffer(Map<String, dynamic> offerData) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.vendorOffersUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(offerData),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        String err = 'Failed to create offer';
        if (data is Map) {
          err = data['detail'] ?? data.toString();
        }
        return {'success': false, 'error': err};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error creating offer: $e'};
    }
  }

  /// Update an existing offer (PATCH)
  static Future<Map<String, dynamic>> updateOffer({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.patch(
        Uri.parse(ApiConfig.vendorOfferDetailUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      final resData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': resData};
      } else {
        return {'success': false, 'error': resData['detail'] ?? 'Failed to update offer'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error updating offer: $e'};
    }
  }

  /// Delete an offer
  static Future<Map<String, dynamic>> deleteOffer(String id) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.vendorOfferDetailUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['detail'] ?? 'Failed to delete offer'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error deleting offer: $e'};
    }
  }

  // ── Reward Milestones CRUD ─────────────────────────────────────────────────

  /// Get vendor reward milestones
  static Future<Map<String, dynamic>> getRewardMilestones() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final list = await _fetchAllPages(ApiConfig.vendorRewardMilestonesUrl, token);
      return {'success': true, 'data': list};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a new reward milestone
  static Future<Map<String, dynamic>> createRewardMilestone(Map<String, dynamic> data) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.vendorRewardMilestonesUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      final resData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': resData};
      } else {
        String err = 'Failed to create reward milestone';
        if (resData is Map) {
          err = resData['detail'] ?? resData.values.first?.toString() ?? resData.toString();
        }
        return {'success': false, 'error': err};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error creating reward milestone: $e'};
    }
  }

  /// Update an existing reward milestone (PATCH)
  static Future<Map<String, dynamic>> updateRewardMilestone({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.patch(
        Uri.parse(ApiConfig.vendorRewardMilestoneDetailUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      final resData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': resData};
      } else {
        String err = 'Failed to update reward milestone';
        if (resData is Map) {
          err = resData['detail'] ?? resData.values.first?.toString() ?? resData.toString();
        }
        return {'success': false, 'error': err};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error updating reward milestone: $e'};
    }
  }

  /// Delete a reward milestone
  static Future<Map<String, dynamic>> deleteRewardMilestone(String id) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.vendorRewardMilestoneDetailUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['detail'] ?? 'Failed to delete reward milestone'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error deleting reward milestone: $e'};
    }
  }

  /// Fetch vendor redemption sessions (orders)
  static Future<Map<String, dynamic>> getVendorRedemptions() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final list = await _fetchAllPages(ApiConfig.vendorRedemptionsUrl, token);
      return {'success': true, 'data': list};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Scan / confirm vendor redemption session (order)
  static Future<Map<String, dynamic>> scanVendorRedemption(String qrCode) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.vendorScanRedemptionUrl(qrCode)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to confirm order'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error confirming order: $e'};
    }
  }

  /// Fetch all customer reviews and ratings summary for the logged in vendor
  static Future<Map<String, dynamic>> getVendorReviews() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.vendorReviewsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data is Map ? (data['detail'] ?? 'Failed to fetch reviews') : 'Failed to fetch reviews',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error fetching reviews: $e'};
    }
  }
}

