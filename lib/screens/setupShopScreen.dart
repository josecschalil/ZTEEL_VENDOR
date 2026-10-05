import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:frontend/screens/locationPageScreen.dart';
import 'package:frontend/screens/vendor_home.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupShopScreen extends StatefulWidget {
  const SetupShopScreen({super.key});

  @override
  State<SetupShopScreen> createState() => _SetupShopScreenState();
}

class _SetupShopScreenState extends State<SetupShopScreen> {
  // ============================================================
  // THEME
  // ============================================================

  static const Color slate950 = Color(0xFF020617);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);

  static const Color accent = Color(0xFF3B82F6);
  static const Color danger = Color(0xFFEF4444);

  // ============================================================
  // ONBOARDING
  //
  // 0 = Welcome
  // 1 = Business Profile
  // 2 = Location + Hours
  // 3 = Review
  // 4 = Success
  // ============================================================

  int _currentStep = 0;

  // The progress indicator represents the four setup stages.
  static const int totalSetupSteps = 4;

  final ScrollController _scrollController = ScrollController();

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _descController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  // ============================================================
  // LOCATION
  // ============================================================

  double _latitude = 12.9716;
  double _longitude = 77.5946;

  // ============================================================
  // IMAGES
  // ============================================================

  File? _iconImageFile;
  File? _coverImageFile;

  String? _iconImageUrl;
  String? _coverImageUrl;

  bool _isUploadingIcon = false;
  bool _isUploadingCover = false;

  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // OPENING HOURS
  // ============================================================

  final List<List<_OpeningSession>> _daySessions = List.generate(
    7,
    (_) => <_OpeningSession>[],
  );

  int _selectedDayIndex = 0;

  // ============================================================
  // STATE
  // ============================================================

  bool _isSubmitting = false;
  bool _isLoadingProfile = true;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadVendorProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD EXISTING VENDOR PROFILE
  // ============================================================

  Future<void> _loadVendorProfile() async {
    try {
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
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });

      _showToast(
        'Could not load your shop details.',
        positive: false,
      );
    }
  }

  // ============================================================
  // IMAGE PICKING
  // ============================================================

  Future<void> _pickIconImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null) return;

      setState(() {
        _iconImageFile = File(picked.path);
        _iconImageUrl = null;
      });
    } catch (_) {
      if (!mounted) return;
      _showToast(
        'Could not select profile image.',
        positive: false,
      );
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null) return;

      setState(() {
        _coverImageFile = File(picked.path);
        _coverImageUrl = null;
      });
    } catch (_) {
      if (!mounted) return;
      _showToast(
        'Could not select cover image.',
        positive: false,
      );
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _openLocationPicker() async {
    final picked = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialPosition: LatLng(
            _latitude,
            _longitude,
          ),
          initialAddress: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
        ),
      ),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _addressController.text = picked.address;

      _latitude = picked.latitude;

      _longitude = picked.longitude;
    });

    _showToast(
      'Shop location updated.',
      positive: true,
    );
  }

  // ============================================================
  // OPENING HOURS
  // ============================================================

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  String _fullDayLabel(int index) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[index];
  }

  String _shortDayLabel(int index) {
    const days = [
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
      'S',
    ];

    return days[index];
  }

  int _toMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String? _sessionValidationMessage(
    int dayIndex,
  ) {
    final sessions = _daySessions[dayIndex];

    if (sessions.isEmpty) {
      return null;
    }

    final normalized = sessions
        .map(
          (session) {
            final startMins = _toMinutes(session.start);
            int endMins = _toMinutes(session.end);
            
            // Allow overnight hours
            if (endMins <= startMins) {
              endMins += 24 * 60;
            }
            
            return (startMins, endMins);
          },
        )
        .toList()
      ..sort(
        (a, b) => a.$1.compareTo(b.$1),
      );

    for (var i = 0; i < normalized.length; i++) {
      if (normalized[i].$1 >= normalized[i].$2) {
        return 'A session has an invalid time range.';
      }

      if (i > 0 && normalized[i].$1 < normalized[i - 1].$2) {
        return 'Sessions overlap. Please adjust the times.';
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: slate900,
              onPrimary: Colors.white,
              onSurface: slate900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _daySessions[dayIndex][sessionIndex] =
          _daySessions[dayIndex][sessionIndex].copyWith(
        start: isOpening ? picked : null,
        end: isOpening ? null : picked,
      );
    });
  }

  void _addSession(int dayIndex) {
    final sessions = _daySessions[dayIndex];

    final start = sessions.isNotEmpty
        ? sessions.last.end
        : const TimeOfDay(
            hour: 9,
            minute: 0,
          );

    final end = TimeOfDay(
      hour: (start.hour + 3) % 24,
      minute: start.minute,
    );

    setState(() {
      sessions.add(
        _OpeningSession(
          start: start,
          end: end,
        ),
      );
    });
  }

  void _removeSession(
    int dayIndex,
    int sessionIndex,
  ) {
    setState(() {
      _daySessions[dayIndex].removeAt(sessionIndex);
    });
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
    _showToast(
      'Applied ${_fullDayLabel(sourceDayIndex)} hours to all 7 days.',
      positive: true,
    );
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
    _showToast(
      'Applied ${_fullDayLabel(sourceDayIndex)} hours to weekdays (Mon–Fri).',
      positive: true,
    );
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
    _showToast(
      'Applied ${_fullDayLabel(sourceDayIndex)} hours to ${targetDayIndices.length} selected days.',
      positive: true,
    );
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
      backgroundColor: slate950,
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
                          color: slate700,
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
                            color: slate900,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: slate800),
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
                                  color: slate400,
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
                        color: slate500,
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
                        color: slate900,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: slate800),
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
                                  color: slate400,
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
                                    color: accent,
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
                                        ? slate950
                                        : isSelected
                                            ? Colors.white
                                            : slate800,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSource
                                          ? slate800
                                          : isSelected
                                              ? Colors.white
                                              : slate700,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _shortDayLabel(i),
                                        style: TextStyle(
                                          color: isSource
                                              ? slate600
                                              : isSelected
                                                  ? slate950
                                                  : slate200,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      if (isSource)
                                        const Text(
                                          'SRC',
                                          style: TextStyle(
                                            color: slate600,
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
                                                ? slate950
                                                : Colors.transparent,
                                            border: isSelected
                                                ? null
                                                : Border.all(
                                                    color: slate600,
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
                          color: selectedDays.isEmpty ? slate900 : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedDays.isEmpty ? slate800 : Colors.white,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            selectedDays.isEmpty
                                ? 'Select at least one day'
                                : 'Apply to ${selectedDays.length} Selected Day${selectedDays.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: selectedDays.isEmpty ? slate600 : slate950,
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
          color: slate900,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: slate800),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: slate800,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: slate700),
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
                      color: slate400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: slate500,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(
        milliseconds: 280,
      ),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleBack() {
    if (_currentStep == 0) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    if (_currentStep == 4) {
      setState(() {
        _currentStep = 3;
      });
      _scrollToTop();
      return;
    }

    setState(() {
      _currentStep--;
    });

    _scrollToTop();
  }

  void _goNext() {
    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep < totalSetupSteps - 1) {
      setState(() {
        _currentStep++;
      });

      _scrollToTop();
    }
  }

  bool _validateCurrentStep() {
    // Business profile
    if (_currentStep == 1) {
      if (_nameController.text.trim().isEmpty) {
        _showToast(
          'Business name is required.',
          positive: false,
        );

        return false;
      }

      return true;
    }

    // Location + hours
    if (_currentStep == 2) {
      if (_addressController.text.trim().isEmpty) {
        _showToast(
          'Please select your restaurant location.',
          positive: false,
        );

        return false;
      }

      final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int i = 0; i < 7; i++) {
        final validation = _sessionValidationMessage(i);
        if (validation != null) {
          _showToast(
            '${days[i]}: $validation',
            positive: false,
          );
          return false;
        }
      }

      return true;
    }

    return true;
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _completeSetup() async {
    if (!_validateCurrentStep()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      /*
       * IMPORTANT:
       *
       * There is intentionally NO category selector in this UI.
       *
       * Your current VendorService.updateVendorProfile()
       * still expects the category argument, so we keep a
       * hidden default value here for API compatibility.
       *
       * If you remove category from VendorService/backend,
       * remove this argument as well.
       */

      final profileRes = await VendorService.updateVendorProfile(
        businessName: _nameController.text.trim(),
        shopDescription: _descController.text.trim(),
        address: _addressController.text.trim(),
        category: 'restaurant',
        latitude: _latitude,
        longitude: _longitude,
        iconImage: _iconImageFile,
        coverImage: _coverImageFile,
      );

      if (profileRes['success'] != true) {
        if (!mounted) return;

        setState(() {
          _isSubmitting = false;
        });

        _showToast(
          profileRes['error'] ?? 'Failed to save shop profile.',
          positive: false,
        );

        return;
      }

      // ========================================================
      // BUSINESS HOURS
      // ========================================================

      final hasHours = _daySessions.any(
        (sessions) => sessions.isNotEmpty,
      );

      if (hasHours) {
        final List<Map<String, dynamic>> daysSchedule = [];

        for (int i = 0; i < 7; i++) {
          final sessions = _daySessions[i];

          final isClosed = sessions.isEmpty;

          final slots = sessions
              .map(
                (session) {
                  final closesNextDay = session.end.hour < session.start.hour || 
                      (session.end.hour == session.start.hour && session.end.minute <= session.start.minute);
                  return {
                    'opens_at': '${session.start.hour.toString().padLeft(2, '0')}:'
                        '${session.start.minute.toString().padLeft(2, '0')}:00',
                    'closes_at': '${session.end.hour.toString().padLeft(2, '0')}:'
                        '${session.end.minute.toString().padLeft(2, '0')}:00',
                    'closes_next_day': closesNextDay,
                  };
                },
              )
              .toList();

          daysSchedule.add({
            'weekday': i,
            'is_closed': isClosed,
            if (!isClosed) 'slots': slots,
          });
        }

        final hoursRes = await VendorService.updateBusinessHours(
          daysSchedule,
        );

        if (hoursRes['success'] == false) {
          if (!mounted) return;

          setState(() {
            _isSubmitting = false;
          });

          _showToast(
            hoursRes['error'] ?? 'Failed to save opening hours.',
            positive: false,
          );

          return;
        }
      }

      if (!mounted) return;

      await AuthService.setOnboarded(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('business_name', _nameController.text.trim());

      setState(() {
        _isSubmitting = false;
        _currentStep = 4;
      });

      _scrollToTop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showToast(
        'Something went wrong. Please try again.',
        positive: false,
      );
    }
  }

  // ============================================================
  // TOAST
  // ============================================================

  void _showToast(
    String message, {
    required bool positive,
  }) {
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    // Position toast cleanly above the sticky bottom action bar
    final bottomMargin = 104.0 + bottomPadding;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2400),
          dismissDirection: DismissDirection.horizontal,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            bottomMargin,
          ),
          elevation: 6,
          backgroundColor: positive
              ? slate900
              : const Color(
                  0xFF7F1D1D,
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
            side: BorderSide(
              color: positive ? slate800 : const Color(0xFF991B1B),
            ),
          ),
          content: Row(
            children: [
              Icon(
                positive
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: slate950,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: slate950,
        body: Stack(
          children: [
            // ── Background image on Step 0 (Welcome / Get Started) ──
            if (_currentStep == 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/setup_shop_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                    // Multi-stop gradient overlay to smoothly blend with slate950
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.35, 0.70, 1.0],
                          colors: [
                            slate950.withValues(alpha: 0.08),
                            slate950.withValues(alpha: 0.35),
                            slate950.withValues(alpha: 0.78),
                            slate950,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (_currentStep != 4) _buildTopBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: _currentStep < 4 ? 115 : 0,
                          ),
                          child: _buildCurrentStep(),
                        ),
                      ),
                    ],
                  ),
                  if (_currentStep < 4) _buildStickyBottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();

      case 1:
        return _buildBusinessProfileStep();

      case 2:
        return _buildLocationAndHoursStep();

      case 3:
        return _buildReviewStep();

      case 4:
        return _buildSuccessStep();

      default:
        return const SizedBox();
    }
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        8,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  0.06,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(
                    0.08,
                  ),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: _buildProgressIndicator(),
          ),
          const SizedBox(
            width: 16,
          ),
          Text(
            '${_currentStep + 1}/$totalSetupSteps',
            style: const TextStyle(
              color: slate400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(
        totalSetupSteps,
        (index) {
          final active = index <= _currentStep;

          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 250,
              ),
              margin: const EdgeInsets.symmetric(
                horizontal: 2,
              ),
              height: 3,
              decoration: BoxDecoration(
                color: active ? Colors.white : slate700,
                borderRadius: BorderRadius.circular(
                  4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // STEP 0 — WELCOME
  // ============================================================

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        42,
        24,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20,
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.06,
              ),
              borderRadius: BorderRadius.circular(
                16,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(
                  0.08,
                ),
              ),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: slate300,
              size: 25,
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          const Text(
            'Start your\nbusiness journey.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.3,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          const Text(
            'Set up your restaurant and start reaching more customers.',
            style: TextStyle(
              color: slate400,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(
            height: 42,
          ),
          _buildWelcomeFeature(
            icon: Icons.people_alt_outlined,
            title: 'Reach more customers',
            description: 'Get discovered by hungry customers nearby.',
          ),
          _buildWelcomeFeature(
            icon: Icons.receipt_long_outlined,
            title: 'Easy management',
            description: 'Manage your business, orders and operations.',
          ),
          _buildWelcomeFeature(
            icon: Icons.insights_outlined,
            title: 'Grow your business',
            description: 'Track performance and understand your customers.',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 25,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.06,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(
                  0.08,
                ),
              ),
            ),
            child: Icon(
              icon,
              color: slate300,
              size: 20,
            ),
          ),
          const SizedBox(
            width: 15,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: slate500,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 1 — BUSINESS PROFILE
  // ============================================================

  Widget _buildBusinessProfileStep() {
    ImageProvider? coverImage;

    if (_coverImageFile != null) {
      coverImage = FileImage(
        _coverImageFile!,
      );
    } else if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
      coverImage = NetworkImage(
        _coverImageUrl!,
      );
    }

    ImageProvider? iconImage;

    if (_iconImageFile != null) {
      iconImage = FileImage(
        _iconImageFile!,
      );
    } else if (_iconImageUrl != null && _iconImageUrl!.isNotEmpty) {
      iconImage = NetworkImage(
        _iconImageUrl!,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeading(
            eyebrow: 'YOUR BUSINESS',
            title: 'Create your\nstorefront.',
            subtitle:
                'Give customers a clear first impression of your restaurant.',
          ),

          const SizedBox(
            height: 30,
          ),

          // ==================================================
          // COVER + PROFILE
          // ==================================================

          SizedBox(
            height: 245,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ----------------------------------------------
                // COVER
                // ----------------------------------------------

                GestureDetector(
                  onTap: _isUploadingCover ? null : _pickCoverImage,
                  child: Container(
                    width: double.infinity,
                    height: 205,
                    decoration: BoxDecoration(
                      color: slate800,
                      borderRadius: BorderRadius.circular(
                        22,
                      ),
                      border: Border.all(
                        color: slate700,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (coverImage != null)
                          Image(
                            image: coverImage,
                            fit: BoxFit.cover,
                          )
                        else
                          _buildEmptyCover(),
                        if (coverImage != null)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(
                                    0.4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: slate950.withOpacity(
                                0.72,
                              ),
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo_camera_outlined,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                Text(
                                  'Cover',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isUploadingCover)
                          Container(
                            color: const Color(
                              0x99000000,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ----------------------------------------------
                // PROFILE IMAGE
                // ----------------------------------------------

                Positioned(
                  left: 20,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _isUploadingIcon ? null : _pickIconImage,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 94,
                          height: 94,
                          padding: const EdgeInsets.all(
                            3,
                          ),
                          decoration: const BoxDecoration(
                            color: slate950,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: slate800,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: slate700,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: iconImage != null
                                ? Image(
                                    image: iconImage,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.storefront_rounded,
                                    color: slate400,
                                    size: 32,
                                  ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: 2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: slate950,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: slate900,
                              size: 14,
                            ),
                          ),
                        ),
                        if (_isUploadingIcon)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(
                                  0x99000000,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          // ==================================================
          // BUSINESS NAME
          // ==================================================

          _buildDarkTextField(
            label: 'Business name',
            hint: 'e.g. The Urban Bites',
            controller: _nameController,
            icon: Icons.storefront_outlined,
          ),

          const SizedBox(
            height: 22,
          ),

          // ==================================================
          // DESCRIPTION
          // ==================================================

          _buildDarkTextField(
            label: 'Description',
            hint: 'Tell customers what makes your restaurant special.',
            controller: _descController,
            icon: Icons.notes_outlined,
            maxLines: 5,
            maxLength: 300,
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'A short description helps customers understand your restaurant before they order.',
            style: TextStyle(
              color: slate500,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCover() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(
              0.06,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            color: slate400,
            size: 23,
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        const Text(
          'Add a cover photo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        const Text(
          'Show customers what your place looks like',
          style: TextStyle(
            color: slate500,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 2 — LOCATION + HOURS
  // ============================================================

  Widget _buildLocationAndHoursStep() {
    final hasAddress = _addressController.text.trim().isNotEmpty;

    final validation = _sessionValidationMessage(
      _selectedDayIndex,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeading(
            eyebrow: 'LOCATION & HOURS',
            title: 'Tell customers\nwhen to find you.',
            subtitle: 'Set your restaurant location and opening schedule.',
          ),

          const SizedBox(
            height: 30,
          ),

          // ==================================================
          // LOCATION
          // ==================================================

          const Text(
            'LOCATION',
            style: TextStyle(
              color: slate400,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          GestureDetector(
            onTap: _openLocationPicker,
            child: Container(
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: slate900,
                borderRadius: BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color: slate800,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(
                        0.10,
                      ),
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: accent,
                      size: 21,
                    ),
                  ),
                  const SizedBox(
                    width: 13,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAddress
                              ? 'Restaurant location'
                              : 'Add restaurant location',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          hasAddress
                              ? _addressController.text.trim()
                              : 'Tap to select your exact location on the map.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: slate400,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        if (hasAddress) ...[
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            '${_latitude.toStringAsFixed(5)}, '
                            '${_longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: slate600,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.06,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                      border: Border.all(
                        color: slate700,
                      ),
                    ),
                    child: Text(
                      hasAddress ? 'Change' : 'Pick',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 34,
          ),

          // ==================================================
          // OPENING HOURS
          // ==================================================

          const Text(
            'OPENING HOURS',
            style: TextStyle(
              color: slate400,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Set different sessions for each day.',
            style: TextStyle(
              color: slate500,
              fontSize: 11.5,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          _buildDaySelector(),

          const SizedBox(
            height: 12,
          ),

          _buildBusinessHoursCard(
            validation,
          ),

          const SizedBox(
            height: 16,
          ),

          Container(
            padding: const EdgeInsets.all(
              14,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.035,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(
                  0.055,
                ),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: slate500,
                  size: 17,
                ),
                SizedBox(
                  width: 9,
                ),
                Expanded(
                  child: Text(
                    'You can add multiple sessions, such as 9 AM–2 PM and 5 PM–11 PM.',
                    style: TextStyle(
                      color: slate500,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        7,
        (index) {
          final selected = _selectedDayIndex == index;

          final hasHours = _daySessions[index].isNotEmpty;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 180,
              ),
              width: 40,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? Colors.white : slate900,
                borderRadius: BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: selected ? Colors.white : slate800,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _shortDayLabel(
                      index,
                    ),
                    style: TextStyle(
                      color: selected ? slate900 : slate400,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: hasHours ? accent : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessHoursCard(
    String? validation,
  ) {
    final sessions = _daySessions[_selectedDayIndex];

    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: slate900,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: slate800,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fullDayLabel(
                      _selectedDayIndex,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    sessions.isEmpty
                        ? 'Closed'
                        : '${sessions.length} ${sessions.length == 1 ? 'opening session' : 'opening sessions'}',
                    style: const TextStyle(
                      color: slate500,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sessions.isNotEmpty) ...[],
                  GestureDetector(
                    onTap: () => _addSession(
                      _selectedDayIndex,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.06,
                        ),
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                        border: Border.all(
                          color: slate700,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            'Add hours',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          if (sessions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: slate800,
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.do_not_disturb_on_outlined,
                    color: slate500,
                    size: 23,
                  ),
                  SizedBox(
                    height: 7,
                  ),
                  Text(
                    'Closed',
                    style: TextStyle(
                      color: slate300,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...sessions.asMap().entries.map(
              (entry) {
                final index = entry.key;

                final session = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                          session.start,
                          () => _pickSessionTime(
                            _selectedDayIndex,
                            index,
                            true,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: slate600,
                          size: 15,
                        ),
                      ),
                      Expanded(
                        child: _buildTimeField(
                          session.end,
                          () => _pickSessionTime(
                            _selectedDayIndex,
                            index,
                            false,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      GestureDetector(
                        onTap: () => _removeSession(
                          _selectedDayIndex,
                          index,
                        ),
                        child: Container(
                          width: 38,
                          height: 44,
                          decoration: BoxDecoration(
                            color: danger.withOpacity(
                              0.10,
                            ),
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(
                              0xFFF87171,
                            ),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (sessions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                top: 4,
              ),
              child: InkWell(
                onTap: () => _showApplyHoursModal(
                  _selectedDayIndex,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.04,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                    border: Border.all(
                      color: slate800,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        color: accent,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          'Apply ${_fullDayLabel(_selectedDayIndex)} hours to other days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: slate500,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (validation != null)
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
              ),
              child: Text(
                validation,
                style: const TextStyle(
                  color: Color(
                    0xFFF87171,
                  ),
                  fontSize: 11.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeField(
    TimeOfDay time,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: slate800,
          borderRadius: BorderRadius.circular(
            11,
          ),
          border: Border.all(
            color: slate700,
          ),
        ),
        child: Text(
          _formatTime(
            time,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 3 — REVIEW
  // ============================================================

  Widget _buildReviewStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeading(
            eyebrow: 'FINAL REVIEW',
            title: 'Review your\ndetails.',
            subtitle: 'Everything looks good? Finish your restaurant setup.',
          ),
          const SizedBox(
            height: 28,
          ),
          _buildReviewCard(
            icon: Icons.storefront_outlined,
            title: 'Business profile',
            subtitle: _nameController.text.trim().isEmpty
                ? 'Business name not added'
                : _nameController.text.trim(),
            detail: _descController.text.trim().isEmpty
                ? 'No description added'
                : _descController.text.trim(),
            onTap: () {
              setState(() {
                _currentStep = 1;
              });

              _scrollToTop();
            },
          ),
          _buildReviewCard(
            icon: Icons.photo_library_outlined,
            title: 'Storefront images',
            subtitle: _iconImageFile != null ||
                    (_iconImageUrl != null && _iconImageUrl!.isNotEmpty)
                ? 'Profile image added'
                : 'Profile image not added',
            detail: _coverImageFile != null ||
                    (_coverImageUrl != null && _coverImageUrl!.isNotEmpty)
                ? 'Cover image added'
                : 'Cover image not added',
            onTap: () {
              setState(() {
                _currentStep = 1;
              });

              _scrollToTop();
            },
          ),
          _buildReviewCard(
            icon: Icons.location_on_outlined,
            title: 'Location',
            subtitle: _addressController.text.trim().isEmpty
                ? 'Location not selected'
                : _addressController.text.trim(),
            detail: '${_latitude.toStringAsFixed(5)}, '
                '${_longitude.toStringAsFixed(5)}',
            onTap: () {
              setState(() {
                _currentStep = 2;
              });

              _scrollToTop();
            },
          ),
          _buildReviewCard(
            icon: Icons.access_time_rounded,
            title: 'Opening hours',
            subtitle: _openingDaysSummary(),
            detail: 'Business schedule',
            onTap: () {
              setState(() {
                _currentStep = 2;
              });

              _scrollToTop();
            },
          ),
          const SizedBox(
            height: 16,
          ),
          Container(
            padding: const EdgeInsets.all(
              16,
            ),
            decoration: BoxDecoration(
              color: accent.withOpacity(
                0.07,
              ),
              borderRadius: BorderRadius.circular(
                16,
              ),
              border: Border.all(
                color: accent.withOpacity(
                  0.15,
                ),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: accent,
                  size: 19,
                ),
                SizedBox(
                  width: 11,
                ),
                Expanded(
                  child: Text(
                    'Your information will be saved when you finish setup.',
                    style: TextStyle(
                      color: slate300,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _openingDaysSummary() {
    final count = _daySessions
        .where(
          (sessions) => sessions.isNotEmpty,
        )
        .length;

    if (count == 0) {
      return 'No opening hours added';
    }

    return '$count ${count == 1 ? 'day' : 'days'} per week';
  }

  Widget _buildReviewCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String detail,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.all(
          16,
        ),
        decoration: BoxDecoration(
          color: slate900,
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: slate800,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  0.05,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                icon,
                color: slate300,
                size: 20,
              ),
            ),
            const SizedBox(
              width: 13,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: slate300,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: slate500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: slate600,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 4 — SUCCESS
  // ============================================================

  Widget _buildSuccessStep() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(
                    0.08,
                  ),
                  border: Border.all(
                    color: accent.withOpacity(
                      0.45,
                    ),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 43,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              const Text(
                'You’re all set!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'Your restaurant has been successfully set up. You can now start managing your business.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: slate400,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(
                height: 38,
              ),
              _buildPrimaryButton(
                label: 'Go to Dashboard',
                icon: Icons.arrow_forward_rounded,
                onTap: () async {
                  await AuthService.setOnboarded(true);
                  if (!mounted) return;
                  Navigator.of(
                    context,
                  ).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const VendorHome(),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(
                height: 12,
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentStep = 1;
                  });

                  _scrollToTop();
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      15,
                    ),
                    border: Border.all(
                      color: slate700,
                    ),
                  ),
                  child: const Text(
                    'Edit Details',
                    style: TextStyle(
                      color: slate300,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

  // ============================================================
  // STICKY BOTTOM BAR
  // ============================================================

  Widget _buildStickyBottomBar() {
    String label;
    IconData icon;
    VoidCallback action;

    switch (_currentStep) {
      case 0:
        label = 'Get Started';
        icon = Icons.arrow_forward_rounded;
        action = _goNext;
        break;

      case 1:
        label = 'Continue';
        icon = Icons.arrow_forward_rounded;
        action = _goNext;
        break;

      case 2:
        label = 'Review Details';
        icon = Icons.arrow_forward_rounded;
        action = _goNext;
        break;

      case 3:
        label = 'Submit & Finish';
        icon = Icons.check_rounded;
        action = _completeSetup;
        break;

      default:
        label = 'Continue';
        icon = Icons.arrow_forward_rounded;
        action = _goNext;
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          24,
          14,
          24,
          24,
        ),
        decoration: BoxDecoration(
          color: slate950.withOpacity(
            0.97,
          ),
          border: const Border(
            top: BorderSide(
              color: slate800,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: _buildPrimaryButton(
            label: label,
            icon: icon,
            loading: _isSubmitting,
            onTap: action,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHARED UI
  // ============================================================

  Widget _buildStepHeading({
    required String eyebrow,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: slate400,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: slate500,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDarkTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: slate300,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Container(
          decoration: BoxDecoration(
            color: slate900,
            borderRadius: BorderRadius.circular(
              15,
            ),
            border: Border.all(
              color: slate800,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: slate600,
                fontSize: 13,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: 15,
                  right: 8,
                  top: maxLines > 1 ? 13 : 0,
                ),
                child: Icon(
                  icon,
                  color: slate500,
                  size: 19,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
              ),
              counterStyle: const TextStyle(
                color: slate500,
                fontSize: 10,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            15,
          ),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: slate900,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: slate900,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Icon(
                      icon,
                      color: slate900,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ================================================================
// OPENING SESSION MODEL
// ================================================================

class _OpeningSession {
  final TimeOfDay start;
  final TimeOfDay end;

  const _OpeningSession({
    required this.start,
    required this.end,
  });

  _OpeningSession copyWith({
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return _OpeningSession(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}
