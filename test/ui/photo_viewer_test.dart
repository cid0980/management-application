import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:fm_shop/app/auth_state.dart';
import 'package:fm_shop/data/service_repository.dart';
import 'package:fm_shop/data/shop_photos.dart';

import '../navigation_test.dart' show pumpApp, locationOf;

/// A 1×1 PNG, enough for the page to draw and read the size of.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);
const _ref = 'fs://shops/s1/photos/202611/1.jpg';

void main() {
  late String id;

  Future<void> openRepairWithPhoto(WidgetTester tester) async {
    final auth = AuthState();
    await auth.signInLocally(email: 'a@b.c', role: Role.admin);
    final router = await pumpApp(tester, auth, size: const Size(400, 2400));
    final repo = Provider.of<ServiceRepository>(
      tester.element(find.byType(Scaffold).first),
      listen: false,
    );
    final order = repo.orders.first;
    id = order.id;
    await repo.save(order.copyWith(photos: [_ref]));
    PhotoBytes.instance.remember(_ref, _png);
    router.go('/service/$id');
    await tester.pumpAndSettle();
  }

  testWidgets('one tap opens a photo full screen, with its details', (
    tester,
  ) async {
    await openRepairWithPhoto(tester);
    await tester.ensureVisible(find.byKey(const Key('repair-photo-0')));
    await tester.tap(find.byKey(const Key('repair-photo-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsOneWidget);
    expect(find.byKey(const Key('photo-zoom')), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text('File size'), findsOneWidget);
    expect(find.text('1 KB'), findsOneWidget);
    expect(find.text('1 × 1'), findsOneWidget);
    // The details can be put away, and back.
    await tester.tap(find.byKey(const Key('photo-details-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-details')), findsNothing);
  });

  testWidgets("the phone's Back closes the photo, not the page under it", (
    tester,
  ) async {
    await openRepairWithPhoto(tester);
    final router = GoRouterLocation.of(tester);
    await tester.ensureVisible(find.byKey(const Key('repair-photo-0')));
    await tester.tap(find.byKey(const Key('repair-photo-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsNothing);
    expect(router(), '/service/$id');
  });

  testWidgets('the close button closes it too', (tester) async {
    await openRepairWithPhoto(tester);
    await tester.ensureVisible(find.byKey(const Key('repair-photo-0')));
    await tester.tap(find.byKey(const Key('repair-photo-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo-viewer')), findsNothing);
    // Opened once, the tile shows the picture from then on.
    expect(find.text('Tap to view'), findsNothing);
  });
}

/// Where the app is, read from the router the test app was built with.
class GoRouterLocation {
  static String Function() of(WidgetTester tester) {
    final context = tester.element(find.byType(Scaffold).first);
    final router = GoRouter.of(context);
    return () => locationOf(router);
  }
}
