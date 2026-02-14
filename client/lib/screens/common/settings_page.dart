import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../widgets/theme_toggle.dart';

/// Shared Settings page for all roles.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
          title: const Text('Settings'),
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
                      leading: Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                      title: const Text('Appearance'),
                      subtitle: const Text('Light / Dark / System'),
                      trailing: const ThemeToggleButton(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.notifications_rounded, color: AppColors.primary),
                      title: const Text('Notifications'),
                      subtitle: const Text('Offer alerts and updates'),
                      trailing: Switch(
                        value: true,
                        onChanged: (v) {
                          // TODO: persist notification preference
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.language_rounded, color: AppColors.primary),
                      title: const Text('Language'),
                      subtitle: const Text('English'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Language options coming soon')),
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
