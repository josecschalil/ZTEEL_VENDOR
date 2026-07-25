import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'PhoneAuthScreen.dart';
import 'package:frontend/app_colors.dart';

// ─────────────────────────────────────────────
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

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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
      _progressAc.forward().then((_) {
        if (mounted) {
          // Add a subtle fade transition to the next screen
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (_, __, ___) => const LoginScreen(),
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
        backgroundColor: AppColors.orange,
        body: Stack(
          children: [
            // Decorative background patterns (e.g., large faint circles)
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textInverse.withOpacity(0.03),
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
                  color: AppColors.textInverse.withOpacity(0.03),
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
                          color: AppColors.textInverse,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            )
                          ],
                        ),
                        child: const _QRIcon(size: 64, color: AppColors.orange),
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
                                color: AppColors.textInverse,
                              ),
                              children: [
                                TextSpan(text: 'Z'),
                                TextSpan(
                                    text: 'tee',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                                TextSpan(
                                    text: 'el',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w300)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'VENDOR PARTNER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4.0,
                              color: AppColors.textInverse.withOpacity(0.8),
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
                        color: AppColors.textInverse.withOpacity(0.6),
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
                  color: AppColors.textInverse.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(barHeight),
                ),
              ),
              // FULL PROGRESS
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.textInverse,
                    borderRadius: BorderRadius.circular(barHeight),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textInverse.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
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