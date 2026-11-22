import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/firestore_errors.dart';

/// A write is done once it is on this phone; a refusal that comes back in
/// time is still a refusal; a late one does not escape as an unhandled error.
void main() {
  const wait = Duration(milliseconds: 50);

  test('a write the server answers is done', () async {
    await localWrite(Future<void>.value(), wait: wait);
  });

  test('a refusal that comes back in time is thrown', () async {
    final refused = Future<void>.error(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await expectLater(
      localWrite(refused, wait: wait),
      throwsA(isA<FirebaseException>()),
    );
  });

  test('no answer (offline) does not hang: the write is queued', () async {
    final never = Completer<void>().future;
    await localWrite(never, wait: wait).timeout(const Duration(seconds: 1));
  });

  // The test framework fails a test on any unhandled async error, so this
  // passing is the check.
  test('a refusal after the wait is swallowed, not unhandled', () async {
    final late = Completer<void>();
    await localWrite(late.future, wait: wait);
    late.completeError(
      FirebaseException(plugin: 'cloud_firestore', code: 'aborted'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
}
