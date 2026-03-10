import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../widgets/profile_option_tile.dart';
import '../auth/login_screen.dart';
import '../customer/customer_dashboard.dart';
import '../common/edit_profile_page.dart';
import '../common/settings_page.dart';
import '../common/help_support_page.dart';
import '../common/about_page.dart';
import '../../models/user_model.dart';
import '../../services/ssa_service.dart';
import '../../models/ssa_lead_model.dart';
import 'ssa_create_lead_screen.dart';

String _monthName(int month) {
  const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return names[(month - 1).clamp(0, 11)];
}

class SsaDashboard extends StatefulWidget {
  const SsaDashboard({super.key});

  @override
  State<SsaDashboard> createState() => _SsaDashboardState();
}

class _SsaDashboardState extends State<SsaDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = const [
    SsaHomeTab(),
    SsaShopkeepersTab(),
    SsaProfileTab(),
  ];

  void _switchToCustomerView() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerDashboard()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await DialogHelper.showExitDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            'SSA',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Customer',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Theme(
                    data: Theme.of(context).copyWith(
                      switchTheme: SwitchThemeData(
                        thumbColor: WidgetStateProperty.resolveWith((s) =>
                            s.contains(WidgetState.selected)
                                ? AppColors.accent
                                : AppColors.textMuted),
                        trackColor: WidgetStateProperty.resolveWith((s) =>
                            s.contains(WidgetState.selected)
                                ? AppColors.accent.withValues(alpha: 0.4)
                                : AppColors.elevated),
                      ),
                    ),
                    child: Switch.adaptive(
                      value: false,
                      onChanged: (_) => _switchToCustomerView(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              label: 'Shopkeepers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class SsaHomeTab extends StatefulWidget {
  const SsaHomeTab({super.key});

  @override
  State<SsaHomeTab> createState() => _SsaHomeTabState();
}

class _SsaHomeTabState extends State<SsaHomeTab> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = SsaService.instance.getStats();
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
                        'SSA Dashboard',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppTokens.spaceXS),
                      Text(
                        'Your assigned shopkeepers and activity at a glance',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      switchTheme: SwitchThemeData(
                        thumbColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.accent;
                          }
                          return AppColors.textMuted;
                        }),
                        trackColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.accent
                                .withValues(alpha: 0.4);
                          }
                          return AppColors.elevated;
                        }),
                      ),
                    ),
                    child: Switch.adaptive(
                      value: true,
                      onChanged: (_) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomerDashboard(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
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
                    final stats = snapshot.data!;
                    final assignedShopkeepers =
                        (stats['assignedShopkeepers'] as num?)?.toInt() ?? 0;
                    final activeShops =
                        (stats['activeShops'] as num?)?.toInt() ?? 0;
                    final activeLeads =
                        (stats['activeLeads'] as num?)?.toInt() ?? 0;
                    final conversions =
                        (stats['conversions'] as num?)?.toInt() ?? 0;
                    final commission =
                        (stats['commission'] as num?)?.toDouble() ?? 0.0;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _SsaMetricCard(
                                  title: 'Assigned Shopkeepers',
                                  value: '$assignedShopkeepers',
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSM),
                              Expanded(
                                child: _SsaMetricCard(
                                  title: 'Active Shops',
                                  value: '$activeShops',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                          Row(
                            children: [
                              Expanded(
                                child: _SsaMetricCard(
                                  title: 'Active Leads',
                                  value: '$activeLeads',
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSM),
                              Expanded(
                                child: _SsaMetricCard(
                                  title: 'Commission',
                                  value: '₹${commission.toStringAsFixed(0)}',
                                ),
                              ),
                            ],
                          ),
                          if (conversions > 0) ...[
                            const SizedBox(height: AppTokens.spaceMD),
                            _SsaMetricCard(
                              title: 'Conversions',
                              value: '$conversions',
                            ),
                          ],
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
                            future: SsaService.instance.getCoupons(),
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
                                  final usages = c['usages'] as List<dynamic>? ?? [];
                                  String usageLabel = '';
                                  if (usages.isNotEmpty) {
                                    final count = usages.length;
                                    final latest = usages.first;
                                    final usedAt = latest['usedAt']?.toString();
                                    DateTime? dt;
                                    if (usedAt != null && usedAt.isNotEmpty) {
                                      dt = DateTime.tryParse(usedAt);
                                    }
                                    final dateStr = dt != null
                                        ? '${dt.day} ${_monthName(dt.month)} ${dt.year}'
                                        : '';
                                    usageLabel = count == 1
                                        ? (dateStr.isNotEmpty ? 'Used: $dateStr' : 'Used once')
                                        : 'Used $count times${dateStr.isNotEmpty ? ' • Last: $dateStr' : ''}';
                                  }
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
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
                                            if (usageLabel.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                usageLabel,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                              ),
                                            ],
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

class _SsaMetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _SsaMetricCard({
    required this.title,
    required this.value,
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
            value,
            style: theme.textTheme.titleLarge
                ?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class SsaShopkeepersTab extends StatefulWidget {
  const SsaShopkeepersTab({super.key});

  @override
  State<SsaShopkeepersTab> createState() => _SsaShopkeepersTabState();
}

class _SsaShopkeepersTabState extends State<SsaShopkeepersTab> {
  late Future<List<dynamic>> _shopkeepersFuture;
  late Future<List<SsaLead>> _leadsFuture;

  @override
  void initState() {
    super.initState();
    _shopkeepersFuture = SsaService.instance.getShopkeepers();
    _leadsFuture = SsaService.instance.getLeads();
  }

  Future<void> _reload() async {
    setState(() {
      _shopkeepersFuture = SsaService.instance.getShopkeepers();
      _leadsFuture = SsaService.instance.getLeads();
    });
  }

  Future<void> _retryLeadInvite(String leadId) async {
    try {
      await SsaService.instance.retryLeadInvite(leadId);
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'Invite OTP sent');
      _reload();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
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
                        'Leads & Shops',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppTokens.spaceXS),
                      Text(
                        'Track leads and onboarded shops',
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                color: AppColors.accent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<List<SsaLead>>(
                          future: _leadsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppTokens.spaceLG),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppTokens.spaceLG),
                                child: Text(
                                  'Unable to load leads',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }
                            final leads = snapshot.data ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Leads',
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.spaceSM),
                                if (leads.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppTokens.spaceLG),
                                    child: Text(
                                      'No leads yet. Tap the + button to create your first lead.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                  )
                                else
                                  ...leads.map(
                                    (lead) => Card(
                                      margin: const EdgeInsets.only(
                                          bottom: AppTokens.spaceSM),
                                      color: AppColors.cardBackground,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.accent
                                              .withValues(alpha: 0.15),
                                          child: const Icon(
                                            Icons.storefront_rounded,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        title: Text(
                                          lead.shopName,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                  color:
                                                      AppColors.textPrimary),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (lead.phone.isNotEmpty)
                                              Text(
                                                lead.phone,
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            if (lead.couponCode != null &&
                                                lead.couponCode!
                                                    .trim()
                                                    .isNotEmpty)
                                              Text(
                                                'Coupon: ${lead.couponCode}',
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            if ((lead.inviteStatus ?? '')
                                                .isNotEmpty)
                                              Text(
                                                'Invite: ${lead.inviteStatus}',
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: lead.inviteStatus ==
                                                          'failed'
                                                      ? AppColors.error
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            if ((lead.resultType ?? '')
                                                .isNotEmpty)
                                              Text(
                                                lead.resultType ==
                                                        'lead_created_existing_user_linked'
                                                    ? 'Linked to existing shopkeeper'
                                                    : 'New shopkeeper invited',
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _buildLeadStatusChip(
                                                context, lead.status),
                                            if (lead.inviteStatus == 'failed')
                                              TextButton(
                                                onPressed: () =>
                                                    _retryLeadInvite(lead.id),
                                                child: const Text('Retry OTP'),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppTokens.spaceLG),
                        FutureBuilder<List<dynamic>>(
                          future: _shopkeepersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppTokens.spaceLG),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppTokens.spaceLG),
                                child: Text(
                                  'Unable to load shops',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }
                            final list = snapshot.data ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shops',
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.spaceSM),
                                if (list.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppTokens.spaceLG),
                                    child: Text(
                                      'No onboarded shops yet.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                  )
                                else
                                  ...list.map((raw) {
                                    final item =
                                        raw as Map<String, dynamic>? ?? {};
                                    return Card(
                                      margin: const EdgeInsets.only(
                                          bottom: AppTokens.spaceSM),
                                      color: AppColors.cardBackground,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.accent
                                              .withValues(alpha: 0.2),
                                          child: const Icon(
                                            Icons.store_rounded,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        title: Text(
                                          item['shopName']?.toString() ??
                                              item['name']?.toString() ??
                                              'Shop',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        subtitle: Text(
                                          item['phone']?.toString() ??
                                              item['city']?.toString() ??
                                              '',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppTokens.space3XL),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: AppTokens.spaceMD,
                bottom: AppTokens.spaceLG,
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const SsaCreateLeadScreen(),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadStatusChip(BuildContext context, String status) {
    final theme = Theme.of(context);
    final normalized = status.toLowerCase();
    Color color;
    String label;
    switch (normalized) {
      case 'contacted':
        color = AppColors.info;
        label = 'CONTACTED';
        break;
      case 'converted':
        color = AppColors.success;
        label = 'CONVERTED';
        break;
      case 'lost':
        color = AppColors.error;
        label = 'LOST';
        break;
      default:
        color = AppColors.accent;
        label = 'OPEN';
    }
    return Chip(
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
    );
  }
}

class SsaProfileTab extends StatefulWidget {
  const SsaProfileTab({super.key});

  @override
  State<SsaProfileTab> createState() => _SsaProfileTabState();
}

class _SsaProfileTabState extends State<SsaProfileTab> {
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
                ? 'SSA'
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
