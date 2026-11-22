import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// SOMETHING IS HAPPENING: SAY SO
///
/// While [work] runs, the screen stops taking taps at once — so a second tap
/// on Save cannot send the same bill twice — and, if it is not done within a
/// moment, a "Saving…" card shows what is going on. A save that lands at once
/// does not flash a spinner.
Future<T> whileBusy<T>(
  BuildContext context,
  Future<T> work, {
  String? label,
  Duration delay = const Duration(milliseconds: 250),
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return work;
  final text = label ?? context.l10n.savingNow;
  final shown = ValueNotifier(false);
  final entry = OverlayEntry(
    builder: (_) => _BusyCover(text: text, shown: shown),
  );
  overlay.insert(entry);
  final timer = Timer(delay, () => shown.value = true);
  try {
    return await work;
  } finally {
    timer.cancel();
    entry.remove();
    entry.dispose();
    shown.dispose();
  }
}

class _BusyCover extends StatelessWidget {
  const _BusyCover({required this.text, required this.shown});

  final String text;
  final ValueNotifier<bool> shown;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: shown,
    builder: (context, visible, _) => Stack(
      children: [
        ModalBarrier(
          dismissible: false,
          color: visible ? Colors.black26 : Colors.transparent,
        ),
        if (visible)
          Center(
            child: Material(
              key: const Key('busy'),
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 16),
                    Text(text, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
