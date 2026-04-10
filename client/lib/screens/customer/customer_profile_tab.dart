import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/dialog_helper.dart';
import '../../core/constants/app_strings.dart';
import '../../models/role_enum.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../auth/login_screen.dart';
import '../common/about_page.dart';
import '../common/addresses_page.dart';
import '../common/edit_profile_page.dart';
import '../common/help_support_page.dart';
import '../common/reward_wallet_screen.dart';
import '../common/settings_page.dart';
import '../customer/become_ssa_onboarding_screen.dart';
import '../ssa/ssa_dashboard.dart';

// ── Palette (consistent with Loans / EditProfile) ─────────────────────────────
class _PP {
  static const canvas        = Color(0xFFF3F5F8);
  static const surface       = Color(0xFFFFFFFF);
  static const border        = Color(0xFFE7E9EE);
  static const headerBg      = Color(0xFF2D3850);
  static const headerAvatar  = Color(0xFFF8AA23);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFF7A8293);
  static const ssaBannerBg   = Color(0xFFE9EDF5);
  static const ssaBannerBdr  = Color(0xFFD5DBE8);
  static const white         = Color(0xFFFFFFFF);
}

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
      backgroundColor: _PP.canvas,
      body: SafeArea(
        child: FutureBuilder<UserModel>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final displayName =
                (user == null || user.name.isEmpty) ? 'Customer' : user.name;
            final displayPhone = user?.phone ?? '';
            final initial =
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C';

            return ListView(
              children: [
                // ── Header ─────────────────────────────────────────────────
                _buildHeader(
                  initial: initial,
                  displayName: displayName,
                  displayPhone: displayPhone,
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                ),
                // ── Menu tiles ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  child: Column(
                    children: [
                      _tile(
                        icon: Icons.edit_outlined,
                        iconTint: const Color(0xFFF59E0B),
                        iconBg: const Color(0xFFF7ECDD),
                        title: 'Edit Profile',
                        subtitle: 'Update name, photo, details',
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                EditProfilePage(user: user, onSaved: _reload),
                          ));
                          if (mounted) _reload();
                        },
                      ),
                      _tile(
                        icon: Icons.location_on_outlined,
                        iconTint: const Color(0xFFEF4444),
                        iconBg: const Color(0xFFF8DDDF),
                        title: 'My Addresses',
                        subtitle: 'Manage saved locations',
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AddressesPage(onSaved: _reload),
                          ));
                          if (mounted) _reload();
                        },
                      ),
                      _tile(
                        icon: Icons.account_balance_wallet_outlined,
                        iconTint: const Color(0xFFF59E0B),
                        iconBg: const Color(0xFFF8EEDD),
                        title: 'Wallet & Coins',
                        subtitle: 'Track rewards and coin balance',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RewardWalletScreen(
                                title: 'Customer Wallet'),
                          ),
                        ),
                      ),
                      if (user != null && user.hasRole(UserRole.customer))
                        _tile(
                          icon: Icons.groups_2_outlined,
                          iconTint: const Color(0xFFF59E0B),
                          iconBg: const Color(0xFFF8EEDD),
                          title: AppStrings.becomeSsa,
                          subtitle: 'Earn by managing coupons',
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  const BecomeSSAOnboardingScreen(),
                            ));
                            if (mounted) _reload();
                          },
                        ),
                      _tile(
                        icon: Icons.settings_outlined,
                        iconTint: const Color(0xFF6B7280),
                        iconBg: const Color(0xFFEAEDF2),
                        title: 'Settings',
                        subtitle: 'Notifications, privacy, language',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SettingsPage()),
                        ),
                      ),
                      _tile(
                        icon: Icons.support_agent_outlined,
                        iconTint: const Color(0xFF6366F1),
                        iconBg: const Color(0xFFE8EAFD),
                        title: 'Help & Support',
                        subtitle: 'Chat with support team',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const HelpSupportPage()),
                        ),
                      ),
                      _tile(
                        icon: Icons.info_outline_rounded,
                        iconTint: const Color(0xFF0284C7),
                        iconBg: const Color(0xFFDFF3FF),
                        title: 'About',
                        subtitle: 'Version, terms and legal details',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AboutPage()),
                        ),
                      ),
                      // ── SSA switch banner ─────────────────────────────
                      if (user != null && user.hasRole(UserRole.ssa))
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _PP.ssaBannerBg,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: _PP.ssaBannerBdr),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz_rounded,
                                    color: Color(0xFF334155), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Switch to SSA dashboard',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _PP.textPrimary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const SsaDashboard()),
                                      (route) => false,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF0284C7),
                                  ),
                                  child: Text(
                                    'Open',
                                    style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // ── Logout ────────────────────────────────────────
                      _tile(
                        icon: Icons.logout_rounded,
                        iconTint: const Color(0xFFDC2626),
                        iconBg: const Color(0xFFFEE2E2),
                        title: 'Logout',
                        subtitle: 'Sign out from this account',
                        isDestructive: true,
                        onTap: () async {
                          final shouldLogout =
                              await DialogHelper.showLogoutDialog(context);
                          if (shouldLogout && mounted) {
                            await AuthStore.clearPersistedAuth();
                            AuthStore.clear();
                            if (!mounted) return;
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

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader({
    required String initial,
    required String displayName,
    required String displayPhone,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      decoration: const BoxDecoration(color: _PP.headerBg),
      child: Column(
        children: [
          // Avatar circle
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _PP.headerAvatar,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.dmSans(
                color: _PP.white,
                fontWeight: FontWeight.w700,
                fontSize: 42,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: _PP.white),
            )
          else ...[
            Text(
              displayName,
              style: GoogleFonts.dmSans(
                color: _PP.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (displayPhone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '+91 $displayPhone',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFFD4D9E3),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Menu tile ────────────────────────────────────────────────────────────────
  Widget _tile({
    required IconData icon,
    required Color iconTint,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _PP.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _PP.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBg,
                  ),
                  child: Icon(icon, color: iconTint, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDestructive
                              ? const Color(0xFFB91C1C)
                              : _PP.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: _PP.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _PP.textMuted,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
