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
  int _currentStep = 0;

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

  Future<void> _showOperationsStep() async {
    setState(() => _currentStep = 1);
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _completeSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VendorHome()),
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
        Expanded(
          child: Text(
            'SHOP SETUP',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${_currentStep + 1}/2',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
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
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildTextField(
            label: 'Shop name',
            hint: 'e.g. Amber & Spice Atelier',
            controller: _nameController,
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
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

  // ─── Vendor Identity Tip ─────────────────────────────────────────
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
              'You can edit these details anytime.',
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

  Widget _buildVisualIdentitySection() {
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
            ),
            child: Stack(
              children: [
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
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
                    label: const Text('Cover photo'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textWhite,
                      backgroundColor: Colors.black.withOpacity(0.20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.22)),
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
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.orange,
                        size: 34,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: AppColors.orange,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () {},
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: AppColors.textWhite,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                const Padding(
                  padding: EdgeInsets.only(top: 27),
                  child: Text(
                    'Add profile photo',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

  Widget _buildShopIdentityMarker() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.storefront_outlined,
            color: AppColors.textWhite,
            size: 23,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Start with the details your customers will see first.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines == 1 ? 1 : 4,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
          cursorColor: AppColors.orange,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
            contentPadding: const EdgeInsets.only(bottom: 13, top: 6),
            filled: false,
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
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
        const SizedBox(height: 14),
        // Day selector row
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('LOCATION'),
            GestureDetector(
              onTap: () {},
              child: const Text('Edit address',
                  style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 96,
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
          child: Row(
            children: [
              // Small map square on the left
              SizedBox(
                width: 96,
                height: 96,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(18)),
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
    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed:
                  _currentStep == 0 ? _showOperationsStep : _completeSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.textWhite,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
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
          ),
        ],
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

  // ─── Bottom Nav ───────────────────────────────────────────────────
  // ─── Helpers ─────────────────────────────────────────────────────
  Widget _buildTermsText() {
    return const Center(
      child: Text(
        "By continuing, you agree to Saffron Bistro's Vendor Terms and Conditions.",
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

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
