import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// SAVING, WITH THE FAILURE SAID OUT LOUD
///
/// Every form's save goes through here. A write that fails — no internet
/// when the shop needs a new job or bill number, an account that is not
/// allowed, anything else — is caught and said in plain words in a dialog
/// over the form, which stays open with everything typed still in it.
///
/// A dialog rather than a snackbar: the forms sit over the whole app, and a
/// snackbar would be drawn on the page underneath, where nobody sees it.
///
/// Returns the operation's result, or null when it did not succeed.
Future<T?> guardSave<T>(
  BuildContext context,
  Future<T> Function() op, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final l10n = context.l10n;
  String message;
  try {
    return await op().timeout(timeout);
  } on TimeoutException {
    // Not "failed": a queued write may still go through. Saying "not
    // confirmed" keeps somebody from typing the whole job in twice.
    message = l10n.saveTimedOut;
  } on FirebaseException catch (e) {
    message = switch (e.code) {
      'unavailable' || 'deadline-exceeded' => l10n.saveNoInternet,
      'permission-denied' || 'unauthenticated' => l10n.saveNotAllowed,
      _ => l10n.saveFailedReason(e.message ?? e.code),
    };
  } catch (e) {
    message = l10n.saveFailedReason(saveErrorText(e));
  }
  if (context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(l10n.saveFailedTitle),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.okButton),
          ),
        ],
      ),
    );
  }
  return null;
}

/// An error as a sentence: a thrown String or a rule message as itself,
/// anything else by its own description without the "Exception:" prefix.
String saveErrorText(Object e) {
  final text = '$e';
  const prefix = 'Exception: ';
  return text.startsWith(prefix) ? text.substring(prefix.length) : text;
}

/// [guardSave] for a write with no result: true when it went through.
Future<bool> guardRun(
  BuildContext context,
  Future<void> Function() op,
) async {
  final ok = await guardSave<bool>(context, () async {
    await op();
    return true;
  });
  return ok ?? false;
}
