import 'package:flutter/material.dart';

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  // Target Selection
  int _targetTab = 0; // 0=Items, 1=Categories, 2=All Menu

  // Offer Type
  int _offerType = 0; // 0=Percentage Discount, 1=Special Fixed Price

  // Validity
  String _startTime = '18:00';
  String _endTime = '23:00';
  final List<bool> _days = [
    true,
    false,
    true,
    false,
    true,
    true,
    false
  ]; // M T W T F S S

  // Colors
  static const Color bgDark = Color(0xFF1A0E0A);
  static const Color cardBg = Color(0xFF251510);
  static const Color orange = Color(0xFFE8622A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9E7E72);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildTopBar(),
                    const SizedBox(height: 28),
                    _buildPageHeader(),
                    const SizedBox(height: 28),
                    _buildTargetSelectionCard(),
                    const SizedBox(height: 16),
                    _buildOfferTypeCard(),
                    const SizedBox(height: 16),
                    _buildValidityCard(),
                    const SizedBox(height: 28),
                    _buildSaveButton(),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Changes will be visible to customers immediately after\nsaving.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: textGrey, fontSize: 12, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        // Logo
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          'SAFFRON BISTRO',
          style: TextStyle(
            color: textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        const Icon(Icons.notifications_outlined, color: textWhite, size: 26),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF3D2010),
          backgroundImage: NetworkImage(
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
          ),
        ),
      ],
    );
  }

  // ── Page Header ──────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit, color: orange, size: 14),
            const SizedBox(width: 6),
            Text(
              'OFFER MANAGEMENT',
              style: TextStyle(
                color: orange,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Create New Offer',
          style: TextStyle(
            color: textWhite,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Design an irresistible promotional experience for\nyour premium clientele.',
          style: TextStyle(color: textGrey, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  // ── Target Selection Card ────────────────────────────────────
  Widget _buildTargetSelectionCard() {
    final tabs = ['Items', 'Categories', 'All Menu'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(Icons.track_changes, color: orange, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Target Selection',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tabs
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(tabs.length, (i) {
              final selected = _targetTab == i;
              return GestureDetector(
                onTap: () => setState(() => _targetTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? orange : const Color(0xFF3A2015),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        tabs[i],
                        style: TextStyle(
                          color: selected ? Colors.white : textGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Selected item card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0E0A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=150',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: const Color(0xFF3A2015),
                      child:
                          const Icon(Icons.restaurant, color: orange, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saffron Glazed Salmon',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Signature Main • \$28.00',
                        style: TextStyle(color: textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.close, color: orange, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Offer Type Card ──────────────────────────────────────────
  Widget _buildOfferTypeCard() {
    final types = [
      {
        'title': 'Percentage Discount',
        'sub': 'BEST FOR HIGH-VOLUME ITEMS',
      },
      {
        'title': 'Special Fixed Price',
        'sub': 'EXCLUSIVE MEMBERSHIP PRICING',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_outlined, color: orange, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Offer Type',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(types.length, (i) {
            final selected = _offerType == i;
            return Padding(
              padding: EdgeInsets.only(bottom: i < types.length - 1 ? 12 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _offerType = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1A0E0A)
                        : const Color(0xFF2A1810),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? orange : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              types[i]['title']!,
                              style: const TextStyle(
                                color: textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              types[i]['sub']!,
                              style: TextStyle(
                                color: textGrey,
                                fontSize: 11,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? orange : textGrey,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: orange,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Validity Card ────────────────────────────────────────────
  Widget _buildValidityCard() {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final startTimes = ['16:00', '17:00', '18:00', '19:00', '20:00'];
    final endTimes = ['21:00', '22:00', '23:00', '00:00', '01:00'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: orange, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Validity',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Time pickers row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START TIME',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _timeDropdown(_startTime, startTimes, (v) {
                      if (v != null) setState(() => _startTime = v);
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'END TIME',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _timeDropdown(_endTime, endTimes, (v) {
                      if (v != null) setState(() => _endTime = v);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Recurrence
          Text(
            'RECURRENCE',
            style: TextStyle(
              color: textGrey,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final selected = _days[i];
              return GestureDetector(
                onTap: () => setState(() => _days[i] = !_days[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? orange : const Color(0xFF3A2015),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayLabels[i],
                    style: TextStyle(
                      color: selected ? Colors.white : textGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _timeDropdown(
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E0A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        onChanged: onChanged,
        isExpanded: true,
        dropdownColor: const Color(0xFF251510),
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: textGrey, size: 20),
        style: const TextStyle(
          color: textWhite,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        items: items.map((t) {
          return DropdownMenuItem(
            value: t,
            child: Text(t),
          );
        }).toList(),
      ),
    );
  }

  // ── Save Button ──────────────────────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: orange,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Text(
          'SAVE OFFER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────
}
