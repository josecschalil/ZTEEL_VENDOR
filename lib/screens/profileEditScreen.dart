import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/app_colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/screens/PhoneAuthScreen.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/widgets/app_top_bar.dart';

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
        if (data['business_name'] != null) {
          _shopNameController.text = data['business_name'].toString();
        }
        if (data['shop_description'] != null) {
          _descriptionController.text = data['shop_description'].toString();
        }
        if (data['address'] != null) {
          _addressController.text = data['address'].toString();
        }
        if (data['category'] != null) {
          _selectedCategory = data['category'].toString().toLowerCase();
        }
        if (data['phone_number'] != null) {
          _phone = data['phone_number'].toString();
        }
        if (data['latitude'] != null) {
          _latitude = (data['latitude'] as num).toDouble();
        }
        if (data['longitude'] != null) {
          _longitude = (data['longitude'] as num).toDouble();
        }
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
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  void _parseBusinessHours(List<dynamic> hoursList) {
    for (int i = 0; i < 7; i++) {
      _daySessions[i].clear();
    }
    for (final dayItem in hoursList) {
      if (dayItem is Map<String, dynamic>) {
        final weekday = dayItem['weekday'] as int? ?? 0;
        final isClosed = dayItem['is_closed'] as bool? ?? false;
        final slots = dayItem['slots'] as List<dynamic>? ?? [];

        if (!isClosed && weekday >= 0 && weekday < 7) {
          for (final slot in slots) {
            if (slot is Map<String, dynamic>) {
              final opensAt = slot['opens_at']?.toString() ?? '09:00:00';
              final closesAt = slot['closes_at']?.toString() ?? '22:00:00';
              _daySessions[weekday].add(
                _OpeningSession(
                  start: _parseTimeOfDay(opensAt),
                  end: _parseTimeOfDay(closesAt),
                ),
              );
            }
          }
        }
      }
    }
  }

  bool _isUploadingIcon = false;
  bool _isUploadingCover = false;

  Future<void> _pickIconImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
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
          if (res['icon_image'] != null) {
            setState(() {
              _iconImageUrl = res['icon_image'].toString();
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Shop logo uploaded and updated!'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['error'] ?? 'Failed to upload shop logo'),
            backgroundColor: AppColors.orangeDim,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingIcon = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not pick icon: $e'),
        backgroundColor: AppColors.orangeDim,
      ));
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
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
          if (res['cover_image'] != null) {
            setState(() {
              _coverImageUrl = res['cover_image'].toString();
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Cover photo uploaded and updated!'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['error'] ?? 'Failed to upload cover photo'),
            backgroundColor: AppColors.orangeDim,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingCover = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not pick cover photo: $e'),
        backgroundColor: AppColors.orangeDim,
      ));
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    // 1. Update Profile (business_name, shop_description, address, category, lat, long)
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(profileRes['error'] ?? 'Failed to update profile'),
        backgroundColor: AppColors.orangeDim,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // 2. Update Business Hours Schedule
    List<Map<String, dynamic>> daysSchedule = [];
    for (int i = 0; i < 7; i++) {
      final sessions = _daySessions[i];
      final isClosed = sessions.isEmpty;
      final slots = sessions.map((s) => {
        'opens_at': '${s.start.hour.toString().padLeft(2, '0')}:${s.start.minute.toString().padLeft(2, '0')}:00',
        'closes_at': '${s.end.hour.toString().padLeft(2, '0')}:${s.end.minute.toString().padLeft(2, '0')}:00',
        'closes_next_day': false,
      }).toList();

      daysSchedule.add({
        'weekday': i,
        'is_closed': isClosed,
        if (!isClosed) 'slots': slots,
      });
    }

    await VendorService.updateBusinessHours(daysSchedule);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Profile updated successfully!'),
      backgroundColor: AppColors.orange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));

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

  String _dayLabel(int index) => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];

  String _fullDayLabel(int index) => [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][index];

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  int _toMinutes(TimeOfDay t) => (t.hour * 60) + t.minute;

  String? _sessionValidationMessage(int dayIndex) {
    final sessions = _daySessions[dayIndex];
    if (sessions.isEmpty) return null;

    final normalized = sessions
        .map((s) => (_toMinutes(s.start), _toMinutes(s.end)))
        .toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));

    for (var i = 0; i < normalized.length; i++) {
      if (normalized[i].$1 >= normalized[i].$2) {
        return 'A session has an invalid time range.';
      }
      if (i > 0 && normalized[i].$1 < normalized[i - 1].$2) {
        return 'Sessions overlap. Adjust times to avoid conflicts.';
      }
    }

    return null;
  }

  Future<void> _pickSessionTime(
    int dayIndex,
    int sessionIndex,
    bool isStart,
  ) async {
    final current = _daySessions[dayIndex][sessionIndex];
    final initialTime = isStart ? current.start : current.end;

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.orange,
            onSurface: AppColors.textPrimary,
            surface: AppColors.surfaceRaised,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() {
      final updated = _daySessions[dayIndex][sessionIndex].copyWith(
        start: isStart ? picked : null,
        end: isStart ? null : picked,
      );
      _daySessions[dayIndex][sessionIndex] = updated;
    });
  }

  void _addSession(int dayIndex) {
    final sessions = _daySessions[dayIndex];
    final fallbackStart = sessions.isNotEmpty
        ? sessions.last.end
        : const TimeOfDay(hour: 9, minute: 0);
    final fallbackEnd = TimeOfDay(
      hour: (fallbackStart.hour + 3) % 24,
      minute: fallbackStart.minute,
    );

    setState(() {
      sessions.add(_OpeningSession(start: fallbackStart, end: fallbackEnd));
    });
  }

  void _removeSession(int dayIndex, int sessionIndex) {
    setState(() {
      _daySessions[dayIndex].removeAt(sessionIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    AppTopBar(
                      title: 'Zteeel Vendor',
                      subtitle: 'Vendor Profile',
                      avatarUrl: ApiConfig.getImageUrl(_iconImageUrl),
                      trailing: [
                        IconButton(
                          onPressed: _loadVendorProfile,
                          icon: const Icon(Icons.refresh, color: AppColors.orange, size: 22),
                          tooltip: 'Refresh Profile',
                        ),
                      ],
                    ),
                    _buildCoverPhoto(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildShopInfoHeader(),
                          const SizedBox(height: 20),
                          _buildLabel('SHOP NAME'),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _shopNameController,
                            icon: Icons.storefront_outlined,
                            hint: 'Enter your shop name',
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('DESCRIPTION'),
                          const SizedBox(height: 6),
                          _buildDescriptionField(),
                          const SizedBox(height: 16),
                          _buildLabel('LOCATION / ADDRESS'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _addressController,
                            icon: Icons.location_on_outlined,
                            hint: 'Enter your shop address',
                          ),
                          const SizedBox(height: 10),
                          _buildLocationMap(),
                          const SizedBox(height: 20),
                          _buildOpenDaysSection(),
                          const SizedBox(height: 22),
                          _buildDivider(),
                          const SizedBox(height: 16),
                          _buildLabel('ACCOUNT & PREFERENCES'),
                          const SizedBox(height: 10),
                          _buildPhonePreferenceItem(),
                          const SizedBox(height: 20),
                          _buildSaveButton(),
                          const SizedBox(height: 10),
                          _buildLogoutButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }



  // ── Cover photo ────────────────────────────────────────────
  Widget _buildCoverPhoto() {
    ImageProvider? coverImg;
    if (_coverImageFile != null) {
      coverImg = FileImage(_coverImageFile!);
    } else if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
      coverImg = NetworkImage(_coverImageUrl!);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            image: coverImg != null
                ? DecorationImage(image: coverImg, fit: BoxFit.cover)
                : null,
          ),
          child: Stack(
            children: [
              if (coverImg == null)
                Positioned.fill(
                  child: Container(
                    color: AppColors.surfaceRaised,
                    child: const Center(
                      child: Icon(Icons.store_rounded, color: AppColors.textMuted, size: 50),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isUploadingCover)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: AppColors.orange,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Uploading cover photo...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _isUploadingCover ? null : _pickCoverImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.separator, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, color: AppColors.textWhite, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _isUploadingCover ? 'UPLOADING...' : 'CHANGE COVER',
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
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
        // Chef / Shop avatar image
        Positioned(
          bottom: -10,
          left: 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.bg, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _iconImageFile != null
                            ? Image.file(_iconImageFile!, width: 70, height: 70, fit: BoxFit.cover)
                            : (_iconImageUrl != null && _iconImageUrl!.isNotEmpty)
                                ? Image.network(
                                    _iconImageUrl!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.storefront_rounded,
                                      color: AppColors.orange,
                                      size: 36,
                                    ),
                                  )
                                : const Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.orange,
                                    size: 36,
                                  ),
                      ),
                      if (_isUploadingIcon)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.55),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.orange,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: GestureDetector(
                  onTap: _isUploadingIcon ? null : _pickIconImage,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.textWhite, size: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shop info header row ───────────────────────────────────
  Widget _buildShopInfoHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Shop Information',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.orange, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'ACTIVE VENDOR',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  // ── Label ──────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Text field ─────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: AppColors.orange,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: AppColors.orange, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // ── Description field ──────────────────────────────────────
  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 3,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        cursorColor: AppColors.orange,
        decoration: const InputDecoration(
          hintText: 'Write a short description for your shop...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(top: 12, bottom: 12),
        ),
      ),
    );
  }

  Widget _buildOpenDaysSection() {
    const fullDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDayValidation = _sessionValidationMessage(_selectedDayIndex);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('OPEN DAYS'),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (i) {
              final hasSessions = _daySessions[i].isNotEmpty;
              final isFocusedDay = _selectedDayIndex == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFocusedDay
                              ? AppColors.orange
                              : (hasSessions
                                  ? AppColors.orange.withValues(alpha: 0.45)
                                  : AppColors.border),
                          width: isFocusedDay ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dayLabel(i),
                            style: TextStyle(
                              color: hasSessions
                                  ? AppColors.orange
                                  : AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fullDayLabels[i],
                            style: TextStyle(
                              color: hasSessions
                                  ? AppColors.orangeLight
                                  : AppColors.textSecondary,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              height: 1,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _fullDayLabel(_selectedDayIndex),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addSession(_selectedDayIndex),
                icon: const Icon(Icons.add, size: 14, color: AppColors.orange),
                label: const Text(
                  'Add Session',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_daySessions[_selectedDayIndex].isEmpty)
            const Text(
              'No hours set for this day. Shop will show as closed.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                      child: GestureDetector(
                        onTap: () => _pickSessionTime(_selectedDayIndex, idx, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(_formatTime(session.start), style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('to', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickSessionTime(_selectedDayIndex, idx, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(_formatTime(session.end), style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeSession(_selectedDayIndex, idx),
                      icon: const Icon(Icons.close, size: 18, color: AppColors.orange),
                    ),
                  ],
                ),
              );
            }),
          if (selectedDayValidation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                selectedDayValidation,
                style: const TextStyle(
                  color: AppColors.orangeLight,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Map placeholder ────────────────────────────────────────
  Widget _buildLocationMap() {
    final shopLocation = LatLng(_latitude, _longitude);
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: shopLocation,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    color: AppColors.orange,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Divider ────────────────────────────────────────────────
  Widget _buildDivider() {
    return Container(height: 1, color: AppColors.border);
  }

  Widget _buildPhonePreferenceItem() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.phone_outlined, color: AppColors.orange, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connected Mobile Number',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _phone.isNotEmpty ? _phone : 'Verified mobile account',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Save button ────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.textWhite,
          disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.textWhite,
                ),
              )
            : const Text(
                'SAVE ALL CHANGES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
      ),
    );
  }

  // ── Logout button ──────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: const Icon(Icons.logout, size: 16, color: AppColors.textPrimary),
        label: const Text(
          'LOGOUT FROM VENDOR PANEL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _OpeningSession {
  final TimeOfDay start;
  final TimeOfDay end;

  const _OpeningSession({required this.start, required this.end});

  _OpeningSession copyWith({TimeOfDay? start, TimeOfDay? end}) {
    return _OpeningSession(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}
