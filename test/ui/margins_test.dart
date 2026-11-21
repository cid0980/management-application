import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/domain/settings/shop_settings.dart';
import 'package:fm_shop/ui/widgets/margins.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Role role,
  required InMemorySettingsStore settings,
}) async {
  final auth = AuthState();
  addTearDown(auth.dispose);
  await auth.signInLocally(email: 'a@b.c', role: role);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider<SettingsRepository>.value(value: settings),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) =>
              Text(canSeeMargins(context) ? 'cost shown' : 'cost hidden'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('staff do not see cost and profit unless the owner allows it',
      (tester) async {
    final settings = InMemorySettingsStore();
    addTearDown(settings.dispose);
    await _pump(tester, role: Role.staff, settings: settings);
    expect(find.text('cost hidden'), findsOneWidget);

    await settings.setStaffSeeCosts(true);
    await tester.pump();
    expect(find.text('cost shown'), findsOneWidget);
  });

  testWidgets('an admin always sees them', (tester) async {
    final settings = InMemorySettingsStore();
    addTearDown(settings.dispose);
    await _pump(tester, role: Role.admin, settings: settings);
    expect(find.text('cost shown'), findsOneWidget);
  });

  test('the switch survives a round trip, and old shops read as off', () {
    final on = ShopSettings.initial().copyWith(staffSeeCosts: true);
    expect(ShopSettings.fromMap(on.toMap()).staffSeeCosts, isTrue);
    expect(ShopSettings.fromMap(const {}).staffSeeCosts, isFalse);
  });
}
