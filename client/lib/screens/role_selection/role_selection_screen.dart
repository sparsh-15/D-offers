import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/constants/app_strings.dart';
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
        tint: AppColors.accent,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/Dofferlogo.png',
                  width: 88,
                  height: 88,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_offer_rounded,
                    color: AppColors.accent,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Join ${AppStrings.appName}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Select how you would like to use the app.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppTokens.spaceLG),
                Text(
                  'I am a…',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: signupRoles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceSM),
                    itemBuilder: (ctx, i) => _buildSignupRoleCard(
                      ctx,
                      item: signupRoles[i],
                    ),
                  ),
                ),
              ],
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
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppTokens.radiusMD),
            border: Border.all(color: item.tint.withValues(alpha: 0.20)),
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
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
