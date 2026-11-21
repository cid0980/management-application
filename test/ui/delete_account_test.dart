import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/shell/more_screen.dart';

Future<AuthState> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final auth = AuthState();
  addTearDown(auth.dispose);
  await auth.signInLocally(email: 'a@b.c', role: Role.staff);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthState>.value(
      value: auth,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MoreScreen()),
      ),
    ),
  );
  return auth;
}

void main() {
  testWidgets('More offers Delete my account, explains what stays, and asks '
      'for the password', (tester) async {
    final auth = await _pump(tester);
    await tester.tap(find.byKey(const Key('delete-account')));
    await tester.pumpAndSettle();
    expect(find.textContaining('stay with the shop'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('delete-account-password')),
      'secret1',
    );
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();
    // Local mode has no account to delete, so it ends signed out.
    expect(auth.signedIn, isFalse);
  });

  testWidgets('Cancel deletes nothing', (tester) async {
    final auth = await _pump(tester);
    await tester.tap(find.byKey(const Key('delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(auth.signedIn, isTrue);
  });
}
