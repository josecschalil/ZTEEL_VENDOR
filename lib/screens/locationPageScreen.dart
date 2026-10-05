import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/location_service.dart';

/// Design tokens matching the ZTEEL Vendor app theme
class _LocTokens {
  static const dark = Color(0xFF0F172A);
  static const slate700 = Color(0xFF334155);
  static const slate100 = Color(0xFFF1F5F9);
  static const bg = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);
}

/// Models
class PickedLocation {
  final String label;
  final String address;
  final LatLng position;
  const PickedLocation({
    required this.label,
    required this.address,
    required this.position,
  });

  double get latitude => position.latitude;
  double get longitude => position.longitude;
}

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialPosition,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _pinController;

  late LatLng _center;
  String _address = 'Move the map to select a location';
  bool _locating = false;
  bool _resolvingAddress = false;
  bool _searching = false;
  List<_SearchResult> _searchResults = [];
  Timer? _debounce;
  Timer? _searchDebounce;
  int _geocodeRequest = 0;
  int _searchRequest = 0;

  static const _userAgent = 'ZTEEL Vendor/1.0 LocationPicker';
  static const _pinOffset = Offset(0, -88);

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition ?? const LatLng(8.8932, 76.6141);
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _address = widget.initialAddress!;
    }
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ── Reverse geocoding (coords -> address) via OSM Nominatim ──
  Future<void> _reverseGeocode(LatLng point) async {
    final request = ++_geocodeRequest;
    setState(() => _resolvingAddress = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': _userAgent,
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted && request == _geocodeRequest) {
          setState(() => _address = _shortAddress(data, point));
        }
      } else {
        if (mounted && request == _geocodeRequest) {
          setState(() => _address = _coordinateAddress(point));
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
      if (mounted && request == _geocodeRequest) {
        setState(() => _address = _coordinateAddress(point));
      }
    } finally {
      if (mounted && request == _geocodeRequest) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  // ── Forward geocoding / search (text -> places) via Nominatim ──
  Future<void> _search(String query) async {
    final currentRequest = ++_searchRequest;
    if (query.trim().length < 3) {
      if (mounted && currentRequest == _searchRequest) {
        setState(() => _searchResults = []);
      }
      return;
    }
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&q=${Uri.encodeQueryComponent(query)}&limit=6&addressdetails=1',
      );
      final response = await http.get(uri, headers: {'User-Agent': _userAgent}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (mounted && currentRequest == _searchRequest) {
          setState(() {
            _searchResults = list
                .map(
                  (e) => _SearchResult(
                    label: e['display_name'] as String,
                    position: LatLng(
                      double.parse(e['lat'] as String),
                      double.parse(e['lon'] as String),
                    ),
                  ),
                )
                .toList();
          });
        }
      }
    } catch (_) {
      // Silently ignore search failures
    } finally {
      if (mounted && currentRequest == _searchRequest) {
        setState(() => _searching = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 1200),
      () => _search(value),
    );
  }

  void _selectSearchResult(_SearchResult result) {
    setState(() {
      _searchResults = [];
      _searchController.text = result.label;
    });
    FocusScope.of(context).unfocus();
    _mapController.move(result.position, 16, offset: _pinOffset);
    setState(() => _center = result.position);
    _reverseGeocode(result.position);
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart) {
      _pinController.forward();
    } else if (event is MapEventMove) {
      setState(() => _center = _selectedPoint(event.camera));
    } else if (event is MapEventMoveEnd) {
      _pinController.reverse();
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 1200),
        () => _reverseGeocode(_selectedPoint(event.camera)),
      );
    }
  }

  // ── Device GPS via geolocator ──
  Future<void> _useCurrentLocation({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are disabled on your phone.'),
              action: SnackBarAction(
                label: 'Enable',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to fetch your position.')),
          );
        }
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permissions are permanently denied. Please enable them in settings.'),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not determine current location. Please try again.')),
          );
        }
        return;
      }

      final point = LatLng(position.latitude, position.longitude);
      _mapController.move(point, 16.5, offset: _pinOffset);
      setState(() => _center = point);
      await _reverseGeocode(point);
    } catch (e) {
      debugPrint('Location fetch error: $e');
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch your location.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  LatLng _selectedPoint(MapCamera camera) {
    try {
      final cx = camera.size.x / 2 + _pinOffset.dx;
      final cy = camera.size.y / 2 + _pinOffset.dy;
      return camera.pointToLatLng(math.Point(cx, cy));
    } catch (_) {
      return camera.center;
    }
  }

  String _coordinateAddress(LatLng point) =>
      '${point.latitude.toStringAsFixed(5)}° N, ${point.longitude.toStringAsFixed(5)}° E';

  String _shortAddress(Map<String, dynamic> data, LatLng point) {
    final address = data['address'];
    if (address is! Map) return _coordinateAddress(point);
    final values = [
      address['road'],
      address['neighbourhood'] ?? address['suburb'],
      address['city'] ?? address['town'] ?? address['village'],
      address['state'],
      address['postcode'],
    ]
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    return values.isEmpty ? _coordinateAddress(point) : values.join(', ');
  }

  Future<void> _confirm(String label, String address, LatLng position) async {
    await LocationService.save(
      SavedLocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        label: label,
        address: address,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(
      PickedLocation(label: label, address: address, position: position),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LocTokens.bg,
      body: Stack(
        children: [
          // ── Real OpenStreetMap map ──
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 15,
                onMapEvent: _onMapEvent,
                onMapReady: () {
                  final selected = _selectedPoint(_mapController.camera);
                  setState(() => _center = selected);
                  if (widget.initialPosition == null) {
                    _useCurrentLocation(silent: true);
                  } else if (_address == 'Move the map to select a location') {
                    _reverseGeocode(selected);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.zteel.vendor',
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          // ── Center Brand Map Pin with lift animation + ground shadow ──
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 110),
              child: AnimatedBuilder(
                animation: _pinController,
                builder: (context, child) {
                  final lift = _pinController.value * 14;
                  final shadowScale = 1 - _pinController.value * 0.4;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, -lift),
                        child: child,
                      ),
                      const SizedBox(height: 2),
                      Transform.scale(
                        scale: shadowScale,
                        child: Container(
                          width: 18,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                child: const _BrandMapPin(),
              ),
            ),
          ),

          // ── Top Search Bar & Back Navigation ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _ModernIconButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _LocTokens.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(
                                color: _LocTokens.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search restaurant location or area…',
                                hintStyle: const TextStyle(
                                  color: _LocTokens.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: _LocTokens.textMuted,
                                  size: 19,
                                ),
                                suffixIcon: _searching
                                    ? const Padding(
                                        padding: EdgeInsets.all(13),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _LocTokens.dark,
                                          ),
                                        ),
                                      )
                                    : _searchController.text.isNotEmpty
                                        ? GestureDetector(
                                            onTap: () {
                                              _searchController.clear();
                                              setState(() => _searchResults = []);
                                            },
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: _LocTokens.textMuted,
                                              size: 18,
                                            ),
                                          )
                                        : null,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                  horizontal: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _LocTokens.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1,
                            color: _LocTokens.border,
                          ),
                          itemBuilder: (context, i) {
                            final result = _searchResults[i];
                            return ListTile(
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _LocTokens.slate100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: _LocTokens.dark,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                result.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _LocTokens.textPrimary,
                                ),
                              ),
                              onTap: () => _selectSearchResult(result),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating GPS Button ──
          Positioned(
            right: 16,
            bottom: 235,
            child: _ModernIconButton(
              icon: Icons.my_location_rounded,
              iconColor: _LocTokens.dark,
              loading: _locating,
              onTap: _useCurrentLocation,
            ),
          ),

          // ── Bottom Location Card ──
          Align(
            alignment: Alignment.bottomCenter,
            child: _LocationBottomCard(
              address: _address,
              coordinates: _coordinateAddress(_center),
              resolving: _resolvingAddress,
              locating: _locating,
              onUseCurrentLocation: _useCurrentLocation,
              onConfirm: () {
                _confirm('Shop Location', _address, _center);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final String label;
  final LatLng position;
  const _SearchResult({required this.label, required this.position});
}

/// Modern rounded icon button matching app design system
class _ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool loading;

  const _ModernIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LocTokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _LocTokens.dark,
                    ),
                  )
                : Icon(
                    icon,
                    size: 18,
                    color: iconColor ?? _LocTokens.dark,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Custom ZTEEL Brand Map Pin
class _BrandMapPin extends StatelessWidget {
  const _BrandMapPin();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: CustomPaint(painter: _BrandPinPainter()),
    );
  }
}

class _BrandPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = w / 2;

    final path = ui.Path();
    path.addOval(
      Rect.fromCircle(center: Offset(w / 2, radius), radius: radius),
    );
    final trianglePath = ui.Path()
      ..moveTo(w / 2 - radius * 0.52, radius * 1.45)
      ..lineTo(w / 2 + radius * 0.52, radius * 1.45)
      ..lineTo(w / 2, h)
      ..close();
    path.addPath(trianglePath, Offset.zero);

    // Deep slate pin body
    final pinPaint = Paint()
      ..color = _LocTokens.dark
      ..style = PaintingStyle.fill;
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 4, false);
    canvas.drawPath(path, pinPaint);

    // Inner slate accent ring
    final innerPaint = Paint()
      ..color = _LocTokens.slate700
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, radius), radius * 0.55, innerPaint);

    // Center white dot
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, radius), radius * 0.22, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Modern themed bottom sheet
class _LocationBottomCard extends StatelessWidget {
  final String address;
  final String coordinates;
  final bool resolving;
  final bool locating;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onConfirm;

  const _LocationBottomCard({
    required this.address,
    required this.coordinates,
    required this.resolving,
    required this.locating,
    required this.onUseCurrentLocation,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        18 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
          top: BorderSide(color: _LocTokens.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle indicator
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Header row with badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _LocTokens.dark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'STORE LOCATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _LocTokens.dark,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  coordinates,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _LocTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Address Card Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _LocTokens.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: _LocTokens.dark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: resolving
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _LocTokens.dark,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Resolving address details…',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _LocTokens.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            address,
                            key: ValueKey(address),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _LocTokens.textPrimary,
                              height: 1.35,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              // Locate Me button
              OutlinedButton.icon(
                onPressed: locating ? null : onUseCurrentLocation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _LocTokens.dark,
                  side: const BorderSide(color: _LocTokens.border, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                icon: locating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _LocTokens.dark,
                        ),
                      )
                    : const Icon(Icons.gps_fixed_rounded, size: 16),
                label: const Text(
                  'GPS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Confirm button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _LocTokens.dark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 17, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
