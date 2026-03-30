import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../services/company_sales_service.dart';
import '../../widgets/profile_option_tile.dart';
import '../auth/login_screen.dart';
import '../common/about_page.dart';
import '../common/customer_experience_shell.dart';
import '../common/edit_profile_page.dart';
import '../common/help_support_page.dart';
import '../common/settings_page.dart';
import 'csa_create_lead_screen.dart';

String _normalizeErrorMessage(Object error,
    {String fallback = 'Something went wrong. Please try again.'}) {
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  if (raw.isEmpty) return fallback;
  return raw;
}

void _showCsaSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : null,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 4 : 2),
    ),
  );
}

String _csaMonthName(int month) {
  const names = [
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
  return names[(month - 1).clamp(0, 11)];
}

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
    CSAProfileTab(),
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
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
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
  late Future<List<Map<String, dynamic>>> _couponsFuture;

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _reload() async {
    setState(() {
      _statsFuture = CompanySalesService.instance.getStats();
      _couponsFuture = CompanySalesService.instance.getCoupons();
    });
  }

  @override
  void initState() {
    super.initState();
    _statsFuture = CompanySalesService.instance.getStats();
    _couponsFuture = CompanySalesService.instance.getCoupons();
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
                    ],
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      switchTheme: SwitchThemeData(
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.accent;
                          }
                          return AppColors.textMuted;
                        }),
                        trackColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.accent.withValues(alpha: 0.4);
                          }
                          return AppColors.elevated;
                        }),
                      ),
                    ),
                    child: Switch.adaptive(
                      value: true,
                      onChanged: (_) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CustomerExperienceShell(
                              sourceLabel: 'Sales Agent',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.textSecondary),
                    tooltip: 'Refresh',
                    onPressed: _reload,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceLG),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
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
                        return ListView(
                          children: [
                            const SizedBox(height: AppTokens.space3XL),
                            _InlineErrorState(
                              message: _normalizeErrorMessage(
                                snapshot.error ?? 'Unable to load stats',
                                fallback: 'Unable to load stats',
                              ),
                              onRetry: _reload,
                            ),
                          ],
                        );
                      }
                      final data = snapshot.data!;
                      final onboardings =
                          Map<String, dynamic>.from(data['onboardings'] ?? {});
                      final shops =
                          Map<String, dynamic>.from(data['shops'] ?? {});
                      final revenue =
                          Map<String, dynamic>.from(data['revenue'] ?? {});
                      final incentives =
                          Map<String, dynamic>.from(data['incentives'] ?? {});

                      return ListView(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'My Onboardings',
                                  primaryValue:
                                      '${_asInt(onboardings['thisMonth'])}',
                                  primaryLabel: 'This month',
                                  secondaryValue:
                                      '${_asInt(onboardings['total'])}',
                                  secondaryLabel: 'Total',
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSM),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Shops',
                                  primaryValue: '${_asInt(shops['active'])}',
                                  primaryLabel: 'Active',
                                  secondaryValue: '${_asInt(shops['churned'])}',
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
                                      '₹${_asDouble(revenue['thisMonth']).toStringAsFixed(0)}',
                                  primaryLabel: 'This month',
                                  secondaryValue:
                                      '₹${_asDouble(revenue['total']).toStringAsFixed(0)}',
                                  secondaryLabel: 'Lifetime',
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSM),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Estimated Incentive',
                                  primaryValue:
                                      '₹${_asDouble(incentives['estimated']).toStringAsFixed(0)}',
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spaceSM),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _couponsFuture,
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
                              if (couponSnapshot.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    _normalizeErrorMessage(
                                      couponSnapshot.error!,
                                      fallback: 'Unable to load coupons',
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              }
                              final coupons = couponSnapshot.data ?? [];
                              if (coupons.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No coupons yet.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: coupons.map((c) {
                                  final pct = _asInt(c['discountValue']);
                                  final code = c['code']?.toString() ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppTokens.spaceSM),
                                    child: InkWell(
                                      onTap: () {
                                        if (code.isNotEmpty) {
                                          Clipboard.setData(
                                            ClipboardData(text: code),
                                          );
                                          _showCsaSnackBar(
                                            context,
                                            'Copied: $code',
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
                                                color: AppColors.textPrimary,
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
                      );
                    },
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

class _InlineErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTokens.spaceSM),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
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
  String _leadStatusFilter = 'all';
  int _currentPage = 1;
  final TextEditingController _leadSearchController = TextEditingController();
  Timer? _leadSearchDebounce;
  final Set<String> _retryingLeadIds = <String>{};
  late Future<Map<String, dynamic>> _shopsFuture;
  late Future<List<Map<String, dynamic>>> _leadsFuture;

  @override
  void initState() {
    super.initState();
    _leadSearchController.addListener(_onLeadSearchChanged);
    _loadLeads();
    _shopsFuture = CompanySalesService.instance.getShops(page: _currentPage);
  }

  @override
  void dispose() {
    _leadSearchDebounce?.cancel();
    _leadSearchController.removeListener(_onLeadSearchChanged);
    _leadSearchController.dispose();
    super.dispose();
  }

  void _onLeadSearchChanged() {
    _leadSearchDebounce?.cancel();
    _leadSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(_loadLeads);
    });
  }

  void _loadLeads() {
    final status = _leadStatusFilter == 'all' ? null : _leadStatusFilter;
    final search = _leadSearchController.text.trim();
    _leadsFuture = CompanySalesService.instance.getLeads(
      status: status,
      search: search.isEmpty ? null : search,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _shopsFuture = CompanySalesService.instance.getShops(
        status: _filter == 'all' ? null : _filter,
        page: _currentPage,
      );
      _loadLeads();
    });
  }

  Future<void> _retryLeadInvite(String leadId) async {
    final id = leadId.trim();
    if (id.isEmpty) {
      _showCsaSnackBar(context, 'Lead id is missing', isError: true);
      return;
    }

    setState(() => _retryingLeadIds.add(id));
    try {
      await CompanySalesService.instance.retryLeadInvite(id);
      if (!mounted) return;
      _showCsaSnackBar(context, 'Invite OTP sent');
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showCsaSnackBar(
        context,
        _normalizeErrorMessage(e, fallback: 'Failed to retry invite'),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _retryingLeadIds.remove(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
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
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.textSecondary),
                        onPressed: _reload,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
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
                        _currentPage = 1;
                      });
                      _reload();
                    },
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSM),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
                  child: Container(
                    padding: const EdgeInsets.all(AppTokens.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leads',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTokens.spaceSM),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _leadSearchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by shop/phone',
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTokens.radiusMD),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTokens.spaceSM),
                            SizedBox(
                              width: 140,
                              child: DropdownButtonFormField<String>(
                                initialValue: _leadStatusFilter,
                                isDense: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTokens.radiusMD),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'all', child: Text('All')),
                                  DropdownMenuItem(
                                      value: 'open', child: Text('Open')),
                                  DropdownMenuItem(
                                      value: 'contacted',
                                      child: Text('Contacted')),
                                  DropdownMenuItem(
                                      value: 'converted',
                                      child: Text('Converted')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _leadStatusFilter = value;
                                    _loadLeads();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.spaceSM),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _leadsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppTokens.spaceMD),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    top: AppTokens.spaceXS),
                                child: Text(
                                  _normalizeErrorMessage(
                                    snapshot.error!,
                                    fallback: 'Unable to load leads',
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              );
                            }

                            final leads =
                                snapshot.data ?? const <Map<String, dynamic>>[];
                            if (leads.isEmpty) {
                              return Text(
                                'No leads found for current filters.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              );
                            }

                            return Column(
                              children: leads.map((lead) {
                                final inviteStatus =
                                    lead['inviteStatus']?.toString() ??
                                        'pending';
                                final inviteColor = inviteStatus == 'failed'
                                    ? AppColors.error
                                    : AppColors.textSecondary;
                                final leadId = lead['id']?.toString() ?? '';
                                final isRetrying =
                                    _retryingLeadIds.contains(leadId);
                                return Card(
                                  margin: const EdgeInsets.only(
                                      bottom: AppTokens.spaceSM),
                                  color: AppColors.elevated,
                                  child: ListTile(
                                    title: Text(
                                      lead['shopName']?.toString() ??
                                          'Shop Lead',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lead['phone']?.toString() ?? '',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          'Invite: $inviteStatus',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: inviteColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: inviteStatus == 'failed'
                                        ? TextButton(
                                            onPressed: isRetrying
                                                ? null
                                                : () =>
                                                    _retryLeadInvite(leadId),
                                            child: Text(isRetrying
                                                ? 'Sending...'
                                                : 'Retry OTP'),
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
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
                        return _InlineErrorState(
                          message: _normalizeErrorMessage(
                            snapshot.error ?? 'Unable to load shops',
                            fallback: 'Unable to load shops',
                          ),
                          onRetry: _reload,
                        );
                      }
                      final data = snapshot.data!;
                      final shops = List<Map<String, dynamic>>.from(
                        data['shops'] as List<dynamic>,
                      );
                      final pagination =
                          Map<String, dynamic>.from(data['pagination'] ?? {});
                      final totalPages =
                          (pagination['pages'] as num?)?.toInt() ?? 1;
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
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.spaceMD,
                            AppTokens.spaceMD,
                            AppTokens.spaceMD,
                            AppTokens.space3XL,
                          ),
                          children: [
                            ...shops.map((shop) => _ShopTile(shop: shop)),
                            if (totalPages > 1)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: AppTokens.spaceSM),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton(
                                      onPressed: _currentPage > 1
                                          ? () {
                                              setState(() => _currentPage -= 1);
                                              _reload();
                                            }
                                          : null,
                                      child: const Text('Previous'),
                                    ),
                                    Text(
                                      'Page $_currentPage of $totalPages',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: _currentPage < totalPages
                                          ? () {
                                              setState(() => _currentPage += 1);
                                              _reload();
                                            }
                                          : null,
                                      child: const Text('Next'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              right: AppTokens.spaceMD,
              bottom: AppTokens.spaceLG,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final created = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const CsaCreateLeadScreen(),
                    ),
                  );
                  if (created == true && mounted) {
                    _reload();
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Lead'),
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
              if (subscription != null && subscription['planName'] != null) ...[
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

class CSAProfileTab extends StatefulWidget {
  const CSAProfileTab({super.key});

  @override
  State<CSAProfileTab> createState() => _CSAProfileTabState();
}

class _CSAProfileTabState extends State<CSAProfileTab> {
  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = AuthService.instance.fetchCurrentUser();
  }

  Future<void> _reload() async {
    setState(() {
      _userFuture = AuthService.instance.fetchCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: SafeArea(
        child: FutureBuilder<UserModel>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final displayName = user?.name.isEmpty == true || user == null
                ? 'Sales Agent'
                : user.name;

            return Column(
              children: [
                AppBar(
                  backgroundColor: AppColors.transparent,
                  title: const Text('Profile'),
                ),
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person_rounded,
                      size: 50, color: AppColors.white),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const CircularProgressIndicator()
                else ...[
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (user?.phone.isNotEmpty == true)
                    Text(
                      '+91 ${user?.phone}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      ProfileOptionTile(
                        icon: Icons.edit_rounded,
                        title: 'Edit Profile',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditProfilePage(
                                user: user,
                                onSaved: _reload,
                              ),
                            ),
                          );
                          if (mounted) _reload();
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.help_rounded,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HelpSupportPage(),
                            ),
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.info_rounded,
                        title: 'About',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutPage(),
                            ),
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isDestructive: true,
                        onTap: () async {
                          final shouldLogout =
                              await DialogHelper.showLogoutDialog(context);
                          if (shouldLogout && context.mounted) {
                            AuthStore.clear();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                            DialogHelper.showSuccessSnackBar(
                                context, 'Logged out successfully');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
  String? _selectedMonthLabel;
  String? _selectedMonthQuery;
  late Future<Map<String, dynamic>> _reportsFuture;

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  List<String> _monthOptions() {
    final now = DateTime.now();
    return List.generate(6, (index) {
      final d = DateTime(now.year, now.month - index, 1);
      return '${d.year}-${_csaMonthName(d.month)}';
    });
  }

  String _toMonthQuery(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return '';
    const months = {
      'Jan': '01',
      'Feb': '02',
      'Mar': '03',
      'Apr': '04',
      'May': '05',
      'Jun': '06',
      'Jul': '07',
      'Aug': '08',
      'Sep': '09',
      'Oct': '10',
      'Nov': '11',
      'Dec': '12',
    };
    final month = months[parts[1]];
    if (month == null) return '';
    return '${parts[0]}-$month';
  }

  String _toMonthLabel(String query) {
    final parts = query.split('-');
    if (parts.length != 2) return query;
    final monthNumber = int.tryParse(parts[1]);
    if (monthNumber == null || monthNumber < 1 || monthNumber > 12) {
      return query;
    }
    return '${parts[0]}-${_csaMonthName(monthNumber)}';
  }

  @override
  void initState() {
    super.initState();
    _reportsFuture = CompanySalesService.instance.getReports();
  }

  Future<void> _reload() async {
    setState(() {
      final month =
          (_selectedMonthQuery == null || _selectedMonthQuery!.isEmpty)
              ? null
              : _selectedMonthQuery;
      _reportsFuture = CompanySalesService.instance.getReports(month: month);
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
                      return _InlineErrorState(
                        message: _normalizeErrorMessage(
                          snapshot.error ?? 'Unable to load performance data',
                          fallback: 'Unable to load performance data',
                        ),
                        onRetry: _reload,
                      );
                    }
                    final data = snapshot.data!;
                    final month = data['month'] as String? ?? '';
                    if (_selectedMonthQuery == null && month.isNotEmpty) {
                      _selectedMonthQuery = month;
                      _selectedMonthLabel = _toMonthLabel(month);
                    }
                    final onboardingTimeline = List<Map<String, dynamic>>.from(
                      data['onboardingTimeline'] as List<dynamic>? ?? [],
                    );
                    final shopStatus =
                        Map<String, dynamic>.from(data['shopStatus'] ?? {});
                    final commissions =
                        Map<String, dynamic>.from(data['commissions'] ?? {});

                    final monthOptions = _monthOptions();

                    return RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue:
                                monthOptions.contains(_selectedMonthLabel)
                                    ? _selectedMonthLabel
                                    : null,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                            ),
                            dropdownColor: AppColors.elevated,
                            items: monthOptions
                                .map(
                                  (m) => DropdownMenuItem<String>(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMonthLabel = value;
                                final monthQuery =
                                    value == null ? null : _toMonthQuery(value);
                                _selectedMonthQuery = monthQuery;
                                _reportsFuture = CompanySalesService.instance
                                    .getReports(month: monthQuery);
                              });
                            },
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          Text(
                            month,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          _MetricCard(
                            title: 'Onboardings this month',
                            primaryValue:
                                '${onboardingTimeline.fold<int>(0, (sum, item) => sum + _asInt(item['count']))}',
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
                                      '${_asInt(shopStatus['active'])}',
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
                                      '${_asInt(shopStatus['churned'])}',
                                  primaryLabel: '',
                                  secondaryValue: '',
                                  secondaryLabel: '',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          _MetricCard(
                            title: 'Commission (earned, est.)',
                            primaryValue:
                                '₹${_asDouble(commissions['earned']).toStringAsFixed(0)}',
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
                                                _asInt(row['count']) * 12 + 8,
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
                                            '${_asInt(row['count'])}',
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
