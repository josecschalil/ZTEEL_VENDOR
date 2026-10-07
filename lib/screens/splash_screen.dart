import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgDeep = Color(0xFF0F172A);
  static const Color _bgSpotlight = Color(0xFF1E293B);
  static const Color _trackColor = Color(0x1FFFFFFF); // white @ 12%
  static const Color _titleColor = Color(0xB3FFFFFF); // white @ 70%

  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Logo: gentle fade and settle into place.
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Title appears just after the logo.
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
    );

    // Slim progress line fills across the whole duration.
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 1.0, curve: Curves.easeInOut),
    );

    _run();
  }

  Future<void> _run() async {
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 0.9,
            colors: [_bgSpotlight, _bgDeep],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Centered brand block
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 140,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: const Text(
                        'Vendor Portal',
                        style: TextStyle(
                          color: _titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom progress line
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 56),
                  child: SizedBox(
                    width: 120,
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _progress.value,
                            minHeight: 3,
                            backgroundColor: _trackColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.orangeWarm,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
