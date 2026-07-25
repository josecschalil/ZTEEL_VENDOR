import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/vendor_home.dart';
import 'package:frontend/app_colors.dart';

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

  int _selectedNavIndex = 3;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _descController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        bottomNavigationBar: _buildBottomNav(),
        body: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroBranding(), // 280px tall banner + overlapping logo
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildVendorIdentityTip(),
                            const SizedBox(height: 24),
                            _buildTextField(
                              label: 'Shop Name',
                              hint: 'e.g. Amber & Spice Atelier',
                              controller: _nameController,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: 'Description',
                              hint: 'Describe your cuisine and offerings...',
                              controller: _descController,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 28),
                            _buildOpenDaysSection(),
                            const SizedBox(height: 28),
                            _buildLocationSection(),
                            const SizedBox(height: 32),
                            _buildSaveButton(),
                            const SizedBox(height: 16),
                            _buildTermsText(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildFloatingTopBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Floating Top Bar ────────────────────────────────────────────
  Widget _buildFloatingTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Text(
              'STEP 2 OF 2',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Branding ───────────────────────────────────────────────
  Widget _buildHeroBranding() {
    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner Background
          Container(
            height: 220,
            width: double.infinity,
            color: AppColors.surfaceElevated,
            // Using a simple grid pattern to keep it clean
            child: CustomPaint(painter: _SimpleBannerPainter()),
          ),
          // Edit Banner Button
          Positioned(
            top: 160,
            right: 16,
            child: _glassButton(
              icon: Icons.camera_alt_outlined,
              label: 'Add Cover',
              onTap: () {},
            ),
          ),
          // Avatar overlapping
          Positioned(
            bottom: 0,
            left: 24,
            child: Stack(
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.bg, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 3),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.textWhite,
                        size: 14,
                      ),
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

  Widget _glassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDark = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.7)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Enter your store details. This information will be visible to your customers.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ─── Vendor Identity Tip ─────────────────────────────────────────
  Widget _buildVendorIdentityTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.textSecondary, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'A clear logo and cover photo can significantly improve customer trust.',
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

  // ─── Text Fields ─────────────────────────────────────────────────
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: AppColors.orange,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: AppColors.surfaceRaised,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
            ),
          ),
        ),
      ],
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
        const SizedBox(height: 12),
        // Day selector row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final hasSessions = _daySessions[i].isNotEmpty;
            final isFocused = _selectedDayIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = i),
              child: Container(
                width: 40,
                height: 40,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
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
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _addSession(_selectedDayIndex),
                    child: const Text(
                      '+ Add Time',
                      style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_daySessions[_selectedDayIndex].isEmpty)
                const Text(
                  'Closed on this day.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(6),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('LOCATION'),
            GestureDetector(
              onTap: () {},
              child: const Text('Edit',
                  style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 90, // Compact and clean
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Small map square on the left
              SizedBox(
                width: 90,
                height: 90,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(8)),
                  child: CustomPaint(painter: _MapPainter()),
                ),
              ),
              // Address details on the right
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '12–14 Saffron Mews',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kensington, London, UK',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Save Button ─────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VendorHome()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Save & Continue',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return const Center(
      child: Text(
        "By continuing, you agree to Saffron Bistro's Vendor Terms and Conditions.",
        style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ─── Bottom Nav ───────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.grid_view_rounded, 'DASHBOARD'),
      (Icons.local_offer_outlined, 'OFFERS'),
      (Icons.receipt_long_outlined, 'ORDERS'),
      (Icons.person_rounded, 'PROFILE'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = _selectedNavIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedNavIndex = i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].$1,
                        size: 22,
                        color: active ? AppColors.orange : AppColors.textMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          color:
                              active ? AppColors.orange : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Custom Painters ─────────────────────────────────────────────────────────

class _SimpleBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.5)
      ..strokeWidth = 1.0;

    // Simple subtle grid pattern for the placeholder
    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Light map background
    final bgPaint = Paint()..color = const Color(0xFFF6F3EE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Map road / block grid lines
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0;
    for (double x = 0; x <= size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Land blocks
    final landPaint = Paint()..color = const Color(0xFFEBE6DD);
    _drawContinent(
        canvas, landPaint, size.width * 0.1, size.height * 0.1, 40, 40);
    _drawContinent(
        canvas, landPaint, size.width * 0.5, size.height * 0.2, 30, 40);
    _drawContinent(
        canvas, landPaint, size.width * 0.7, size.height * 0.1, 50, 40);

    // Location pin
    _drawPin(canvas, Offset(size.width * 0.50, size.height * 0.50));
  }

  void _drawContinent(
      Canvas canvas, Paint paint, double x, double y, double w, double h) {
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h), const Radius.circular(4));
    canvas.drawRRect(rect, paint);
  }

  void _drawPin(Canvas canvas, Offset center) {
    final outerPaint = Paint()..color = AppColors.orange;
    canvas.drawCircle(center, 6, outerPaint);

    final innerPaint = Paint()..color = AppColors.textWhite;
    canvas.drawCircle(center, 2.5, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
