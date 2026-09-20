import 'package:flutter/material.dart';
import 'package:frontend/screens/scan_qr.dart';

enum VendorTab { dashboard, offers, orders, profile }

class VendorBottomNav extends StatelessWidget {
  const VendorBottomNav({
    super.key,
    required this.currentTab,
    this.onTabChanged,
  });

  final VendorTab currentTab;
  final Function(VendorTab)? onTabChanged;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),
      decoration: const BoxDecoration(
        color: Color(0xF5FFFFFF),
        border: Border(top: BorderSide(color: Color(0x14E2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: currentTab == VendorTab.dashboard,
            onTap: () => onTabChanged?.call(VendorTab.dashboard),
          ),
          _NavItem(
            icon: Icons.local_offer_outlined,
            label: 'Offers',
            isActive: currentTab == VendorTab.offers,
            onTap: () => onTabChanged?.call(VendorTab.offers),
          ),
          // Center scan button
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QRScannerScreen(),
                ),
              );
            },
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            isActive: currentTab == VendorTab.orders,
            onTap: () => onTabChanged?.call(VendorTab.orders),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: currentTab == VendorTab.profile,
            onTap: () => onTabChanged?.call(VendorTab.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
              ),
            ] else ...[
              const SizedBox(height: 7),
            ],
          ],
        ),
      ),
    );
  }
}
