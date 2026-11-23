import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/l10n/app_localizations.dart';
import 'package:fm_shop/ui/widgets/contact_buttons.dart';

void main() {
  final opened = <String>[];
  setUp(() {
    opened.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async {
            if (call.method == 'launch') {
              opened.add((call.arguments as Map)['url'] as String);
              return true;
            }
            return true;
          },
        );
  });

  Future<void> pump(WidgetTester tester, String phone) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListView(
          children: [
            SwipeToContact(
              id: 'o1',
              phone: phone,
              message: () => 'Your phone is ready',
              child: const SizedBox(
                height: 80,
                child: Card(child: Text('Galaxy A54')),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  testWidgets(
    'swipe right rings, swipe left writes on WhatsApp; the row stays',
    (tester) async {
      await pump(tester, '9876543210');
      await tester.drag(find.text('Galaxy A54'), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(opened.single, startsWith('tel:'));
      expect(opened.single, contains('9876543210'));
      expect(find.text('Galaxy A54'), findsOneWidget);

      await tester.drag(find.text('Galaxy A54'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(opened.last, contains('wa.me'));
      expect(opened.last, contains('text=Your+phone+is+ready'));
      expect(find.text('Galaxy A54'), findsOneWidget);
    },
  );

  testWidgets('a small sideways wobble while scrolling rings nobody', (
    tester,
  ) async {
    await pump(tester, '9876543210');
    await tester.drag(find.text('Galaxy A54'), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
  });

  testWidgets('no usable number: the row does not slide', (tester) async {
    await pump(tester, '');
    expect(find.byType(Dismissible), findsNothing);
  });
}
