import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UniversalErrorPage extends StatelessWidget {
  final ErrorPageType type;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final bool fullHeight;

  const UniversalErrorPage({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.onRetry,
    this.fullHeight = true,
  });

  static Widget empty({
    String? title,
    String? message,
    VoidCallback? onRetry,
    bool fullHeight = true,
  }) {
    return UniversalErrorPage(
      type: ErrorPageType.empty,
      title: title,
      message: message,
      onRetry: onRetry,
      fullHeight: fullHeight,
    );
  }

  static Widget error({
    String? title,
    String? message,
    VoidCallback? onRetry,
    bool fullHeight = true,
  }) {
    return UniversalErrorPage(
      type: ErrorPageType.error,
      title: title,
      message: message,
      onRetry: onRetry,
      fullHeight: fullHeight,
    );
  }

  static Widget notFound({
    String? title,
    String? message,
    VoidCallback? onRetry,
    bool fullHeight = true,
  }) {
    return UniversalErrorPage(
      type: ErrorPageType.notFound,
      title: title,
      message: message,
      onRetry: onRetry,
      fullHeight: fullHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    const iconBg      = Color(0xFFECEEF2);
    const iconColor   = Color(0xFF8A95A8);
    const errorColor  = Color(0xFFE24D69);
    const textMuted   = Color(0xFF667085);
    const accent      = Color(0xFFE88428);
    const white       = Color(0xFFFFFFFF);

    final (IconData icon, Color effectiveIconColor, String defaultTitle, String defaultMessage) = switch (type) {
      ErrorPageType.empty => (
          Icons.desktop_windows_outlined,
          iconColor,
          'Nothing here',
          'No data to show. Check back later or try again.',
        ),
      ErrorPageType.error => (
          Icons.error_outline_rounded,
          errorColor,
          'Something went wrong',
          'A problem occurred. Please try again.',
        ),
      ErrorPageType.notFound => (
          Icons.search_off_rounded,
          iconColor,
          'Page not found',
          'This page does not exist or was moved.',
        ),
    };

    final effectiveMessage = message ?? defaultMessage;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, size: 48, color: effectiveIconColor),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            effectiveMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: textMuted,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  textStyle: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );

    if (fullHeight) {
      return Center(child: SingleChildScrollView(child: content));
    }
    return content;
  }
}

enum ErrorPageType { empty, error, notFound }
