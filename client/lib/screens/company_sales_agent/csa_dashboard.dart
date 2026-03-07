import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/company_sales_service.dart';
import 'csa_create_lead_screen.dart';

class CSADashboard extends StatefulWidget {
  const CSADashboard({super.key});

  @override
  State<CSADashboard> createState() => _CSADashboardState();
}

class _CSADashboardState extends State<CSADashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = const [
    CSAHomeTab(),
    CSAShopsTab(),
    CSAPerformanceTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.textMuted,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.store_rounded),
                label: 'Shops',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: 'Performance',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CSAHomeTab extends StatefulWidget {
  const CSAHomeTab({super.key});

  @override
  State<CSAHomeTab> createState() => _CSAHomeTabState();
}

class _CSAHomeTabState extends State<CSAHomeTab> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = CompanySalesService.instance.getStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales Dashboard',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppTokens.spaceXS),
              Text(
                'Your onboarding and incentives at a glance',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTokens.spaceLG),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Text(
                          'Unable to load stats',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    final data = snapshot.data!;
                    final onboardings =
                        Map<String, dynamic>.from(data['onboardings'] ?? {});
                    final shops = Map<String, dynamic>.from(data['shops'] ?? {});
                    final revenue =
                        Map<String, dynamic>.from(data['revenue'] ?? {});
                    final incentives =
                        Map<String, dynamic>.from(data['incentives'] ?? {});

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'My Onboardings',
                                  primaryValue:
                                      '${onboardings['thisMonth'] ?? 0}',
                                  primaryLabel: 'This month',
                                  secondaryValue:
                                      '${onboardings['total'] ?? 0}',
                                  secondaryLabel: 'Total',
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSM),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Shops',
                                  primaryValue: '${shops['active'] ?? 0}',
                                  primaryLabel: 'Active',
                                  secondaryValue: '${shops['churned'] ?? 0}',
                                  secondaryLabel: 'Churned',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'Revenue',
                                  primaryValue:
                                      '₹${(revenue['thisMonth'] ?? 0).toStringAsFixed(0)}',
                                  primaryLabel: 'This month',
                                  secondaryValue:
                                      '₹${(revenue['total'] ?? 0).toStringAsFixed(0)}',
                                  secondaryLabel: 'Lifetime',
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSM),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Estimated Incentive',
                                  primaryValue:
                                      '₹${(incentives['estimated'] ?? 0).toStringAsFixed(0)}',
                                  primaryLabel: 'This month (est.)',
                                  secondaryValue: '',
                                  secondaryLabel: '',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceLG),
                          Text(
                            'My coupons',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppTokens.spaceSM),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: CompanySalesService.instance.getCoupons(),
                            builder: (context, couponSnapshot) {
                              if (couponSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final coupons =
                                  couponSnapshot.data ?? [];
                              if (coupons.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No coupons yet.',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                );
                              }
                              return Column(
                                children: coupons.map((c) {
                                  final pct = (c['discountValue'] is num)
                                      ? (c['discountValue'] as num).toInt()
                                      : int.tryParse(
                                            c['discountValue']?.toString() ??
                                                '0',
                                          ) ??
                                          0;
                                  final code =
                                      c['code']?.toString() ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppTokens.spaceSM),
                                    child: InkWell(
                                      onTap: () {
                                        if (code.isNotEmpty) {
                                          Clipboard.setData(
                                            ClipboardData(text: code),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Copied: $code',
                                              ),
                                              duration: const Duration(
                                                  seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(
                                          AppTokens.radiusMD),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTokens.spaceMD,
                                          vertical: AppTokens.spaceSM,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBackground,
                                          borderRadius: BorderRadius.circular(
                                              AppTokens.radiusMD),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '$pct% off',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    color: AppColors
                                                        .textPrimary,
                                                  ),
                                            ),
                                            SelectableText(
                                              code,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontFamily: 'monospace',
                                                    color: AppColors.accent,
                                                  ),
                                            ),
                                            Icon(
                                              Icons.copy_rounded,
                                              size: 18,
                                              color: AppColors.textSecondary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String primaryValue;
  final String primaryLabel;
  final String secondaryValue;
  final String secondaryLabel;

  const _MetricCard({
    required this.title,
    required this.primaryValue,
    required this.primaryLabel,
    required this.secondaryValue,
    required this.secondaryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTokens.spaceSM),
          Text(
            primaryValue,
            style: theme.textTheme.displayMedium
                ?.copyWith(color: AppColors.textPrimary),
          ),
          if (primaryLabel.isNotEmpty)
            Text(
              primaryLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          if (secondaryLabel.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spaceSM),
            Text(
              secondaryValue,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            Text(
              secondaryLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class CSAShopsTab extends StatefulWidget {
  const CSAShopsTab({super.key});

  @override
  State<CSAShopsTab> createState() => _CSAShopsTabState();
}

class _CSAShopsTabState extends State<CSAShopsTab> {
  String _filter = 'all';
  late Future<Map<String, dynamic>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _shopsFuture = CompanySalesService.instance.getShops();
  }

  Future<void> _reload() async {
    setState(() {
      _shopsFuture = CompanySalesService.instance.getShops(
        status: _filter == 'all' ? null : _filter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Shops',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppTokens.spaceXS),
                      Text(
                        'Track onboarding and subscriptions',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_rounded,
                            color: AppColors.accent),
                        tooltip: 'Add lead',
                        onPressed: () async {
                          final created = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const CsaCreateLeadScreen(),
                            ),
                          );
                          if (created == true) _reload();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.textSecondary),
                        onPressed: _reload,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(value: 'active', label: Text('Active')),
                  ButtonSegment(value: 'expired', label: Text('Expired')),
                  ButtonSegment(value: 'none', label: Text('No Plan')),
                ],
                selected: {_filter},
                onSelectionChanged: (value) {
                  setState(() {
                    _filter = value.first;
                  });
                  _reload();
                },
              ),
            ),
            const SizedBox(height: AppTokens.spaceSM),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _shopsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text(
                        'Unable to load shops',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  final data = snapshot.data!;
                  final shops = List<Map<String, dynamic>>.from(
                    data['shops'] as List<dynamic>,
                  );
                  if (shops.isEmpty) {
                    return Center(
                      child: Text(
                        'No shops yet.\nStart onboarding merchants to see them here.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.all(AppTokens.spaceMD),
                      itemCount: shops.length,
                      itemBuilder: (context, index) {
                        final shop = shops[index];
                        return _ShopTile(shop: shop);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  final Map<String, dynamic> shop;

  const _ShopTile({required this.shop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscription = shop['subscription'] as Map<String, dynamic>?;
    final status = subscription?['status'] as String? ?? 'none';

    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'expired':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spaceSM),
      padding: const EdgeInsets.all(AppTokens.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusLG),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.elevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.store_rounded,
                color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(width: AppTokens.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (shop['name'] as String? ?? 'Shop').trim(),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  shop['phone'] as String? ?? '',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                if ((shop['city'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${shop['city']}, ${shop['state'] ?? ''}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTokens.spaceSM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                ),
                child: Text(
                  status == 'none'
                      ? 'No Plan'
                      : status[0].toUpperCase() + status.substring(1),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (subscription != null &&
                  subscription['planName'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  subscription['planName'] as String,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class CSAPerformanceTab extends StatefulWidget {
  const CSAPerformanceTab({super.key});

  @override
  State<CSAPerformanceTab> createState() => _CSAPerformanceTabState();
}

class _CSAPerformanceTabState extends State<CSAPerformanceTab> {
  String? _selectedMonth;
  late Future<Map<String, dynamic>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = CompanySalesService.instance.getReports();
  }

  Future<void> _reload() async {
    setState(() {
      _reportsFuture =
          CompanySalesService.instance.getReports(month: _selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppTokens.spaceXS),
                      Text(
                        'Monthly onboarding & commissions',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.textSecondary),
                    onPressed: _reload,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceMD),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _reportsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Text(
                          'Unable to load performance data',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    final data = snapshot.data!;
                    final month = data['month'] as String? ?? '';
                    if (_selectedMonth == null && month.isNotEmpty) {
                      _selectedMonth = month;
                    }
                    final onboardingTimeline =
                        List<Map<String, dynamic>>.from(
                      data['onboardingTimeline'] as List<dynamic>? ?? [],
                    );
                    final shopStatus =
                        Map<String, dynamic>.from(data['shopStatus'] ?? {});
                    final commissions =
                        Map<String, dynamic>.from(data['commissions'] ?? {});

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            month,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          _MetricCard(
                            title: 'Onboardings this month',
                            primaryValue:
                                '${onboardingTimeline.fold<int>(0, (sum, item) => sum + (item['count'] as int? ?? 0))}',
                            primaryLabel: '',
                            secondaryValue: '',
                            secondaryLabel: '',
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'Active Shops',
                                  primaryValue:
                                      '${shopStatus['active'] ?? 0}',
                                  primaryLabel: '',
                                  secondaryValue: '',
                                  secondaryLabel: '',
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSM),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Churned Shops',
                                  primaryValue:
                                      '${shopStatus['churned'] ?? 0}',
                                  primaryLabel: '',
                                  secondaryValue: '',
                                  secondaryLabel: '',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          _MetricCard(
                            title: 'Commission (earned)',
                            primaryValue:
                                '₹${(commissions['earned'] ?? 0).toStringAsFixed(0)}',
                            primaryLabel: '',
                            secondaryValue: '',
                            secondaryLabel: '',
                          ),
                          const SizedBox(height: AppTokens.spaceLG),
                          Text(
                            'Onboarding timeline',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppTokens.spaceSM),
                          if (onboardingTimeline.isEmpty)
                            Text(
                              'No onboardings recorded for this month.',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            )
                          else
                            Column(
                              children: onboardingTimeline
                                  .map(
                                    (row) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppTokens.spaceXS,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              row['date'] as String? ?? '',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width:
                                                (row['count'] as int? ?? 0) *
                                                        12 +
                                                    8,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: AppColors.accentDim,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(
                                              width: AppTokens.spaceXS),
                                          Text(
                                            '${row['count'] ?? 0}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

