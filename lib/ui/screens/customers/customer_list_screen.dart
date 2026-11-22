import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
import '../../widgets/shop_ui.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_theme.dart';
import '../../../domain/common/money.dart';
import '../../../domain/common/phone.dart';
import '../../../domain/customers/customer.dart';
import 'customer_form_sheet.dart';
import '../../../l10n/l10n.dart';

/// EVERYONE THE SHOP HAS SERVED
///
/// Searchable by name or number, because the person at the counter is found
/// one way or the other and never both. The search runs over the stored digits
/// too, so `98765 43210` typed with spaces still lands.
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<CustomerRepository>();

    if (repo.error != null) {
      return ErrorState(
        title: context.l10n.customerBookFailed,
        detail: repo.error!,
        onRetry: repo.load,
      );
    }

    // Best match first, most recently dealt with after: the shop's repeat
    // customers are the ones who come back.
    final rows = suggestCustomers(repo.customers, _query, limit: 500);

    return Scaffold(
      body: Column(
        children: [
          NavySearchBlock(
            fieldKey: const Key('customer-search'),
            hint: context.l10n.searchNameOrNumber,
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: repo.loading && repo.customers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                ? _NoMatch(query: _query)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _CustomerRow(customer: rows[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customer-new',
        onPressed: () => openCustomerSheet(context),
        icon: const Icon(Icons.person_add_alt),
        label: Text(context.l10n.add),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.go('/customers/${customer.id}'),
        leading: CircleAvatar(
          backgroundColor: AppTheme.surfaceSubtle,
          foregroundColor: AppTheme.primary,
          child: Text(
            customer.initials,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        // A walk-in who gave only a number is shown by that number rather than
        // as a blank row.
        title: Text(
          customer.name.isEmpty ? formatPhone(customer.phone) : customer.name,
        ),
        subtitle: Text(
          customer.name.isEmpty
              ? context.l10n.noNameGiven
              : formatPhone(customer.phone),
        ),
        // Store credit the customer can still spend.
        trailing: customer.walletBalance > 0
            ? StatusPill(
                rupees(customer.walletBalance),
                color: context.shopColors.good,
                soft: context.shopColors.goodSoft,
                icon: Icons.account_balance_wallet_outlined,
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final looksLikeANumber = isDiallablePhone(query);
    return EmptyState(
      icon: query.isEmpty ? Icons.people_outline : Icons.search_off,
      title: query.isEmpty
          ? context.l10n.nobodyInBookYet
          : context.l10n.noMatchFor(query),
      // A full number searched with no hit is almost always someone standing
      // at the counter. Offer to add them with it filled in, rather than
      // making them read it out again.
      action: looksLikeANumber
          ? FilledButton.icon(
              onPressed: () => openCustomerSheet(context, phone: query),
              icon: const Icon(Icons.person_add_alt),
              label: Text(context.l10n.addNamed(formatPhone(query))),
            )
          : null,
    );
  }
}
