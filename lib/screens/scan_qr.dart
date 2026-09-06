import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:frontend/app_colors.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isTorchOn = false;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

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
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      _showErrorSnackBar('Flashlight is unavailable on this device.');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (e) {
      _showErrorSnackBar('Camera switch unavailable.');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          final code = capture.barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            _handleScannedCode(code);
          } else {
            _showErrorSnackBar('No valid QR code found in selected image.');
          }
        } else {
          _showErrorSnackBar('No QR code detected in the selected image.');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to scan image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.orangeDim,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleScannedCode(String rawCode) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.orangeDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: AppColors.orange, size: 38),
            ),
            const SizedBox(height: 16),
            const Text(
              'QR Code Scanned!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rawCode,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.orange),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: rawCode));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Scan Again', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Order verified: $rawCode'),
                          backgroundColor: AppColors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.orange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Verify Order', style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Live Camera Scanner View ──
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_isProcessing) return;
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                    _handleScannedCode(barcode.rawValue!);
                    break;
                  }
                }
              },
              errorBuilder: (context, error) {
                return Container(
                  color: const Color(0xFF1A1A1A),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: AppColors.orange, size: 54),
                          const SizedBox(height: 16),
                          const Text(
                            'Camera Access Error',
                            style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please grant camera permission to scan QR codes.\n${error.errorCode.name}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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

                // Scanner area
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildScannerFrame(),
                    ],
                  ),
                ),

                // Instructions + controls
                _buildBottomContent(),
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
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.textWhite, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Zteel Scanner',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _switchCamera,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cameraswitch_outlined, color: AppColors.textWhite, size: 22),
            ),
          ),
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
            // Scanner Viewport
            ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: Container(
                width: boxSize,
                height: boxSize,
                color: AppColors.transparent,
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
                          AppColors.orange.withOpacity(0),
                          AppColors.orange.withOpacity(0.9),
                          AppColors.orange.withOpacity(0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withOpacity(0.5),
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
          color: AppColors.orange,
          strokeWidth: thick,
          radius: r,
        ),
      ),
    );
  }

  // ── Bottom Instructions + Controls ───────────────────────────
  Widget _buildBottomContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const Text(
            'Scan QR to complete order',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Position the QR code within the frame to scan\nautomatically',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Torch + Gallery buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconButton(
                icon: _isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_outlined,
                isActive: _isTorchOn,
                onTap: _toggleTorch,
              ),
              const SizedBox(width: 24),
              _iconButton(
                icon: Icons.image_outlined,
                onTap: _pickFromGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: isActive ? AppColors.orange : AppColors.textWhite.withOpacity(0.16),
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: AppColors.textWhite,
          size: 26,
        ),
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
    final paint = Paint()..color = AppColors.black.withOpacity(0.62);
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