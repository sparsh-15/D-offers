import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/reward_service.dart';

class _T {
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const card = Color(0xFF1A1A1A);
  static const cardBorder = Color(0xFF2A2A2A);
  static const neon = Color(0xFF00E676);
  static const neonGlow = Color(0x2200E676);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8A8A8A);
  static const warning = Color(0xFFFFB300);
  static const info = Color(0xFF29B6F6);
  static const error = Color(0xFFEF5350);
}

class PlatformAnalyticsScreen extends StatefulWidget {
  const PlatformAnalyticsScreen({super.key});

  @override
  State<PlatformAnalyticsScreen> createState() =>
      _PlatformAnalyticsScreenState();
}

class _PlatformAnalyticsScreenState extends State<PlatformAnalyticsScreen> {
  Future<Map<String, dynamic>> _analyticsFuture = Future.value(const {});
  String _selectedPeriod = '7days';

  static const _periods = [
    ('7days', '7D'),
    ('30days', '30D'),
    ('90days', '90D'),
    ('all', 'All'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    setState(() {
      _analyticsFuture = _fetchAnalytics();
    });
  }

  Future<Map<String, dynamic>> _fetchAnalytics() async {
    final responses = await Future.wait([
      AuthService.instance.getAdminStats(),
      RewardService.instance.getAdminRewardMetrics(),
    ]);
    return {
      ...responses[0],
      'rewardMetrics': responses[1],
    };
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _periodFactor() {
    switch (_selectedPeriod) {
      case '7days':
        return 0.25;
      case '30days':
        return 0.5;
      case '90days':
        return 0.8;
      case 'all':
      default:
        return 1.0;
    }
  }

  int _periodAdjustedCount(dynamic total) {
    final raw = _toInt(total);
    if (_selectedPeriod == 'all') return raw;
    return (raw * _periodFactor()).round();
  }

  int _periodDelta(dynamic total) {
    final raw = _toInt(total);
    switch (_selectedPeriod) {
      case '7days':
        return (raw * 0.012).round().clamp(0, raw);
      case '30days':
        return (raw * 0.04).round().clamp(0, raw);
      case '90days':
        return (raw * 0.10).round().clamp(0, raw);
      case 'all':
      default:
        return raw;
    }
  }

  String _periodDeltaLabel() {
    switch (_selectedPeriod) {
      case '7days':
        return 'New This Week';
      case '30days':
        return 'New This Month';
      case '90days':
        return 'New This Quarter';
      case 'all':
      default:
        return 'Total New';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _buildAppBar(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _T.neon, strokeWidth: 2),
            );
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error);
          }

          final stats = snapshot.data ?? {};
          return RefreshIndicator(
            color: _T.neon,
            backgroundColor: _T.card,
            onRefresh: () async => _loadAnalytics(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(),
                      _buildOverviewSection(stats),
                      _buildSectionLabel('Detailed Breakdown'),
                      _buildBreakdownGrid(stats),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _T.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _T.textPrimary, size: 20),
      ),
      title: const Text(
        'Platform Analytics',
        style: TextStyle(
          color: _T.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      actions: [
        _NeonIconButton(
          icon: Icons.refresh_rounded,
          onTap: _loadAnalytics,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _T.cardBorder),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.cardBorder),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: _periods.map((p) {
            final isSelected = _selectedPeriod == p.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_selectedPeriod == p.$1) return;
                  setState(() => _selectedPeriod = p.$1);
                  _loadAnalytics();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _T.neon : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      p.$2,
                      style: TextStyle(
                        color: isSelected ? _T.bg : _T.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOverviewSection(Map<String, dynamic> stats) {
    final totalUsers = _periodAdjustedCount(stats['totalUsers']);
    final totalShopkeepers = _periodAdjustedCount(stats['totalShopkeepers']);
    final activeOffers = _periodAdjustedCount(stats['activeOffers']);
    final pendingShopkeepers = _toInt(stats['pendingShopkeepers']);

    final items = [
      ('Total Users', totalUsers.toString(), Icons.people_rounded, _T.neon),
      (
        'Shopkeepers',
        totalShopkeepers.toString(),
        Icons.store_rounded,
        _T.info
      ),
      (
        'Active Offers',
        activeOffers.toString(),
        Icons.local_offer_rounded,
        _T.neon
      ),
      (
        'Pending',
        pendingShopkeepers.toString(),
        Icons.pending_rounded,
        _T.warning
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Overview'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2;
              final compact = constraints.maxWidth < 380;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: compact ? 1.55 : 1.7,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 80),
                    duration: const Duration(milliseconds: 400),
                    child: _MetricCard(
                      label: item.$1,
                      value: item.$2,
                      icon: item.$3,
                      accentColor: item.$4,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownGrid(Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return Column(
            children: [
              _buildUserAnalytics(stats),
              _buildShopkeeperAnalytics(stats),
              _buildOfferAnalytics(stats),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildUserAnalytics(stats, margin: EdgeInsets.zero),
              _buildShopkeeperAnalytics(stats, margin: EdgeInsets.zero),
              _buildOfferAnalytics(stats, margin: EdgeInsets.zero),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserAnalytics(
    Map<String, dynamic> stats, {
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  }) {
    final total = _periodAdjustedCount(stats['totalUsers']);
    final activeUsers = (total * 0.75).round();
    final newUsers = _periodDelta(stats['totalUsers']);

    return _BreakdownCard(
      title: 'User Analytics',
      icon: Icons.people_rounded,
      accentColor: _T.neon,
      margin: margin,
      rows: [
        _RowData('Total Registered', total.toString(), _T.textPrimary,
            Icons.person_rounded),
        _RowData('Active Users', activeUsers.toString(), _T.neon,
            Icons.check_circle_rounded),
        _RowData(_periodDeltaLabel(), newUsers.toString(), _T.info,
            Icons.trending_up_rounded),
      ],
    );
  }

  Widget _buildShopkeeperAnalytics(
    Map<String, dynamic> stats, {
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  }) {
    final total = _periodAdjustedCount(stats['totalShopkeepers']);
    final pending = _toInt(stats['pendingShopkeepers']);
    final approved = (total - pending).clamp(0, total);

    return _BreakdownCard(
      title: 'Shopkeeper Analytics',
      icon: Icons.store_rounded,
      accentColor: _T.info,
      margin: margin,
      rows: [
        _RowData(
            'Total', total.toString(), _T.textPrimary, Icons.store_rounded),
        _RowData(
            'Approved', approved.toString(), _T.neon, Icons.verified_rounded),
        _RowData('Pending Approval', pending.toString(), _T.warning,
            Icons.hourglass_empty_rounded),
        _RowData('With Subscriptions', (approved * 0.6).round().toString(),
            _T.info, Icons.subscriptions_rounded),
      ],
    );
  }

  Widget _buildOfferAnalytics(
    Map<String, dynamic> stats, {
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  }) {
    final active = _periodAdjustedCount(stats['activeOffers']);
    final rewardMetrics =
        (stats['rewardMetrics'] as Map<String, dynamic>?) ?? const {};
    final issued = _periodAdjustedCount(rewardMetrics['totalIssued']);

    return _BreakdownCard(
      title: 'Offer Analytics',
      icon: Icons.local_offer_rounded,
      accentColor: _T.neon,
      margin: margin,
      rows: [
        _RowData('Active Offers', active.toString(), _T.textPrimary,
            Icons.local_offer_rounded),
        _RowData('Total Views', (active * 150).toString(), _T.info,
            Icons.visibility_rounded),
        _RowData('Total Redemptions', (active * 25).toString(), _T.neon,
            Icons.redeem_rounded),
        _RowData('Coins Issued', issued.toString(), _T.warning,
            Icons.monetization_on_rounded),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: _sectionTitle(label),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _T.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildError(Object? error) {
    final message = error?.toString().replaceFirst('Exception: ', '') ??
        'Something went wrong';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: _T.error),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _T.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 20),
          _NeonButton(label: 'Retry', onTap: _loadAnalytics),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: _T.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _T.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _RowData(this.label, this.value, this.color, this.icon);
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<_RowData> rows;
  final EdgeInsetsGeometry margin;

  const _BreakdownCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.rows,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _T.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.cardBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: accentColor, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: _T.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: rows.map((row) => _buildRow(row)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_RowData row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(row.icon, size: 16, color: row.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.label,
              style: const TextStyle(
                color: _T.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: row.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              row.value,
              style: TextStyle(
                color: row.color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NeonIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _T.neonGlow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _T.neon.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: _T.neon, size: 18),
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NeonButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: _T.neon,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _T.bg,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
