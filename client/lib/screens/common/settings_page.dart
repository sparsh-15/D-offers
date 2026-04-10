import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/theme_toggle.dart';

class _STP {
  static const canvas        = Color(0xFFF3F5F8);
  static const surface       = Color(0xFFFFFFFF);
  static const border        = Color(0xFFE7E9EE);
  static const accent        = Color(0xFFE88428);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFF7A8293);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _STP.canvas,
      appBar: AppBar(
        backgroundColor: _STP.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: _STP.canvas,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _STP.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            // ── Appearance section ───────────────────────────────────────
            _sectionLabel('Appearance'),
            _settingsCard(
              children: [
                _tile(
                  icon: Icons.dark_mode_rounded,
                  iconTint: const Color(0xFF6366F1),
                  iconBg: const Color(0xFFE8EAFD),
                  title: 'Theme',
                  subtitle: 'Light / Dark / System',
                  trailing: const ThemeToggleButton(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Notifications section ────────────────────────────────────
            _sectionLabel('Notifications'),
            _settingsCard(
              children: [
                _tile(
                  icon: Icons.notifications_rounded,
                  iconTint: const Color(0xFFF59E0B),
                  iconBg: const Color(0xFFF7ECDD),
                  title: 'Offer Alerts',
                  subtitle: 'Get notified about new deals near you',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeColor: _STP.accent,
                    onChanged: (v) =>
                        setState(() => _notificationsEnabled = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── General section ──────────────────────────────────────────
            _sectionLabel('General'),
            _settingsCard(
              children: [
                _tile(
                  icon: Icons.language_rounded,
                  iconTint: const Color(0xFF0284C7),
                  iconBg: const Color(0xFFDFF3FF),
                  title: 'Language',
                  subtitle: 'English',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: _STP.textMuted,
                    size: 24,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Language options coming soon')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _STP.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _STP.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _STP.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 72,
                color: _STP.border,
              ),
          ],
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color iconTint,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: Icon(icon, color: iconTint, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _STP.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: _STP.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
