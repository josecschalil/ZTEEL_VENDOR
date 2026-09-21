import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/screens/locationPageScreen.dart';
import 'package:frontend/screens/vendor_home.dart';
import 'package:frontend/services/vendor_service.dart';

class SetupShopScreen extends StatefulWidget {
  const SetupShopScreen({super.key});

  @override
  State<SetupShopScreen> createState() => _SetupShopScreenState();
}

class _SetupShopScreenState extends State<SetupShopScreen> {
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final List<List<_OpeningSession>> _daySessions =
      List.generate(7, (_) => <_OpeningSession>[]);
  int _selectedDayIndex = 0;

  String _selectedCategory = 'restaurant';
  double _latitude = 12.9716;
  double _longitude = 77.5946;

  File? _iconImageFile;
  File? _coverImageFile;
  String? _iconImageUrl;
  String? _coverImageUrl;

  bool _isUploadingIcon = false;
  bool _isUploadingCover = false;
  bool _isSubmitting = false;
  bool _isLoadingProfile = true;

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
          _nameController.text = data['business_name'].toString();
        }
        if (data['shop_description'] != null) {
          _descController.text = data['shop_description'].toString();
        }
        if (data['address'] != null) {
          _addressController.text = data['address'].toString();
        }
        if (data['category'] != null) {
          _selectedCategory = data['category'].toString().toLowerCase();
        }
        if (data['latitude'] != null) {
          _latitude = (data['latitude'] as num).toDouble();
        }
        if (data['longitude'] != null) {
          _longitude = (data['longitude'] as num).toDouble();
        }
        _iconImageUrl = data['icon_image']?.toString();
        _coverImageUrl = data['cover_image']?.toString();
        _isLoadingProfile = false;
      });
    } else {
      setState(() => _isLoadingProfile = false);
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
          if (res['icon_image'] != null) {
            _iconImageUrl = res['icon_image'].toString();
          }
          _showToast('Shop logo updated successfully!', positive: true);
        } else {
          _showToast(res['error'] ?? 'Failed to upload logo', positive: false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingIcon = false);
      _showToast('Could not pick icon image.', positive: false);
    }
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
          if (res['cover_image'] != null) {
            _coverImageUrl = res['cover_image'].toString();
          }
          _showToast('Cover photo updated successfully!', positive: true);
        } else {
          _showToast(res['error'] ?? 'Failed to upload cover photo',
              positive: false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingCover = false);
      _showToast('Could not pick cover image.', positive: false);
    }
  }

  // ─── Step 2 Operations Logic ─────────────────────────────────────────────────

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _fullDayLabel(int index) => [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][index];

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
        return 'Sessions overlap. Please adjust times.';
      }
    }
    return null;
  }

  Future<void> _pickSessionTime(
    int dayIndex,
    int sessionIndex,
    bool isOpening,
  ) async {
    final current = _daySessions[dayIndex][sessionIndex];
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? current.start : current.end,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryDark,
            onPrimary: AppColors.white,
            onSurface: AppColors.darkSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _daySessions[dayIndex][sessionIndex] =
            _daySessions[dayIndex][sessionIndex].copyWith(
          start: isOpening ? picked : null,
          end: isOpening ? null : picked,
        );
      });
    }
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

  void _showToast(String message, {required bool positive}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          elevation: 0,
          backgroundColor:
              positive ? AppColors.darkSurface : AppColors.primaryDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(
                positive
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                color: positive
                    ? AppColors.success
                    : AppColors.primaryDark,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _handleBack() {
    if (_currentStep == 1) {
      setState(() => _currentStep = 0);
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
    } else {
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _goToNextStep() {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      _showToast('Shop name is required.', positive: false);
      return;
    }
    setState(() => _currentStep = 1);
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic);
  }

  Future<void> _completeSetup() async {
    setState(() => _isSubmitting = true);

    // 1. Profile Update
    final profileRes = await VendorService.updateVendorProfile(
      businessName: _nameController.text.trim(),
      shopDescription: _descController.text.trim(),
      address: _addressController.text.trim(),
      category: _selectedCategory,
      latitude: _latitude,
      longitude: _longitude,
      iconImage: _iconImageFile,
      coverImage: _coverImageFile,
    );

    if (profileRes['success'] != true) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showToast(profileRes['error'] ?? 'Failed to save shop profile',
          positive: false);
      return;
    }

    // 2. Schedule Update
    bool hasHours = _daySessions.any((sessions) => sessions.isNotEmpty);
    if (hasHours) {
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

        daysSchedule.add({
          'weekday': i,
          'is_closed': isClosed,
          if (!isClosed) 'slots': slots,
        });
      }
      await VendorService.updateBusinessHours(daysSchedule);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showToast('Shop setup completed successfully!', positive: true);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const VendorHome()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 120),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCoverAndAvatar(),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedCrossFade(
                      firstChild: _buildStorefrontStep(),
                      secondChild: _buildOperationsStep(),
                      crossFadeState: _currentStep == 0
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                      firstCurve: Curves.easeOutCubic,
                      secondCurve: Curves.easeOutCubic,
                    ),
                  ),
                ],
              ),
            ),
            _buildStickyBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─── Hero Cover & Avatar Header ──────────────────────────────────────────────

  Widget _buildHeroCoverAndAvatar() {
    ImageProvider? coverImg;
    if (_coverImageFile != null) {
      coverImg = FileImage(_coverImageFile!);
    } else if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
      coverImg = NetworkImage(_coverImageUrl!);
    }

    ImageProvider? iconImg;
    if (_iconImageFile != null) {
      iconImg = FileImage(_iconImageFile!);
    } else if (_iconImageUrl != null && _iconImageUrl!.isNotEmpty) {
      iconImg = NetworkImage(_iconImageUrl!);
    }

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              image: coverImg != null
                  ? DecorationImage(
                      image: coverImg,
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        AppColors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 20,
                    child: GestureDetector(
                      onTap: _handleBack,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.white, size: 20),
                      ),
                    ),
                  ),
                  if (_currentStep == 0)
                    Center(
                      child: GestureDetector(
                        onTap: _isUploadingCover ? null : _pickCoverImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isUploadingCover)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      color: AppColors.white, strokeWidth: 2),
                                )
                              else
                                const Icon(Icons.camera_alt_outlined,
                                    color: AppColors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _isUploadingCover
                                    ? 'Uploading...'
                                    : (coverImg != null
                                        ? 'Change Cover'
                                        : 'Add Cover Photo'),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
          Positioned(
            bottom: 0,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.bg, width: 4),
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (iconImg != null)
                          Image(image: iconImg, fit: BoxFit.cover)
                        else
                          const Icon(Icons.storefront_rounded,
                              size: 36, color: AppColors.textMuted),
                        if (_isUploadingIcon)
                          Container(
                            color: AppColors.black.withOpacity(0.5),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: AppColors.success, strokeWidth: 2.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_currentStep == 0)
                  GestureDetector(
                    onTap: _isUploadingIcon ? null : _pickIconImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.bg, width: 3),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: AppColors.white, size: 14),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Storefront Profile ──────────────────────────────────────────────

  Widget _buildStorefrontStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            title: 'Business Profile',
            subtitle: 'These details will be displayed to your customers.',
            step: 1),
        const SizedBox(height: 24),
        _buildTextFieldCard(
          label: 'Shop Name *',
          hint: 'e.g. Artisan Trattoria',
          icon: Icons.store_mall_directory_outlined,
          controller: _nameController,
        ),
        const SizedBox(height: 20),
        _buildTextFieldCard(
          label: 'Description',
          hint: 'What kind of food do you serve?',
          icon: Icons.notes_rounded,
          controller: _descController,
          maxLines: 4,
        ),
      ],
    );
  }

  // ─── Step 2: Daily Operations ────────────────────────────────────────────────

  Future<void> _openLocationPicker() async {
    final picked = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialPosition: LatLng(_latitude, _longitude),
          initialAddress: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _addressController.text = picked.address;
        _latitude = picked.latitude;
        _longitude = picked.longitude;
      });
      _showToast('Shop location updated!', positive: true);
    }
  }

  Widget _buildLocationPickerCard() {
    final hasAddress = _addressController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shop Location *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openLocationPicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasAddress
                    ? AppColors.border
                    : AppColors.borderStrong,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hasAddress
                            ? AppColors.darkSurface.withValues(alpha: 0.07)
                            : AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasAddress
                            ? Icons.location_on_rounded
                            : Icons.add_location_alt_outlined,
                        color: hasAddress
                            ? AppColors.darkSurface
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasAddress
                                ? _addressController.text.trim()
                                : 'Select shop location on map',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  hasAddress ? FontWeight.w700 : FontWeight.w500,
                              color: hasAddress
                                  ? AppColors.darkSurface
                                  : AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasAddress
                                ? 'Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}'
                                : 'Tap to open map and pin exact store address',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasAddress
                                ? Icons.edit_location_alt_rounded
                                : Icons.map_rounded,
                            color: AppColors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasAddress ? 'Change' : 'Pick Map',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            title: 'Daily Operations',
            subtitle: 'Set your business hours and location details.',
            step: 2),
        const SizedBox(height: 24),
        _buildBusinessHoursSection(),
        const SizedBox(height: 28),
        _buildLocationPickerCard(),
        const SizedBox(height: 32),
        const Center(
          child: Text(
            "By finishing, you agree to our Vendor Terms & Conditions.",
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final validation = _sessionValidationMessage(_selectedDayIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Hours',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final hasSessions = _daySessions[i].isNotEmpty;
            final isFocused = _selectedDayIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isFocused
                      ? AppColors.darkSurface
                      : (hasSessions ? AppColors.successTint : AppColors.white),
                  shape: BoxShape.circle,
                  border: isFocused
                      ? null
                      : Border.all(
                          color: hasSessions
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.border,
                        ),
                ),
                alignment: Alignment.center,
                child: Text(
                  dayLabels[i],
                  style: TextStyle(
                    color: isFocused
                        ? AppColors.white
                        : (hasSessions
                            ? AppColors.success
                            : AppColors.textSecondary),
                    fontSize: 14,
                    fontWeight: isFocused || hasSessions
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fullDayLabel(_selectedDayIndex),
                    style: const TextStyle(
                      color: AppColors.darkSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _addSession(_selectedDayIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 16, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Add hours',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_daySessions[_selectedDayIndex].isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No hours added. Marked as Closed.',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                )
              else
                ..._daySessions[_selectedDayIndex].asMap().entries.map((entry) {
                  final idx = entry.key;
                  final session = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTimePickerField(
                            time: session.start,
                            onTap: () =>
                                _pickSessionTime(_selectedDayIndex, idx, true),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 16, color: AppColors.textMuted),
                        ),
                        Expanded(
                          child: _buildTimePickerField(
                            time: session.end,
                            onTap: () =>
                                _pickSessionTime(_selectedDayIndex, idx, false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _removeSession(_selectedDayIndex, idx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.dangerTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger, size: 18),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              if (validation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(validation,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerField({
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          _formatTime(time),
          style: const TextStyle(
            color: AppColors.darkSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─── Reusable Components ─────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required int step,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.darkSurface,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'STEP $step OF 2',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldCard({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.darkSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: maxLines == 1
                  ? Icon(icon, color: AppColors.textMuted, size: 20)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child:
                          Icon(icon, color: AppColors.textMuted, size: 20),
                    ),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.success, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : (_currentStep == 0 ? _goToNextStep : _completeSetup),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: AppColors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 0 ? 'Continue' : 'Finish Setup',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == 0
                            ? Icons.arrow_forward_rounded
                            : Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ],
                  ),
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
