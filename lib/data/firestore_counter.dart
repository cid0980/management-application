/// THE COUNTER THAT HANDS OUT NUMBERS
///
/// Label numbers, invoice numbers and service-order numbers all come from
/// here, and never from counting documents. Counting was the original
/// implementation and it broke in the only way it could: two staff saving at
/// the same moment both read "there are 412 records", both wrote 413, and the
/// scanner then opened the wrong record for one of them. A label is physical —
/// it is stuck to a phone and handed over — so a duplicate is not a display
/// bug, it is two phones the shop cannot tell apart.
///
/// So the read and the increment happen inside one transaction, on one
/// document per counter: `shops/{shopId}/counters/{key}`. What the next value
/// IS, and where a counter starts, is `domain/common/counters.dart`; this is
/// only the transaction around it.
///
/// **Per shop, on purpose.** Two shops both starting at label 26001 is
/// correct. One counter across all of them would print the same sticker number
/// on two different phones in two different towns, and a scan would open
/// somebody else's handset. The counter cannot be shared by accident because
/// it is reached through a [ShopScope], which has no way to name another
/// shop's document.
library;

import '../domain/common/counters.dart';
import 'firestore_paths.dart';

class FirestoreCounter implements NumberCounter {
  const FirestoreCounter({required this.scope});

  final ShopScope scope;

  @override
  Future<int> next(String key, {int start = 1}) {
    final ref = scope.counter(key);
    return scope.firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(ref);
      // A counter that does not exist yet, or holds something unusable,
      // starts at [start] — and never goes backwards. See
      // `nextCounterValue`.
      final data = snapshot.exists ? snapshot.data() : null;
      final value = nextCounterValue(
        data == null ? null : data['value'],
        start: start,
      );
      // Written with the number it handed out, so the next transaction reads
      // this one's answer rather than the value it was computed from.
      transaction.set(ref, {
        'value': value,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return value;
    });
  }

  /// What [key] holds without consuming anything, for showing "next label:
  /// 26043" on the labels page.
  ///
  /// A hint, not a promise: by the time a sticker is printed somebody else may
  /// have taken that number. Only [next] decides.
  Future<int?> peek(String key) async {
    final snapshot = await scope.counter(key).get();
    final data = snapshot.data();
    final value = data == null ? null : data['value'];
    return switch (value) {
      int i => i,
      num n => n.toInt(),
      String s => int.tryParse(s.trim()),
      _ => null,
    };
  }
}
