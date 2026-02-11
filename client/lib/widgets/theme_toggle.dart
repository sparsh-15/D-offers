import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../core/constants/app_colors.dart';

class ThemeToggle extends StatelessWidget {
  final bool showLabel;

  const ThemeToggle({super.key, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(showLabel ? 'Dark Mode' : ''),
        subtitle: showLabel
            ? Text(isDark ? 'Switch to light theme' : 'Switch to dark theme')
            : null,
        trailing: Switch(
          value: isDark,
          onChanged: (_) => themeProvider.toggleTheme(),
          activeColor: AppColors.primary,
        ),
        onTap: () => themeProvider.toggleTheme(),
      ),
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      ),
      onPressed: () => themeProvider.toggleTheme(),
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}
