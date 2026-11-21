import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.customerBookFailed),
              const SizedBox(height: 8),
              Text(repo.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: repo.load,
                child: Text(context.l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    // Best match first, most recently dealt with after: the shop's repeat
    // customers are the ones who come back.
    final rows = suggestCustomers(repo.customers, _query, limit: 500);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              key: const Key('customer-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.searchNameOrNumber,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: rows.isEmpty
                ? _NoMatch(query: _query)
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
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
    return ListTile(
      onTap: () => context.go('/customers/${customer.id}'),
      leading: CircleAvatar(child: Text(customer.initials)),
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
      trailing: customer.walletBalance > 0
          ? Chip(label: Text('₹${customer.walletBalance}'))
          : null,
    );
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final looksLikeANumber = isDiallablePhone(query);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              query.isEmpty
                  ? context.l10n.nobodyInBookYet
                  : context.l10n.noMatchFor(query),
            ),
            const SizedBox(height: 8),
            // A full number searched with no hit is almost always someone
            // standing at the counter. Offer to add them with it filled in,
            // rather than making them read it out again.
            if (looksLikeANumber)
              FilledButton.icon(
                onPressed: () => openCustomerSheet(context, phone: query),
                icon: const Icon(Icons.person_add_alt),
                label: Text(context.l10n.addNamed(formatPhone(query))),
              ),
          ],
        ),
      ),
    );
  }
}
