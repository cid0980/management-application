/// WHAT A FIRESTORE FAILURE SAYS TO THE SHOP
///
/// Said as itself, in one place. "Could not load" with no reason is how
/// somebody spends an afternoon on a rules problem they could have read in a
/// second — and Firebase's own `message` is written for whoever wrote the
/// plugin. On a real device an unmapped failure came back reading
/// `dev.flutter.pigeon.firebase_auth_platform_interface…`, printed in red to a
/// shop owner.
///
/// **A dropped connection is not an error state.** Firestore keeps a local
/// cache and queues writes, so the till keeps working when the shop's wifi
/// goes down. That case says so rather than reading as a failure, because a
/// list screen that shows an error instead of yesterday's stock is a till
/// nobody trusts.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// [what] names the thing that could not be read — "customers", "stock",
/// "today's tasks" — so the message says which part of the screen is empty.
String describeFirestoreError(Object e, String what) {
  if (e is FirebaseException) {
    return switch (e.code) {
      // The two that actually happen.
      'permission-denied' => 'You do not have access to this shop\'s $what.',
      'unavailable' =>
        'Cannot reach Firestore. The app keeps working on its local copy.',
      _ => plainError(e),
    };
  }
  return plainError(e);
}

/// The sentences [plainError] says. English here; Tamil and Hindi in
/// rule_messages.dart, through ruleText.
const kErrNoInternet =
    "No internet connection. Check the shop's internet and try again.";
const kErrNotAllowed = 'Not allowed. Ask the shop owner to check your access.';
const kErrSignInAgain = 'Please sign in again.';
const kErrTooMany = 'Too many tries. Wait a minute and try again.';
const kErrClash = 'Somebody else changed this at the same moment. Try again.';
const kErrGone = 'It is not there any more. It may have been removed.';
const kErrGeneric = 'Something went wrong. Please try again.';

/// ANY ERROR, AS A SENTENCE FOR THE PERSON AT THE COUNTER
///
/// Never Firebase's or Android's own text: `[cloud_firestore/permission-
/// denied] The caller does not have permission…`, `PlatformException(…)`,
/// `dev.flutter.pigeon…` are for whoever wrote the plugin. The app's own
/// messages (a rule refusing a save: "Not enough stock") are kept as they
/// are. The technical text still goes to the debug log, for whoever fixes
/// it.
String plainError(Object e) {
  final type = e.runtimeType.toString();
  String? code;
  if (e is FirebaseException) {
    code = e.code;
  } else if (type.contains('PlatformException')) {
    try {
      code = (e as dynamic).code as String?;
    } catch (_) {}
  }
  if (code != null) {
    debugPrint('plainError: $type $code: $e');
    return switch (code) {
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' ||
      'network_error' => kErrNoInternet,
      // `unauthorized`: Firebase Storage's word for a refused read or write.
      'permission-denied' || 'unauthorized' => kErrNotAllowed,
      'unauthenticated' ||
      'user-token-expired' ||
      'requires-recent-login' => kErrSignInAgain,
      'resource-exhausted' || 'too-many-requests' => kErrTooMany,
      'aborted' => kErrClash,
      'not-found' || 'object-not-found' => kErrGone,
      'retry-limit-exceeded' => kErrNoInternet,
      'quota-exceeded' => kErrTooMany,
      _ => kErrGeneric,
    };
  }
  if (type.contains('SocketException') ||
      type.contains('ClientException') ||
      e is TimeoutException) {
    debugPrint('plainError: $type: $e');
    return kErrNoInternet;
  }
  var text = '$e';
  for (final prefix in ['Exception: ', 'Bad state: ']) {
    if (text.startsWith(prefix)) text = text.substring(prefix.length);
  }
  final technical = RegExp(
    r'\[\w_]+/[\w-]+\]|firebase|pigeon|dev\.flutter|Exception|Error\b|'
    r'Instance of|null check|_\w+\(|\bat \w+\.dart',
    caseSensitive: false,
  );
  if (text.trim().isEmpty || technical.hasMatch(text)) {
    debugPrint('plainError: $type: $e');
    return kErrGeneric;
  }
  return text;
}

/// A plain write, counted as done once it is on this phone.
///
/// Firestore keeps every write in its local copy straight away and sends it
/// when the server can be reached; the Future it hands back only completes
/// when the server answers. Awaited as it is, an edit made with the shop's
/// wifi down sat on a spinner until the wifi came back. So: wait [wait] for
/// the server; if it has not answered by then, the write is queued and the
/// lists already show it — carry on. A refusal that comes back in time is
/// still thrown, so "not allowed" is still said.
///
/// Not for transactions, which cannot run offline at all and must fail.
Future<void> localWrite(
  Future<void> write, {
  Duration wait = const Duration(seconds: 3),
}) {
  final done = Completer<void>();
  write.then(
    (_) {
      if (!done.isCompleted) done.complete();
    },
    // A late error has nobody waiting for it; caught here so it is not an
    // unhandled one. Firestore rolls the local copy back on a refusal.
    onError: (Object e, StackTrace st) {
      if (!done.isCompleted) done.completeError(e, st);
    },
  );
  return done.future.timeout(wait, onTimeout: () {});
}
