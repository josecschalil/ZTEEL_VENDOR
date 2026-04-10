import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/setupShopScreen.dart';

// ── Tokens (same as login) ─────────────────────
const _bg = Color(0xFF16100A);
const _orange = Color(0xFFE87722);
const _orangeDim = Color(0xFF7A3D10);
const _white = Color(0xFFF5F0EB);
const _grey1 = Color(0xFF9E9080);
const _grey2 = Color(0xFF3A2E26);
const _navy = Color(0xFF0F1C30);

// ── OTP Screen ────────────────────────────────
class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _ctrl =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _fn = List.generate(4, (_) => FocusNode());

  // which box is active
  int _active = 0;

  // shake animation for wrong code
  late final AnimationController _shakeAc = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 480));
  late final Animation<double> _shakeAnim = Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(parent: _shakeAc, curve: Curves.elasticIn));

  // entry stagger
  late final AnimationController _entryAc = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  Animation<double> _fade(int i) => CurvedAnimation(
      parent: _entryAc,
      curve: Interval(i * .11, .55 + i * .09, curve: Curves.easeOut));
  Animation<Offset> _slide(int i) => Tween<Offset>(
          begin: const Offset(0, .07), end: Offset.zero)
      .animate(CurvedAnimation(
          parent: _entryAc,
          curve: Interval(i * .11, .55 + i * .09, curve: Curves.easeOutCubic)));

  Widget _reveal(int i, Widget child) => FadeTransition(
      opacity: _fade(i),
      child: SlideTransition(position: _slide(i), child: child));

  // resend countdown
  int _countdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _entryAc.forward();
    _fn[0].requestFocus();
    for (int i = 0; i < 4; i++) {
      _fn[i].addListener(() {
        if (_fn[i].hasFocus) setState(() => _active = i);
      });
    }
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 30;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _countdown--;
        if (_countdown <= 0) _canResend = true;
      });
      return _countdown > 0;
    });
  }

  @override
  void dispose() {
    _shakeAc.dispose();
    _entryAc.dispose();
    for (final c in _ctrl) c.dispose();
    for (final f in _fn) f.dispose();
    super.dispose();
  }

  String get _code => _ctrl.map((c) => c.text).join();
  bool get _filled => _code.length == 4;

  void _onKey(String val, int i) {
    if (val.length == 1) {
      if (i < 3) {
        _fn[i + 1].requestFocus();
      } else {
        _fn[i].unfocus();
      }
    } else if (val.isEmpty && i > 0) {
      _fn[i - 1].requestFocus();
    }
    setState(() {});
  }

  void _verify() {
    if (!_filled) return;
    // Simulate wrong code → shake
    if (_code != '1234') {
      _shakeAc.forward(from: 0);
      for (final c in _ctrl) c.clear();
      _fn[0].requestFocus();
      setState(() {});
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SetupShopScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top bar ────────────────────────
                        _reveal(
                          0,
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                            child: Row(
                              children: [
                                // Back button
                                GestureDetector(
                                  onTap: () => Navigator.maybePop(context),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: _grey2, width: 1.2),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(Icons.arrow_back_ios_new,
                                        color: _grey1, size: 15),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Wordmark
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .4),
                                    children: [
                                      TextSpan(
                                          text: 'Z',
                                          style: TextStyle(color: _white)),
                                      TextSpan(
                                          text: 'tee',
                                          style: TextStyle(color: _orange)),
                                      TextSpan(
                                          text: 'el',
                                          style: TextStyle(
                                              color: _white,
                                              fontWeight: FontWeight.w300)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Heading ────────────────────────
                        _reveal(
                          1,
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 52, 28, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: _orangeDim, width: 1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'VERIFICATION',
                                    style: TextStyle(
                                      color: _orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Enter the\ncode',
                                  style: TextStyle(
                                    color: _white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w800,
                                    height: 1.08,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        color: _grey1,
                                        fontSize: 15,
                                        height: 1.65),
                                    children: [
                                      const TextSpan(
                                          text: 'A 4-digit OTP was sent to\n'),
                                      TextSpan(
                                        text: widget.phone,
                                        style: const TextStyle(
                                          color: _white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Accent line ────────────────────
                        _reveal(
                          2,
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 40, 0, 0),
                            child: Row(
                              children: [
                                Container(width: 28, height: 2, color: _orange),
                                Container(width: 72, height: 2, color: _grey2),
                              ],
                            ),
                          ),
                        ),

                        // ── OTP boxes ──────────────────────
                        _reveal(
                          3,
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 44, 28, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'OTP CODE',
                                  style: TextStyle(
                                    color: _grey1,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // 4 digit boxes with shake
                                AnimatedBuilder(
                                  animation: _shakeAnim,
                                  builder: (_, child) {
                                    final dx = _shakeAnim.value == 0
                                        ? 0.0
                                        : 8.0 *
                                            (0.5 -
                                                (_shakeAnim.value % .15 / .15));
                                    return Transform.translate(
                                      offset: Offset(dx, 0),
                                      child: child,
                                    );
                                  },
                                  child: Row(
                                    children: List.generate(
                                      4,
                                      (i) => Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              right: i < 3 ? 14 : 0),
                                          child: _OtpDigit(
                                            controller: _ctrl[i],
                                            focusNode: _fn[i],
                                            isActive: _active == i,
                                            isFilled: _ctrl[i].text.isNotEmpty,
                                            onChanged: (v) => _onKey(v, i),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Resend row
                                Row(
                                  children: [
                                    Text(
                                      _canResend
                                          ? "Didn't receive it?"
                                          : 'Resend in  ${_countdown}s',
                                      style: const TextStyle(
                                          color: _grey1, fontSize: 13),
                                    ),
                                    if (_canResend) ...[
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => setState(_startCountdown),
                                        child: const Text(
                                          'Resend OTP',
                                          style: TextStyle(
                                            color: _orange,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),

                // ── Sticky footer ──────────────────────
                _reveal(4, _Footer(filled: _filled, onVerify: _verify)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single OTP digit box ───────────────────────
class _OtpDigit extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final bool isFilled;
  final ValueChanged<String> onChanged;

  const _OtpDigit({
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.isFilled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 64,
      decoration: BoxDecoration(
        color: isFilled ? _orange.withOpacity(.10) : _navy.withOpacity(.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? _orange
              : isFilled
                  ? _orangeDim
                  : _grey2,
          width: isActive ? 1.8 : 1.2,
        ),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: TextStyle(
            color: isFilled ? _orange : _white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          cursorColor: _orange,
          cursorWidth: 1.5,
          maxLength: 1,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────
class _Footer extends StatelessWidget {
  final bool filled;
  final VoidCallback onVerify;
  const _Footer({required this.filled, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: Colors.white.withOpacity(.05), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 56,
            child: ElevatedButton(
              onPressed: filled ? onVerify : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: filled ? _orange : _grey2,
                foregroundColor: filled ? Colors.white : _grey1,
                disabledBackgroundColor: _grey2,
                disabledForegroundColor: _grey1,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Verify & Continue',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                  color: _grey1.withOpacity(.75), fontSize: 11.5, height: 1.5),
              children: [
                const TextSpan(text: 'By continuing, you agree to our '),
                TextSpan(
                    text: 'Terms',
                    style: TextStyle(
                        color: _orange.withOpacity(.9),
                        fontWeight: FontWeight.w600)),
                const TextSpan(text: ' and '),
                TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                        color: _orange.withOpacity(.9),
                        fontWeight: FontWeight.w600)),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
