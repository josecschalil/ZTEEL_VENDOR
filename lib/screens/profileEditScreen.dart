import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/screens/PhoneAuthScreen.dart';
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

  // Accents — slate-900 primary, emerald secondary (matches dashboard)
  static const accent = Color(0xFF0F172A); // slate-900
  static const emerald = Color(0xFF10B981); // emerald-500
  static const emeraldLight = Color(0xFF6EE7B7); // emerald-300
  static const emeraldBg = Color(0xFFECFDF5); // emerald-50
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

  String _selectedCategory = 'restaurant';
  String _phone = '';
  double _latitude = 12.9716;
  double _longitude = 77.5946;

  File? _iconImageFile;
  File? _coverImageFile;
  String? _iconImageUrl;
  String? _coverImageUrl;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingIcon = false;
  bool _isUploadingCover = false;
  bool _isMapInteractive = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadVendorProfile();
  }

  Future<void> _loadVendorProfile() async {
    final res = await VendorService.getVendorProfile();
    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        if (data['business_name'] != null)
          _shopNameController.text = data['business_name'].toString();
        if (data['shop_description'] != null)
          _descriptionController.text = data['shop_description'].toString();
        if (data['address'] != null)
          _addressController.text = data['address'].toString();
        if (data['category'] != null)
          _selectedCategory = data['category'].toString().toLowerCase();
        if (data['phone_number'] != null)
          _phone = data['phone_number'].toString();
        if (data['latitude'] != null)
          _latitude = (data['latitude'] as num).toDouble();
        if (data['longitude'] != null)
          _longitude = (data['longitude'] as num).toDouble();
        _iconImageUrl = data['icon_image']?.toString();
        _coverImageUrl = data['cover_image']?.toString();
        if (data['business_hours'] != null && data['business_hours'] is List) {
          _parseBusinessHours(data['business_hours'] as List);
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final profileRes = await VendorService.updateVendorProfile(
      businessName: _shopNameController.text.trim(),
      shopDescription: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      category: _selectedCategory,
      latitude: _latitude,
      longitude: _longitude,
      iconImage: _iconImageFile,
      coverImage: _coverImageFile,
    );

    if (profileRes['success'] != true) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack(profileRes['error'] ?? 'Failed to update profile');
      return;
    }

    List<Map<String, dynamic>> daysSchedule = [];
    for (int i = 0; i < 7; i++) {
      final sessions = _daySessions[i];
      final isClosed = sessions.isEmpty;
      final slots = sessions
          .map((s) => {
                'opens_at':
                    '${s.start.hour.toString().padLeft(2, '0')}:${s.start.minute.toString().padLeft(2, '0')}:00',
                'closes_at':
                    '${s.end.hour.toString().padLeft(2, '0')}:${s.end.minute.toString().padLeft(2, '0')}:00',
                'closes_next_day': false,
              })
          .toList();
      daysSchedule.add(
          {'weekday': i, 'is_closed': isClosed, if (!isClosed) 'slots': slots});
    }

    await VendorService.updateBusinessHours(daysSchedule);
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showSnack('Profile saved.', success: true);
    _loadVendorProfile();
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
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
            primary: _Dt.emerald,
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
    _showSnack('Applied ${_fullDayLabel(sourceDayIndex)} hours to all 7 days.',
        success: true);
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
    _showSnack(
        'Applied ${_fullDayLabel(sourceDayIndex)} hours to weekdays (Mon–Fri).',
        success: true);
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
    _showSnack(
        'Applied ${_fullDayLabel(sourceDayIndex)} hours to ${targetDayIndices.length} selected days.',
        success: true);
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
      backgroundColor: _Dt.dark,
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
                          color: const Color(0xFF334155),
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
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: const Icon(
                            Icons.copy_all_rounded,
                            color: Colors.white,
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
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                summaryText,
                                style: const TextStyle(
                                  color: _Dt.textMuted,
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
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF334155)),
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
                                  color: _Dt.textMuted,
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
                                    color: Colors.white,
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
                                        ? const Color(0xFF0F172A)
                                        : isSelected
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSource
                                          ? const Color(0xFF1E293B)
                                          : isSelected
                                              ? Colors.white
                                              : const Color(0xFF334155),
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
                                              ? _Dt.textSecondary
                                              : isSelected
                                                  ? _Dt.dark
                                                  : _Dt.border,
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
                                                    color: _Dt.textSecondary,
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
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedDays.isEmpty
                                ? const Color(0xFF334155)
                                : Colors.white,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            selectedDays.isEmpty
                                ? 'Select at least one day'
                                : 'Apply to ${selectedDays.length} Selected Day${selectedDays.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: selectedDays.isEmpty
                                  ? _Dt.textSecondary
                                  : _Dt.dark,
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
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
            ? const Center(child: CircularProgressIndicator(color: _Dt.emerald))
            : RefreshIndicator(
                onRefresh: _loadVendorProfile,
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
                      _buildSection('Opening Hours',
                          child: _buildOpenHoursCard()),
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
                              color: _Dt.emerald,
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
                        onTap: _isUploadingCover ? null : _showCoverPhotoOptions,
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
                    color: const Color(0xFF1E293B),
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
                            color: const Color(0xFF1E293B),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: _Dt.emerald,
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
                      color: _Dt.emerald,
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

  Widget _buildSection(String title, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
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
          _FieldRow(
            icon: Icons.storefront_outlined,
            label: 'Shop name',
            child: TextField(
              controller: _shopNameController,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _Dt.textPrimary),
              cursorColor: _Dt.emerald,
              decoration: const InputDecoration(
                hintText: 'Enter your shop name',
                hintStyle: TextStyle(
                    fontSize: 13,
                    color: _Dt.textMuted,
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          _buildInCardDivider(),
          _FieldRow(
            icon: Icons.notes_outlined,
            label: 'Description',
            child: TextField(
              controller: _descriptionController,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _Dt.textPrimary,
                  height: 1.5),
              cursorColor: _Dt.emerald,
              decoration: const InputDecoration(
                hintText: 'Describe your shop in a few words…',
                hintStyle: TextStyle(
                    fontSize: 13,
                    color: _Dt.textMuted,
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          _buildInCardDivider(),
          _FieldRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            child: TextField(
              controller: _addressController,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _Dt.textPrimary),
              cursorColor: _Dt.emerald,
              decoration: const InputDecoration(
                hintText: 'Enter your shop address',
                hintStyle: TextStyle(
                    fontSize: 13,
                    color: _Dt.textMuted,
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Location map card ────────────────────────────────────────────────────

  Widget _buildLocationCard() {
    final shopLocation = LatLng(_latitude, _longitude);
    return _Card(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              GestureDetector(
                onDoubleTap: () {
                  setState(() {
                    _isMapInteractive = !_isMapInteractive;
                  });
                },
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: shopLocation,
                    initialZoom: 14,
                    interactionOptions: InteractionOptions(
                      flags: _isMapInteractive
                          ? (InteractiveFlag.pinchZoom |
                              InteractiveFlag.drag |
                              InteractiveFlag.doubleTapZoom)
                          : InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.frontend',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: shopLocation,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: _Dt.dark,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Interaction helper badge
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMapInteractive = !_isMapInteractive;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isMapInteractive
                          ? _Dt.dark.withValues(alpha: 0.88)
                          : Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isMapInteractive
                            ? _Dt.emerald.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isMapInteractive
                              ? Icons.lock_open_rounded
                              : Icons.touch_app_outlined,
                          size: 13,
                          color: _isMapInteractive
                              ? _Dt.emeraldLight
                              : Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isMapInteractive
                              ? 'Map active · Tap to lock'
                              : 'Double tap to edit map',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _isMapInteractive
                                ? _Dt.emeraldLight
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Opening hours card ───────────────────────────────────────────────────

  Widget _buildOpenHoursCard() {
    final selectedDayValidation = _sessionValidationMessage(_selectedDayIndex);
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
                                  ? _Dt.emerald.withOpacity(0.5)
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
                                      ? _Dt.emerald
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
                                      ? _Dt.emeraldLight
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
              if (_daySessions[_selectedDayIndex].isNotEmpty) ...[],
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
                        onTap: () =>
                            _pickSessionTime(_selectedDayIndex, idx, true),
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
                        onTap: () =>
                            _pickSessionTime(_selectedDayIndex, idx, false),
                      ),
                    ),
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
                ),
              );
            }),
          if (_daySessions[_selectedDayIndex].isNotEmpty)
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
              color: _Dt.emeraldBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _Dt.emerald.withOpacity(0.3)),
            ),
            child: const Text('Verified',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _Dt.emerald)),
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
          // Save button — slate-900 filled, matches dashboard CTAs
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Dt.dark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _Dt.dark.withOpacity(0.55),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text('Save changes',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2)),
            ),
          ),
          const SizedBox(height: 10),
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

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _FieldRow(
      {required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.2)),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
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
