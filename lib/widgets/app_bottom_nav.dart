import 'package:flutter/material.dart';
import 'package:frontend/app_colors.dart';
import 'package:frontend/screens/scan_qr.dart';

enum VendorTab {
  dashboard,
  offers,
  orders,
  profile,
}

class VendorBottomNav extends StatelessWidget {
  const VendorBottomNav({
    super.key,
    required this.currentTab,
    this.onTabChanged,
    this.onScanTap,
  });

  final VendorTab currentTab;
  final ValueChanged<VendorTab>? onTabChanged;
  final VoidCallback? onScanTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBg,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    activeIcon: Icons.home_rounded,
                    inactiveIcon: Icons.home_outlined,
                    label: 'Home',
                    isActive: currentTab == VendorTab.dashboard,
                    onTap: () {
                      onTabChanged?.call(
                        VendorTab.dashboard,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    activeIcon: Icons.local_offer_rounded,
                    inactiveIcon: Icons.local_offer_outlined,
                    label: 'Offers',
                    isActive: currentTab == VendorTab.offers,
                    onTap: () {
                      onTabChanged?.call(
                        VendorTab.offers,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    activeIcon: Icons.qr_code_scanner_rounded,
                    inactiveIcon: Icons.qr_code_scanner_rounded,
                    label: 'Scan',
                    isScanAction: true,
                    onTap: onScanTap ??
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const QRScannerScreen(),
                            ),
                          );
                        },
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    activeIcon: Icons.receipt_long_rounded,
                    inactiveIcon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    isActive: currentTab == VendorTab.orders,
                    onTap: () {
                      onTabChanged?.call(
                        VendorTab.orders,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    activeIcon: Icons.account_circle_rounded,
                    inactiveIcon: Icons.account_circle_outlined,
                    label: 'Profile',
                    isActive: currentTab == VendorTab.profile,
                    onTap: () {
                      onTabChanged?.call(
                        VendorTab.profile,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isScanAction = false,
  });

  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final VoidCallback onTap;

  final bool isActive;
  final bool isScanAction;

  @override
  Widget build(BuildContext context) {
    final icon = isActive ? activeIcon : inactiveIcon;

    final bool highlighted = isActive || isScanAction;

    final Color iconColor = isScanAction
        ? AppColors.textOnAccent
        : isActive
            ? AppColors.primaryDark
            : AppColors.iconMuted;

    final Color textColor = isScanAction
        ? AppColors.textOnAccent
        : isActive
            ? AppColors.primaryDark
            : AppColors.textMuted;

    return Semantics(
      button: true,
      selected: isActive,
      label: isScanAction ? 'Scan QR code' : label,

      // No InkWell:
      // completely removes splash/ripple.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(
              minWidth: 58,
            ),
            height: 52,
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: isScanAction
                  ? AppColors.primary
                  : isActive
                      ? AppColors.primaryTint
                      : AppColors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isScanAction ? 23 : 22,
                  color: iconColor,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    height: 1,
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
