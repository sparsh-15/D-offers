import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_strings.dart';

class _ABP {
  static const canvas        = Color(0xFFF3F5F8);
  static const surface       = Color(0xFFFFFFFF);
  static const border        = Color(0xFFE7E9EE);
  static const accent        = Color(0xFFE88428);
  static const accentSoft    = Color(0xFFFBE7D6);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF334155);
  static const textMuted     = Color(0xFF64748B);
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ABP.canvas,
      appBar: AppBar(
        backgroundColor: _ABP.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: _ABP.canvas,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About',
          style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ABP.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── App hero ───────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: _ABP.accentSoft,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.local_offer_rounded,
                          size: 44, color: _ABP.accent),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.appName,
                      style: GoogleFonts.dmSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _ABP.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Discover Amazing Deals Near You',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: _ABP.textMuted),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // ── About card ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: _ABP.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _ABP.border),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x080F172A),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About ${AppStrings.companyName}',
                      style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ABP.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'D\'Offer helps you discover hyperlocal deals and offers from shops near you. '
                      'Customers can browse and save offers; shopkeepers can create and manage offers; '
                      'admins oversee the platform.',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: _ABP.textSecondary,
                          height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Support', AppStrings.supportEmail),
                    const SizedBox(height: 10),
                    _infoRow('Version', appVersion),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Copyright ──────────────────────────────────────────────
              Text(
                '© ${DateTime.now().year} ${AppStrings.companyName}. All rights reserved.',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: _ABP.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                color: _ABP.textMuted,
                fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                color: _ABP.textPrimary,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
