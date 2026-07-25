import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard.dart';
import 'package:frontend/screens/offerScreen.dart';
import 'package:frontend/screens/orderScreen.dart';
import 'package:frontend/screens/profileEditScreen.dart';
import 'package:frontend/screens/scan_qr.dart';
import 'package:frontend/app_colors.dart';

enum VendorTab { dashboard, offers, orders, profile }

class VendorBottomNav extends StatelessWidget {
  const VendorBottomNav({
    super.key,
    required this.currentTab,
    this.onTabChanged,
  });

  final VendorTab currentTab;
  final Function(VendorTab)? onTabChanged;

  static const double _barHeight = 64;
  static const double _qrButtonSize = 56;

  @override
  Widget build(BuildContext context) {
    final leftItems = [
      _VendorNavItem(
        tab: VendorTab.dashboard,
        icon: Icons.grid_view_rounded,
        label: 'Dashboard',
        builder: () => const RestaurantDashboard(),
      ),
      _VendorNavItem(
        tab: VendorTab.offers,
        icon: Icons.local_offer_outlined,
        label: 'Offers',
        builder: () => const OffersScreen(),
      ),
    ];

    final rightItems = [
      _VendorNavItem(
        tab: VendorTab.orders,
        icon: Icons.receipt_long_outlined,
        label: 'Orders',
        builder: () => const OrdersScreen(),
      ),
      _VendorNavItem(
        tab: VendorTab.profile,
        icon: Icons.person_outline_rounded,
        label: 'Profile',
        builder: () => const ProfileEditScreen(),
      ),
    ];

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // ── Main Bottom Nav Bar ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.navBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: _barHeight,
              child: Row(
                children: [
                  ...leftItems.map((item) => _buildNavItem(context, item)),
                  const SizedBox(width: 64), // space for center QR button
                  ...rightItems.map((item) => _buildNavItem(context, item)),
                ],
              ),
            ),
          ),
        ),

        // ── Center Floating Scan QR Button ──
        Positioned(
          top: -26,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QRScannerScreen(),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _qrButtonSize + 8,
                  height: _qrButtonSize + 8,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bg,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF5A4C), Color(0xFFD63A2C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.textWhite,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SCAN QR',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, _VendorNavItem item) {
    final isActive = item.tab == currentTab;
    final color = isActive ? AppColors.orange : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(context, item),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.orange.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, _VendorNavItem item) {
    if (item.tab == currentTab) {
      return;
    }

    onTabChanged?.call(item.tab);
  }
}

class _VendorNavItem {
  const _VendorNavItem({
    required this.tab,
    required this.icon,
    required this.label,
    required this.builder,
  });

  final VendorTab tab;
  final IconData icon;
  final String label;
  final Widget Function() builder;
}
