import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/l10n/rule_messages.dart';

/// Every fixed rule message written in lib/domain has a Tamil and a Hindi
/// line. A message added later without one fails here, by name.
void main() {
  final lit = RegExp(r"""(?:'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")""");
  final assign = RegExp(
    r"""(?:(?:errors|warnings)\['\w+'\]\s*=|\w+\.\w+:)\s*((?:(?:'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")\s*)+)[;,]""",
  );

  Set<String> domainMessages() {
    const files = [
      'sales/sale.dart',
      'customers/customer.dart',
      'inventory/purchase_validation.dart',
      'shops/shop.dart',
      'service/order_validation.dart',
      'products/product_validation.dart',
      'enquiries/enquiry.dart',
      'sales/due_payments.dart',
      'tasks/task.dart',
      'customers/wallet.dart',
      'shops/membership.dart',
      'products/stock_movement.dart',
      'enquiries/enquiry_state.dart',
    ];
    final out = <String>{};
    for (final f in files) {
      final s = File('lib/domain/$f').readAsStringSync();
      for (final m in assign.allMatches(s)) {
        final text = lit
            .allMatches(m.group(1)!)
            .map((p) => p.group(0)!.substring(1, p.group(0)!.length - 1))
            .join()
            .replaceAll(r"\'", "'");
        if (!text.contains(r'$')) out.add(text);
      }
    }
    return out;
  }

  test('every fixed rule message has Tamil and Hindi', () {
    final missing = domainMessages()
        .where((m) => !kRuleTranslations.containsKey(m))
        .toList();
    expect(missing, isEmpty, reason: 'add these to rule_messages.dart');
  });

  test('none of the translations is left in English', () {
    for (final e in kRuleTranslations.entries) {
      if (const {'RAM', 'Owner / admin'}.contains(e.key)) continue;
      expect(e.value.$1, isNot(e.key), reason: 'Tamil: ${e.key}');
      expect(e.value.$2, isNot(e.key), reason: 'Hindi: ${e.key}');
    }
  });

  test('English stays English, and unknown text passes through', () {
    expect(ruleTextIn('en', 'Brand is needed'), 'Brand is needed');
    expect(ruleTextIn('ta', 'Brand is needed'), 'பிராண்ட் தேவை');
    expect(ruleTextIn('hi', 'Brand is needed'), 'ब्रांड चाहिए');
    expect(ruleTextIn('ta', 'Something new'), 'Something new');
  });
}
