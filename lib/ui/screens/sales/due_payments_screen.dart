import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/nav.dart';
import '../../../data/sales_repository.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/common/money.dart';
import '../../../domain/sales/due_payments.dart';
import '../../../l10n/l10n.dart';
import '../../../domain/common/contact_links.dart';
import '../../widgets/contact_buttons.dart';

/// DUE PAYMENTS
///
/// The list staff ring people from, so what is NOT on it matters more than
/// what is.
///
/// **A financed sale is never here.** The customer paid their down payment and
/// the financier pays the shop the rest, so the customer owes the shop
/// nothing. When financed sales appeared on this list, customers were rung and
/// chased for money they did not owe, over a settlement the financier had not
/// sent yet.
///
/// That exclusion is not a filter in this file. It comes out of
/// `balanceDueFor`, which returns zero for a finance method — one rule, one
/// place, so this page and the sale page cannot disagree.
///
/// Grouped by customer, because the person at the counter is one customer with
/// three bills, not three rows.
class DuePaymentsScreen extends StatelessWidget {
  const DuePaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SalesRepository>();
    final accounts = dueAccounts(repo.sales);
    final total = totalOutstanding(repo.sales);
    final now = DateTime.now();

    if (accounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 40),
              const SizedBox(height: 12),
              Text(context.l10n.nothingOutstanding),
              const SizedBox(height: 6),
              Text(
                context.l10n.financedNotCountedHere,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.l10n.owedByCustomers('$total', '${accounts.length}'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.financedNotHere,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (final account in accounts)
          _AccountCard(account: account, now: now),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.now});

  final DueAccount account;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = account.daysOutstanding(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    account.customerName.isEmpty
                        ? formatPhone(account.customerPhone)
                        : account.customerName,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  rupees(account.outstanding),
                  style: theme.textTheme.titleSmall,
                ),
                IconButton(
                  key: Key('remind-${account.customerPhone}'),
                  tooltip: context.l10n.contactRemind,
                  icon: const Icon(
                    Icons.chat_outlined,
                    color: Color(0xFF128C4A),
                  ),
                  onPressed: () => openContactLink(
                    context,
                    whatsAppUri(
                      account.customerPhone,
                      context.l10n.waDueReminder(
                        account.customerName,
                        rupees(account.outstanding),
                        account.sales.map((s) => s.invoiceNumber).join(', '),
                        shopNameOf(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              [
                formatPhone(account.customerPhone),
                '${account.sales.length} bill(s)',
                if (days != null) context.l10n.oldestDays('$days'),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final sale in account.sales)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(sale.invoiceNumber),
                subtitle: Text(
                  context.l10n.billedPaidMethod(
                    '${sale.total}',
                    '${sale.amountPaid}',
                    sale.paymentMethod,
                  ),
                ),
                trailing: Text(rupees(sale.balanceDue)),
                // Collecting happens on the sale, where the rule lives.
                onTap: () => openPage(context, '/sales/${sale.id}'),
              ),
            if (account.customerId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      openPage(context, '/customers/${account.customerId}'),
                  child: Text(context.l10n.openTheCustomer),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
