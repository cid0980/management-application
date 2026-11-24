import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../data/demo_stores.dart';
import '../../data/sales_repository.dart';
import '../../data/service_repository.dart';
import '../../data/shop_widget.dart';
import '../../domain/dashboard/widget_summary.dart';
import '../../l10n/l10n.dart';

/// Keeps the phone's home-screen widget in step with Home: a couple of
/// seconds after a bill or a repair changes, the widget's figures are
/// written again. Draws nothing. Does nothing during a tour (practice data
/// must not reach the home screen), while data is still loading or could
/// not be read (a zero there would be a lie), or where the app gives it no
/// widget (tests, the web).
class ShopWidgetSync extends StatefulWidget {
  const ShopWidgetSync({super.key});

  @override
  State<ShopWidgetSync> createState() => _ShopWidgetSyncState();
}

class _ShopWidgetSyncState extends State<ShopWidgetSync> {
  Timer? _soon;
  bool _started = false;

  T? _maybe<T>({bool listen = false}) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final widgetApi = _maybe<ShopWidget>();
    if (widgetApi == null) return;
    if (!_started) {
      _started = true;
      unawaited(widgetApi.init());
    }
    // Listen, so a change to either reaches here.
    _maybe<SalesRepository>(listen: true);
    _maybe<ServiceRepository>(listen: true);
    _soon?.cancel();
    _soon = Timer(const Duration(seconds: 2), _push);
  }

  Future<void> _push() async {
    if (!mounted) return;
    final widgetApi = _maybe<ShopWidget>();
    final auth = _maybe<AuthState>();
    final sales = _maybe<SalesRepository>();
    final service = _maybe<ServiceRepository>();
    if (widgetApi == null || auth == null || sales == null || service == null) {
      return;
    }
    if (_maybe<TourSandbox>()?.active ?? false) return;
    final shopId = auth.shopId;
    if (!auth.hasShop || shopId == null) return;
    if (sales.loading || service.loading) return;
    if (sales.error != null || service.error != null) return;
    final summary = summarizeForWidget(
      sales: sales.sales,
      orders: service.orders,
      now: DateTime.now(),
      includeOwed: auth.isAdmin,
    );
    await widgetApi.push(
      summary: summary,
      l10n: context.l10n,
      locale: Localizations.localeOf(context).languageCode,
      shopId: shopId,
      isAdmin: auth.isAdmin,
    );
  }

  @override
  void dispose() {
    _soon?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
