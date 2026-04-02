import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/constants/app_strings.dart';
import '../auth/login_screen.dart';
import '../../services/auth_store.dart';
import '../../services/auth_service.dart';
import '../../models/role_enum.dart';
import '../customer/customer_dashboard.dart';
import '../shopkeeper/shop_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../company_sales_agent/csa_dashboard.dart';
import '../ssa/ssa_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 800));
    bool restored = false;

    try {
      restored = await AuthStore.loadAuth();
      if (restored && AuthStore.token != null) {
        // Validate token and refresh user profile
        final user = await AuthService.instance.fetchCurrentUser();
        AuthStore.currentUser = user;

        if (!mounted) return;

        await Future.delayed(const Duration(milliseconds: 1000));

        Widget destination;
        switch (user.role) {
          case UserRole.customer:
            destination = const CustomerDashboard();
            break;
          case UserRole.shopkeeper:
            destination = const ShopDashboard();
            break;
          case UserRole.admin:
            destination = const AdminDashboard();
            break;
          case UserRole.companySalesAgent:
            destination = const CSADashboard();
            break;
          case UserRole.ssa:
            destination = const SsaDashboard();
            break;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
        return;
      }
    } catch (_) {
      await AuthStore.clearPersistedAuth();
      AuthStore.clear();
    }

    // Fallback to login if we couldn't restore a valid session
    if (!mounted) return;
    await Future.delayed(
        const Duration(milliseconds: 2000)); // keep total ~2.8s
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              // color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(AppTokens.radiusXL),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/Dofferlogo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.local_offer_rounded,
                                color: AppColors.accent,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTokens.spaceLG),
                          Text(
                            AppStrings.appName,
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTokens.spaceSM),
                          Text(
                            AppStrings.appTagline,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Minimal loader
                  SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.borderSubtle,
                      color: AppColors.accent,
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space2XL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
