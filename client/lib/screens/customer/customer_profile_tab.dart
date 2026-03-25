import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/profile_option_tile.dart';
import '../auth/login_screen.dart';
import '../common/edit_profile_page.dart';
import '../common/addresses_page.dart';
import '../common/settings_page.dart';
import '../common/help_support_page.dart';
import '../common/about_page.dart';
import '../common/reward_wallet_screen.dart';
import '../customer/become_ssa_onboarding_screen.dart';
import '../ssa/ssa_dashboard.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/user_model.dart';
import '../../models/role_enum.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/theme_helper.dart';

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
                ? 'Customer'
                : user.name;
            final displayPhone = user?.phone ?? '';

            return Column(
              children: [
                AppBar(
                  backgroundColor: AppColors.transparent,
                  title: const Text('Profile'),
                  actions: const [
                    ThemeToggleButton(),
                  ],
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
                  if (displayPhone.isNotEmpty)
                    Text(
                      '+91 $displayPhone',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
                const SizedBox(height: 24),
                if (user != null && user.role == UserRole.ssa) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer view',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Switch to SSA dashboard',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
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
                                    builder: (_) => const SsaDashboard(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
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
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Wallet & Coins',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RewardWalletScreen(
                                title: 'Customer Wallet',
                              ),
                            ),
                          );
                        },
                      ),
                      if (user != null && user.role == UserRole.customer)
                        ProfileOptionTile(
                          icon: Icons.headset_mic_rounded,
                          title: AppStrings.becomeSsa,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BecomeSSAOnboardingScreen(),
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
                            await AuthStore.clearPersistedAuth();
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
