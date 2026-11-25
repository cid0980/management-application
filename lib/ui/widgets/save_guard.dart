import '../../data/firestore_errors.dart';
import '../../l10n/rule_messages.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'input_sheet.dart';

import '../../l10n/l10n.dart';
import 'busy.dart';

/// SAVING, WITH THE FAILURE SAID OUT LOUD
///
/// Every form's save goes through here. A write that fails — no internet
/// when the shop needs a new job or bill number, an account that is not
/// allowed, anything else — is caught and said in plain words in a sheet
/// over the form, which stays open with everything typed still in it.
///
/// A sheet rather than a snackbar: the forms sit over the whole app, and a
/// snackbar would be drawn on the page underneath, where nobody sees it.
///
/// Returns the operation's result, or null when it did not succeed.
Future<T?> guardSave<T>(
  BuildContext context,
  Future<T> Function() op, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final l10n = context.l10n;
  final lang = Localizations.localeOf(context).languageCode;
  String message;
  try {
    // The screen says "Saving…" while it goes, and takes no second tap.
    return await whileBusy(context, op().timeout(timeout));
  } on TimeoutException {
    // Not "failed": a queued write may still go through. Saying "not
    // confirmed" keeps somebody from typing the whole job in twice.
    message = l10n.saveTimedOut;
  } on FirebaseException catch (e) {
    message = switch (e.code) {
      'unavailable' || 'deadline-exceeded' => l10n.saveNoInternet,
      'permission-denied' || 'unauthenticated' => l10n.saveNotAllowed,
      _ => l10n.saveFailedReason(ruleTextIn(lang, plainError(e))),
    };
  } catch (e) {
    message = l10n.saveFailedReason(ruleTextIn(lang, saveErrorText(e)));
  }
  if (context.mounted) {
    await showMessageSheet(
      context,
      title: l10n.saveFailedTitle,
      body: message,
      ok: l10n.okButton,
    );
  }
  return null;
}

/// An error as a sentence: a thrown String or a rule message as itself,
/// anything else by its own description without the "Exception:" prefix.
String saveErrorText(Object e) => plainError(e);

/// [guardSave] for a write with no result: true when it went through.
Future<bool> guardRun(BuildContext context, Future<void> Function() op) async {
  final ok = await guardSave<bool>(context, () async {
    await op();
    return true;
  });
  return ok ?? false;
}
