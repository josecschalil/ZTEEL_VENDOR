import 'package:flutter/material.dart';
import 'package:frontend/services/vendor_service.dart';
import 'package:frontend/services/vendor_cache_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _Colors {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textFaint = Color(0xFF94A3B8);
  static const primary = Color(0xFF0F172A);
  static const amber = Color(0xFFF59E0B);
  static const emerald = Color(0xFF10B981);
  static const emeraldBg = Color(0xFFECFDF5);
}

class ReviewsScreen extends StatefulWidget {
  final String initialFilter;

  const ReviewsScreen({super.key, this.initialFilter = 'all'});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _data;
  late String _selectedFilter;
  bool _cacheRefreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _loadReviews();
    VendorCacheService.revision.addListener(_onCacheRevision);
  }

  Future<void> _loadReviews({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await VendorService.getVendorReviews(forceRefresh: forceRefresh);

    if (!mounted) return;

    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      setState(() {
        _data = res['data'] as Map<String, dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res['error']?.toString() ?? 'Failed to load reviews';
        _isLoading = false;
      });
    }
  }

  void _onCacheRevision() {
    if (_cacheRefreshScheduled) return;
    _cacheRefreshScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      _cacheRefreshScheduled = false;
      if (mounted) _loadReviews();
    });
  }

  @override
  void dispose() {
    VendorCacheService.revision.removeListener(_onCacheRevision);
    super.dispose();
  }

  List<dynamic> _getFilteredReviews(List<dynamic> allReviews) {
    if (_selectedFilter == 'all') return allReviews;
    final targetRating = int.tryParse(_selectedFilter);
    if (targetRating == null) return allReviews;
    return allReviews.where((r) {
      if (r is! Map) return false;
      final rating = (r['rating'] as num?)?.toInt();
      return rating == targetRating;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double rating = (_data?['rating'] as num?)?.toDouble() ?? 0.0;
    final int reviewCount = (_data?['review_count'] as num?)?.toInt() ?? 0;
    final rawBreakdown = _data?['breakdown'] as Map<String, dynamic>?;
    final rawPercentages = _data?['percentages'] as Map<String, dynamic>?;
    final allReviews = (_data?['reviews'] as List<dynamic>?) ?? [];
    final filteredReviews = _getFilteredReviews(allReviews);

    return Scaffold(
      backgroundColor: _Colors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _Colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Customer Reviews & Ratings',
          style: TextStyle(
            color: _Colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _Colors.textSecondary),
            onPressed: _loadReviews,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _Colors.primary),
            )
          : RefreshIndicator(
              color: _Colors.primary,
              onRefresh: () => _loadReviews(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Error message banner if any
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadReviews,
                            child: const Text('Retry', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                  // Rating Overview Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _Colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _Colors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Big Score Box
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color: _Colors.textPrimary,
                                        height: 1.0,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 6, left: 4),
                                      child: Text(
                                        '/ 5.0',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _Colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(5, (index) {
                                    final starVal = index + 1;
                                    if (rating >= starVal) {
                                      return const Icon(Icons.star_rounded, color: _Colors.amber, size: 20);
                                    } else if (rating >= starVal - 0.5) {
                                      return const Icon(Icons.star_half_rounded, color: _Colors.amber, size: 20);
                                    } else {
                                      return const Icon(Icons.star_outline_rounded,
                                          color: _Colors.textFaint, size: 20);
                                    }
                                  }),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$reviewCount ${reviewCount == 1 ? "Customer Review" : "Customer Reviews"}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: _Colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            // Breakdown Bars
                            Expanded(
                              child: Column(
                                children: [5, 4, 3, 2, 1].map((star) {
                                  final key = star.toString();
                                  final p = (rawPercentages?[key] as num?)?.toDouble() ?? 0.0;
                                  final count = (rawBreakdown?[key] as num?)?.toInt() ?? 0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          child: Text(
                                            '$star ★',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: _Colors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: p.clamp(0.0, 1.0),
                                              minHeight: 7,
                                              backgroundColor: const Color(0xFFF1F5F9),
                                              valueColor: const AlwaysStoppedAnimation<Color>(_Colors.amber),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 24,
                                          child: Text(
                                            '$count',
                                            textAlign: TextAlign.end,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: _Colors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Quick badge footer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _Colors.emeraldBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: _Colors.emerald, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Ratings submitted by verified diners on Zteel',
                                style: TextStyle(
                                  color: Color(0xFF065F46),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All (${allReviews.length})'),
                        const SizedBox(width: 8),
                        ...[5, 4, 3, 2, 1].map((s) {
                          final key = s.toString();
                          final count = (rawBreakdown?[key] as num?)?.toInt() ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(key, '$s ★ ($count)'),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFilter == 'all'
                            ? 'All Reviews (${filteredReviews.length})'
                            : '$_selectedFilter-Star Reviews (${filteredReviews.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _Colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Reviews List
                  if (filteredReviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      decoration: BoxDecoration(
                        color: _Colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _Colors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No reviews to display',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _Colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedFilter == 'all'
                                ? 'No customer reviews have been received yet.'
                                : 'No $_selectedFilter-star reviews yet.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _Colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredReviews.map((item) {
                      final review = item is Map ? item : {};
                      final String dinerName = (review['user_name']?.toString() ?? '').trim().isNotEmpty
                          ? review['user_name'].toString()
                          : 'Verified Customer';
                      final int r = (review['rating'] as num?)?.toInt() ?? 5;
                      final String comment = review['comment']?.toString() ?? '';
                      final String dateStr = review['created_at_formatted']?.toString() ?? '';
                      final bool isVerified = review['is_verified'] as bool? ?? true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _Colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _Colors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x04000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _Colors.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    dinerName.isNotEmpty ? dinerName[0].toUpperCase() : 'C',
                                    style: const TextStyle(
                                      color: _Colors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              dinerName,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: _Colors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isVerified) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _Colors.emeraldBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_circle_rounded, color: _Colors.emerald, size: 11),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    'Verified',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: _Colors.emerald,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (dateStr.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            color: _Colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < r ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: index < r ? _Colors.amber : _Colors.textFaint,
                                      size: 15,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  comment,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: _Colors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _Colors.primary : _Colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _Colors.primary : _Colors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _Colors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : _Colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
