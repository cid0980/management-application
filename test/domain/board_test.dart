import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/customers/customer.dart';
import 'package:fm_shop/domain/dashboard/board.dart';
import 'package:fm_shop/domain/enquiries/enquiry.dart';
import 'package:fm_shop/domain/products/product.dart';
import 'package:fm_shop/domain/sales/sale.dart';
import 'package:fm_shop/domain/sales/sale_item.dart';
import 'package:fm_shop/domain/service/service_order.dart';

/// THE BOARD
///
/// The rule under test in most of this file is that a count which could not be
/// read says so. A zero on this board means the shop is on top of its work,
/// and a permission error rendered as 0 is a lie nobody investigates.
void main() {
  final today = DateTime(2026, 10, 25, 10);

  AreaState<T> area<T>(
    List<T> items, {
    bool loading = false,
    String? error,
    String what = 'records',
  }) =>
      AreaState<T>(items: items, loading: loading, error: error, what: what);

  Board board({
    AreaState<ServiceOrder>? orders,
    AreaState<Sale>? sales,
    AreaState<Product>? products,
    AreaState<Customer>? customers,
    AreaState<Enquiry>? enquiries,
    bool isAdmin = true,
  }) =>
      buildBoard(
        orders: orders ?? area<ServiceOrder>(const []),
        sales: sales ?? area<Sale>(const []),
        products: products ?? area<Product>(const []),
        customers: customers ?? area<Customer>(const []),
        enquiries: enquiries ?? area<Enquiry>(const []),
        isAdmin: isAdmin,
        now: today,
      );

  ServiceOrder order({
    required String id,
    String status = 'In Progress',
    DateTime? expected,
    DateTime? received,
  }) =>
      ServiceOrder(
        id: id,
        customerName: 'A customer',
        brand: 'Samsung',
        model: 'A54',
        status: status,
        expectedCompletionAt: expected,
        receivedAt: received,
      );

  Sale sale({
    required String id,
    SaleStatus status = SaleStatus.completed,
    DateTime? completedAt,
    num unitPrice = 1000,
    num amountPaid = 1000,
    String paymentMethod = 'Cash',
  }) =>
      Sale(
        id: id,
        items: [SaleItem(description: 'A thing', unitPrice: unitPrice)],
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        status: status,
        completedAt: completedAt,
      );

  group('a count that could not be read says so, never zero', () {
    test('an unreadable area reports its own message', () {
      final b = board(
        orders: area<ServiceOrder>(
          const [],
          error: "You do not have access to this shop's service orders.",
          what: 'service orders',
        ),
      );

      final overdue = b.tile(BoardTile.overdue);
      expect(overdue.isReady, isFalse);
      expect(overdue.value, isNull);
      expect(
        overdue.unavailable,
        "You do not have access to this shop's service orders.",
      );
    });

    test('and it reads as alerting, so nobody takes it for good news', () {
      final b = board(
        orders: area<ServiceOrder>(const [], error: 'Cannot reach Firestore.'),
      );

      expect(b.overdueOrders.isAlerting, isTrue);
      expect(b.hasAlerts, isTrue);
    });

    test('a real zero is not alerting', () {
      final b = board(orders: area([order(id: 'so-1', status: 'Completed')]));

      expect(b.overdueOrders.value, 0);
      expect(b.overdueOrders.isAlerting, isFalse);
    });
  });

  group('one failed count does not blank the board', () {
    test('the areas that read fine still have their numbers', () {
      final b = board(
        orders: area<ServiceOrder>(const [], error: 'Stock is unreadable'),
        customers: area([
          Customer(id: 'c-1', name: 'Ramesh', phone: '9876543210'),
          Customer(id: 'c-2', name: 'Priya', phone: '9123456780'),
        ]),
        sales: area([sale(id: 's-1', completedAt: today)]),
      );

      expect(b.tile(BoardTile.overdue).isReady, isFalse);
      expect(b.tile(BoardTile.customers).value, 2);
      expect(b.takings.value, 1000);
    });
  });

  group('a cached list is still a number', () {
    test('loading with records in hand shows the number, not a spinner', () {
      final b = board(
        customers: area(
          [Customer(id: 'c-1', name: 'Ramesh', phone: '9876543210')],
          loading: true,
        ),
      );

      expect(b.tile(BoardTile.customers).loading, isFalse);
      expect(b.tile(BoardTile.customers).value, 1);
    });

    test('loading with nothing in hand is loading', () {
      final b = board(customers: area<Customer>(const [], loading: true));

      expect(b.tile(BoardTile.customers).loading, isTrue);
      expect(b.tile(BoardTile.customers).value, isNull);
    });

    test('an error wins over loading — a failure is not a slow read', () {
      final b = board(
        customers: area<Customer>(const [], loading: true, error: 'Refused'),
      );

      expect(b.tile(BoardTile.customers).loading, isFalse);
      expect(b.tile(BoardTile.customers).unavailable, 'Refused');
    });
  });

  group('the money tiles are the admin\'s', () {
    test('staff do not get Due Payments or Pending Bills', () {
      final tiles = visibleTiles(isAdmin: false);

      expect(tiles, isNot(contains(BoardTile.duePayments)));
      expect(tiles, isNot(contains(BoardTile.pendingBills)));
      expect(tiles, contains(BoardTile.pendingOrders));
    });

    test('a staff board does not even count them', () {
      final b = board(
        isAdmin: false,
        sales: area([sale(id: 's-1', amountPaid: 0, completedAt: today)]),
      );

      expect(b.tiles.containsKey(BoardTile.duePayments), isFalse);
      // And the work tiles are all there.
      expect(b.tiles.length, visibleTiles(isAdmin: false).length);
    });

    test('an admin gets all nine', () {
      expect(visibleTiles(isAdmin: true).length, BoardTile.values.length);
    });

    test('every tile has a label and somewhere to land', () {
      for (final tile in BoardTile.values) {
        expect(kBoardTileLabels[tile], isNotNull, reason: '$tile has no label');
        expect(kBoardTileRoutes[tile], isNotNull, reason: '$tile goes nowhere');
      }
    });
  });

  group("today's takings", () {
    test('counts completed bills dated today', () {
      final total = takingsOn([
        sale(id: 's-1', completedAt: today, unitPrice: 1200),
        sale(id: 's-2', completedAt: today, unitPrice: 800),
      ], today);

      expect(total, 2000);
    });

    test('a draft is not money — it is a bill somebody is still building', () {
      final total = takingsOn([
        sale(id: 's-1', status: SaleStatus.draft, completedAt: today),
      ], today);

      expect(total, 0);
    });

    test('a cancelled bill is counted out again', () {
      final total = takingsOn([
        sale(id: 's-1', status: SaleStatus.cancelled, completedAt: today),
      ], today);

      expect(total, 0);
    });

    test('yesterday is not today', () {
      final total = takingsOn([
        sale(
          id: 's-1',
          completedAt: today.subtract(const Duration(days: 1)),
        ),
      ], today);

      expect(total, 0);
    });

    test('a bill settled this morning counts this morning, not when started',
        () {
      // completedAt is what the day's takings are dated on.
      final total = takingsOn([sale(id: 's-1', completedAt: today)], today);

      expect(total, 1000);
    });
  });

  group('new today counts when the record was made', () {
    test('a customer added today', () {
      final b = board(
        customers: area([
          Customer(
            id: 'c-1',
            name: 'Ramesh',
            phone: '9876543210',
            createdAt: today,
          ),
        ]),
      );

      expect(b.tile(BoardTile.newToday).value, 1);
    });

    test('an old customer edited today is not new', () {
      final b = board(
        customers: area([
          Customer(
            id: 'c-1',
            name: 'Ramesh',
            phone: '9876543210',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: today,
          ),
        ]),
      );

      expect(b.tile(BoardTile.newToday).value, 0);
      // Still counted as a customer, though.
      expect(b.tile(BoardTile.customers).value, 1);
    });
  });

  group('recent orders are what came in, newest first', () {
    test('sorted by when the phone was handed over', () {
      final rows = recentServiceOrders([
        order(id: 'old', received: DateTime(2026, 10, 20)),
        order(id: 'new', received: DateTime(2026, 10, 25)),
        order(id: 'middle', received: DateTime(2026, 10, 23)),
      ]);

      expect([for (final o in rows) o.id], ['new', 'middle', 'old']);
    });

    test('an order with no date sorts last rather than disappearing', () {
      final rows = recentServiceOrders([
        order(id: 'undated'),
        order(id: 'dated', received: DateTime(2026, 10, 20)),
      ]);

      expect([for (final o in rows) o.id], ['dated', 'undated']);
    });

    test('only the few that fit on the board', () {
      final rows = recentServiceOrders([
        for (var i = 0; i < 20; i++)
          order(id: 'so-$i', received: DateTime(2026, 10, i % 28 + 1)),
      ], count: 5);

      expect(rows.length, 5);
    });
  });

  group('the greeting follows the clock', () {
    test('morning, afternoon, evening', () {
      // The part of the day is the rule; the words come from the shop's
      // language, so there is nothing in English to assert here.
      expect(dayPartFor(DateTime(2026, 10, 25, 9)), DayPart.morning);
      expect(dayPartFor(DateTime(2026, 10, 25, 14)), DayPart.afternoon);
      expect(dayPartFor(DateTime(2026, 10, 25, 20)), DayPart.evening);
    });

    test('noon is afternoon and five is evening, not the other way round', () {
      expect(dayPartFor(DateTime(2026, 10, 25, 11, 59)), DayPart.morning);
      expect(dayPartFor(DateTime(2026, 10, 25, 12)), DayPart.afternoon);
      expect(dayPartFor(DateTime(2026, 10, 25, 16, 59)), DayPart.afternoon);
      expect(dayPartFor(DateTime(2026, 10, 25, 17)), DayPart.evening);
    });
  });

  group('every quick action goes somewhere', () {
    test('label and route for all four', () {
      for (final action in QuickAction.values) {
        expect(kQuickActionLabels[action], isNotNull);
        expect(kQuickActionRoutes[action], isNotNull);
      }
    });
  });
}
