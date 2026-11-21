/// THE BOARD STAFF OPEN ON
///
/// Nine tiles, two alert rows and today's takings, each one counted from a
/// different area. The rule that shapes this whole file is about what happens
/// when one of those areas cannot be read.
///
/// **A count that failed says so. It never shows a zero.** The board is the
/// first thing anybody looks at, and "Overdue: 0" means the shop is on top of
/// its work. A permission error that renders as 0 is not a blank space
/// somebody investigates — it is a reassuring number that is a lie, and the
/// phones that should have been rung are not rung.
///
/// **One failed count does not blank the board.** Each tile carries its own
/// state, so stock being unreadable costs the stock tile and nothing else. The
/// till still shows today's takings.
///
/// **A cached list is still a number.** Firestore keeps a local copy and a
/// screen opened on a dropped connection has last-known data in hand. A tile
/// shows that number rather than a spinner: slightly stale beats blank, and
/// the alternative is a board that is empty every time the wifi hiccups.
///
/// The counting itself is not here. Every number comes from the function that
/// already owns that rule — `serviceAlerts`, `lowStockAlerts`,
/// `totalOutstanding`, `openEnquiryCount` — so the board and the list it lands
/// on can never disagree about what "overdue" means.
library;

import '../common/dates.dart';
import '../customers/customer.dart';
import '../enquiries/enquiry.dart';
import '../enquiries/enquiry_list.dart';
import '../products/product.dart';
import '../products/product_list.dart';
import '../sales/due_payments.dart';
import '../sales/sale.dart';
import '../service/order_list.dart';
import '../service/service_order.dart';

/// One number on the board, or the reason there is not one.
class BoardCount {
  const BoardCount.ready(num this.value) : loading = false, unavailable = null;

  const BoardCount.loading() : value = null, loading = true, unavailable = null;

  /// Said in the shop's words, naming the area. See the library note on why
  /// this is never a zero.
  const BoardCount.unavailable(String this.unavailable)
    : value = null,
      loading = false;

  final num? value;
  final bool loading;
  final String? unavailable;

  bool get isReady => value != null;

  /// Whether this tile is worth somebody's attention right now. A tile that
  /// could not be read is, which is the point.
  bool get isAlerting => unavailable != null || (value != null && value! > 0);
}

/// What an area's repository currently has: its records, and whether the last
/// read worked.
class AreaState<T> {
  const AreaState({
    required this.items,
    this.loading = false,
    this.error,
    required this.what,
  });

  final Iterable<T> items;
  final bool loading;

  /// The repository's own message, already in the shop's words.
  final String? error;

  /// The area's name, for the message when there is no count — "stock",
  /// "today's tasks".
  final String what;

  /// Count this area with [measure], or say why there is no number.
  BoardCount count(num Function(Iterable<T> items) measure) {
    if (error != null) return BoardCount.unavailable(error!);
    // A cached list is still a number. Only an area with nothing at all in
    // hand shows as loading.
    if (loading && items.isEmpty) return const BoardCount.loading();
    return BoardCount.ready(measure(items));
  }
}

/// The tiles, in the order they are laid out.
enum BoardTile {
  pendingOrders,
  overdue,
  dueToday,
  lowStock,
  duePayments,
  pendingBills,
  openEnquiries,
  customers,
  newToday,
}

/// The English label for each tile.
///
/// The screen shows the shop's language instead — see `dashboard_screen.dart`.
/// These are kept because they are what a test, a log line and a bug report
/// can name a tile by, and because a tile added without a translation falls
/// back to its English name rather than to a blank card.
const Map<BoardTile, String> kBoardTileLabels = {
  BoardTile.pendingOrders: 'Pending Orders',
  BoardTile.overdue: 'Overdue',
  BoardTile.dueToday: 'Due Today',
  BoardTile.lowStock: 'Low Stock',
  BoardTile.duePayments: 'Due Payments',
  BoardTile.pendingBills: 'Pending Bills',
  BoardTile.openEnquiries: 'Open Enquiries',
  BoardTile.customers: 'Customers',
  BoardTile.newToday: 'New Today',
};

/// Where a tile lands. Every tile is tappable and opens the list it counts —
/// a number nobody can act on is decoration.
const Map<BoardTile, String> kBoardTileRoutes = {
  BoardTile.pendingOrders: '/service',
  BoardTile.overdue: '/service',
  BoardTile.dueToday: '/service',
  BoardTile.lowStock: '/products',
  BoardTile.duePayments: '/due-payments',
  BoardTile.pendingBills: '/sales',
  BoardTile.openEnquiries: '/enquiries',
  BoardTile.customers: '/customers',
  BoardTile.newToday: '/customers',
};

/// Money, so the tile is rendered with the shop's currency rather than as a
/// plain count.
const Set<BoardTile> kMoneyTiles = {BoardTile.duePayments};

/// The two tiles that are about the shop's money, rather than its work.
///
/// Staff do not see what customers owe or what is sitting unbilled. Not
/// because either is secret from the person at the counter, but because both
/// are figures the owner acts on, and a board full of numbers nobody can do
/// anything about is a board people stop reading.
const Set<BoardTile> kAdminTiles = {
  BoardTile.duePayments,
  BoardTile.pendingBills,
};

List<BoardTile> visibleTiles({required bool isAdmin}) => [
  for (final tile in BoardTile.values)
    if (isAdmin || !kAdminTiles.contains(tile)) tile,
];

/// Everything on the board, counted.
class Board {
  const Board({
    required this.tiles,
    required this.overdueOrders,
    required this.takings,
    required this.recentOrders,
  });

  /// One entry per visible tile, in order.
  final Map<BoardTile, BoardCount> tiles;

  /// The alert row. Separate from the tiles because it is what the board is
  /// for: work that is late.
  final BoardCount overdueOrders;

  /// What the shop took today, from completed bills only.
  final BoardCount takings;

  /// The last few service orders, newest first — the shop's own answer to
  /// "what came in today".
  final List<ServiceOrder> recentOrders;

  BoardCount tile(BoardTile tile) => tiles[tile] ?? const BoardCount.loading();

  /// Whether anything on the board needs somebody now.
  bool get hasAlerts => overdueOrders.isAlerting;
}

/// Build the board for one person at one moment.
///
/// [isAdmin] decides which tiles exist at all.
Board buildBoard({
  required AreaState<ServiceOrder> orders,
  required AreaState<Sale> sales,
  required AreaState<Product> products,
  required AreaState<Customer> customers,
  required AreaState<Enquiry> enquiries,
  required bool isAdmin,
  DateTime? now,
  int recentCount = 5,
}) {
  final today = now ?? DateTime.now();

  final tiles = <BoardTile, BoardCount>{};
  for (final tile in visibleTiles(isAdmin: isAdmin)) {
    tiles[tile] = switch (tile) {
      BoardTile.pendingOrders => orders.count(
        (all) => all.where((o) => !o.closed).length,
      ),
      BoardTile.overdue => orders.count(
        (all) => serviceAlerts(all, now: today).overdue.length,
      ),
      BoardTile.dueToday => orders.count(
        (all) => serviceAlerts(all, now: today).dueToday.length,
      ),
      // The same rule the products page sorts by: no threshold means no
      // alert, so a product nobody set a level for is never "low".
      BoardTile.lowStock => products.count((all) => lowStockAlerts(all).length),
      // What customers owe, which excludes financed sales — see
      // `balanceDueFor`. The board must not put a number on this page that the
      // Due Payments list then disagrees with.
      BoardTile.duePayments => sales.count(totalOutstanding),
      // Bills started and never finished. They have moved no stock, which is
      // exactly why they are worth seeing: something is sitting in a cabinet
      // that the shop thinks it has.
      BoardTile.pendingBills => sales.count(
        (all) => all.where((s) => s.status == SaleStatus.draft).length,
      ),
      BoardTile.openEnquiries => enquiries.count(openEnquiryCount),
      BoardTile.customers => customers.count((all) => all.length),
      // Counted on when the record was created, never on `updatedAt`: editing
      // a customer from two years ago does not make them new today.
      BoardTile.newToday => customers.count(
        (all) => all.where((c) => isSameDay(c.createdAt, today)).length,
      ),
    };
  }

  return Board(
    tiles: tiles,
    overdueOrders: orders.count(
      (all) => serviceAlerts(all, now: today).overdue.length,
    ),
    takings: sales.count((all) => takingsOn(all, today)),
    recentOrders: recentServiceOrders(orders.items, count: recentCount),
  );
}

/// What the shop took on [day], from completed bills only.
///
/// A draft is not money: it is a bill somebody is still building, and counting
/// it would have the day's takings fall when a customer changed their mind. A
/// cancelled bill is not money either — it is counted out again, which is what
/// cancelling it was for.
///
/// Dated on `completedAt` rather than `createdAt`, because a bill started
/// yesterday evening and settled this morning was taken this morning.
num takingsOn(Iterable<Sale> all, DateTime day) => all
    .where((s) => s.completed && isSameDay(s.completedAt, day))
    .fold<num>(0, (sum, s) => sum + s.total);

/// The last few service orders to come in, newest first.
///
/// By `receivedAt` — when the phone was handed over the counter — rather than
/// by when the record was last touched, so a note added to an old job does not
/// push today's intake off the board.
List<ServiceOrder> recentServiceOrders(
  Iterable<ServiceOrder> all, {
  int count = 5,
}) {
  final rows = [...all]
    ..sort((a, b) {
      final x = a.receivedAt ?? a.createdAt;
      final y = b.receivedAt ?? b.createdAt;
      if (x == null && y == null) return a.title.compareTo(b.title);
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
  return rows.take(count < 0 ? 0 : count).toList();
}

/// Which greeting the clock on the wall calls for.
///
/// A part of the day, not a sentence: the words are in the shop's language
/// and belong to the screen. This is the rule — where morning ends and
/// evening starts — which is the part worth testing.
enum DayPart { morning, afternoon, evening }

DayPart dayPartFor(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return DayPart.morning;
  if (hour < 17) return DayPart.afternoon;
  return DayPart.evening;
}

/// The four things staff start from, rather than hunting through the drawer.
enum QuickAction { serviceOrder, purchase, sale, scan }

const Map<QuickAction, String> kQuickActionLabels = {
  QuickAction.serviceOrder: 'New service order',
  QuickAction.purchase: 'New purchase',
  QuickAction.sale: 'New sale',
  QuickAction.scan: 'Scan',
};

const Map<QuickAction, String> kQuickActionRoutes = {
  QuickAction.serviceOrder: '/service',
  QuickAction.purchase: '/inventory/second-hand',
  QuickAction.sale: '/sales',
  QuickAction.scan: '/scanner',
};
