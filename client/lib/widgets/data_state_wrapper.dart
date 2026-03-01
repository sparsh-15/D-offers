import 'package:flutter/material.dart';
import 'universal_error_page.dart';

/// Centralized wrapper for loading, error, and empty states. Uses
/// [UniversalErrorPage] for error and empty; shows [child] when data is ready.
class DataStateWrapper extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool isEmpty;
  final VoidCallback? onRetry;
  final Widget child;
  final String? emptyTitle;
  final String? emptyMessage;
  final String? errorTitle;
  final String? errorMessage;

  const DataStateWrapper({
    super.key,
    required this.loading,
    this.error,
    required this.isEmpty,
    this.onRetry,
    required this.child,
    this.emptyTitle,
    this.emptyMessage,
    this.errorTitle,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final hasError = error != null && error!.isNotEmpty;
    if (hasError) {
      return UniversalErrorPage.error(
        title: errorTitle,
        message: errorMessage ?? error,
        onRetry: onRetry,
        fullHeight: true,
      );
    }
    if (isEmpty) {
      return UniversalErrorPage.empty(
        title: emptyTitle,
        message: emptyMessage,
        onRetry: onRetry,
        fullHeight: true,
      );
    }
    return child;
  }
}
