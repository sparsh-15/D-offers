import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/profile_option_tile.dart';
import '../role_selection/role_selection_screen.dart';
import '../common/edit_profile_page.dart';
import '../common/addresses_page.dart';
import '../common/settings_page.dart';
import '../common/help_support_page.dart';
import '../common/about_page.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/user_model.dart';

class CustomerProfileTab extends StatefulWidget {
  const CustomerProfileTab({super.key});

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.backgroundGradient
            : AppColors.lightBackgroundGradient,
      ),
      child: SafeArea(
        child: FutureBuilder<UserModel>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final displayName = user?.name.isEmpty == true || user == null
                ? 'Customer'
                : user.name;
            final displayPhone = user?.phone ?? '';

            return Column(
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
                  child:
                      Icon(Icons.person_rounded, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const CircularProgressIndicator()
                else ...[
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (displayPhone.isNotEmpty)
                    Text(
                      '+91 $displayPhone',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      const ThemeToggle(),
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
                        icon: Icons.location_on_rounded,
                        title: 'My Addresses',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddressesPage(onSaved: _reload),
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
                                  builder: (_) => const RoleSelectionScreen()),
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
