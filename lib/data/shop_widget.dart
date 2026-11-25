import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../domain/common/money.dart';
import '../domain/dashboard/widget_summary.dart';
import '../firebase_options.dart';
import '../l10n/app_localizations.dart';
import 'customer_repository.dart';
import 'firestore_expense_repository.dart';
import 'firestore_paths.dart';
import 'firestore_sales_repository.dart';
import 'firestore_service_repository.dart';
import 'product_repository.dart';
import 'second_hand_repository.dart';

/// THE PHONE'S HOME-SCREEN WIDGET
///
/// The app writes the words and figures (in the shop's language) and Android
/// draws them (android/.../ShopWidgetProvider.kt). Written whenever Home's
/// data changes while the app is open; the widget's refresh button reads
/// today's figures from the server again in the background
/// ([shopWidgetBackground]).
///
/// Provided only by main.dart: tests and the web have no home screen.
class ShopWidget {
  const ShopWidget();

  static const androidName = 'ShopWidgetProvider';

  /// Lets the widget's refresh button run [shopWidgetBackground].
  Future<void> init() async {
    try {
      await HomeWidget.registerInteractivityCallback(shopWidgetBackground);
    } catch (_) {
      // No widget support on this phone: the app works without it.
    }
  }

  /// Signed out: the widget forgets the shop. Its figures belong to the
  /// shop, not to whoever is holding the phone next.
  Future<void> clear() async {
    try {
      for (final key in [...widgetKeys, 'shopId', 'locale', 'isAdmin']) {
        await HomeWidget.saveWidgetData<String>(key, null);
      }
      await HomeWidget.updateWidget(androidName: androidName);
    } catch (_) {
      // Nothing on the home screen.
    }
  }

  Future<void> push({
    required WidgetSummary summary,
    required AppLocalizations l10n,
    required String locale,
    required String shopId,
    required bool isAdmin,
  }) => _write(
    widgetTexts(summary, l10n, locale: locale, at: DateTime.now()),
    shopId: shopId,
    locale: locale,
    isAdmin: isAdmin,
  );
}

/// Every key the widget reads: cleared on sign-out.
const widgetKeys = [
  'w_title', 'w_amount', 'w_net', 'w_spent', //
  'w_l_upi', 'w_v_upi', 'w_l_cash', 'w_v_cash',
  'w_l_other', 'w_v_other', 'w_l_rep', 'w_v_rep',
  'w_jobs_title', 'w_late', 'w_due', 'w_ready', 'w_jobs_empty', 'w_job_n',
  'w_job0', 'w_job0_at', 'w_job0_id', 'w_job0_label',
  'w_job1', 'w_job1_at', 'w_job1_id', 'w_job1_label',
  'w_job2', 'w_job2_at', 'w_job2_id', 'w_job2_label',
  'w_t_left', 'w_t_late', 'w_t_ready', 'w_u_m', 'w_u_h', 'w_u_d',
  'w_stock', 'w_owed', 'w_updated',
  // Written by earlier versions; cleared so nothing old lingers.
  'w_split', 'w_repairs', 'w_late_job',
];

/// What each part of the widget says. The keys are the ones
/// ShopWidgetProvider.kt reads.
///
/// A repair's "3h left" is written here for the moment [at], and the phone
/// works it out again from `w_jobN_at` each time it redraws (every half
/// hour), with the same words (`w_t_*`, `w_u_*`) — see [countdown].
Map<String, String> widgetTexts(
  WidgetSummary s,
  AppLocalizations l, {
  required String locale,
  required DateTime at,
}) {
  final jobs = s.jobs.take(3).toList();
  return {
    'w_title': '${l.homeTodaysSales} · ${l.homeBillsCount(s.bills)}',
    'w_amount': rupees(s.takings),
    'w_l_upi': 'UPI',
    'w_v_upi': rupees(s.upi),
    'w_l_cash': l.expenseCash,
    'w_v_cash': rupees(s.cash),
    'w_l_other': s.other > 0 ? l.otherMethods(s.otherMethods) : '',
    'w_v_other': s.other > 0 ? rupees(s.other) : '',
    'w_l_rep': l.widgetRepairsLabel,
    'w_v_rep': rupees(s.repairsCollected),
    'w_jobs_title': l.widgetJobsTitle(s.takenIn, s.handedBack),
    'w_late': l.widgetChipLate(s.late),
    'w_due': l.widgetChipDue(s.dueToday),
    'w_ready': l.widgetChipReady(s.ready),
    'w_jobs_empty': l.widgetNoJobs,
    'w_job_n': '${jobs.length}',
    for (final (i, j) in jobs.indexed) ...{
      'w_job$i': j.name,
      'w_job${i}_at': j.ready || j.promised == null
          ? ''
          : '${j.promised!.millisecondsSinceEpoch}',
      'w_job${i}_id': j.id,
      'w_job${i}_label': jobLabel(j, l, at),
    },
    'w_t_left': l.widgetLeft('{t}'),
    'w_t_late': l.widgetLateBy('{t}'),
    'w_t_ready': l.homeReady,
    'w_u_m': l.widgetUnitMin(0).replaceFirst('0', '{n}'),
    'w_u_h': l.widgetUnitHour(0).replaceFirst('0', '{n}'),
    'w_u_d': l.widgetUnitDay(0).replaceFirst('0', '{n}'),
    'w_owed': s.owed == null || s.owed! <= 0
        ? ''
        : l.widgetOwedShort(rupees(s.owed!)),
    'w_updated': _time(at, locale),
    // Only what this run could count: the refresh button reads bills,
    // repairs and expenses, and leaves the rest as the app last wrote them.
    if (s.spent != null) ...{
      'w_net': l.widgetNetOnly(rupees(s.net!)),
      'w_spent': l.widgetSpentOnly(rupees(s.spent!)),
    },
    if (s.phonesInStock != null && s.lowStock != null && s.callsToday != null)
      'w_stock': l.widgetStockShort(
        s.phonesInStock!,
        s.lowStock!,
        s.callsToday!,
      ),
  };
}

/// "3h left", "2d late", "Ready": what a repair's chip says at [now].
String jobLabel(WidgetJob j, AppLocalizations l, DateTime now) {
  if (j.ready || j.promised == null) return l.homeReady;
  final (n, unit, kind) = countdown(j.promised!, now);
  final t = switch (unit) {
    'm' => l.widgetUnitMin(n),
    'h' => l.widgetUnitHour(n),
    _ => l.widgetUnitDay(n),
  };
  return kind == CountdownKind.late ? l.widgetLateBy(t) : l.widgetLeft(t);
}

/// The time in the shop's language; English digits if that language's
/// formats are not loaded (the refresh button runs without the app, where
/// they are not loaded unless asked for).
String _time(DateTime at, String locale) {
  try {
    return DateFormat.jm(locale).format(at);
  } catch (_) {
    return DateFormat.jm().format(at);
  }
}

Future<void> _write(
  Map<String, String> texts, {
  required String shopId,
  required String locale,
  required bool isAdmin,
}) async {
  try {
    for (final e in texts.entries) {
      await HomeWidget.saveWidgetData<String>(e.key, e.value);
    }
    // For the refresh button, which runs without the app.
    await HomeWidget.saveWidgetData<String>('shopId', shopId);
    await HomeWidget.saveWidgetData<String>('locale', locale);
    await HomeWidget.saveWidgetData<bool>('isAdmin', isAdmin);
    await HomeWidget.updateWidget(androidName: ShopWidget.androidName);
  } catch (_) {
    // Nothing on the home screen to update.
  }
}

/// The widget's refresh button: sign-in as the app left it, read today's
/// sales and repairs for the shop the app last showed, write the widget.
/// Anything that fails leaves the widget as it was.
@pragma('vm:entry-point')
Future<void> shopWidgetBackground(Uri? uri) async {
  if (uri?.host != 'refresh') return;
  FirestoreSalesStore? sales;
  FirestoreServiceStore? service;
  FirestoreExpenseStore? expenses;
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
      const Duration(seconds: 10),
    );
    final shopId = await HomeWidget.getWidgetData<String>('shopId');
    final locale = await HomeWidget.getWidgetData<String>('locale') ?? 'en';
    final isAdmin = await HomeWidget.getWidgetData<bool>('isAdmin') ?? false;
    if (user == null || shopId == null || shopId.isEmpty) return;

    final scope = ShopScope(
      shopId: shopId,
      firestore: FirebaseFirestore.instance,
    );
    service = FirestoreServiceStore(scope: scope);
    sales = FirestoreSalesStore(
      scope: scope,
      stock: InMemorySecondHandStore(seed: const []),
      products: InMemoryProductStore(seed: const []),
      customers: InMemoryCustomerStore(seed: const []),
    );
    expenses = FirestoreExpenseStore(scope: scope);
    unawaited(service.load());
    unawaited(sales.load());
    unawaited(expenses.load());
    final until = DateTime.now().add(const Duration(seconds: 25));
    while ((service.loading || sales.loading || expenses.loading) &&
        DateTime.now().isBefore(until)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (service.loading || sales.loading) return;
    if (service.error != null || sales.error != null) return;

    final summary = summarizeForWidget(
      sales: sales.sales,
      orders: service.orders,
      now: DateTime.now(),
      includeOwed: isAdmin,
      // Expenses too, when they came back in time; stock, products and
      // enquiries are not read here (each costs reads) and keep what the
      // app last wrote.
      expenses: !expenses.loading && expenses.error == null
          ? expenses.expenses
          : null,
    );
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      await initializeDateFormatting(locale);
    } catch (_) {
      // English times, then.
    }
    await _write(
      widgetTexts(summary, l10n, locale: locale, at: DateTime.now()),
      shopId: shopId,
      locale: locale,
      isAdmin: isAdmin,
    );
  } catch (_) {
    // Offline, signed out, no widget: leave it as it was.
  } finally {
    service?.dispose();
    sales?.dispose();
    expenses?.dispose();
  }
}
