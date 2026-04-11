import 'package:flutter/material.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final List<List<_OpeningSession>> _daySessions = List.generate(
    7,
    (_) => <_OpeningSession>[],
  );
  int _selectedDayIndex = 0;

  // ── Design tokens ──────────────────────────────────────────
  static const Color bgDark = Color(0xFF130A04);
  static const Color fieldBg = Color(0xFF261509);
  static const Color accent = Color(0xFFE8622A);
  static const Color accentLight = Color(0xFFF07840);
  static const Color textPrimary = Color(0xFFF5E6D3);
  static const Color textSecond = Color(0xFF9A7A5F);
  static const Color divider = Color(0xFF3A1E0A);

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
            primary: accent,
            onSurface: textPrimary,
            surface: fieldBg,
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
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
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
                    const SizedBox(height: 6),
                    _buildTextField(
                        'Saffron Bistro', Icons.storefront_outlined),
                    const SizedBox(height: 16),
                    _buildLabel('DESCRIPTION'),
                    const SizedBox(height: 6),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildLabel('LOCATION / ADDRESS'),
                    const SizedBox(height: 6),
                    _buildTextField('42 Culinary Blvd, Spice District, NY',
                        Icons.location_on_outlined),
                    const SizedBox(height: 10),
                    _buildMapPlaceholder(),
                    const SizedBox(height: 20),
                    _buildOpenDaysSection(),
                    const SizedBox(height: 20),
                    _buildMenuShowcase(),
                    const SizedBox(height: 22),
                    _buildDivider(),
                    const SizedBox(height: 16),
                    _buildLabel('ACCOUNT & PREFERENCES'),
                    const SizedBox(height: 10),
                    _buildPreferenceItem(
                      Icons.account_balance_wallet_outlined,
                      'Payout Settings',
                      'Manage bank account & taxes',
                    ),
                    const SizedBox(height: 10),
                    _buildPreferenceItem(
                      Icons.shield_outlined,
                      'Privacy & Security',
                      '2FA, Password & Permissions',
                    ),
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

  // ── Top bar ────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: divider, width: 1),
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Zteel Vendor Panel',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: divider, width: 1),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: accent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Cover photo ────────────────────────────────────────────
  Widget _buildCoverPhoto() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image placeholder
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D1A05), Color(0xFF6B2E08), Color(0xFF5C2004)],
            ),
          ),
          child: Stack(
            children: [
              // Food items illustration grid
              Positioned.fill(
                child: CustomPaint(painter: _FoodPatternPainter()),
              ),
              // Change cover button
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'CHANGE COVER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Chef avatar
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
                  color: const Color(0xFF261509),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bgDark, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    color: const Color(0xFF1F1108),
                    child: const Center(
                      child: Icon(Icons.person,
                          color: Color(0xFF5C3E28), size: 40),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: bgDark, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 12),
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
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: accent, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'ACTIVE VENDOR',
            style: TextStyle(
              color: accent,
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
        color: textSecond,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Text field ─────────────────────────────────────────────
  Widget _buildTextField(String value, IconData icon) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(icon, color: textSecond, size: 18),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider, width: 1),
      ),
      child: const TextField(
        maxLines: 4,
        style: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        cursorColor: accent,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Write a short description for your shop...',
          hintStyle: TextStyle(
            color: textSecond,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
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
        color: fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider, width: 1),
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
                        color: const Color(0xFF1F1108),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFocusedDay
                              ? accent
                              : (hasSessions
                                  ? accent.withOpacity(0.45)
                                  : divider),
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
                              color: hasSessions ? accent : textSecond,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fullDayLabels[i],
                            style: TextStyle(
                              color: hasSessions ? accentLight : textSecond,
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
                '${_fullDayLabel(_selectedDayIndex)} Sessions',
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _addSession(_selectedDayIndex),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withOpacity(0.45)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 13, color: accent),
                      SizedBox(width: 4),
                      Text(
                        'Add Session',
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_daySessions[_selectedDayIndex].isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1108),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: divider),
              ),
              child: const Text(
                'This day is closed. Add a session to open this day.',
                style: TextStyle(
                  color: textSecond,
                  fontSize: 11,
                ),
              ),
            )
          else ...[
            ..._daySessions[_selectedDayIndex].asMap().entries.map((entry) {
              final idx = entry.key;
              final session = entry.value;
              return Padding(
                padding: EdgeInsets.only(top: idx == 0 ? 0 : 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1108),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: divider),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Session ${idx + 1}',
                        style: const TextStyle(
                          color: textSecond,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _pickSessionTime(_selectedDayIndex, idx, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: divider),
                            ),
                            child: Text(
                              _formatTime(session.start),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '-',
                          style: TextStyle(
                            color: textSecond,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _pickSessionTime(_selectedDayIndex, idx, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: divider),
                            ),
                            child: Text(
                              _formatTime(session.end),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeSession(_selectedDayIndex, idx),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accent.withOpacity(0.35)),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (selectedDayValidation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  selectedDayValidation,
                  style: const TextStyle(
                    color: accentLight,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Map placeholder ────────────────────────────────────────
  Widget _buildMapPlaceholder() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1108),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: CustomPaint(
          painter: _MapGridPainter(),
          child: Container(),
        ),
      ),
    );
  }

  // ── Time field ─────────────────────────────────────────────
  Widget _buildTimeField(String time, IconData icon) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(icon, color: textSecond, size: 18),
        ],
      ),
    );
  }

  // ── Menu showcase ──────────────────────────────────────────
  Widget _buildMenuShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('MENU SHOWCASE'),
            const Text(
              'Add More',
              style: TextStyle(
                color: accentLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: Row(
            children: [
              _buildMenuImage(
                  color1: const Color(0xFF8B6914),
                  color2: const Color(0xFFD4A017),
                  isYellow: true),
              const SizedBox(width: 8),
              _buildMenuImage(
                  color1: const Color(0xFF8B2014),
                  color2: const Color(0xFFD44A20),
                  isPizza: true),
              const SizedBox(width: 8),
              _buildUploadBox(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuImage({
    required Color color1,
    required Color color2,
    bool isYellow = false,
    bool isPizza = false,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
        ),
        child: Center(
          child: Icon(
            isPizza ? Icons.local_pizza_outlined : Icons.rice_bowl_outlined,
            color: Colors.white.withOpacity(0.5),
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadBox() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: divider, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: textSecond, size: 26),
            const SizedBox(height: 4),
            const Text(
              'UPLOAD',
              style: TextStyle(
                color: textSecond,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Divider ────────────────────────────────────────────────
  Widget _buildDivider() {
    return Container(height: 1, color: divider);
  }

  // ── Preference item ────────────────────────────────────────
  Widget _buildPreferenceItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1108),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textSecond,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: textSecond, size: 18),
        ],
      ),
    );
  }

  // ── Save button ────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: const Text(
          'SAVE ALL CHANGES',
          style: TextStyle(
            fontSize: 12,
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
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        icon: const Icon(Icons.logout, size: 14, color: textPrimary),
        label: const Text(
          'LOGOUT FROM VENDOR PANEL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: textPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Custom painters ────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E1A0A)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Road lines (thicker)
    final roadPaint = Paint()
      ..color = const Color(0xFF3A2010)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width * 0.3, 0),
        Offset(size.width * 0.4, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.35), roadPaint);
    canvas.drawLine(Offset(size.width * 0.6, 0),
        Offset(size.width * 0.7, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7),
        Offset(size.width, size.height * 0.65), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FoodPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle warm overlay dots pattern
    final paint = Paint()
      ..color = const Color(0x15FF8040)
      ..style = PaintingStyle.fill;

    for (double x = 20; x < size.width; x += 60) {
      for (double y = 20; y < size.height; y += 60) {
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
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
