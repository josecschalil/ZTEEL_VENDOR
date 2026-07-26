import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard.dart';
import 'package:frontend/screens/offerScreen.dart';
import 'package:frontend/screens/orderScreen.dart';
import 'package:frontend/screens/profileEditScreen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';
import 'package:frontend/app_colors.dart';

class VendorHome extends StatefulWidget {
  const VendorHome({super.key});

  @override
  State<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  int _selectedTabIndex = 0;

  final List<VendorTab> _tabs = [
    VendorTab.dashboard,
    VendorTab.offers,
    VendorTab.orders,
    VendorTab.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: KeyedSubtree(
        key: ValueKey(_selectedTabIndex),
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: VendorBottomNav(
        currentTab: _tabs[_selectedTabIndex],
        onTabChanged: (tab) {
          setState(() {
            _selectedTabIndex = _tabs.indexOf(tab);
          });
        },
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_tabs[_selectedTabIndex]) {
      case VendorTab.dashboard:
        return const RestaurantDashboard();
      case VendorTab.offers:
        return const OffersScreen();
      case VendorTab.orders:
        return const OrdersScreen();
      case VendorTab.profile:
        return const ProfileEditScreen();
    }
  }
}
