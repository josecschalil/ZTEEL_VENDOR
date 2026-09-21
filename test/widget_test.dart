import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';
import 'package:frontend/widgets/app_top_bar.dart';

void main() {
  testWidgets('bottom dock exposes active and inactive destinations',
      (tester) async {
    VendorTab? changedTab;
    var scanTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: VendorBottomNav(
            currentTab: VendorTab.dashboard,
            onTabChanged: (tab) => changedTab = tab,
            onScanTap: () => scanTaps += 1,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.bySemanticsLabel('Orders'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Orders'));
    expect(changedTab, VendorTab.orders);

    await tester.tap(find.bySemanticsLabel('Scan QR code'));
    expect(scanTaps, 1);
  });

  testWidgets('bottom dock includes device safe-area padding', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
        child: const MaterialApp(
          home: Scaffold(
            bottomNavigationBar:
                VendorBottomNav(currentTab: VendorTab.dashboard),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(VendorBottomNav)).height, 100);
  });

  testWidgets('top bar retains notification, back, and shop-status actions',
      (tester) async {
    var notificationTaps = 0;
    var backTaps = 0;
    bool? nextShopStatus;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppTopBar(
            title: 'Orders',
            showBackButton: true,
            isDark: true,
            showStatusBadge: true,
            notificationCount: 3,
            onBack: () => backTaps += 1,
            onNotificationTap: () => notificationTaps += 1,
            onStatusToggle: (isOpen) => nextShopStatus = isOpen,
          ),
        ),
      ),
    );

    expect(find.text('Orders'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    expect(find.bySemanticsLabel('3 notifications'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.tap(find.bySemanticsLabel('3 notifications'));
    expect(backTaps, 1);
    expect(notificationTaps, 1);

    await tester.tap(find.bySemanticsLabel('Shop open. Change status'));
    await tester.pumpAndSettle();
    expect(find.text('Close Shop?'), findsOneWidget);

    await tester.tap(find.text('Mark Closed'));
    await tester.pumpAndSettle();
    expect(nextShopStatus, isFalse);
  });
}
