# fm_shop

The French Mobiles shop management app, in Flutter.

A port of the **flow** of [French-Mobiles-2026](https://github.com/Pugazhendii22/French-Mobiles-2026),
the React PWA the shop runs today — service jobs, second-hand stock, sales,
customers. Theme and colour are not carried over; see [docs/FLOW.md](docs/FLOW.md)
for what is.

Not the same product as `../mobile_app` (`french_mobiles`), which is the
customer-facing trade-in app.

## Toolchain

Installed under `~/development` and `~/Android`, all without root. `~/.bashrc`
sets the paths, so a new shell has them:

| | |
|---|---|
| Flutter | 3.47.7 stable · `~/development/flutter` |
| Dart | 3.13.5 (bundled) |
| JDK | Temurin 17 · `~/development/jdk` |
| Android SDK | platform 36, build-tools 36.0.0, platform-tools 37.0.1 · `~/Android/Sdk` |

```bash
flutter doctor -v
```

Flutter, Android and Linux desktop are green. The Linux desktop toolchain came
from the distribution:

```bash
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev
```

Only the web target is missing: `flutter run -d chrome` needs Chrome installed
and `CHROME_EXECUTABLE` set. Firefox will not do — Flutter drives the browser
over the Chrome DevTools protocol.

## Running

```bash
scripts/adb-wifi.sh      # connect the phone over wifi (scan the QR it prints)
flutter run              # then run on it
flutter run -d linux     # no device needed, fastest way to walk the flow
```

## Languages

The app is sold across states, so the shop picks its language — **English,
Tamil or Hindi** today, and the list is one `.arb` file longer each time.

```
lib/domain/settings/languages.dart   which languages exist, and how one is resolved
lib/l10n/app_en.arb                  the template every other file is keyed against
lib/l10n/app_ta.arb                  தமிழ்
lib/l10n/app_hi.arb                  हिन्दी
lib/l10n/l10n.dart                   context.l10n, with an English fallback
lib/l10n/display_labels.dart         what a STORED value is called on screen
```

The language is **the shop's**, stored as a code in its settings document, not
the phone's: two staff on two phones set to two languages work the same till
and must see the same words. It is picked at the end of setting a shop up —
guessed from the device, because a phone in Tamil usually belongs to a shop
that works in Tamil — and changed on the settings page, where it takes effect
on the next frame rather than after a restart.

With nothing stored, the device's own language is the better guess than
English. A stored language this build does not have falls back to English for
display and is **left alone** in the document, so a shop that picked Telugu in
a later build is still in Telugu when they update.

Nothing the shop typed is translated, and neither is anything a rule reads.
Brands, models and colours are the shop's own vocabulary; service statuses like
`Completed` are rule keys that `canComplete` and `firestore.rules` both compare
against, so they are stored in English and only ever displayed through a lookup.

**Every screen is translated** — 562 strings, the same keys in all three
files, which `test/ui/language_test.dart` checks along with "nothing in the
Tamil file is still the English string".

Statuses, tabs, stock states and label kinds are **keys, not words**:
`canComplete` and `firestore.rules` both compare against `'Completed'`, and a
handset's state is stored as `sold`. So the English value stays in storage and
`lib/l10n/display_labels.dart` is the one place that turns one into words a
shop reads — falling back to the stored value, so a status written by a newer
build shows as itself instead of vanishing.

The Tamil and Hindi wording is a first pass and wants a read-through by
somebody who works a counter, especially the trade words.

```bash
flutter gen-l10n    # after editing any .arb
```

## Multi-tenant

The app is sold to many mobile shops. Everything a shop records lives under
`shops/{shopId}`, and one shop can see nothing of another's.

```
shops/{shopId}                     the shop
shops/{shopId}/members/{uid}       who works there, and their role
shops/{shopId}/invites/{email}     staff invited but not signed up yet
shops/{shopId}/second_hand_mobiles …and every other area, the same
shops/{shopId}/counters/{name}     label and invoice numbers, PER SHOP
shops/{shopId}/settings/options    that shop's own vocabulary
users/{uid}                        which shop a signed-in person is in
invites/{email}                    the pointer an invited person can find
```

Two things enforce the boundary, and they are not the same thing:

- **`lib/data/firestore_paths.dart`** — repositories are handed a `ShopScope`
  and there is no method on it that returns a top-level collection of shop
  data, so a cross-shop read cannot be typed by accident.
- **`firestore.rules`** — what makes it actually impossible. A modified
  client, a stolen API key or a plain bug all stop there.

`test/rules/` proves the second with the Firestore emulator, and should be run
after any rules change. It has already earned its keep — see its README.

Counters are per shop on purpose: two shops both starting at label 26001 is
correct, while one shared counter would put the same sticker number on two
phones in two different towns.

## Firebase

Connected to a **dev** project, `fm-shop-dev-71842`, created for this work.
`lib/firebase_options.dart` is generated by `flutterfire configure`.

**Every area is on Firestore.** Customers, second-hand stock, service orders,
sales, products, enquiries, the label registry and the shop's own settings all read and write under `shops/{shopId}`, through one
`Firestore…Store` per area in `lib/data/`. The screens cannot tell the
difference — that is what the repository boundary is for.

The in-memory stores are still there, and still seeded, but nothing in the app
builds a seeded one: they are what the tests drive, and what the app falls back
to — **empty** — when there is no shop yet or Firebase could not be reached at
startup. A till showing four invented handsets is worse than one showing none,
because somebody would try to sell one.

| | |
|---|---|
| Numbers | `FirestoreCounter` — one transaction per number, `counters/{key}` |
| Appends | `FieldValue.arrayUnion`, so two staff adding a brand both succeed |
| Ticks, reprints | `arrayUnion` / `increment`, never a whole-field write |
| Rules about the record | a transaction: sold wins, never below zero, the checklist gate |
| Sub-ledgers | `customers/{id}/wallet_moves`, `products/{id}/stock_movements` |
| Failures | `firestore_errors.dart` — said in the shop's words, in one place |

**This is not the shop's live project.** `fren-75087` is: the owner's
second-hand stock, which `../mobile_app` reads to fill the public shop window.
Pointing this app there is a one-line change in `firebase_options.dart`.

Auth is real: Firebase Auth, with email and password, in
`lib/app/auth_state.dart`. Signing in resolves which shop the person is in
before the router decides anything, and an invite waiting under that shop is
claimed on their first sign-in — the only moment a uid and the invited email
both exist. `AuthState` keeps a local mode for the tests and for a device that
cannot reach Firebase, so every role rule can still be walked offline.

`firestore.rules` requires a signed-in member of the shop for everything under
it, with the membership check being `exists()` on the member document rather
than a field on the user's own profile. See the file's own notes, and
`test/rules/`.

## Layout

```
lib/
  app/        auth state, nav model, route table
  domain/     the rules, ported one-to-one and tested — no Flutter imports
  data/       repositories: what the screens talk to instead of Firestore
  ui/
    shell/    drawer + bottom bar frame
    screens/  one per route
docs/FLOW.md  what the app does, and why each rule is the way it is
```

Screens talk to a repository in `data/`, never to Firestore. Each area has two
implementations behind one interface — `Firestore…Store`, which the app builds
for the signed-in shop, and `InMemory…Store`, which the tests drive, seeded
with the record shapes that have caused trouble before: one handset on the
bench, one sold, one carrying a status this build has never seen. Which one is
in place is decided once, in `main.dart`, and no screen knows.

### Built so far

| Area | State |
|---|---|
| Login, nav, route table and the role gate | done |
| Customers (`/customers`) | list, form, detail with wallet and history |
| Second-Hand (`/inventory/second-hand`) | list, purchase form, detail |
| Service (`/service`) | list with nine tabs, intake, detail with the checklist gate |
| Sales (`/sales`, `/due-payments`) | list, bill form, detail, Due Payments |
| Products (`/products`) | list, form, detail with stock movements and labels |
| Scanner (`/scanner`) | three modes, manual entry, scan-to-intake with TAC prefill |
| Labels (`/admin/labels`, `/scan/:n`) | registry, reprint, public scan summary |
| Settings (`/admin/settings`) | the shop's vocabulary, models per brand, checklist, print server, language |
| Enquiries (`/enquiries`) | list, form, detail with the Won-needs-an-outcome rule |
| Dashboard (`/dashboard`) | alerts, today's takings, quick actions, nine tiles, recent orders |
| Reports (`/reports`) | four figures and the activity behind them, over a period |
| Staff (`/admin/staff`) | members, roles, invites — over the shop repository |

There are no placeholder screens left. `/setup` redirects to `/login`: signing
up **is** first-run setup here — the first person to sign up creates the shop
and becomes its owner.

Tasks, Ratings and Import Contacts were built and then **taken out again** on
2026-10-26: the shop does not want them. Their screens, domain modules, stores,
rules and tests are gone rather than hidden, so nothing half-wired is left
behind. `docs/FLOW.md` still describes them as part of the React app's flow,
which is what that document is for.

The rules each area turns on, and where they live:

| Rule | Where |
|---|---|
| Three stock states; sold always wins | `domain/inventory/stock_state.dart` |
| Grade falls out of the condition checklist; an empty one has no grade | `domain/inventory/condition_grade.dart` |
| Repairs are costed on the purchase, so the margin is honest | `domain/inventory/purchase_costing.dart` |
| 14–16 digits is an IMEI, never a shop label | `domain/inventory/imei.dart` |
| A wallet move below zero is refused, not clamped | `domain/customers/wallet.dart` |
| Closed beats overdue | `domain/service/order_state.dart` |
| `Completed` is reached through the checklist, never a dropdown | `domain/service/order_validation.dart` |
| Checklist keys are derived once, collisions resolved | `domain/service/checklist.dart` |
| A financed sale leaves the customer owing nothing | `domain/sales/payment_methods.dart` |
| Stock moves only when a sale is completed | `data/sales_repository.dart` |
| Numbers come off an atomic counter, never a document count | `domain/common/counters.dart` |
| One registry mints every label; minting and attaching are one step | `data/label_repository.dart` |
| A label carries a copy of its record; the live record is laid over it | `domain/labels/label_entry.dart` |
| Length alone tells an IMEI from a shop label, so label mode can say so | `domain/labels/scan_resolution.dart` |
| A TAC prefills an intake and never decides it | `domain/devices/tac_registry.dart` |
| A stock count never goes below zero, and is never written by a form | `domain/products/stock_movement.dart` |
| Low stock is a threshold per product; no threshold means no alert | `domain/products/stock_level.dart` |
| A value typed into a form joins the list; deciding is separate from writing | `domain/settings/option_learning.dart` |
| Case and space make no new value; the first spelling keeps the casing | `domain/settings/option_set.dart` |
| Union-append, so two staff adding a brand at once both succeed | `data/settings_repository.dart` |
| A Won enquiry needs something to point at | `domain/enquiries/enquiry_state.dart` |
| A count that failed says so; it is never a zero | `domain/dashboard/board.dart` |
| Takings, service revenue and handset margin are never summed | `domain/reports/shop_report.dart` |

`domain/` is the flow. It holds no widgets and no Firestore, so every rule is
stated in a test rather than discovered in the shop.

## Checks

```bash
flutter analyze   # 0 issues
flutter test      # 931 pass
flutter build apk --debug
flutter build linux --debug
```

`graphify update .` rebuilds a reference graph of the whole project under
`graphify-out/` (gitignored), which is a quick way to check nothing new is
orphaned:

```bash
graphify explain "lib/data/sales_repository.dart"
```
