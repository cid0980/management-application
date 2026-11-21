import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/devices/tac_registry.dart';

void main() {
  final registry = SeedTacRegistry();

  group('a TAC lookup takes whatever the scanner gave it', () {
    test('a full IMEI', () {
      final entry = registry.lookup('354879104523681');
      expect(entry!.brand, 'Samsung');
      expect(entry.model, 'Galaxy A54');
    });

    test('a bare TAC', () {
      expect(registry.lookup('35487910')!.brand, 'Samsung');
    });

    test('an IMEI with spaces and dashes', () {
      expect(registry.lookup('354 879-104 523681')!.brand, 'Samsung');
    });
  });

  group('not knowing is the ordinary case, not an error', () {
    test('a TAC the table does not have is null', () {
      // The table is never complete, and most of the shop's stock is not in
      // it. The intake form opens either way.
      expect(registry.lookup('99999999999999'), isNull);
    });

    test('too few digits to carry a TAC is null', () {
      expect(registry.lookup('26001'), isNull);
      expect(registry.lookup(''), isNull);
      expect(registry.lookup(null), isNull);
    });
  });

  test('the seed table has no duplicate TACs', () {
    final tacs = kSeedTacTable.map((e) => e.tac).toList();
    expect(tacs.toSet(), hasLength(tacs.length));
    expect(tacs.every((t) => t.length == 8), isTrue);
  });

  test('the device string skips the parts that are not filled in', () {
    expect(
      const TacEntry(tac: '1', brand: 'Samsung', model: 'A54').device,
      'Samsung A54',
    );
    expect(
      const TacEntry(tac: '1', brand: 'Samsung', model: 'A54', variant: '5G')
          .device,
      'Samsung A54 5G',
    );
  });

  test('a custom table can be injected, which is how the real one arrives', () {
    final custom = SeedTacRegistry(const [
      TacEntry(tac: '12345678', brand: 'Nothing', model: 'Phone 2a'),
    ]);
    expect(custom.lookup('123456789012345')!.brand, 'Nothing');
    expect(custom.lookup('354879104523681'), isNull);
  });
}
