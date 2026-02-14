import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';

/// Security page for Admin (and optionally other roles later).
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Security'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.lock_rounded, color: AppColors.primary),
                      title: const Text('Change password'),
                      subtitle: const Text('Update your login password'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password change is not required for OTP-based login. Contact support if you need to secure your account.'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.phone_android_rounded, color: AppColors.primary),
                      title: const Text('Two-step verification'),
                      subtitle: const Text('Add extra security with 2FA'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        DialogHelper.showSuccessSnackBar(
                          context,
                          'Two-step verification coming soon',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.devices_rounded, color: AppColors.primary),
                      title: const Text('Active sessions'),
                      subtitle: const Text('Manage devices where you\'re logged in'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Session management coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
