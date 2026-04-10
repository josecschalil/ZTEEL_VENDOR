import 'package:flutter/material.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  int _selectedNav = 2;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const Color orange = Color(0xFFE8622A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9E7E72);

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen blurred restaurant background ──
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.55),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF2A1205),
              ),
            ),
          ),

          // ── Dark overlay outside scanner box ──
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                scanBoxSize: 260,
                centerY: size.height * 0.42,
              ),
            ),
          ),

          // ── SafeArea content ──
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),

                // Scanner area (expands to fill)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Scanner frame + animated scan line
                      _buildScannerFrame(),
                    ],
                  ),
                ),

                // Instructions + controls
                _buildBottomContent(),

                // Nav bar
                _buildBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.arrow_back, color: orange, size: 26),
          ),
          const SizedBox(width: 14),
          const Text(
            'Zteel Scanner',
            style: TextStyle(
              color: textWhite,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_outlined, color: orange, size: 26),
        ],
      ),
    );
  }

  // ── Animated Scanner Frame ───────────────────────────────────
  Widget _buildScannerFrame() {
    const double boxSize = 260;
    const double cornerLen = 28;
    const double cornerThick = 4;
    const double cornerRadius = 10;

    return ScaleTransition(
      scale: _pulseAnim,
      child: SizedBox(
        width: boxSize,
        height: boxSize,
        child: Stack(
          children: [
            // Camera preview placeholder (blurred bg shows through)
            ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: Container(
                width: boxSize,
                height: boxSize,
                color: Colors.transparent,
              ),
            ),

            // Animated scan line
            AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (_, __) {
                final top = 12 + _scanLineAnim.value * (boxSize - 24);
                return Positioned(
                  top: top,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          orange.withOpacity(0),
                          orange.withOpacity(0.9),
                          orange.withOpacity(0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: orange.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Corner brackets — Top Left
            _corner(
                top: 0,
                left: 0,
                tl: true,
                cornerLen: cornerLen,
                thick: cornerThick,
                r: cornerRadius),
            // Top Right
            _corner(
                top: 0,
                right: 0,
                tr: true,
                cornerLen: cornerLen,
                thick: cornerThick,
                r: cornerRadius),
            // Bottom Left
            _corner(
                bottom: 0,
                left: 0,
                bl: true,
                cornerLen: cornerLen,
                thick: cornerThick,
                r: cornerRadius),
            // Bottom Right
            _corner(
                bottom: 0,
                right: 0,
                br: true,
                cornerLen: cornerLen,
                thick: cornerThick,
                r: cornerRadius),
          ],
        ),
      ),
    );
  }

  Widget _corner({
    double? top,
    double? left,
    double? right,
    double? bottom,
    bool tl = false,
    bool tr = false,
    bool bl = false,
    bool br = false,
    required double cornerLen,
    required double thick,
    required double r,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: CustomPaint(
        size: Size(cornerLen + thick, cornerLen + thick),
        painter: _CornerPainter(
          tl: tl,
          tr: tr,
          bl: bl,
          br: br,
          color: orange,
          strokeWidth: thick,
          radius: r,
        ),
      ),
    );
  }

  // ── Bottom Instructions + Controls ───────────────────────────
  Widget _buildBottomContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          const Text(
            'Scan QR to complete order',
            style: TextStyle(
              color: textWhite,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Position the QR code within the frame to scan\nautomatically',
            style: TextStyle(
              color: textGrey,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Torch + Gallery buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconButton(Icons.flashlight_on_outlined),
              const SizedBox(width: 20),
              _iconButton(Icons.image_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: textWhite, size: 26),
      ),
    );
  }

  // ── Bottom Navigation ────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.grid_view_rounded, 'label': 'DASHBOARD'},
      {'icon': Icons.local_offer_outlined, 'label': 'OFFERS'},
      {'icon': Icons.list_alt_rounded, 'label': 'ORDERS'},
      {'icon': Icons.person_outline_rounded, 'label': 'PROFILE'},
    ];

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF150C08).withOpacity(0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFF2A1810), width: 1),
        ),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = _selectedNav == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedNav = i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    items[i]['icon'] as IconData,
                    color: selected ? orange : textGrey,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i]['label'] as String,
                    style: TextStyle(
                      color: selected ? orange : textGrey,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Dark overlay with transparent scanner cutout ─────────────
class _ScannerOverlayPainter extends CustomPainter {
  final double scanBoxSize;
  final double centerY;

  _ScannerOverlayPainter({required this.scanBoxSize, required this.centerY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.52);
    final cx = size.width / 2;
    final left = cx - scanBoxSize / 2;
    final top = centerY - scanBoxSize / 2;
    const radius = Radius.circular(14);

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final holeRect = RRect.fromLTRBR(
        left, top, left + scanBoxSize, top + scanBoxSize, radius);

    final path = Path()
      ..addRect(fullRect)
      ..addRRect(holeRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) =>
      old.scanBoxSize != scanBoxSize || old.centerY != centerY;
}

// ── Corner bracket painter ───────────────────────────────────
class _CornerPainter extends CustomPainter {
  final bool tl, tr, bl, br;
  final Color color;
  final double strokeWidth;
  final double radius;

  const _CornerPainter({
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = radius;
    final s = strokeWidth / 2;

    final path = Path();

    if (tl) {
      path.moveTo(s, h - s);
      path.lineTo(s, r + s);
      path.arcToPoint(Offset(r + s, s),
          radius: Radius.circular(r), clockwise: true);
      path.lineTo(w - s, s);
    } else if (tr) {
      path.moveTo(s, s);
      path.lineTo(w - r - s, s);
      path.arcToPoint(Offset(w - s, r + s),
          radius: Radius.circular(r), clockwise: true);
      path.lineTo(w - s, h - s);
    } else if (bl) {
      path.moveTo(w - s, h - s);
      path.lineTo(r + s, h - s);
      path.arcToPoint(Offset(s, h - r - s),
          radius: Radius.circular(r), clockwise: true);
      path.lineTo(s, s);
    } else if (br) {
      path.moveTo(s, h - s);
      path.lineTo(w - s, h - s);
      path.lineTo(w - s, s);
      // Redraw as correct br corner:
      final p2 = Path();
      p2.moveTo(s, h - s);
      p2.lineTo(w - r - s, h - s);
      p2.arcToPoint(Offset(w - s, h - r - s),
          radius: Radius.circular(r), clockwise: false);
      p2.lineTo(w - s, s);
      canvas.drawPath(p2, paint);
      return;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
