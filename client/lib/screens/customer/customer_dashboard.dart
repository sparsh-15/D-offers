import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/theme_toggle.dart';
import '../role_selection/role_selection_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const OffersTab(),
    const FavoritesTab(),
    const ProfileTab(),
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_offer_rounded),
                label: 'Offers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded),
                label: 'Favorites',
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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.backgroundGradient
            : AppColors.lightBackgroundGradient,
      ),
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
                    'Hello, Customer!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    AppStrings.exploreOffers,
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: AppStrings.search,
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.tune_rounded),
                              onPressed: () {},
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInLeft(
                      child: Text(
                        'Featured Offers',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OffersTab extends StatelessWidget {
  const OffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.backgroundGradient
            : AppColors.lightBackgroundGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('My Offers'),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Your saved offers will appear here',
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

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.backgroundGradient
            : AppColors.lightBackgroundGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Favorites'),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Your favorite shops will appear here',
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

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.backgroundGradient
            : AppColors.lightBackgroundGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Profile'),
              actions: const [
                ThemeToggleButton(),
              ],
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person_rounded, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Customer Name',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '+91 9876543210',
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
                      context, Icons.location_on_rounded, 'My Addresses'),
                  _buildProfileOption(
                      context, Icons.settings_rounded, 'Settings'),
                  _buildProfileOption(
                      context, Icons.help_rounded, 'Help & Support'),
                  _buildProfileOption(context, Icons.info_rounded, 'About'),
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
