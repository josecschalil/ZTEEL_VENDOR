import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/vendor_home.dart';

// ─── Color Palette ───────────────────────────────────────────────
class SBColors {
  static const bg = Color(0xFF130A04);
  static const surface = Color(0xFF1F1108);
  static const surfaceElevated = Color(0xFF261509);
  static const saffron = Color(0xFFE8622A);
  static const saffronLight = Color(0xFFF07840);
  static const saffronDim = Color(0x33E8622A);
  static const gold = Color(0xFFD4A853);
  static const textPrimary = Color(0xFFF5E6D3);
  static const textSecondary = Color(0xFF9A7A5F);
  static const textMuted = Color(0xFF5C3E28);
  static const border = Color(0xFF3A1E0A);
  static const borderAccent = Color(0xFF5C3E28);
  static const mapDark = Color(0xFF1F1108);
}

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

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
          colorScheme: const ColorScheme.dark(
            primary: SBColors.saffron,
            onSurface: SBColors.textPrimary,
            surface: SBColors.surfaceElevated,
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
    return Scaffold(
      backgroundColor: SBColors.bg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildStoreBrandingSection(),
                    const SizedBox(height: 20),
                    _buildVendorIdentityTip(),
                    const SizedBox(height: 28),
                    _buildTextField(
                      label: 'SHOP NAME',
                      hint: 'e.g. Amber & Spice Atelier',
                      maxLines: 1,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'DESCRIPTION',
                      hint:
                          'Describe the atmosphere, cuisine style,\nand unique offerings...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    _buildOpenDaysSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    const SizedBox(height: 12),
                    _buildTermsText(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: SBColors.bg,
          border: Border(
            bottom: BorderSide(color: SBColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SBColors.saffronDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SBColors.saffron.withOpacity(0.4)),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: SBColors.saffron,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Zteel Vendor SignUp',
              style: TextStyle(
                color: SBColors.saffron,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SBColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SBColors.border),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: SBColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        children: [
          const Text(
            'Setup Your Shop',
            style: TextStyle(
              color: SBColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Tell us about your culinary space. These details will be\nvisible to your customers.',
            style: TextStyle(
              color: SBColors.textSecondary,
              fontSize: 13.5,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Store Branding ──────────────────────────────────────────────
  Widget _buildStoreBrandingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('STORE BRANDING'),
          const SizedBox(height: 12),
          // Banner
          _buildBannerPicker(),
        ],
      ),
    );
  }

  Widget _buildBannerPicker() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner container
        GestureDetector(
          onTap: () {},
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: SBColors.saffron.withOpacity(0.35),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3D1F05),
                  Color(0xFF2A1203),
                  Color(0xFF1E0E02),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Subtle pattern overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(painter: _GridPatternPainter()),
                  ),
                ),
                // Center content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SBColors.saffron.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SBColors.saffron.withOpacity(0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          color: SBColors.saffronLight,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Banner Image',
                        style: TextStyle(
                          color: SBColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Logo avatar
        Positioned(
          bottom: -18,
          left: 16,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SBColors.surfaceElevated,
                border: Border.all(color: SBColors.saffron, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: SBColors.saffron.withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: SBColors.saffron,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Vendor Identity Tip ─────────────────────────────────────────
  Widget _buildVendorIdentityTip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SBColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SBColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SBColors.saffronDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: SBColors.saffron,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vendor Identity',
                    style: TextStyle(
                      color: SBColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A high-quality banner and clear logo increase customer trust by up to 40% in premium listings.',
                    style: TextStyle(
                      color: SBColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Text Fields ─────────────────────────────────────────────────
  Widget _buildTextField({
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(label),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: SBColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SBColors.border),
            ),
            child: TextField(
              maxLines: maxLines,
              style: const TextStyle(
                color: SBColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
              cursorColor: SBColors.saffron,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: SBColors.textMuted.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenDaysSection() {
    final validation = _sessionValidationMessage(_selectedDayIndex);
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const fullDayLabels = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SBColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SBColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _sectionLabel('OPEN DAYS & HOURS'),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a day and configure one or more opening sessions.',
              style: TextStyle(
                color: SBColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
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
                        height: 60,
                        decoration: BoxDecoration(
                          color: SBColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFocusedDay
                                ? SBColors.saffron
                                : (hasSessions
                                    ? SBColors.saffron.withOpacity(0.45)
                                    : SBColors.border),
                            width: isFocusedDay ? 1.4 : 1,
                          ),
                          boxShadow: isFocusedDay
                              ? [
                                  BoxShadow(
                                    color: SBColors.saffron.withOpacity(0.14),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayLabels[i],
                              style: TextStyle(
                                color: hasSessions
                                    ? SBColors.saffron
                                    : SBColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fullDayLabels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasSessions
                                    ? SBColors.saffronLight
                                    : SBColors.textMuted,
                                fontSize: 8.5,
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _addSession(_selectedDayIndex),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SBColors.saffron.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: SBColors.saffron.withOpacity(0.45)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          color: SBColors.saffron, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Add Session',
                        style: TextStyle(
                          color: SBColors.saffron,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_fullDayLabel(_selectedDayIndex)} timings',
              style: TextStyle(
                color: SBColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            if (_daySessions[_selectedDayIndex].isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: SBColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SBColors.border),
                ),
                child: const Text(
                  'This day is closed. Add a session to open this day.',
                  style: TextStyle(
                    color: SBColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              )
            else
              ..._daySessions[_selectedDayIndex].asMap().entries.map((entry) {
                final idx = entry.key;
                final session = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: idx == _daySessions[_selectedDayIndex].length - 1
                          ? 0
                          : 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _timeField(
                          'OPEN',
                          session.start,
                          () => _pickSessionTime(_selectedDayIndex, idx, true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _timeField(
                          'CLOSE',
                          session.end,
                          () => _pickSessionTime(_selectedDayIndex, idx, false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeSession(_selectedDayIndex, idx),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: SBColors.saffron.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: SBColors.saffron.withOpacity(0.35)),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: SBColors.saffron,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (validation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  validation,
                  style: TextStyle(
                    color: SBColors.saffronLight,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timeField(String label, TimeOfDay time, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SBColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: SBColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SBColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  label.contains('OPEN')
                      ? Icons.schedule_rounded
                      : Icons.nightlight_round,
                  color: SBColors.saffron,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    color: SBColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Location Section ────────────────────────────────────────────
  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: SBColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SBColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Text(
                'LOCATION',
                style: TextStyle(
                  color: SBColors.saffron,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Map area
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(painter: _MapPainter()),
              ),
            ),
            // Location buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Row(
                  children: [
                    _locationBtn(
                      icon: Icons.my_location_rounded,
                      label: 'Use Current',
                      filled: true,
                    ),
                    const SizedBox(width: 10),
                    _locationBtn(
                      icon: Icons.map_outlined,
                      label: 'Pick Location',
                      filled: false,
                    ),
                  ],
                ),
              ),
            ),
            // Address
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: SBColors.saffron,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '12–14 Saffron Mews, Kensington',
                        style: TextStyle(
                          color: SBColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'LONDON, UNITED KINGDOM',
                        style: TextStyle(
                          color: SBColors.textSecondary,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationBtn({
    required IconData icon,
    required String label,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? SBColors.saffron : SBColors.surfaceElevated,
          borderRadius: BorderRadius.circular(22),
          border: filled ? null : Border.all(color: SBColors.borderAccent),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: SBColors.saffron.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: filled ? Colors.white : SBColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : SBColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Save Button ─────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VendorHome()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [SBColors.saffronLight, SBColors.saffron],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: SBColors.saffron.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Save & Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        "By continuing, you agree to Saffron Bistro's Vendor Terms and Conditions.",
        style: TextStyle(
          color: SBColors.textMuted,
          fontSize: 11.5,
          height: 1.5,
        ),
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
      decoration: BoxDecoration(
        color: SBColors.surface,
        border: Border(
          top: BorderSide(color: SBColors.border, width: 0.5),
        ),
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
                        color: active ? SBColors.saffron : SBColors.textMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          color: active ? SBColors.saffron : SBColors.textMuted,
                          fontSize: 9.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 0.5,
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
        color: SBColors.saffron,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Custom Painters ─────────────────────────────────────────────────────────

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFC87A)
      ..strokeWidth = 0.5;

    const step = 22.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark map background
    final bgPaint = Paint()..color = SBColors.mapDark;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines (map grid)
    final gridPaint = Paint()
      ..color = const Color(0x20F5E6D3)
      ..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Fake continent blobs
    final landPaint = Paint()..color = const Color(0xFF3A1E0A);
    _drawContinent(
        canvas, landPaint, size.width * 0.08, size.height * 0.2, 55, 55);
    _drawContinent(
        canvas, landPaint, size.width * 0.35, size.height * 0.25, 45, 60);
    _drawContinent(
        canvas, landPaint, size.width * 0.55, size.height * 0.3, 80, 55);

    // Location pins
    _drawPin(canvas, Offset(size.width * 0.45, size.height * 0.3));
    _drawPin(canvas, Offset(size.width * 0.72, size.height * 0.5));
    _drawPin(canvas, Offset(size.width * 0.85, size.height * 0.68));

    // Meridian line
    final meridianPaint = Paint()
      ..color = const Color(0x339A7A5F)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.55, size.height),
      meridianPaint,
    );
  }

  void _drawContinent(
      Canvas canvas, Paint paint, double x, double y, double w, double h) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, paint);
  }

  void _drawPin(Canvas canvas, Offset center) {
    final glowPaint = Paint()
      ..color = const Color(0x33E8622A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, 10, glowPaint);

    final outerPaint = Paint()..color = const Color(0xFFE8622A);
    canvas.drawCircle(center, 6, outerPaint);

    final innerPaint = Paint()..color = Colors.white;
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
