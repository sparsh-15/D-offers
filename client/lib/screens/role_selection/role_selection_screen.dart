import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/theme_helper.dart';
import '../../models/role_enum.dart';
import '../auth/Register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signupRoles = <_SignupRole>[
      _SignupRole(
        title: AppStrings.customerRole,
        description: AppStrings.customerDesc,
        icon: Icons.shopping_bag_rounded,
        role: UserRole.customer,
        tint: AppColors.primary,
      ),
      _SignupRole(
        title: AppStrings.shopkeeperRole,
        description: AppStrings.shopkeeperDesc,
        icon: Icons.store_rounded,
        role: UserRole.shopkeeper,
        tint: AppColors.accent,
      ),
      _SignupRole(
        title: AppStrings.salesAgentRole,
        description: AppStrings.salesAgentDesc,
        icon: Icons.support_agent_rounded,
        role: UserRole.companySalesAgent,
        tint: AppColors.gradientIndigo,
      ),
      _SignupRole(
        title: AppStrings.ssaRole,
        description: AppStrings.ssaDesc,
        icon: Icons.headset_mic_rounded,
        role: UserRole.ssa,
        tint: AppColors.gradientCoral,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeHelper.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  child: Image.asset(
                    'assets/Dofferlogo.png',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 12),
                FadeInDown(
                  delay: const Duration(milliseconds: 120),
                  child: Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeInDown(
                  delay: const Duration(milliseconds: 180),
                  child: Text(
                    'Register as a new user by selecting your role.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign Up',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ThemeHelper.getTextColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: signupRoles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = signupRoles[index];
                      return FadeInUp(
                        delay: Duration(milliseconds: 280 + (index * 70)),
                        child: _buildSignupRoleCard(
                          context,
                          item: item,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupRoleCard(BuildContext context,
      {required _SignupRole item}) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegisterScreen(role: item.role)),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ThemeHelper.getSurfaceColor(context).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.tint.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 20, color: item.tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ThemeHelper.getTextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: item.tint,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupRole {
  final String title;
  final String description;
  final IconData icon;
  final UserRole role;
  final Color tint;

  const _SignupRole({
    required this.title,
    required this.description,
    required this.icon,
    required this.role,
    required this.tint,
  });
}
