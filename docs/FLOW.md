# fm_shop — flow specification

A Flutter port of the **French-Mobiles-2026** React PWA
(`github.com/Pugazhendii22/French-Mobiles-2026`): the shop's own management
system — service jobs, second-hand stock, sales, customers.

Only the **flow** is carried over. Theme, colours and layout are ours to decide;
nothing in this document prescribes a visual style.

Not to be confused with `../mobile_app` (`french_mobiles`), which is the
customer-facing trade-in app — a different product.

---

## 1. Roles and the gate

Two roles, read from `users/{uid}.role` after Firebase Auth sign-in: **admin**
and **staff**. Everything except login, the public rating page and the public
scan page sits behind the gate; an unauthenticated open redirects to login.

| Route | Who |
|---|---|
| `/setup` | first-run admin creation |
| `/login` | public |
| `/rate/:token` | public — customer rates a finished job |
| `/scan/:labelNumber` | public — a scanned label resolves to a summary |
| everything else | signed in |
| `/admin/*`, `/reports` | admin only |
| `/tasks` | staff only |

## 2. Navigation

A drawer (full nav) plus a bottom bar of five: **Home · Mobiles · Scan · Service
· Sales**, with Scan raised in the middle.

Drawer order: Dashboard, Customers, Second-Hand, Products, Service, Sales, Due
Payments, Enquiries, Scanner, Labels, then admin-only Settings, Reports, Task
Management, Ratings, Import Contacts, Staff, and staff-only Tasks.

Every area follows the same four page types: **dashboard → list → form → detail**.
Lists carry a FAB that opens the form as a sheet; forms and details get a sticky
bottom action bar on mobile.

## 3. Dashboard

Greeting, then alert rows (overdue service orders, open tasks), today's sales
total, four quick actions (new service order, new purchase, new sale, scan), a
stat grid and the recent-orders list.

Tiles: Pending Orders, Overdue, Due Today, Low Stock, Due Payments (admin),
Pending Bills (admin), Open Enquiries, Customers, New Today. Each tile is
tappable and lands on the list it counts.

Counts come from aggregate queries, run with `allSettled` semantics — one failed
count must not blank the whole board, and a failure says so rather than showing
a zero.

## 4. Service orders — the core loop

**Intake** (`ServiceOrderForm`), four sections:

1. **Device** — brand, model, IMEI (taken off the phone, not the box), lock type
   (None / PIN / Password / Pattern / Fingerprint / Face Unlock / Other; a
   pattern is drawn on a 3×3 lock widget), accessories left with the device.
2. **Issues & Complaints** — one or more complaint types from the shop's shared
   repair vocabulary. The job card and the final bill are both built from these.
3. **Estimate & Costs** — estimated price, raw material, outside labour; profit
   is shown live.
4. **Schedule & Technician** — `receivedAt` and `expectedCompletionAt`, plus who
   is on it.

Both dates are mandatory and validated in **one** place, so "Save" and
"Save & Print" cannot disagree about what a valid order is.

**Status** — `Received → In Progress → Parts Awaiting → Awaiting Customer
Approval → Completed → Returned`, but the allowed transitions are written down,
not derived from list position:

- **Ready** (for pickup) was added on 2026-11-22, between Awaiting
  Customer Approval and Completed: the work is done and the phone waits for
  its owner. It is open but never overdue or due — see `isReady`.
- `Completed` is never selectable from a dropdown. An order is finished only by
  passing the **pre-delivery checklist**.
- `Received` cannot be returned to by staff (admins may).
- An order carrying an unknown status still shows it.

**Derived state** drives the list, not the raw status — `overdue` (promised and
the time has passed), `open` (in the shop, time left), `closed` (handed back).
Closed beats overdue: a job finished last month is not an alarm.

List tabs: Open, Due Today, Overdue, In Progress, Parts Awaiting, Awaiting
Customer Approval, Completed, Returned, All.

**Pre-delivery checklist** — labels come from settings, ticks are stored as a map
on the order. Keys are derived once for the whole list with collisions resolved,
so "Display OK" and "Display: OK!" can never share a checkbox. An empty
checklist passes.

**Documents** — job card at intake, final bill at delivery. Printing saves first.

## 5. Second-hand stock

**Purchase form** — five steps, one screen each, in the order the shop's
counter app (the French Mobiles POS) asks them: **Seller** (search the shop's
customers, or add one with ID type and number; alternate phone) → **Phone**
(brand, model, RAM, ROM, IMEI 1, IMEI 2, serial — required for an iPhone) →
**Condition** (checklist, grade A–D, grade details, notes) → **Price** (paid,
selling price, purchase date defaulting to today, supplier) → **Photos** (six
named slots, front required; ID card front and back). Optional extras — colour,
other costs, repairs, the bench switch, ID proof reference, signature — are
folded under "Add more details" on their step. Save, or Save & print label.

**Condition checklist** — the POS one: common checks for every phone, then
iPhone-only or Android-only checks, grouped by category. Every line **starts
as passed** ("Working", or "No" for a fault question); staff tap only the
faults. Grade: physical damage or an iCloud lock → D; four or more not working,
a replaced display or white spots → C; one to three not working → B; else A.
A grade picked by hand is recorded as an override.

Repairs costed on the purchase feed into profit, so the margin stays honest.

**Three states**, not two: `available` (sellable), `repairing` (bought damaged,
on the bench — not yet sellable, kept out of the sale picker), `sold`. Sold
always wins; editing a sold record cannot put it back on the shelf.

A device under repair must **not** be modelled as a service order: a service
order assumes a customer owns it and owes money, which lands it in Due Payments
as a debt and in Reports as revenue nobody paid.

The seller's declaration prints from the purchase's detail page.

## 6. Sales

Sections: **Customer** (autocomplete over everyone served before, so nobody is
added twice) → **Items** (scan a label or add a line by hand) → **Payment** →
**Bill Summary**.

- Stock comes down, and a second-hand handset is marked sold, **only when the
  sale is completed** — not while the bill is being built.
- Only sellable stock reaches the picker; the rest is still loaded so a scan of
  a repairing or sold device can explain itself.
- Payment methods: Cash, UPI, Card, Split, plus finance providers (Bajaj, IDFC,
  Samsung Finance, Poonawalla, TVS Credit).
- A **financed** sale is recorded as fully paid: the customer owes nothing, the
  financier's settlement is a different ledger. It must never show in Due
  Payments.
- Paying less than the total leaves a balance; only an admin may collect it
  later from the sale page.

Invoice prints from the sale.

## 7. Customers

List, form and a detail page carrying history across all areas, plus a wallet.
Wallet moves run in a transaction and stamp `updatedAt`, which is how other
tills learn the customer changed. A move that would take the balance below zero
is refused.

Contacts can be bulk-imported from vCards (admin).

## 8. Labels and scanning

One `label_registry` collection. A label number is minted from an **atomic
counter** in a transaction — deriving it by counting documents gave two staff
the same number, and the scanner then opened the wrong record. Same for invoice
and service-order numbers (`INV-YYYYMMDD-NNN`). Labels start at 26001.

A label entry carries a **copy** of the record it was printed for, so a scan
resolves in one read; the live record is laid over that copy on display, so a
price corrected since printing shows correctly.

**Scanner page** modes: scan a shop label, or start an intake (new service
order / new second-hand purchase) from a device barcode.

- 14–16 digits is a factory **IMEI**, never a shop label — length alone tells
  them apart, and scanning an IMEI in label mode says so instead of failing.
- A scanned label opens the **record itself** (`/products/:id`,
  `/inventory/second-hand/:id`, `/service/:id`, `/sales/:id`), not a read-only
  summary, so staff land somewhere they can act.
- An IMEI's TAC prefix is looked up in a read-only device database to prefill
  brand and model on intake.

Printing goes to a label print server on the shop PC over HTTP.

## 9. Settings, options and drafts

The shop's own vocabulary — brands, models per brand, suppliers, colours,
categories, complaint types — lives in `settings/*`. **A value typed into a form
that is not on the list joins it**, so the next person finds it in the dropdown.
Deciding what is new is kept separate from writing it. Writes use union-append,
never a whole-document write, so two staff adding a brand in the same minute
both succeed. Filing a brand name must never fail the sale that was just made.

Forms keep a **draft per form instance** — a half-typed new intake and an edit of
an existing order do not share one. Pulling a sheet down keeps the draft
(it may be a slip); the X discards it.

## 10. Other areas

- **Enquiries** — list / form / detail for walk-in questions.
- **Products** — new-goods inventory with photos, pricing, stock and low-stock
  alerts.
- **Due Payments** — outstanding customer balances; admin collects.
- **Tasks** — admin assigns, staff see their own, with a daily reset rule.
- **Ratings** — a public token link per finished job; admin reads the results.
- **Reports** — admin revenue and activity.

## 11. Data

Firestore collections: `customers`, `second_hand_mobiles`, `products`,
`service_orders`, `sales`, `enquiries`, `tasks`, `ratings`, `users`,
`label_registry`, `settings`, `counters`, plus a read-only `tac_registry` for
device lookup.

Dates arrive as a Firestore `Timestamp` on some documents and an ISO string on
others, depending on which build wrote them — **every read normalizes**.

Images upload to Cloudinary. A collection cache keeps lists warm between opens
and refreshes on `updatedAt`.

---

## Porting notes

| React | Flutter |
|---|---|
| react-router routes | `go_router` route table, same paths |
| AuthContext / SettingsContext | `provider` |
| html5-qrcode / zxing | `mobile_scanner` |
| jspdf + html2canvas | `pdf` + `printing` |
| jsbarcode | `barcode_widget` |
| browser-image-compression | `flutter_image_compress` |
| localStorage drafts | `shared_preferences` |
| QZ Tray | HTTP post to the shop print server |

The pure logic modules — order state, stock state, checklist keys, option
writes, counters, phone normalization, search matching — port to Dart one-to-one
and keep their tests. They are the flow; the widgets are not.

---

## What is built, and where each rule lives

Screens talk to a repository in `lib/data/`, never to Firestore. Each area has
a Firestore store, which the app uses, and an in-memory one the tests drive —
seeded with the record shapes that have caused trouble: a handset on the bench,
one sold, one carrying a status this build has never seen, a customer with no
name, an order with an unrecognised status.

Everything this document describes is built. **Ratings** was added on
2026-11-21 (see the table below); Import Contacts is built too.

Ratings needs one thing outside the code before a customer can open a link:
the app has to be served on the web (`flutterfire configure` for web, `flutter
create --platforms=web .`, then Firebase Hosting), and that address goes into
Settings → Customer links. Until then "Ask for a rating" says so and sends
nothing.

Earlier history: Ratings and Import Contacts and Tasks were written and then removed on 2026-10-26
because the one shop did not want them. **Tasks came back on 2026-11-11**: the
app is sold to many shops, so what one shop does not use is no longer a reason
to leave an area out. The sections below still describe the other two, because
this document is the flow of the React app being ported, not a list of what is
in the Flutter build.

A rule stated in this document is in exactly one module, and that module has a
test naming the rule:

| Section here | Rule | Module |
|---|---|---|
| §5 | Three stock states; sold always wins | `domain/inventory/stock_state.dart` |
| §5 | Checks start as passed; the grade follows the POS rules (damage/iCloud → D, 4+ faults or display replaced/spots → C, 1–3 → B) | `domain/inventory/condition_grade.dart` |
| §5 | Repairs costed on the purchase feed profit; an unsold device has no realised profit | `domain/inventory/purchase_costing.dart` |
| §5 | Seller, brand, model, RAM, ROM, IMEI, paid, selling price, date and front photo required; serial for an iPhone; one validator for Next and Save | `domain/inventory/purchase_validation.dart` |
| §8 | 14–16 digits is an IMEI, never a shop label | `domain/inventory/imei.dart` |
| §7 | A wallet move below zero is refused, not clamped; every move stamps `updatedAt` | `domain/customers/wallet.dart` |
| §7, §6 | The number is the identity, so nobody is added twice | `domain/customers/customer.dart` |
| §4 | Closed beats overdue; allowed transitions are written down | `domain/service/order_state.dart` |
| §4 | `Completed` only through the pre-delivery checklist | `domain/service/order_validation.dart` |
| §4 | Checklist keys derived once, collisions resolved | `domain/service/checklist.dart` |
| §6 | A financed sale leaves the customer owing nothing | `domain/sales/payment_methods.dart` |
| §6 | Stock comes down only when the sale is completed | `data/sales_repository.dart` |
| §6, §10 | Financed sales never reach Due Payments; only an admin collects | `domain/sales/due_payments.dart` |
| §8 | Numbers come off an atomic counter, never a document count | `domain/common/counters.dart` |
| §8 | One `label_registry` mints every number, and minting and attaching are one step | `data/label_repository.dart` |
| §8 | A label carries a copy of its record; the live record is laid over it on display | `domain/labels/label_entry.dart` |
| §8 | 14–16 digits is an IMEI, so label mode answers instead of failing | `domain/labels/scan_resolution.dart` |
| §8 | A scanned label opens the record itself, not a summary | `domain/labels/label_target.dart` |
| §8 | A TAC prefills an intake and never decides it | `domain/devices/tac_registry.dart` |
| §8 | Printing goes to the shop PC over HTTP, and a failed print undoes nothing | `data/print_server.dart` |
| §10 | A stock count never goes below zero, and never comes from a form | `domain/products/stock_movement.dart` |
| §10 | Low stock is a threshold per product; no threshold means no alert | `domain/products/stock_level.dart` |
| §9 | A value typed into a form joins the list, and deciding is separate from writing | `domain/settings/option_learning.dart` |
| §9 | Case and space make no new value; the first spelling keeps the list's casing | `domain/settings/option_set.dart` |
| §9 | Union-append, so two staff adding a brand in the same minute both succeed | `data/settings_repository.dart` |
| §9 | A draft per form instance; the sheet keeps it, the X discards it | `domain/common/form_draft.dart` |
| §10 | A Won enquiry needs a sale, a repair or a note to point at | `domain/enquiries/enquiry_state.dart` |
| §10 | A task stores the days it was done on, nothing resets it, and only a one-time task is overdue; staff see and tick only their own | `domain/tasks/task.dart` |
| §10 | Only a finished job is asked; one link per job; the token is 128 random bits; the first answer stands; 1–5 stars, comment ≤ 500; the public copy has no phone, price or IMEI; the average counts answers only | `domain/ratings/rating.dart` (and `firestore.rules`, tested in `test/rules/`) |
| §11 | Every read normalizes dates and amounts | `domain/common/dates.dart`, each model's `fromMap` |

### Two things this port decided that the document did not

**One door back from sold.** `statusForSave` deliberately leaves a sold device
sold, so no edit, form or scan can quietly un-sell a record. But a cancelled
bill is real — a customer changes their mind and the phone is still in the
cabinet — and without a way back the only option was re-entering it as a new
purchase, which double-counted both the stock and the margin. So there is
exactly one named method, `SecondHandRepository.returnToStock`, called only
when a completed bill is cancelled.

**A cancelled bill is kept, not deleted.** A bill given to a customer and then
cancelled is part of the day's record. Deleting it is how a till comes up short
with nothing to explain it.

**Only the registry mints a label number.** The second-hand store had a counter
of its own, and every area that prints labels would have grown one — four
counters over a single number space, and label 26042 ending up on two different
phones. `LabelRepository.assign` is now the only thing that takes a number, and
it attaches it in the same step; each area plugs in through a
`LabelTargetBinding`, so the registry imports none of them and a record's own
repository has no way to invent a number. A record that already has a label
keeps it, and a reprint keeps the number — a second number for one record is a
second sticker resolving somewhere the first one did not.

**The public scan page is a summary; the in-app scanner is not.** `/scan/:n` is
reachable without signing in, which is the point of printing a QR code on a
sticker, so it shows only what is already on the thing in the customer's hand —
no cost price, no seller, no margin. The in-app scanner opens the record
itself, because staff scanning a label are holding the phone and have something
to do about it.

**The daily reset was a derivation, not a job.** §10 asks for tasks with "a
daily reset rule", and the obvious implementation — a boolean `done` plus
something that clears it overnight — is the wrong one, because in a shop that
something does not run. The app is closed, the counter PC is off, the phone is
in a drawer; the shop opens on Monday with Saturday's ticks still showing, and
staff either trust the list and skip the checks or stop trusting the list.

So a task stores the **days** it was completed on, and "is it done" is a
question about a particular day. Nothing runs at midnight, and nothing can be
stale, because there is nothing to be stale. It also makes the history free:
"was the cabinet checked on Saturday" is the same question asked about a
different day, where a reset that overwrote a flag would have thrown it away.

Two consequences follow. A **daily task is never overdue** — it is due today,
every day, and calling yesterday's unticked check overdue leaves a permanent
red mark nobody can clear, which is how staff learn to ignore red. And a tick
is an **append** of a day key, so two tills ticking the same morning agree.

**Staff see and tick only their own.** Not the unassigned ones: a list an admin
wrote before deciding who does what has not asked anybody to do anything, and
showing those to everyone means five people each assuming somebody else had it.
The task is still allowed to be unassigned — writing the list first is real —
and the admin page gives it its own tab and says on the row that nobody will
see it. The visibility rule is one function used by both pages, and the
repository applies it to the write as well, because a rule enforced only by
which buttons a screen draws is a rule a deep link walks straight past.

**A Won enquiry needs something to point at.** An enquiry marked won with
nothing behind it is how a conversion rate gets inflated, so closing one as Won
asks which sale or repair it became. Anything non-empty counts, including a
note saying "sold over the counter, no bill" — refusing that would just stop
the enquiry being closed at all. Conversion is then counted over the **closed**
enquiries only: a rate that drops because somebody wrote a new enquiry down is
a rate that discourages writing them down.

**The lists grow by themselves, and nobody waits for them.** The three rules in
§9 pull in one direction: a value typed into a form joins the list, deciding
what is new is kept separate from writing it, and filing a brand name must
never fail the sale that was just made. The separation is what makes the last
one possible — `pendingAdditions` is pure and returns a plain value, so the
save completes, the sheet closes, and the filing happens afterwards in a call
nothing awaits and nothing rolls back. A failed filing is a dropdown that is
briefly out of date.

The dedupe rule is the other half. `samsung`, `Samsung` and ` Samsung ` are one
brand, or a list that learns by itself fills with the same word five ways
within a month. And the **first** spelling to arrive keeps the list's casing,
not the newest: records already written carry the first spelling, and rewriting
the entry would make the dropdown disagree with the records. It is the same
rule as the checklist keys.

Two consequences worth stating. Removing a value from a list does **not** touch
the records using it — a brand taken off the list is still the brand on two
hundred handsets. And loading a stored settings document never merges the
defaults back in: a shop that removed a complaint type meant to, and quietly
restoring it would make the setting impossible to change.

The pre-delivery checklist is the one list here whose **order** is the value,
because it is the order somebody works through a phone. So it is the one thing
written whole rather than appended to — an append cannot express a reorder, and
it is one admin on the settings page with nobody waiting. It is also now live:
adding a check while a phone is on the bench blocks an order that was ready a
moment ago, and emptying the list turns the completion gate off entirely. The
settings page says so in as many words.

**A product has a count, not a status.** That is the whole difference from a
second-hand record, and it changes the shape of everything around it: there is
no `available`/`sold` on a product, and the question the list answers is "how
many are left" rather than "can I sell this". So a product carries its own
reorder level, and `stock_level.dart` turns the count and that level into the
only three answers anyone needs — in stock, low, out of stock. A product with
no reorder level set has no low-stock alert at all and says so, because an
alert nobody chose is an alert nobody trusts.

**A stock count is never written by a form.** It changes only through a
movement with a reason, which is the same shape as the customer wallet and for
the same reason: two tills selling the last screen guard both read "two in
stock" and both wrote "one". A movement is also the only answer to "the system
says three and I have counted five" — a count with no history has nothing to
say to it. A stock-take therefore records the *difference* as an adjustment
rather than overwriting the count, so the fact that it was ever wrong survives.
Taking more off than is there is refused, not clamped to zero: a count is what
the shop believes it has, and a negative count is a belief that is certainly
wrong.

**Product lines on a bill move stock the same way handsets do, and at the same
moment.** `LineSource.product` reported `movesStock` from the day sales were
built, but `completeSale` had nothing to call — products did not exist yet, and
the lines were silently skipped. They are now checked before anything is
written and decremented on completion. A shortfall names the number: "only 2
left, 3 on the bill" tells the person serving what to change, where "not
available" does not. One bad line refuses the whole bill, so half a bill is
never written with nobody knowing which half.

**A scan reaches an intake form as query parameters.** `/service?imei=…&brand=…`
rather than in-memory state, so a counter PC can bookmark it and a link can be
sent on. `IntakePrefill` both writes and reads that query, so the two cannot
drift, and it drops anything implausible — a shop label in the `imei` parameter
would otherwise fail validation in the IMEI field and read as a broken form.
