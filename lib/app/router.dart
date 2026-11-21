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
import 'nav.dart';
import 'auth_state.dart';
import '../l10n/l10n.dart';

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
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),

      // Outside the shell on purpose: there is no shop yet, so the bottom bar
      // would point at screens with nothing behind them.
      GoRoute(path: '/shop/new', builder: (_, _) => const CreateShopScreen()),
      // First-run setup was a screen of its own in the React app, where an
      // admin account had to be made before anything else. Here signing up IS
      // that step — the first person to sign up creates the shop and becomes
      // its owner — so the route only exists to catch an old link.
      GoRoute(path: '/setup', redirect: (_, _) => '/login'),
      GoRoute(
        path: '/scan/:labelNumber',
        builder: (context, s) => Scaffold(
          appBar: AppBar(title: Text(context.l10n.labelTitle)),
          body: PublicScanScreen(labelNumber: s.pathParameters['labelNumber']!),
        ),
      ),
      // The customer's rating page: public, outside the shell, no tab bar —
      // the person opening it is not staff. See rate_screen.dart.
      GoRoute(
        path: '/rate/:token',
        builder: (_, s) => RateScreen(token: s.pathParameters['token']!),
      ),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (_, _) => const CustomerListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    CustomerDetailScreen(id: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/inventory/second-hand',
            builder: (_, _) => const SecondHandListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    SecondHandDetailScreen(id: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/products',
            builder: (_, s) =>
                ProductListScreen(initialTab: s.uri.queryParameters['tab']),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    ProductDetailScreen(id: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/service',
            builder: (_, s) =>
                ServiceListScreen(initialTab: s.uri.queryParameters['tab']),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    ServiceDetailScreen(id: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/sales',
            builder: (_, s) =>
                SaleListScreen(initialTab: s.uri.queryParameters['tab']),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    SaleDetailScreen(id: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/enquiries',
            builder: (_, _) => const EnquiryListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    EnquiryDetailScreen(id: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/due-payments',
            builder: (_, _) => const DuePaymentsScreen(),
          ),
          GoRoute(path: '/scanner', builder: (_, _) => const ScannerScreen()),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(
            path: '/admin/labels',
            builder: (_, _) => const LabelRegistryScreen(),
          ),
          GoRoute(path: '/admin/staff', builder: (_, _) => const StaffScreen()),
          GoRoute(
            path: '/admin/ratings',
            builder: (_, _) => const RatingsScreen(),
          ),
          GoRoute(
            path: '/admin/tasks',
            builder: (_, _) => const TaskListScreen(manage: true),
          ),
          // A staff member's own tasks. Not under /admin, so they can open it.
          GoRoute(
            path: '/tasks',
            builder: (_, _) => const TaskListScreen(manage: false),
          ),
          GoRoute(
            path: '/admin/import-contacts',
            builder: (_, _) => const ImportContactsScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(path: kMorePath, builder: (_, _) => const MoreScreen()),
        ],
      ),
    ],
    errorBuilder: (context, s) => Scaffold(
      appBar: AppBar(title: Text(context.l10n.notFound)),
      body: Center(child: Text(context.l10n.noScreenFor('${s.uri}'))),
    ),
  );
}
