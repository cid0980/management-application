import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// GETTING THE DATA: SAY SO, AND KEEP SAYING SOMETHING
///
/// A bare spinner says nothing, and after a few seconds of it people wonder
/// whether the app froze. So the spinner comes with words, and the words move
/// on every couple of seconds — "Getting your repairs…", "Still working on
/// it…", "Almost there…", "Slow internet? Hang on…" — so it is plain that the
/// phone is still at it.
///
/// [first] is what this page is getting; the rest are the same everywhere.
/// [compact] is one line (a spinner and the words) for loading more of a page
/// that is already showing something.
class LoadingWords extends StatefulWidget {
  const LoadingWords({super.key, this.first, this.compact = false});

  final String? first;
  final bool compact;

  /// How long each line stays.
  static const step = Duration(milliseconds: 1900);

  @override
  State<LoadingWords> createState() => _LoadingWordsState();
}

class _LoadingWordsState extends State<LoadingWords> {
  late final Timer _timer;
  var _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(LoadingWords.step, (_) => setState(() => _i++));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lines = [
      widget.first ?? l10n.loadingData,
      l10n.loadingStill,
      l10n.loadingAlmost,
      l10n.loadingSlow,
    ];
    // Round and round, but never back to the first line: once it has said
    // what it is getting, "still working" is the honest thing to say.
    final line = _i < lines.length ? lines[_i] : lines[1 + (_i - 1) % 3];
    final words = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        line,
        key: ValueKey(line),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (widget.compact) {
      return Padding(
        key: const Key('loading'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: words),
            ),
          ],
        ),
      );
    }
    return Center(
      key: const Key('loading'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            words,
          ],
        ),
      ),
    );
  }
}

/// Fades its child in once, when it first appears — a list arriving after
/// "Getting your repairs…" comes in softly instead of popping.
class FadeIn extends StatelessWidget {
  const FadeIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOut,
    child: child,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
    ),
  );
}
