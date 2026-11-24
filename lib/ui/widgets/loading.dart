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
///
/// The full-page form is drawn as the page that is coming (Forest & Lime,
/// 2026-11-25): pale ticket-shaped cards for a list, a title card and fact
/// rows for a record ([record]), shimmering softly — so the wait already
/// looks like the page, not like a blank screen with a wheel. The shimmer
/// stops when the phone asks for less motion.
class LoadingWords extends StatefulWidget {
  const LoadingWords({
    super.key,
    this.first,
    this.compact = false,
    this.record = false,
  });

  final String? first;
  final bool compact;

  /// One record's page (a title card and rows), not a list.
  final bool record;

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
    return SingleChildScrollView(
      key: const Key('loading'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: words),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.record
                  ? const [
                      _Bone(height: 132, lines: [0.35, 0.7, 0.5]),
                      SizedBox(height: 12),
                      _Bone(height: 84, lines: [0.45, 0.8]),
                      SizedBox(height: 12),
                      _Bone(height: 160, lines: [0.3, 0.9, 0.75, 0.6]),
                    ]
                  : const [
                      _Bone(height: 104, lines: [0.6, 0.4], ticket: true),
                      SizedBox(height: 10),
                      _Bone(height: 104, lines: [0.5, 0.35], ticket: true),
                      SizedBox(height: 10),
                      _Bone(height: 104, lines: [0.65, 0.3], ticket: true),
                      SizedBox(height: 10),
                      _Bone(height: 104, lines: [0.45, 0.4], ticket: true),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A placeholder card: white, hairline edge, pale bars where the words will
/// be. A [ticket] has the tear line and a short bar under it, like Home's
/// repair tickets.
class _Bone extends StatelessWidget {
  const _Bone({required this.height, required this.lines, this.ticket = false});

  final double height;

  /// Each bar's width, as a share of the card.
  final List<double> lines;
  final bool ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bar = scheme.surfaceContainerHighest;
    Widget line(double share, {double h = 12}) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: share,
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: bar,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(lines.first, h: 15),
          for (final share in lines.skip(1)) ...[
            const SizedBox(height: 9),
            line(share),
          ],
          const Spacer(),
          if (ticket) ...[
            Container(height: 1.5, color: bar),
            const SizedBox(height: 9),
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  Container(
                    width: 14,
                    height: 4,
                    decoration: BoxDecoration(
                      color: bar,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                const Spacer(),
                Container(
                  width: 64,
                  height: 16,
                  decoration: BoxDecoration(
                    color: bar,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A soft light sweeping across its child, over and over — the "still
/// coming" of a placeholder. Still when the phone asks for less motion.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) => ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) {
        final x = -1 + 3 * _c.value;
        return LinearGradient(
          begin: Alignment(x - 1, -0.3),
          end: Alignment(x, 0.3),
          colors: const [
            Color(0x00FFFFFF),
            Color(0x66FFFFFF),
            Color(0x00FFFFFF),
          ],
        ).createShader(rect);
      },
      child: child,
    ),
  );
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
