import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/theme_helper.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: AppColors.background,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeHelper.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceLG),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'D\'Offer Terms & Conditions',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  Text(
                    'These are placeholder terms and conditions for D\'Offer. '
                    'The final legal document will be provided here in a future update.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceLG),
                  Text(
                    'By proceeding with signup, you confirm that:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceSM),
                  const _BulletPoint(
                    text:
                        'You are providing accurate information about yourself and/or your business.',
                  ),
                  const _BulletPoint(
                    text:
                        'You consent to receive transactional communications (such as OTPs and important account updates).',
                  ),
                  const _BulletPoint(
                    text:
                        'You understand that offers and discounts are subject to availability and may change at any time.',
                  ),
                  const SizedBox(height: AppTokens.spaceLG),
                  Text(
                    'This page is for demonstration only. A full legal Terms & Conditions document will replace this content later.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

