import 'package:flutter/material.dart';
import 'package:frontend/widgets/app_top_bar.dart';

enum LegalTab { terms, privacy }

class TermsAndPolicyScreen extends StatefulWidget {
  final LegalTab initialTab;

  const TermsAndPolicyScreen({
    super.key,
    this.initialTab = LegalTab.terms,
  });

  @override
  State<TermsAndPolicyScreen> createState() => _TermsAndPolicyScreenState();
}

class _TermsAndPolicyScreenState extends State<TermsAndPolicyScreen> {
  late LegalTab _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: _currentTab == LegalTab.terms
                  ? 'Terms & Conditions'
                  : 'Privacy Policy',
              subtitle: 'ZTEEL Partner Agreement',
              showBackButton: true,
              backgroundColor: Colors.transparent,
              showBorder: false,
            ),
            _buildTabSelector(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: _currentTab == LegalTab.terms
                    ? _buildTermsContent()
                    : _buildPrivacyContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              title: 'Terms of Service',
              tab: LegalTab.terms,
              icon: Icons.gavel_rounded,
            ),
          ),
          Expanded(
            child: _tabButton(
              title: 'Privacy Policy',
              tab: LegalTab.privacy,
              icon: Icons.shield_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required LegalTab tab,
    required IconData icon,
  }) {
    final isSelected = _currentTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditorialHeader(
          icon: Icons.storefront_rounded,
          title: 'Vendor Partner Agreement',
          subtitle:
              'Terms and operating guidelines for restaurants and merchants processing orders via the ZTEEL platform.',
          versionText: 'v1.0 • Updated Oct 2026',
        ),
        const SizedBox(height: 14),

        _buildOperationalSummaryCard([
          'Direct Payment Settlement: ZTEEL does not collect in-app customer payments. All bills are settled at your restaurant counter.',
          'Dine-in & Pickup Only: ZTEEL does not provide delivery drivers or home delivery logistics.',
          'Order Autonomy: You have full control to accept or reject incoming orders according to kitchen availability.',
        ]),
        const SizedBox(height: 14),

        _buildSectionCard(
          number: '01',
          title: 'Platform Role & Intermediary Status',
          content:
              'ZTEEL operates as a technology and discovery platform that connects local food vendors with customers. ZTEEL is not a food producer, restaurant operator, or payment gateway. Our role is strictly to broadcast menus, transmit live order requests, and enable discovery.',
        ),
        const SizedBox(height: 10),

        _buildSectionCard(
          number: '02',
          title: 'Order Processing & Kitchen Autonomy',
          content:
              '• Receiving Orders: Vendors receive real-time digital notifications for incoming customer orders.\n\n'
              '• Acceptance Discretion: You may accept or decline orders based on kitchen capacity, stock availability, or operating hours.\n\n'
              '• Preparation & Handover: Once accepted, vendors commit to preparing the order promptly. At customer pickup or table service, verify the order using the customer details or by scanning their digital order QR code.',
        ),
        const SizedBox(height: 10),

        _buildSectionCard(
          number: '03',
          title: 'Payment Settlement (No In-App Payments)',
          content:
              '• In-Person Counter Payments: The ZTEEL platform does not collect or disburse payments from customers. All monetary transactions, taxes, and bills must be collected directly by the vendor via in-store cash, UPI, cards, or POS systems.\n\n'
              '• Financial Independence: ZTEEL does not hold vendor funds or act as an escrow agent.',
        ),
        const SizedBox(height: 10),

        _buildSectionCard(
          number: '04',
          title: 'No Home Delivery Logistics',
          content:
              '• Customer Pickup & Dine-in: ZTEEL does not provide delivery riders, vehicles, or logistics management. All orders placed through the client app are strictly for customer takeaway/pickup or dine-in consumption at your premises.',
        ),
        const SizedBox(height: 10),

        _buildSectionCard(
          number: '05',
          title: 'Menu, Pricing & Promotional Offers',
          content:
              '• Accurate Listings: Vendors agree to maintain accurate item descriptions, prices, dietary tags (Veg/Non-Veg), and stock availability.\n\n'
              '• Honoring Created Offers: Any discounts, promotional coupons, or milestone rewards published by you in the ZTEEL vendor app must be honored in full when presented by eligible customers.',
        ),
        const SizedBox(height: 10),

        _buildSectionCard(
          number: '06',
          title: 'Food Safety, Hygiene & Licensing',
          content:
              '• Statutory Licenses: You represent and warrant that your establishment complies with all statutory food safety regulations (such as FSSAI guidelines) and holds valid business permits.\n\n'
              '• Quality & Hygiene: The vendor maintains sole responsibility for food preparation hygiene, allergen disclosure, and overall food quality.',
        ),
        const SizedBox(height: 10),

        _buildSectionCard(
          number: '07',
          title: 'Account Management & Service Standards',
          content:
              '• Authentication: Accounts are secured via mobile OTP. Please keep your login access secure.\n\n'
              '• Termination: Repeated unfulfilled accepted orders, fraudulent activity, or health violations may result in temporary or permanent suspension from the ZTEEL platform.',
        ),
        const SizedBox(height: 20),
        _buildFooterBrand(),
      ],
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditorialHeader(
          icon: Icons.shield_outlined,
          title: 'Vendor Privacy Policy',
          subtitle:
              'How ZTEEL collects, utilizes, and protects information associated with your business and vendor account.',
          versionText: 'v1.0 • Updated Oct 2026',
        ),
        const SizedBox(height: 14),

        _buildOperationalSummaryCard([
          'Business Data Only: We only collect details necessary to display your shop and route orders.',
          'Zero Banking Credentials: Since we do not process in-app payments, we never store bank accounts or payment cards.',
          'No Data Selling: Your business and contact information is never sold to third-party marketing firms.',
        ]),
        const SizedBox(height: 14),

        _buildSectionCard(
          number: '01',
          title: 'Information Collected',
          content:
              '• Account Credentials: Registered phone number, store manager/owner name, and device authentication session tokens.\n\n'
              '• Store Details: Restaurant name, cuisine types, address, operating schedules, cover photos, and menu items with pricing.\n\n'
              '• Outlet Geolocation: Precise GPS coordinates used solely to show your restaurant on customer search maps and distance estimates.',
        ),
        const SizedBox(height: 10),

        _buildSectionCard(
          number: '02',
          title: 'How Data is Used',
          content:
              '• To publish your storefront and menu to nearby customers.\n\n'
              '• To send live incoming order alerts and customer pickup notifications.\n\n'
              '• To generate analytics regarding sales trends, popular dishes, and peak business hours on your vendor dashboard.',
        ),
        const SizedBox(height: 10),

        _buildSectionCard(
          number: '03',
          title: 'Third-Party Services & Storage',
          content:
              '• Map Providers: We use OpenStreetMap tiles for map display and coordinate geotagging.\n\n'
              '• Secure Infrastructure: Data is hosted on protected cloud servers with encrypted API communications (HTTPS/TLS).',
        ),
        const SizedBox(height: 10),

        _buildSectionCard(
          number: '04',
          title: 'Vendor Rights & Support',
          content:
              'You can edit your store info, menu items, opening hours, or request account deletion at any time. For privacy inquiries or assistance, reach out to our partner team at support@zteel.com.',
        ),
        const SizedBox(height: 20),
        _buildFooterBrand(),
      ],
    );
  }

  Widget _buildEditorialHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required String versionText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      versionText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalSummaryCard(List<String> points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF475569)),
              SizedBox(width: 7),
              Text(
                'Key Operational Highlights',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(Icons.circle, size: 4.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.8,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBrand() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 12, bottom: 32),
        child: Column(
          children: [
            Text(
              'ZTEEL Merchant Platform',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 2),
            Text(
              '© 2026 ZTEEL. All rights reserved.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
