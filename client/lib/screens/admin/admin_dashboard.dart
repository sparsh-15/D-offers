import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/theme_toggle.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/user_model.dart';
import '../role_selection/role_selection_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminHomeTab(),
    const UsersManagementTab(),
    const ShopkeepersApprovalTab(),
    const AdminProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await DialogHelper.showExitDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.approval_rounded),
              label: 'Approvals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Admin',
            ),
          ],
        ),
      ),
    );
  }
}

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Platform Overview',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded),
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Total Users',
                              '1,234',
                              Icons.people_rounded,
                              AppColors.primaryGradient,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Shopkeepers',
                              '156',
                              Icons.store_rounded,
                              AppColors.accentGradient,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Active Offers',
                              '432',
                              Icons.local_offer_rounded,
                              const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Pending',
                              '8',
                              Icons.pending_rounded,
                              const LinearGradient(
                                colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInLeft(
                      child: Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      child: _buildQuickAction(
                        context,
                        AppStrings.manageUsers,
                        'View and manage all users',
                        Icons.people_rounded,
                        AppColors.primary,
                      ),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: _buildQuickAction(
                        context,
                        AppStrings.approveShopkeepers,
                        'Review pending shopkeeper requests',
                        Icons.approval_rounded,
                        AppColors.accent,
                      ),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: _buildQuickAction(
                        context,
                        AppStrings.platformAnalytics,
                        'View detailed platform statistics',
                        Icons.analytics_rounded,
                        AppColors.success,
                      ),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: _buildQuickAction(
                        context,
                        AppStrings.reports,
                        'Generate and view reports',
                        Icons.assessment_rounded,
                        AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Gradient gradient,
  ) {
    return GradientCard(
      gradient: gradient,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {},
      ),
    );
  }
}

class UsersManagementTab extends StatelessWidget {
  const UsersManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Manage Users'),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 10,
                itemBuilder: (context, index) {
                  return FadeInUp(
                    delay: Duration(milliseconds: 50 * index),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text('U${index + 1}'),
                        ),
                        title: Text('User ${index + 1}'),
                        subtitle: Text('+91 98765432${10 + index}'),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(child: Text('View Details')),
                            const PopupMenuItem(child: Text('Suspend')),
                            const PopupMenuItem(child: Text('Delete')),
                          ],
                        ),
                      ),
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

class ShopkeepersApprovalTab extends StatelessWidget {
  const ShopkeepersApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: _ShopkeepersApprovalBody(),
      ),
    );
  }
}

class _ShopkeepersApprovalBody extends StatefulWidget {
  @override
  State<_ShopkeepersApprovalBody> createState() =>
      _ShopkeepersApprovalBodyState();
}

class _ShopkeepersApprovalBodyState extends State<_ShopkeepersApprovalBody> {
  late Future<List<UserModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AuthService.instance.getShopkeepers(status: 'pending');
  }

  Future<void> _refresh() async {
    setState(() {
      _future = AuthService.instance.getShopkeepers(status: 'pending');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Pending Approvals'),
        ),
        Expanded(
          child: FutureBuilder<List<UserModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Failed to load shopkeepers\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Text('No pending shopkeepers'),
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final s = items[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: AppColors.accent,
                                    child: Icon(Icons.store_rounded,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name.isEmpty
                                              ? 'Shopkeeper'
                                              : s.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(
                                          '+91 ${s.phone}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        if (s.city.isNotEmpty)
                                          Text(
                                            '${s.city}, ${s.state} (${s.pincode})',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _approve(context, s.id, s.name),
                                      icon: const Icon(Icons.check_rounded,
                                          size: 18),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _reject(context, s.id, s.name),
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18),
                                      label: const Text('Reject'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(
                                            color: AppColors.error),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }

  Future<void> _approve(
      BuildContext context, String id, String displayName) async {
    try {
      await AuthService.instance.approveShopkeeper(id);
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(
          context, 'Approved $displayName successfully');
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _reject(
      BuildContext context, String id, String displayName) async {
    final confirm = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Reject Shopkeeper',
      message: 'Are you sure you want to reject $displayName?',
      confirmText: 'Reject',
      cancelText: 'Cancel',
      isDestructive: true,
    );
    if (!confirm) return;
    try {
      await AuthService.instance.rejectShopkeeper(id);
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(
          context, 'Rejected $displayName successfully');
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }
}

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Admin Profile'),
              actions: const [
                ThemeToggleButton(),
              ],
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.admin_panel_settings_rounded,
                  size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Admin User',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'admin@doffers.com',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  const ThemeToggle(),
                  _buildProfileOption(
                      context, Icons.edit_rounded, 'Edit Profile'),
                  _buildProfileOption(
                      context, Icons.security_rounded, 'Security'),
                  _buildProfileOption(
                      context, Icons.settings_rounded, 'Settings'),
                  _buildProfileOption(
                      context, Icons.help_rounded, 'Help & Support'),
                  _buildProfileOption(context, Icons.logout_rounded, 'Logout',
                      isDestructive: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title,
      {bool isDestructive = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon,
            color: isDestructive ? AppColors.error : AppColors.primary),
        title: Text(
          title,
          style: TextStyle(color: isDestructive ? AppColors.error : null),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () async {
          if (title == 'Logout') {
            final shouldLogout = await DialogHelper.showLogoutDialog(context);
            if (shouldLogout && context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
              DialogHelper.showSuccessSnackBar(
                  context, 'Logged out successfully');
            }
          }
        },
      ),
    );
  }
}
