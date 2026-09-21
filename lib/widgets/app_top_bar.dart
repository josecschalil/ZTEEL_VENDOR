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
        (widget.isDark ? AppColors.transparent : AppColors.surface);
    final titleColor =
        widget.isDark ? AppColors.textWhite : AppColors.textPrimary;
    final subtitleColor =
        widget.isDark ? AppColors.textInverse.withValues(alpha: 0.72) : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: widget.showBorder && !widget.isDark
            ? const Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.8),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            // ── Left: Leading widget / Back button / Brand Avatar ──
            _buildLeading(context),
            const SizedBox(width: 10),

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
                      fontSize: widget.showBackButton ? 17 : 16,
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
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  border:
                      Border.all(color: AppColors.primaryBorder, width: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.badgeText!,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
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
              const SizedBox(width: 8),
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
      return Semantics(
        button: true,
        label: 'Back',
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: widget.onBack ?? () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(AppRadii.medium),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.black.withValues(alpha: 0.35)
                    : AppColors.surfaceRaised,
                border: Border.all(
                  color: widget.isDark ? AppColors.transparent : AppColors.divider,
                  width: 0.8,
                ),
                borderRadius: BorderRadius.circular(AppRadii.medium),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: widget.isDark
                    ? AppColors.textWhite
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),
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
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(color: AppColors.divider, width: 1),
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
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadii.medium),
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
    final statusColor = isOpen ? AppColors.success : AppColors.danger;
    final bgColor = isOpen ? AppColors.successDim : AppColors.dangerTint;
    final borderColor = isOpen ? AppColors.successBorder : AppColors.danger.withValues(alpha: 0.3);
    final label = isOpen ? 'OPEN' : 'CLOSED';

    final pill = AnimatedBuilder(
      animation: _pulseAc,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 0.8),
          borderRadius: BorderRadius.circular(AppRadii.pill),
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

    return Semantics(
      button: true,
      label: isOpen ? 'Shop open. Change status' : 'Shop closed. Change status',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showStatusConfirmDialog(context),
        child: pill,
      ),
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
                    ? AppColors.dangerTint
                    : AppColors.greenDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isOpen
                    ? Icons.storefront_outlined
                    : Icons.store_rounded,
                color: isOpen
                    ? AppColors.danger
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
                  isOpen ? AppColors.danger : AppColors.success,
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
    return Semantics(
      button: true,
      label: count > 0 ? '$count notifications' : 'Notifications',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: widget.onNotificationTap,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.black.withValues(alpha: 0.35)
                      : AppColors.surfaceRaised,
                  border: Border.all(
                    color: widget.isDark
                        ? AppColors.transparent
                        : AppColors.divider,
                    width: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: widget.isDark
                      ? AppColors.textWhite
                      : AppColors.textSecondary,
                  size: 20,
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
                      color: AppColors.primaryDark,
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
        ),
      ),
    );
  }
}
