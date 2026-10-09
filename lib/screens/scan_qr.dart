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

// ─── Light Theme Palette ────────────────────────────────────────────────
class _ScanTheme {
  const _ScanTheme._();
  static const bg = Color(0xFF0F172A); // slate-50
  static const surface = Color(0xFF0F172A);
  static const surfaceRaised = Color(0xFF0F172A); // slate-100
  static const border = Color(0xFF0F172A); // slate-200
  static const textPrimary = Color(0xFFF8FAFC); // slate-900
  static const textSecondary = Color(0xFF64748B); // slate-500
  static const emerald = Color(0xFFF8FAFC); // emerald-500
  static const dark = Color(0xFFF8FAFC); // slate-900
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
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
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
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
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
        backgroundColor: success ? _ScanTheme.emerald : const Color(0xFF0F172A),
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
      // QR ownership and status are security-sensitive. Never use an offline
      // order cache to accept or reject a code.
      final redRes = await VendorService.getVendorRedemptions(
        forceRefresh: true,
        allowStale: false,
      );
      if (redRes['success'] != true) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showSnackBar('A live connection is required to verify this QR code.');
        return;
      }
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
          extractedId = (decoded['id'] ??
                  decoded['qr_code'] ??
                  decoded['redemption_id'] ??
                  cleanRaw)
              .toString()
              .trim();
        }
      } catch (_) {
        try {
          final uri = Uri.parse(cleanRaw);
          if (uri.hasQuery) {
            extractedId = (uri.queryParameters['id'] ??
                    uri.queryParameters['qr_code'] ??
                    cleanRaw)
                .trim();
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
        orderIdStr = '#ORD-${clean.toUpperCase()}';
      } else {
        orderIdStr = '#ORD-UNKNOWN';
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
                  iMap['image']?.toString() ?? iMap['image_url']?.toString()) ??
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
    return Scaffold(
      backgroundColor: _ScanTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _ScanTheme.textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Scan Order',
          style: TextStyle(
            color: _ScanTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Text(
              'Align QR Code',
              style: TextStyle(
                color: _ScanTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan the customer\'s order code to proceed',
              style: TextStyle(
                color: _ScanTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: _ScanTheme.dark.withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: _ScanTheme.dark.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          if (_isProcessing) return;
                          for (final barcode in capture.barcodes) {
                            final value = barcode.rawValue?.trim();
                            if (value != null && value.isNotEmpty) {
                              _handleScannedCode(value);
                              break;
                            }
                          }
                        },
                        errorBuilder: (context, error) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_off_outlined,
                                  color: _ScanTheme.textSecondary,
                                  size: 40,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Camera Error\n${error.errorCode.name}',
                                  style: const TextStyle(
                                    color: _ScanTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _scanLineAnim,
                      builder: (context, child) {
                        final top = 20 + _scanLineAnim.value * 240;
                        return Positioned(
                          top: top,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _ScanTheme.emerald.withValues(alpha: 0),
                                  _ScanTheme.emerald,
                                  _ScanTheme.emerald.withValues(alpha: 0),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _ScanTheme.emerald.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ScannerCornersPainter(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFloatingButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: _pickFromGallery,
                ),
                const SizedBox(width: 10),
                _buildFloatingButton(
                  icon: _isTorchOn
                      ? Icons.flashlight_on_rounded
                      : Icons.flashlight_off_outlined,
                  label: 'Torch',
                  onTap: _toggleTorch,
                  isActive: _isTorchOn,
                ),
                const SizedBox(width: 10),
                _buildFloatingButton(
                  icon: Icons.cameraswitch_outlined,
                  label: 'Flip',
                  onTap: _switchCamera,
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isActive ? _ScanTheme.emerald : const Color(0xFF334155),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.22 : 0.14),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isActive
                    ? _ScanTheme.emerald.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? _ScanTheme.emerald : Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _ScanTheme.emerald : const Color(0xFFE2E8F0),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _ScanTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _ScanTheme.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: _ScanTheme.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order scanner',
                style: TextStyle(
                  color: _ScanTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Secure QR verification',
                style: TextStyle(
                  color: _ScanTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _ScanTheme.emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: _ScanTheme.emerald.withValues(alpha: 0.28)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 14, color: _ScanTheme.emerald),
              SizedBox(width: 5),
              Text(
                'Secure',
                style: TextStyle(
                  color: _ScanTheme.emerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScannerWindow(double side) {
    return Center(
      child: Container(
        width: side,
        height: side,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              _ScanTheme.emerald.withValues(alpha: 0.92),
              const Color(0xFF38BDF8).withValues(alpha: 0.72),
              _ScanTheme.emerald.withValues(alpha: 0.22),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _ScanTheme.emerald.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  if (_isProcessing) return;
                  for (final barcode in capture.barcodes) {
                    final value = barcode.rawValue?.trim();
                    if (value != null && value.isNotEmpty) {
                      _handleScannedCode(value);
                      break;
                    }
                  }
                },
                errorBuilder: (context, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam_off_outlined,
                          color: _ScanTheme.textSecondary,
                          size: 38,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Camera unavailable\n${error.errorCode.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ScanTheme.textSecondary,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
              AnimatedBuilder(
                animation: _scanLineAnim,
                builder: (context, child) => Positioned(
                  top: 30 + _scanLineAnim.value * (side - 60),
                  left: 28,
                  right: 28,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          _ScanTheme.emerald.withValues(alpha: 0),
                          _ScanTheme.emerald,
                          _ScanTheme.emerald.withValues(alpha: 0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _ScanTheme.emerald.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              CustomPaint(
                  painter: _ScannerCornersPainter(color: _ScanTheme.emerald)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: _ScanTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ScanTheme.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _ScanTheme.emerald, size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Only QR codes for your shop can be confirmed.',
              style: TextStyle(
                color: _ScanTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _ScanTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ScanTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildControlButton(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: _pickFromGallery,
            ),
          ),
          Expanded(
            child: _buildControlButton(
              icon: _isTorchOn
                  ? Icons.flashlight_on_rounded
                  : Icons.flashlight_off_outlined,
              label: _isTorchOn ? 'Torch on' : 'Torch',
              onTap: _toggleTorch,
              isActive: _isTorchOn,
            ),
          ),
          Expanded(
            child: _buildControlButton(
              icon: Icons.cameraswitch_outlined,
              label: 'Flip camera',
              onTap: _switchCamera,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive
              ? _ScanTheme.emerald.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? _ScanTheme.emerald : _ScanTheme.textPrimary,
              size: 20,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? _ScanTheme.emerald : _ScanTheme.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom Painter for Scanner Corners ────────────────────────────────────
class _ScannerCornersPainter extends CustomPainter {
  final Color color;

  _ScannerCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 32.0;
    const double padding = 24.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(padding, padding + cornerLength)
        ..lineTo(padding, padding)
        ..lineTo(padding + cornerLength, padding),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - cornerLength, padding)
        ..lineTo(size.width - padding, padding)
        ..lineTo(size.width - padding, padding + cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(padding, size.height - padding - cornerLength)
        ..lineTo(padding, size.height - padding)
        ..lineTo(padding + cornerLength, size.height - padding),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - cornerLength, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
