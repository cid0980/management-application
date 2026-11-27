import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_state.dart';
import '../../../app/nav.dart';
import '../settings/settings_screen.dart' show SettingsPage, settingsTitleFor;
import '../../../data/live_window.dart' show mergedById;
import '../../../data/recent_records.dart';
import '../../../domain/sales/sale.dart';
import '../../../domain/service/service_order.dart';
import '../../../domain/enquiries/enquiry.dart';
import '../../../domain/inventory/second_hand_device.dart';

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
import '../../widgets/loading.dart';

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

  /// Records outside the live lists, found on the server for a job number,
  /// bill number, phone number or IMEI nothing on the phone matched.
  List<ServiceOrder> _olderOrders = const [];
  List<Sale> _olderSales = const [];
  List<SecondHandDevice> _olderDevices = const [];
  List<Enquiry> _olderEnquiries = const [];
  String? _askedFor;
  bool _asking = false;

  /// A job or bill number, or a phone number: worth asking the server.
  static bool _worthAsking(String q) {
    final t = q.trim();
    return t.length >= 5 &&
        RegExp(r'^[A-Za-z0-9-]+$').hasMatch(t) &&
        RegExp(r'\d{3}').hasMatch(t);
  }

  void _askServer(String q) {
    if (_askedFor == q) return;
    _askedFor = q;
    final service = _maybe<ServiceRepository>(context, listen: false);
    final sales = _maybe<SalesRepository>(context, listen: false);
    final stock = _maybe<SecondHandRepository>(context, listen: false);
    final enquiries = _maybe<EnquiryRepository>(context, listen: false);
    if (service?.liveSince == null &&
        sales?.liveSince == null &&
        stock?.liveSince == null &&
        enquiries?.liveSince == null) {
      return;
    }
    final t = q.trim();
    setState(() => _asking = true);
    Future.wait([
          service?.fetchOlder(number: t, phone: t) ??
              Future.value(const <ServiceOrder>[]),
          sales?.fetchOlder(number: t, phone: t) ??
              Future.value(const <Sale>[]),
          stock?.fetchOlder(sellerPhone: t, imei: t) ??
              Future.value(const <SecondHandDevice>[]),
          enquiries?.fetchOlder(phone: t) ?? Future.value(const <Enquiry>[]),
        ])
        .then((r) {
          if (!mounted || _askedFor != q) return;
          setState(() {
            _olderOrders = r[0] as List<ServiceOrder>;
            _olderSales = r[1] as List<Sale>;
            _olderDevices = r[2] as List<SecondHandDevice>;
            _olderEnquiries = r[3] as List<Enquiry>;
            _asking = false;
          });
        })
        .catchError((Object _) {
          if (mounted) setState(() => _asking = false);
        });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static T? _maybe<T>(BuildContext context, {bool listen = true}) {
    try {
      return Provider.of<T>(context, listen: listen);
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
      orders: mergedById([
        _maybe<ServiceRepository>(context)?.orders ?? const <ServiceOrder>[],
        if (_askedFor == q) _olderOrders,
      ], (o) => o.id),
      devices: mergedById([
        _maybe<SecondHandRepository>(context)?.devices ??
            const <SecondHandDevice>[],
        if (_askedFor == q) _olderDevices,
      ], (d) => d.id),
      sales: mergedById([
        _maybe<SalesRepository>(context)?.sales ?? const <Sale>[],
        if (_askedFor == q) _olderSales,
      ], (b) => b.id),
      customers: _maybe<CustomerRepository>(context)?.customers ?? const [],
      products: _maybe<ProductRepository>(context)?.products ?? const [],
      enquiries: mergedById([
        _maybe<EnquiryRepository>(context)?.enquiries ?? const <Enquiry>[],
        if (_askedFor == q) _olderEnquiries,
      ], (e) => e.id),
    );
    final pages = _pagesFor(context, q);
    // Nothing here for a number: the record may be older than the phone
    // keeps. Ask the server, once per query.
    if (groups.isEmpty && _worthAsking(q) && _askedFor != q) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _query.text == q) _askServer(q);
      });
    }
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
          ? _Recent(
              hits: recentHits(
                _maybe<RecentRecords>(context)?.routes ?? const [],
                orders: _maybe<ServiceRepository>(context)?.orders ?? const [],
                devices:
                    _maybe<SecondHandRepository>(context)?.devices ?? const [],
                sales: _maybe<SalesRepository>(context)?.sales ?? const [],
                customers:
                    _maybe<CustomerRepository>(context)?.customers ?? const [],
                products:
                    _maybe<ProductRepository>(context)?.products ?? const [],
                enquiries:
                    _maybe<EnquiryRepository>(context)?.enquiries ?? const [],
              ),
              onClear: () =>
                  _maybe<RecentRecords>(context, listen: false)?.clear(),
            )
          : groups.isEmpty && pages.isEmpty && _asking
          ? LoadingWords(first: context.l10n.loadingSearch)
          : groups.isEmpty && pages.isEmpty
          ? EmptyState(icon: Icons.search_off, title: l10n.noMatchFor(q))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (pages.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      l10n.searchPages,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final (title, icon, route) in pages)
                    ListTile(
                      key: Key('page-$route'),
                      leading: Icon(icon),
                      title: Text(title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openPage(context, route),
                    ),
                ],
                for (final g in groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      '${kindLabel(l10n, g.kind)} · ${g.total}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final h in g.hits) _HitTile(h),
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

  /// Pages whose name (in the phone's language or English) or usual words
  /// match: "exp" finds Expenses, "gst" the shop details, "print" the label
  /// printer. Only pages this person can open; five at most.
  static List<(String, IconData, String)> _pagesFor(
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final l10n = context.l10n;
    final isAdmin = _maybe<AuthState>(context, listen: false)?.isAdmin ?? false;
    bool hit(String title, [String english = '', String words = '']) =>
        title.toLowerCase().contains(q) ||
        english.toLowerCase().contains(q) ||
        words.split(' ').any((w) => w.isNotEmpty && w.startsWith(q));
    final out = <(String, IconData, String)>[
      for (final item in kNavItems)
        if (item.visibleTo(isAdmin: isAdmin) &&
            hit(item.labelIn(l10n), item.label, _navWords[item.path] ?? ''))
          (item.labelIn(l10n), item.icon, item.path),
      if (isAdmin)
        for (final page in SettingsPage.values)
          if (hit(
            settingsTitleFor(context, '/admin/settings/${page.name}') ?? '',
            page.name,
            _settingsWords[page] ?? '',
          ))
            (
              settingsTitleFor(context, '/admin/settings/${page.name}') ??
                  page.name,
              Icons.settings_outlined,
              '/admin/settings/${page.name}',
            ),
    ];
    return out.take(5).toList();
  }

  /// The words people use for a page that are not in its name.
  static const _navWords = {
    '/expenses': 'spent spending money out rent tea salary bills paid',
    '/reports': 'profit takings sales today month export csv excel',
    '/due-payments': 'owed owes pending credit balance udhaar',
    '/admin/labels': 'sticker barcode qr print',
    '/scanner': 'barcode qr imei camera',
    '/admin/staff': 'team employee worker invite',
    '/admin/tasks': 'todo jobs chores',
    '/inventory/second-hand': 'phones mobiles stock used',
    '/service': 'repairs jobs fix',
  };

  static const _settingsWords = {
    SettingsPage.shop: 'gst gstin address phone invoice logo name',
    SettingsPage.language: 'tamil hindi english',
    SettingsPage.printer: 'label print bluetooth sticker',
    SettingsPage.reminders: 'notification alarm morning alert',
    SettingsPage.web: 'rating review link website',
    SettingsPage.warranty: 'guarantee days',
    SettingsPage.checklist: 'delivery test check',
    SettingsPage.brands: 'models phone make',
  };

  static String kindLabel(AppLocalizations l10n, HitKind k) => switch (k) {
    HitKind.repair => l10n.navService,
    HitKind.phone => l10n.navSecondHand,
    HitKind.bill => l10n.navSales,
    HitKind.customer => l10n.navCustomers,
    HitKind.product => l10n.navProducts,
    HitKind.enquiry => l10n.navEnquiries,
  };

  static IconData kindIcon(HitKind k) => switch (k) {
    HitKind.repair => Icons.build_outlined,
    HitKind.phone => Icons.smartphone_outlined,
    HitKind.bill => Icons.receipt_long_outlined,
    HitKind.customer => Icons.person_outline,
    HitKind.product => Icons.inventory_2_outlined,
    HitKind.enquiry => Icons.chat_bubble_outline,
  };
}

class _HitTile extends StatelessWidget {
  const _HitTile(this.hit, {this.prefix = 'hit'});

  final SearchHit hit;
  final String prefix;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key('$prefix-${hit.kind.name}-${hit.id}'),
    leading: Icon(_SearchScreenState.kindIcon(hit.kind)),
    title: Text(hit.title),
    subtitle: Text(hit.subtitle),
    trailing: hit.exact ? const Icon(Icons.check_circle, size: 18) : null,
    // Opened over Search, so Back comes back to the list.
    onTap: () => openPage(context, hit.route),
  );
}

/// Before anything is typed: the records opened lately, or what Search does
/// when there are none yet.
class _Recent extends StatelessWidget {
  const _Recent({required this.hits, required this.onClear});

  final List<SearchHit> hits;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (hits.isEmpty) {
      return EmptyState(
        icon: Icons.search,
        title: l10n.searchEverythingTitle,
        detail: l10n.searchEverythingDetail,
      );
    }
    return ListView(
      key: const Key('recent-list'),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.recentlyOpened,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton(
                key: const Key('recent-clear'),
                onPressed: onClear,
                child: Text(l10n.clear),
              ),
            ],
          ),
        ),
        for (final h in hits) _HitTile(h, prefix: 'recent'),
      ],
    );
  }
}
