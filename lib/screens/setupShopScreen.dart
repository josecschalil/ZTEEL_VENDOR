import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/screens/vendor_home.dart';
import 'package:frontend/app_colors.dart';
import 'package:frontend/services/vendor_service.dart';

class SetupShopScreen extends StatefulWidget {
  const SetupShopScreen({super.key});

  @override
  State<SetupShopScreen> createState() => _SetupShopScreenState();
}

class _SetupShopScreenState extends State<SetupShopScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<List<_OpeningSession>> _daySessions =
      List.generate(7, (_) => <_OpeningSession>[]);
  int _selectedDayIndex = 0;
  int _currentStep = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _loadVendorProfile();
  }

  Future<void> _loadVendorProfile() async {
    final res = await VendorService.getVendorProfile();
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        if (data['business_name'] != null && data['business_name'].toString().isNotEmpty) {
          _nameController.text = data['business_name'].toString();
        }
        if (data['shop_description'] != null) {
          _descController.text = data['shop_description'].toString();
        }
        if (data['address'] != null && data['address'].toString().isNotEmpty) {
          _addressController.text = data['address'].toString();
        }
        if (data['category'] != null && data['category'].toString().isNotEmpty) {
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
      });
    }
  }

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
            content: Text(res['error'] ?? 'Failed to upload logo'),
            backgroundColor: AppColors.orangeDim,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingIcon = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not pick icon image: $e'),
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
        content: Text('Could not pick cover image: $e'),
        backgroundColor: AppColors.orangeDim,
      ));
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

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
        return 'Sessions overlap. Please adjust time ranges.';
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
            primary: AppColors.orange,
            onPrimary: AppColors.textWhite,
            onSurface: AppColors.textPrimary,
            surface: AppColors.surface,
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

  Future<void> _showOperationsStep() async {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Shop name is mandatory to create your shop profile.'),
        backgroundColor: AppColors.orangeDim,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _currentStep = 1);
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _skipAndFinish() async {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Shop name is mandatory to create your shop profile.'),
        backgroundColor: AppColors.orangeDim,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    final profileRes = await VendorService.updateVendorProfile(
      businessName: rawName,
      shopDescription: _descController.text.trim(),
      address: _addressController.text.trim(),
      category: _selectedCategory,
      latitude: _latitude,
      longitude: _longitude,
      iconImage: _iconImageFile,
      coverImage: _coverImageFile,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (profileRes['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Shop created! Other details can be updated anytime from Profile.'),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const VendorHome()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(profileRes['error'] ?? 'Failed to create shop profile'),
        backgroundColor: AppColors.orangeDim,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  Future<void> _completeSetup() async {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Shop name is mandatory to create your shop profile.'),
        backgroundColor: AppColors.orangeDim,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. Update Profile (business_name, shop_description, address, category, lat, long)
    final profileRes = await VendorService.updateVendorProfile(
      businessName: rawName,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(profileRes['error'] ?? 'Failed to save shop profile'),
        backgroundColor: AppColors.orangeDim,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    // 2. Update Business Hours Schedule (if configured)
    bool hasHours = false;
    for (int i = 0; i < 7; i++) {
      if (_daySessions[i].isNotEmpty) {
        hasHours = true;
        break;
      }
    }

    if (hasHours) {
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
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Shop setup completed successfully!'),
      backgroundColor: AppColors.orange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const VendorHome()),
      (route) => false,
    );
  }

  void _handleBack() {
    if (_currentStep == 1) {
      setState(() => _currentStep = 0);
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFCFA),
        body: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 34),
                      _buildStepContent(),
                    ],
                  ),
                ),
                _buildFloatingSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Floating Top Bar ────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceRaised,
            fixedSize: const Size(44, 44),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'SHOP SETUP',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _skipAndFinish,
          child: Text(
            _currentStep == 0 ? 'Create Shop Now' : 'Skip optional steps',
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: KeyedSubtree(
            key: ValueKey(_currentStep),
            child: _buildHeader(),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedCrossFade(
          firstChild: _buildStorefrontBody(),
          secondChild: _buildOperationsBody(),
          crossFadeState: _currentStep == 0
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 420),
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
          sizeCurve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }



  Widget _buildStorefrontBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVisualIdentitySection(),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildTextField(
            label: 'Shop name *',
            hint: 'e.g. Amber & Spice Atelier',
            controller: _nameController,
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildTextField(
            label: 'Short description',
            hint: 'What do you serve and what makes it special?',
            controller: _descController,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 28),
        _buildPrivacyNote(),
      ],
    );
  }

  Widget _buildOperationsBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        _buildOpenDaysSection(),
        const SizedBox(height: 32),
        _buildLocationSection(),
        const SizedBox(height: 24),
        _buildTermsText(),
      ],
    );
  }

  // ─── Visual Identity Section ─────────────────────────────────────
  Widget _buildVisualIdentitySection() {
    ImageProvider? coverImg;
    if (_coverImageFile != null) {
      coverImg = FileImage(_coverImageFile!);
    } else if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
      coverImg = NetworkImage(_coverImageUrl!);
    }

    return SizedBox(
      height: 214,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 156,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF342C27), Color(0xFF7D4238)],
              ),
              image: coverImg != null
                  ? DecorationImage(
                      image: coverImg,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  if (coverImg == null)
                    Positioned(
                      top: -30,
                      right: -10,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  const Positioned(
                    left: 18,
                    top: 18,
                    child: Text(
                      'YOUR STOREFRONT',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  if (_isUploadingCover)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.55),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.orange,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Uploading cover...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: TextButton.icon(
                      onPressed: _isUploadingCover ? null : _pickCoverImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
                      label: Text(_isUploadingCover
                          ? 'Uploading...'
                          : (coverImg != null ? 'Change Cover' : 'Cover photo')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textWhite,
                        backgroundColor: Colors.black.withOpacity(0.35),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 0,
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFFCFA),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.13),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _iconImageFile != null
                                  ? Image.file(
                                      _iconImageFile!,
                                      width: 86,
                                      height: 86,
                                      fit: BoxFit.cover,
                                    )
                                  : (_iconImageUrl != null && _iconImageUrl!.isNotEmpty)
                                      ? Image.network(
                                          _iconImageUrl!,
                                          width: 86,
                                          height: 86,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.storefront_rounded,
                                            color: AppColors.orange,
                                            size: 34,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.storefront_rounded,
                                          color: AppColors.orange,
                                          size: 34,
                                        ),
                            ),
                            if (_isUploadingIcon)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.55),
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
                      right: -2,
                      bottom: 2,
                      child: GestureDetector(
                        onTap: _isUploadingIcon ? null : _pickIconImage,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFFCFA), width: 2),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.textWhite,
                            size: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    final title = _currentStep == 0
        ? 'Set your storefront'
        : 'Set up daily operations';
    final subtitle = _currentStep == 0
        ? 'Make your shop easy to recognise.'
        : 'Choose your hours and confirm your location.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Text(
              'STEP ${_currentStep + 1} OF 2',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            const Spacer(),
            Text(
              _currentStep == 0 ? 'Storefront' : 'Operations',
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0.5,
            end: (_currentStep + 1) / 2,
          ),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: AppColors.border,
              color: AppColors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orangeDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orangeBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined, color: AppColors.orange, size: 19),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Shop name is mandatory. All other shop details are optional and can be updated anytime from profile settings.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Open Days Section ──────────────────────────────────────────
  Widget _buildOpenDaysSection() {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final validation = _sessionValidationMessage(_selectedDayIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('BUSINESS HOURS'),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final hasSessions = _daySessions[i].isNotEmpty;
            final isFocused = _selectedDayIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = i),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isFocused
                      ? AppColors.orange
                      : (hasSessions
                          ? AppColors.orangeDim
                          : AppColors.surfaceRaised),
                  shape: BoxShape.circle,
                  border: isFocused
                      ? null
                      : Border.all(
                          color: hasSessions
                              ? AppColors.orange.withOpacity(0.3)
                              : AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  dayLabels[i],
                  style: TextStyle(
                    color: isFocused
                        ? AppColors.textWhite
                        : (hasSessions
                            ? AppColors.orange
                            : AppColors.textSecondary),
                    fontSize: 14,
                    fontWeight: isFocused || hasSessions
                        ? FontWeight.w500
                        : FontWeight.w400,
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
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
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addSession(_selectedDayIndex),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add hours'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_daySessions[_selectedDayIndex].isEmpty)
                const Text(
                  'No hours added. This day will show as closed.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                          child: Text('-',
                              style: TextStyle(color: AppColors.textSecondary)),
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
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textSecondary, size: 20),
                        ),
                      ],
                    ),
                  );
                }),
              if (validation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(validation,
                      style:
                          const TextStyle(color: AppColors.red, fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerField(
      {required TimeOfDay time, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          _formatTime(time),
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ─── Location Section ────────────────────────────────────────────
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('LOCATION ADDRESS'),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Shop Address',
          hint: 'Enter your full shop address',
          controller: _addressController,
          maxLines: 2,
        ),
      ],
    );
  }

  // ─── Save Button ─────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting
            ? null
            : (_currentStep == 0 ? _showOperationsStep : _completeSetup),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.textWhite,
          disabledBackgroundColor: AppColors.orange.withOpacity(0.6),
          disabledForegroundColor: AppColors.textWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.textWhite,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == 0 ? 'Continue' : 'Finish setup',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentStep == 0
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                    size: 19,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFloatingSaveButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: _buildSaveButton(),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return const Center(
      child: Text(
        "By continuing, you agree to ZTEEL's Vendor Terms and Conditions.",
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11.5,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.surfaceRaised,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
            ),
          ),
        ),
      ],
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
