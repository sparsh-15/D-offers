import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_strings.dart';

class _HP {
  static const canvas        = Color(0xFFF3F5F8);
  static const surface       = Color(0xFFFFFFFF);
  static const border        = Color(0xFFE7E9EE);
  static const accent        = Color(0xFFE88428);
  static const accentSoft    = Color(0xFFFBE7D6);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF334155);
  static const textMuted     = Color(0xFF64748B);
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const String _supportPhone = '+91 1800 123 4567';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HP.canvas,
      appBar: AppBar(
        backgroundColor: _HP.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: _HP.canvas,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.dmSans(
              fontSize: 22, fontWeight: FontWeight.w800, color: _HP.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero card ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: _HP.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _HP.accent.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _HP.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          size: 32, color: _HP.accent),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "We're here to help",
                      style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _HP.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Contact ${AppStrings.companyName} for any questions or issues.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: _HP.textMuted,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Contact section ────────────────────────────────────────
              _sectionLabel('Contact Us'),
              _card(children: [
                _contactTile(
                  context: context,
                  icon: Icons.email_rounded,
                  iconTint: const Color(0xFF6366F1),
                  iconBg: const Color(0xFFE8EAFD),
                  title: 'Email us',
                  subtitle: AppStrings.supportEmail,
                  onTap: () {
                    Clipboard.setData(
                        const ClipboardData(text: AppStrings.supportEmail));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Email copied to clipboard')),
                    );
                  },
                ),
                _divider(),
                _contactTile(
                  context: context,
                  icon: Icons.phone_rounded,
                  iconTint: const Color(0xFF1F9D65),
                  iconBg: const Color(0xFFE4F6EC),
                  title: 'Call us',
                  subtitle: _supportPhone,
                  onTap: () {
                    Clipboard.setData(
                        const ClipboardData(text: _supportPhone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Phone number copied to clipboard')),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 16),

              // ── FAQ section ────────────────────────────────────────────
              _sectionLabel('FAQ'),
              _card(children: [
                _faqTile(
                  context: context,
                  question: 'How do I redeem an offer?',
                  answer:
                      'Show the offer details to the shopkeeper at the store. They will verify and apply the discount.',
                ),
                _divider(),
                _faqTile(
                  context: context,
                  question: 'How can I get my shop approved?',
                  answer:
                      'After registration, an admin will review your profile. You\'ll be notified once approved.',
                ),
                _divider(),
                _faqTile(
                  context: context,
                  question: 'I forgot my password',
                  answer:
                      'D\'Offer uses OTP-based login. Use your registered phone number to receive a new OTP.',
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _HP.textMuted,
              letterSpacing: 0.8),
        ),
      );

  Widget _card({required List<Widget> children}) => Container(
        decoration: BoxDecoration(
          color: _HP.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _HP.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Column(children: children),
      );

  Widget _divider() =>
      Divider(height: 1, indent: 72, color: _HP.border);

  Widget _contactTile({
    required BuildContext context,
    required IconData icon,
    required Color iconTint,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: iconBg),
              child: Icon(icon, color: iconTint, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _HP.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: _HP.textMuted,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, color: _HP.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _faqTile({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding:
            const EdgeInsets.fromLTRB(72, 0, 16, 14),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _HP.accentSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.help_outline_rounded,
              color: _HP.accent, size: 18),
        ),
        title: Text(
          question,
          style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _HP.textPrimary),
        ),
        iconColor: _HP.accent,
        collapsedIconColor: _HP.textMuted,
        children: [
          Text(
            answer,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: _HP.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
