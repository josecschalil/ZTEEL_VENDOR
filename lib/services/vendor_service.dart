import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/vendor_cache_service.dart';

class VendorService {
  static const _profileCacheTtl = Duration(hours: 12);
  static const _catalogCacheTtl = Duration(hours: 6);
  static const _offersCacheTtl = Duration(minutes: 30);
  static const _ordersCacheTtl = Duration(minutes: 2);
  static const _reviewsCacheTtl = Duration(hours: 6);
  static Future<List<dynamic>>? _menuItemsInFlight;
  static int? _menuItemsInFlightGeneration;
  static int _menuItemsGeneration = 0;
  static Future<void>? _essentialRefreshInFlight;
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

  static Future<Map<String, dynamic>?> _freshCachedMap(
    String resource,
    Duration ttl, {
    required bool forceRefresh,
  }) async {
    final entry = await VendorCacheService.readEntry(resource);
    if (forceRefresh || entry == null || !entry.isFresh(ttl) || entry.value is! Map) {
      return null;
    }
    return {
      'success': true,
      'data': Map<String, dynamic>.from(entry.value as Map),
      'from_cache': true,
      'is_stale': false,
    };
  }

  static Future<Map<String, dynamic>?> _freshCachedList(
    String resource,
    Duration ttl, {
    required bool forceRefresh,
  }) async {
    final entry = await VendorCacheService.readEntry(resource);
    if (forceRefresh || entry == null || !entry.isFresh(ttl) || entry.value is! List) {
      return null;
    }
    return {
      'success': true,
      'data': List<dynamic>.from(entry.value as List),
      'from_cache': true,
      'is_stale': false,
    };
  }

  static Future<Map<String, dynamic>> _staleMapOrError(
    String resource,
    Object error,
  ) async {
    final cached = await VendorCacheService.readMap(resource);
    if (cached != null) {
      return {
        'success': true,
        'data': cached,
        'from_cache': true,
        'is_stale': true,
      };
    }
    return {'success': false, 'error': error.toString()};
  }

  static Future<Map<String, dynamic>> _staleListOrError(
    String resource,
    Object error,
  ) async {
    final cached = await VendorCacheService.readList(resource);
    if (cached != null) {
      return {
        'success': true,
        'data': cached,
        'from_cache': true,
        'is_stale': true,
      };
    }
    return {'success': false, 'error': error.toString()};
  }

  static Future<Map<String, dynamic>?> _getCacheManifest() async {
    try {
      final response = await authGet(Uri.parse(ApiConfig.vendorCacheManifestUrl));
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {
      // Offline operation intentionally keeps the last known cache.
    }
    return null;
  }

  /// Revalidates only collections whose server revision advanced. Individual
  /// fetches fall back to cache, so a weak connection cannot blank a screen.
  static Future<void> refreshEssentialData() {
    final existing = _essentialRefreshInFlight;
    if (existing != null) return existing;

    late final Future<void> request;
    request = _refreshEssentialData().whenComplete(() {
      if (identical(_essentialRefreshInFlight, request)) {
        _essentialRefreshInFlight = null;
      }
    });
    _essentialRefreshInFlight = request;
    return request;
  }

  static Future<void> _refreshEssentialData() async {
    final manifest = await _getCacheManifest();
    if (manifest == null) return;
    final vendorId = manifest['vendor_id']?.toString() ?? '';
    if (vendorId.isEmpty) return;
    await VendorCacheService.setActiveVendor(vendorId);
    final previous = await VendorCacheService.readMap('sync_manifest') ??
        <String, dynamic>{};
    bool changed(String resource) => previous[resource]?.toString() != manifest[resource]?.toString();

    final results = await Future.wait([
      if (changed('profile')) getVendorProfile(forceRefresh: true),
      if (changed('categories')) getMenuCategories(forceRefresh: true),
      if (changed('menu_items')) getMenuItems(forceRefresh: true),
      if (changed('offers')) getOffers(forceRefresh: true),
      if (changed('reward_milestones')) getRewardMilestones(forceRefresh: true),
      if (changed('orders')) getVendorRedemptions(forceRefresh: true),
      if (changed('reviews')) getVendorReviews(forceRefresh: true),
    ]);
    // Never acknowledge a manifest whose changed collections were served from
    // stale cache after a network failure. Keeping the old manifest makes the
    // next resume/reconnect retry safely.
    if (results.any((result) =>
        result['success'] != true || result['is_stale'] == true)) {
      return;
    }
    await VendorCacheService.write('sync_manifest', manifest);
  }

  /// Refreshes only resources announced by the vendor realtime stream.
  /// The manifest remains the reconnect safety net; this path keeps an active
  /// second device current without waiting for a lifecycle transition.
  static Future<bool> refreshResources(Iterable<String> resources) async {
    final requested = resources.toSet();
    if (requested.isEmpty) return true;

    final futures = <Future<Map<String, dynamic>>>[];
    if (requested.contains('profile')) {
      futures.add(getVendorProfile(forceRefresh: true));
    }
    if (requested.contains('categories')) {
      futures.add(getMenuCategories(forceRefresh: true));
    }
    if (requested.contains('menu_items') || requested.contains('categories')) {
      futures.add(getMenuItems(forceRefresh: true));
    }
    if (requested.contains('offers')) {
      futures.add(getOffers(forceRefresh: true));
    }
    if (requested.contains('reward_milestones')) {
      futures.add(getRewardMilestones(forceRefresh: true));
    }
    if (requested.contains('reviews')) {
      futures.add(getVendorReviews(forceRefresh: true));
    }
    if (requested.contains('orders')) {
      futures.add(getVendorRedemptions(forceRefresh: true));
    }
    final results = await Future.wait(futures);
    if (results.any((result) =>
        result['success'] != true || result['is_stale'] == true)) {
      return false;
    }

    // Do not advance the whole manifest here. Another invalidation can arrive
    // while these requests are in flight; only the manifest reconciliation
    // path can atomically acknowledge its complete changed-resource set.
    return true;
  }

  /// Fetch vendor profile from backend
  static Future<Map<String, dynamic>> getVendorProfile({
    bool forceRefresh = false,
  }) async {
    final cached = await _freshCachedMap(
      'profile',
      _profileCacheTtl,
      forceRefresh: forceRefresh,
    );
    if (cached != null) return cached;
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

        await VendorCacheService.writeProfile(data);

        return {'success': true, 'data': data};
      } else {
        return _staleMapOrError(
          'profile',
          _extractApiError(data, 'Failed to fetch vendor profile.'),
        );
      }
    } catch (e) {
      return _staleMapOrError('profile', 'Network error: $e');
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
          await VendorCacheService.writeProfile(data);
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
          await VendorCacheService.writeProfile(data);
          return {'success': true, 'data': data};
        } else {
          return {'success': false, 'error': _extractApiError(data, 'Failed to update shop profile.')};
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Error saving shop profile: $e'};
    }
  }

  /// Persist only the vendor's delivery location without saving unrelated
  /// in-progress edits from the profile form.
  static Future<Map<String, dynamic>> updateVendorLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http
          .patch(
            Uri.parse(ApiConfig.vendorProfileUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'address': address,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        await VendorCacheService.writeProfile(data);
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'error': _extractApiError(data, 'Failed to update shop location.'),
      };
    } catch (e) {
      return {'success': false, 'error': 'Error saving shop location: $e'};
    }
  }

  /// Patch a small, explicit subset of the vendor profile. This is used by
  /// field-level editing so unsaved values in another profile field are never
  /// sent to the server inadvertently.
  static Future<Map<String, dynamic>> updateVendorProfileFields(
    Map<String, dynamic> fields,
  ) async {
    if (fields.isEmpty) {
      return {'success': false, 'error': 'No profile changes to save'};
    }

    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http
          .patch(
            Uri.parse(ApiConfig.vendorProfileUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(fields),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (fields['business_name'] is String) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('business_name', fields['business_name'] as String);
        }
        await VendorCacheService.writeProfile(data);
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'error': _extractApiError(data, 'Failed to update shop profile.'),
      };
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
        if (data is Map<String, dynamic>) {
          await VendorCacheService.writeProfile(data);
        } else {
          await VendorCacheService.invalidate('profile');
        }
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
        await VendorCacheService.writeProfile(data);
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
        await VendorCacheService.invalidate('profile');
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
        await VendorCacheService.writeProfile(data);
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
  static Future<Map<String, dynamic>> getMenuCategories({
    bool forceRefresh = false,
  }) async {
    final cached = await _freshCachedList(
      'categories',
      _catalogCacheTtl,
      forceRefresh: forceRefresh,
    );
    if (cached != null) return cached;
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final list = await _fetchAllPages(ApiConfig.vendorMenuCategoriesUrl, token);
      await VendorCacheService.write('categories', list);
      return {'success': true, 'data': list};
    } catch (e) {
      return _staleListOrError('categories', e);
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
        if (data is Map<String, dynamic>) {
          await VendorCacheService.upsertListRecord('categories', data);
        } else {
          await VendorCacheService.invalidate('categories');
        }
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
        if (data is Map<String, dynamic>) {
          await VendorCacheService.upsertListRecord('categories', data);
        } else {
          await VendorCacheService.invalidate('categories');
        }
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
        await VendorCacheService.removeListRecord('categories', id);
        // Categories and items are a single aggregate from the UI's point of
        // view, so a deletion invalidates item/category derived caches too.
        await VendorCacheService.invalidate('menu_items');
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
  static Future<Map<String, dynamic>> getMenuItems({
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final cached = await _freshCachedList(
      'menu_items',
      _catalogCacheTtl,
      forceRefresh: forceRefresh,
    );
    if (cached != null) {
      final list = cached['data'] as List<dynamic>;
      return {
        ...cached,
        'data': _filterItemsForCategory(list, categoryId),
      };
    }
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    Future<List<dynamic>>? menuRequest;
    try {
      // A realtime invalidation must never join an older in-flight fetch: that
      // response may predate the mutation. A generation also prevents an old
      // request finishing late from overwriting the newer cache snapshot.
      final activeRequest = forceRefresh ? null : _menuItemsInFlight;
      final Future<List<dynamic>> request;
      final int requestGeneration;
      if (activeRequest != null) {
        request = activeRequest;
        requestGeneration = _menuItemsInFlightGeneration ?? _menuItemsGeneration;
      } else {
        requestGeneration = ++_menuItemsGeneration;
        request = _fetchAllPages(ApiConfig.vendorMenuItemsUrl, token);
      }
      if (activeRequest == null && !forceRefresh) {
        _menuItemsInFlight = request;
        _menuItemsInFlightGeneration = requestGeneration;
      }
      menuRequest = request;
      final list = await request;
      if (requestGeneration == _menuItemsGeneration) {
        await VendorCacheService.write('menu_items', list);
      }
      if (identical(_menuItemsInFlight, menuRequest)) {
        _menuItemsInFlight = null;
        _menuItemsInFlightGeneration = null;
      }
      return {'success': true, 'data': _filterItemsForCategory(list, categoryId)};
    } catch (e) {
      if (menuRequest != null && identical(_menuItemsInFlight, menuRequest)) {
        _menuItemsInFlight = null;
        _menuItemsInFlightGeneration = null;
      }
      final fallback = await _staleListOrError('menu_items', e);
      if (fallback['success'] == true && fallback['data'] is List) {
        fallback['data'] = _filterItemsForCategory(
          fallback['data'] as List<dynamic>,
          categoryId,
        );
      }
      return fallback;
    }
  }

  static List<dynamic> _filterItemsForCategory(
    List<dynamic> list,
    String? categoryId,
  ) {
    if (categoryId == null || categoryId.isEmpty) return List<dynamic>.from(list);
    return list.where((item) {
      if (item is Map) {
        final category = item['category'];
        return category is String
            ? category == categoryId
            : category is Map && category['id']?.toString() == categoryId;
      }
      return false;
    }).toList();
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
        if (data is Map<String, dynamic>) {
          await VendorCacheService.upsertListRecord('menu_items', data);
        } else {
          await VendorCacheService.invalidate('menu_items');
        }
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
        if (data is Map<String, dynamic>) {
          await VendorCacheService.upsertListRecord('menu_items', data);
        } else {
          await VendorCacheService.invalidate('menu_items');
        }
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
        await VendorCacheService.removeListRecord('menu_items', id);
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
  static Future<Map<String, dynamic>> getOffers({bool forceRefresh = false}) async {
    final cached = await _freshCachedList(
      'offers',
      _offersCacheTtl,
      forceRefresh: forceRefresh,
    );
    if (cached != null) return cached;
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final list = await _fetchAllPages(ApiConfig.vendorOffersUrl, token);
      await VendorCacheService.write('offers', list);
      return {'success': true, 'data': list};
    } catch (e) {
      return _staleListOrError('offers', e);
    }
  }

  /// Read the server-owned master pause state for this vendor's offers.
  static Future<Map<String, dynamic>> getOfferMasterStatus() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.vendorOfferMasterStatusUrl),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data is Map ? data['detail'] ?? data.toString() : 'Failed to load offer status',
      };
    } catch (e) {
      return {'success': false, 'error': 'Error loading offer status: $e'};
    }
  }

  /// Pause or resume every offer through the server-side master switch.
  static Future<Map<String, dynamic>> setOfferMasterPaused(bool isPaused) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.vendorOfferMasterStatusUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'is_paused': isPaused}),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        await VendorCacheService.invalidate('offers');
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data is Map ? data['detail'] ?? data.toString() : 'Failed to update offer status',
      };
    } catch (e) {
      return {'success': false, 'error': 'Error updating offer status: $e'};
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
        if (data is Map<String, dynamic>) {
          await VendorCacheService.upsertListRecord('offers', data);
        } else {
          await VendorCacheService.invalidate('offers');
        }
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
        if (resData is Map<String, dynamic>) {
          // Featuring an offer also clears the featured flag from its siblings,
          // so a single-record cache update would leave the list inconsistent.
          if (data.containsKey('is_featured')) {
            await VendorCacheService.invalidate('offers');
          } else {
            await VendorCacheService.upsertListRecord('offers', resData);
          }
        } else {
          await VendorCacheService.invalidate('offers');
        }
        return {'success': true, 'data': resData};
      } else {
        final error = resData is Map
            ? (resData['detail'] ??
                resData.entries
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join(', '))
            : 'Failed to update offer';
        return {'success': false, 'error': error};
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
        await VendorCacheService.removeListRecord('offers', id);
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
  static Future<Map<String, dynamic>> getRewardMilestones({
    bool forceRefresh = false,
  }) async {
    final cached = await _freshCachedList(
      'reward_milestones',
      _offersCacheTtl,
      forceRefresh: forceRefresh,
    );
    if (cached != null) return cached;
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final list = await _fetchAllPages(ApiConfig.vendorRewardMilestonesUrl, token);
      await VendorCacheService.write('reward_milestones', list);
      return {'success': true, 'data': list};
    } catch (e) {
      return _staleListOrError('reward_milestones', e);
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
        if (resData is Map<String, dynamic>) {
          await VendorCacheService.upsertListRecord('reward_milestones', resData);
        } else {
          await VendorCacheService.invalidate('reward_milestones');
        }
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
        if (resData is Map<String, dynamic>) {
          await VendorCacheService.upsertListRecord('reward_milestones', resData);
        } else {
          await VendorCacheService.invalidate('reward_milestones');
        }
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
        await VendorCacheService.removeListRecord('reward_milestones', id);
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
  static Future<Map<String, dynamic>> getVendorRedemptions({
    bool forceRefresh = false,
    bool allowStale = true,
  }) async {
    final cached = await _freshCachedList(
      'orders',
      _ordersCacheTtl,
      forceRefresh: forceRefresh,
    );
    if (cached != null) return cached;
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final list = await _fetchAllPages(ApiConfig.vendorRedemptionsUrl, token);
      // Keep offline history bounded. The server remains the canonical archive.
      await VendorCacheService.write('orders', list.take(500).toList());
      return {'success': true, 'data': list};
    } catch (e) {
      if (!allowStale) return {'success': false, 'error': e.toString()};
      return _staleListOrError('orders', e);
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
        if (data is Map<String, dynamic>) {
          await VendorCacheService.upsertOrder(data);
        } else {
          await VendorCacheService.invalidate('orders');
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to confirm order'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error confirming order: $e'};
    }
  }

  /// Reject an unexpired pending redemption session.
  static Future<Map<String, dynamic>> rejectVendorRedemption(String qrCode) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.vendorRejectRedemptionUrl(qrCode)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data is Map<String, dynamic>) {
          await VendorCacheService.upsertOrder(data);
        } else {
          await VendorCacheService.invalidate('orders');
        }
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data is Map
            ? (data['message'] ?? data['detail'] ?? 'Failed to reject order')
            : 'Failed to reject order',
      };
    } catch (e) {
      return {'success': false, 'error': 'Error rejecting order: $e'};
    }
  }

  /// Fetch all customer reviews and ratings summary for the logged in vendor
  static Future<Map<String, dynamic>> getVendorReviews({
    bool forceRefresh = false,
  }) async {
    final cached = await _freshCachedMap(
      'reviews',
      _reviewsCacheTtl,
      forceRefresh: forceRefresh,
    );
    if (cached != null) return cached;
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
        await VendorCacheService.write('reviews', data);
        return {'success': true, 'data': data};
      } else {
        return _staleMapOrError(
          'reviews',
          data is Map ? (data['detail'] ?? 'Failed to fetch reviews') : 'Failed to fetch reviews',
        );
      }
    } catch (e) {
      return _staleMapOrError('reviews', 'Error fetching reviews: $e');
    }
  }
}

