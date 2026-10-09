import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/realtime_order_service.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/services/vendor_cache_service.dart';
import 'package:frontend/screens/HelpSupportScreen.dart';
import 'package:frontend/screens/PhoneAuthScreen.dart';
import 'package:frontend/screens/locationPageScreen.dart';
import 'package:frontend/screens/terms_policy_screen.dart';

// ─── Design tokens matching the Artisan Trattoria dashboard ──────────────────
class _Dt {
  // Backgrounds
  static const bg = Color(0xFFF8FAFC); // slate-50
  static const surfaceRaised = Color(0xFFF1F5F9); // slate-100
  static const dark = Color(0xFF0F172A); // slate-900 (hero)

  // Borders
  static const border = Color(0xFFE2E8F0); // slate-200

  // Text
  static const textPrimary = Color(0xFF0F172A); // slate-900
  static const textSecondary = Color(0xFF64748B); // slate-500
  static const textMuted = Color(0xFF94A3B8); // slate-400

  // Accents — slate throughout, matching the dashboard.
  static const accent = Color(0xFF0F172A); // slate-900
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<List<_OpeningSession>> _daySessions = List.generate(
    7,
    (_) => <_OpeningSession>[],
  );
  int _selectedDayIndex = 0;

  String _phone = '';
  double _latitude = 12.9716;
  double _longitude = 77.5946;

  File? _iconImageFile;
  File? _coverImageFile;
  String? _iconImageUrl;
  String? _coverImageUrl;

  bool _isLoading = true;
  bool _isUploadingIcon = false;
  bool _isUploadingCover = false;
  bool _isUpdatingLocation = false;
  bool _isEditingShopName = false;
  bool _isEditingDescription = false;
  bool _isEditingHours = false;
  String? _savingProfilePart;
  String _shopNameBeforeEdit = '';
  String _descriptionBeforeEdit = '';
  List<List<_OpeningSession>> _hoursBeforeEdit = [];
  bool _cacheRefreshScheduled = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadVendorProfile();
    VendorCacheService.revision.addListener(_onCacheRevision);
  }

  Future<void> _loadVendorProfile({bool forceRefresh = false}) async {
    final res =
        await VendorService.getVendorProfile(forceRefresh: forceRefresh);
    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        if (!_isEditingShopName && data['business_name'] != null)
          _shopNameController.text = data['business_name'].toString();
        if (!_isEditingDescription && data['shop_description'] != null)
          _descriptionController.text = data['shop_description'].toString();
        if (data['address'] != null)
          _addressController.text = data['address'].toString();
        if (data['phone_number'] != null)
          _phone = data['phone_number'].toString();
        if (data['latitude'] != null)
          _latitude = (data['latitude'] as num).toDouble();
        if (data['longitude'] != null)
          _longitude = (data['longitude'] as num).toDouble();
        _iconImageUrl = data['icon_image']?.toString();
        _coverImageUrl = data['cover_image']?.toString();
        if (!_isEditingHours &&
            data['business_hours'] != null &&
            data['business_hours'] is List) {
          _parseBusinessHours(data['business_hours'] as List);
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _onCacheRevision() {
    if (_cacheRefreshScheduled) return;
    _cacheRefreshScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      _cacheRefreshScheduled = false;
      if (mounted) _loadVendorProfile();
    });
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  void _parseBusinessHours(List<dynamic> hoursList) {
    for (int i = 0; i < 7; i++) _daySessions[i].clear();
    for (final dayItem in hoursList) {
      if (dayItem is Map<String, dynamic>) {
        final weekday = dayItem['weekday'] as int? ?? 0;
        final isClosed = dayItem['is_closed'] as bool? ?? false;
        final slots = dayItem['slots'] as List<dynamic>? ?? [];
        if (!isClosed && weekday >= 0 && weekday < 7) {
          for (final slot in slots) {
            if (slot is Map<String, dynamic>) {
              _daySessions[weekday].add(_OpeningSession(
                start:
                    _parseTimeOfDay(slot['opens_at']?.toString() ?? '09:00:00'),
                end: _parseTimeOfDay(
                    slot['closes_at']?.toString() ?? '22:00:00'),
              ));
            }
          }
        }
      }
    }
  }

  Future<void> _pickIconImage() async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final file = File(picked.path);
        setState(() {
          _iconImageFile = file;
          _isUploadingIcon = true;
        });
        final res = await VendorService.uploadSingleImage(iconImage: file);
        if (!mounted) return;
        setState(() => _isUploadingIcon = false);
        if (res['success'] == true) {
          if (res['icon_image'] != null)
            setState(() => _iconImageUrl = res['icon_image'].toString());
          _showSnack('Shop logo updated.', success: true);
        } else {
          _showSnack(res['error'] ?? 'Failed to upload shop logo');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingIcon = false);
      _showSnack('Could not pick logo: $e');
    }
  }

  Future<void> _removeIconImage() async {
    setState(() => _isUploadingIcon = true);
    final res = await VendorService.removeVendorImage(removeIcon: true);
    if (!mounted) return;
    setState(() {
      _isUploadingIcon = false;
      if (res['success'] == true) {
        _iconImageFile = null;
        _iconImageUrl = null;
      }
    });
    if (res['success'] == true) {
      _showSnack('Shop logo removed.', success: true);
    } else {
      _showSnack(res['error'] ?? 'Failed to remove shop logo');
    }
  }

  void _showIconPhotoOptions() {
    if (_isUploadingIcon) return;
    final hasIcon = _iconImageFile != null ||
        (_iconImageUrl != null && _iconImageUrl!.isNotEmpty);
    if (!hasIcon) {
      _pickIconImage();
      return;
    }

    _showImageOptionsSheet(
      title: 'Shop Logo',
      subtitle: 'Manage your shop profile image',
      onChange: _pickIconImage,
      onRemove: _removeIconImage,
    );
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final file = File(picked.path);
        setState(() {
          _coverImageFile = file;
          _isUploadingCover = true;
        });
        final res = await VendorService.uploadSingleImage(coverImage: file);
        if (!mounted) return;
        setState(() => _isUploadingCover = false);
        if (res['success'] == true) {
          if (res['cover_image'] != null)
            setState(() => _coverImageUrl = res['cover_image'].toString());
          _showSnack('Cover photo updated.', success: true);
        } else {
          _showSnack(res['error'] ?? 'Failed to upload cover photo');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingCover = false);
      _showSnack('Could not pick cover photo: $e');
    }
  }

  Future<void> _removeCoverImage() async {
    setState(() => _isUploadingCover = true);
    final res = await VendorService.removeVendorImage(removeCover: true);
    if (!mounted) return;
    setState(() {
      _isUploadingCover = false;
      if (res['success'] == true) {
        _coverImageFile = null;
        _coverImageUrl = null;
      }
    });
    if (res['success'] == true) {
      _showSnack('Cover photo removed.', success: true);
    } else {
      _showSnack(res['error'] ?? 'Failed to remove cover photo');
    }
  }

  void _showCoverPhotoOptions() {
    if (_isUploadingCover) return;
    final hasCover = _coverImageFile != null ||
        (_coverImageUrl != null && _coverImageUrl!.isNotEmpty);
    if (!hasCover) {
      _pickCoverImage();
      return;
    }

    _showImageOptionsSheet(
      title: 'Cover Photo',
      subtitle: 'Manage your shop cover banner',
      onChange: _pickCoverImage,
      onRemove: _removeCoverImage,
    );
  }

  void _showImageOptionsSheet({
    required String title,
    required String subtitle,
    required VoidCallback onChange,
    required VoidCallback onRemove,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF334155), width: 1),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _Dt.textMuted,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 18),
              _buildImageSheetOption(
                icon: Icons.photo_library_outlined,
                iconColor: Colors.white,
                title: 'Change photo',
                subtitle: 'Choose a new image from your gallery',
                onTap: () {
                  Navigator.pop(ctx);
                  onChange();
                },
              ),
              const SizedBox(height: 10),
              _buildImageSheetOption(
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Remove photo',
                subtitle: 'Delete current photo and reset to default',
                titleColor: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(ctx);
                  onRemove();
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => Navigator.pop(ctx),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: _Dt.textSecondary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSheetOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color titleColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _Dt.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _Dt.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? _Dt.accent : const Color(0xFF64748B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _saveShopName() async {
    final name = _shopNameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Shop name cannot be empty');
      return;
    }
    await _saveProfilePart(
      part: 'shop_name',
      fields: {'business_name': name},
      onSuccess: () => _isEditingShopName = false,
      successMessage: 'Shop name saved.',
    );
  }

  Future<void> _saveDescription() => _saveProfilePart(
        part: 'description',
        fields: {'shop_description': _descriptionController.text.trim()},
        onSuccess: () => _isEditingDescription = false,
        successMessage: 'Description saved.',
      );

  Future<void> _saveProfilePart({
    required String part,
    required Map<String, dynamic> fields,
    required VoidCallback onSuccess,
    required String successMessage,
  }) async {
    if (_savingProfilePart != null) return;
    setState(() => _savingProfilePart = part);
    final result = await VendorService.updateVendorProfileFields(fields);
    if (!mounted) return;

    setState(() {
      _savingProfilePart = null;
      if (result['success'] == true) onSuccess();
    });
    if (result['success'] == true) {
      _showSnack(successMessage, success: true);
    } else {
      _showSnack(result['error'] ?? 'Failed to save changes');
    }
  }

  List<List<_OpeningSession>> _copyHours() => _daySessions
      .map((sessions) => sessions
          .map((session) =>
              _OpeningSession(start: session.start, end: session.end))
          .toList())
      .toList();

  List<Map<String, dynamic>> _hoursPayload() => List.generate(7, (index) {
        final sessions = _daySessions[index];
        return {
          'weekday': index,
          'is_closed': sessions.isEmpty,
          if (sessions.isNotEmpty)
            'slots': sessions
                .map((session) => {
                      'opens_at':
                          '${session.start.hour.toString().padLeft(2, '0')}:${session.start.minute.toString().padLeft(2, '0')}:00',
                      'closes_at':
                          '${session.end.hour.toString().padLeft(2, '0')}:${session.end.minute.toString().padLeft(2, '0')}:00',
                      'closes_next_day': false,
                    })
                .toList(),
        };
      });

  void _startHoursEditing() {
    setState(() {
      _hoursBeforeEdit = _copyHours();
      _isEditingHours = true;
    });
  }

  void _discardHoursEdit() {
    setState(() {
      for (var index = 0; index < 7; index++) {
        _daySessions[index] = _hoursBeforeEdit[index]
            .map((session) =>
                _OpeningSession(start: session.start, end: session.end))
            .toList();
      }
      _isEditingHours = false;
    });
  }

  Future<void> _saveHours() async {
    if (_savingProfilePart != null) return;
    for (var index = 0; index < 7; index++) {
      final message = _sessionValidationMessage(index);
      if (message != null) {
        _showSnack('${_fullDayLabel(index)}: $message');
        return;
      }
    }

    setState(() => _savingProfilePart = 'hours');
    final result = await VendorService.updateBusinessHours(_hoursPayload());
    if (!mounted) return;
    setState(() {
      _savingProfilePart = null;
      if (result['success'] == true) _isEditingHours = false;
    });
    if (result['success'] == true) {
      _showSnack('Opening hours saved.', success: true);
    } else {
      _showSnack(result['error'] ?? 'Failed to save opening hours');
    }
  }

  Future<void> _openLocationPicker() async {
    if (_isUpdatingLocation) return;

    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialPosition: LatLng(_latitude, _longitude),
          initialAddress: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        ),
      ),
    );
    if (picked == null || !mounted) return;

    setState(() => _isUpdatingLocation = true);
    final result = await VendorService.updateVendorLocation(
      address: picked.address,
      latitude: picked.latitude,
      longitude: picked.longitude,
    );
    if (!mounted) return;

    setState(() => _isUpdatingLocation = false);
    if (result['success'] != true) {
      _showSnack(result['error'] ?? 'Failed to update shop location');
      return;
    }

    setState(() {
      _addressController.text = picked.address;
      _latitude = picked.latitude;
      _longitude = picked.longitude;
    });
    _showSnack('Shop location updated.', success: true);
  }

  Future<void> _handleLogout() async {
    await VendorOrderRealtimeService.instance.stop();
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    VendorCacheService.revision.removeListener(_onCacheRevision);
    _shopNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _dayLabel(int i) => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i];
  String _fullDayLabel(int i) => [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][i];
  String _shortDayLabel(int i) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i];

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String? _sessionValidationMessage(int dayIndex) {
    final sessions = _daySessions[dayIndex];
    if (sessions.isEmpty) return null;
    final normalized = sessions
        .map((s) => (_toMinutes(s.start), _toMinutes(s.end)))
        .toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    for (var i = 0; i < normalized.length; i++) {
      if (normalized[i].$1 >= normalized[i].$2)
        return 'Invalid time range in one of the sessions.';
      if (i > 0 && normalized[i].$1 < normalized[i - 1].$2)
        return 'Sessions overlap — adjust to avoid conflicts.';
    }
    return null;
  }

  Future<void> _pickSessionTime(
      int dayIndex, int sessionIndex, bool isStart) async {
    final current = _daySessions[dayIndex][sessionIndex];
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? current.start : current.end,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _Dt.dark,
            onSurface: _Dt.textPrimary,
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _daySessions[dayIndex][sessionIndex] =
          _daySessions[dayIndex][sessionIndex].copyWith(
        start: isStart ? picked : null,
        end: isStart ? null : picked,
      );
    });
  }

  void _addSession(int dayIndex) {
    final sessions = _daySessions[dayIndex];
    final fallbackStart = sessions.isNotEmpty
        ? sessions.last.end
        : const TimeOfDay(hour: 9, minute: 0);
    final fallbackEnd = TimeOfDay(
        hour: (fallbackStart.hour + 3) % 24, minute: fallbackStart.minute);
    setState(() =>
        sessions.add(_OpeningSession(start: fallbackStart, end: fallbackEnd)));
  }

  void _removeSession(int dayIndex, int sessionIndex) {
    setState(() => _daySessions[dayIndex].removeAt(sessionIndex));
  }

  void _applyHoursToAllDays(int sourceDayIndex) {
    final sourceSessions = _daySessions[sourceDayIndex];
    setState(() {
      for (int i = 0; i < 7; i++) {
        if (i != sourceDayIndex) {
          _daySessions[i] = sourceSessions
              .map((s) => _OpeningSession(start: s.start, end: s.end))
              .toList();
        }
      }
    });
  }

  void _applyHoursToWeekdays(int sourceDayIndex) {
    final sourceSessions = _daySessions[sourceDayIndex];
    setState(() {
      for (int i = 0; i < 5; i++) {
        if (i != sourceDayIndex) {
          _daySessions[i] = sourceSessions
              .map((s) => _OpeningSession(start: s.start, end: s.end))
              .toList();
        }
      }
    });
  }

  void _applyHoursToCustomDays(int sourceDayIndex, List<int> targetDayIndices) {
    final sourceSessions = _daySessions[sourceDayIndex];
    setState(() {
      for (final index in targetDayIndices) {
        if (index != sourceDayIndex && index >= 0 && index < 7) {
          _daySessions[index] = sourceSessions
              .map((s) => _OpeningSession(start: s.start, end: s.end))
              .toList();
        }
      }
    });
  }

  void _showApplyHoursModal(int sourceDayIndex) {
    final sourceSessions = _daySessions[sourceDayIndex];
    final dayName = _fullDayLabel(sourceDayIndex);
    final String summaryText = sourceSessions.isEmpty
        ? 'Closed (Will mark other days as Closed)'
        : sourceSessions
            .map((s) => '${_formatTime(s.start)} – ${_formatTime(s.end)}')
            .join(', ');

    // By default select all other 6 days
    final Set<int> selectedDays =
        List.generate(7, (i) => i).where((i) => i != sourceDayIndex).toSet();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allOtherSelected = selectedDays.length == 6;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  18 + MediaQuery.of(context).viewInsets.bottom,
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
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _Dt.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    // Title Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _Dt.surfaceRaised,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _Dt.border),
                          ),
                          child: const Icon(
                            Icons.copy_all_rounded,
                            color: _Dt.textPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apply $dayName Schedule',
                                style: const TextStyle(
                                  color: _Dt.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                summaryText,
                                style: const TextStyle(
                                  color: _Dt.textSecondary,
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Quick presets section
                    const Text(
                      'QUICK PRESETS',
                      style: TextStyle(
                        color: _Dt.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // All 7 Days preset
                    _buildPresetOption(
                      icon: Icons.calendar_month_rounded,
                      title: 'Apply to all 7 days (Mon – Sun)',
                      subtitle: 'Copy this schedule across the whole week',
                      onTap: () {
                        Navigator.pop(ctx);
                        _applyHoursToAllDays(sourceDayIndex);
                      },
                    ),

                    const SizedBox(height: 8),

                    // Weekdays Only preset
                    _buildPresetOption(
                      icon: Icons.business_center_rounded,
                      title: 'Apply to weekdays (Mon – Fri)',
                      subtitle: 'Keep Saturday & Sunday schedule unchanged',
                      onTap: () {
                        Navigator.pop(ctx);
                        _applyHoursToWeekdays(sourceDayIndex);
                      },
                    ),

                    const SizedBox(height: 18),

                    // Custom Days Selector Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _Dt.surfaceRaised,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _Dt.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SELECT SPECIFIC DAYS',
                                style: TextStyle(
                                  color: _Dt.textSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (allOtherSelected) {
                                      selectedDays.clear();
                                    } else {
                                      selectedDays.clear();
                                      for (int i = 0; i < 7; i++) {
                                        if (i != sourceDayIndex) {
                                          selectedDays.add(i);
                                        }
                                      }
                                    }
                                  });
                                },
                                child: Text(
                                  allOtherSelected ? 'Clear all' : 'Select all',
                                  style: const TextStyle(
                                    color: _Dt.dark,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 7-day pill tiles row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (i) {
                              final isSource = i == sourceDayIndex;
                              final isSelected = selectedDays.contains(i);

                              return GestureDetector(
                                onTap: isSource
                                    ? null
                                    : () {
                                        setModalState(() {
                                          if (isSelected) {
                                            selectedDays.remove(i);
                                          } else {
                                            selectedDays.add(i);
                                          }
                                        });
                                      },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 42,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isSource
                                        ? _Dt.surfaceRaised
                                        : isSelected
                                            ? _Dt.dark
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSource
                                          ? _Dt.border
                                          : isSelected
                                              ? _Dt.dark
                                              : _Dt.border,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _dayLabel(i),
                                        style: TextStyle(
                                          color: isSource
                                              ? _Dt.textMuted
                                              : isSelected
                                                  ? Colors.white
                                                  : _Dt.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      if (isSource)
                                        const Text(
                                          'SRC',
                                          style: TextStyle(
                                            color: _Dt.textSecondary,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 13,
                                          height: 13,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? _Dt.dark
                                                : Colors.transparent,
                                            border: isSelected
                                                ? null
                                                : Border.all(
                                                    color: _Dt.border,
                                                    width: 1.2,
                                                  ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 9,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Apply Button
                    GestureDetector(
                      onTap: selectedDays.isEmpty
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _applyHoursToCustomDays(
                                sourceDayIndex,
                                selectedDays.toList(),
                              );
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: selectedDays.isEmpty
                              ? _Dt.surfaceRaised
                              : _Dt.dark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedDays.isEmpty ? _Dt.border : _Dt.dark,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            selectedDays.isEmpty
                                ? 'Select at least one day'
                                : 'Apply to ${selectedDays.length} Selected Day${selectedDays.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: selectedDays.isEmpty
                                  ? _Dt.textMuted
                                  : Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _Dt.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Dt.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _Dt.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _Dt.border),
              ),
              child: Icon(icon, color: _Dt.textPrimary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _Dt.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _Dt.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _Dt.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _Dt.bg,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _Dt.dark))
            : RefreshIndicator(
                onRefresh: () => _loadVendorProfile(forceRefresh: true),
                color: _Dt.dark,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      _buildHeroHeader(topPadding),
                      const SizedBox(height: 52),
                      _buildSection('Shop Details', child: _buildDetailsCard()),
                      const SizedBox(height: 16),
                      _buildSection('Location', child: _buildLocationCard()),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Opening Hours',
                        action: _buildHoursEditAction(),
                        child: _buildOpenHoursCard(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection('Account', child: _buildAccountCard()),
                      const SizedBox(height: 20),
                      _buildFooterButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── Dark hero header (matches dashboard) ─────────────────────────────────

  Widget _buildHeroHeader(double topPadding) {
    ImageProvider? coverImg;
    if (_coverImageFile != null) {
      coverImg = FileImage(_coverImageFile!);
    } else if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
      coverImg = NetworkImage(_coverImageUrl!);
    }

    const double avatarSize = 84.0;
    final double headerHeight = 195.0 + topPadding;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomLeft,
      children: [
        // ── Full Cover Image Header (Fills all along the top) ──
        GestureDetector(
          onTap: _isUploadingCover ? null : _showCoverPhotoOptions,
          child: Container(
            height: headerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _Dt.dark,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
              image: coverImg != null
                  ? DecorationImage(
                      image: coverImg,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Placeholder if no cover image
                if (coverImg == null)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: topPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 36,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to add cover photo',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Gradient Overlay for smooth contrast
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x55000000),
                          Colors.transparent,
                          Color(0x80000000),
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Uploading indicator
                if (_isUploadingCover)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xA6000000),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: _Dt.dark,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Uploading cover…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top Floating Action Buttons (Change Cover pill + Refresh button)
                Positioned(
                  top: topPadding + 12,
                  right: 16,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap:
                            _isUploadingCover ? null : _showCoverPhotoOptions,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_outlined,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                _isUploadingCover
                                    ? 'Uploading…'
                                    : (coverImg != null
                                        ? 'Edit cover'
                                        : 'Add cover'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _loadVendorProfile,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Profile Photo (Half on cover photo and half on white bottom) ──
        Positioned(
          bottom: -(avatarSize / 2),
          left: 28,
          child: GestureDetector(
            onTap: _isUploadingIcon ? null : _showIconPhotoOptions,
            child: Stack(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Dt.surfaceRaised,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _isUploadingIcon
                        ? Container(
                            color: _Dt.surfaceRaised,
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: _Dt.dark,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : _iconImageFile != null
                            ? Image.file(_iconImageFile!, fit: BoxFit.cover)
                            : (_iconImageUrl != null &&
                                    _iconImageUrl!.isNotEmpty)
                                ? Image.network(
                                    _iconImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const _AvatarPlaceholder(),
                                  )
                                : const _AvatarPlaceholder(),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _Dt.dark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Section wrapper ──────────────────────────────────────────────────────

  Widget _buildSection(String title, {Widget? action, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _Dt.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  // ─── Details card ─────────────────────────────────────────────────────────

  Widget _buildDetailsCard() {
    return _Card(
      child: Column(
        children: [
          _buildEditableProfileField(
            icon: Icons.storefront_outlined,
            label: 'Shop name',
            controller: _shopNameController,
            hint: 'Enter your shop name',
            isEditing: _isEditingShopName,
            isSaving: _savingProfilePart == 'shop_name',
            onEdit: () => setState(() {
              _shopNameBeforeEdit = _shopNameController.text;
              _isEditingShopName = true;
            }),
            onDiscard: () => setState(() {
              _shopNameController.text = _shopNameBeforeEdit;
              _isEditingShopName = false;
            }),
            onSave: _saveShopName,
          ),
          _buildInCardDivider(),
          _buildEditableProfileField(
            icon: Icons.notes_outlined,
            label: 'Description',
            controller: _descriptionController,
            hint: 'Describe your shop in a few words…',
            maxLines: 3,
            isEditing: _isEditingDescription,
            isSaving: _savingProfilePart == 'description',
            onEdit: () => setState(() {
              _descriptionBeforeEdit = _descriptionController.text;
              _isEditingDescription = true;
            }),
            onDiscard: () => setState(() {
              _descriptionController.text = _descriptionBeforeEdit;
              _isEditingDescription = false;
            }),
            onSave: _saveDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableProfileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isEditing,
    required bool isSaving,
    required VoidCallback onEdit,
    required VoidCallback onDiscard,
    required Future<void> Function() onSave,
    int maxLines = 1,
  }) {
    final value = controller.text.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: _Dt.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _Dt.textMuted,
                          letterSpacing: 0.2)),
                  const Spacer(),
                  if (!isEditing)
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_note,
                            size: 16, color: _Dt.textSecondary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              if (isEditing) ...[
                TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 1,
                  maxLines: maxLines,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        maxLines == 1 ? FontWeight.w600 : FontWeight.w500,
                    color: _Dt.textPrimary,
                    height: maxLines == 1 ? null : 1.5,
                  ),
                  cursorColor: _Dt.dark,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                        fontSize: 13,
                        color: _Dt.textMuted,
                        fontWeight: FontWeight.w400),
                    filled: true,
                    fillColor: _Dt.surfaceRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _Dt.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _Dt.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _Dt.border, width: 1.2),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.all(11),
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSaving ? null : onDiscard,
                      style: TextButton.styleFrom(
                        foregroundColor: _Dt.textSecondary,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text('Discard',
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Dt.dark,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _Dt.dark.withOpacity(0.55),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  value.isEmpty ? 'Not set' : value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        value.isEmpty ? FontWeight.w400 : FontWeight.w600,
                    color: value.isEmpty ? _Dt.textMuted : _Dt.textPrimary,
                    height: maxLines == 1 ? null : 1.45,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Location display ─────────────────────────────────────────────────────

  Widget _buildLocationCard() {
    return _Card(
      child: GestureDetector(
        onDoubleTap: _openLocationPicker,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _Dt.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Dt.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _Dt.surfaceRaised,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isUpdatingLocation
                      ? Icons.sync_rounded
                      : Icons.location_on_rounded,
                  color: _isUpdatingLocation ? _Dt.textSecondary : _Dt.dark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isUpdatingLocation
                          ? 'Updating location…'
                          : 'Shop location',
                      style: const TextStyle(
                        color: _Dt.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _addressController.text.trim().isEmpty
                          ? 'No location selected'
                          : _addressController.text.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _Dt.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isUpdatingLocation ? null : _openLocationPicker,
                tooltip: 'Edit location',
                icon: const Icon(
                  Icons.edit_location_alt_outlined,
                  color: _Dt.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Opening hours card ───────────────────────────────────────────────────

  Widget _buildHoursEditAction() {
    final isSaving = _savingProfilePart == 'hours';
    if (!_isEditingHours) {
      return IconButton(
        onPressed: _savingProfilePart == null ? _startHoursEditing : null,
        tooltip: 'Edit opening hours',
        visualDensity: VisualDensity.compact,
        icon:
            const Icon(Icons.edit_outlined, color: _Dt.textSecondary, size: 18),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: isSaving ? null : _discardHoursEdit,
          tooltip: 'Discard opening hours changes',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded,
              color: _Dt.textSecondary, size: 19),
        ),
        IconButton(
          onPressed: isSaving ? null : _saveHours,
          tooltip: 'Save opening hours',
          visualDensity: VisualDensity.compact,
          icon: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _Dt.dark),
                )
              : const Icon(Icons.check_rounded, color: _Dt.dark, size: 21),
        ),
      ],
    );
  }

  Widget _buildOpenHoursCard() {
    final selectedDayValidation =
        _isEditingHours ? _sessionValidationMessage(_selectedDayIndex) : null;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day picker row
          Row(
            children: List.generate(7, (i) {
              final hasSessions = _daySessions[i].isNotEmpty;
              final isSelected = _selectedDayIndex == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? _Dt.dark : _Dt.surfaceRaised,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _Dt.dark
                              : hasSessions
                                  ? _Dt.dark.withOpacity(0.35)
                                  : _Dt.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayLabel(i),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : hasSessions
                                      ? _Dt.dark
                                      : _Dt.textMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _shortDayLabel(i),
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.6)
                                  : hasSessions
                                      ? _Dt.textSecondary
                                      : _Dt.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          // Day label + action buttons
          Row(
            children: [
              Expanded(
                child: Text(
                  _fullDayLabel(_selectedDayIndex),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _Dt.textPrimary),
                ),
              ),
              if (_isEditingHours)
                GestureDetector(
                  onTap: () => _addSession(_selectedDayIndex),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _Dt.surfaceRaised,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _Dt.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 13, color: _Dt.textPrimary),
                        SizedBox(width: 4),
                        Text('Add session',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _Dt.textPrimary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_daySessions[_selectedDayIndex].isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _Dt.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _Dt.border),
              ),
              child: const Text(
                'No hours set — shop shows as closed today.',
                style: TextStyle(
                    fontSize: 11,
                    color: _Dt.textMuted,
                    fontWeight: FontWeight.w500),
              ),
            )
          else
            ..._daySessions[_selectedDayIndex].asMap().entries.map((entry) {
              final idx = entry.key;
              final session = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _TimeChip(
                        label: _formatTime(session.start),
                        onTap: _isEditingHours
                            ? () =>
                                _pickSessionTime(_selectedDayIndex, idx, true)
                            : null,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('to',
                          style: TextStyle(
                              fontSize: 12,
                              color: _Dt.textMuted,
                              fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: _TimeChip(
                        label: _formatTime(session.end),
                        onTap: _isEditingHours
                            ? () =>
                                _pickSessionTime(_selectedDayIndex, idx, false)
                            : null,
                      ),
                    ),
                    if (_isEditingHours) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeSession(_selectedDayIndex, idx),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _Dt.surfaceRaised,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _Dt.border),
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: _Dt.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          if (_isEditingHours && _daySessions[_selectedDayIndex].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                onTap: () => _showApplyHoursModal(_selectedDayIndex),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _Dt.surfaceRaised,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _Dt.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded,
                          size: 15, color: _Dt.textPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Apply ${_fullDayLabel(_selectedDayIndex)} hours to other days',
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _Dt.textPrimary),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: _Dt.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          if (selectedDayValidation != null) ...[
            const SizedBox(height: 6),
            Text(selectedDayValidation,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

  // ─── Account card ─────────────────────────────────────────────────────────

  Widget _buildAccountCard() {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _Dt.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _Dt.border),
            ),
            child: const Icon(Icons.phone_outlined,
                size: 16, color: _Dt.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connected mobile',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Dt.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  _phone.isNotEmpty ? _phone : 'Verified mobile account',
                  style: const TextStyle(fontSize: 12, color: _Dt.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _Dt.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _Dt.border),
            ),
            child: const Text('Verified',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _Dt.dark)),
          ),
        ],
      ),
    );
  }

  // ─── Footer buttons ───────────────────────────────────────────────────────

  Widget _buildFooterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Logout — outline, minimal
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: _Dt.textSecondary,
                side: const BorderSide(color: _Dt.border, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              icon: const Icon(Icons.logout_rounded,
                  size: 15, color: _Dt.textSecondary),
              label: const Text('Log out',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _Dt.textSecondary)),
            ),
          ),
          const SizedBox(height: 24),
          // ─── Legal & App Policies Section ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _Dt.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gavel_rounded,
                        size: 16, color: _Dt.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Legal & Compliance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Dt.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildLegalTile(
                  title: 'Terms & Conditions',
                  subtitle:
                      'Vendor service rules, order policies & disclaimers',
                  icon: Icons.description_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsAndPolicyScreen(
                        initialTab: LegalTab.terms,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: _Dt.border),
                _buildLegalTile(
                  title: 'Privacy Policy',
                  subtitle: 'How shop information & location data are handled',
                  icon: Icons.shield_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsAndPolicyScreen(
                        initialTab: LegalTab.privacy,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: _Dt.border),
                _buildLegalTile(
                  title: 'Help & Support',
                  subtitle: 'Get help with your shop, account, or ZTEEL tools',
                  icon: Icons.support_agent_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'ZTEEL Vendor App • v1.0.0',
              style: TextStyle(
                fontSize: 11,
                color: _Dt.textMuted.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLegalTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF475569)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _Dt.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _Dt.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: _Dt.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInCardDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(height: 1, color: _Dt.border),
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _TimeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A))),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Icon(Icons.storefront_rounded,
          color: Color(0xFF475569), size: 24),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _OpeningSession {
  final TimeOfDay start;
  final TimeOfDay end;
  const _OpeningSession({required this.start, required this.end});

  _OpeningSession copyWith({TimeOfDay? start, TimeOfDay? end}) {
    return _OpeningSession(start: start ?? this.start, end: end ?? this.end);
  }
}
