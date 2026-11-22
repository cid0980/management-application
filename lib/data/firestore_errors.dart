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

/// [what] names the thing that could not be read — "customers", "stock",
/// "today's tasks" — so the message says which part of the screen is empty.
String describeFirestoreError(Object e, String what) {
  if (e is FirebaseException) {
    return switch (e.code) {
      // The two that actually happen.
      'permission-denied' => 'You do not have access to this shop\'s $what.',
      'unavailable' =>
        'Cannot reach Firestore. The app keeps working on its local copy.',
      _ => e.message ?? 'Firestore error: ${e.code}',
    };
  }
  return '$e';
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
