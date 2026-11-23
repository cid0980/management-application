import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/demo_stores.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('practice data has something on every page', () {
    final demo = DemoStores.create();
    addTearDown(demo.dispose);
    expect(demo.service.orders, isNotEmpty);
    expect(demo.secondHand.devices, isNotEmpty);
    expect(demo.customers.customers, isNotEmpty);
    expect(demo.products.products, isNotEmpty);
    expect(demo.enquiries.enquiries, isNotEmpty);
    expect(demo.sales.sales, hasLength(4));
    // The records the tours open by name are there.
    expect(demo.service.orders.map((o) => o.id), contains('so-1'));
    expect(demo.secondHand.devices.map((d) => d.id), contains('sh-1'));
    expect(demo.customers.customers.map((c) => c.id), contains('c-1'));
    expect(demo.products.products.map((p) => p.id), contains('p-1'));
    expect(demo.enquiries.enquiries.map((e) => e.id), contains('enq-1'));
    expect(demo.sales.sales.map((s) => s.id), contains('demo-s3'));
  });

  testWidgets('a tour switches to practice data and back', (tester) async {
    final sandbox = TourSandbox();
    var told = 0;
    sandbox.addListener(() => told++);
    expect(sandbox.active, isFalse);

    sandbox.enter();
    expect(sandbox.active, isTrue);
    final first = sandbox.demo;
    sandbox.enter(); // a second start keeps the same practice data
    expect(sandbox.demo, same(first));

    sandbox.exit();
    await tester.pump();
    expect(sandbox.active, isFalse);
    expect(told, 2);
    sandbox.dispose();
  });
}
