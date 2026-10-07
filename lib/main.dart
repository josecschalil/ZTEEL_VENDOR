import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/app_colors.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:frontend/screens/PhoneAuthScreen.dart';
import 'package:frontend/screens/setupShopScreen.dart';
import 'package:frontend/screens/vendor_home.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/services/realtime_order_service.dart';
import 'package:frontend/services/vendor_cache_service.dart';
import 'package:frontend/screens/splash_screen.dart';

final GlobalKey<ScaffoldMessengerState> _rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
StreamSubscription<VendorOrderEvent>? _orderAlertSubscription;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await VendorCacheService.initialize();

  final loggedIn = await AuthService.isLoggedIn();
  Widget targetScreen;
  var shouldStartRealtime = false;

  if (loggedIn) {
    try {
      await AuthService.getValidAccessToken();
    } catch (_) {}
    
    final hasShop = await VendorService.hasExistingShopData();
    targetScreen = hasShop ? const VendorHome() : const SetupShopScreen();
    shouldStartRealtime = hasShop;
  } else {
    targetScreen = const LoginScreen();
  }

  runApp(ZTEELVendorApp(initialScreen: SplashScreen(nextScreen: targetScreen)));
  _orderAlertSubscription ??=
      VendorOrderRealtimeService.instance.events.where((event) => event.isNewOrder).listen(
    (event) {
      final orderNumber = event.order['order_number']?.toString() ?? 'new';
      final amount = event.order['final_total']?.toString();
      _rootMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            amount == null || amount.isEmpty
                ? 'New order $orderNumber received.'
                : 'New order $orderNumber received — ₹$amount.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    },
  );
  if (shouldStartRealtime) {
    unawaited(VendorService.refreshEssentialData());
    unawaited(VendorOrderRealtimeService.instance.start());
  }
}

class ZTEELVendorApp extends StatelessWidget {
  final Widget initialScreen;
  const ZTEELVendorApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _rootMessengerKey,
      title: 'ZTEEL Vendor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orangeWarm),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return _OfflineWrapper(child: child!);
      },
      home: initialScreen,
    );
  }
}

class _OfflineWrapper extends StatefulWidget {
  final Widget child;
  const _OfflineWrapper({required this.child});

  @override
  State<_OfflineWrapper> createState() => _OfflineWrapperState();
}

class _OfflineWrapperState extends State<_OfflineWrapper> {
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _updateConnectivity(results);
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectivity(results);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final nextOffline =
        (results.contains(ConnectivityResult.none) && results.length == 1) ||
        results.every((result) => result == ConnectivityResult.none);
    final wasOffline = _isOffline;
    if (mounted) {
      setState(() {
        _isOffline = nextOffline;
      });
    }
    if (wasOffline && !nextOffline) {
      // `Image.network` can hold an error result after an offline request.
      // Drop that result and notify cache-backed pages to bind their current
      // data again while the manifest sync runs in the background.
      PaintingBinding.instance.imageCache.clear();
      VendorCacheService.notifyVisibleDataMayHaveChanged();
      unawaited(_syncAfterReconnect());
    }
  }

  Future<void> _syncAfterReconnect() async {
    await VendorService.refreshEssentialData();
    VendorCacheService.notifyVisibleDataMayHaveChanged();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_isOffline)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    color: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'No Internet Connection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
