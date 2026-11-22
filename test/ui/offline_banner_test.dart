import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/shell/app_shell.dart';

class _Offline extends InMemorySettingsStore {
  bool down = true;
  @override
  bool get offline => down;
}

void main() {
  testWidgets('offline says the work is safe on the phone; online says nothing',
      (tester) async {
    final store = _Offline();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsRepository>.value(
        value: store,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: OfflineBanner()),
        ),
      ),
    );
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.textContaining('saved on this phone'), findsOneWidget);

    store.down = false;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    store.notifyListeners();
    await tester.pump();
    expect(find.byKey(const Key('offline-banner')), findsNothing);
  });
}
