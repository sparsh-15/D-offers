import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';

/// Shared Help & Support page for all roles.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const String _supportEmail = 'support@doffer.app';
  static const String _supportPhone = '+91 1800 123 4567';

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
          title: const Text('Help & Support'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.support_agent_rounded, size: 48, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'We\'re here to help',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contact the D\'Offer support team for any questions or issues.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ContactTile(
                  icon: Icons.email_rounded,
                  title: 'Email us',
                  subtitle: _supportEmail,
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: _supportEmail));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email copied to clipboard')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ContactTile(
                  icon: Icons.phone_rounded,
                  title: 'Call us',
                  subtitle: _supportPhone,
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: _supportPhone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone number copied to clipboard')),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'FAQ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _FaqTile(
                        question: 'How do I redeem an offer?',
                        answer: 'Show the offer details to the shopkeeper at the store. They will verify and apply the discount.',
                      ),
                      const Divider(height: 1),
                      _FaqTile(
                        question: 'How can I get my shop approved?',
                        answer: 'After registration, an admin will review your profile. You\'ll be notified once approved.',
                      ),
                      const Divider(height: 1),
                      _FaqTile(
                        question: 'I forgot my password',
                        answer: 'D\'Offer uses OTP-based login. Use your registered phone number to receive a new OTP.',
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
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 24),
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
          child: Text(answer, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
