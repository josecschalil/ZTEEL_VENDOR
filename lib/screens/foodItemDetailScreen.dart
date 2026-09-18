import 'package:flutter/material.dart';
import 'package:frontend/app_colors.dart';
import 'package:frontend/screens/editFoodItemScreen.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/widgets/app_top_bar.dart';

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
  late bool _isAvailable;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.isAvailable;
  }

  Future<void> _toggleAvailability() async {
    if (widget.itemId.isEmpty) return;

    final newStatus = !_isAvailable;
    final res = await VendorService.updateMenuItem(
      id: widget.itemId,
      isAvailable: newStatus,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _isAvailable = newStatus;
        _hasChanged = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newStatus ? 'Item is now available!' : 'Item is now hidden.'),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] ?? 'Failed to update availability'),
        backgroundColor: AppColors.orangeDim,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteItem() async {
    if (widget.itemId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Food Item', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${widget.itemName}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Delete', style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await VendorService.deleteMenuItem(widget.itemId);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Item "${widget.itemName}" deleted.'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['error'] ?? 'Failed to delete item'),
          backgroundColor: AppColors.orangeDim,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppTopBar(
                title: 'Food Item Details',
                showBackButton: true,
                onBack: () => Navigator.maybePop(context, _hasChanged),
                trailing: [
                  if (widget.itemId.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 22),
                      onPressed: _deleteItem,
                      tooltip: 'Delete Item',
                    ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () async {
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
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 14),
                      _buildActions(),
                      const SizedBox(height: 18),
                      _buildIdentityCard(),
                      const SizedBox(height: 14),
                      _buildDescriptionCard(),
                      const SizedBox(height: 14),
                      _buildSnapshotRow(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.surfaceRaised,
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: AppColors.orange,
                    size: 44,
                  ),
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.black.withValues(alpha: 0.12),
                    AppColors.black.withValues(alpha: 0.68),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildHeroChip(widget.categoryName),
                      _buildHeroChip(_isAvailable ? 'Available' : 'Hidden'),
                      if (widget.isBestseller) _buildHeroChip('Bestseller'),
                      _buildHeroChip(widget.isVeg ? 'Veg' : 'Non-Veg'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.itemName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.textWhite.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textWhite.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textWhite,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu Positioning',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile('Category', widget.categoryName),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoTile(
                  'Status',
                  _isAvailable ? 'Live on menu' : 'Currently hidden',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            VendorService.cleanDescription(widget.description),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSnapshotCard(
            icon: Icons.local_offer_outlined,
            title: 'Visibility',
            value: _isAvailable ? 'Order-ready' : 'Off menu',
            accent: _isAvailable ? AppColors.green : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSnapshotCard(
            icon: widget.isVeg ? Icons.eco_rounded : Icons.restaurant_menu_rounded,
            title: 'Dietary',
            value: widget.isVeg ? 'Vegetarian' : 'Non-Vegetarian',
            accent: widget.isVeg ? AppColors.green : AppColors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotCard({
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '\$${widget.price.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _toggleAvailability,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _isAvailable ? 'Mark Unavailable' : 'Make Available',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
