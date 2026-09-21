import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/OtpProfileScreen.dart';
import 'package:frontend/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _focused = false;
  bool _isLoading = false;

  late final AnimationController _entryAc = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 950));

  Animation<double> _fade(int i) => CurvedAnimation(
        parent: _entryAc,
        curve: Interval(i * .10, .55 + i * .09, curve: Curves.easeOut),
      );
  Animation<Offset> _slide(int i) =>
      Tween<Offset>(begin: const Offset(0, .07), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _entryAc,
        curve: Interval(i * .10, .55 + i * .09, curve: Curves.easeOutCubic),
      ));

  Widget _reveal(int i, Widget child) => FadeTransition(
      opacity: _fade(i),
      child: SlideTransition(position: _slide(i), child: child));

  @override
  void initState() {
    super.initState();
    _focusNode
        .addListener(() => setState(() => _focused = _focusNode.hasFocus));
    _entryAc.forward();
  }

  @override
  void dispose() {
    _entryAc.dispose();
    _phoneCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    FocusScope.of(context).unfocus();
    final rawInput = _phoneCtrl.text.trim();
    if (rawInput.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter a valid 10-digit mobile number'),
        backgroundColor: const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthService.sendOtp(rawInput);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final formattedPhone = AuthService.formatPhoneNumber(rawInput);
      final devOtp = res['dev_otp'] as String?;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phone: formattedPhone,
            initialOtp: devOtp,
          ),
        ),
      );
    } else {
      final errorMsg = res['error'] ?? 'Failed to send OTP';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMsg),
        backgroundColor: const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top bar ──────────────────────────
                          _reveal(
                            0,
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(Icons.restaurant,
                                        color: Colors.white, size: 19),
                                  ),
                                  const SizedBox(width: 10),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: .4),
                                      children: [
                                        TextSpan(
                                            text: 'Z',
                                            style: TextStyle(
                                                color: Color(0xFF0F172A))),
                                        TextSpan(
                                            text: 'tee',
                                            style: TextStyle(
                                                color: Color(0xFF0F172A))),
                                        TextSpan(
                                            text: 'el',
                                            style: TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.w300)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Hero heading ─────────────────────
                          _reveal(
                            1,
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 56, 28, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pill label
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'FOOD DEALS · NEAR YOU',
                                      style: TextStyle(
                                        color: Color(0xFF334155),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.6,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // Left-aligned editorial heading
                                  const Text(
                                    'Welcome\nto ZTEEEL',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 44,
                                      fontWeight: FontWeight.w800,
                                      height: 1.08,
                                      letterSpacing: -1.5,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  const Text(
                                    'Find the best food deals near you.\nLet\'s get started.',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 15,
                                      height: 1.65,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Accent line ───────────────────────
                          _reveal(
                            2,
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 40, 0, 0),
                              child: Row(
                                children: [
                                  Container(
                                      width: 28,
                                      height: 2,
                                      color: const Color(0xFF0F172A)),
                                  Container(
                                      width: 72,
                                      height: 2,
                                      color: const Color(0xFFE2E8F0)),
                                ],
                              ),
                            ),
                          ),

                          // ── Phone field ───────────────────────
                          _reveal(
                            3,
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 38, 28, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PHONE NUMBER',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // Inline country code + bare field
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '+91',
                                        style: TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                          width: 1,
                                          height: 26,
                                          color: const Color(0xFFE2E8F0)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: _phoneCtrl,
                                          focusNode: _focusNode,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                                10),
                                          ],
                                          onChanged: (_) => setState(() {}),
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 2.5,
                                          ),
                                          cursorColor: const Color(0xFF0F172A),
                                          cursorWidth: 2,
                                          decoration: const InputDecoration(
                                            hintText: '00000 00000',
                                            hintStyle: TextStyle(
                                              color: Color(0xFFE2E8F0),
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 2.5,
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Animated underline
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    height: 1.5,
                                    color: _focused
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Expanded(child: SizedBox(height: 48)),

                          // ── Footer ─────────────────────────
                          _reveal(
                              4,
                              _Footer(
                                  onContinue: _onSendOtp,
                                  isLoading: _isLoading)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────
class _Footer extends StatelessWidget {
  final VoidCallback onContinue;
  final bool isLoading;
  const _Footer({required this.onContinue, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFF0F172A).withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Continue',
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
                  color: const Color(0xFF94A3B8).withOpacity(.75),
                  fontSize: 11.5,
                  height: 1.5),
              children: [
                const TextSpan(text: 'By continuing, you agree to our '),
                TextSpan(
                    text: 'Terms',
                    style: TextStyle(
                        color: const Color(0xFF0F172A).withOpacity(.9),
                        fontWeight: FontWeight.w600)),
                const TextSpan(text: ' and '),
                TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                        color: const Color(0xFF0F172A).withOpacity(.9),
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
