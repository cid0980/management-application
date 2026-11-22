import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/customer_repository.dart';
import '../../../data/enquiry_repository.dart';
import '../../../data/product_repository.dart';
import '../../../data/sales_repository.dart';
import '../../../data/second_hand_repository.dart';
import '../../../data/service_repository.dart';
import '../../../domain/search/global_search.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/empty_state.dart';

/// SEARCH EVERYTHING — `/search`
///
/// The box at the top of Home. Type a name, a phone number, an IMEI, a job
/// or bill number, or a label, and every area answers at once; a row opens
/// the record itself. The rules are in `global_search.dart`.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static T? _maybe<T>(BuildContext context) {
    try {
      return Provider.of<T>(context);
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = _query.text;
    final groups = searchEverything(
      q,
      orders: _maybe<ServiceRepository>(context)?.orders ?? const [],
      devices: _maybe<SecondHandRepository>(context)?.devices ?? const [],
      sales: _maybe<SalesRepository>(context)?.sales ?? const [],
      customers: _maybe<CustomerRepository>(context)?.customers ?? const [],
      products: _maybe<ProductRepository>(context)?.products ?? const [],
      enquiries: _maybe<EnquiryRepository>(context)?.enquiries ?? const [],
    );
    return Scaffold(
      // Under the shell's own top bar: the box sits in a navy block, white,
      // the same shape as Home's search.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        titleSpacing: 16,
        title: TextField(
          key: const Key('global-search'),
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: l10n.searchEverythingHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: q.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.clear,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_query.clear),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: q.trim().isEmpty
          ? EmptyState(
              icon: Icons.search,
              title: l10n.searchEverythingTitle,
              detail: l10n.searchEverythingDetail,
            )
          : groups.isEmpty
          ? EmptyState(icon: Icons.search_off, title: l10n.noMatchFor(q))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final g in groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      '${_kindLabel(l10n, g.kind)} · ${g.total}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final h in g.hits)
                    ListTile(
                      key: Key('hit-${h.kind.name}-${h.id}'),
                      leading: Icon(_kindIcon(h.kind)),
                      title: Text(h.title),
                      subtitle: Text(h.subtitle),
                      trailing: h.exact
                          ? const Icon(Icons.check_circle, size: 18)
                          : null,
                      onTap: () => context.go(h.route),
                    ),
                  if (g.more > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.searchMore(g.more),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  static String _kindLabel(AppLocalizations l10n, HitKind k) => switch (k) {
    HitKind.repair => l10n.navService,
    HitKind.phone => l10n.navSecondHand,
    HitKind.bill => l10n.navSales,
    HitKind.customer => l10n.navCustomers,
    HitKind.product => l10n.navProducts,
    HitKind.enquiry => l10n.navEnquiries,
  };

  static IconData _kindIcon(HitKind k) => switch (k) {
    HitKind.repair => Icons.build_outlined,
    HitKind.phone => Icons.smartphone_outlined,
    HitKind.bill => Icons.receipt_long_outlined,
    HitKind.customer => Icons.person_outline,
    HitKind.product => Icons.inventory_2_outlined,
    HitKind.enquiry => Icons.chat_bubble_outline,
  };
}
