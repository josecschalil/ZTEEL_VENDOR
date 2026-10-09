import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:frontend/services/vendor_service.dart';

// ════════════════════════════════════════════════════════════════════════════
//  Design tokens
// ════════════════════════════════════════════════════════════════════════════

class _C {
  const _C._();
  static const bg = Color(0xFFF2F5F9);
  static const surface = Colors.white;
  static const wash = Color(0xFFE9EEF4);
  static const line = Color(0xFFE1E7EF);
  static const ink = Color(0xFF12261F);
  static const inkMid = Color(0xFF3B4F4A);
  static const muted = Color(0xFF677A82);
  static const faint = Color(0xFF9AAAB2);

  static const hero = Color(0xFF064E3B);
  static const heroDeep = Color(0xFF042F24);
  static const mint = Color(0xFFA7F3D0);

  static const green = Color(0xFF10B981);
  static const greenSoft = Color(0xFFBFEBD8);
  static const teal = Color(0xFF0D9488);
  static const indigo = Color(0xFF5B5BD6);
  static const sky = Color(0xFF0284C7);
  static const amber = Color(0xFFF59E0B);
  static const amberDeep = Color(0xFFB45309);
  static const rose = Color(0xFFE11D48);

  static const greenTint = Color(0xFFE2F6EE);
  static const indigoTint = Color(0xFFECEDFC);
  static const skyTint = Color(0xFFE3F2FA);
  static const amberTint = Color(0xFFFDF1D8);
  static const roseTint = Color(0xFFFDE8EC);
}

class _T {
  const _T._();
  static const title = TextStyle(
      color: _C.ink,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3);
  static const sub = TextStyle(
      color: _C.muted, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3);
  static const caption =
      TextStyle(color: _C.muted, fontSize: 11.5, fontWeight: FontWeight.w600);
}

// ════════════════════════════════════════════════════════════════════════════
//  Formatting helpers
// ════════════════════════════════════════════════════════════════════════════

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _fullWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

String _shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String _hourLabel(int h) {
  final display = h % 12 == 0 ? 12 : h % 12;
  return '$display ${h % 24 >= 12 ? 'PM' : 'AM'}';
}

/// Full rupee amount with Indian digit grouping: ₹1,23,456
String _inr(double v) {
  final n = v.round();
  final s = n.abs().toString();
  var out = s;
  if (s.length > 3) {
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},${s.substring(s.length - 3)}';
  }
  return '${n < 0 ? '-' : ''}₹$out';
}

String _trim1(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// Compact rupee amount for tight spaces: ₹4.2k, ₹1.5L, ₹2Cr
String _inrShort(double v) {
  final a = v.abs();
  final String body;
  if (a >= 10000000) {
    body = '${_trim1(a / 10000000)}Cr';
  } else if (a >= 100000) {
    body = '${_trim1(a / 100000)}L';
  } else if (a >= 1000) {
    body = '${_trim1(a / 1000)}k';
  } else {
    body = a.round().toString();
  }
  return '${v < 0 ? '-' : ''}₹$body';
}

double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

DateTime? _dateOf(Map<String, dynamic> order) {
  final raw = order['confirmed_at'] ?? order['created_at'];
  return raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();
}

// ════════════════════════════════════════════════════════════════════════════
//  Analytics model  (pure data – no widgets)
// ════════════════════════════════════════════════════════════════════════════

class _Bucket {
  const _Bucket(
      {required this.value,
      required this.orders,
      required this.axis,
      required this.title});
  final double value;
  final int orders;
  final String axis, title;
}

class _TopItem {
  const _TopItem(this.name, this.units, this.revenue);
  final String name;
  final int units;
  final double revenue;
}

class _Snapshot {
  const _Snapshot({
    required this.total,
    required this.completed,
    required this.pending,
    required this.rejected,
    required this.cancelled,
    required this.expired,
    required this.itemsSold,
    required this.revenue,
    required this.pendingValue,
    required this.itemRevenue,
    required this.hours,
    required this.weekdays,
    required this.buckets,
    required this.topItems,
    required this.unit,
  });

  final int total, completed, pending, rejected, cancelled, expired, itemsSold;
  final double revenue, pendingValue, itemRevenue;
  final List<int> hours, weekdays;
  final List<_Bucket> buckets;
  final List<_TopItem> topItems;
  final String unit;

  int get closed => rejected + cancelled + expired;
  double get average => completed == 0 ? 0 : revenue / completed;
  double get rate => total == 0 ? 0 : completed / total * 100;
  List<String> get labels => buckets.map((b) => b.axis).toList();
  List<double> get values => buckets.map((b) => b.value).toList();

  _Bucket? get best {
    _Bucket? out;
    for (final b in buckets) {
      if (b.value > 0 && (out == null || b.value > out.value)) out = b;
    }
    return out;
  }

  int? get peakHour {
    var idx = -1, top = 0;
    for (var i = 0; i < hours.length; i++) {
      if (hours[i] > top) {
        top = hours[i];
        idx = i;
      }
    }
    return idx < 0 ? null : idx;
  }

  factory _Snapshot.from(List<Map<String, dynamic>> orders, DateTimeRange range,
      {int? maxBuckets}) {
    final minutes = range.end.difference(range.start).inMinutes;
    final hourly = minutes <= 1440;
    final days = (minutes / 1440).ceil();
    final weekly = !hourly && days > 31;
    var count =
        hourly ? (minutes / 60).ceil() : (weekly ? (days / 7).ceil() : days);
    if (maxBuckets != null) count = math.min(count, maxBuckets);
    count = math.max(count, 1);
    final stepMinutes = hourly ? 60 : (weekly ? 10080 : 1440);

    final sums = List<double>.filled(count, 0);
    final counts = List<int>.filled(count, 0);
    final hours = List<int>.filled(24, 0);
    final weekdays = List<int>.filled(7, 0);
    final items = <String, _TopItem>{};
    var total = 0,
        completed = 0,
        pending = 0,
        rejected = 0,
        cancelled = 0,
        expired = 0,
        itemsSold = 0;
    var revenue = 0.0, pendingValue = 0.0, itemRevenue = 0.0;

    for (final order in orders) {
      final date = _dateOf(order);
      if (date == null ||
          date.isBefore(range.start) ||
          !date.isBefore(range.end)) continue;
      total++;
      final amount = _num(order['final_total']);
      switch (order['status']?.toString().toLowerCase()) {
        case 'confirmed':
          completed++;
          revenue += amount;
          hours[date.hour]++;
          weekdays[date.weekday - 1]++;
          final idx = date.difference(range.start).inMinutes ~/ stepMinutes;
          if (idx >= 0 && idx < count) {
            sums[idx] += amount;
            counts[idx]++;
          }
          final rawItems = order['items'];
          if (rawItems is List) {
            for (final raw in rawItems.whereType<Map>()) {
              final item = Map<String, dynamic>.from(raw);
              if (item['is_reward_item'] == true) continue;
              final name =
                  (item['item_name_snapshot']?.toString().trim() ?? '').isEmpty
                      ? 'Menu item'
                      : item['item_name_snapshot'].toString().trim();
              final qty = int.tryParse(item['quantity']?.toString() ?? '') ?? 1;
              final line = _num(item['line_total']);
              final prior = items[name] ?? _TopItem(name, 0, 0);
              items[name] =
                  _TopItem(name, prior.units + qty, prior.revenue + line);
              itemsSold += qty;
              itemRevenue += line;
            }
          }
        case 'pending':
          pending++;
          pendingValue += amount;
        case 'rejected':
          rejected++;
        case 'cancelled':
          cancelled++;
        case 'expired':
          expired++;
      }
    }

    final step = Duration(minutes: stepMinutes);
    final lastDay = range.end.subtract(const Duration(days: 1));
    final buckets = <_Bucket>[];
    for (var i = 0; i < count; i++) {
      final start = range.start.add(step * i);
      final String axis, title;
      if (hourly) {
        axis = _hourLabel(start.hour);
        title = '${_shortDate(start)}, ${_hourLabel(start.hour)}';
      } else if (weekly) {
        var end = start.add(const Duration(days: 6));
        if (end.isAfter(lastDay)) end = lastDay;
        axis = _shortDate(start);
        title = '${_shortDate(start)} to ${_shortDate(end)}';
      } else {
        axis = days <= 7 ? _weekdays[start.weekday - 1] : _shortDate(start);
        title = '${_weekdays[start.weekday - 1]}, ${_shortDate(start)}';
      }
      buckets.add(
          _Bucket(value: sums[i], orders: counts[i], axis: axis, title: title));
    }

    final top = items.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return _Snapshot(
      total: total,
      completed: completed,
      pending: pending,
      rejected: rejected,
      cancelled: cancelled,
      expired: expired,
      itemsSold: itemsSold,
      revenue: revenue,
      pendingValue: pendingValue,
      itemRevenue: itemRevenue,
      hours: hours,
      weekdays: weekdays,
      buckets: buckets,
      topItems: top.take(5).toList(),
      unit: hourly ? 'hour' : (weekly ? 'week' : 'day'),
    );
  }
}

enum _RangePreset { today, week, month, custom }

enum _Tone { positive, warning, neutral }

class _InsightData {
  const _InsightData(
      {required this.icon,
      required this.tone,
      required this.title,
      required this.detail});
  final IconData icon;
  final _Tone tone;
  final String title, detail;
}

Color _toneColor(_Tone t) => switch (t) {
      _Tone.positive => _C.green,
      _Tone.warning => _C.amberDeep,
      _Tone.neutral => _C.indigo,
    };

Color _toneTint(_Tone t) => switch (t) {
      _Tone.positive => _C.greenTint,
      _Tone.warning => _C.amberTint,
      _Tone.neutral => _C.indigoTint,
    };

// ════════════════════════════════════════════════════════════════════════════
//  Screen
// ════════════════════════════════════════════════════════════════════════════

class PerformanceAnalysisScreen extends StatefulWidget {
  const PerformanceAnalysisScreen({super.key});

  @override
  State<PerformanceAnalysisScreen> createState() =>
      _PerformanceAnalysisScreenState();
}

class _PerformanceAnalysisScreenState extends State<PerformanceAnalysisScreen> {
  _RangePreset _preset = _RangePreset.month;
  DateTimeRange? _customRange;
  bool _loading = true, _refreshing = false, _loaded = false;
  String? _loadError;
  List<Map<String, dynamic>> _orders = [];
  double _rating = 0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Data ────────────────────────────────────────────────────────────────

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _loadError = null;
      if (_loaded) {
        _refreshing = true;
      } else {
        _loading = true;
      }
    });
    try {
      final results = await Future.wait([
        VendorService.getVendorRedemptions(forceRefresh: forceRefresh),
        VendorService.getVendorReviews(forceRefresh: forceRefresh),
      ]);
      if (!mounted) return;

      final orderResult = results[0];
      final reviewResult = results[1];
      final rawOrders = orderResult['data'];
      final orders = rawOrders is List
          ? rawOrders
              .whereType<Map>()
              .map((x) => Map<String, dynamic>.from(x))
              .toList()
          : <Map<String, dynamic>>[];
      final reviewData = reviewResult['data'];
      final reviews = reviewData is Map
          ? Map<String, dynamic>.from(reviewData)
          : <String, dynamic>{};

      setState(() {
        _orders = orders;
        _rating = (reviews['rating'] as num?)?.toDouble() ?? 0;
        _reviewCount = (reviews['review_count'] as num?)?.toInt() ?? 0;
        _loadError = orderResult['success'] == true
            ? null
            : (orderResult['error']?.toString() ?? 'Unable to refresh');
        _loaded = true;
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
        _refreshing = false;
      });
    }
  }

  // ── Range logic ─────────────────────────────────────────────────────────

  DateTimeRange get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 1));
    switch (_preset) {
      case _RangePreset.today:
        return DateTimeRange(start: today, end: end);
      case _RangePreset.week:
        return DateTimeRange(
            start: today.subtract(const Duration(days: 6)), end: end);
      case _RangePreset.month:
        return DateTimeRange(
            start: today.subtract(const Duration(days: 29)), end: end);
      case _RangePreset.custom:
        return _customRange ??
            DateTimeRange(
                start: today.subtract(const Duration(days: 29)), end: end);
    }
  }

  bool _isLiveDay(DateTimeRange r) {
    final now = DateTime.now();
    return r.end.difference(r.start).inMinutes <= 1440 &&
        !now.isBefore(r.start) &&
        now.isBefore(r.end);
  }

  /// The window immediately before the active range, used for comparisons.
  /// For a day in progress it covers the same elapsed time yesterday.
  DateTimeRange get _prevRange {
    final r = _range;
    if (_isLiveDay(r)) {
      final start = r.start.subtract(const Duration(days: 1));
      return DateTimeRange(
          start: start, end: start.add(DateTime.now().difference(r.start)));
    }
    final len = r.end.difference(r.start);
    return DateTimeRange(start: r.start.subtract(len), end: r.start);
  }

  String get _rangeLabel {
    switch (_preset) {
      case _RangePreset.today:
        return 'Today';
      case _RangePreset.week:
        return 'Last 7 days';
      case _RangePreset.month:
        return 'Last 30 days';
      case _RangePreset.custom:
        final r = _range;
        return '${_shortDate(r.start)} – ${_shortDate(r.end.subtract(const Duration(days: 1)))}';
    }
  }

  String get _subtitle {
    final r = _range;
    final last = r.end.subtract(const Duration(days: 1));
    return _preset == _RangePreset.today
        ? _shortDate(last)
        : '${_shortDate(r.start)} – ${_shortDate(last)}';
  }

  String get _compareSuffix {
    if (_isLiveDay(_range)) return 'yesterday';
    switch (_preset) {
      case _RangePreset.today:
        return 'yesterday';
      case _RangePreset.week:
        return 'in the previous 7 days';
      case _RangePreset.month:
        return 'in the previous 30 days';
      case _RangePreset.custom:
        return 'in the previous period';
    }
  }

  Future<void> _chooseCustomRange() async {
    final today = DateTime.now();
    final lastDay = DateTime(today.year, today.month, today.day);
    final active = _range;
    final initialEnd = active.end.subtract(const Duration(days: 1));
    final selection = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: lastDay,
      initialDateRange: DateTimeRange(
        start: active.start,
        end: initialEnd.isAfter(lastDay) ? lastDay : initialEnd,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _C.hero),
        ),
        child: child!,
      ),
    );
    if (selection != null && mounted) {
      setState(() {
        _customRange = DateTimeRange(
          start: DateTime(
              selection.start.year, selection.start.month, selection.start.day),
          end: DateTime(
                  selection.end.year, selection.end.month, selection.end.day)
              .add(const Duration(days: 1)),
        );
        _preset = _RangePreset.custom;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _C.green,
          onRefresh: () => _loadData(forceRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: _buildHeader()),
              ),
              SliverPersistentHeader(
                  pinned: true,
                  delegate:
                      _PinnedDelegate(extent: 62, child: _buildRangePicker())),
              if (_loading)
                const SliverToBoxAdapter(child: _Skeleton())
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    ..._buildBlocks(),
                    SizedBox(height: 32 + bottomInset),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBlocks() {
    final range = _range;
    final cap = _isLiveDay(range) ? DateTime.now().hour + 1 : null;
    final cur = _Snapshot.from(_orders, range, maxBuckets: cap);
    final prev = _Snapshot.from(_orders, _prevRange, maxBuckets: cap);

    final blocks = <Widget>[
      if (_loadError != null)
        _Notice(
          message: _loaded
              ? 'Showing the last data we have. Pull down or retry to refresh.'
              : 'We couldn’t load your orders. Check your connection and retry.',
          onRetry: () => _loadData(forceRefresh: true),
        ),
      _RevenueHero(
          cur: cur,
          prev: prev,
          rangeLabel: _rangeLabel,
          compareSuffix: _compareSuffix),
      _buildKpis(cur, prev),
      if (cur.total == 0)
        _buildEmpty()
      else ...[
        _Bleed(child: _buildInsights(cur, prev)),
        _buildHealth(cur),
        _DemandPanel(hours: cur.hours, weekdays: cur.weekdays),
        _buildTopItems(cur),
      ],
    ];
    return [
      for (final b in blocks)
        Padding(
          padding: EdgeInsets.fromLTRB(
              b is _Bleed ? 0 : 20, 0, b is _Bleed ? 0 : 20, 16),
          child: b,
        ),
    ];
  }

  Widget _buildHeader() => Row(
        children: [
          _RoundButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop()),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Performance',
                  style: TextStyle(
                      color: _C.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8)),
              const SizedBox(height: 1),
              Text(_subtitle, style: _T.sub),
            ]),
          ),
          _RoundButton(
              icon: Icons.refresh_rounded,
              busy: _refreshing,
              onTap: () => _loadData(forceRefresh: true)),
        ],
      );

  Widget _buildRangePicker() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: _C.wash, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            _Seg(
                label: 'Today',
                selected: _preset == _RangePreset.today,
                onTap: () => setState(() => _preset = _RangePreset.today)),
            _Seg(
                label: '7 days',
                selected: _preset == _RangePreset.week,
                onTap: () => setState(() => _preset = _RangePreset.week)),
            _Seg(
                label: '30 days',
                selected: _preset == _RangePreset.month,
                onTap: () => setState(() => _preset = _RangePreset.month)),
            _Seg(
                label: 'Custom',
                icon: Icons.calendar_month_rounded,
                selected: _preset == _RangePreset.custom,
                onTap: _chooseCustomRange),
          ]),
        ),
      );

  Widget _buildKpis(_Snapshot s, _Snapshot p) {
    final rate = s.rate;
    final rateColor = rate >= 85 ? _C.green : (rate >= 60 ? _C.amber : _C.rose);
    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ]),
        );
    return Column(children: [
      row(
        _KpiTile(
          icon: Icons.receipt_long_rounded,
          color: _C.indigo,
          tint: _C.indigoTint,
          label: 'Completed orders',
          value: '${s.completed}',
          delta: _DeltaPill(
              cur: s.completed.toDouble(), prev: p.completed.toDouble()),
          footer: Text('${s.pending} pending, ${s.closed} closed',
              style: _T.caption),
        ),
        _KpiTile(
          icon: Icons.shopping_bag_outlined,
          color: _C.sky,
          tint: _C.skyTint,
          label: 'Average order',
          value: _inr(s.average),
          delta: _DeltaPill(cur: s.average, prev: p.average),
          footer: Text(
              p.completed == 0 ? 'No earlier data' : 'Was ${_inr(p.average)}',
              style: _T.caption),
        ),
      ),
      const SizedBox(height: 12),
      row(
        _KpiTile(
          icon: Icons.verified_rounded,
          color: _C.green,
          tint: _C.greenTint,
          label: 'Confirmation rate',
          value: '${rate.round()}%',
          delta: p.total == 0
              ? null
              : _DeltaPill(cur: rate, prev: p.rate, asPoints: true),
          footer: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(
                    value: rate / 100,
                    color: rateColor,
                    height: 7,
                    track: Colors.white),
                const SizedBox(height: 6),
                Text('${s.completed} of ${s.total} confirmed',
                    style: _T.caption),
              ]),
        ),
        _KpiTile(
          icon: Icons.star_rounded,
          color: _C.amber,
          tint: _C.amberTint,
          label: 'Customer rating',
          value: _rating == 0 ? '—' : _rating.toStringAsFixed(1),
          footer: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < 5; i++)
                Icon(
                  _rating >= i + 1
                      ? Icons.star_rounded
                      : (_rating >= i + .5
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded),
                  size: 15,
                  color: _C.amber,
                ),
              const SizedBox(width: 6),
              Text('$_reviewCount ${_reviewCount == 1 ? 'review' : 'reviews'}',
                  style: _T.caption),
            ]),
          ),
        ),
      ),
    ]);
  }

  // ── Smart insights ──────────────────────────────────────────────────────

  List<_InsightData> _insights(_Snapshot s, _Snapshot p) {
    final out = <_InsightData>[];

    if (s.completed == 0) {
      out.add(const _InsightData(
        icon: Icons.hourglass_empty_rounded,
        tone: _Tone.neutral,
        title: 'No completed orders yet',
        detail:
            'Revenue insights appear as soon as orders are confirmed in this period.',
      ));
    } else if (p.revenue > 0) {
      final pct = (s.revenue - p.revenue) / p.revenue * 100;
      if (pct >= 1) {
        out.add(_InsightData(
          icon: Icons.trending_up_rounded,
          tone: _Tone.positive,
          title: 'Revenue is up ${pct.round()}%',
          detail:
              '${_inr(s.revenue - p.revenue)} more than the previous period. Keep the momentum going.',
        ));
      } else if (pct <= -1) {
        out.add(_InsightData(
          icon: Icons.trending_down_rounded,
          tone: _Tone.warning,
          title: 'Revenue is down ${pct.abs().round()}%',
          detail:
              '${_inr(p.revenue - s.revenue)} less than the previous period. Try an offer in your slower hours.',
        ));
      } else {
        out.add(const _InsightData(
          icon: Icons.trending_flat_rounded,
          tone: _Tone.neutral,
          title: 'Revenue is holding steady',
          detail:
              'You’re level with the previous period. A promotion could tip it upward.',
        ));
      }
    } else {
      out.add(_InsightData(
        icon: Icons.rocket_launch_rounded,
        tone: _Tone.positive,
        title: 'Strong start',
        detail:
            'You earned ${_inr(s.revenue)} with no sales in the previous period.',
      ));
    }

    final ph = s.peakHour;
    if (ph != null) {
      out.add(_InsightData(
        icon: Icons.bolt_rounded,
        tone: _Tone.neutral,
        title: 'Busiest hour: ${_hourLabel(ph)} to ${_hourLabel(ph + 1)}',
        detail:
            '${s.hours[ph]} of ${s.completed} orders arrive in this hour. Prepare stock and staff ahead of it.',
      ));
    }

    if (s.topItems.isNotEmpty && s.itemRevenue > 0) {
      final top = s.topItems.first;
      final share = top.revenue / s.itemRevenue * 100;
      out.add(_InsightData(
        icon: Icons.restaurant_menu_rounded,
        tone: share >= 50 ? _Tone.warning : _Tone.positive,
        title: '${top.name} leads your menu',
        detail: share >= 50
            ? '${share.round()}% of item sales come from it. Promote other dishes to spread the risk.'
            : '${top.units} sold, ${share.round()}% of item sales. Keep it well stocked.',
      ));
    }

    if (s.pending > 0) {
      out.add(_InsightData(
        icon: Icons.pending_actions_rounded,
        tone: _Tone.warning,
        title:
            '${s.pending} ${s.pending == 1 ? 'order needs' : 'orders need'} confirming',
        detail:
            '${_inr(s.pendingValue)} is on hold. Confirm quickly before the orders expire.',
      ));
    } else if (s.total > 0) {
      out.add(s.rate >= 85
          ? _InsightData(
              icon: Icons.task_alt_rounded,
              tone: _Tone.positive,
              title: '${s.rate.round()}% of orders confirmed',
              detail:
                  'Excellent consistency. Keep fulfilment times predictable.',
            )
          : _InsightData(
              icon: Icons.rule_rounded,
              tone: _Tone.warning,
              title: 'Only ${s.rate.round()}% of orders confirmed',
              detail:
                  'Review rejected, cancelled and expired orders to win back sales.',
            ));
    }

    if (_rating > 0) {
      final tone = _rating >= 4.5
          ? _Tone.positive
          : (_rating >= 4.0 ? _Tone.neutral : _Tone.warning);
      out.add(_InsightData(
        icon: Icons.sentiment_satisfied_alt_rounded,
        tone: tone,
        title: 'Customers rate you ${_rating.toStringAsFixed(1)}',
        detail: _rating >= 4.5
            ? 'Across $_reviewCount reviews. That reputation helps new customers choose you.'
            : (_rating >= 4.0
                ? 'Across $_reviewCount reviews. Small service fixes can push this higher.'
                : 'Across $_reviewCount reviews. Read recent feedback and fix the common complaints.'),
      ));
    }
    return out;
  }

  Widget _buildInsights(_Snapshot s, _Snapshot p) {
    final list = _insights(s, p);
    final cardWidth = math.min(MediaQuery.sizeOf(context).width * .74, 290.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _SectionHeader('Smart insights',
            subtitle: 'What your numbers are telling you'),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) =>
              SizedBox(width: cardWidth, child: _InsightCard(data: list[i])),
        ),
      ),
    ]);
  }

  // ── Order health ────────────────────────────────────────────────────────

  Widget _buildHealth(_Snapshot s) {
    String share(int v) =>
        s.total == 0 ? '0%' : '${(v / s.total * 100).round()}%';
    final closedParts = <String>[
      if (s.rejected > 0) '${s.rejected} rejected',
      if (s.cancelled > 0) '${s.cancelled} cancelled',
      if (s.expired > 0) '${s.expired} expired',
    ];
    return _Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader('Order health',
            subtitle:
                '${s.total} ${s.total == 1 ? 'order' : 'orders'} in this period'),
        const SizedBox(height: 18),
        Row(children: [
          _Donut(
              completed: s.completed,
              pending: s.pending,
              closed: s.closed,
              rate: s.rate),
          const SizedBox(width: 22),
          Expanded(
            child: Column(children: [
              _StatusRow(
                  color: _C.green,
                  label: 'Completed',
                  count: s.completed,
                  share: share(s.completed)),
              const SizedBox(height: 14),
              _StatusRow(
                  color: _C.amber,
                  label: 'Pending',
                  count: s.pending,
                  share: share(s.pending)),
              const SizedBox(height: 14),
              _StatusRow(
                  color: _C.rose,
                  label: 'Closed',
                  count: s.closed,
                  share: share(s.closed)),
            ]),
          ),
        ]),
        if (closedParts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: _C.roseTint, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: _C.rose),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Closed orders: ${closedParts.join(', ')}',
                      style: const TextStyle(
                          color: _C.inkMid,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600))),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Top items ───────────────────────────────────────────────────────────

  Widget _buildTopItems(_Snapshot s) {
    final items = s.topItems;
    return _Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionHeader('Top selling items',
            subtitle: 'Ranked by revenue from completed orders'),
        const SizedBox(height: 6),
        if (items.isEmpty)
          const _EmptyContent(
              message: 'Top items appear once orders are completed.')
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _C.line),
            _TopItemRow(
              item: items[i],
              rank: i + 1,
              fill: items.first.revenue == 0
                  ? 0
                  : items[i].revenue / items.first.revenue,
              share: s.itemRevenue == 0 ? 0 : items[i].revenue / s.itemRevenue,
            ),
          ],
      ]),
    );
  }

  Widget _buildEmpty() => _Panel(
        child: Column(children: [
          const SizedBox(height: 6),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: _C.greenTint, shape: BoxShape.circle),
            child:
                const Icon(Icons.bar_chart_rounded, color: _C.green, size: 28),
          ),
          const SizedBox(height: 14),
          const Text('No orders in this period', style: _T.title),
          const SizedBox(height: 6),
          const Text(
            'Trends, demand and insights appear once orders come in. Try a wider date range to see more.',
            textAlign: TextAlign.center,
            style: _T.sub,
          ),
          if (_preset != _RangePreset.month) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(() => _preset = _RangePreset.month),
              style: FilledButton.styleFrom(
                  backgroundColor: _C.hero, shape: const StadiumBorder()),
              child: const Text('Show last 30 days'),
            ),
          ],
          const SizedBox(height: 6),
        ]),
      );
}

// ════════════════════════════════════════════════════════════════════════════
//  Hero: revenue headline + scrubbable trend chart
// ════════════════════════════════════════════════════════════════════════════

class _RevenueHero extends StatefulWidget {
  const _RevenueHero(
      {required this.cur,
      required this.prev,
      required this.rangeLabel,
      required this.compareSuffix});
  final _Snapshot cur, prev;
  final String rangeLabel, compareSuffix;

  @override
  State<_RevenueHero> createState() => _RevenueHeroState();
}

class _RevenueHeroState extends State<_RevenueHero> {
  static const double _chartHeight = 156;
  int? _sel;

  @override
  void didUpdateWidget(covariant _RevenueHero old) {
    super.didUpdateWidget(old);
    if (old.cur.revenue != widget.cur.revenue ||
        old.cur.buckets.length != widget.cur.buckets.length) _sel = null;
  }

  void _pick(double dx, double width, {bool toggle = false}) {
    final n = widget.cur.buckets.length;
    if (n == 0) return;
    final plotW =
        math.max(1.0, width - _TrendPainter.leftPad - _TrendPainter.rightPad);
    final raw = ((dx - _TrendPainter.leftPad) / plotW * (n - 1)).round();
    final i = n == 1 ? 0 : math.min(n - 1, math.max(0, raw));
    setState(() => _sel = (toggle && _sel == i) ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.cur, prev = widget.prev;
    final buckets = cur.buckets;
    final sel = (_sel != null && _sel! < buckets.length) ? _sel : null;
    final shown = sel == null ? null : buckets[sel];
    final before =
        (sel != null && sel < prev.buckets.length) ? prev.buckets[sel] : null;
    final best = cur.best;
    final value = shown?.value ?? cur.revenue;
    const numStyle = TextStyle(
        color: Colors.white,
        fontSize: 42,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
        height: 1.05);

    final String detail;
    if (shown != null) {
      final orderText =
          '${shown.orders} ${shown.orders == 1 ? 'order' : 'orders'}';
      detail = before == null
          ? orderText
          : '$orderText, vs ${_inr(before.value)} before';
    } else {
      detail = 'vs ${_inr(prev.revenue)} ${widget.compareSuffix}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_C.hero, _C.heroDeep],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33064E3B), blurRadius: 28, offset: Offset(0, 14))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(99)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: Colors.white.withValues(alpha: .75)),
              const SizedBox(width: 6),
              Text(widget.rangeLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const Spacer(),
          _DeltaPill(
              cur: value, prev: before?.value ?? prev.revenue, onDark: true),
        ]),
        const SizedBox(height: 22),
        Text(shown?.title ?? 'Revenue from completed orders',
            style: TextStyle(
                color: Colors.white.withValues(alpha: .72),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        sel == null
            ? _CountUp(value: value, format: _inr, style: numStyle)
            : Text(_inr(value), style: numStyle),
        const SizedBox(height: 6),
        Text(detail,
            style: TextStyle(
                color: Colors.white.withValues(alpha: .62),
                fontSize: 12.5,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        SizedBox(
          height: _chartHeight,
          child: cur.revenue == 0
              ? Center(
                  child: Text(
                      'Your revenue trend will draw here\nonce orders are completed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .55),
                          fontSize: 12.5,
                          height: 1.4)))
              : LayoutBuilder(builder: (context, c) {
                  final w = c.maxWidth;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _pick(d.localPosition.dx, w, toggle: true),
                    onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, w),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(
                          '${buckets.length}-${cur.revenue.round()}-${prev.revenue.round()}'),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => CustomPaint(
                        size: Size.infinite,
                        painter: _TrendPainter(
                            cur: cur.values,
                            prev: prev.values,
                            labels: cur.labels,
                            selected: sel,
                            progress: t),
                      ),
                    ),
                  );
                }),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: IntrinsicHeight(
            child: Row(children: [
              Expanded(
                  child: _HeroStat(
                      value: '${cur.itemsSold}', label: 'Items sold')),
              const VerticalDivider(
                  width: 1, thickness: 1, color: Color(0x24FFFFFF)),
              Expanded(
                  child: _HeroStat(
                      value: best == null ? '—' : _inrShort(best.value),
                      label: best == null
                          ? 'Best ${cur.unit}'
                          : 'Best ${cur.unit} (${best.axis})')),
              const VerticalDivider(
                  width: 1, thickness: 1, color: Color(0x24FFFFFF)),
              Expanded(
                  child: _HeroStat(
                      value: _inrShort(cur.pendingValue),
                      label: 'Pending value')),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .62),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(
      {required this.cur,
      required this.prev,
      required this.labels,
      required this.selected,
      required this.progress});

  static const leftPad = 40.0, rightPad = 4.0, topPad = 8.0, bottomPad = 24.0;
  final List<double> cur, prev;
  final List<String> labels;
  final int? selected;
  final double progress;

  static double _nice(double v) {
    if (v <= 0) return 1;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    final n = v / mag;
    final f = n <= 1 ? 1 : (n <= 2 ? 2 : (n <= 5 ? 5 : 10));
    return f * mag;
  }

  static double _xAt(Rect plot, int i, int n) =>
      n == 1 ? plot.center.dx : plot.left + plot.width * i / (n - 1);

  static Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 1; i < p.length; i++) {
      final a = p[i - 1], b = p[i];
      final c = (b.dx - a.dx) / 2;
      path.cubicTo(a.dx + c, a.dy, b.dx - c, b.dy, b.dx, b.dy);
    }
    return path;
  }

  static void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
        d += 9;
      }
    }
  }

  static void _text(Canvas canvas, String text, Offset anchor,
      {bool right = false, bool center = false, double? maxRight}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: 10.5,
              fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = right
        ? anchor.dx - tp.width
        : (center ? anchor.dx - tp.width / 2 : anchor.dx);
    if (maxRight != null) dx = math.max(0, math.min(dx, maxRight - tp.width));
    tp.paint(canvas, Offset(dx, anchor.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = cur.length;
    if (n == 0) return;
    final plot = Rect.fromLTRB(
        leftPad, topPad, size.width - rightPad, size.height - bottomPad);
    final peak = math.max(cur.fold<double>(0, (a, b) => math.max(a, b)),
        prev.fold<double>(0, (a, b) => math.max(a, b)));
    final top = _nice(peak);

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .10)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = plot.bottom - plot.height * i / 2;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(canvas, _inrShort(top * i / 2), Offset(plot.left - 8, y),
          right: true);
    }

    final ticks = math.min(n, 5);
    for (var k = 0; k < ticks; k++) {
      final i = ticks == 1 ? 0 : (k * (n - 1) / (ticks - 1)).round();
      _text(canvas, labels[i], Offset(_xAt(plot, i, n), size.height - 8),
          center: true, maxRight: size.width);
    }

    Offset pt(int i, double v) =>
        Offset(_xAt(plot, i, n), plot.bottom - (v / top) * plot.height);
    final pts = [for (var i = 0; i < n; i++) pt(i, cur[i])];

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(
        0, 0, plot.left + plot.width * progress + 4, size.height));

    if (prev.length >= 2 && prev.any((v) => v > 0)) {
      final count = math.min(prev.length, n);
      final prevPts = [for (var i = 0; i < count; i++) pt(i, prev[i])];
      if (prevPts.length >= 2) {
        _dashed(
          canvas,
          _smooth(prevPts),
          Paint()
            ..color = Colors.white.withValues(alpha: .38)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }
    }

    if (n >= 2) {
      final line = _smooth(pts);
      final area = Path.from(line)
        ..lineTo(pts.last.dx, plot.bottom)
        ..lineTo(pts.first.dx, plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _C.mint.withValues(alpha: .34),
              _C.mint.withValues(alpha: 0)
            ],
          ).createShader(plot),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = _C.mint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (n <= 14) {
      for (final p in pts) {
        canvas.drawCircle(p, 3.4, Paint()..color = _C.hero);
        canvas.drawCircle(
          p,
          3.4,
          Paint()
            ..color = _C.mint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }
    }

    final s = selected;
    if (s != null && s < n) {
      final p = pts[s];
      canvas.drawLine(
        Offset(p.dx, plot.top),
        Offset(p.dx, plot.bottom),
        Paint()
          ..color = Colors.white.withValues(alpha: .35)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
          p, 9, Paint()..color = Colors.white.withValues(alpha: .22));
      canvas.drawCircle(p, 4.8, Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => true;
}

// ════════════════════════════════════════════════════════════════════════════
//  Customer demand (hour / weekday)
// ════════════════════════════════════════════════════════════════════════════

class _DemandPanel extends StatefulWidget {
  const _DemandPanel({required this.hours, required this.weekdays});
  final List<int> hours, weekdays;

  @override
  State<_DemandPanel> createState() => _DemandPanelState();
}

class _DemandPanelState extends State<_DemandPanel> {
  bool _byHour = true;
  int? _sel;

  String _name(int i) =>
      _byHour ? '${_hourLabel(i)} to ${_hourLabel(i + 1)}' : _fullWeekdays[i];

  @override
  Widget build(BuildContext context) {
    final data = _byHour ? widget.hours : widget.weekdays;
    final maxV = data.fold<int>(0, (a, b) => math.max(a, b));
    final total = data.fold<int>(0, (a, b) => a + b);
    final peak = maxV == 0 ? null : data.indexOf(maxV);
    final focus = _sel ?? peak;
    final readoutLabel = _sel == null
        ? (_byHour ? 'Busiest hour' : 'Busiest day')
        : (_byHour ? 'Selected hour' : 'Selected day');

    return _Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Expanded(
              child: _SectionHeader('Customer demand',
                  subtitle: 'When completed orders come in')),
          _MiniToggle(
            labels: const ['Hour', 'Day'],
            index: _byHour ? 0 : 1,
            onChanged: (i) => setState(() {
              _byHour = i == 0;
              _sel = null;
            }),
          ),
        ]),
        const SizedBox(height: 16),
        if (maxV == 0 || focus == null)
          const _EmptyContent(
              message: 'Demand patterns appear once orders are completed.')
        else ...[
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(readoutLabel, style: _T.caption),
                    const SizedBox(height: 2),
                    Text(_name(focus),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${data[focus]} ${data[focus] == 1 ? 'order' : 'orders'}',
                  style: const TextStyle(
                      color: _C.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
              Text(
                  '${total == 0 ? 0 : (data[focus] / total * 100).round()}% of total',
                  style: _T.caption),
            ]),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 112,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < data.length; i++)
                Expanded(
                  key: ValueKey('${_byHour ? 'h' : 'd'}$i'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _sel = _sel == i ? null : i),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: _byHour ? 1.5 : 7),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: data[i] / maxV),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => Container(
                            height: 6 + v * 100,
                            decoration: BoxDecoration(
                              color: data[i] == 0
                                  ? _C.wash
                                  : (i == focus ? _C.green : _C.greenSoft),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(_byHour ? 4 : 9),
                                  bottom: const Radius.circular(2)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          if (_byHour)
            const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('12 AM', style: _axis),
                  Text('6 AM', style: _axis),
                  Text('12 PM', style: _axis),
                  Text('6 PM', style: _axis),
                  Text('11 PM', style: _axis),
                ])
          else
            Row(children: [
              for (final d in _weekdays)
                Expanded(child: Center(child: Text(d, style: _axis))),
            ]),
        ],
      ]),
    );
  }

  static const _axis =
      TextStyle(color: _C.faint, fontSize: 10.5, fontWeight: FontWeight.w600);
}

class _MiniToggle extends StatelessWidget {
  const _MiniToggle(
      {required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: _C.wash, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9)),
                child: Text(labels[i],
                    style: TextStyle(
                        color: i == index ? _C.ink : _C.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      );
}

// ════════════════════════════════════════════════════════════════════════════
//  Order-health donut
// ════════════════════════════════════════════════════════════════════════════

class _Donut extends StatelessWidget {
  const _Donut(
      {required this.completed,
      required this.pending,
      required this.closed,
      required this.rate});
  final int completed, pending, closed;
  final double rate;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 124,
        height: 124,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('$completed-$pending-$closed'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => CustomPaint(
            painter: _DonutPainter(completed, pending, closed, t),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${rate.round()}%',
                    style: const TextStyle(
                        color: _C.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
                const Text('confirmed',
                    style: TextStyle(
                        color: _C.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.completed, this.pending, this.closed, this.t);
  final int completed, pending, closed;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromLTWH(
        stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = _C.wash,
    );
    final values = [completed, pending, closed];
    final colors = [_C.green, _C.amber, _C.rose];
    final total = completed + pending + closed;
    if (total == 0) return;
    final active = values.where((v) => v > 0).length;
    final gap = active > 1 ? 0.38 : 0.0;
    final avail = math.pi * 2 - gap * active;
    var start = -math.pi / 2 + gap / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final full = avail * values[i] / total;
      canvas.drawArc(
        rect,
        start,
        math.max(0.001, full * t),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = colors[i],
      );
      start += full + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.t != t ||
      old.completed != completed ||
      old.pending != pending ||
      old.closed != closed;
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(
      {required this.color,
      required this.label,
      required this.count,
      required this.share});
  final Color color;
  final String label, share;
  final int count;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: _C.inkMid,
                    fontSize: 13,
                    fontWeight: FontWeight.w600))),
        Text('$count',
            style: const TextStyle(
                color: _C.ink, fontSize: 15, fontWeight: FontWeight.w800)),
        SizedBox(
            width: 40,
            child: Text(share, textAlign: TextAlign.right, style: _T.caption)),
      ]);
}

// ════════════════════════════════════════════════════════════════════════════
//  Top items
// ════════════════════════════════════════════════════════════════════════════

class _TopItemRow extends StatelessWidget {
  const _TopItemRow(
      {required this.item,
      required this.rank,
      required this.fill,
      required this.share});
  final _TopItem item;
  final int rank;
  final double fill, share;

  static const _barColors = [_C.green, _C.teal, _C.sky, _C.indigo, _C.faint];

  @override
  Widget build(BuildContext context) {
    final Gradient? badge = switch (rank) {
      1 => const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      2 => const LinearGradient(
          colors: [Color(0xFFCBD5E1), Color(0xFF8A9BB0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      3 => const LinearGradient(
          colors: [Color(0xFFE0A070), Color(0xFFB5703A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                gradient: badge,
                color: badge == null ? _C.wash : null,
                borderRadius: BorderRadius.circular(11)),
            child: Text('$rank',
                style: TextStyle(
                    color: badge == null ? _C.muted : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _C.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                  '${item.units} sold, ${(share * 100).round()}% of item sales',
                  style: _T.caption),
            ]),
          ),
          const SizedBox(width: 8),
          Text(_inr(item.revenue),
              style: const TextStyle(
                  color: _C.ink,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2)),
        ]),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: _Bar(
              value: fill,
              color: _barColors[math.min(rank - 1, _barColors.length - 1)],
              height: 6),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Reusable building blocks
// ════════════════════════════════════════════════════════════════════════════

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _C.line)),
        child: child,
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: _T.title),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: _T.sub)
        ],
      ]);
}

class _Bleed extends StatelessWidget {
  const _Bleed({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

class _KpiTile extends StatelessWidget {
  const _KpiTile(
      {required this.icon,
      required this.color,
      required this.tint,
      required this.label,
      required this.value,
      required this.footer,
      this.delta});
  final IconData icon;
  final Color color, tint;
  final String label, value;
  final Widget footer;
  final Widget? delta;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration:
            BoxDecoration(color: tint, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const Spacer(),
            if (delta != null) delta!,
          ]),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    color: _C.ink,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _C.inkMid,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          footer,
        ]),
      );
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill(
      {required this.cur,
      required this.prev,
      this.onDark = false,
      this.asPoints = false});
  final double cur, prev;
  final bool onDark, asPoints;

  @override
  Widget build(BuildContext context) {
    final String text;
    final int dir; // 1 up, -1 down, 0 flat
    if (asPoints) {
      final d = cur - prev;
      dir = d.abs() < 0.5 ? 0 : (d > 0 ? 1 : -1);
      text = '${d.abs().round()} pts';
    } else if (prev == 0) {
      dir = cur > 0 ? 1 : 0;
      text = cur > 0 ? 'New' : '0%';
    } else {
      final pct = (cur - prev) / prev * 100;
      dir = pct.abs() < 0.5 ? 0 : (pct > 0 ? 1 : -1);
      text = '${pct.abs().round()}%';
    }
    final Color fg, bg;
    if (onDark) {
      fg = dir > 0
          ? _C.mint
          : (dir < 0 ? const Color(0xFFFECDD3) : const Color(0xFFCBD5E1));
      bg = Colors.white.withValues(alpha: .13);
    } else {
      fg = dir > 0 ? const Color(0xFF047857) : (dir < 0 ? _C.rose : _C.muted);
      bg = Colors.white.withValues(alpha: .75);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
            dir > 0
                ? Icons.arrow_upward_rounded
                : (dir < 0
                    ? Icons.arrow_downward_rounded
                    : Icons.remove_rounded),
            size: 13,
            color: fg),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.data});
  final _InsightData data;
  @override
  Widget build(BuildContext context) {
    final color = _toneColor(data.tone);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _toneTint(data.tone), borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .8),
                shape: BoxShape.circle),
            child: Icon(data.icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _C.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.2))),
        ]),
        const SizedBox(height: 10),
        Text(data.detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: _C.inkMid,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.38)),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(
      {required this.value,
      required this.color,
      this.height = 6,
      this.track = _C.wash});
  final double value, height;
  final Color color, track;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            color: track,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                  begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(99))),
              ),
            ),
          ),
        ),
      );
}

class _CountUp extends StatelessWidget {
  const _CountUp(
      {required this.value, required this.format, required this.style});
  final double value;
  final String Function(double) format;
  final TextStyle style;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Text(format(v), style: style),
      );
}

class _Seg extends StatelessWidget {
  const _Seg(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                          color: Color(0x14064E3B),
                          blurRadius: 8,
                          offset: Offset(0, 2))
                    ]
                  : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: selected ? _C.hero : _C.muted),
                const SizedBox(width: 5)
              ],
              Text(label,
                  style: TextStyle(
                      color: selected ? _C.ink : _C.muted,
                      fontSize: 12.5,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600)),
            ]),
          ),
        ),
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton(
      {required this.icon, required this.onTap, this.busy = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool busy;
  @override
  Widget build(BuildContext context) => Material(
        color: _C.surface,
        shape: const CircleBorder(side: BorderSide(color: _C.line)),
        child: InkWell(
          onTap: busy ? null : onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: _C.green))
                  : Icon(icon, color: _C.ink, size: 20),
            ),
          ),
        ),
      );
}

class _PinnedDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedDelegate({required this.child, required this.extent});
  final Widget child;
  final double extent;
  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: _C.bg, alignment: Alignment.topCenter, child: child);
  @override
  bool shouldRebuild(covariant _PinnedDelegate old) => true;
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
            color: _C.amberTint, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const Icon(Icons.cloud_off_rounded, color: _C.amberDeep, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: _C.inkMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3))),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
                foregroundColor: _C.amberDeep,
                visualDensity: VisualDensity.compact),
            child: const Text('Retry',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(children: [
          const Icon(Icons.auto_graph_rounded, color: _C.faint, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: _T.sub)),
        ]),
      );
}

class _Skeleton extends StatefulWidget {
  const _Skeleton();
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _box(double h, double r) => Container(
      height: h,
      decoration: BoxDecoration(
          color: _C.line, borderRadius: BorderRadius.circular(r)));

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: FadeTransition(
          opacity: Tween<double>(begin: .45, end: 1)
              .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
          child: Column(children: [
            _box(400, 32),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _box(140, 22)),
              const SizedBox(width: 12),
              Expanded(child: _box(140, 22))
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _box(140, 22)),
              const SizedBox(width: 12),
              Expanded(child: _box(140, 22))
            ]),
            const SizedBox(height: 16),
            _box(220, 26),
          ]),
        ),
      );
}
