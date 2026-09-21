import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';

class LocationColors {
  static const primary = Color(0xFF0F172A);
  static const brand = Color(0xFFEE5B2B);
  static const backgroundLight = Color(0xFFF8FAFC);
  static const cardLight = Colors.white;
  static const borderLight = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
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

  static const _userAgent = 'ZTEEEL Vendor/1.0 LocationPicker';
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

  // -- Reverse geocoding (coords -> address) via OSM Nominatim --
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

  // -- Forward geocoding / search (text -> places) via Nominatim --
  Future<void> _search(String query) async {
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&q=${Uri.encodeQueryComponent(query)}&limit=6&addressdetails=1',
      );
      final response = await http.get(uri, headers: {'User-Agent': _userAgent});
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (mounted) {
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
      // Silently ignore search failures; the field simply shows no results.
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
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

  // -- Map pan handling: keep pin fixed, lift it while dragging, and
  //    reverse-geocode once the user stops moving the map. --
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart) {
      _pinController.forward();
    } else if (event is MapEventMove) {
      setState(() => _center = _selectedPoint(event.camera));
    } else if (event is MapEventMoveEnd) {
      _pinController.reverse();
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 400),
        () => _reverseGeocode(_selectedPoint(event.camera)),
      );
    }
  }

  // -- Device GPS via geolocator --
  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required.')),
          );
        }
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services.')),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final point = LatLng(position.latitude, position.longitude);
      _mapController.move(point, 16, offset: _pinOffset);
      setState(() => _center = point);
      await _reverseGeocode(point);
    } catch (_) {
      if (mounted) {
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
      'Coordinates: ${point.latitude.toStringAsFixed(6)}, '
      '${point.longitude.toStringAsFixed(6)}';

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
      body: Stack(
        children: [
          // --- Real OpenStreetMap map ---
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
                  if (_address == 'Move the map to select a location') {
                    _reverseGeocode(selected);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.zteeel.vendor',
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          // --- Fixed center pin with lift animation + ground shadow ---
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
                          width: 16,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                child: const _MapPin(),
              ),
            ),
          ),

          // --- Top search bar + back button + results dropdown ---
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
                        _RoundButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: LocationColors.cardLight,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(
                                color: LocationColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search shop area, street, landmark…',
                                hintStyle: const TextStyle(
                                  color: LocationColors.textMuted,
                                  fontWeight: FontWeight.normal,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: LocationColors.textMuted,
                                  size: 20,
                                ),
                                suffixIcon: _searching
                                    ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: LocationColors.brand,
                                          ),
                                        ),
                                      )
                                    : null,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
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
                          color: LocationColors.cardLight,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: LocationColors.borderLight,
                          ),
                          itemBuilder: (context, i) {
                            final result = _searchResults[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.location_on_outlined,
                                color: LocationColors.brand,
                                size: 20,
                              ),
                              title: Text(
                                result.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: LocationColors.textPrimary,
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

          // --- Floating GPS button ---
          Positioned(
            right: 16,
            bottom: 240,
            child: _RoundButton(
              icon: Icons.my_location,
              iconColor: LocationColors.brand,
              loading: _locating,
              onTap: _useCurrentLocation,
            ),
          ),

          // --- Bottom sheet ---
          Align(
            alignment: Alignment.bottomCenter,
            child: _LocationSheet(
              address: _address,
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

/// Small reusable round icon button (back, GPS, etc.)
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool loading;
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LocationColors.cardLight,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: loading ? null : onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LocationColors.brand,
                  ),
                )
              : Icon(
                  icon,
                  size: 19,
                  color: iconColor ?? LocationColors.textSecondary,
                ),
        ),
      ),
    );
  }
}

/// Fixed center map pin (teardrop with a dot)
class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 52,
      child: CustomPaint(painter: _PinPainter()),
    );
  }
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path();
    final w = size.width;
    final h = size.height;
    final radius = w / 2;
    path.addOval(
      Rect.fromCircle(center: Offset(w / 2, radius), radius: radius),
    );
    final trianglePath = ui.Path()
      ..moveTo(w / 2 - radius * 0.55, radius * 1.5)
      ..lineTo(w / 2 + radius * 0.55, radius * 1.5)
      ..lineTo(w / 2, h)
      ..close();
    path.addPath(trianglePath, Offset.zero);

    final paint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = const Color(0xFFEE5B2B);
    canvas.drawCircle(Offset(w / 2, radius), radius * 0.38, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom sheet: current address & confirm button
class _LocationSheet extends StatelessWidget {
  final String address;
  final bool resolving;
  final bool locating;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onConfirm;

  const _LocationSheet({
    required this.address,
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
        16,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: LocationColors.cardLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: LocationColors.borderLight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store_mall_directory_rounded,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SHOP LOCATION',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: LocationColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: resolving
                          ? const Text(
                              'Locating address…',
                              key: ValueKey('loading'),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontStyle: FontStyle.italic,
                                color: LocationColors.textMuted,
                              ),
                            )
                          : Text(
                              address,
                              key: ValueKey(address),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: LocationColors.textPrimary,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: locating ? null : onUseCurrentLocation,
                style: TextButton.styleFrom(
                  foregroundColor: LocationColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                icon: locating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: LocationColors.brand,
                        ),
                      )
                    : const Icon(Icons.gps_fixed, size: 16),
                label: const Text(
                  'GPS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Confirm Shop Location',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
