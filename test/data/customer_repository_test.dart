import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/customer_repository.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/domain/customers/wallet.dart';

Customer _c(String id, {String phone = '9876543210', String name = 'Ramesh K'}) =>
    Customer(id: id, name: name, phone: phone);

WalletMove _credit(num a) =>
    WalletMove(kind: WalletMoveKind.credit, amount: a, reason: 'Refund left on account');

WalletMove _debit(num a) =>
    WalletMove(kind: WalletMoveKind.debit, amount: a, reason: 'Against bill INV-1');

void main() {
  group('saving', () {
    test('a number typed with spaces is stored clean', () async {
      final store = InMemoryCustomerStore(seed: []);
      final saved = await store.save(_c('a', phone: '+91 98765 43210'));
      expect(saved.phone, '9876543210');
      expect(store.byPhone('098765-43210')!.id, 'a');
    });

    test('every save stamps updatedAt — it is how the other till learns',
        () async {
      final store = InMemoryCustomerStore(seed: []);
      expect((await store.save(_c('a'))).updatedAt, isNotNull);
    });

    test('a form cannot write a balance', () async {
      final store = InMemoryCustomerStore(seed: [_c('a')]);
      await store.moveWallet('a', _credit(500));
      // An edit carrying a made-up balance must not move the money.
      final saved = await store.save(
        _c('a').copyWith(walletBalance: 99999, name: 'Ramesh Kumar'),
      );
      expect(saved.walletBalance, 500);
      expect(saved.name, 'Ramesh Kumar');
    });

    test('a new customer starts with an empty wallet', () async {
      final store = InMemoryCustomerStore(seed: []);
      final saved = await store.save(_c('a').copyWith(walletBalance: 1000));
      expect(saved.walletBalance, 0);
    });
  });

  group('wallet moves go through the repository, read-check-write', () {
    test('credit goes in and the balance moves', () async {
      final store = InMemoryCustomerStore(seed: [_c('a')]);
      final result = await store.moveWallet('a', _credit(350));
      expect(result.allowed, isTrue);
      expect(store.byId('a')!.walletBalance, 350);
    });

    test('a refused move leaves the balance exactly as it was', () async {
      final store = InMemoryCustomerStore(seed: [_c('a')]);
      await store.moveWallet('a', _credit(300));
      final result = await store.moveWallet('a', _debit(500));
      expect(result.allowed, isFalse);
      expect(store.byId('a')!.walletBalance, 300);
      // And leaves no line in the history: nothing happened.
      expect(store.walletHistory('a'), hasLength(1));
    });

    test('every move stamps updatedAt', () async {
      final store = InMemoryCustomerStore(seed: [_c('a')]);
      await store.moveWallet('a', _credit(100));
      expect(store.byId('a')!.updatedAt, isNotNull);
    });

    test('the history adds up to the stored balance', () async {
      final store = InMemoryCustomerStore(seed: [_c('a')]);
      await store.moveWallet('a', _credit(500));
      await store.moveWallet('a', _debit(200));
      await store.moveWallet('a', _credit(100));
      expect(store.byId('a')!.walletBalance, 400);
      expect(balanceFromHistory(store.walletHistory('a')), 400);
    });

    test('the history is newest first, and every line is stamped', () async {
      final store = InMemoryCustomerStore(seed: [_c('a')]);
      await store.moveWallet('a', _credit(500));
      await store.moveWallet('a', _debit(200));
      final history = store.walletHistory('a');
      expect(history.first.kind, WalletMoveKind.debit);
      expect(history.every((m) => m.at != null), isTrue);
    });

    test('a missing customer is said so', () {
      final store = InMemoryCustomerStore(seed: []);
      expect(
        () => store.moveWallet('nope', _credit(100)),
        throwsA(isA<NoSuchCustomer>()),
      );
    });
  });

  test('a change notifies, so the page redraws without being told', () async {
    final store = InMemoryCustomerStore(seed: [_c('a')]);
    var notified = 0;
    store.addListener(() => notified++);
    await store.save(_c('b', phone: '9123456780'));
    await store.moveWallet('a', _credit(100));
    // A refusal changed nothing, so it notifies nobody.
    await store.moveWallet('a', _debit(99999));
    expect(notified, 2);
  });

  test('the seed holds a walk-in with no name and a number written with +91',
      () {
    final store = InMemoryCustomerStore();
    expect(store.customers.any((c) => c.name.isEmpty), isTrue);
    expect(store.byPhone('9000011111')!.name, 'Kavitha R');
    expect(store.byId('c-4')!.walletBalance, 350);
  });
}
