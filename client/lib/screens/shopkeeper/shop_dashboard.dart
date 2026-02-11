import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/theme_toggle.dart';
import '../role_selection/role_selection_screen.dart';

class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});

  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ShopHomeTab(),
    const OffersManagementTab(),
    const LeadsTab(),
    const ShopProfileTab(),
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
              icon: Icon(Icons.local_offer_rounded),
              label: 'Offers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Leads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_rounded),
              label: 'Shop',
            ),
          ],
        ),
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton.extended(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Offer'),
              )
            : null,
      ),
    );
  }
}

class ShopHomeTab extends StatelessWidget {
  const ShopHomeTab({super.key});

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
                    'My Shop Dashboard',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Manage your business',
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
                              'Active Offers',
                              '12',
                              Icons.local_offer_rounded,
                              AppColors.primaryGradient,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Total Leads',
                              '48',
                              Icons.people_rounded,
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
                              'Views Today',
                              '156',
                              Icons.visibility_rounded,
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
                              'Rating',
                              '4.8',
                              Icons.star_rounded,
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
                        'Add New Offer',
                        'Create attractive offers for customers',
                        Icons.add_circle_rounded,
                        AppColors.primary,
                      ),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: _buildQuickAction(
                        context,
                        'View Analytics',
                        'Check your shop performance',
                        Icons.analytics_rounded,
                        AppColors.accent,
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

class OffersManagementTab extends StatelessWidget {
  const OffersManagementTab({super.key});

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
              title: const Text('My Offers'),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_offer_rounded,
                              color: Colors.white),
                        ),
                        title: Text('Offer ${index + 1}'),
                        subtitle: Text('${20 + index * 10}% OFF • Active'),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(child: Text('Edit')),
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

class LeadsTab extends StatelessWidget {
  const LeadsTab({super.key});

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
              title: const Text('Customer Leads'),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Customer leads will appear here',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopProfileTab extends StatelessWidget {
  const ShopProfileTab({super.key});

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
              title: const Text('Shop Profile'),
              actions: const [
                ThemeToggleButton(),
              ],
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.store_rounded, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'My Shop Name',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Electronics & Gadgets',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  const ThemeToggle(),
                  _buildProfileOption(
                      context, Icons.edit_rounded, 'Edit Shop Profile'),
                  _buildProfileOption(
                      context, Icons.business_rounded, 'Business Details'),
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
