import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/nav.dart';
import '../../data/demo_stores.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../widgets/input_sheet.dart';

/// THE APP TOURS
///
/// One tour per part of the shop — getting around, taking in a repair,
/// buying a phone, making a bill, customers, products, enquiries, money,
/// labels and search, the team, settings. A tour dims the screen except the
/// real button or box it is talking about and says what it is for, with
/// Next, Back and Skip.
///
/// The tours that show a form fill it in themselves, with practice data:
/// the tour taps the buttons and types into the boxes while you watch. For
/// the whole of a tour the app runs on practice records (demo_stores.dart),
/// so whatever it types or saves never reaches the shop's database, and the
/// shop's own records are back the moment it ends.
///
/// Every page's ? button runs the tour for that page; Settings › Help › App
/// tour lists them all; the first time anyone signs in on a phone, Getting
/// around is offered once.

/// Something a tour does before showing a step: open a form, type into it.
typedef TourAct = Future<void> Function(TourDriver d);

/// One thing to point at, and what to say about it.
class TourStep {
  const TourStep(this.target, this.title, this.body, {this.route, this.act});

  /// The key of the widget to light up; null for a card in the middle.
  final String? target;
  final String title;
  final String body;

  /// The page to be on for this step, gone to first.
  final String? route;

  /// Done before the step is shown, while the screen is not dimmed.
  final TourAct? act;
}

/// One tour: a part of the shop, start to end.
class TourChapter {
  const TourChapter({
    required this.id,
    required this.icon,
    required this.title,
    required this.blurb,
    required this.steps,
    this.pages = const [],
  });

  final String id;
  final IconData icon;
  final String title;
  final String blurb;
  final List<TourStep> steps;

  /// The pages whose ? button runs this tour (the path starts with one).
  final List<String> pages;
}

/// Getting around: what each page is for. Offered on first sign-in.
TourChapter gettingAround(AppLocalizations l) => TourChapter(
  id: 'around',
  icon: Icons.explore_outlined,
  title: l.tourChAroundTitle,
  blurb: l.tourChAroundBlurb,
  pages: const ['/dashboard', '/more'],
  steps: [
    TourStep(null, l.tourWelcomeTitle, l.tourWelcomeBody, route: '/dashboard'),
    TourStep('home-search', l.tourSearchTitle, l.tourSearchBody),
    TourStep('home-today', l.tourTodayTitle, l.tourTodayBody),
    TourStep('home-actions', l.tourActionsTitle, l.tourActionsBody),
    TourStep('home-queue', l.tourQueueTitle, l.tourQueueBody),
    TourStep('nav-bar', l.tourNavTitle, l.tourNavBody),
    TourStep(
      'mobiles-summary',
      l.tourStockTitle,
      l.tourStockBody,
      route: '/inventory/second-hand',
    ),
    TourStep('mobiles-tabs', l.tourStockTabsTitle, l.tourStockTabsBody),
    TourStep('mobiles-buy', l.tourBuyTitle, l.tourBuyBody),
    TourStep(
      'repairs-tabs',
      l.tourRepairsTitle,
      l.tourRepairsBody,
      route: '/service',
    ),
    TourStep('repairs-new', l.tourNewRepairTitle, l.tourNewRepairBody),
    TourStep('sales-tabs', l.tourBillsTitle, l.tourBillsBody, route: '/sales'),
    TourStep('sales-new', l.tourNewBillTitle, l.tourNewBillBody),
    TourStep(
      'more-/admin/settings',
      l.tourSettingsTitle,
      l.tourSettingsBody,
      route: '/more',
    ),
    TourStep(null, l.tourDoneTitle, l.tourDoneBody),
  ],
);

/// Every tour, Getting around first.
List<TourChapter> tourChapters(AppLocalizations l) => [
  gettingAround(l),
  TourChapter(
    id: 'repair',
    icon: Icons.build_outlined,
    title: l.tourChRepairTitle,
    blurb: l.tourChRepairBlurb,
    pages: const ['/service'],
    steps: [
      TourStep(
        'repairs-tabs',
        l.tourRepair1T,
        l.tourRepair1B,
        route: '/service',
      ),
      TourStep('repairs-new', l.tourRepair2T, l.tourRepair2B),
      TourStep(
        'service-customerPhone',
        l.tourRepair3T,
        l.tourRepair3B,
        act: (d) async {
          await d.tap('repairs-new');
          await d.type('service-customerPhone', '9876500001');
        },
      ),
      TourStep(
        'service-customerName',
        l.tourRepair4T,
        l.tourRepair4B,
        act: (d) async {
          await d.type('service-customerName', 'Karthik');
        },
      ),
      TourStep(
        'service-brand',
        l.tourRepair5T,
        l.tourRepair5B,
        act: (d) async {
          await d.tap('option-brand-Samsung');
        },
      ),
      TourStep(
        'service-model',
        l.tourRepair6T,
        l.tourRepair6B,
        act: (d) async {
          await d.tap('option-model-Galaxy A54');
        },
      ),
      TourStep(
        'service-imei',
        l.tourRepair7T,
        l.tourRepair7B,
        act: (d) async {
          await d.type('service-imei', '354879104523682');
        },
      ),
      TourStep(
        'service-lockType',
        l.tourRepair8T,
        l.tourRepair8B,
        act: (d) async {
          await d.tap('option-lock-PIN');
          await d.type('service-lockValue', '4417');
        },
      ),
      TourStep(
        'service-complaintFind',
        l.tourRepair9T,
        l.tourRepair9B,
        act: (d) async {
          await d.tap('option-complaint-Not charging');
        },
      ),
      TourStep(
        'service-estimatedPrice',
        l.tourRepair10T,
        l.tourRepair10B,
        act: (d) async {
          await d.type('service-estimatedPrice', '1500');
        },
      ),
      TourStep('service-expectedAt', l.tourRepair11T, l.tourRepair11B),
      TourStep('service-save', l.tourRepair12T, l.tourRepair12B),
      TourStep(
        'repair-status',
        l.tourRepair13T,
        l.tourRepair13B,
        act: (d) async {
          await d.close();
          await d.go('/service/so-1');
        },
      ),
      TourStep('repair-actions', l.tourRepair14T, l.tourRepair14B),
    ],
  ),
  TourChapter(
    id: 'buy',
    icon: Icons.add_a_photo_outlined,
    title: l.tourChBuyTitle,
    blurb: l.tourChBuyBlurb,
    pages: const ['/inventory/second-hand'],
    steps: [
      TourStep(
        'mobiles-buy',
        l.tourBuy1T,
        l.tourBuy1B,
        route: '/inventory/second-hand',
      ),
      TourStep(
        'purchase-sellerSearch',
        l.tourBuy2T,
        l.tourBuy2B,
        act: (d) async {
          await d.tap('mobiles-buy');
          await d.type('purchase-sellerSearch', 'Ramesh');
        },
      ),
      TourStep(
        'purchase-brand',
        l.tourBuy3T,
        l.tourBuy3B,
        act: (d) async {
          await d.tap('step-1');
          await d.tap('option-brand-Samsung');
        },
      ),
      TourStep(
        'purchase-rom',
        l.tourBuy4T,
        l.tourBuy4B,
        act: (d) async {
          await d.tap('option-model-Galaxy A54');
          await d.tap('option-ram-8GB');
          await d.tap('option-rom-128GB');
        },
      ),
      TourStep(
        'purchase-imei',
        l.tourBuy5T,
        l.tourBuy5B,
        act: (d) async {
          await d.type('purchase-imei', '354879104523682');
        },
      ),
      TourStep(
        'purchase-grade',
        l.tourBuy6T,
        l.tourBuy6B,
        act: (d) async {
          await d.tap('step-2');
        },
      ),
      TourStep(
        'purchase-profit',
        l.tourBuy7T,
        l.tourBuy7B,
        act: (d) async {
          await d.tap('step-3');
          await d.type('purchase-purchasePrice', '12000');
          await d.type('purchase-askingPrice', '15500');
        },
      ),
      TourStep(
        'photo-front',
        l.tourBuy8T,
        l.tourBuy8B,
        act: (d) async {
          await d.tap('step-4');
        },
      ),
      TourStep(
        'sell-make-bill',
        l.tourBuy9T,
        l.tourBuy9B,
        act: (d) async {
          await d.close();
          await d.go('/inventory/second-hand/sh-1');
        },
      ),
    ],
  ),
  TourChapter(
    id: 'bill',
    icon: Icons.receipt_long_outlined,
    title: l.tourChBillTitle,
    blurb: l.tourChBillBlurb,
    pages: const ['/sales'],
    steps: [
      TourStep('sales-tabs', l.tourBill1T, l.tourBill1B, route: '/sales'),
      TourStep(
        'sale-phone',
        l.tourBill2T,
        l.tourBill2B,
        act: (d) async {
          await d.tap('sales-new');
          await d.type('sale-phone', '9876543210');
        },
      ),
      TourStep('sale-add-product', l.tourBill3T, l.tourBill3B),
      TourStep(
        'sale-method',
        l.tourBill4T,
        l.tourBill4B,
        act: (d) async {
          await d.tap('sale-method-UPI');
        },
      ),
      TourStep('sale-paid', l.tourBill5T, l.tourBill5B),
      TourStep('sale-complete', l.tourBill6T, l.tourBill6B),
      TourStep(
        'bill-actions',
        l.tourBill7T,
        l.tourBill7B,
        act: (d) async {
          await d.close();
          await d.go('/sales/demo-s3');
        },
      ),
    ],
  ),
  TourChapter(
    id: 'customers',
    icon: Icons.people_outline,
    title: l.tourChCustomersTitle,
    blurb: l.tourChCustomersBlurb,
    pages: const ['/customers'],
    steps: [
      TourStep(
        'customer-search',
        l.tourCustomers1T,
        l.tourCustomers1B,
        route: '/customers',
      ),
      TourStep(
        'customer-phone',
        l.tourCustomers2T,
        l.tourCustomers2B,
        act: (d) async {
          await d.tap('customers-new');
          await d.type('customer-phone', '9000012345');
          await d.type('customer-name', 'Meena');
        },
      ),
      TourStep(
        null,
        l.tourCustomers3T,
        l.tourCustomers3B,
        act: (d) async {
          await d.close();
          await d.go('/customers/c-1');
        },
      ),
    ],
  ),
  TourChapter(
    id: 'products',
    icon: Icons.inventory_2_outlined,
    title: l.tourChProductsTitle,
    blurb: l.tourChProductsBlurb,
    pages: const ['/products'],
    steps: [
      TourStep(
        'product-search',
        l.tourProducts1T,
        l.tourProducts1B,
        route: '/products',
      ),
      TourStep('send-order-list', l.tourProducts2T, l.tourProducts2B),
      TourStep(
        'product-name',
        l.tourProducts3T,
        l.tourProducts3B,
        act: (d) async {
          await d.tap('products-new');
          await d.type('product-name', 'Tempered glass');
          await d.type('product-sellingPrice', '250');
        },
      ),
      TourStep(
        'product-actions',
        l.tourProducts4T,
        l.tourProducts4B,
        act: (d) async {
          await d.close();
          await d.go('/products/p-1');
        },
      ),
    ],
  ),
  TourChapter(
    id: 'enquiries',
    icon: Icons.chat_bubble_outline,
    title: l.tourChEnquiriesTitle,
    blurb: l.tourChEnquiriesBlurb,
    pages: const ['/enquiries'],
    steps: [
      TourStep(
        'enquiry-search',
        l.tourEnquiries1T,
        l.tourEnquiries1B,
        route: '/enquiries',
      ),
      TourStep(
        'enquiry-question',
        l.tourEnquiries2T,
        l.tourEnquiries2B,
        act: (d) async {
          await d.tap('enquiries-new');
          await d.type('enquiry-customerPhone', '9123400000');
          await d.tap('about-Second-hand handset');
          await d.type('enquiry-question', 'iPhone 13 under 30,000');
        },
      ),
      TourStep(
        'enquiry-actions',
        l.tourEnquiries3T,
        l.tourEnquiries3B,
        act: (d) async {
          await d.close();
          await d.go('/enquiries/enq-1');
        },
      ),
    ],
  ),
  TourChapter(
    id: 'money',
    icon: Icons.bar_chart,
    title: l.tourChMoneyTitle,
    blurb: l.tourChMoneyBlurb,
    pages: const ['/reports', '/due-payments', '/expenses'],
    steps: [
      TourStep(
        'report-periods',
        l.tourMoney1T,
        l.tourMoney1B,
        route: '/reports',
      ),
      TourStep('report-how-paid', l.tourMoney2T, l.tourMoney2B),
      TourStep('share-report', l.tourMoney3T, l.tourMoney3B),
      TourStep(null, l.tourMoney4T, l.tourMoney4B, route: '/due-payments'),
      TourStep(
        'expenses-totals',
        l.tourMoney5T,
        l.tourMoney5B,
        route: '/expenses',
      ),
      TourStep(
        'expense-kind',
        l.tourMoney6T,
        l.tourMoney6B,
        act: (d) async {
          await d.tap('expenses-new');
          await d.type('expense-amount', '60');
          await d.tap('expense-kind-Tea & food');
        },
      ),
      TourStep(
        'report-money-out',
        l.tourMoney7T,
        l.tourMoney7B,
        act: (d) async {
          await d.close();
          await d.go('/reports');
        },
      ),
    ],
  ),
  TourChapter(
    id: 'labels',
    icon: Icons.qr_code_scanner,
    title: l.tourChLabelsTitle,
    blurb: l.tourChLabelsBlurb,
    pages: const ['/scanner', '/admin/labels', '/search'],
    steps: [
      TourStep(
        'global-search',
        l.tourLabels1T,
        l.tourLabels1B,
        route: '/search',
      ),
      TourStep(
        'scan-camera',
        l.tourLabels2T,
        l.tourLabels2B,
        route: '/scanner',
      ),
      TourStep(
        'label-search',
        l.tourLabels3T,
        l.tourLabels3B,
        route: '/admin/labels',
      ),
    ],
  ),
  TourChapter(
    id: 'team',
    icon: Icons.groups_outlined,
    title: l.tourChTeamTitle,
    blurb: l.tourChTeamBlurb,
    pages: const ['/admin/staff', '/admin/tasks', '/tasks', '/admin/ratings'],
    steps: [
      TourStep(null, l.tourTeam1T, l.tourTeam1B, route: '/admin/staff'),
      TourStep('tasks-new', l.tourTeam2T, l.tourTeam2B, route: '/admin/tasks'),
      TourStep(
        'ratings-average',
        l.tourTeam3T,
        l.tourTeam3B,
        route: '/admin/ratings',
      ),
    ],
  ),
  TourChapter(
    id: 'settings',
    icon: Icons.settings_outlined,
    title: l.tourChSettingsTitle,
    blurb: l.tourChSettingsBlurb,
    pages: const ['/admin/settings'],
    steps: [
      TourStep(
        'settings-tour',
        l.tourSettings1T,
        l.tourSettings1B,
        route: '/admin/settings',
      ),
      TourStep('settings-brands', l.tourSettings2T, l.tourSettings2B),
      TourStep('settings-printer', l.tourSettings3T, l.tourSettings3B),
      TourStep('settings-web', l.tourSettings4T, l.tourSettings4B),
    ],
  ),
];

/// Whether the tour has been offered on this phone. Kept on the phone, not
/// the shop: each person holding a phone is offered it once.
class TourPrefs {
  static const _key = 'tour.offered.v1';

  Future<bool> offered() async {
    try {
      return await SharedPreferencesAsync().getBool(_key) ?? false;
    } catch (_) {
      // No storage to ask: better not to nag on every start.
      return true;
    }
  }

  Future<void> markOffered() async {
    try {
      await SharedPreferencesAsync().setBool(_key, true);
    } catch (_) {
      // Not stored: it may be offered once more. Harmless.
    }
  }
}

/// The first-run offer: "New here? Take a one-minute tour" — once per phone.
Future<void> offerTourOnce(BuildContext context, TourPrefs prefs) async {
  if (await prefs.offered()) return;
  await prefs.markOffered();
  if (!context.mounted) return;
  final l10n = context.l10n;
  final go = await showInputSheet<bool>(
    context: context,
    builder: (sheet) => InputSheet(
      title: Text(l10n.tourOfferTitle),
      content: Text(l10n.tourOfferBody),
      actions: [
        TextButton(
          key: const Key('tour-later'),
          onPressed: () => Navigator.of(sheet).pop(false),
          child: Text(l10n.tourOfferLater),
        ),
        FilledButton(
          key: const Key('tour-start'),
          onPressed: () => Navigator.of(sheet).pop(true),
          child: Text(l10n.tourOfferStart),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) await runAppTour(context);
}

/// Getting around, from the start.
Future<void> runAppTour(BuildContext context) =>
    runTour(context, gettingAround(context.l10n));

/// Settings › Help › App tour: every tour, to pick one.
Future<void> showTourMenu(BuildContext context) async {
  final chapters = tourChapters(context.l10n);
  final id = await showInputSheet<String>(
    context: context,
    builder: (sheet) => PickSheet(
      title: Text(context.l10n.tourMenuTitle),
      children: [
        for (final c in chapters)
          ListTile(
            key: Key('tour-chapter-${c.id}'),
            leading: Icon(c.icon),
            title: Text(c.title),
            subtitle: Text(c.blurb),
            trailing: const Icon(Icons.play_circle_outline),
            onTap: () => Navigator.of(sheet).pop(c.id),
          ),
      ],
    ),
  );
  if (id == null || !context.mounted) return;
  await runTour(context, chapters.firstWhere((c) => c.id == id));
}

/// The tour whose page [path] is: the longest of its page paths that [path]
/// is, or is under. Null when no tour covers it.
TourChapter? tourForPage(AppLocalizations l, String path) {
  TourChapter? best;
  var bestLength = -1;
  for (final c in tourChapters(l)) {
    for (final p in c.pages) {
      if ((path == p || path.startsWith('$p/')) && p.length > bestLength) {
        best = c;
        bestLength = p.length;
      }
    }
  }
  return best;
}

/// The ? button: the tour for the page at [path], or the list of tours when
/// no tour covers it.
Future<void> runTourHere(BuildContext context, String path) async {
  final chapter = tourForPage(context.l10n, path);
  if (chapter == null) return showTourMenu(context);
  await runTour(context, chapter);
}

enum _Move { next, back, skip }

class _View {
  const _View({
    required this.step,
    required this.hole,
    required this.index,
    required this.total,
    required this.canBack,
  });

  final TourStep step;
  final Rect? hole;
  final int index;
  final int total;
  final bool canBack;
}

/// Runs [chapter] from its first step, on practice data, and goes back to
/// the page it was started from.
Future<void> runTour(BuildContext context, TourChapter chapter) async {
  final router = GoRouter.of(context);
  final overlay = Overlay.of(context, rootOverlay: true);
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  TourSandbox? sandbox;
  try {
    sandbox = context.read<TourSandbox>();
  } on ProviderNotFoundException {
    sandbox = null;
  }
  final start = currentUri(router).toString();
  final steps = chapter.steps;
  final view = ValueNotifier<_View?>(null);
  final driving = ValueNotifier<bool>(false);
  Completer<_Move>? waiting;
  void move(_Move m) {
    final w = waiting;
    if (w != null && !w.isCompleted) w.complete(m);
  }

  final driver = TourDriver._(router, rootNavigator);
  final entry = OverlayEntry(
    builder: (_) => _TourLayer(
      view: view,
      driving: driving,
      practice: sandbox != null,
      onMove: move,
    ),
  );
  overlay.insert(entry);
  // Practice records in, before the first page is shown.
  sandbox?.enter();
  await _settle(const Duration(milliseconds: 200));
  var i = 0;
  var cameBack = false;
  try {
    while (i < steps.length) {
      final step = steps[i];
      if (!cameBack) {
        final route = step.route;
        if (route != null && currentUri(router).path != Uri.parse(route).path) {
          view.value = null;
          driving.value = true;
          await driver.go(route);
        }
        final act = step.act;
        if (act != null) {
          view.value = null;
          driving.value = true;
          try {
            await act(driver);
          } catch (_) {
            // A step that could not be acted out is still explained.
          }
        }
        driving.value = false;
      }
      cameBack = false;
      final hole = await _holeFor(step.target);
      waiting = Completer<_Move>();
      view.value = _View(
        step: step,
        hole: hole,
        index: i,
        total: steps.length,
        canBack: i > 0 && step.act == null && step.route == null,
      );
      final m = await waiting.future;
      if (m == _Move.skip) break;
      if (m == _Move.back) {
        i -= 1;
        cameBack = true;
      } else {
        i += 1;
      }
    }
  } finally {
    view.value = null;
    driving.value = true;
    // Any form the tour opened is closed before the real records return.
    rootNavigator.popUntil((r) => r is PageRoute);
    await _settle(const Duration(milliseconds: 250));
    sandbox?.exit();
    entry.remove();
    entry.dispose();
    view.dispose();
    driving.dispose();
  }
  router.go(start);
}

Future<void> _settle(Duration d) async {
  await Future<void>.delayed(d);
  await WidgetsBinding.instance.endOfFrame;
}

/// The last widget with [key] in the app — the one on top, when a form
/// sheet covers a page with the same key.
Element? _find(String key) {
  Element? found;
  void visit(Element e) {
    if (e.widget.key == Key(key)) found = e;
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return found;
}

/// What a tour step does with the app: the same taps and typing a person
/// would do, on practice data.
class TourDriver {
  TourDriver._(this._router, this._rootNavigator);

  final GoRouter _router;
  final NavigatorState _rootNavigator;
  static int _pointer = 900000;

  /// To a page.
  Future<void> go(String route) async {
    _router.go(route);
    await _settle(const Duration(milliseconds: 600));
  }

  /// A tap on the widget with [key], where a finger would tap it.
  Future<void> tap(String key) async {
    final e = _find(key);
    if (e == null) return;
    try {
      await Scrollable.ensureVisible(
        e,
        alignment: 0.4,
        duration: const Duration(milliseconds: 200),
      );
    } catch (_) {
      // Not in a scrolling list.
    }
    await _settle(const Duration(milliseconds: 150));
    final box = e.mounted ? e.findRenderObject() : null;
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final at = box.localToGlobal(box.size.center(Offset.zero));
    final id = ++_pointer;
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(pointer: id, position: at),
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(pointer: id, position: at),
    );
    await _settle(const Duration(milliseconds: 550));
  }

  /// [text] typed into the box with [key], a letter at a time.
  Future<void> type(String key, String text) async {
    final e = _find(key);
    if (e == null) return;
    try {
      await Scrollable.ensureVisible(
        e,
        alignment: 0.4,
        duration: const Duration(milliseconds: 200),
      );
    } catch (_) {
      // Not in a scrolling list.
    }
    EditableTextState? box;
    void visit(Element x) {
      if (box != null) return;
      if (x is StatefulElement && x.state is EditableTextState) {
        box = x.state as EditableTextState;
        return;
      }
      x.visitChildren(visit);
    }

    if (e is StatefulElement && e.state is EditableTextState) {
      box = e.state as EditableTextState;
    } else {
      e.visitChildren(visit);
    }
    final editable = box;
    if (editable == null) return;
    for (var n = 1; n <= text.length; n++) {
      if (!editable.mounted) return;
      editable.userUpdateTextEditingValue(
        TextEditingValue(
          text: text.substring(0, n),
          selection: TextSelection.collapsed(offset: n),
        ),
        SelectionChangedCause.keyboard,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    await _settle(const Duration(milliseconds: 250));
  }

  /// The open form closed, as its × would.
  Future<void> close() async {
    if (_find('form-close') != null) {
      await tap('form-close');
    } else {
      await _rootNavigator.maybePop();
    }
    await _settle(const Duration(milliseconds: 400));
  }
}

/// A long page builds only what is on screen, so something far down it (a
/// report's last card) does not exist until scrolled to. The page on top is
/// walked down a screen at a time until [key] turns up; null if it never
/// does, and the page is put back where it was.
Future<Element?> _sweepFor(String key) async {
  ScrollPosition? page;
  void visit(Element e) {
    if (e is StatefulElement && e.state is ScrollableState) {
      final p = (e.state as ScrollableState).position;
      // The last vertical list found is the one on top.
      if (p.axis == Axis.vertical && p.hasContentDimensions) page = p;
    }
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  final position = page;
  if (position == null) return null;
  final start = position.pixels;
  for (var i = 0; i < 40; i++) {
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo(
      (position.pixels + position.viewportDimension * 0.8).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
    final found = _find(key);
    if (found != null) return found;
  }
  position.jumpTo(start);
  await WidgetsBinding.instance.endOfFrame;
  return null;
}

/// Where the widget with [key] is on screen, brought into sight first; null
/// when it is not there.
Future<Rect?> _holeFor(String? key) async {
  if (key == null) return null;
  final element = _find(key) ?? await _sweepFor(key);
  if (element == null) return null;
  try {
    await Scrollable.ensureVisible(
      element,
      alignment: 0.3,
      duration: const Duration(milliseconds: 200),
    );
  } catch (_) {
    // Not in a scrolling list: already where it is.
  }
  await WidgetsBinding.instance.endOfFrame;
  final box = element.mounted ? element.findRenderObject() : null;
  if (box is! RenderBox || !box.attached || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

class _TourLayer extends StatelessWidget {
  const _TourLayer({
    required this.view,
    required this.driving,
    required this.practice,
    required this.onMove,
  });

  final ValueNotifier<_View?> view;
  final ValueNotifier<bool> driving;
  final bool practice;
  final void Function(_Move) onMove;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: driving,
    builder: (context, isDriving, _) {
      if (isDriving) {
        // The tour is tapping and typing: the app shows through, untouched
        // by the dim, and only a small note says what is going on.
        final pad = MediaQuery.paddingOf(context);
        return IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: pad.top + 8),
              child: Material(
                key: const Key('tour-driving'),
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    context.l10n.tourFilling,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return ValueListenableBuilder<_View?>(
        valueListenable: view,
        builder: (context, v, _) {
          final size = MediaQuery.sizeOf(context);
          final pad = MediaQuery.paddingOf(context);
          final hole = v?.hole;
          final Widget card = v == null
              ? const SizedBox.shrink()
              : _TourCard(
                  key: ValueKey(v.index),
                  view: v,
                  practice: practice,
                  onMove: onMove,
                );
          // The card goes on the other side of the lit part from the edge
          // it is nearer, so it never covers what it is talking about.
          final Widget placed;
          if (hole == null) {
            placed = Positioned.fill(
              child: Center(
                child: Padding(padding: const EdgeInsets.all(16), child: card),
              ),
            );
          } else if (hole.center.dy < size.height * 0.5) {
            placed = Positioned(
              left: 16,
              right: 16,
              top: (hole.bottom + 14).clamp(pad.top + 8, size.height - 240),
              child: card,
            );
          } else {
            placed = Positioned(
              left: 16,
              right: 16,
              bottom: (size.height - hole.top + 14).clamp(
                pad.bottom + 8,
                size.height - pad.top - 240,
              ),
              child: card,
            );
          }
          return Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                // Takes every tap: the tour is driven from its card.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: TweenAnimationBuilder<Rect?>(
                      // Nothing to point at: the lit part shrinks away.
                      tween: RectTween(
                        end:
                            hole ??
                            Rect.fromCenter(
                              center: size.center(Offset.zero),
                              width: 0,
                              height: 0,
                            ),
                      ),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOut,
                      builder: (context, r, _) =>
                          CustomPaint(painter: _HolePainter(r)),
                    ),
                  ),
                ),
                placed,
              ],
            ),
          );
        },
      );
    },
  );
}

class _HolePainter extends CustomPainter {
  _HolePainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0xA6000000);
    final all = Path()..addRect(Offset.zero & size);
    final h = hole;
    if (h == null || h.width < 2 || h.height < 2) {
      canvas.drawPath(all, dim);
      return;
    }
    final lit = RRect.fromRectAndRadius(
      h.inflate(6),
      const Radius.circular(16),
    );
    canvas.drawPath(
      Path.combine(PathOperation.difference, all, Path()..addRRect(lit)),
      dim,
    );
    canvas.drawRRect(
      lit,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.hole != hole;
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    super.key,
    required this.view,
    required this.practice,
    required this.onMove,
  });

  final _View view;
  final bool practice;
  final void Function(_Move) onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final last = view.index == view.total - 1;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Material(
          key: const Key('tour-card'),
          elevation: 8,
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.tourStepOf(view.index + 1, view.total),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  view.step.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(view.step.body, style: theme.textTheme.bodyMedium),
                if (practice) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.tourPractice,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!last)
                      TextButton(
                        key: const Key('tour-skip'),
                        onPressed: () => onMove(_Move.skip),
                        child: Text(l10n.tourSkip),
                      ),
                    const Spacer(),
                    if (view.canBack)
                      TextButton(
                        key: const Key('tour-back'),
                        onPressed: () => onMove(_Move.back),
                        child: Text(l10n.tourBack),
                      ),
                    const SizedBox(width: 4),
                    FilledButton(
                      key: const Key('tour-next'),
                      onPressed: () => onMove(_Move.next),
                      child: Text(last ? l10n.tourDone : l10n.tourNext),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
