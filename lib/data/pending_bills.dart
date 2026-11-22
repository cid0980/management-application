import 'dart:async';

import '../domain/sales/sale.dart';
import 'sales_repository.dart';
import 'settings_repository.dart';

/// BILLS WAITING FOR THE INTERNET
///
/// Completing a bill takes an invoice number and moves stock, both in a
/// server transaction, which cannot run offline. Rather than turn the
/// customer away, the sale form keeps such a bill as a draft marked
/// [Sale.pendingCompletion]; this completes them as soon as the phone is
/// back online.
///
/// If the shop sold the same handset elsewhere meanwhile, completion is
/// refused as it would be at the counter: the bill stays a draft, the mark is
/// cleared, and the reason is written into its notes for someone to sort out.
/// Nothing is sold twice.
class PendingBillCompleter {
  PendingBillCompleter({required this.sales, required this.settings}) {
    sales.addListener(_check);
    settings.addListener(_check);
    scheduleMicrotask(_check);
  }

  final SalesRepository sales;
  final SettingsRepository settings;
  bool _running = false;

  /// The bills still waiting.
  static List<Sale> pendingIn(Iterable<Sale> all) => [
    for (final s in all)
      if (s.pendingCompletion && s.status == SaleStatus.draft) s,
  ];

  Future<void> _check() async {
    if (_running || settings.offline || sales.loading) return;
    final pending = pendingIn(sales.sales);
    if (pending.isEmpty) return;
    _running = true;
    try {
      for (final sale in pending) {
        final SaleCompletion outcome;
        try {
          outcome = await sales.completeSale(
            sale.copyWith(pendingCompletion: false),
          );
        } catch (_) {
          // Still cannot reach the server: try again on the next change.
          return;
        }
        if (!outcome.completed) {
          await sales.saveDraft(
            sale.copyWith(
              pendingCompletion: false,
              notes: [
                if (sale.notes.isNotEmpty) sale.notes,
                'Not completed automatically: ${outcome.message ?? ''}',
              ].join('\n'),
            ),
          );
        }
      }
    } finally {
      _running = false;
    }
  }

  void dispose() {
    sales.removeListener(_check);
    settings.removeListener(_check);
  }
}
