import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/widgets/save_guard.dart';

/// A save that fails says why, over the form, and hands back nothing — the
/// caller keeps the form open. One that works hands back its result.
Future<BuildContext> _pump(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (c) {
          ctx = c;
          return const Scaffold();
        },
      ),
    ),
  );
  return ctx;
}

void main() {
  testWidgets('a save that works returns its result, with no dialog', (
    tester,
  ) async {
    final ctx = await _pump(tester);
    final result = await guardSave(ctx, () async => 42);
    expect(result, 42);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('no internet is said as no internet', (tester) async {
    final ctx = await _pump(tester);
    int? result = -1;
    unawaited(
      guardSave<int>(
        ctx,
        () async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
      ).then((r) => result = r),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not saved'), findsOneWidget);
    expect(find.textContaining('No internet'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('a refusal says to ask the owner', (tester) async {
    final ctx = await _pump(tester);
    unawaited(
      guardSave<int>(
        ctx,
        () async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Ask the shop owner'), findsOneWidget);
  });

  testWidgets('any other failure is said as itself', (tester) async {
    final ctx = await _pump(tester);
    var ok = true;
    unawaited(
      guardRun(
        ctx,
        () async => throw Exception('Label 26001 is taken'),
      ).then((r) => ok = r),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not save: Label 26001 is taken'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(ok, isFalse);
  });

  testWidgets('a write that never answers is not confirmed, not hung', (
    tester,
  ) async {
    final ctx = await _pump(tester);
    unawaited(
      guardSave<int>(
        ctx,
        () => Completer<int>().future,
        timeout: const Duration(seconds: 1),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not confirmed'), findsOneWidget);
  });
}
