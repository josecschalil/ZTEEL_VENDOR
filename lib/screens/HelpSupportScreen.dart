import 'package:flutter/material.dart';
import 'package:frontend/app_colors.dart';

class SupportTicket {
  final String id;
  final String subject;
  final String status;
  final String date;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.date,
  });
}

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});
}

/// Vendor-facing copy of the customer Help & Support experience.
/// Ticket and chat integrations can replace the local action sheets later.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const List<SupportTicket> _tickets = [
    SupportTicket(
      id: 'TCK-1042',
      subject: 'Question about an offer promotion',
      status: 'In Progress',
      date: 'Aug 21, 2026',
    ),
    SupportTicket(
      id: 'TCK-1031',
      subject: 'Help updating shop hours',
      status: 'Resolved',
      date: 'Aug 12, 2026',
    ),
  ];

  static const List<FaqItem> _faqs = [
    FaqItem(
      question: 'Who will answer my support request?',
      answer:
          'Help & Support connects you with the ZTEEL app team. For a customer-specific order question, use the order details page to review the order first.',
    ),
    FaqItem(
      question: 'How long does a support ticket take to get a reply?',
      answer:
          'Most tickets receive a first response within one business day. You can review any open ticket from this screen.',
    ),
    FaqItem(
      question: 'Can I get help with offers or shop availability?',
      answer:
          'Yes. Choose Raise a Ticket and include the promotion or availability issue, together with any relevant order details.',
    ),
    FaqItem(
      question: 'How do I report a bug with a screenshot?',
      answer:
          'Raise a ticket, select Bug Report, and describe the steps that led to the issue. You can provide the screenshot when support follows up.',
    ),
  ];

  int? _expandedFaqIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: _buildTopBar(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('My Tickets'),
                    const SizedBox(height: 12),
                    _buildTicketsCard(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Frequently Asked Questions'),
                    const SizedBox(height: 12),
                    _buildFaqCard(),
                    const SizedBox(height: 24),
                    _buildFooterCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.orange,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help & Support',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Talk to the ZTEEL team about your shop.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) => Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.chat_bubble_rounded,
            label: 'Live Chat',
            accent: AppColors.orange,
            tint: AppColors.orangeDim,
            onTap: () => _showActionSheet(
              title: 'Live chat',
              message:
                  'Live chat is available daily from 9 AM to 9 PM. Outside those hours, leave a ticket and the team will follow up.',
              icon: Icons.chat_bubble_rounded,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.confirmation_number_rounded,
            label: 'Raise a\nTicket',
            accent: AppColors.gold,
            tint: const Color(0x1AC4922E),
            onTap: _showTicketSheet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.mail_rounded,
            label: 'Email Us',
            accent: AppColors.green,
            tint: AppColors.greenDim,
            onTap: () => _showActionSheet(
              title: 'Email the ZTEEL team',
              message:
                  'support@zteel.app\n\nWe usually reply within one business day.',
              icon: Icons.mail_rounded,
            ),
          ),
        ),
      ],
    );
  }

  void _showActionSheet({
    required String title,
    required String message,
    required IconData icon,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Icon(icon, color: AppColors.orange, size: 24),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showTicketSheet() {
    final subjectController = TextEditingController();
    final detailController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Raise a ticket',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            _sheetField(subjectController, 'Subject'),
            const SizedBox(height: 10),
            _sheetField(detailController, 'Describe the issue', maxLines: 4),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (subjectController.text.trim().isEmpty ||
                      detailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Add a subject and description first.'),
                    ));
                    return;
                  }
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Ticket saved. Support will follow up soon.'),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.textOnAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Submit ticket',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      subjectController.dispose();
      detailController.dispose();
    });
  }

  Widget _sheetField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildTicketsCard() => _surfaceCard(
        Column(
          children: List.generate(_tickets.length, (index) {
            final ticket = _tickets[index];
            return Column(
              children: [
                _buildTicketRow(ticket),
                if (index != _tickets.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            );
          }),
        ),
      );

  Widget _buildTicketRow(SupportTicket ticket) {
    final colors = switch (ticket.status) {
      'Resolved' => (AppColors.green, AppColors.greenDim, AppColors.greenBorder),
      'In Progress' =>
        (AppColors.gold, const Color(0x1AC4922E), const Color(0x40C4922E)),
      _ => (AppColors.orange, AppColors.orangeDim, AppColors.orangeBorder),
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.id,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6)),
                const SizedBox(height: 4),
                Text(ticket.subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(ticket.date,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.$2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.$3),
            ),
            child: Text(ticket.status,
                style: TextStyle(
                    color: colors.$1,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard() => _surfaceCard(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            children: List.generate(_faqs.length, (index) {
              final expanded = _expandedFaqIndex == index;
              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(
                        () => _expandedFaqIndex = expanded ? null : index),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(_faqs[index].question,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 10),
                              AnimatedRotation(
                                turns: expanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.orange,
                                    size: 20),
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 200),
                            crossFadeState: expanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: const SizedBox(width: double.infinity),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(_faqs[index].answer,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index != _faqs.length - 1)
                    const Divider(
                        color: AppColors.border,
                        height: 1,
                        indent: 14,
                        endIndent: 14),
                ],
              );
            }),
          ),
        ),
      );

  Widget _surfaceCard(Widget child) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  Widget _buildFooterCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.orangeTint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.orangeBorder),
        ),
        child: const Row(
          children: [
            _SupportIcon(),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Still stuck? Raise a ticket and our team will follow up directly.',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4),
              ),
            ),
          ],
        ),
      );
}

class _SupportIcon extends StatelessWidget {
  const _SupportIcon();

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.support_agent_rounded,
            color: AppColors.textOnAccent, size: 20),
      );
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.accent,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: tint, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(height: 10),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2)),
            ],
          ),
        ),
      );
}
