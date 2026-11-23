import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/common/dates.dart';
import 'package:fm_shop/domain/expenses/expense.dart';
import 'package:fm_shop/domain/reports/export_csv.dart';

void main() {
  final day = DateTime(2026, 11, 23, 11);
  Expense e(
    String id,
    num amount,
    String kind, {
    String method = 'Cash',
    DateTime? at,
  }) => Expense(
    id: id,
    amount: amount,
    kind: kind,
    method: method,
    spentAt: at ?? day,
  );
  const staff = ExpenseActor(uid: 's', isAdmin: false);
  const owner = ExpenseActor(uid: 'o', isAdmin: true);

  group('who may save', () {
    test('anyone writes a new one down', () {
      expect(
        expenseSaveBlock(e('1', 60, 'Tea & food'), staff, isNew: true),
        isNull,
      );
    });
    test('only the owner changes one already saved', () {
      expect(
        expenseSaveBlock(e('1', 60, 'Tea & food'), staff, isNew: false),
        ExpenseBlock.adminOnly,
      );
      expect(
        expenseSaveBlock(e('1', 60, 'Tea & food'), owner, isNew: false),
        isNull,
      );
    });
    test('needs an amount and what it was for', () {
      expect(
        expenseSaveBlock(e('1', 0, 'Rent'), owner, isNew: true),
        ExpenseBlock.noAmount,
      );
      expect(
        expenseSaveBlock(e('1', 50, ' '), owner, isNew: true),
        ExpenseBlock.noKind,
      );
    });
  });

  test('a span: total, the cash part, and where it went, most first', () {
    final s = summarizeExpenses([
      e('1', 60, 'Tea & food'),
      e('2', 1800, 'Parts', method: 'UPI'),
      e('3', 40, 'Tea & food'),
      e('4', 15000, 'Rent', at: DateTime(2026, 10, 1)),
    ], DateRange.day(day));
    expect(s.total, 1900);
    expect(s.cash, 100);
    expect(s.count, 3);
    expect(s.byKind, [('Parts', 1800), ('Tea & food', 100)]);
  });

  test('reads back what it writes, and an old record without a day', () {
    final x = e('1', 60, 'Tea & food').copyWith(note: 'Two teas');
    final back = Expense.fromMap('1', x.toMap());
    expect(back.amount, 60);
    expect(back.note, 'Two teas');
    expect(back.spentAt, day);
    final bare = Expense.fromMap('2', {
      'amount': '25',
      'createdAt': '2026-11-20T10:00:00',
    });
    expect(bare.amount, 25);
    expect(bare.kind, 'Other');
    expect(bare.spentAt, DateTime(2026, 11, 20, 10));
  });

  test('newest first', () {
    final list = newestFirst([
      e('a', 1, 'Rent', at: DateTime(2026, 11, 1)),
      e('b', 1, 'Rent', at: DateTime(2026, 11, 20)),
    ]);
    expect(list.map((x) => x.id), ['b', 'a']);
  });

  test('as a spreadsheet: the period only, oldest first, notes quoted', () {
    final csv = expensesCsv(
      [
        e('1', 60, 'Tea & food').copyWith(note: 'tea, biscuits'),
        e('2', 1800, 'Parts', method: 'UPI', at: DateTime(2026, 11, 22)),
        e('3', 9, 'Other', at: DateTime(2026, 12, 1)),
      ],
      DateTime(2026, 11, 1),
      DateTime(2026, 12, 1),
    );
    expect(csv.split('\r\n'), [
      'Date,What for,Amount,Paid by,Note,Written by',
      '2026-11-22,Parts,1800,UPI,,',
      '2026-11-23,Tea & food,60,Cash,"tea, biscuits",',
    ]);
  });

  test('the usual ones: newest first, each different one once', () {
    final u = usualExpenses([
      e('1', 60, 'Tea & food', at: DateTime(2026, 11, 21)),
      e('2', 60, 'Tea & food', at: DateTime(2026, 11, 23)),
      e('3', 120, 'Transport', at: DateTime(2026, 11, 22)),
      e('4', 60, 'Tea & food', method: 'UPI', at: DateTime(2026, 11, 20)),
    ]);
    expect(u.map((x) => x.id), ['2', '3', '4']);
  });
}
