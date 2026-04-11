import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard.dart';
import 'package:frontend/screens/offerScreen.dart';
import 'package:frontend/screens/orderScreen.dart';
import 'package:frontend/screens/profileEditScreen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';

class VendorHome extends StatefulWidget {
  const VendorHome({super.key});

  @override
  State<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  int _selectedTabIndex = 0;

  static const Color bgDark = Color(0xFF1A0E0A);

  final List<VendorTab> _tabs = [
    VendorTab.dashboard,
    VendorTab.offers,
    VendorTab.orders,
    VendorTab.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: IndexedStack(
        index: _selectedTabIndex,
        children: const [
          RestaurantDashboard(),
          OffersScreen(),
          OrdersScreen(),
          ProfileEditScreen(),
        ],
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
}
