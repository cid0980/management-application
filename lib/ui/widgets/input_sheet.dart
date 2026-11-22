import 'package:flutter/material.dart';

/// FILLING SOMETHING IN: A SHEET FROM THE BOTTOM, NOT A BOX IN THE MIDDLE
///
/// A price, a reason, a quantity, a payment: each used to open a small box
/// in the middle of the screen, the way old desktop software asks. On a phone
/// the thumb is at the bottom, the keyboard comes up from the bottom, and the
/// app's own forms already open there — so these do too. The box keeps clear
/// of the keyboard, and the buttons sit side by side at full width like the
/// forms' own Save buttons.
///
/// Dialogs stay for what is a question, not a form: "are you sure?" and
/// "that did not save".
Future<T?> showInputSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  // Over the bottom bar, like every form in the app.
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: builder,
);

/// The inside of an input sheet: a title, the fields, the buttons.
///
/// Takes the same three things an AlertDialog did, so moving a dialog here is
/// a rename. A TextButton among [actions] (the usual Cancel) is drawn with a
/// border, so the two buttons read as a pair.
class InputSheet extends StatelessWidget {
  const InputSheet({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
  });

  final Widget? title;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Clear of the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              DefaultTextStyle.merge(
                style: theme.textTheme.titleLarge,
                child: title!,
              ),
              const SizedBox(height: 16),
            ],
            ?content,
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              TextButtonTheme(
                data: TextButtonThemeData(
                  style: theme.outlinedButtonTheme.style,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A list to pick one from, as a sheet: a title and full-width rows.
class PickSheet extends StatelessWidget {
  const PickSheet({super.key, required this.title, required this.children});

  final Widget title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.titleLarge,
            child: title,
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    ),
  );
}
