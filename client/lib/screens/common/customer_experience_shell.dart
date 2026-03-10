import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../customer/customer_dashboard.dart';

class CustomerExperienceShell extends StatelessWidget {
  final String sourceLabel;

  const CustomerExperienceShell({
    super.key,
    required this.sourceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Reuse the existing customer UI and overlay a compact toggle
      // in the top-right corner without adding another full AppBar.
      body: Stack(
        children: [
          const CustomerDashboard(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Theme(
              data: Theme.of(context).copyWith(
                switchTheme: SwitchThemeData(
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.accent;
                    }
                    return AppColors.textMuted;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.accent.withValues(alpha: 0.4);
                    }
                    return Colors.black.withOpacity(0.2);
                  }),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Customer',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch.adaptive(
                      value: true,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (_) {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


