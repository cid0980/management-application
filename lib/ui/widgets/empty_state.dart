import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// What a list shows when there is nothing in it.
///
/// One shape everywhere — icon, one line, an optional hint — so an empty list
/// looks deliberate rather than broken, and looks the same on every page. A
/// search that found nothing gets the search-off icon, so "nothing here" and
/// "nothing matches what you typed" are told apart at a glance.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? detail;

  /// A button that gets out of the empty state: "Buy phone", "Try again".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// What a page shows when its records could not be read: the reason as the
/// server gave it, and a way to try again. Never an empty list — an empty
/// shelf and a failed read look the same otherwise, and staff read both as
/// "nothing here".
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.detail,
    this.onRetry,
  });

  final String title;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A record page whose record is not in the live list (it is older than the
/// list keeps): asks the server once, with a spinner meanwhile. If it is
/// found, the store notifies and the page draws it; if not, [notFound].
class FetchingRecord extends StatefulWidget {
  const FetchingRecord({
    super.key,
    required this.fetch,
    required this.notFound,
  });

  final Future<Object?> Function() fetch;
  final Widget notFound;

  @override
  State<FetchingRecord> createState() => _FetchingRecordState();
}

class _FetchingRecordState extends State<FetchingRecord> {
  late final Future<Object?> _future = widget.fetch().catchError(
    (Object _) => null,
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<Object?>(
    future: _future,
    builder: (context, snap) => snap.connectionState == ConnectionState.done
        ? widget.notFound
        : const Center(child: CircularProgressIndicator()),
  );
}
