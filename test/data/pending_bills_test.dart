import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/data/pending_bills.dart';
import 'package:fm_shop/data/product_repository.dart';
import 'package:fm_shop/data/sales_repository.dart';
import 'package:fm_shop/data/second_hand_repository.dart';
import 'package:fm_shop/data/settings_repository.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';

/// Settings whose "can reach the server" can be switched, as the real
/// store's does when the shop's wifi comes and goes.
class _Settings extends InMemorySettingsStore {
  bool _offline = true;

  @override
  bool get offline => _offline;

  set online(bool value) {
    _offline = !value;
    notifyListeners();
  }
}

({InMemorySalesStore sales, _Settings settings}) _stores(Sale pending) {
  final stock = InMemorySecondHandStore();
  final products = InMemoryProductStore(seed: const []);
  final customers = InMemoryCustomerStore(seed: const []);
  final sales = InMemorySalesStore(
    seed: [pending],
    stock: stock,
    products: products,
    customers: customers,
  );
  final settings = _Settings();
  addTearDown(() {
    sales.dispose();
    stock.dispose();
    products.dispose();
    customers.dispose();
    settings.dispose();
  });
  return (sales: sales, settings: settings);
}

void main() {
  const cover = Sale(
    id: 'p-1',
    items: [SaleItem(description: 'Back cover', unitPrice: 300)],
    amountPaid: 300,
    pendingCompletion: true,
  );

  test('waits while offline, then completes the bill on its own', () async {
    final s = _stores(cover);
    final completer = PendingBillCompleter(
      sales: s.sales,
      settings: s.settings,
    );
    addTearDown(completer.dispose);
    await pumpEventQueue();
    expect(s.sales.byId('p-1')!.status, SaleStatus.draft);

    s.settings.online = true;
    await pumpEventQueue();
    final done = s.sales.byId('p-1')!;
    expect(done.status, SaleStatus.completed);
    expect(done.pendingCompletion, isFalse);
    expect(done.invoiceNumber, isNotEmpty);
  });

  test('a phone sold elsewhere meanwhile is not sold twice', () async {
    // sh-3 in the seed stock is already sold.
    const handset = Sale(
      id: 'p-2',
      items: [
        SaleItem(
          description: 'Used handset',
          unitPrice: 9000,
          source: LineSource.secondHand,
          recordId: 'sh-3',
        ),
      ],
      amountPaid: 9000,
      pendingCompletion: true,
    );
    final s = _stores(handset);
    s.settings.online = true;
    final completer = PendingBillCompleter(
      sales: s.sales,
      settings: s.settings,
    );
    addTearDown(completer.dispose);
    await pumpEventQueue();
    final kept = s.sales.byId('p-2')!;
    expect(kept.status, SaleStatus.draft);
    expect(kept.pendingCompletion, isFalse);
    expect(kept.notes, contains('Not completed automatically'));
  });

  test('only drafts marked as waiting are picked up', () {
    expect(
      PendingBillCompleter.pendingIn([
        cover,
        cover.copyWith(pendingCompletion: false),
        cover.copyWith(status: SaleStatus.completed),
      ]),
      hasLength(1),
    );
  });
}
