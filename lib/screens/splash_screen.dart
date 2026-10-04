import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'PhoneAuthScreen.dart';
import 'package:frontend/screens/setupShopScreen.dart';
import 'package:frontend/screens/vendor_home.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/vendor_service.dart';

// ─── Design tokens (slate scale only) ────────────────────────────────────────
class _K {
  static const bg = Color(0xFF0F172A); // slate-900
  static const bgGlow = Color(0xFF16213A);
  static const bgDeep = Color(0xFF080E1C);
  static const s700 = Color(0xFF334155);
  static const s500 = Color(0xFF64748B);
  static const s400 = Color(0xFF94A3B8);
  static const s300 = Color(0xFFCBD5E1);
  static const s200 = Color(0xFFE2E8F0);
  static const s50 = Color(0xFFF8FAFC);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _progress;

  late final Animation<double> _grid;
  late final Animation<double> _tagline;
  late final Animation<double> _foot;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _grid = CurvedAnimation(
        parent: _intro, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _tagline = CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.62, 0.92, curve: Curves.easeOutCubic));
    _foot = CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut));

    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _intro.forward().then((_) {
      _progress.forward().then((_) => _navigate());
    });
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final loggedIn = await AuthService.isLoggedIn();

    Widget targetScreen;
    if (loggedIn) {
      final hasShop = await VendorService.hasExistingShopData();
      targetScreen = hasShop ? const VendorHome() : const SetupShopScreen();
    } else {
      targetScreen = const LoginScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => targetScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _progress.dispose();
    super.dispose();
  }

  String _statusFor(double p) {
    if (p < 0.34) return 'Checking your session';
    if (p < 0.70) return 'Loading shop details';
    return 'Preparing your dashboard';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _K.bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background: vignette + dot grid fading away from the centre
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.05),
                  radius: 1.15,
                  colors: [_K.bgGlow, _K.bg, _K.bgDeep],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            FadeTransition(
              opacity: _grid,
              child: const CustomPaint(painter: _DotGridPainter()),
            ),

            SafeArea(
              child: Stack(
                children: [
                  // Brand lockup (wordmark only — no logo mark yet)
                  Align(
                    alignment: const Alignment(0, -0.05),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Wordmark(animation: _intro),
                        const SizedBox(height: 22),
                        FadeTransition(
                          opacity: _tagline,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.4),
                              end: Offset.zero,
                            ).animate(_tagline),
                            child: const _Tagline(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer: progress + status
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 44,
                    child: FadeTransition(
                      opacity: _foot,
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (_, __) => Column(
                          children: [
                            _ProgressLine(value: _progress.value),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                _statusFor(_progress.value),
                                key: ValueKey(_statusFor(_progress.value)),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                  color: _K.s500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

// ─────────────────────────────────────────────
//  WORDMARK — letters rise in one after another
// ─────────────────────────────────────────────
class _Wordmark extends StatelessWidget {
  final Animation<double> animation;
  const _Wordmark({required this.animation});

  static const _letters = ['Z', 'T', 'E', 'E', 'L'];

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_K.s50, _K.s300],
      ).createShader(r),
      blendMode: BlendMode.srcIn,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_letters.length, (i) {
              // Each letter owns a slice of 15%–75% of the intro timeline
              final start = 0.15 + i * 0.09;
              final local = ((animation.value - start) / 0.28).clamp(0.0, 1.0);
              final k = Curves.easeOutCubic.transform(local);

              return Opacity(
                opacity: k,
                child: Transform.translate(
                  offset: Offset(0, (1 - k) * 14),
                  child: Padding(
                    // letter-spacing handled by padding so the word stays
                    // perfectly centred (no trailing gap after the last letter)
                    padding: EdgeInsets.only(
                        right: i == _letters.length - 1 ? 0 : 14),
                    child: Text(
                      _letters[i],
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 28, height: 1, color: _K.s700),
        const SizedBox(width: 12),
        const Text(
          'Vendor',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: _K.s400,
          ),
        ),
        const SizedBox(width: 12),
        Container(width: 28, height: 1, color: _K.s700),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  DOT GRID (alpha falls off with distance)
// ─────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 28.0;
    final centre = Offset(size.width / 2, size.height * 0.47);
    final maxD = size.shortestSide * 0.95;
    final paint = Paint();

    for (double y = step / 2; y < size.height; y += step) {
      for (double x = step / 2; x < size.width; x += step) {
        final d = (Offset(x, y) - centre).distance;
        final a = (1 - d / maxD).clamp(0.0, 1.0);
        if (a <= 0) continue;
        paint.color = _K.s400.withOpacity(0.16 * a * a);
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
//  PROGRESS LINE
// ─────────────────────────────────────────────
class _ProgressLine extends StatelessWidget {
  final double value;
  const _ProgressLine({required this.value});

  @override
  Widget build(BuildContext context) {
    const h = 2.0;
    return SizedBox(
      width: 148,
      height: h,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _K.s700.withOpacity(0.55),
              borderRadius: BorderRadius.circular(h),
            ),
          ),
          FractionallySizedBox(
            widthFactor: Curves.easeInOut.transform(value),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_K.s500, _K.s200]),
                borderRadius: BorderRadius.circular(h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
