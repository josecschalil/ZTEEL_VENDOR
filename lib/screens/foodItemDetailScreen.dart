import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/screens/editFoodItemScreen.dart';
import 'package:frontend/services/vendor_service.dart';

/// Reimagined vendor food-item detail screen — take two.
///
/// This throws out the "scroll past a hero photo" layout entirely and
/// builds the page around three ideas instead:
///
/// 1. A dark hero band (same ink/rounded-bottom language as the app's
///    top bar) that carries the name, category, live price and status
///    directly, with a large product photo anchored on the right —
///    and it now scrolls away with the rest of the page instead of
///    staying pinned.
/// 2. A single floating card that straddles the seam between the hero
///    and the light canvas. It holds a small item photo and the
///    availability switch together, because "is this live right now"
///    is the one control a vendor actually needs at a glance.
/// 3. A horizontal stat strip (price / category / diet) instead of a
///    stacked fact list, plus a floating pill action bar instead of an
///    edge-to-edge toolbar — so nothing on the page reads as a plain
///    list of rows.
///
/// Palette, radii, typography scale and interaction language (emerald
/// = live/positive, dark slate = primary, red = destructive only) are
/// unchanged from the rest of the app.
class FoodItemDetailScreen extends StatefulWidget {
  final String itemId;
  final String itemName;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final String categoryName;
  final bool isAvailable;
  final bool isVeg;
  final bool isBestseller;

  const FoodItemDetailScreen({
    super.key,
    this.itemId = '',
    required this.itemName,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.categoryId = '',
    required this.categoryName,
    required this.isAvailable,
    required this.isVeg,
    required this.isBestseller,
  });

  @override
  State<FoodItemDetailScreen> createState() => _FoodItemDetailScreenState();
}

class _FoodItemDetailScreenState extends State<FoodItemDetailScreen> {
  bool _isAvailable = false;
  bool _hasChanged = false;
  bool _updatingAvailability = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.isAvailable;
  }

  Future<void> _toggleAvailability() async {
    if (widget.itemId.isEmpty || _updatingAvailability) return;

    final nextValue = !_isAvailable;

    setState(() => _updatingAvailability = true);
    HapticFeedback.selectionClick();

    final res = await VendorService.updateMenuItem(
      id: widget.itemId,
      isAvailable: nextValue,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _isAvailable = nextValue;
        _hasChanged = true;
        _updatingAvailability = false;
      });

      HapticFeedback.mediumImpact();
      _showMessage(
        nextValue ? 'Item is now live on your menu' : 'Item has been hidden',
        positive: nextValue,
      );
    } else {
      setState(() => _updatingAvailability = false);
      _showMessage(
        res['error'] ?? 'Could not update item availability',
        positive: false,
      );
    }
  }

  Future<void> _editItem() async {
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditFoodItemScreen(
          itemId: widget.itemId,
          initialCategoryId: widget.categoryId,
          initialName: widget.itemName,
          initialPrice: widget.price,
          initialDescription: widget.description,
          initialIsVeg: widget.isVeg,
          initialIsAvailable: _isAvailable,
          initialImageUrl: widget.imageUrl,
        ),
      ),
    );

    if (updated == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteItem() async {
    if (widget.itemId.isEmpty || _deleting) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DeleteSheet(itemName: widget.itemName),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);

    final res = await VendorService.deleteMenuItem(widget.itemId);

    if (!mounted) return;

    if (res['success'] == true) {
      _showMessage('“${widget.itemName}” was deleted', positive: true);
      Navigator.of(context).pop(true);
    } else {
      setState(() => _deleting = false);
      _showMessage(
        res['error'] ?? 'Could not delete this item',
        positive: false,
      );
    }
  }

  void _showMessage(String message, {required bool positive}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          elevation: 0,
          backgroundColor: positive ? _C.dark : const Color(0xFF7F1D1D),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(
                positive
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                color: positive ? _C.emeraldLight : const Color(0xFFFCA5A5),
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _showMoreActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _C.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionSheetButton(
                  icon: Icons.edit_outlined,
                  title: 'Edit item',
                  subtitle: 'Change name, price, image or details',
                  onTap: () {
                    Navigator.pop(context);
                    _editItem();
                  },
                ),
                const SizedBox(height: 8),
                _ActionSheetButton(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete item',
                  subtitle: 'Permanently remove this menu item',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteItem();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Everything — including the hero band — now lives inside a single
    // scroll view, so the topbar scrolls away with the rest of the page
    // instead of staying pinned above an inner Expanded scroll area.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {},
        child: Scaffold(
          backgroundColor: _C.bg,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(),
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverlapCard(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatStrip(),
                            if (VendorService.cleanDescription(
                                    widget.description)
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildAbout(),
                            ],
                            const SizedBox(height: 22),
                            _buildLabels(),
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildFloatingActionBar(),
        ),
      ),
    );
  }

  // ─── Hero band ───────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _C.dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeroIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.maybePop(context, _hasChanged),
                  ),
                  const Spacer(),
                  if (widget.itemId.isNotEmpty)
                    _HeroIconButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: _showMoreActions,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              // Name / price on the left, large product photo on the right.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _C.emeraldLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.itemName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.7,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${widget.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _StatusPill(isAvailable: _isAvailable),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _buildHeroImage(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Large product photo anchored to the right side of the hero band.
  Widget _buildHeroImage() {
    final hasImage = widget.imageUrl.trim().isNotEmpty;

    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.restaurant_rounded,
                color: Colors.white54,
                size: 30,
              ),
            )
          else
            const Icon(
              Icons.restaurant_rounded,
              color: Colors.white54,
              size: 30,
            ),
          if (widget.isBestseller)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: _C.amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded,
                    color: Colors.white, size: 13),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Overlap card (photo + availability control) ─────────────────
  Widget _buildOverlapCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildThumbnail(),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'Live on menu' : 'Hidden from menu',
                  style: TextStyle(
                    color: _isAvailable ? _C.textPrimary : _C.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isAvailable
                      ? 'Customers can order this now'
                      : 'Customers cannot see this item',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _C.textMuted,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleAvailability,
            child: _MiniSwitch(
              value: _isAvailable,
              loading: _updatingAvailability,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final hasImage = widget.imageUrl.trim().isNotEmpty;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _C.raised,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.restaurant_rounded,
                color: _C.textMuted,
                size: 22,
              ),
            )
          else
            const Icon(
              Icons.restaurant_rounded,
              color: _C.textMuted,
              size: 22,
            ),
          if (widget.isBestseller)
            Positioned(
              right: 3,
              top: 3,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: _C.amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded,
                    color: Colors.white, size: 11),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Stat strip ───────────────────────────────────────────────────
  Widget _buildStatStrip() {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.sell_rounded,
              iconColor: _C.emerald,
              iconBackground: _C.emeraldBg,
              label: 'Price',
              value: '\$${widget.price.toStringAsFixed(2)}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.folder_rounded,
              iconColor: _C.textSecondary,
              iconBackground: _C.raised,
              label: 'Category',
              value: widget.categoryName,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: widget.isVeg ? Icons.eco_rounded : Icons.restaurant_rounded,
              iconColor: widget.isVeg ? _C.emerald : _C.red,
              iconBackground: widget.isVeg ? _C.emeraldBg : _C.redBg,
              label: 'Dietary',
              value: widget.isVeg ? 'Veg' : 'Non-veg',
            ),
          ),
        ],
      ),
    );
  }

  // ─── About ─────────────────────────────────────────────────────────
  Widget _buildAbout() {
    final cleaned = VendorService.cleanDescription(widget.description).trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('ABOUT THIS ITEM'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Text(
            cleaned,
            style: const TextStyle(
              color: _C.textSecondary,
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Labels ─────────────────────────────────────────────────────────
  Widget _buildLabels() {
    final chips = <Widget>[
      _LabelChip(
        icon: widget.isVeg ? Icons.eco_rounded : Icons.restaurant_rounded,
        label: widget.isVeg ? 'Vegetarian' : 'Non-vegetarian',
        color: widget.isVeg ? _C.emerald : _C.red,
      ),
      if (widget.isBestseller)
        _LabelChip(
          icon: Icons.star_rounded,
          label: 'Bestseller',
          color: _C.amber,
        ),
      _LabelChip(
        icon: _isAvailable
            ? Icons.visibility_rounded
            : Icons.visibility_off_rounded,
        label: _isAvailable ? 'Visible to customers' : 'Hidden currently',
        color: _isAvailable ? _C.emerald : _C.textMuted,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('MENU LABELS'),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  // ─── Floating action bar ─────────────────────────────────────────

  // ─── Floating action bar ─────────────────────────────────────────
  Widget _buildFloatingActionBar() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        child: Container(
          height: 58,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(29),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _PillButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                filled: false,
                onTap: _editItem,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _PillButton(
                  icon: _isAvailable
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  label: _isAvailable ? 'Hide item' : 'Make item live',
                  filled: true,
                  loading: _updatingAvailability,
                  expand: true,
                  onTap: _toggleAvailability,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small reusable pieces ───────────────────────────────────────────

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isAvailable;

  const _StatusPill({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable
            ? _C.emerald.withValues(alpha: .94)
            : Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'LIVE' : 'HIDDEN',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  final bool value;
  final bool loading;

  const _MiniSwitch({required this.value, required this.loading});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 47,
      height: 27,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? _C.emerald : _C.borderMid,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 21,
          height: 21,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(5),
                  child: CircularProgressIndicator(
                    strokeWidth: 1.7,
                    color: _C.textSecondary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _C.textMuted,
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.15,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _C.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _C.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _LabelChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _C.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final bool expand;
  final bool loading;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.filled,
    this.expand = false,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled ? _C.dark : Colors.transparent;
    final foreground = filled ? Colors.white : _C.textPrimary;

    final content = loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: filled ? _C.emeraldLight : foreground, size: 17),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );

    final button = Material(
      color: background,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    return expand ? button : SizedBox(width: 92, child: button);
  }
}

// ─── Bottom sheets ───────────────────────────────────────────────────

class _DeleteSheet extends StatelessWidget {
  final String itemName;

  const _DeleteSheet({required this.itemName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        MediaQuery.of(context).padding.bottom + 18,
      ),
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: _C.borderMid,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _C.redBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: _C.red, size: 22),
          ),
          const SizedBox(height: 14),
          const Text(
            'Delete this item?',
            style: TextStyle(
              color: _C.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '“$itemName” will be permanently removed from your menu. '
            'This action cannot be undone.',
            style: const TextStyle(
              color: _C.textSecondary,
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: 'Keep item',
                  filled: false,
                  onTap: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetButton(
                  label: 'Delete',
                  filled: true,
                  destructive: true,
                  onTap: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool destructive;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.filled,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = destructive ? _C.red : (filled ? _C.dark : _C.surface);
    final foreground = destructive || filled ? Colors.white : _C.textPrimary;

    return SizedBox(
      height: 48,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:
                  !filled && !destructive ? Border.all(color: _C.border) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionSheetButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionSheetButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? _C.red : _C.textPrimary;
    final background = destructive ? _C.redBg : _C.raised;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      destructive ? _C.red.withValues(alpha: .10) : _C.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _C.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _C.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const raised = Color(0xFFF1F5F9);

  static const dark = Color(0xFF0F172A);
  static const border = Color(0xFFE2E8F0);
  static const borderMid = Color(0xFFCBD5E1);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  static const emerald = Color(0xFF10B981);
  static const emeraldLight = Color(0xFF6EE7B7);
  static const emeraldBg = Color(0xFFECFDF5);

  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFEF2F2);

  static const amber = Color(0xFFF59E0B);
  static const amberBg = Color(0xFFFFFBEB);
}
