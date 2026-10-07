import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard.dart';
import 'package:frontend/screens/offerScreen.dart';
import 'package:frontend/screens/orderScreen.dart';
import 'package:frontend/screens/profileEditScreen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';
import 'package:frontend/app_colors.dart';
import 'package:frontend/services/vendor_service.dart';

class VendorHome extends StatefulWidget {
  const VendorHome({super.key});

  @override
  State<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> with WidgetsBindingObserver {
  int _selectedTabIndex = 0;
  final Map<int, Widget> _visitedScreens = {};

  final List<VendorTab> _tabs = [
    VendorTab.dashboard,
    VendorTab.offers,
    VendorTab.orders,
    VendorTab.profile,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Cache is displayed immediately. A resume performs one consolidated
      // revalidation instead of every screen independently reloading.
      VendorService.refreshEssentialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _selectedTabIndex,
        children: List<Widget>.generate(
          _tabs.length,
          (index) {
            final existing = _visitedScreens[index];
            if (existing != null) return existing;
            if (index == _selectedTabIndex) {
              final screen = _buildScreen(index);
              _visitedScreens[index] = screen;
              return screen;
            }
            return const SizedBox.shrink();
          },
        ),
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

  Widget _buildScreen(int index) {
    switch (_tabs[index]) {
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
