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
              'The terms that govern a restaurant or merchant’s use of the ZTEEL Vendor app and platform.',
          versionText: 'Effective 10 October 2026 • Version 2.0',
        ),
        const SizedBox(height: 14),

        _buildOperationalSummaryCard([
          'ZTEEL is a restaurant discovery and order-redemption platform. It is not the seller, food preparer, payment processor, or delivery provider for your business.',
          'The current service supports dine-in and customer pickup. You collect payment directly at your premises; ZTEEL does not collect, hold, or settle customer payments.',
          'Please read these terms together with the Privacy Policy tab. By creating or using a vendor account, you agree to both.',
        ]),
        const SizedBox(height: 14),

        ..._buildSections(_termsSections),
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
              'How ZTEEL handles information connected with your vendor account, shop, device, and orders.',
          versionText: 'Effective 10 October 2026 • Version 2.0',
        ),
        const SizedBox(height: 14),

        _buildOperationalSummaryCard([
          'We use your information to run your vendor account, publish the shop information you choose to provide, route orders, and maintain the service.',
          'The app does not process customer payments and does not request or store your bank account, card, or UPI credentials.',
          'We do not sell or rent personal information, and the vendor app does not include advertising or third-party analytics SDKs.',
        ]),
        const SizedBox(height: 14),

        ..._buildSections(_privacySections),
        const SizedBox(height: 20),
        _buildFooterBrand(),
      ],
    );
  }

  List<Widget> _buildSections(List<_LegalSection> sections) {
    return [
      for (var index = 0; index < sections.length; index++) ...[
        _buildSectionCard(
          number: (index + 1).toString().padLeft(2, '0'),
          title: sections[index].title,
          content: sections[index].content,
        ),
        if (index < sections.length - 1) const SizedBox(height: 10),
      ],
    ];
  }

  static const List<_LegalSection> _termsSections = [
    _LegalSection(
      title: 'Who These Terms Apply To',
      content:
          'These Terms apply to any restaurant, café, food outlet, merchant, owner, manager, employee, or authorised representative using ZTEEL Vendor (the “Vendor”). If you use the app for a business, you confirm that you are authorised to accept these Terms for that business. “ZTEEL”, “we”, “us”, and “our” mean the operator of the ZTEEL platform.',
    ),
    _LegalSection(
      title: 'The ZTEEL Service',
      content:
          'ZTEEL provides technology that may display your shop, menu, offers, business hours, and location to customers and transmit customer order-redemption requests to you. ZTEEL does not prepare food, employ you, operate your premises, guarantee customer demand, or act as your agent except to provide the platform features described here.',
    ),
    _LegalSection(
      title: 'Eligibility, Account Security & Accurate Information',
      content:
          'You must provide truthful, current business and contact information and keep it updated. Access is authenticated using a one-time password sent to your registered mobile number. Do not share that number, OTP, session, device, or account access with unauthorised people. Tell us promptly if you suspect unauthorised access.',
    ),
    _LegalSection(
      title: 'Your Public Storefront',
      content:
          'Your business name, address, map location, operating hours, shop description, shop images, menu categories, item names, descriptions, food tags, prices, availability, offers, and customer ratings/reviews may be displayed to customers through ZTEEL. Only upload content you have the right to use, and do not include private personal information in public fields or images.',
    ),
    _LegalSection(
      title: 'Orders, QR Codes & Customer Information',
      content:
          'You may receive live order alerts and order details, including a customer name, items, quantities, applicable offers, totals, order status, and QR/order identifier. Use this information only to verify, prepare, hand over, resolve, or record the relevant order. Do not use it for unrelated marketing, disclose it, retain it longer than necessary, or contact customers outside the order context without a lawful basis and their consent.',
    ),
    _LegalSection(
      title: 'Order Acceptance, Fulfilment & Disputes',
      content:
          'You may accept or reject a pending order based on real kitchen capacity, stock, or operating conditions. If you confirm an order by scanning its QR code, you are confirming that the order was fulfilled or handed over at your premises. Prepare accepted orders accurately and promptly, honour valid platform offers and rewards, and handle customer concerns professionally. ZTEEL may investigate misuse, but does not guarantee the outcome of a dispute between a Vendor and customer.',
    ),
    _LegalSection(
      title: 'Payments, Taxes & Delivery',
      content:
          'ZTEEL does not collect, hold, settle, refund, or process customer payments in this version of the service. You are solely responsible for collecting the bill at your counter, issuing invoices or receipts, taxes, refunds, chargebacks, and your own POS, cash, card, or UPI arrangements. ZTEEL does not provide delivery riders, vehicles, or home-delivery logistics; orders are for customer pickup or dine-in at your premises.',
    ),
    _LegalSection(
      title: 'Food Safety, Legal Compliance & Prohibited Conduct',
      content:
          'You are solely responsible for food preparation, quality, hygiene, allergens, dietary claims, packaging, labelling, permits, taxes, employment obligations, consumer-law compliance, and all licences required for your business, including applicable FSSAI requirements in India. You must not list unlawful, unsafe, infringing, deceptive, discriminatory, or age-restricted items; manipulate ratings or orders; misuse QR codes; impersonate anyone; introduce malware; or interfere with the platform.',
    ),
    _LegalSection(
      title: 'Content, Reviews & Intellectual Property',
      content:
          'You retain ownership of content you submit, but give ZTEEL a non-exclusive, worldwide, royalty-free licence to host, reproduce, adapt for technical display, and show that content as needed to operate, promote, and improve the service. You are responsible for obtaining all permissions for names, logos, images, and menu content. Customer reviews represent their authors’ views; we may remove content that violates law or platform rules.',
    ),
    _LegalSection(
      title: 'Availability, Changes & Suspension',
      content:
          'The service may be unavailable, interrupted, changed, or discontinued for maintenance, security, technical, legal, or business reasons. To the extent permitted by law, it is provided “as is” and “as available” without a promise of uninterrupted or error-free operation. We may limit, suspend, or end access when we reasonably believe there is fraud, a safety concern, a legal violation, material breach, or risk to users or the platform.',
    ),
    _LegalSection(
      title: 'Liability & Indemnity',
      content:
          'To the maximum extent permitted by applicable law, ZTEEL is not liable for indirect, incidental, special, consequential, or loss-of-profit damages arising from use of the service, food, fulfilment, payments, delivery, or disputes between Vendors and customers. You will defend and indemnify ZTEEL from third-party claims arising from your business, food, content, legal non-compliance, or breach of these Terms, except to the extent caused by ZTEEL’s own unlawful conduct.',
    ),
    _LegalSection(
      title: 'Changes, Governing Law & Contact',
      content:
          'We may update these Terms when the service, law, or our practices change. The revised version will be posted in the app with a new effective date; continued use after it takes effect means you accept it. These Terms are governed by the laws applicable in India, subject to mandatory consumer or local laws. For questions, contact support@zteel.com. Nothing in these Terms limits rights that cannot legally be excluded.',
    ),
  ];

  static const List<_LegalSection> _privacySections = [
    _LegalSection(
      title: 'Scope & Controller',
      content:
          'This Privacy Policy explains how ZTEEL handles personal and business information in the ZTEEL Vendor app and related platform services. ZTEEL is responsible for information it determines the purposes and means of processing. This policy does not replace any privacy notice supplied by map, app-store, operating-system, or communications providers that you use independently.',
    ),
    _LegalSection(
      title: 'Information We Collect',
      content:
          'We collect: (a) account information—your mobile number and, if you provide them, your name and email address; (b) business and storefront information—business name, address, description, operating hours, menu, prices, availability, offers, images, food tags, and map coordinates; (c) order and service information—order identifiers, status, items, quantities, totals, offer/reward details, timestamps, customer name supplied with the order, and reviews; (d) technical/session information—authentication tokens, device/app interaction required to maintain a signed-in session, and locally stored cache data; and (e) support messages or information you send to us.',
    ),
    _LegalSection(
      title: 'Why We Use Information',
      content:
          'We use information to create and secure vendor accounts; verify phone-based sign-in; set up and publish your shop; show your shop in customer discovery and maps; maintain menus, offers, hours, and availability; transmit, display, and reconcile orders; enable QR verification; provide notifications and in-app history; calculate vendor dashboard and performance information; respond to support requests; protect against fraud or misuse; and comply with legal obligations.',
    ),
    _LegalSection(
      title: 'Information Visible to Customers',
      content:
          'Information you enter for your storefront can be public to ZTEEL customers: business name, address, approximate or precise shop location, hours, shop description, images, menus, prices, availability, offers, food tags, ratings, and reviews. Your account phone number, authentication tokens, and private vendor session information are not intentionally displayed to customers through the storefront.',
    ),
    _LegalSection(
      title: 'Location Information',
      content:
          'The app requests location only when you choose a feature that uses it, such as setting or updating your shop location. You may instead search for or place the shop location on the map manually. We use the selected coordinates and address to locate your shop, show it on maps, and calculate customer-facing distance or discovery results. The app does not request background location access for continuous tracking.',
    ),
    _LegalSection(
      title: 'Camera, Photos & QR Codes',
      content:
          'Camera access is used to scan a customer order QR code when you choose to verify an order. Photo-library access is used only when you select a shop, cover, or menu image, or choose a QR image from your library. Images you choose for your storefront or menu are uploaded to the platform and may be publicly displayed as described above. We do not use the camera to record video or collect images in the background.',
    ),
    _LegalSection(
      title: 'Notifications',
      content:
          'With your permission, the app uses device notifications to alert you to new orders. A notification may include an order number and order total. You can decline or later disable notification permission in your device settings; in-app order information may remain available while you are signed in.',
    ),
    _LegalSection(
      title: 'Customer Information You Receive',
      content:
          'Vendors act independently when handling customer order information shown in the app. Use that information only for the relevant order and protect it from unauthorised access, disclosure, or marketing use. Do not add it to unrelated contact lists, use it to create customer profiles, or sell/share it. You are responsible for your own legal duties when you process customer information outside the platform.',
    ),
    _LegalSection(
      title: 'Sharing & Service Providers',
      content:
          'We share information only as needed to operate the service: with customers through your public storefront; with vendors for the orders placed with them; with hosting, database, security, communications, and support providers acting for ZTEEL; and with map providers. The app uses OpenStreetMap map tiles and may send a map search, address, or coordinates to Nominatim/OpenStreetMap to display, search for, or resolve a location. We may also disclose information where required by law, to protect rights or safety, or in connection with a business transfer. We do not sell or rent personal information or share it for third-party behavioural advertising.',
    ),
    _LegalSection(
      title: 'Storage & Security',
      content:
          'The app communicates with the production API over HTTPS. Authentication tokens are stored using the device’s secure-storage facility. The app’s offline cache is encrypted and scoped to the signed-in vendor; it is cleared on logout and protected from being shown to a different vendor on the same device. No security method is perfect, so please keep your device and OTP private and notify us of suspected misuse.',
    ),
    _LegalSection(
      title: 'Retention',
      content:
          'We retain information for as long as needed to provide the service, maintain accurate order and business records, resolve disputes, prevent fraud, meet legal, tax, accounting, food-safety, or regulatory obligations, and enforce our agreements. We then delete, anonymise, or securely isolate information as appropriate. Public-facing business content may remain visible until it is changed, removed, or the listing is disabled; order and transaction records may need to be retained even after account deletion where legally required or necessary for legitimate record-keeping.',
    ),
    _LegalSection(
      title: 'Your Choices & Rights',
      content:
          'You can review and correct much of your profile, location, hours, menu, images, and offers in the app. You can control camera, photo, location, and notification permissions in device settings. Depending on applicable law, you may request access, correction, deletion, restriction, objection, or a copy of your personal information by contacting support@zteel.com. We may need to verify your identity and may limit a request where law permits or requires us to do so.',
    ),
    _LegalSection(
      title: 'Account Deletion',
      content:
          'You can initiate deletion directly in the app: Help & Support → Delete Account. The deletion flow closes the account, ends access, removes the local signed-in session, and de-identifies account details such as the phone number and name in our account record. It does not require you to call or email support. We may retain or anonymise limited information where required or permitted for the retention purposes described above. If you need help with a deletion request, contact support@zteel.com.',
    ),
    _LegalSection(
      title: 'Children, International Processing & Updates',
      content:
          'ZTEEL Vendor is a business-facing app and is not directed to children. Do not use it or submit personal information if you are below the age at which you can lawfully enter this agreement. Information may be processed in locations where ZTEEL or its service providers operate, with safeguards appropriate to the transfer. We may update this Policy and will post the revised version in the app with a new effective date. For privacy questions or complaints, contact support@zteel.com.',
    ),
  ];

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

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}
