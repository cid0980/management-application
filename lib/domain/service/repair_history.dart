/// WHO DID WHAT TO A REPAIR, AND WHEN
///
/// Kept inside the repair's own record (one Firestore document is one read
/// however much it holds), so the repair page can say "Ready 5:10 PM · by
/// Suresh" at no extra cost. Written by the repair stores on every change —
/// not by the screens — so no path that changes a job can forget it.
library;

import '../common/dates.dart';
import 'service_order.dart';

/// Who is making changes on this phone: set by the sign-in (AuthState).
abstract final class HistoryActor {
  static String uid = '';
  static String name = '';

  static void set(String uid, String name) {
    HistoryActor.uid = uid;
    HistoryActor.name = name;
  }
}

class RepairEvent {
  const RepairEvent({
    required this.at,
    required this.kind,
    this.detail = '',
    this.byUid = '',
    this.byName = '',
  });

  /// received, technician, status, price, handedBack, returned.
  final String kind;
  final DateTime at;
  final String detail;
  final String byUid;
  final String byName;

  Map<String, Object?> toMap() => {
    'at': at.toIso8601String(),
    'kind': kind,
    if (detail.isNotEmpty) 'detail': detail,
    if (byUid.isNotEmpty) 'byUid': byUid,
    if (byName.isNotEmpty) 'byName': byName,
  };

  static RepairEvent? fromMap(Map<String, Object?> m) {
    final at = normalizeDate(m['at']);
    final kind = (m['kind'] ?? '').toString();
    if (at == null || kind.isEmpty) return null;
    return RepairEvent(
      at: at,
      kind: kind,
      detail: (m['detail'] ?? '').toString(),
      byUid: (m['byUid'] ?? '').toString(),
      byName: (m['byName'] ?? '').toString(),
    );
  }
}

/// The most a record keeps: plenty for one job, and the record stays small.
const kHistoryLimit = 60;

/// What changed between [before] (null: a new job) and [after].
List<RepairEvent> historyEvents(
  ServiceOrder? before,
  ServiceOrder after,
  DateTime at,
) {
  RepairEvent e(String kind, [String detail = '']) => RepairEvent(
    at: at,
    kind: kind,
    detail: detail,
    byUid: HistoryActor.uid,
    byName: HistoryActor.name,
  );
  if (before == null) {
    return [
      e('received'),
      if (after.technician.trim().isNotEmpty)
        e('technician', after.technician.trim()),
    ];
  }
  return [
    if (after.technicianUid != before.technicianUid ||
        after.technician.trim() != before.technician.trim())
      e('technician', after.technician.trim()),
    if (after.status != before.status)
      switch (after.status) {
        'Completed' => e(
          'handedBack',
          after.pickupPayment == null ? '' : '${after.pickupPayment!.amount}',
        ),
        'Returned' => e('returned'),
        _ => e('status', after.status),
      },
    if (after.finalPrice != null && after.finalPrice != before.finalPrice)
      e('price', '${after.finalPrice}'),
  ];
}

/// [after] carrying [before]'s history plus what changed, at most
/// [kHistoryLimit] (the oldest go first).
ServiceOrder withHistory(
  ServiceOrder? before,
  ServiceOrder after,
  DateTime at,
) {
  final events = historyEvents(before, after, at);
  final base = before?.history ?? after.history;
  if (events.isEmpty) return after.copyWith(history: base);
  final all = [...base, ...events];
  return after.copyWith(
    history: all.length > kHistoryLimit
        ? all.sublist(all.length - kHistoryLimit)
        : all,
  );
}
