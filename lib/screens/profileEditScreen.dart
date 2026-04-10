import 'package:flutter/material.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final List<bool> _openDays = [true, true, true, true, true, true, true];

  // ── Design tokens ──────────────────────────────────────────
  static const Color bgDark = Color(0xFF1A0F08);
  static const Color cardBg = Color(0xFF2A1A0E);
  static const Color fieldBg = Color(0xFF231409);
  static const Color accent = Color(0xFFD4622A);
  static const Color accentLight = Color(0xFFE8763C);
  static const Color textPrimary = Color(0xFFF5E6D3);
  static const Color textSecond = Color(0xFF9A7B60);
  static const Color divider = Color(0xFF3D2515);

  String _dayLabel(int index) => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      bottomNavigationBar: const VendorBottomNav(currentTab: VendorTab.profile),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('OPENING TIME'),
                              const SizedBox(height: 6),
                              _buildTimeField(
                                  '11:00 AM', Icons.access_time_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CLOSING TIME'),
                              const SizedBox(height: 6),
                              _buildTimeField(
                                  '10:00 PM', Icons.bedtime_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildOpenDaysSection(),
                    const SizedBox(height: 20),
                    _buildMenuShowcase(),
                    const SizedBox(height: 28),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildLabel('ACCOUNT & PREFERENCES'),
                    const SizedBox(height: 14),
                    _buildPreferenceItem(
                      Icons.account_balance_wallet_outlined,
                      'Payout Settings',
                      'Manage bank account & taxes',
                    ),
                    const SizedBox(height: 12),
                    _buildPreferenceItem(
                      Icons.shield_outlined,
                      'Privacy & Security',
                      '2FA, Password & Permissions',
                    ),
                    const SizedBox(height: 28),
                    _buildSaveButton(),
                    const SizedBox(height: 12),
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
              colors: [Color(0xFF4A2010), Color(0xFF6B3020), Color(0xFF3A1808)],
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
                  color: const Color(0xFF3A1A08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bgDark, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    color: const Color(0xFF2A1005),
                    child: const Center(
                      child: Icon(Icons.person,
                          color: Color(0xFF6A4030), size: 40),
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
              final selected = _openDays[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _openDays[i] = !_openDays[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 58,
                      decoration: BoxDecoration(
                        color: selected ? accent : const Color(0xFF1E1008),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? accent : divider,
                          width: 1,
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
                              color: selected ? Colors.white : textSecond,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fullDayLabels[i],
                            style: TextStyle(
                              color: selected ? Colors.white : textSecond,
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
        ],
      ),
    );
  }

  // ── Map placeholder ────────────────────────────────────────
  Widget _buildMapPlaceholder() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1008),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF3A1A08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textSecond,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: textSecond, size: 20),
        ],
      ),
    );
  }

  // ── Save button ────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'SAVE ALL CHANGES',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // ── Logout button ──────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: const Icon(Icons.logout, size: 16, color: textPrimary),
        label: const Text(
          'LOGOUT FROM VENDOR PANEL',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
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
