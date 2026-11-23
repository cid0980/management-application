import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/screens/login_screen.dart';
import '../ui/screens/customers/customer_detail_screen.dart';
import '../ui/screens/customers/import_contacts_screen.dart';
import '../ui/screens/enquiries/enquiry_detail_screen.dart';
import '../ui/screens/enquiries/enquiry_list_screen.dart';
import '../ui/screens/labels/label_registry_screen.dart';
import '../ui/screens/labels/public_scan_screen.dart';
import '../ui/screens/scanner/scanner_screen.dart';
import '../ui/screens/customers/customer_list_screen.dart';
import '../ui/screens/dashboard/dashboard_screen.dart';
import '../ui/screens/reports/reports_screen.dart';
import '../ui/screens/shops/staff_screen.dart';
import '../ui/screens/tasks/task_list_screen.dart';
import '../domain/reports/shop_report.dart' show ReportPeriod;
import '../ui/screens/expenses/expense_list_screen.dart';
import '../ui/screens/products/product_detail_screen.dart';
import '../ui/screens/products/product_list_screen.dart';
import '../ui/screens/sales/due_payments_screen.dart';
import '../ui/screens/sales/sale_detail_screen.dart';
import '../ui/screens/sales/sale_list_screen.dart';
import '../ui/screens/second_hand/second_hand_detail_screen.dart';
import '../ui/screens/second_hand/second_hand_list_screen.dart';
import '../ui/screens/settings/settings_screen.dart';
import '../ui/screens/shops/create_shop_screen.dart';
import '../ui/screens/service/service_detail_screen.dart';
import '../ui/screens/service/service_list_screen.dart';
import '../ui/shell/app_shell.dart';
import '../ui/shell/more_screen.dart';
import '../ui/screens/ratings/rate_screen.dart';
import '../ui/screens/ratings/ratings_screen.dart';
import '../ui/screens/search/search_screen.dart';
import 'nav.dart';
import 'auth_state.dart';
import '../l10n/l10n.dart';
import '../ui/theme/page_slide.dart';

/// THE ROUTE TABLE
///
/// The same paths the web app uses, so a label printed with a `/scan/:n` URL,
/// a rating link already in a customer's messages, and anything bookmarked on
/// the counter PC all still resolve.
///
/// Four routes are public: first-run setup, login, the customer rating page
/// and the scan summary. A scan has to work in the hand of someone who has
/// never signed in — that is the whole point of printing it on a label.
const Set<String> _publicPrefixes = {'/login', '/setup', '/scan', '/rate'};

bool _isPublic(String location) =>
    _publicPrefixes.any((p) => location == p || location.startsWith('$p/'));

/// Admin-only areas. A staff member who follows a link into one is put back on
/// the dashboard rather than shown an empty page.
bool _isAdminOnly(String location) =>
    location.startsWith('/admin') || location.startsWith('/reports');

GoRouter buildRouter(AuthState auth) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.uri.path;

      // The session may still be restoring, AND the shop may still be
      // resolving. Bouncing anywhere during either would throw out someone
      // who is in fact signed in, or send a shop owner to set up a shop they
      // already have.
      if (auth.loading) return null;

      if (!auth.signedIn) return _isPublic(location) ? null : '/login';

      // An account with no shop. Every screen in this app reads a shop's
      // data, so there is genuinely nothing to show them until they make one
      // — and a dashboard full of zeroes would look like a broken app rather
      // than an unfinished setup.
      if (!auth.hasShop) {
        return location == '/shop/new' ? null : '/shop/new';
      }

      // Signed in, with a shop: the setup screen is behind them.
      if (location == '/login' || location == '/' || location == '/shop/new') {
        return '/dashboard';
      }
      if (_isAdminOnly(location) && !auth.isAdmin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (_, s) => _page(s, const LoginScreen()),
      ),

      // Outside the shell on purpose: there is no shop yet, so the bottom bar
      // would point at screens with nothing behind them.
      GoRoute(
        path: '/shop/new',
        pageBuilder: (_, s) => _page(s, const CreateShopScreen()),
      ),
      // First-run setup was a screen of its own in the React app, where an
      // admin account had to be made before anything else. Here signing up IS
      // that step — the first person to sign up creates the shop and becomes
      // its owner — so the route only exists to catch an old link.
      GoRoute(path: '/setup', redirect: (_, _) => '/login'),
      GoRoute(
        path: '/scan/:labelNumber',
        pageBuilder: (context, s) => _page(
          s,
          Scaffold(
            appBar: AppBar(title: Text(context.l10n.labelTitle)),
            body: PublicScanScreen(
              labelNumber: s.pathParameters['labelNumber']!,
            ),
          ),
        ),
      ),
      // The customer's rating page: public, outside the shell, no tab bar —
      // the person opening it is not staff. See rate_screen.dart.
      GoRoute(
        path: '/rate/:token',
        pageBuilder: (_, s) =>
            _page(s, RateScreen(token: s.pathParameters['token']!)),
      ),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, s) => _tab(s, 0, const DashboardScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (_, s) => _page(s, const SearchScreen()),
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (_, s) => _page(s, const CustomerListScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, s) =>
                    _page(s, CustomerDetailScreen(id: s.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/inventory/second-hand',
            pageBuilder: (_, s) => _tab(s, 1, const SecondHandListScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, s) => _page(
                  s,
                  SecondHandDetailScreen(id: s.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (_, s) => _page(
              s,
              ProductListScreen(initialTab: s.uri.queryParameters['tab']),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, s) =>
                    _page(s, ProductDetailScreen(id: s.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/service',
            pageBuilder: (_, s) => _tab(
              s,
              2,
              ServiceListScreen(initialTab: s.uri.queryParameters['tab']),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, s) =>
                    _page(s, ServiceDetailScreen(id: s.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/sales',
            pageBuilder: (_, s) => _tab(
              s,
              3,
              SaleListScreen(initialTab: s.uri.queryParameters['tab']),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, s) =>
                    _page(s, SaleDetailScreen(id: s.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/enquiries',
            pageBuilder: (_, s) => _page(s, const EnquiryListScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, s) =>
                    _page(s, EnquiryDetailScreen(id: s.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/due-payments',
            pageBuilder: (_, s) => _page(s, const DuePaymentsScreen()),
          ),
          GoRoute(
            path: '/scanner',
            pageBuilder: (_, s) => _page(s, const ScannerScreen()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (_, s) => _page(
              s,
              ReportsScreen(
                // `?period=today` from Home's Today card.
                initialPeriod: ReportPeriod.values
                    .where((p) => p.name == s.uri.queryParameters['period'])
                    .firstOrNull,
              ),
            ),
          ),
          GoRoute(
            path: '/admin/labels',
            pageBuilder: (_, s) => _page(s, const LabelRegistryScreen()),
          ),
          GoRoute(
            path: '/admin/staff',
            pageBuilder: (_, s) => _page(s, const StaffScreen()),
          ),
          GoRoute(
            path: '/admin/ratings',
            pageBuilder: (_, s) => _page(s, const RatingsScreen()),
          ),
          GoRoute(
            path: '/expenses',
            pageBuilder: (_, s) => _page(s, const ExpenseListScreen()),
          ),
          GoRoute(
            path: '/admin/tasks',
            pageBuilder: (_, s) => _page(s, const TaskListScreen(manage: true)),
          ),
          // A staff member's own tasks. Not under /admin, so they can open it.
          GoRoute(
            path: '/tasks',
            pageBuilder: (_, s) =>
                _page(s, const TaskListScreen(manage: false)),
          ),
          GoRoute(
            path: '/admin/import-contacts',
            pageBuilder: (_, s) => _page(s, const ImportContactsScreen()),
          ),
          GoRoute(
            path: '/admin/settings',
            pageBuilder: (_, s) => _page(s, const SettingsScreen()),
            routes: [
              // One setting per page; see SettingsPage.
              GoRoute(
                path: 'models/:brand',
                pageBuilder: (_, state) => _page(
                  state,
                  BrandModelsScreen(brand: state.pathParameters['brand']!),
                ),
              ),
              GoRoute(
                path: ':page',
                pageBuilder: (_, state) {
                  final page = SettingsPage.fromName(
                    state.pathParameters['page'],
                  );
                  return _page(
                    state,
                    page == null
                        ? const SettingsScreen()
                        : SettingsPageScreen(page: page),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: kMorePath,
            pageBuilder: (_, s) => _tab(s, 4, const MoreScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, s) => Scaffold(
      appBar: AppBar(title: Text(context.l10n.notFound)),
      body: Center(child: Text(context.l10n.noScreenFor('${s.uri}'))),
    ),
  );
}

/// A bottom-bar tab slides in from the side of the tab tapped — from the
/// right when moving right along the bar, from the left when moving left —
/// a third of the way, fading as it comes. Under an opened page it moves
/// left like any other page (page_slide.dart).
int _lastTab = 0;
Object? _lastTabKey;
double _tabFrom = 0.3;

Page<void> _tab(GoRouterState state, int index, Widget child) {
  // Decided once per visit: rebuilds of the same tab keep its direction.
  if (state.pageKey != _lastTabKey) {
    _tabFrom = index >= _lastTab ? 0.3 : -0.3;
    _lastTab = index;
    _lastTabKey = state.pageKey;
  }
  final from = _tabFrom;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondary, child) =>
        pageSlide(context, animation, secondary, child, from: from, fade: true),
  );
}

/// Every page as a real MaterialPage, so it slides in and out (the theme's
/// SlidePageTransitionsBuilder). Left to itself, go_router 18 looks for
/// package:material_ui's MaterialApp, does not find the app's own, and
/// gives every page a NoTransitionPage — no movement at all, which is what
/// the owner saw opening pages from More.
Page<void> _page(GoRouterState state, Widget child) => MaterialPage<void>(
  key: state.pageKey,
  name: state.name ?? state.path,
  arguments: <String, String>{
    ...state.pathParameters,
    ...state.uri.queryParameters,
  },
  restorationId: state.pageKey.value,
  child: child,
);
