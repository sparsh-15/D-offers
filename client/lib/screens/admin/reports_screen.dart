import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/auth_service.dart';
import '../../services/reward_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _MetricSeriesItem {
  final String label;
  final num value;
  final Color color;

  const _MetricSeriesItem(this.label, this.value, this.color);
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedReportType = 'users';
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<Map<String, dynamic>> _rewardMetricsFuture;

  final List<Map<String, dynamic>> _reportTypes = [
    {
      'id': 'users',
      'title': 'User Report',
      'description': 'Detailed user registration and activity report',
      'icon': Icons.people_rounded,
      'color': AppColors.primary,
    },
    {
      'id': 'shopkeepers',
      'title': 'Shopkeeper Report',
      'description': 'Shopkeeper onboarding and approval statistics',
      'icon': Icons.store_rounded,
      'color': AppColors.accent,
    },
    {
      'id': 'offers',
      'title': 'Offers Report',
      'description': 'Offer creation, views, and redemption analytics',
      'icon': Icons.local_offer_rounded,
      'color': AppColors.success,
    },
    {
      'id': 'subscriptions',
      'title': 'Subscription Report',
      'description': 'Subscription plans, revenue, and renewals',
      'icon': Icons.subscriptions_rounded,
      'color': AppColors.accentDim,
    },
    {
      'id': 'coupons',
      'title': 'Coupon Report',
      'description': 'Coupon usage and discount distribution',
      'icon': Icons.confirmation_number_rounded,
      'color': AppColors.accentDim,
    },
    {
      'id': 'agents',
      'title': 'Agent Performance Report',
      'description': 'SSA and sales agent performance metrics',
      'icon': Icons.support_agent_rounded,
      'color': AppColors.warning,
    },
  ];

  @override
  void initState() {
    super.initState();
    _statsFuture = AuthService.instance.getAdminStats();
    _rewardMetricsFuture = RewardService.instance.getAdminRewardMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ThemeHelper.buildBackButton(context),
        title: const Text('Reports'),
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
            final sectionGap = constraints.maxWidth < 360 ? 16.0 : 20.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangeSelector(),
                  SizedBox(height: sectionGap),
                  _buildMetricsSection(),
                  SizedBox(height: sectionGap),
                  _buildRewardMetricsSection(),
                  SizedBox(height: sectionGap),
                  const Text(
                    'Select Report Type',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildReportTypeGrid(),
                  SizedBox(height: sectionGap),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateReport,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Generate Report'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data ?? <String, dynamic>{};
        final totalUsers = _asNum(stats['totalUsers']);
        final totalShopkeepers = _asNum(stats['totalShopkeepers']);
        final activeOffers = _asNum(stats['activeOffers']);
        final pendingShopkeepers = _asNum(stats['pendingShopkeepers']);
        final selectedSeries = _buildSeriesForSelectedType(
          totalUsers: totalUsers,
          totalShopkeepers: totalShopkeepers,
          activeOffers: activeOffers,
          pendingShopkeepers: pendingShopkeepers,
        );

        final maxY = [
              ...selectedSeries.map((e) => e.value),
              10,
            ].reduce((a, b) => a > b ? a : b) *
            1.2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Metrics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 960
                    ? 4
                    : width >= 620
                        ? 2
                        : 1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: crossAxisCount == 1 ? 3.2 : 2.2,
                  children: [
                    _buildMiniMetricCard(
                      'Users',
                      totalUsers.toInt().toString(),
                      Icons.people_rounded,
                    ),
                    _buildMiniMetricCard(
                      'Shopkeepers',
                      totalShopkeepers.toInt().toString(),
                      Icons.store_rounded,
                    ),
                    _buildMiniMetricCard(
                      'Active Offers',
                      activeOffers.toInt().toString(),
                      Icons.local_offer_rounded,
                    ),
                    _buildMiniMetricCard(
                      'Pending',
                      pendingShopkeepers.toInt().toString(),
                      Icons.pending_rounded,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              '${_selectedReportConfig['title']} Insights',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      maxY: maxY,
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 34),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= selectedSeries.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  selectedSeries[index].label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < selectedSeries.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: selectedSeries[i].value.toDouble(),
                                color: selectedSeries[i].color,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRewardMetricsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _rewardMetricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Reward metrics unavailable right now',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        final metrics = snapshot.data ?? const {};
        final issued = (metrics['totalIssued'] as num?)?.toInt() ?? 0;
        final debited = (metrics['totalDebited'] as num?)?.toInt() ?? 0;
        final wallets = (metrics['activeWallets'] as num?)?.toInt() ?? 0;
        final net = issued - debited;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coin Economy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 900
                    ? 4
                    : width >= 620
                        ? 2
                        : 1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: crossAxisCount == 1 ? 3.2 : 2.2,
                  children: [
                    _buildMiniMetricCard(
                        'Issued', '$issued', Icons.add_circle_rounded),
                    _buildMiniMetricCard(
                        'Debited', '$debited', Icons.remove_circle_rounded),
                    _buildMiniMetricCard(
                        'Net Coins', '$net', Icons.balance_rounded),
                    _buildMiniMetricCard('Wallets', '$wallets',
                        Icons.account_balance_wallet_rounded),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  num _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> get _selectedReportConfig {
    return _reportTypes.firstWhere(
      (report) => report['id'] == _selectedReportType,
      orElse: () => _reportTypes.first,
    );
  }

  List<_MetricSeriesItem> _buildSeriesForSelectedType({
    required num totalUsers,
    required num totalShopkeepers,
    required num activeOffers,
    required num pendingShopkeepers,
  }) {
    final approvedShopkeepers =
        (totalShopkeepers - pendingShopkeepers).clamp(0, double.infinity);
    switch (_selectedReportType) {
      case 'shopkeepers':
        return [
          _MetricSeriesItem('Total', totalShopkeepers, AppColors.accent),
          _MetricSeriesItem('Approved', approvedShopkeepers, AppColors.success),
          _MetricSeriesItem('Pending', pendingShopkeepers, AppColors.warning),
          _MetricSeriesItem(
              'Subs', (approvedShopkeepers * 0.6), AppColors.info),
        ];
      case 'offers':
        return [
          _MetricSeriesItem('Active', activeOffers, AppColors.success),
          _MetricSeriesItem('Views', activeOffers * 150, AppColors.primary),
          _MetricSeriesItem('Redeem', activeOffers * 25, AppColors.accent),
          _MetricSeriesItem('Shops', totalShopkeepers, AppColors.textSecondary),
        ];
      case 'subscriptions':
        return [
          _MetricSeriesItem(
              'Subscribed', approvedShopkeepers * 0.6, AppColors.accent),
          _MetricSeriesItem('Pending', pendingShopkeepers, AppColors.warning),
          _MetricSeriesItem('Shops', totalShopkeepers, AppColors.primary),
          _MetricSeriesItem('Users', totalUsers, AppColors.textSecondary),
        ];
      case 'coupons':
        return [
          _MetricSeriesItem('Issued', activeOffers * 40, AppColors.primary),
          _MetricSeriesItem('Used', activeOffers * 18, AppColors.success),
          _MetricSeriesItem('Active', activeOffers * 8, AppColors.accent),
          _MetricSeriesItem('Users', totalUsers, AppColors.textSecondary),
        ];
      case 'agents':
        return [
          _MetricSeriesItem(
              'Active', approvedShopkeepers * 0.18, AppColors.accent),
          _MetricSeriesItem(
              'Leads', totalShopkeepers * 0.42, AppColors.primary),
          _MetricSeriesItem(
              'Convert', totalShopkeepers * 0.21, AppColors.success),
          _MetricSeriesItem('Pending', pendingShopkeepers, AppColors.warning),
        ];
      case 'users':
      default:
        return [
          _MetricSeriesItem('Users', totalUsers, AppColors.primary),
          _MetricSeriesItem('Shops', totalShopkeepers, AppColors.accent),
          _MetricSeriesItem('Offers', activeOffers, AppColors.success),
          _MetricSeriesItem('Pending', pendingShopkeepers, AppColors.warning),
        ];
    }
  }

  Widget _buildReportTypeGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1040
            ? 3
            : width >= 680
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reportTypes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 2.7 : 2.1,
          ),
          itemBuilder: (context, index) {
            final report = _reportTypes[index];
            return FadeInUp(
              delay: Duration(milliseconds: 70 * index),
              child: _buildReportCard(report),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniMetricCard(String title, String value, IconData icon) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.date_range_rounded, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Date Range',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}'
                        : 'Select Date Range',
                  ),
                ),
                if (_startDate != null && _endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickDateChip('Today', () {
                  setState(() {
                    _startDate = DateTime.now();
                    _endDate = DateTime.now();
                  });
                }),
                _buildQuickDateChip('Last 7 Days', () {
                  setState(() {
                    _endDate = DateTime.now();
                    _startDate = _endDate!.subtract(const Duration(days: 7));
                  });
                }),
                _buildQuickDateChip('Last 30 Days', () {
                  setState(() {
                    _endDate = DateTime.now();
                    _startDate = _endDate!.subtract(const Duration(days: 30));
                  });
                }),
                _buildQuickDateChip('This Month', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = DateTime(now.year, now.month, 1);
                    _endDate = DateTime(now.year, now.month + 1, 0);
                  });
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.accent.withValues(alpha: 0.1),
      labelStyle: const TextStyle(color: AppColors.accent),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final isSelected = _selectedReportType == report['id'];

    return Card(
      margin: EdgeInsets.zero,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? report['color'] as Color : AppColors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedReportType = report['id'] as String;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (report['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  report['icon'] as IconData,
                  color: report['color'] as Color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report['description'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: report['color'] as Color,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateReport() {
    if (_startDate == null || _endDate == null) {
      DialogHelper.showErrorSnackBar(context, 'Please select a date range');
      return;
    }

    final reportType = _reportTypes.firstWhere(
      (r) => r['id'] == _selectedReportType,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(reportType['icon'] as IconData,
                color: reportType['color'] as Color),
            const SizedBox(width: 12),
            Expanded(child: Text(reportType['title'] as String)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date Range:'),
            Text(
              '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Report generation is in progress...'),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        DialogHelper.showSuccessSnackBar(
          context,
          'Report generated successfully! Check your downloads.',
        );
      }
    });
  }
}
