import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../auth/login_screen.dart';
import '../../models/role_enum.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/gradient_card.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.backgroundGradient
              : AppColors.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                FadeInDown(
                  child: Image.asset(
                    'assets/Dofferlogo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    AppStrings.selectRole,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                const SizedBox(height: 60),
                Expanded(
                  child: ListView(
                    children: [
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: _buildRoleCard(
                          context,
                          title: AppStrings.customerRole,
                          description: AppStrings.customerDesc,
                          icon: Icons.shopping_bag_rounded,
                          gradient: AppColors.primaryGradient,
                          onTap: () =>
                              _navigateToLogin(context, UserRole.customer),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInUp(
                        delay: const Duration(milliseconds: 500),
                        child: _buildRoleCard(
                          context,
                          title: AppStrings.shopkeeperRole,
                          description: AppStrings.shopkeeperDesc,
                          icon: Icons.store_rounded,
                          gradient: AppColors.accentGradient,
                          onTap: () =>
                              _navigateToLogin(context, UserRole.shopkeeper),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInUp(
                        delay: const Duration(milliseconds: 600),
                        child: _buildRoleCard(
                          context,
                          title: AppStrings.adminRole,
                          description: AppStrings.adminDesc,
                          icon: Icons.admin_panel_settings_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () =>
                              _navigateToLogin(context, UserRole.admin),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GradientCard(
      gradient: gradient,
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _navigateToLogin(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(role: role),
      ),
    );
  }
}
