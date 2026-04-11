import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard.dart';
import 'package:frontend/screens/offerScreen.dart';
import 'package:frontend/screens/orderScreen.dart';
import 'package:frontend/screens/profileEditScreen.dart';

enum VendorTab { dashboard, offers, orders, profile }

class VendorBottomNav extends StatelessWidget {
  const VendorBottomNav({
    super.key,
    required this.currentTab,
    this.onTabChanged,
  });

  final VendorTab currentTab;
  final Function(VendorTab)? onTabChanged;

  static const Color _bg = Color(0xFF1A0E0A);
  static const Color _orange = Color(0xFFE8622A);
  static const Color _grey = Color(0xFF9E7E72);

  @override
  Widget build(BuildContext context) {
    final items = [
      _VendorNavItem(
        tab: VendorTab.dashboard,
        icon: Icons.grid_view_rounded,
        label: 'DASHBOARD',
        builder: () => const RestaurantDashboard(),
      ),
      _VendorNavItem(
        tab: VendorTab.offers,
        icon: Icons.local_offer_outlined,
        label: 'OFFERS',
        builder: () => const OffersScreen(),
      ),
      _VendorNavItem(
        tab: VendorTab.orders,
        icon: Icons.receipt_long_outlined,
        label: 'ORDERS',
        builder: () => const OrdersScreen(),
      ),
      _VendorNavItem(
        tab: VendorTab.profile,
        icon: Icons.person_outline_rounded,
        label: 'PROFILE',
        builder: () => const ProfileEditScreen(),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: Color(0x0FFFFFFF), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: items.map((item) {
              final isActive = item.tab == currentTab;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _handleTap(context, item),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive ? _orange : _grey,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isActive ? _orange : _grey,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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
