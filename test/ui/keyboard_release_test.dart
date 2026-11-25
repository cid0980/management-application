import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/ui/shell/keyboard_release.dart';

void main() {
  Future<FocusNode> pump(WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyboardRelease(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              TextField(key: const Key('box'), focusNode: node),
              const TextField(key: Key('other')),
              FilledButton(
                key: const Key('button'),
                onPressed: () {},
                child: const Text('Go'),
              ),
              const Expanded(
                child: SizedBox(key: Key('empty'), width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
    return node;
  }

  testWidgets('a tap on empty space lets go of the box', (tester) async {
    final node = await pump(tester);
    await tester.tap(find.byKey(const Key('box')));
    await tester.pump();
    expect(node.hasFocus, isTrue);
    await tester.tap(find.byKey(const Key('empty')));
    await tester.pump();
    expect(node.hasFocus, isFalse);
  });

  testWidgets('a tap on another box moves there; a button keeps its tap', (
    tester,
  ) async {
    final node = await pump(tester);
    await tester.tap(find.byKey(const Key('box')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('other')));
    await tester.pump();
    expect(node.hasFocus, isFalse);
    expect(KeyboardRelease.typing(), isTrue);
  });

  testWidgets('a drag (scrolling) is not a tap: the box stays', (tester) async {
    final node = await pump(tester);
    await tester.tap(find.byKey(const Key('box')));
    await tester.pump();
    await tester.drag(find.byKey(const Key('empty')), const Offset(0, -200));
    await tester.pump();
    expect(node.hasFocus, isTrue);
  });

  testWidgets('the keyboard closing (Back) lets go of the box', (tester) async {
    final node = await pump(tester);
    await tester.tap(find.byKey(const Key('box')));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump(const Duration(milliseconds: 400));
    expect(node.hasFocus, isFalse);
  });

  testWidgets('a keyboard that only blinks between boxes keeps the box', (
    tester,
  ) async {
    final node = await pump(tester);
    await tester.tap(find.byKey(const Key('box')));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump(const Duration(milliseconds: 100));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pump(const Duration(milliseconds: 400));
    expect(node.hasFocus, isTrue);
  });
}
