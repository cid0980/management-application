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
