import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/revamp/login_revamp_theme.dart';
import '../../models/role_enum.dart';
import '../auth/Register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 430).clamp(0.84, 1.0);
    final sidePad = 24.0 * scale;

    final signupRoles = <_SignupRole>[
      _SignupRole(
        title: AppStrings.customerRole,
        description: AppStrings.customerDesc,
        icon: Icons.shopping_bag_rounded,
        role: UserRole.customer,
        tint: const Color(0xFF3AAE7E),
        iconBackground: const Color(0xFFEAF7F1),
      ),
      _SignupRole(
        title: AppStrings.shopkeeperRole,
        description: AppStrings.shopkeeperDesc,
        icon: Icons.store_rounded,
        role: UserRole.shopkeeper,
        tint: const Color(0xFF6F77D9),
        iconBackground: const Color(0xFFEEF0FD),
      ),
      _SignupRole(
        title: AppStrings.salesAgentRole,
        description: AppStrings.salesAgentDesc,
        icon: Icons.support_agent_rounded,
        role: UserRole.companySalesAgent,
        tint: const Color(0xFFE18735),
        iconBackground: const Color(0xFFFCEEDC),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                if (Navigator.of(context).canPop())
                  Positioned(
                    left: sidePad,
                    top: 16 * scale,
                    child: Material(
                      color: const Color(0xFFF2F4F8),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1B2331),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      sidePad, 16 * scale, sidePad, 12 * scale),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44 * scale,
                                height: 44 * scale,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFAB53D),
                                      Color(0xFFF8991D)
                                    ],
                                  ),
                                ),
                                child: const RotatedBox(
                                  quarterTurns: 1,
                                  child: Icon(
                                    Icons.local_offer_outlined,
                                    color: Colors.white,
                                    size: 21,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10 * scale),
                              Text.rich(
                                TextSpan(
                                  style: LoginRevampTypography.sectionTitle
                                      .copyWith(
                                    color: const Color(0xFF151B2D),
                                    fontSize: 28 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                    const TextSpan(text: 'My'),
                                    TextSpan(
                                      text: 'Offers',
                                      style: LoginRevampTypography.sectionTitle
                                          .copyWith(
                                        color: LoginRevampColors.accent,
                                        fontSize: 28 * scale,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 16 * scale),
                            child: Text(
                              'Choose how you want to use the app and continue signup.',
                              textAlign: TextAlign.center,
                              style: LoginRevampTypography.sectionSubtitle
                                  .copyWith(
                                fontSize: 14,
                                color: const Color(0xFF67758A),
                              ),
                            ),
                          ),
                          ListView.separated(
                            itemCount: signupRoles.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (_, __) =>
                                SizedBox(height: 12 * scale),
                            itemBuilder: (ctx, i) => _buildSignupRoleCard(
                              ctx,
                              item: signupRoles[i],
                              scale: scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupRoleCard(
    BuildContext context, {
    required _SignupRole item,
    required double scale,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegisterScreen(role: item.role)),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: BoxConstraints(minHeight: 106 * scale),
          padding: EdgeInsets.symmetric(
              horizontal: 15 * scale, vertical: 14 * scale),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                item.iconBackground.withValues(alpha: 0.40),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: item.tint.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: item.tint.withValues(alpha: 0.13),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: item.iconBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: item.tint.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: item.tint.withValues(alpha: 0.16),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(item.icon, size: 32, color: item.tint),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14 * scale),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: LoginRevampTypography.sectionTitle.copyWith(
                        fontSize: 17.2 * scale,
                        color: const Color(0xFF15172B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LoginRevampTypography.body.copyWith(
                        fontSize: 13.1,
                        color: const Color(0xFF666C86),
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6 * scale),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: item.tint.withValues(alpha: 0.22)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: item.tint,
                  size: 21,
                ),
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
  final Color iconBackground;

  const _SignupRole({
    required this.title,
    required this.description,
    required this.icon,
    required this.role,
    required this.tint,
    required this.iconBackground,
  });
}
