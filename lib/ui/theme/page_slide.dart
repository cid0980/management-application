import 'package:flutter/material.dart';

/// PAGES SLIDE
///
/// A page opens by sliding in from the right while the page under it moves a
/// little to the left, and Back slides it out the way it came — the way a
/// book's pages turn, not a box popping up. The owner asked for exactly this
/// on 22 Nov 2026 ("a slider animation instead of some pop up feel").
///
/// [SlidePageTransitionsBuilder] does it for every ordinary page through the
/// theme; [tabSlide] is the same motion for the bottom-bar tabs, sideways in
/// the direction of the tab tapped.
class SlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlidePageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => pageSlide(context, animation, secondaryAnimation, child);
}

/// In from [from] (1 = a full width to the right), and out to the left by a
/// third when another page slides over it. Opaque, so two pages never show
/// through each other mid-slide.
Widget pageSlide(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child, {
  double from = 1,
  bool fade = false,
}) {
  final coming = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  final covered = CurvedAnimation(
    parent: secondaryAnimation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  Widget page = ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: child,
  );
  if (fade) page = FadeTransition(opacity: coming, child: page);
  return SlideTransition(
    position: Tween(begin: Offset(from, 0), end: Offset.zero).animate(coming),
    child: SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: const Offset(-0.3, 0),
      ).animate(covered),
      child: page,
    ),
  );
}
