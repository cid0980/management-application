import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app/auth_state.dart';
import 'app/router.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'data/customer_repository.dart';
import 'data/firestore_paths.dart';
import 'data/firestore_customer_repository.dart';
import 'data/firestore_enquiry_repository.dart';
import 'data/firestore_label_repository.dart';
import 'data/firestore_product_repository.dart';
import 'data/firestore_rating_repository.dart';
import 'data/firestore_sales_repository.dart';
import 'data/firestore_second_hand_repository.dart';
import 'data/firestore_service_repository.dart';
import 'data/firestore_settings_repository.dart';
import 'data/firestore_task_repository.dart';
import 'data/shop_repository.dart';
import 'data/enquiry_repository.dart';
import 'data/label_repository.dart';
import 'data/photo_uploader.dart';
import 'data/print_server.dart';
import 'data/printing/print_fonts.dart';
import 'data/pending_bills.dart';
import 'data/printing/label_printer_prefs.dart';
import 'data/printing/system_print_server.dart';
import 'data/product_repository.dart';
import 'data/rating_repository.dart';
import 'data/sales_repository.dart';
import 'data/second_hand_repository.dart';
import 'data/settings_repository.dart';
import 'data/service_repository.dart';
import 'data/shared_prefs_draft_store.dart';
import 'data/task_repository.dart';
import 'domain/common/form_draft.dart';
import 'domain/settings/languages.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'domain/devices/tac_registry.dart';
import 'domain/labels/label_target.dart';
import 'ui/theme/app_theme.dart';
import 'ui/tour/app_tour.dart';
import 'data/demo_stores.dart';
import 'data/recent_records.dart';
import 'data/reminders/phone_reminders.dart';
import 'data/reminders/reminder_prefs.dart';

/// Firebase is initialized before the app runs, and a failure to reach it does
/// NOT stop the app starting.
///
/// The shop's connection drops, and a till that refuses to open because it
/// could not reach Google is worse than one that opens and says so. The app
/// starts, the failure is recorded rather than swallowed so a screen can show
/// it, and the repositories fall back to empty in-memory stores — empty on
/// purpose, because a till showing invented stock is worse than one showing
/// none. See `_ShopRepositories`.
///
/// This is only about Firebase being unreachable at startup. A connection that
/// drops while the shop is working is not this: Firestore keeps a local cache
/// and queues writes, so the till carries on.
String? firebaseStartupError;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The phone's own navigation bar, in the app's colours rather than black.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    firebaseStartupError = '$e';
  }
  // Before the first screen, so the first bill of the day has its ₹ sign.
  await loadPrintFonts();
  runApp(const FmShopApp());
}

/// The app, and the one thing above every shop: who is signed in.
///
/// Everything else — stock, customers, sales, settings — belongs to a shop, so
/// it is built by [_ShopRepositories] below and rebuilt from scratch when the
/// shop changes. Keeping the repositories up here instead would mean one
/// shop's till still holding another shop's stock in memory after a switch.
class FmShopApp extends StatefulWidget {
  const FmShopApp({super.key});

  @override
  State<FmShopApp> createState() => _FmShopAppState();
}

class _FmShopAppState extends State<FmShopApp> {
  /// Local mode when Firebase could not be reached at startup, so the app is
  /// still walkable offline. See AuthState's class note.
  late final _auth = firebaseStartupError == null
      ? AuthState(
          auth: FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
        )
      : AuthState();

  late final _shops = firebaseStartupError == null
      ? FirestoreShopStore()
      : null;

  final _drafts = SharedPrefsDraftStore();

  /// The customer's side of ratings: one document by its token, no shop. Up
  /// here because the person opening a rating link is not signed in.
  late final PublicRatings _publicRatings = firebaseStartupError == null
      ? FirestorePublicRatings(firestore: FirebaseFirestore.instance)
      : InMemoryRatingStore().public;
  late final _router = buildRouter(_auth);

  @override
  void dispose() {
    _auth.dispose();
    _shops?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: _auth),
        Provider<DraftStore>.value(value: _drafts),
        Provider<PublicRatings>.value(value: _publicRatings),
        if (_shops != null)
          ChangeNotifierProvider<ShopRepository>.value(value: _shops),
      ],
      // Rebuilt whenever the signed-in person's shop changes, which also
      // covers signing out: shopId becomes null and every store is thrown
      // away with it.
      child: Consumer<AuthState>(
        builder: (context, auth, _) => _ShopRepositories(
          // The key is what forces a fresh set of stores on a shop change.
          // Without it Flutter would reuse the State and the old shop's data
          // would still be sitting in it.
          key: ValueKey(auth.shopId ?? 'no-shop'),
          shopId: auth.shopId,
          // Inside _ShopRepositories, so the shop's own settings — and with
          // them its language — are above the app rather than below it.
          child: _LocalizedApp(router: _router),
        ),
      ),
    );
  }
}

/// THE APP, IN THE SHOP'S OWN LANGUAGE
///
/// The language is the shop's setting, not the phone's: two staff on two
/// phones set to two languages work the same till and must see the same
/// words. So the locale comes from `SettingsRepository`, and the whole app
/// rebuilds when it changes — no restart, because a shop owner trying a
/// language wants to see it, not to be told to close the app.
///
/// Before anybody has signed in there is no shop and nothing stored, and the
/// device's own language is the better guess than English. `resolveLanguage`
/// decides; see `languages.dart`.
class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({required this.router});

  /// Built once, in the state above, so changing the language does not throw
  /// away the navigation stack somebody is standing in.
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    final language = resolveLanguage(
      stored: settings.settings.language,
      device: device.languageCode,
    );

    return MaterialApp.router(
      // The name in the phone's task switcher; matches the launcher label
      // (android/app/src/main/res/values/strings.xml).
      title: 'Shop Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: Locale(codeOf(language)),
      // Material's own widgets — date pickers, dialogs, the text-selection
      // menu — come from the Flutter delegates. Without them a Tamil app
      // still says "CANCEL" in the date picker.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // Plural: it declares the Cupertino localizations too, and Tamil has
        // Material translations where Cupertino has none. Listing the
        // Cupertino delegate on its own makes Flutter complain that the app's
        // own locale is unsupported.
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

/// Every repository that belongs to one shop.
///
/// Built for a [shopId] and discarded when it changes. With a shop and a
/// reachable Firebase, every one of these is the Firestore implementation,
/// reading and writing under `shops/{shopId}` — no screen can tell which it
/// is talking to, which is what the repository boundary in `lib/data/` is for.
///
/// **Without a shop, or without Firebase, they are empty in-memory stores.**
/// Not seeded ones: a till that cannot reach Google showing four invented
/// handsets is worse than one showing nothing, because somebody would try to
/// sell one. The sign-in and create-a-shop screens still need a complete
/// provider tree above them, and that is all these are for. The seed records
/// live on in the in-memory stores for the tests, which is where invented
/// data belongs.
class _ShopRepositories extends StatefulWidget {
  const _ShopRepositories({
    super.key,
    required this.shopId,
    required this.child,
  });

  /// Null when nobody is signed in, or they have an account but no shop yet.
  final String? shopId;
  final Widget child;

  @override
  State<_ShopRepositories> createState() => _ShopRepositoriesState();
}

class _ShopRepositoriesState extends State<_ShopRepositories> {
  late final SettingsRepository _settings;
  late final SecondHandRepository _secondHand;
  late final CustomerRepository _customers;
  late final ServiceRepository _service;
  late final ProductRepository _products;
  late final EnquiryRepository _enquiries;
  late final TaskRepository _tasks;
  late final SalesRepository _sales;
  late final LabelRepository _labels;
  late final RatingRepository _ratings;

  /// Read-only, and a hint rather than an answer — see tac_registry.dart.
  final _tacs = SeedTacRegistry();

  /// Labels go to the shop PC when its address is in settings, and to the
  /// phone's own print dialog otherwise. See system_print_server.dart.
  late final PrintServer _printer;

  /// Which label printer this phone uses — kept on the phone, see
  /// label_printer_prefs.dart.
  final LabelPrinterPrefs _labelPrinter = LabelPrinterPrefs()..load();
  final TourPrefs _tourPrefs = TourPrefs();

  /// The morning reminder and enquiry call-backs, shown by the phone itself
  /// (data/reminders/). On unless turned off in Settings.
  final ReminderPrefs _reminderPrefs = ReminderPrefs()..load();
  final PhoneReminders _phoneReminders = PhoneReminders();

  /// The record pages opened lately, for the Search page (recent_records.dart).
  final RecentRecords _recent = RecentRecords()..load();

  /// Practice data while a tour runs (demo_stores.dart): the screens get
  /// these stores instead of the shop's own, so nothing a tour does is kept.
  final TourSandbox _sandbox = TourSandbox();

  /// Completes bills kept on the phone while offline — see pending_bills.dart.
  late final PendingBillCompleter _pendingBills;

  /// Real photo uploads when this build is configured for them; see
  /// photo_uploader.dart.
  final PhotoUploader _photos = CloudinaryPhotoUploader();

  @override
  void initState() {
    super.initState();

    final shopId = widget.shopId;
    // This shop's data, and no other shop's. Null when there is no shop to
    // scope to — see the class note.
    final scope = shopId == null || firebaseStartupError != null
        ? null
        : ShopScope(shopId: shopId, firestore: FirebaseFirestore.instance);

    // The shop's own vocabulary. Every form's dropdowns read from here, and
    // every form files back into it after a save.
    _settings = scope == null
        ? InMemorySettingsStore()
        : FirestoreSettingsStore(scope: scope);

    _printer = ShopPrintServer(prefs: _labelPrinter);

    _secondHand = scope == null
        ? InMemorySecondHandStore(seed: const [])
        : FirestoreSecondHandStore(scope: scope);

    _customers = scope == null
        ? InMemoryCustomerStore(seed: const [])
        : FirestoreCustomerStore(scope: scope);

    // The pre-delivery checklist comes from settings, so editing it there
    // changes what has to be ticked before the next phone goes back.
    _service = scope == null
        ? InMemoryServiceStore(seed: const [], settings: _settings)
        : FirestoreServiceStore(scope: scope, settings: _settings);

    _products = scope == null
        ? InMemoryProductStore(seed: const [])
        : FirestoreProductStore(scope: scope);

    _enquiries = scope == null
        ? InMemoryEnquiryStore(seed: const [])
        : FirestoreEnquiryStore(scope: scope);

    _tasks = scope == null
        ? InMemoryTaskStore(seed: const [])
        : FirestoreTaskStore(scope: scope);

    // Completing a sale writes to stock, to products and to the wallet, so the
    // sales store holds all three rather than a screen wiring them together.
    _sales = scope == null
        ? InMemorySalesStore(
            seed: const [],
            stock: _secondHand,
            products: _products,
            customers: _customers,
          )
        : FirestoreSalesStore(
            scope: scope,
            stock: _secondHand,
            products: _products,
            customers: _customers,
          );
    _pendingBills = PendingBillCompleter(sales: _sales, settings: _settings);

    /// ONE registry per shop, because a label number is unique within a shop.
    /// Two shops both starting at 26001 is correct and expected; one counter
    /// across all of them would put the same sticker number on two different
    /// phones in two different towns.
    final targets = {
      LabelTargetKind.secondHand: LabelTargetBinding(
        snapshot: _secondHand.labelSnapshot,
        attach: (id, number) => _secondHand.attachLabel(id, number),
      ),
      LabelTargetKind.service: LabelTargetBinding(
        snapshot: _service.labelSnapshot,
        // Service orders keep no number of their own: the registry is the
        // record of which order a sticker belongs to.
        attach: (_, _) async {},
      ),
      LabelTargetKind.sale: LabelTargetBinding(
        snapshot: _sales.labelSnapshot,
        attach: (_, _) async {},
      ),
      LabelTargetKind.product: LabelTargetBinding(
        snapshot: _products.labelSnapshot,
        attach: (id, number) => _products.attachLabel(id, number),
      ),
    };
    _labels = scope == null
        ? InMemoryLabelStore(targets: targets)
        : FirestoreLabelStore(scope: scope, targets: targets);

    _ratings = scope == null
        ? InMemoryRatingStore()
        : FirestoreRatingStore(scope: scope);

    // Opens every snapshot listener. The in-memory stores' load() is a no-op,
    // so this is safe whichever implementation is in place.
    for (final store in <dynamic>[
      _settings,
      _secondHand,
      _customers,
      _service,
      _products,
      _enquiries,
      _tasks,
      _sales,
      _labels,
      _ratings,
    ]) {
      store.load();
    }
  }

  @override
  void dispose() {
    // Before the stores it listens to.
    _pendingBills.dispose();
    _settings.dispose();
    _secondHand.dispose();
    _customers.dispose();
    _service.dispose();
    _products.dispose();
    _enquiries.dispose();
    _tasks.dispose();
    _sales.dispose();
    _labels.dispose();
    _ratings.dispose();
    _labelPrinter.dispose();
    _reminderPrefs.dispose();
    _sandbox.exit();
    _sandbox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _sandbox,
    builder: (context, _) {
      // During a tour, practice stores; otherwise the shop's own.
      final d = _sandbox.demo;
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsRepository>.value(
            value: d?.settings ?? _settings,
          ),
          ChangeNotifierProvider<SecondHandRepository>.value(
            value: d?.secondHand ?? _secondHand,
          ),
          ChangeNotifierProvider<CustomerRepository>.value(
            value: d?.customers ?? _customers,
          ),
          ChangeNotifierProvider<ServiceRepository>.value(
            value: d?.service ?? _service,
          ),
          ChangeNotifierProvider<ProductRepository>.value(
            value: d?.products ?? _products,
          ),
          ChangeNotifierProvider<EnquiryRepository>.value(
            value: d?.enquiries ?? _enquiries,
          ),
          ChangeNotifierProvider<TaskRepository>.value(
            value: d?.tasks ?? _tasks,
          ),
          ChangeNotifierProvider<SalesRepository>.value(
            value: d?.sales ?? _sales,
          ),
          ChangeNotifierProvider<LabelRepository>.value(
            value: d?.labels ?? _labels,
          ),
          ChangeNotifierProvider<RatingRepository>.value(
            value: d?.ratings ?? _ratings,
          ),
          Provider<TacRegistry>.value(value: _tacs),
          Provider<PrintServer>.value(value: d?.printer ?? _printer),
          ChangeNotifierProvider<LabelPrinterPrefs>.value(value: _labelPrinter),
          Provider<PhotoUploader>.value(value: d?.photos ?? _photos),
          // The app tour is offered once per phone (ui/tour/app_tour.dart).
          Provider<TourPrefs>.value(value: _tourPrefs),
          ChangeNotifierProvider<TourSandbox>.value(value: _sandbox),
          ChangeNotifierProvider<ReminderPrefs>.value(value: _reminderPrefs),
          Provider<PhoneReminders>.value(value: _phoneReminders),
          ChangeNotifierProvider<RecentRecords>.value(value: _recent),
          // A tour's half-typed forms are not kept as drafts.
          if (d != null) Provider<DraftStore>.value(value: d.drafts),
        ],
        child: widget.child,
      );
    },
  );
}
