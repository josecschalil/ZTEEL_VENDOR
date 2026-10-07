import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/services/vendor_notification_service.dart';

class NotifColors {
  static const primary = Color(0xFFEE5B2B);
  static const backgroundLight = Color(0xFFFAFAFC);
  static const backgroundDark = Color(0xFF1E1714);
  static const cardLight = Colors.white;
  static const cardDark = Color(0xFF281E19);
  static const borderLight = Color(0xFFF0F0F3);
  static const borderDark = Color(0xFF3D2B23);
  static const mutedTextLight = Color(0xFF8A8A9A);
  static const mutedTextDark = Color(0xFFC9A092);
}

/// ---------------------------------------------------------------------
/// Data model
/// ---------------------------------------------------------------------
enum NotifType { order, promo, reward, account }

class NotifIconStyle {
  final IconData icon;
  final Color color;
  const NotifIconStyle(this.icon, this.color);
}

const _typeStyles = {
  NotifType.order: NotifIconStyle(Icons.receipt_long, Color(0xFF3B82F6)),
  NotifType.promo: NotifIconStyle(
    Icons.local_fire_department,
    NotifColors.primary,
  ),
  NotifType.reward: NotifIconStyle(Icons.card_giftcard, Color(0xFF22C55E)),
  NotifType.account: NotifIconStyle(Icons.person, Color(0xFFA855F7)),
};

class NotifItem {
  final String id;
  final NotifType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? orderId;
  bool read;
  NotifItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.orderId,
    this.read = false,
  });
}

class NotifSection {
  final String label;
  final List<NotifItem> items;
  NotifSection({required this.label, required this.items});
}

/// ---------------------------------------------------------------------
/// Main screen
/// ---------------------------------------------------------------------
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotifItem> _items = <NotifItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    VendorNotificationService.notifications.addListener(_syncFromInbox);
    unawaited(_load());
  }

  @override
  void dispose() {
    VendorNotificationService.notifications.removeListener(_syncFromInbox);
    super.dispose();
  }

  Future<void> _load() async {
    await VendorNotificationService.initialize();
    await VendorNotificationService.reload();
    if (mounted) setState(() => _loading = false);
  }

  void _syncFromInbox() {
    if (!mounted) return;
    setState(() {
      _items = VendorNotificationService.notifications.value
          .map(_toNotifItem)
          .toList();
      _loading = false;
    });
  }

  NotifItem _toNotifItem(VendorNotification item) => NotifItem(
        id: item.id,
        type: switch (item.type) {
          'order' => NotifType.order,
          'promo' => NotifType.promo,
          'reward' => NotifType.reward,
          _ => NotifType.account,
        },
        title: item.title,
        message: item.message,
        createdAt: item.createdAt,
        orderId: item.orderId,
        read: item.read,
      );

  List<NotifSection> get _sections {
    final today = <NotifItem>[];
    final yesterday = <NotifItem>[];
    final thisWeek = <NotifItem>[];
    final earlier = <NotifItem>[];
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    final startOfWeek = startOfToday.subtract(Duration(days: startOfToday.weekday - 1));

    for (final item in _items) {
      if (!item.createdAt.isBefore(startOfToday)) {
        today.add(item);
      } else if (!item.createdAt.isBefore(startOfYesterday)) {
        yesterday.add(item);
      } else if (!item.createdAt.isBefore(startOfWeek)) {
        thisWeek.add(item);
      } else {
        earlier.add(item);
      }
    }
    return [
      NotifSection(label: 'Today', items: today),
      NotifSection(label: 'Yesterday', items: yesterday),
      NotifSection(label: 'This Week', items: thisWeek),
      NotifSection(label: 'Earlier', items: earlier),
    ];
  }

  int get _unreadCount =>
      _sections.expand((s) => s.items).where((i) => !i.read).length;

  void _markAllRead() {
    unawaited(VendorNotificationService.markAllRead());
  }

  void _dismiss(NotifItem item) {
    unawaited(VendorNotificationService.dismiss(item.id));
  }

  void _toggleRead(NotifItem item) {
    if (!item.read) unawaited(VendorNotificationService.markRead(item.id));
    VendorNotificationService.openOrder(item.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAny = _items.isNotEmpty;
    final bgColor = isDark ? NotifColors.backgroundDark : NotifColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              isDark: isDark,
              unreadCount: _unreadCount,
              onMarkAllRead: _markAllRead,
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : hasAny
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        for (final section in _sections)
                          if (section.items.isNotEmpty)
                            _NotifSectionWidget(
                              isDark: isDark,
                              section: section,
                              onDismiss: _dismiss,
                              onTap: _toggleRead,
                            ),
                      ],
                    )
                  : _EmptyState(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Header
/// ---------------------------------------------------------------------
class _Header extends StatelessWidget {
  final bool isDark;
  final int unreadCount;
  final VoidCallback onMarkAllRead;
  const _Header({
    required this.isDark,
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? NotifColors.backgroundDark : NotifColors.backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF1D1E20);
    final borderColor = isDark ? NotifColors.borderDark : NotifColors.borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: textColor,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: NotifColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 38,
            height: 38,
            child: unreadCount > 0
                ? IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: onMarkAllRead,
                    icon: const Icon(
                      Icons.done_all,
                      color: NotifColors.primary,
                      size: 20,
                    ),
                    tooltip: 'Mark all as read',
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Section: label + list of notification cards
/// ---------------------------------------------------------------------
class _NotifSectionWidget extends StatelessWidget {
  final bool isDark;
  final NotifSection section;
  final ValueChanged<NotifItem> onDismiss;
  final ValueChanged<NotifItem> onTap;
  const _NotifSectionWidget({
    required this.isDark,
    required this.section,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFF8A8A9A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            section.label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: labelColor,
              letterSpacing: 1.6,
            ),
          ),
        ),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => onDismiss(item),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
              child: _NotifCard(
                isDark: isDark,
                item: item,
                onTap: () => onTap(item),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// A single notification card
/// ---------------------------------------------------------------------
class _NotifCard extends StatelessWidget {
  final bool isDark;
  final NotifItem item;
  final VoidCallback onTap;
  const _NotifCard({
    required this.isDark,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _typeStyles[item.type]!;
    final cardBg = isDark ? NotifColors.cardDark : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1D1E20);
    final messageColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF8A8A9A);
    final timeColor = isDark ? NotifColors.mutedTextDark : NotifColors.mutedTextLight;
    final borderColor = item.read
        ? (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : NotifColors.borderLight)
        : NotifColors.primary.withValues(alpha: 0.25);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (!item.read)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: NotifColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: messageColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(item.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: timeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime dateTime) {
  final elapsed = DateTime.now().difference(dateTime);
  if (elapsed.inMinutes < 1) return 'Just now';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
  if (elapsed.inDays < 1) return '${elapsed.inHours}h ago';
  if (elapsed.inDays == 1) return 'Yesterday';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

/// ---------------------------------------------------------------------
/// Empty state
/// ---------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1D1E20);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF8A8A9A);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: NotifColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                color: NotifColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You're all caught up",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New deals, order updates, and rewards will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: subtextColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
