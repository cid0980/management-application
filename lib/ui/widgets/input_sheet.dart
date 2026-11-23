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
/// "Are you sure?" and "that did not save" come up the same way
/// ([confirmSheet], [showMessageSheet]): nothing in the app pops up in the
/// middle of the screen.
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

/// "Are you sure?" from the bottom: [yes] and [no] side by side. True only
/// for [yes]; swiping it away is a no.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  String? body,
  required String yes,
  required String no,
  Key? yesKey,
  bool destructive = true,
}) async {
  final answer = await showInputSheet<bool>(
    context: context,
    builder: (sheet) {
      final scheme = Theme.of(sheet).colorScheme;
      return InputSheet(
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          TextButton(
            key: const Key('confirm-no'),
            onPressed: () => Navigator.of(sheet).pop(false),
            child: Text(no),
          ),
          FilledButton(
            key: yesKey ?? const Key('confirm-yes'),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(sheet).pop(true),
            child: Text(yes),
          ),
        ],
      );
    },
  );
  return answer == true;
}

/// Something to read and close — "that did not save, because…" — from the
/// bottom, with an icon in front of the title.
Future<void> showMessageSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String ok,
  IconData icon = Icons.error_outline,
  bool error = true,
}) => showInputSheet<void>(
  context: context,
  builder: (sheet) {
    final scheme = Theme.of(sheet).colorScheme;
    return InputSheet(
      key: const Key('message-sheet'),
      title: Row(
        children: [
          Icon(icon, color: error ? scheme.error : scheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(body),
      actions: [
        FilledButton(
          key: const Key('message-ok'),
          onPressed: () => Navigator.of(sheet).pop(),
          child: Text(ok),
        ),
      ],
    );
  },
);
