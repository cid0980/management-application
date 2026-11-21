import 'package:flutter/material.dart';

/// A sideways-scrolling row that SHOWS it scrolls.
///
/// The filter chips on the list pages (Open / Due today / Overdue / …) do not
/// fit across a phone, and a row that is simply cut off at the edge reads as
/// "these are all the tabs" — staff never found Overdue on the Service page.
/// So the edge with more behind it fades out, and the fade goes away once
/// there is nothing more that way.
class FadingScroll extends StatefulWidget {
  const FadingScroll({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  State<FadingScroll> createState() => _FadingScrollState();
}

class _FadingScrollState extends State<FadingScroll> {
  final _controller = ScrollController();
  bool _moreLeft = false;
  bool _moreRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!mounted || !_controller.hasClients) return;
    final p = _controller.position;
    // Not laid out yet — a page being built offstage during a route change.
    if (!p.hasContentDimensions || !p.hasPixels) return;
    final left = p.extentBefore > 1;
    final right = p.extentAfter > 1;
    if (left != _moreLeft || right != _moreRight) {
      setState(() {
        _moreLeft = left;
        _moreRight = right;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scroll = NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _update());
        return false;
      },
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        child: widget.child,
      ),
    );
    if (!_moreLeft && !_moreRight) return scroll;
    return ShaderMask(
      key: const Key('fading-scroll-hint'),
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        colors: [
          _moreLeft ? Colors.transparent : Colors.black,
          Colors.black,
          Colors.black,
          _moreRight ? Colors.transparent : Colors.black,
        ],
        stops: const [0, 0.08, 0.88, 1],
      ).createShader(rect),
      child: scroll,
    );
  }
}
