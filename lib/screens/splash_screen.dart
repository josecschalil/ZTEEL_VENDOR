import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'PhoneAuthScreen.dart';
import 'package:frontend/screens/setupShopScreen.dart';
import 'package:frontend/screens/vendor_home.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/app_colors.dart';

// ─── Color tokens (same as profile / orders / categories / rewards screens) ──
class _K {
  static const dark = AppColors.primaryDark;
  static const darkRaised = AppColors.primaryDark;
  static const emerald = AppColors.success;
  static const emeraldLight = AppColors.successLight;
  static const white = AppColors.white;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // We will use a staggered animation approach
  late AnimationController _ac;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  late AnimationController _progressAc;

  @override
  void initState() {
    super.initState();

    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ac,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ac,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ac,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ac,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _progressAc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _ac.forward().then((_) {
      _progressAc.forward().then((_) async {
        if (!mounted) return;
        final loggedIn = await AuthService.isLoggedIn();

        Widget targetScreen;
        if (loggedIn) {
          final hasShop = await VendorService.hasExistingShopData();
          targetScreen = hasShop ? const VendorHome() : const SetupShopScreen();
        } else {
          targetScreen = const LoginScreen();
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (_, __, ___) => targetScreen,
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    _progressAc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _K.dark,
        body: Stack(
          children: [
            // Decorative background patterns (large faint circles)
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _K.white.withOpacity(0.03),
                ),
              ),
            ),
            Positioned(
              bottom: -200,
              left: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _K.white.withOpacity(0.03),
                ),
              ),
            ),
            // Subtle emerald glow accent, echoing the dashboard's "live" motif
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _K.emerald.withOpacity(0.06),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _K.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const _QRIcon(size: 64, color: _K.dark),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Animated Text
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                                color: _K.white,
                              ),
                              children: [
                                TextSpan(text: 'Z'),
                                TextSpan(
                                    text: 'tee',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(
                                    text: 'el',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w300)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Emerald "live" pill — matches dashboard status badges
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _K.emerald.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _K.emerald.withOpacity(0.3)),
                            ),
                            child: Text(
                              'VENDOR PARTNER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3.0,
                                color: _K.emeraldLight,
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

            // Progress indicator at the very bottom
            Positioned(
              bottom: 48,
              left: 48,
              right: 48,
              child: FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    _ProgressBar(progressController: _progressAc),
                    const SizedBox(height: 16),
                    Text(
                      'Setting up your workspace...',
                      style: TextStyle(
                        color: _K.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QR ICON
// ─────────────────────────────────────────────
class _QRIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _QRIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _QRIconPainter(color: color),
    );
  }
}

class _QRIconPainter extends CustomPainter {
  final Color color;
  _QRIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
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
      ..color = paint.color
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
//  PROGRESS BAR
// ─────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final AnimationController progressController;
  const _ProgressBar({required this.progressController});

  @override
  Widget build(BuildContext context) {
    const barHeight = 3.0;

    return AnimatedBuilder(
      animation: progressController,
      builder: (_, __) {
        final progress = progressController.value;

        return SizedBox(
          height: barHeight,
          child: Stack(
            children: [
              // Track
              Container(
                decoration: BoxDecoration(
                  color: _K.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(barHeight),
                ),
              ),

              // Fill — emerald, matching the dashboard's "live" accent
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: _K.emerald,
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
