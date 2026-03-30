import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/reward_service.dart';

// ─── Theme Tokens ──────────────────────────────────────────────────────────────
class _T {
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const card = Color(0xFF1A1A1A);
  static const border = Color(0xFF2A2A2A);
  static const neon = Color(0xFF00E676);
  static const neonBg = Color(0x1500E676);
  static const neonBdr = Color(0x3300E676);
  static const amber = Color(0xFFFFB300);
  static const amberBg = Color(0x15FFB300);
  static const info = Color(0xFF29B6F6);
  static const infoBg = Color(0x1529B6F6);
  static const error = Color(0xFFEF5350);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFF8A8A8A);
  static const greyDark = Color(0xFF3A3A3A);
}

// ─── Data model ───────────────────────────────────────────────────────────────
class _Series {
  final String label;
  final double value;
  final Color color;
  const _Series(this.label, this.value, this.color);
}

// ─── Screen ────────────────────────────────────────────────────────────────────
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'users';

  Future<Map<String, dynamic>> _statsFuture =
      AuthService.instance.getAdminStats();
  Future<Map<String, dynamic>> _rewardFuture =
      RewardService.instance.getAdminRewardMetrics();

  static const _reportTypes = [
    {
      'id': 'users',
      'title': 'User Report',
      'sub': 'Registration & activity',
      'icon': Icons.people_rounded,
      'color': _T.neon
    },
    {
      'id': 'shopkeepers',
      'title': 'Shopkeeper Report',
      'sub': 'Onboarding & approvals',
      'icon': Icons.store_rounded,
      'color': _T.info
    },
    {
      'id': 'offers',
      'title': 'Offers Report',
      'sub': 'Views & redemptions',
      'icon': Icons.local_offer_rounded,
      'color': _T.neon
    },
    {
      'id': 'subscriptions',
      'title': 'Subscription Report',
      'sub': 'Revenue & renewals',
      'icon': Icons.subscriptions_rounded,
      'color': _T.amber
    },
    {
      'id': 'coupons',
      'title': 'Coupon Report',
      'sub': 'Usage & distribution',
      'icon': Icons.confirmation_number_rounded,
      'color': _T.info
    },
    {
      'id': 'agents',
      'title': 'Agent Performance',
      'sub': 'SSA & sales metrics',
      'icon': Icons.support_agent_rounded,
      'color': _T.amber
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _appBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pad = _hPad(constraints.maxWidth);
          return RefreshIndicator(
            color: _T.neon,
            backgroundColor: _T.card,
            onRefresh: () async {
              setState(() {
                _statsFuture = AuthService.instance.getAdminStats();
                _rewardFuture = RewardService.instance.getAdminRewardMetrics();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pad, 20, pad, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateRangeCard(),
                  const SizedBox(height: 20),
                  _metricsSection(),
                  const SizedBox(height: 20),
                  _rewardSection(),
                  const SizedBox(height: 20),
                  _sectionLabel('Select Report Type'),
                  const SizedBox(height: 12),
                  _reportTypeGrid(constraints.maxWidth),
                  const SizedBox(height: 24),
                  _generateButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar() => AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _T.white, size: 19),
        ),
        title: const Text(
          'Reports',
          style: TextStyle(
              color: _T.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _T.border),
        ),
      );

  // ─── Date Range ────────────────────────────────────────────────────────────
  Widget _dateRangeCard() {
    final hasRange = _startDate != null && _endDate != null;
    final label = hasRange
        ? '${DateFormat('MMM d, y').format(_startDate!)}  →  ${DateFormat('MMM d, y').format(_endDate!)}'
        : 'Select date range';

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.date_range_rounded, color: _T.neon, size: 18),
            const SizedBox(width: 8),
            const Text('Date Range',
                style: TextStyle(
                    color: _T.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            if (hasRange)
              GestureDetector(
                onTap: () => setState(() {
                  _startDate = null;
                  _endDate = null;
                }),
                child:
                    const Icon(Icons.close_rounded, color: _T.grey, size: 18),
              ),
          ]),
          const SizedBox(height: 14),

          // Main date picker button
          _OutlineBtn(
            onTap: _pickDateRange,
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  color: _T.neon, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasRange ? _T.white : _T.grey,
                    fontSize: 13,
                    fontWeight: hasRange ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _T.grey, size: 18),
            ]),
          ),

          const SizedBox(height: 12),
          // Quick chips
          Wrap(spacing: 8, runSpacing: 8, children: [
            _QuickChip('Today', _setToday),
            _QuickChip('7 Days', _set7Days),
            _QuickChip('30 Days', _set30Days),
            _QuickChip('This Month', _setThisMonth),
          ]),
        ],
      ),
    );
  }

  // ─── Quick Metrics ─────────────────────────────────────────────────────────
  Widget _metricsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (ctx, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final stats = snap.data ?? {};

        final totalUsers = _n(stats['totalUsers']);
        final totalShops = _n(stats['totalShopkeepers']);
        final activeOffers = _n(stats['activeOffers']);
        final pendingShops = _n(stats['pendingShopkeepers']);

        final series =
            _buildSeries(totalUsers, totalShops, activeOffers, pendingShops);
        final maxY = ([...series.map((e) => e.value), 10.0]
                .reduce((a, b) => a > b ? a : b)) *
            1.25;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Quick Metrics'),
            const SizedBox(height: 12),
            loading
                ? _shimmerGrid()
                : LayoutBuilder(builder: (ctx, bc) {
                    const cols = 2;
                    final compact = bc.maxWidth < 380;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: compact ? 1.55 : 1.8,
                      children: [
                        FadeInUp(
                            delay: const Duration(milliseconds: 0),
                            child: _MiniMetric(
                                label: 'Users',
                                value: _fmt(totalUsers),
                                icon: Icons.people_rounded,
                                color: _T.neon)),
                        FadeInUp(
                            delay: const Duration(milliseconds: 70),
                            child: _MiniMetric(
                                label: 'Shopkeepers',
                                value: _fmt(totalShops),
                                icon: Icons.store_rounded,
                                color: _T.info)),
                        FadeInUp(
                            delay: const Duration(milliseconds: 140),
                            child: _MiniMetric(
                                label: 'Active Offers',
                                value: _fmt(activeOffers),
                                icon: Icons.local_offer_rounded,
                                color: _T.neon)),
                        FadeInUp(
                            delay: const Duration(milliseconds: 210),
                            child: _MiniMetric(
                                label: 'Pending',
                                value: _fmt(pendingShops),
                                icon: Icons.pending_rounded,
                                color: _T.amber)),
                      ],
                    );
                  }),
            const SizedBox(height: 16),
            // Chart label
            Row(children: [
              Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                      color: _T.neon, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(
                '${_selectedConfig['title']} Insights',
                style: const TextStyle(
                    color: _T.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ]),
            const SizedBox(height: 10),
            _DarkCard(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: loading
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: _T.neon, strokeWidth: 2)))
                  : LayoutBuilder(builder: (ctx, bc) {
                      final h = _chartH(bc.maxWidth);
                      return SizedBox(
                        height: h,
                        child: BarChart(BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: (_) =>
                                FlLine(color: _T.border, strokeWidth: 1),
                            getDrawingVerticalLine: (_) =>
                                FlLine(color: Colors.transparent),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (v, m) => Text(
                                  _fmtShort(v),
                                  style: const TextStyle(
                                      color: _T.grey, fontSize: 10),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, m) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= series.length)
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(series[i].label,
                                        style: const TextStyle(
                                            color: _T.grey, fontSize: 10)),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0; i < series.length; i++)
                              BarChartGroupData(x: i, barRods: [
                                BarChartRodData(
                                  toY: series[i].value,
                                  color: series[i].color,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5)),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY,
                                    color: _T.border.withOpacity(0.4),
                                  ),
                                ),
                              ]),
                          ],
                        )),
                      );
                    }),
            ),
          ],
        );
      },
    );
  }

  // ─── Reward / Coin Economy ─────────────────────────────────────────────────
  Widget _rewardSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _rewardFuture,
      builder: (ctx, snap) {
        if (snap.hasError) return const SizedBox.shrink();
        final loading = snap.connectionState == ConnectionState.waiting;
        final m = snap.data ?? {};
        final issued = _n(m['totalIssued']);
        final debited = _n(m['totalDebited']);
        final wallets = _n(m['activeWallets']);
        final net = issued - debited;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Coin Economy'),
            const SizedBox(height: 12),
            loading
                ? _shimmerGrid()
                : LayoutBuilder(builder: (ctx, bc) {
                    final cols = _cols(bc.maxWidth, max: 4);
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio:
                          cols == 1 ? 3.2 : (cols >= 3 ? 1.9 : 2.1),
                      children: [
                        FadeInUp(
                            delay: const Duration(milliseconds: 0),
                            child: _MiniMetric(
                                label: 'Issued',
                                value: _fmt(issued),
                                icon: Icons.add_circle_rounded,
                                color: _T.neon)),
                        FadeInUp(
                            delay: const Duration(milliseconds: 70),
                            child: _MiniMetric(
                                label: 'Debited',
                                value: _fmt(debited),
                                icon: Icons.remove_circle_rounded,
                                color: _T.error)),
                        FadeInUp(
                            delay: const Duration(milliseconds: 140),
                            child: _MiniMetric(
                                label: 'Net Coins',
                                value: _fmt(net),
                                icon: Icons.balance_rounded,
                                color: net >= 0 ? _T.neon : _T.error)),
                        FadeInUp(
                            delay: const Duration(milliseconds: 210),
                            child: _MiniMetric(
                                label: 'Wallets',
                                value: _fmt(wallets),
                                icon: Icons.account_balance_wallet_rounded,
                                color: _T.info)),
                      ],
                    );
                  }),
          ],
        );
      },
    );
  }

  // ─── Report Type Grid ──────────────────────────────────────────────────────
  Widget _reportTypeGrid(double parentWidth) {
    final cols = _cols(parentWidth, max: 2);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reportTypes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: cols == 1
            ? (parentWidth < 400 ? 3.6 : 4.0)
            : (parentWidth >= 900 ? 3.4 : 3.0),
      ),
      itemBuilder: (ctx, i) {
        final r = _reportTypes[i];
        final isSelected = _selectedType == r['id'];
        final color = r['color'] as Color;
        return FadeInUp(
          delay: Duration(milliseconds: 60 * i),
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = r['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.08) : _T.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? color : _T.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(r['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        r['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? color : _T.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r['sub'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _T.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedOpacity(
                  opacity: isSelected ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child:
                      Icon(Icons.check_circle_rounded, color: color, size: 18),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ─── Generate Button ───────────────────────────────────────────────────────
  Widget _generateButton() {
    return GestureDetector(
      onTap: _generateReport,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _T.neon,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: _T.neon.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_rounded, color: _T.bg, size: 20),
            SizedBox(width: 10),
            Text('Generate Report',
                style: TextStyle(
                    color: _T.bg,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(String t) => Text(
        t,
        style: const TextStyle(
            color: _T.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2),
      );

  Widget _shimmerGrid() => GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
        children: List.generate(
            4,
            (_) => Container(
                  decoration: BoxDecoration(
                      color: _T.card, borderRadius: BorderRadius.circular(14)),
                )),
      );

  Map<String, dynamic> get _selectedConfig =>
      _reportTypes.firstWhere((r) => r['id'] == _selectedType,
          orElse: () => _reportTypes.first);

  List<_Series> _buildSeries(double u, double s, double o, double p) {
    final approved = (s - p).clamp(0, double.infinity).toDouble();
    switch (_selectedType) {
      case 'shopkeepers':
        return [
          _Series('Total', s, _T.info),
          _Series('Appr.', approved, _T.neon),
          _Series('Pend.', p, _T.amber),
          _Series('Subs', approved * 0.6, _T.info)
        ];
      case 'offers':
        return [
          _Series('Active', o, _T.neon),
          _Series('Views', o * 150, _T.info),
          _Series('Redeem', o * 25, _T.neon),
          _Series('Shops', s, _T.grey)
        ];
      case 'subscriptions':
        return [
          _Series('Subscr.', approved * 0.6, _T.info),
          _Series('Pend.', p, _T.amber),
          _Series('Shops', s, _T.neon),
          _Series('Users', u, _T.grey)
        ];
      case 'coupons':
        return [
          _Series('Issued', o * 40, _T.neon),
          _Series('Used', o * 18, _T.info),
          _Series('Active', o * 8, _T.neon),
          _Series('Users', u, _T.grey)
        ];
      case 'agents':
        return [
          _Series('Active', approved * .18, _T.info),
          _Series('Leads', s * .42, _T.neon),
          _Series('Conv.', s * .21, _T.neon),
          _Series('Pend.', p, _T.amber)
        ];
      default:
        return [
          _Series('Users', u, _T.neon),
          _Series('Shops', s, _T.info),
          _Series('Offers', o, _T.neon),
          _Series('Pend.', p, _T.amber)
        ];
    }
  }

  double _n(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toInt().toString();
  String _fmtShort(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString();

  int _cols(double w, {required int max}) {
    if (w >= 900) return max;
    if (w >= 600) return max >= 2 ? 2 : max;
    return 1;
  }

  double _hPad(double w) => w < 360 ? 12 : (w >= 1200 ? 20 : 16);
  double _chartH(double w) => w >= 900 ? 260 : (w >= 600 ? 230 : 200);

  // ─── Date Actions ──────────────────────────────────────────────────────────
  void _setToday() => setState(() {
        _startDate = _endDate = DateTime.now();
      });
  void _set7Days() => setState(() {
        _endDate = DateTime.now();
        _startDate = _endDate!.subtract(const Duration(days: 7));
      });
  void _set30Days() => setState(() {
        _endDate = DateTime.now();
        _startDate = _endDate!.subtract(const Duration(days: 30));
      });
  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: _T.neon,
              onPrimary: _T.bg,
              surface: _T.card,
              onSurface: _T.white),
          dialogBackgroundColor: _T.surface,
        ),
        child: child!,
      ),
    );
    if (picked != null)
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
  }

  void _generateReport() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a date range first'),
          backgroundColor: _T.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: _T.error)),
        ),
      );
      return;
    }

    final r = _selectedConfig;
    showDialog(
      context: context,
      builder: (_) => _GenerateDialog(
        title: r['title'] as String,
        icon: r['icon'] as IconData,
        color: r['color'] as Color,
        startDate: _startDate!,
        endDate: _endDate!,
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _DarkCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border),
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      );
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniMetric(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _T.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _T.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: _T.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
            ],
          )),
        ]),
      );
}

class _OutlineBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _OutlineBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _T.border),
          ),
          child: child,
        ),
      );
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _T.neonBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _T.neonBdr),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: _T.neon, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}

class _GenerateDialog extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final DateTime startDate;
  final DateTime endDate;
  const _GenerateDialog(
      {required this.title,
      required this.icon,
      required this.color,
      required this.startDate,
      required this.endDate});

  @override
  State<_GenerateDialog> createState() => _GenerateDialogState();
}

class _GenerateDialogState extends State<_GenerateDialog> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _done = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Report generated! Check your downloads.'),
              backgroundColor: _T.card,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: _T.neon)),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _T.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _T.border)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(widget.icon, color: widget.color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(widget.title,
              style: const TextStyle(
                  color: _T.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            '${DateFormat('MMM d, y').format(widget.startDate)} – ${DateFormat('MMM d, y').format(widget.endDate)}',
            style: const TextStyle(color: _T.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _done
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle_rounded,
                        color: _T.neon, size: 20),
                    const SizedBox(width: 8),
                    const Text('Done!',
                        style: TextStyle(
                            color: _T.neon, fontWeight: FontWeight.w700)),
                  ])
                : Column(key: const ValueKey('loading'), children: [
                    const Text('Generating report…',
                        style: TextStyle(color: _T.grey, fontSize: 13)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      backgroundColor: _T.border,
                      color: widget.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                  color: _T.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _T.border)),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: _T.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
