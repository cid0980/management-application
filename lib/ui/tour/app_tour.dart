import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../widgets/input_sheet.dart';

/// THE APP TOUR
///
/// The first time the app opens, it offers a one-minute walk through every
/// page: the screen dims, the real button or box being talked about stays
/// lit, and a card says what it is for. Next and Back move through it; Skip
/// ends it at once. Settings › Help › App tour runs it again any time.
///
/// Each step points at a widget by its key (`home-search`, `repairs-new`…),
/// the same keys the tests use, so the tour points at what is really there.
/// A step whose widget is not on screen (a staff member has no Settings, say)
/// is shown as a card in the middle instead of being skipped silently.

/// One thing to point at, and what to say about it.
class TourStep {
  const TourStep(this.target, this.title, this.body);

  /// The key of the widget to light up; null for a card in the middle.
  final String? target;
  final String title;
  final String body;
}

/// A page of the tour: where to go, and what to show there.
class TourStop {
  const TourStop(this.route, this.steps);

  final String route;
  final List<TourStep> steps;
}

/// The whole tour, page by page.
List<TourStop> appTour(AppLocalizations l) => [
  TourStop('/dashboard', [
    TourStep(null, l.tourWelcomeTitle, l.tourWelcomeBody),
    TourStep('home-search', l.tourSearchTitle, l.tourSearchBody),
    TourStep('home-today', l.tourTodayTitle, l.tourTodayBody),
    TourStep('home-actions', l.tourActionsTitle, l.tourActionsBody),
    TourStep('home-queue', l.tourQueueTitle, l.tourQueueBody),
    TourStep('nav-bar', l.tourNavTitle, l.tourNavBody),
  ]),
  TourStop('/inventory/second-hand', [
    TourStep('mobiles-summary', l.tourStockTitle, l.tourStockBody),
    TourStep('mobiles-tabs', l.tourStockTabsTitle, l.tourStockTabsBody),
    TourStep('mobiles-buy', l.tourBuyTitle, l.tourBuyBody),
  ]),
  TourStop('/service', [
    TourStep('repairs-tabs', l.tourRepairsTitle, l.tourRepairsBody),
    TourStep('repairs-new', l.tourNewRepairTitle, l.tourNewRepairBody),
  ]),
  TourStop('/sales', [
    TourStep('sales-tabs', l.tourBillsTitle, l.tourBillsBody),
    TourStep('sales-new', l.tourNewBillTitle, l.tourNewBillBody),
  ]),
  TourStop('/more', [
    TourStep('more-/admin/settings', l.tourSettingsTitle, l.tourSettingsBody),
    TourStep(null, l.tourDoneTitle, l.tourDoneBody),
  ]),
];

/// Whether the tour has been offered on this phone. Kept on the phone, not
/// the shop: each person holding a phone is offered it once.
class TourPrefs {
  static const _key = 'tour.offered.v1';

  Future<bool> offered() async {
    try {
      return await SharedPreferencesAsync().getBool(_key) ?? false;
    } catch (_) {
      // No storage to ask: better not to nag on every start.
      return true;
    }
  }

  Future<void> markOffered() async {
    try {
      await SharedPreferencesAsync().setBool(_key, true);
    } catch (_) {
      // Not stored: it may be offered once more. Harmless.
    }
  }
}

/// The first-run offer: "New here? Take a one-minute tour" — once per phone.
Future<void> offerTourOnce(BuildContext context, TourPrefs prefs) async {
  if (await prefs.offered()) return;
  await prefs.markOffered();
  if (!context.mounted) return;
  final l10n = context.l10n;
  final go = await showInputSheet<bool>(
    context: context,
    builder: (sheet) => InputSheet(
      title: Text(l10n.tourOfferTitle),
      content: Text(l10n.tourOfferBody),
      actions: [
        TextButton(
          key: const Key('tour-later'),
          onPressed: () => Navigator.of(sheet).pop(false),
          child: Text(l10n.tourOfferLater),
        ),
        FilledButton(
          key: const Key('tour-start'),
          onPressed: () => Navigator.of(sheet).pop(true),
          child: Text(l10n.tourOfferStart),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) await runAppTour(context);
}

enum _Move { next, back, skip }

class _View {
  const _View({
    required this.step,
    required this.hole,
    required this.index,
    required this.total,
  });

  final TourStep step;
  final Rect? hole;
  final int index;
  final int total;
}

/// Runs the tour from the first step, moving between pages as it goes, and
/// ends on Home.
Future<void> runAppTour(BuildContext context) async {
  final router = GoRouter.of(context);
  final overlay = Overlay.of(context, rootOverlay: true);
  final stops = appTour(context.l10n);
  final steps = [
    for (final stop in stops)
      for (final step in stop.steps) (stop.route, step),
  ];
  final view = ValueNotifier<_View?>(null);
  Completer<_Move>? waiting;
  void move(_Move m) {
    final w = waiting;
    if (w != null && !w.isCompleted) w.complete(m);
  }

  final entry = OverlayEntry(
    builder: (_) => _TourLayer(view: view, onMove: move),
  );
  overlay.insert(entry);
  String? at;
  var i = 0;
  try {
    while (i < steps.length) {
      final (route, step) = steps[i];
      if (route != at) {
        // Dim, without a card, while the page changes under it.
        view.value = null;
        router.go(route);
        at = route;
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
      final hole = await _holeFor(step.target);
      waiting = Completer<_Move>();
      view.value = _View(step: step, hole: hole, index: i, total: steps.length);
      final m = await waiting.future;
      if (m == _Move.skip) break;
      i = m == _Move.next ? i + 1 : (i - 1).clamp(0, steps.length - 1);
    }
  } finally {
    entry.remove();
    entry.dispose();
    view.dispose();
  }
  router.go('/dashboard');
}

/// Where the widget with [key] is on screen, brought into sight first; null
/// when it is not there.
Future<Rect?> _holeFor(String? key) async {
  if (key == null) return null;
  Element? find() {
    Element? found;
    void visit(Element e) {
      if (found != null) return;
      if (e.widget.key == Key(key)) {
        found = e;
        return;
      }
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return found;
  }

  final element = find();
  if (element == null) return null;
  try {
    await Scrollable.ensureVisible(
      element,
      alignment: 0.3,
      duration: const Duration(milliseconds: 200),
    );
  } catch (_) {
    // Not in a scrolling list: already where it is.
  }
  await WidgetsBinding.instance.endOfFrame;
  final box = element.mounted ? element.findRenderObject() : null;
  if (box is! RenderBox || !box.attached || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

class _TourLayer extends StatelessWidget {
  const _TourLayer({required this.view, required this.onMove});

  final ValueNotifier<_View?> view;
  final void Function(_Move) onMove;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<_View?>(
    valueListenable: view,
    builder: (context, v, _) {
      final size = MediaQuery.sizeOf(context);
      final pad = MediaQuery.paddingOf(context);
      final hole = v?.hole;
      final Widget card = v == null
          ? const SizedBox.shrink()
          : _TourCard(key: ValueKey(v.index), view: v, onMove: onMove);
      // The card goes on the other side of the lit part from the edge it
      // is nearer, so it never covers what it is talking about.
      final Widget placed;
      if (hole == null) {
        placed = Center(
          child: Padding(padding: const EdgeInsets.all(16), child: card),
        );
      } else if (hole.center.dy < size.height * 0.5) {
        placed = Positioned(
          left: 16,
          right: 16,
          top: (hole.bottom + 14).clamp(pad.top + 8, size.height - 220),
          child: card,
        );
      } else {
        placed = Positioned(
          left: 16,
          right: 16,
          bottom: (size.height - hole.top + 14).clamp(
            pad.bottom + 8,
            size.height - pad.top - 220,
          ),
          child: card,
        );
      }
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Takes every tap: the tour is driven from its card.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: TweenAnimationBuilder<Rect?>(
                  // Nothing to point at: the lit part shrinks away into the middle.
                  tween: RectTween(
                    end:
                        hole ??
                        Rect.fromCenter(
                          center: size.center(Offset.zero),
                          width: 0,
                          height: 0,
                        ),
                  ),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  builder: (context, r, _) =>
                      CustomPaint(painter: _HolePainter(r)),
                ),
              ),
            ),
            if (hole == null)
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: placed,
                ),
              )
            else
              placed,
          ],
        ),
      );
    },
  );
}

class _HolePainter extends CustomPainter {
  _HolePainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0xA6000000);
    final all = Path()..addRect(Offset.zero & size);
    final h = hole;
    if (h == null || h.width < 2 || h.height < 2) {
      canvas.drawPath(all, dim);
      return;
    }
    final lit = RRect.fromRectAndRadius(
      h.inflate(6),
      const Radius.circular(16),
    );
    canvas.drawPath(
      Path.combine(PathOperation.difference, all, Path()..addRRect(lit)),
      dim,
    );
    canvas.drawRRect(
      lit,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.hole != hole;
}

class _TourCard extends StatelessWidget {
  const _TourCard({super.key, required this.view, required this.onMove});

  final _View view;
  final void Function(_Move) onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final last = view.index == view.total - 1;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Material(
          key: const Key('tour-card'),
          elevation: 8,
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.tourStepOf(view.index + 1, view.total),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  view.step.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(view.step.body, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!last)
                      TextButton(
                        key: const Key('tour-skip'),
                        onPressed: () => onMove(_Move.skip),
                        child: Text(l10n.tourSkip),
                      ),
                    const Spacer(),
                    if (view.index > 0)
                      TextButton(
                        key: const Key('tour-back'),
                        onPressed: () => onMove(_Move.back),
                        child: Text(l10n.tourBack),
                      ),
                    const SizedBox(width: 4),
                    FilledButton(
                      key: const Key('tour-next'),
                      onPressed: () => onMove(_Move.next),
                      child: Text(last ? l10n.tourDone : l10n.tourNext),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
