import 'package:flutter/material.dart';

/// TAKING THE PERSON TO WHAT IS MISSING
///
/// Save with a required field left empty used to stop with a line at the
/// bottom of the screen — often behind the form, so it looked like nothing
/// happened. Now the form scrolls to the first field that needs something
/// (the top-most one) and, when it is a text box, puts the cursor in it with
/// the keyboard up. Its red error is already under it.
///
/// [keys] are the widget keys of the fields with errors (every form keys its
/// fields already, e.g. `service-brand`). A form's list builds lazily, so a
/// field far up the page may not exist yet: the list is walked from the top
/// until one is found. True when a field was found.
Future<bool> jumpToFirstError(BuildContext context, Iterable<Key> keys) async {
  final wanted = keys.toSet();
  if (wanted.isEmpty || !context.mounted) return false;
  final root = context as Element;

  Element? topMost() {
    Element? best;
    var bestY = double.infinity;
    void visit(Element e) {
      final key = e.widget.key;
      if (key != null && wanted.contains(key)) {
        final box = e.findRenderObject();
        if (box is RenderBox && box.attached && box.hasSize) {
          final y = box.localToGlobal(Offset.zero).dy;
          if (y < bestY) {
            bestY = y;
            best = e;
          }
        }
        return;
      }
      e.visitChildren(visit);
    }

    root.visitChildren(visit);
    return best;
  }

  ScrollPosition? page() {
    ScrollPosition? found;
    void visit(Element e) {
      if (found != null) return;
      if (e is StatefulElement && e.state is ScrollableState) {
        final position = (e.state as ScrollableState).position;
        if (position.axis == Axis.vertical) {
          found = position;
          return;
        }
      }
      e.visitChildren(visit);
    }

    root.visitChildren(visit);
    return found;
  }

  var target = topMost();
  final position = page();
  if (position != null && position.hasContentDimensions) {
    // From the top, so the first field with a problem is the one found.
    position.jumpTo(position.minScrollExtent);
    await WidgetsBinding.instance.endOfFrame;
    target = topMost();
    while (target == null && position.pixels < position.maxScrollExtent) {
      position.jumpTo(
        (position.pixels + position.viewportDimension * 0.8).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await WidgetsBinding.instance.endOfFrame;
      target = topMost();
    }
  }
  final found = target;
  if (found == null || !found.mounted) return false;

  await Scrollable.ensureVisible(
    found,
    alignment: 0.2,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );
  if (!found.mounted) return true;

  // A text box gets the cursor, so typing can start at once.
  FocusNode? node;
  void findText(Element e) {
    if (node != null) return;
    final widget = e.widget;
    if (widget is EditableText) {
      node = widget.focusNode;
      return;
    }
    e.visitChildren(findText);
  }

  if (found.widget is EditableText) {
    node = (found.widget as EditableText).focusNode;
  } else {
    found.visitChildren(findText);
  }
  node?.requestFocus();
  return true;
}
