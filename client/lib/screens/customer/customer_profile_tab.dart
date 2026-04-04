import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F3),
      body: SafeArea(
        child: FutureBuilder<UserModel>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final displayName = user?.name.isEmpty == true || user == null
                ? 'Customer'
                : user.name;
            final displayPhone = user?.phone ?? '';
            final initial =
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C';

            return ListView(
              children: [
                _buildHeader(
                  context,
                  initial: initial,
                  displayName: displayName,
                  displayPhone: displayPhone,
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  child: Column(
                    children: [
                      _buildMenuTile(
                        icon: Icons.edit_outlined,
                        iconTint: const Color(0xFFF59E0B),
                        iconBackground: const Color(0xFFF7ECDD),
                        title: 'Edit Profile',
                        subtitle: 'Update name, photo, details',
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
                      _buildMenuTile(
                        icon: Icons.location_on_outlined,
                        iconTint: const Color(0xFFEF4444),
                        iconBackground: const Color(0xFFF8DDDF),
                        title: 'My Addresses',
                        subtitle: 'Manage saved locations',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddressesPage(onSaved: _reload),
                            ),
                          );
                          if (mounted) _reload();
                        },
                      ),
                      _buildMenuTile(
                        icon: Icons.account_balance_wallet_outlined,
                        iconTint: const Color(0xFFF59E0B),
                        iconBackground: const Color(0xFFF8EEDD),
                        title: 'Wallet & Coins',
                        subtitle: 'Track rewards and coin balance',
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
                      if (user != null && user.hasRole(UserRole.customer))
                        _buildMenuTile(
                          icon: Icons.groups_2_outlined,
                          iconTint: const Color(0xFFF59E0B),
                          iconBackground: const Color(0xFFF8EEDD),
                          title: AppStrings.becomeSsa,
                          subtitle: 'Earn by managing coupons',
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
                      _buildMenuTile(
                        icon: Icons.settings_outlined,
                        iconTint: const Color(0xFF6B7280),
                        iconBackground: const Color(0xFFEAEDF2),
                        title: 'Settings',
                        subtitle: 'Notifications, privacy, language',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      _buildMenuTile(
                        icon: Icons.support_agent_outlined,
                        iconTint: const Color(0xFF6366F1),
                        iconBackground: const Color(0xFFE8EAFD),
                        title: 'Help & Support',
                        subtitle: 'Chat with support team',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HelpSupportPage(),
                            ),
                          );
                        },
                      ),
                      _buildMenuTile(
                        icon: Icons.info_outline_rounded,
                        iconTint: const Color(0xFF0284C7),
                        iconBackground: const Color(0xFFDFF3FF),
                        title: 'About',
                        subtitle: 'Version, terms and legal details',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutPage(),
                            ),
                          );
                        },
                      ),
                      if (user != null && user.hasRole(UserRole.ssa))
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9EDF5),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFD5DBE8)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Color(0xFF334155),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Switch to SSA dashboard',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SsaDashboard(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text('Open'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      _buildMenuTile(
                        icon: Icons.logout_rounded,
                        iconTint: const Color(0xFFDC2626),
                        iconBackground: const Color(0xFFFEE2E2),
                        title: 'Logout',
                        subtitle: 'Sign out from this account',
                        isDestructive: true,
                        onTap: () async {
                          final shouldLogout =
                              await DialogHelper.showLogoutDialog(context);
                          if (shouldLogout && context.mounted) {
                            await AuthStore.clearPersistedAuth();
                            AuthStore.clear();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                            DialogHelper.showSuccessSnackBar(
                              context,
                              'Logged out successfully',
                            );
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

  Widget _buildHeader(
    BuildContext context, {
    required String initial,
    required String displayName,
    required String displayPhone,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF2D3850),
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF8AA23),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 46,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          else ...[
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (displayPhone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+91 $displayPhone',
                  style: const TextStyle(
                    color: Color(0xFFD4D9E3),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconTint,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7E9EE)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F0F172A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBackground,
                  ),
                  child: Icon(icon, color: iconTint, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDestructive
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF7A8293),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
