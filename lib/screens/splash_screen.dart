import 'PhoneAuthScreen.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';

// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Logo entrance
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoFadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    // Loading bar – 3 seconds
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Fade-out before navigation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Sequence: logo in → progress bar → fade out → navigate
    _logoController.forward().then((_) {
      _progressController.forward().then((_) {
        _fadeController.forward().then((_) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RestaurantDashboard()),
            );
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0E05),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Tiled QR-code watermark background ──
            const _WatermarkBackground(),

            // ── Radial glow in center-lower area ──
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE87722).withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content ──
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Logo icon
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: const _AppIcon(),
                  ),
                ),

                const SizedBox(height: 28),

                // Brand name
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: const _BrandName(),
                ),

                const Spacer(flex: 4),

                // Tagline
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: const _Tagline(),
                ),

                const SizedBox(height: 20),

                // Progress indicator (two-segment bar)
                _ProgressBar(progressController: _progressController),

                const SizedBox(height: 28),

                // Offline redemption badge
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: const _OfflineBadge(),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WATERMARK BACKGROUND
// ─────────────────────────────────────────────
class _WatermarkBackground extends StatelessWidget {
  const _WatermarkBackground();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.07,
      child: CustomPaint(
        painter: _WatermarkPainter(),
      ),
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE87722)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Draw scattered QR-like squares in a grid
    const cellSize = 80.0;
    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * cellSize - 10;
        final y = r * cellSize - 10;
        _drawMiniQR(canvas, paint, Offset(x, y), 50);
      }
    }
  }

  void _drawMiniQR(Canvas canvas, Paint paint, Offset origin, double size) {
    // Outer border
    canvas.drawRect(Rect.fromLTWH(origin.dx, origin.dy, size, size), paint);
    // Corner squares
    final cs = size * 0.28;
    canvas.drawRect(Rect.fromLTWH(origin.dx + 4, origin.dy + 4, cs, cs), paint);
    canvas.drawRect(
        Rect.fromLTWH(origin.dx + size - cs - 4, origin.dy + 4, cs, cs), paint);
    canvas.drawRect(
        Rect.fromLTWH(origin.dx + 4, origin.dy + size - cs - 4, cs, cs), paint);
    // Center dots
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(origin.dx + size * 0.4, origin.dy + size * 0.4,
            size * 0.2, size * 0.2),
        dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  APP ICON
// ─────────────────────────────────────────────
class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFE87722),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE87722).withOpacity(0.45),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Center(
        child: _QRIcon(size: 64),
      ),
    );
  }
}

/// Simple hand-drawn QR icon in white
class _QRIcon extends StatelessWidget {
  final double size;
  const _QRIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _QRIconPainter(),
    );
  }
}

class _QRIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final s = size.width;
    final u = s / 7; // unit

    // Top-left corner block
    _drawCorner(canvas, paint, 0, 0, u);
    // Top-right corner block
    _drawCorner(canvas, paint, 4 * u, 0, u);
    // Bottom-left corner block
    _drawCorner(canvas, paint, 0, 4 * u, u);

    // Random data dots in bottom-right quadrant
    final dots = [
      Offset(4 * u, 4 * u),
      Offset(5 * u, 4 * u),
      Offset(4 * u, 5 * u),
      Offset(6 * u, 5 * u),
      Offset(5 * u, 6 * u),
      Offset(6 * u, 6 * u),
      // center scatter
      Offset(3 * u, 2 * u),
      Offset(2 * u, 3 * u),
      Offset(3 * u, 3 * u),
    ];
    for (final d in dots) {
      canvas.drawRect(Rect.fromLTWH(d.dx + 1, d.dy + 1, u - 2, u - 2), paint);
    }
  }

  void _drawCorner(Canvas canvas, Paint paint, double x, double y, double u) {
    // Outer 3×3 frame
    final outer = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.5;
    canvas.drawRect(
        Rect.fromLTWH(x + u * 0.25, y + u * 0.25, u * 2.5, u * 2.5), outer);
    // Inner fill dot
    canvas.drawRect(
        Rect.fromLTWH(x + u * 0.9, y + u * 0.9, u * 1.2, u * 1.2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  BRAND NAME
// ─────────────────────────────────────────────
class _BrandName extends StatelessWidget {
  const _BrandName();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'Z',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          TextSpan(
            text: 'tee',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Color(0xFFE87722),
              letterSpacing: 1,
            ),
          ),
          TextSpan(
            text: 'e',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Color(0xFFE87722),
              letterSpacing: 1,
            ),
          ),
          TextSpan(
            text: 'l',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TAGLINE
// ─────────────────────────────────────────────
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Discover the best food deals',
          style: TextStyle(
            color: Color(0xFFCCCCCC),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
        Text(
          'near you',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AnimationController progressController;
  const _ProgressBar({required this.progressController});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = screenWidth * 0.58;
    const barHeight = 3.5;

    return AnimatedBuilder(
      animation: progressController,
      builder: (_, __) {
        final progress = progressController.value;

        return SizedBox(
          width: barWidth,
          height: barHeight,
          child: Stack(
            children: [
              // Track
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(barHeight),
                ),
              ),
              // FULL ORANGE PROGRESS
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE87722),
                    borderRadius: BorderRadius.circular(barHeight),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  OFFLINE BADGE
// ─────────────────────────────────────────────
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE87722), width: 1.5),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFFE87722), size: 18),
          SizedBox(width: 10),
          Text(
            'INSTANT OFFLINE REDEMPTION',
            style: TextStyle(
              color: Color(0xFFE87722),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
