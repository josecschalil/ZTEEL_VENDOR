import 'package:shared_preferences/shared_preferences.dart';

class SavedLocationCoordinates {
  final double latitude;
  final double longitude;
  final String label;
  final String address;

  const SavedLocationCoordinates({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.address,
  });
}

/// Persistent coordinate store for location-aware frontend processing.
class LocationService {
  LocationService._();

  static const _latitudeKey = 'selected_vendor_location_latitude';
  static const _longitudeKey = 'selected_vendor_location_longitude';
  static const _labelKey = 'selected_vendor_location_label';
  static const _addressKey = 'selected_vendor_location_address';

  static Future<void> save(SavedLocationCoordinates location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latitudeKey, location.latitude);
    await prefs.setDouble(_longitudeKey, location.longitude);
    await prefs.setString(_labelKey, location.label);
    await prefs.setString(_addressKey, location.address);
  }

  static Future<SavedLocationCoordinates?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);
    if (latitude == null || longitude == null) return null;
    return SavedLocationCoordinates(
      latitude: latitude,
      longitude: longitude,
      label: prefs.getString(_labelKey) ?? 'Shop Location',
      address: prefs.getString(_addressKey) ?? '',
    );
  }
}
