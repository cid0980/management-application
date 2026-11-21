import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/domain/service/checklist.dart';
import 'package:fm_shop/domain/service/order_validation.dart';
import 'package:fm_shop/domain/service/service_order.dart';

/// An order that saves cleanly, which each test then breaks in one place.
ServiceOrder _good({
  String customerPhone = '9876543210',
  String? customerId = 'c-1',
  String brand = 'Samsung',
  String model = 'Galaxy M14',
  String imei = '354879104523681',
  List<String> complaints = const ['Not charging'],
  num estimate = 2000,
  num raw = 650,
  num labour = 0,
  String lockType = 'None',
  String lockValue = '',
  String technician = 'Suresh',
  DateTime? receivedAt,
  DateTime? expectedAt,
  Map<String, bool>? checklist,
  num? finalPrice,
  String status = 'In Progress',
}) =>
    ServiceOrder(
      id: 'o',
      customerId: customerId,
      customerPhone: customerPhone,
      brand: brand,
      model: model,
      imei: imei,
      complaints: complaints,
      estimatedPrice: estimate,
      rawMaterialCost: raw,
      outsideLabourCost: labour,
      lockType: lockType,
      lockValue: lockValue,
      technician: technician,
      status: status,
      finalPrice: finalPrice,
      checklist: checklist ?? const {},
      receivedAt: receivedAt ?? DateTime(2026, 3, 1),
      expectedCompletionAt: expectedAt ?? DateTime(2026, 3, 4),
    );

Map<String, bool> _allTicked() => {
      for (final e in checklistEntries(kDefaultPreDeliveryChecklist)) e.key: true,
    };

void main() {
  test('a complete intake saves with no errors', () {
    expect(validateOrder(_good()).isValid, isTrue);
  });

  group('one validator, both save paths', () {
    test('the job card asks exactly what a save asks', () {
      final broken = _good(complaints: const []);
      expect(validateOrder(broken).errors, contains('complaints'));
      // Not a different set, which is how a job card went out carrying an
      // Invalid Date.
      expect(validateJobCard(broken).errors, validateOrder(broken).errors);
    });
  });

  group('both dates are mandatory', () {
    test('a missing received date blocks the save', () {
      expect(
        validateOrder(_good(receivedAt: DateTime(0))).isValid,
        isTrue,
        reason: 'a real date, however odd, is a date',
      );
      final order = ServiceOrder(
        id: 'o',
        customerId: 'c-1',
        brand: 'Samsung',
        model: 'M14',
        complaints: const ['Not charging'],
        expectedCompletionAt: DateTime(2026, 3, 4),
      );
      expect(validateOrder(order).errors, contains('receivedAt'));
    });

    test('a missing promised date blocks the save', () {
      final order = ServiceOrder(
        id: 'o',
        customerId: 'c-1',
        brand: 'Samsung',
        model: 'M14',
        complaints: const ['Not charging'],
        receivedAt: DateTime(2026, 3, 1),
      );
      expect(validateOrder(order).errors, contains('expectedCompletionAt'));
    });

    test('promised before it came in is refused', () {
      final result = validateOrder(_good(
        receivedAt: DateTime(2026, 3, 4),
        expectedAt: DateTime(2026, 3, 1),
      ));
      expect(result.errors['expectedCompletionAt'], contains('before'));
    });
  });

  group('the order has to be about something', () {
    test('a customer is needed', () {
      expect(
        validateOrder(_good(customerId: null, customerPhone: '')).errors,
        contains('customer'),
      );
    });

    test('a number alone is enough — a walk-in is a customer', () {
      expect(
        validateOrder(_good(customerId: null, customerPhone: '9876543210'))
            .isValid,
        isTrue,
      );
    });

    test('brand and model are needed', () {
      expect(validateOrder(_good(brand: '')).errors, contains('brand'));
      expect(validateOrder(_good(model: '')).errors, contains('model'));
    });

    test('at least one complaint — both documents are built from these', () {
      expect(
        validateOrder(_good(complaints: const [])).errors,
        contains('complaints'),
      );
    });
  });

  group('the IMEI', () {
    test('a missing one warns but saves — a dead phone cannot be read', () {
      final result = validateOrder(_good(imei: ''));
      expect(result.isValid, isTrue);
      expect(result.warnings, contains('imei'));
    });

    test('a shop label typed into it is refused', () {
      expect(validateOrder(_good(imei: '26001')).errors, contains('imei'));
    });
  });

  group('warnings the shop may overrule', () {
    test('no estimate means the customer has not been quoted', () {
      final result = validateOrder(_good(estimate: 0));
      expect(result.isValid, isTrue);
      expect(result.warnings['estimatedPrice'], contains('not been quoted'));
    });

    test('a goodwill quote below cost is flagged, not refused', () {
      final result = validateOrder(_good(estimate: 500, raw: 900));
      expect(result.isValid, isTrue);
      expect(result.warnings, contains('estimatedPrice'));
    });

    test('a locked phone with no way in cannot be tested', () {
      final result = validateOrder(_good(lockType: 'PIN', lockValue: ''));
      expect(result.isValid, isTrue);
      expect(result.warnings['lockValue'], contains('PIN'));
    });

    test('a recorded code clears that warning', () {
      expect(
        validateOrder(_good(lockType: 'PIN', lockValue: '4417')).warnings,
        isNot(contains('lockValue')),
      );
    });

    test('nobody on the job is worth saying', () {
      expect(
        validateOrder(_good(technician: '')).warnings,
        contains('technician'),
      );
    });

    test('a negative cost is an error, not a warning', () {
      expect(validateOrder(_good(raw: -1)).errors, contains('costs'));
      expect(validateOrder(_good(estimate: -1)).errors,
          contains('estimatedPrice'));
    });
  });

  group('completion goes through the checklist, never a dropdown', () {
    test('an order with a full list and a price may be completed', () {
      final check = canComplete(
        _good(checklist: _allTicked(), finalPrice: 1800),
        checklistItems: kDefaultPreDeliveryChecklist,
      );
      expect(check.allowed, isTrue);
      expect(check.remaining, isEmpty);
    });

    test('a half-ticked list blocks it, and names what is left', () {
      final ticks = _allTicked();
      ticks[checklistEntries(kDefaultPreDeliveryChecklist).first.key] = false;
      final check = canComplete(
        _good(checklist: ticks, finalPrice: 1800),
        checklistItems: kDefaultPreDeliveryChecklist,
      );
      expect(check.allowed, isFalse);
      expect(check.blocks, contains(CompletionBlock.checklistIncomplete));
      expect(check.remaining, [kDefaultPreDeliveryChecklist.first]);
    });

    test('nothing charged blocks it — a free repair is never implicit', () {
      final check = canComplete(
        _good(checklist: _allTicked()),
        checklistItems: kDefaultPreDeliveryChecklist,
      );
      expect(check.allowed, isFalse);
      expect(check.blocks, contains(CompletionBlock.noFinalPrice));
    });

    test('a charge of zero is a decision, and passes', () {
      final check = canComplete(
        _good(checklist: _allTicked(), finalPrice: 0),
        checklistItems: kDefaultPreDeliveryChecklist,
      );
      expect(check.allowed, isTrue);
    });

    test('an order already handed back cannot be completed again', () {
      final check = canComplete(
        _good(status: 'Completed', checklist: _allTicked(), finalPrice: 1800),
        checklistItems: kDefaultPreDeliveryChecklist,
      );
      expect(check.blocks, contains(CompletionBlock.alreadyClosed));
    });

    test('an empty checklist passes — a shop with no list has nothing to check',
        () {
      final check = canComplete(
        _good(finalPrice: 1800),
        checklistItems: const [],
      );
      expect(check.allowed, isTrue);
      expect(check.remaining, isEmpty);
    });

    test('a leftover tick from a removed item cannot carry the vote', () {
      // The stored map says everything is fine, but it is keyed for a list
      // that no longer exists. The question is asked about the LIST.
      final check = canComplete(
        _good(checklist: const {'some_old_key': true}, finalPrice: 1800),
        checklistItems: const ['Display OK', 'Charging tested'],
      );
      expect(check.allowed, isFalse);
      expect(check.remaining, ['Display OK', 'Charging tested']);
    });
  });

  test('the default checklist has two labels that would collide', () {
    // "Display OK" and a label like "Display: OK!" slug to the same key.
    // checklistEntries resolves it, and keeping a near-collision in the
    // default list means this is caught here rather than by a shop that typed
    // one.
    final entries = checklistEntries(kDefaultPreDeliveryChecklist);
    expect(entries.map((e) => e.key).toSet(), hasLength(entries.length));
    expect(entries.map((e) => e.item), kDefaultPreDeliveryChecklist);
  });
}
