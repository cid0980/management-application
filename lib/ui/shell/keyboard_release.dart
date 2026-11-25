import 'dart:async';

import 'package:flutter/material.dart';

/// LET GO OF A TEXT BOX THE WAY EVERY OTHER APP DOES
///
/// Flutter on Android keeps a text box selected when you touch somewhere
/// else (by design: its own code drops the focus on desktops only). So in
/// this app the keyboard stayed up after a tap on empty space, and when the
/// phone's Back key closed the keyboard, the box stayed selected with its
/// cursor blinking and nothing to type with.
///
/// Around the whole app:
/// - **A tap on empty space** lets go of the box, and the keyboard closes.
///   A tap on a button, another box, a list row or a suggestion is theirs:
///   the innermost tap wins, so this one only fires where nothing else
///   wanted the tap. A drag (scrolling a form) is not a tap and keeps the
///   keyboard.
/// - **The keyboard closing** (Back, or the keyboard's own hide key) lets go
///   of the box too. Checked again a moment later, so a keyboard that only
///   changes layout between boxes (text to numbers) is not taken for one
///   that closed.
class KeyboardRelease extends StatefulWidget {
  const KeyboardRelease({super.key, required this.child});

  final Widget child;

  /// A text box has the focus now.
  static bool typing() =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() !=
      null;

  static void release() {
    if (typing()) FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  State<KeyboardRelease> createState() => _KeyboardReleaseState();
}

class _KeyboardReleaseState extends State<KeyboardRelease>
    with WidgetsBindingObserver {
  bool _wasOpen = false;
  Timer? _check;

  bool get _open {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    return views.isNotEmpty && views.first.viewInsets.bottom > 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _check?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final open = _open;
    if (_wasOpen && !open) {
      _check?.cancel();
      _check = Timer(const Duration(milliseconds: 300), () {
        if (mounted && !_open) KeyboardRelease.release();
      });
    }
    _wasOpen = open;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: KeyboardRelease.release,
    child: widget.child,
  );
}
