import 'package:flutter/material.dart';
import 'package:frontend/app_colors.dart';

/// A standardized top bar widget for the ZTEEL_VENDOR app.
/// Supports both main root views (with branding, live status, and notification bell)
/// and nested/detail views (with back button, title, badges, and trailing actions).
class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
  /// Title of the top bar. Defaults to 'Zteeel Vendor' if omitted in brand mode.
  final String? title;

  /// Optional subtitle shown below the title.
  final String? subtitle;

  /// Whether to show a back button on the left. If false, shows the brand icon/avatar.
  final bool showBackButton;

  /// Custom back button callback. Defaults to `Navigator.maybePop(context)`.
  final VoidCallback? onBack;

  /// Optional custom leading widget. Overrides default brand avatar / back button.
  final Widget? leading;

  /// Optional image URL for the brand avatar.
  final String? avatarUrl;

  /// Optional icon to display in the brand avatar box.
  final IconData? avatarIcon;

  /// Whether to show the interactive 'OPEN'/'CLOSED' status pill.
  final bool showStatusBadge;

  /// Whether the shop is currently open. Controls label and colour automatically.
  /// When [onStatusToggle] is provided, tapping the pill shows a confirmation
  /// dialog and calls [onStatusToggle] with the desired new state on confirm.
  final bool isOpen;

  /// Called when the user confirms a status change. Receives the new open state.
  /// If null, the pill is display-only (no tap interaction).
  final ValueChanged<bool>? onStatusToggle;

  /// Optional notification badge count. If null or <= 0, badge is not shown.
  final int? notificationCount;

  /// Callback when notification button is tapped.
  final VoidCallback? onNotificationTap;

  /// Optional badge text to display beside the title (e.g. "12 items").
  final String? badgeText;

  /// List of custom trailing widgets.
  final List<Widget>? trailing;

  /// Background color override.
  final Color? backgroundColor;

  /// Whether to render a bottom border line.
  final bool showBorder;

  /// Whether to use dark mode styling (for camera/dark overlays).
  final bool isDark;

  const AppTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBack,
    this.leading,
    this.avatarUrl,
    this.avatarIcon,
    this.showStatusBadge = false,
    this.isOpen = true,
    this.onStatusToggle,
    this.notificationCount,
    this.onNotificationTap,
    this.badgeText,
    this.trailing,
    this.backgroundColor,
    this.showBorder = true,
    this.isDark = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAc;

  @override
  void initState() {
    super.initState();
    _pulseAc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.showStatusBadge && widget.isOpen) {
      _pulseAc.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AppTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldPulse = widget.showStatusBadge && widget.isOpen;
    if (shouldPulse && !_pulseAc.isAnimating) {
      _pulseAc.repeat(reverse: true);
    } else if (!shouldPulse && _pulseAc.isAnimating) {
      _pulseAc.stop();
      _pulseAc.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseAc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ??
        (widget.isDark ? AppColors.transparent : AppColors.bg);
    final titleColor =
        widget.isDark ? AppColors.textWhite : AppColors.textPrimary;
    final subtitleColor =
        widget.isDark ? const Color(0xFFCBD5E1) : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: widget.showBorder && !widget.isDark
            ? const Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              )
            : null,
        boxShadow: widget.showBorder && !widget.isDark
            ? [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            // ── Left: Leading widget / Back button / Brand Avatar ──
            _buildLeading(context),
            const SizedBox(width: 12),

            // ── Center: Title & Subtitle ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title ?? (widget.showBackButton ? '' : 'Zteeel Vendor'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: widget.showBackButton ? 17 : 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Optional Badge Chip (e.g. "12 items") ──
            if (widget.badgeText != null && widget.badgeText!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orangeDim,
                  border:
                      Border.all(color: AppColors.orangeBorder, width: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.badgeText!,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],

            // ── Right: Status badge ──
            if (widget.showStatusBadge) ...[
              const SizedBox(width: 8),
              _buildStatusBadge(),
            ],

            // ── Right: Notification Icon ──
            if (widget.notificationCount != null) ...[
              const SizedBox(width: 10),
              _buildNotificationButton(context),
            ],

            // ── Right: Custom Trailing Widgets ──
            if (widget.trailing != null && widget.trailing!.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (widget.leading != null) {
      return widget.leading!;
    }

    if (widget.showBackButton) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onBack ?? () => Navigator.maybePop(context),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.black.withValues(alpha: 0.35)
                : AppColors.surfaceRaised,
            border: Border.all(
              color: widget.isDark ? Colors.transparent : AppColors.border,
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: widget.isDark
                ? AppColors.textWhite
                : AppColors.textSecondary,
            size: 15,
          ),
        ),
      );
    }

    // Default: Brand avatar / icon
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          image: DecorationImage(
            image: NetworkImage(widget.avatarUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF5A4C), Color(0xFFE87722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        widget.avatarIcon ?? Icons.local_fire_department_rounded,
        color: AppColors.textWhite,
        size: 22,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isOpen = widget.isOpen;
    final statusColor = isOpen ? AppColors.green : const Color(0xFFE05252);
    final bgColor = isOpen ? AppColors.greenDim : const Color(0xFFFFEDED);
    final borderColor = isOpen ? AppColors.greenBorder : const Color(0xFFF5ACAC);
    final label = isOpen ? 'OPEN' : 'CLOSED';

    final pill = AnimatedBuilder(
      animation: _pulseAc,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isOpen
                    ? statusColor.withValues(alpha: 0.5 + 0.5 * _pulseAc.value)
                    : statusColor.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: isOpen
                    ? [
                        BoxShadow(
                          color: statusColor
                              .withValues(alpha: 0.45 * _pulseAc.value),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
            if (widget.onStatusToggle != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: statusColor.withValues(alpha: 0.7),
                size: 13,
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.onStatusToggle == null) return pill;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showStatusConfirmDialog(context),
      child: pill,
    );
  }

  Future<void> _showStatusConfirmDialog(BuildContext context) async {
    final isOpen = widget.isOpen;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isOpen
                    ? const Color(0xFFFFEDED)
                    : AppColors.greenDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isOpen
                    ? Icons.storefront_outlined
                    : Icons.store_rounded,
                color: isOpen
                    ? const Color(0xFFE05252)
                    : AppColors.green,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOpen ? 'Close Shop?' : 'Open Shop?',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isOpen
              ? 'Customers will not be able to place new orders while your shop is closed.'
              : 'Your shop will be visible and open for new orders.',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 6),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  isOpen ? const Color(0xFFE05252) : AppColors.green,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isOpen ? 'Mark Closed' : 'Open Shop',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onStatusToggle != null) {
      widget.onStatusToggle!(!isOpen);
    }
  }

  Widget _buildNotificationButton(BuildContext context) {
    final count = widget.notificationCount ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onNotificationTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : AppColors.surfaceRaised,
              border: Border.all(
                color: widget.isDark ? Colors.transparent : AppColors.border,
                width: 0.8,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: widget.isDark
                  ? AppColors.textWhite
                  : AppColors.textSecondary,
              size: 19,
            ),
          ),
          if (count > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
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
