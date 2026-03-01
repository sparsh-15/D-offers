import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Universal dark-theme error/empty/not-found state for failed API calls,
/// empty data, or 404. Use as full-screen content or inside a scroll view.
class UniversalErrorPage extends StatelessWidget {
  /// Type of state: empty list, API/server error, or page not found.
  final ErrorPageType type;

  /// Optional short title (e.g. "Nothing here").
  final String? title;

  /// Optional longer message (e.g. "No plans found for this category.").
  final String? message;

  /// Optional retry callback; if set, a "Try again" button is shown.
  final VoidCallback? onRetry;

  /// If true, expands to fill available height (e.g. for full-screen).
  /// If false, only takes the space it needs (e.g. inside ListView).
  final bool fullHeight;

  const UniversalErrorPage({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.onRetry,
    this.fullHeight = true,
  });

  /// Convenience: empty state (e.g. no results, empty API response).
  static Widget empty({
    String? title,
    String? message,
    VoidCallback? onRetry,
    bool fullHeight = true,
  }) {
    return UniversalErrorPage(
      type: ErrorPageType.empty,
      title: title ?? 'Nothing here',
      message: message,
      onRetry: onRetry,
      fullHeight: fullHeight,
    );
  }

  /// Convenience: error state (e.g. failed API call, server error).
  static Widget error({
    String? title,
    String? message,
    VoidCallback? onRetry,
    bool fullHeight = true,
  }) {
    return UniversalErrorPage(
      type: ErrorPageType.error,
      title: title ?? 'Something went wrong',
      message: message,
      onRetry: onRetry,
      fullHeight: fullHeight,
    );
  }

  /// Convenience: page not found (404).
  static Widget notFound({
    String? title,
    String? message,
    VoidCallback? onRetry,
    bool fullHeight = true,
  }) {
    return UniversalErrorPage(
      type: ErrorPageType.notFound,
      title: title ?? 'Page not found',
      message: message,
      onRetry: onRetry,
      fullHeight: fullHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color iconColor, String defaultTitle, String defaultMessage) = switch (type) {
      ErrorPageType.empty => (
          Icons.inbox_rounded,
          AppColors.textMuted,
          'Nothing here',
          'No data to show. Check back later or try again.',
        ),
      ErrorPageType.error => (
          Icons.error_outline_rounded,
          AppColors.error,
          'Something went wrong',
          'A problem occurred. Please try again.',
        ),
      ErrorPageType.notFound => (
          Icons.search_off_rounded,
          AppColors.textMuted,
          'Page not found',
          'This page doesn’t exist or was moved.',
        ),
    };

    final effectiveTitle = title ?? defaultTitle;
    final effectiveMessage = message ?? defaultMessage;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderMid),
          ),
          child: Icon(icon, size: 56, color: iconColor),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            effectiveTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            effectiveMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );

    if (fullHeight) {
      return Center(
        child: SingleChildScrollView(
          child: content,
        ),
      );
    }
    return content;
  }
}

enum ErrorPageType {
  empty,
  error,
  notFound,
}
