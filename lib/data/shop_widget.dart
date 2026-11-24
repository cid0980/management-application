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

/// What each line of the widget says. The keys are the ones
/// ShopWidgetProvider.kt reads.
Map<String, String> widgetTexts(
  WidgetSummary s,
  AppLocalizations l, {
  required String locale,
  required DateTime at,
}) {
  final split = [
    'UPI ${rupees(s.upi)}',
    '${l.expenseCash} ${rupees(s.cash)}',
    if (s.other > 0) '${l.otherMethods(1)} ${rupees(s.other)}',
    l.homeBillsCount(s.bills),
  ].join('  ·  ');
  return {
    'w_title': l.homeTodaysSales,
    'w_amount': rupees(s.takings),
    'w_split': split,
    'w_late': '${l.homeLate} ${s.late}',
    'w_due': '${l.homeDueToday} ${s.dueToday}',
    'w_ready': '${l.homeReady} ${s.ready}',
    'w_owed': s.owed == null || s.owed! <= 0
        ? ''
        : l.widgetOwed(rupees(s.owed!)),
    'w_updated': _time(at, locale),
  };
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
    unawaited(service.load());
    unawaited(sales.load());
    final until = DateTime.now().add(const Duration(seconds: 25));
    while ((service.loading || sales.loading) &&
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
  }
}
