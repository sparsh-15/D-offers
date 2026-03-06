import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _shopkeepersFuture = SsaService.instance.getShopkeepers();
  }

  Future<void> _reload() async {
    setState(() {
      _shopkeepersFuture = SsaService.instance.getShopkeepers();
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
                        'Assigned Shopkeepers',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppTokens.spaceXS),
                      Text(
                        'Shops you have onboarded',
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
              child: FutureBuilder<List<dynamic>>(
                future: _shopkeepersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load shopkeepers',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No assigned shopkeepers yet',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _reload,
                    color: AppColors.accent,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spaceMD,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item =
                            list[index] as Map<String, dynamic>? ?? {};
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppTokens.spaceSM),
                          color: AppColors.cardBackground,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
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
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                            subtitle: Text(
                              item['phone']?.toString() ??
                                  item['city']?.toString() ??
                                  '',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        );
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
