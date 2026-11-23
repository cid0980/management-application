import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/recent_records.dart';

void main() {
  test('newest first, no repeats, only the last few kept', () {
    final r = RecentRecords(keep: 3);
    addTearDown(r.dispose);
    r.visit('/service/a');
    r.visit('/sales/b');
    r.visit('/service/a');
    expect(r.routes, ['/service/a', '/sales/b']);
    r.visit('/customers/c');
    r.visit('/products/d');
    expect(r.routes, ['/products/d', '/customers/c', '/service/a']);
    r.clear();
    expect(r.routes, isEmpty);
  });

  test('opening the same page again changes nothing', () {
    final r = RecentRecords();
    addTearDown(r.dispose);
    var told = 0;
    r.addListener(() => told++);
    r.visit('/service/a');
    r.visit('/service/a');
    expect(told, 1);
  });
}
