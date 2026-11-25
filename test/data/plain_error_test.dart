import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/firestore_errors.dart';
import 'package:fm_shop/l10n/rule_messages.dart';

void main() {
  test("Firebase's own words never reach the screen", () {
    final denied = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'The caller does not have permission to execute the operation.',
    );
    expect(plainError(denied), kErrNotAllowed);
    expect(plainError(denied), isNot(contains('caller')));
    expect(
      plainError(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      ),
      kErrNoInternet,
    );
    expect(
      plainError(
        FirebaseException(
          plugin: 'x',
          code: 'some-new-code',
          message: 'dev.flutter.pigeon…',
        ),
      ),
      kErrGeneric,
    );
  });

  test('Android and network failures read as sentences', () {
    expect(
      plainError(
        PlatformException(
          code: 'channel-error',
          message:
              'Unable to establish connection on channel: dev.flutter.pigeon.x',
        ),
      ),
      kErrGeneric,
    );
    expect(plainError(TimeoutException('x')), kErrNoInternet);
    expect(
      plainError(Exception('[cloud_firestore/unknown] An unknown error')),
      kErrGeneric,
    );
    expect(plainError('Null check operator used on a null value'), kErrGeneric);
  });

  test("the app's own messages are kept as they are", () {
    expect(plainError(Exception('Not enough stock')), 'Not enough stock');
    expect(
      plainError(StateError('That label is taken')),
      'That label is taken',
    );
    expect(
      plainError('Pick today or a later day.'),
      'Pick today or a later day.',
    );
  });

  test('every sentence is in Tamil and Hindi', () {
    for (final s in [
      kErrNoInternet,
      kErrNotAllowed,
      kErrSignInAgain,
      kErrTooMany,
      kErrClash,
      kErrGone,
      kErrGeneric,
    ]) {
      expect(ruleTextIn('ta', s), isNot(s), reason: s);
      expect(ruleTextIn('hi', s), isNot(s), reason: s);
    }
  });
}
