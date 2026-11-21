---
name: ui-pages
description: What each fm_shop page shows on the phone (seen 2026-11-21, admin, empty "Test Shop") and the UI problems found
metadata:
  type: project
---

Seen on the CPH2219 on 2026-11-21 as admin (asencid07…) in shop "Test Shop",
which had one customer and nothing else, so lists showed empty states.

**Look today:** Material 3, `ColorScheme.fromSeed` in `lib/ui/theme/app_theme.dart`
(293 lines). Dusty rose app bars and summary cards, dark green primary buttons/FABs,
pale pink background. Floating pill bottom bar.

## Pages
- **Login** — "Management System / Sign in to your shop": email, password,
  Sign in, Set up a new shop, Forgotten password.
- **Home** (`/dashboard`) — "Good evening / <shop>", avatar; rose "Today ₹0
  (completed bills only)" card; big green "New sale" (goes to Sales list, not a
  form); 3 tiles New service order / New purchase / Scan; count rows Overdue
  service orders, Pending orders, Overdue… (list continues below).
- **Mobiles** (`/inventory/second-hand`, title "Second-Hand") — search (brand,
  model, IMEI, label) + help "?"; rose "0 on hand · Selling for ₹0 · Paid ₹0";
  status chips In stock / Repairing / Sold… with "?"; FAB "Take in".
- **Scan** — raised centre tab, opens camera scanner.
- **Service** (`/service`) — search order/customer/device; chips Open / Due
  Today / Overdue / …; FAB "Take in".
- **More** — avatar + "admin", list: Customers, Products, Sales, Due Payments,
  Enquiries, Labels, Settings, Reports, Staff (+ Tasks, Import contacts below).
- **Customers** — search name/number, avatar-letter rows (name + number), FAB Add.
- **Products** — search; chips All / To order / Out of stock; totals line
  (products · units · cost · retail); FAB Add.
- **Sales** — search invoice/customer/item/IMEI; chips Completed / Drafts /
  Cancelled; FAB New sale.
- **Due Payments** — empty state explains financed sales aren't counted.
- **Enquiries** — search; chips Open / Due today / Overdue; "0 open · nothing
  closed yet"; FAB Record.
- **Labels** — "Next label: 26001" + explanation; search; empty state.
- **Settings** — Your shop (name, phone, address, GSTIN, Save) then "These lists
  grow by themselves" option lists… (long page).
- **Reports** — range chips Today / 7 / 30 days / This month / Custom; cards
  Takings, Service revenue, Second-hand margin, Outstanding — each with an
  explanation line.
- **Staff** — "1 working here" member card (email shown twice, wraps badly);
  Invited + Invite button.

## UI problems found
1. ~~Android Back exits the app from every page~~ — **FIXED 2026-11-21**
   (commit 025ed0a): `backTarget()` in `lib/app/nav.dart` sends Back one level
   up (record→list, More area→More, tab→Home, Home exits), applied by a
   PopScope in `AppShell`. Verified on the phone.
2. Home "New sale" opens the Sales list instead of a new-sale form.
3. Filter chip rows overflow off-screen with no hint (Mobiles, Service, Sales,
   Enquiries).
4. Staff card repeats the email and breaks it mid-word ("…gmail.co / m").
5. Long explanatory paragraphs on Labels / Settings / Reports / Due Payments —
   correct but heavy; could be collapsible help.
6. Empty states are inconsistent (icon+title+hint on Mobiles/Due vs plain text
   elsewhere).
7. Settings is one very long scroll — needs sections/tabs.

**How to apply:** use this as the before-state for the UI work; re-shoot a page
after changing it. Screens are tapped via adb at 1080×2400 (bottom bar y=2121;
tabs x=142/358/539/718/933). Back (`input keyevent 4`) is safe since the fix.
Run with `flutter run --pid-file …` so `kill -USR1 $(cat pidfile)` hot-reloads.
