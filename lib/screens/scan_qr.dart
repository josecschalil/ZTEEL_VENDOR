import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/screens/orderDetailScreen.dart';
import 'package:frontend/screens/orderScreen.dart';
import 'package:frontend/services/vendor_service.dart';

// ─── Slate Theme Palette ─────────────────────────────────────────────────────
class _ScanTheme {
  const _ScanTheme._();

  static const bg = Color(0xFF0F172A); // slate-900
  static const surface = Color(0xFF1E293B); // slate-800
  static const border = Color(0xFF334155); // slate-700
  static const emerald = Color(0xFF10B981); // emerald-500
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF94A3B8); // slate-400
}

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
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
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
    } catch (_) {
      _showSnackBar('Flashlight is unavailable on this device.');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (_) {
      _showSnackBar('Camera switch unavailable.');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final BarcodeCapture? capture =
            await _scannerController.analyzeImage(image.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          final code = capture.barcodes.first.rawValue;
          if (code != null && code.trim().isNotEmpty) {
            _handleScannedCode(code.trim());
          } else {
            _showSnackBar('No valid QR code found in selected image.');
          }
        } else {
          _showSnackBar('No QR code detected in the selected image.');
        }
      }
    } catch (e) {
      _showSnackBar('Failed to scan image: $e');
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        backgroundColor:
            success ? _ScanTheme.emerald : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInvalidOrderDialog(String code) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.block_flipped,
                color: Color(0xFFEF4444),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Not Found for Your Shop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This QR code ($code) does not belong to your shop or is invalid. Please verify that the customer is presenting an active order placed with your restaurant.',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12.5,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => Navigator.pop(ctx),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Center(
                  child: Text(
                    'Scan Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  Future<void> _handleScannedCode(String rawCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    // Show clean slate loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Color(0xFF10B981),
                  strokeWidth: 2.5,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Opening order details…',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 1. Fetch live redemptions for this vendor
      final redRes = await VendorService.getVendorRedemptions();
      List<dynamic> vendorOrders = [];
      if (redRes['success'] == true && redRes['data'] is List) {
        vendorOrders = redRes['data'] as List<dynamic>;
      }

      // 2. Search for matching order in this vendor's redemptions
      final cleanRaw = rawCode.trim();
      
      // Parse structured payload (JSON or URI) to extract the canonical ID
      String extractedId = cleanRaw;
      try {
        final decoded = jsonDecode(cleanRaw);
        if (decoded is Map<String, dynamic>) {
          extractedId = (decoded['id'] ?? decoded['qr_code'] ?? decoded['redemption_id'] ?? cleanRaw).toString().trim();
        }
      } catch (_) {
        try {
          final uri = Uri.parse(cleanRaw);
          if (uri.hasQuery) {
            extractedId = (uri.queryParameters['id'] ?? uri.queryParameters['qr_code'] ?? cleanRaw).trim();
          }
        } catch (_) {}
      }

      Map<String, dynamic>? matchedSession;

      for (final order in vendorOrders) {
        if (order is Map<String, dynamic>) {
          final qr = order['qr_code']?.toString().trim() ?? '';
          final id = order['id']?.toString().trim() ?? '';
          final orderNum = order['order_number']?.toString().trim() ?? '';

          if ((qr.isNotEmpty && qr == extractedId) ||
              (id.isNotEmpty && id == extractedId) ||
              (orderNum.isNotEmpty && orderNum == extractedId)) {
            matchedSession = order;
            break;
          }
        }
      }



      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // If no matching order exists for THIS vendor, reject and notify
      if (matchedSession == null) {
        if (mounted) {
          _showInvalidOrderDialog(cleanRaw);
        }
        return;
      }

      // 3. Map order session to OrderDetailScreen
      final session = matchedSession;
      final rawOrderNum = session['order_number']?.toString();
      final qrCode = session['qr_code']?.toString() ?? cleanRaw;
      final idStr = session['id']?.toString() ?? '';
      String orderIdStr;
      if (rawOrderNum != null && rawOrderNum.isNotEmpty) {
        orderIdStr =
            rawOrderNum.startsWith('#') ? rawOrderNum : '#$rawOrderNum';
      } else if (qrCode.isNotEmpty) {
        orderIdStr = qrCode.startsWith('#') ? qrCode : '#$qrCode';
      } else if (idStr.isNotEmpty) {
        final clean = idStr.replaceAll('-', '');
        orderIdStr =
            '#ORD-${clean.length >= 6 ? clean.substring(0, 6).toUpperCase() : clean.toUpperCase()}';
      } else {
        orderIdStr = '#ORD-000000';
      }

      final status = (session['status'] ?? 'pending').toString().toLowerCase();
      final customerName = session['customer_name']?.toString() ?? '';
      final finalTotal = session['final_total']?.toString() ?? '0.00';
      final subtotal = session['subtotal']?.toString() ?? finalTotal;
      final discount = session['total_discount']?.toString() ?? '0.00';

      final hasReward = session['reward'] != null;
      final milestoneMsg = hasReward
          ? (session['reward']?['name_snapshot']?.toString() ??
              'Milestone discount applied')
          : 'No milestone unlocked';

      final rawOffers = session['applied_offers'] as List<dynamic>?;
      final offersList = rawOffers != null
          ? rawOffers.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      final offersSummaryStr = offersList.isNotEmpty
          ? 'Applied: ${offersList.map((o) {
              final title = o['title_snapshot']?.toString() ?? 'Special Offer';
              final dAmount = o['discount_amount']?.toString();
              if (dAmount != null &&
                  double.tryParse(dAmount) != null &&
                  double.tryParse(dAmount)! > 0) {
                return '$title (Saved ₹$dAmount)';
              }
              return title;
            }).join(', ')}'
          : '[No Offers Applied]';

      final rawItems = (session['items'] as List<dynamic>?) ?? [];
      List<OrderLineItem> mappedItems = [];
      if (rawItems.isEmpty) {
        mappedItems.add(OrderLineItem(
          name: 'Scanned QR Item',
          note: 'Code: $cleanRaw',
          quantity: 'x1',
          imageUrl: '',
          unitPrice: '₹$finalTotal each',
          lineTotal: '₹$finalTotal',
          appliedOffer: offersList.isNotEmpty
              ? offersList.first['title_snapshot']?.toString()
              : null,
        ));
      } else {
        mappedItems = rawItems.map((item) {
          final iMap = item as Map<String, dynamic>;
          final iName = iMap['item_name_snapshot']?.toString() ??
              iMap['name']?.toString() ??
              '';
          final nameStr = iName.isNotEmpty ? iName : 'Item';

          final components = iMap['components'] as List<dynamic>?;
          String noteStr = '';
          if (components != null && components.isNotEmpty) {
            noteStr = components
                .map((c) =>
                    '${c['quantity'] ?? 1}x ${c['item_name_snapshot'] ?? c['name'] ?? ''}')
                .join(', ');
          } else if (iMap['is_reward_item'] == true) {
            noteStr = 'Free Milestone Reward';
          }
          if (noteStr.isEmpty) noteStr = 'Standard';

          final qty = iMap['quantity']?.toString() ?? '1';
          final uPrice = iMap['unit_price_snapshot']?.toString() ??
              iMap['price']?.toString() ??
              '0.00';
          final lTotal = iMap['line_total']?.toString() ?? '0.00';
          final imgUrl = ApiConfig.getImageUrl(
                  iMap['image']?.toString() ??
                      iMap['image_url']?.toString()) ??
              '';

          return OrderLineItem(
            name: nameStr,
            note: noteStr,
            quantity: 'x$qty',
            imageUrl: imgUrl,
            unitPrice: '₹$uPrice each',
            lineTotal: '₹$lTotal',
            appliedOffer: offersList.isNotEmpty
                ? offersList.first['title_snapshot']?.toString()
                : null,
          );
        }).toList();
      }

      if (!mounted) return;

      // 4. Open OrderDetailScreen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            orderId: orderIdStr,
            qrCode: qrCode,
            status: status,
            customerName: customerName.isNotEmpty ? customerName : null,
            totalAmount: '₹$finalTotal',
            subtotalAmount: '₹$subtotal',
            savingsAmount: '-₹$discount',
            offersSummary: offersSummaryStr,
            milestoneUnlocked: hasReward,
            milestoneMessage: milestoneMsg,
            items: mappedItems,
            onOrderCompleted: () {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const OrdersScreen(initialTabIndex: 1),
                  ),
                );
              }
            },
          ),
        ),
      );

      if (result == true && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const OrdersScreen(initialTabIndex: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('Error reading order details: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _ScanTheme.bg,
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
                    if (barcode.rawValue != null &&
                        barcode.rawValue!.trim().isNotEmpty) {
                      _handleScannedCode(barcode.rawValue!.trim());
                      break;
                    }
                  }
                },
                errorBuilder: (context, error) {
                  return Container(
                    color: _ScanTheme.bg,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _ScanTheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: _ScanTheme.border),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: _ScanTheme.textSecondary,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Camera Access Required',
                              style: TextStyle(
                                color: _ScanTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please allow camera permission to scan order QR codes.\n${error.errorCode.name}',
                              style: const TextStyle(
                                color: _ScanTheme.textSecondary,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
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

            // ── Slate Overlay Outside Scanner Box ──
            Positioned.fill(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(
                  scanBoxSize: 260,
                  centerY: size.height * 0.40,
                ),
              ),
            ),

            // ── Top Header & Scanner Area ──
            SafeArea(
              child: Column(
                children: [
                  // Slate Glass Top Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _ScanTheme.bg.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan Order QR',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Align customer\'s code to view order',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: _ScanTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _switchCamera,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _ScanTheme.bg.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Icon(
                              Icons.cameraswitch_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scanner Frame Area
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildScannerFrame(),
                      ],
                    ),
                  ),

                  // Bottom Controls
                  _buildBottomContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Animated Scanner Frame ─────────────────────────────────────────────────
  Widget _buildScannerFrame() {
    const double boxSize = 260;
    const double cornerLen = 28;
    const double cornerThick = 3.5;
    const double cornerRadius = 12;

    return ScaleTransition(
      scale: _pulseAnim,
      child: SizedBox(
        width: boxSize,
        height: boxSize,
        child: Stack(
          children: [
            // Inner Viewport
            ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: Container(
                width: boxSize,
                height: boxSize,
                color: Colors.transparent,
              ),
            ),

            // Animated Laser Scan Line (Emerald Glow)
            AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (_, __) {
                final top = 14 + _scanLineAnim.value * (boxSize - 28);
                return Positioned(
                  top: top,
                  left: 14,
                  right: 14,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _ScanTheme.emerald.withValues(alpha: 0),
                          _ScanTheme.emerald.withValues(alpha: 0.95),
                          _ScanTheme.emerald.withValues(alpha: 0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: _ScanTheme.emerald.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2.5,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Corner Brackets — Top Left
            _corner(
              top: 0,
              left: 0,
              tl: true,
              cornerLen: cornerLen,
              thick: cornerThick,
              r: cornerRadius,
            ),
            // Top Right
            _corner(
              top: 0,
              right: 0,
              tr: true,
              cornerLen: cornerLen,
              thick: cornerThick,
              r: cornerRadius,
            ),
            // Bottom Left
            _corner(
              bottom: 0,
              left: 0,
              bl: true,
              cornerLen: cornerLen,
              thick: cornerThick,
              r: cornerRadius,
            ),
            // Bottom Right
            _corner(
              bottom: 0,
              right: 0,
              br: true,
              cornerLen: cornerLen,
              thick: cornerThick,
              r: cornerRadius,
            ),
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
          color: _ScanTheme.emerald,
          strokeWidth: thick,
          radius: r,
        ),
      ),
    );
  }

  // ── Bottom Instructions + Controls ─────────────────────────────────────────
  Widget _buildBottomContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _ScanTheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _ScanTheme.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.center_focus_strong_rounded,
                  color: _ScanTheme.emerald,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Point camera at customer QR code',
                  style: TextStyle(
                    color: _ScanTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Torch + Gallery buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: _isTorchOn
                    ? Icons.flashlight_on_rounded
                    : Icons.flashlight_off_outlined,
                label: _isTorchOn ? 'Torch On' : 'Torch Off',
                isActive: _isTorchOn,
                onTap: _toggleTorch,
              ),
              const SizedBox(width: 28),
              _buildActionButton(
                icon: Icons.photo_library_outlined,
                label: 'Scan Gallery',
                isActive: false,
                onTap: _pickFromGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? _ScanTheme.emerald
                  : _ScanTheme.surface.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? _ScanTheme.emerald
                    : Colors.white.withValues(alpha: 0.16),
                width: 1.2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: _ScanTheme.emerald.withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : _ScanTheme.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slate Overlay with Transparent Scanner Cutout ────────────────────────────
class _ScannerOverlayPainter extends CustomPainter {
  final double scanBoxSize;
  final double centerY;

  _ScannerOverlayPainter({required this.scanBoxSize, required this.centerY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.72);
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

// ── Corner Bracket Painter ───────────────────────────────────────────────────
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