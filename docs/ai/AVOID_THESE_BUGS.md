# Bugs to avoid — rules for any AI building an app or website

> **To the AI reading this:** follow every rule below while you build, not after.
> Each one comes from a real bug found by testing a finished app. Before you say a
> feature is done, go through the **Done checklist** at the end and fix anything
> that fails. When a rule does not apply to this project, skip it — do not invent
> features to satisfy it.
>
> **Keep this file growing.** If you find a new bug that is common, logical
> (a rule any app should follow) or keeps repeating, add it here: put the rule
> in the right section, add a line to the "Real examples" table, and update
> this file in https://github.com/cid0980/ai-avoid-bugs. Write the rule so it
> fits any app, not only the one you are building. Don't add one-off bugs that
> belong to a single app.

---

## 0. How to work

1. **One rule, one place.** Every rule about a kind of input (money, quantity,
   date, phone, ID) lives in ONE shared function or component, and every screen
   uses it. Never re-write a check per screen — that is how one screen ends up
   accepting what another refuses.
2. **Check at the edge and at the core.** The input box blocks what can never be
   right (typing rule); the save/store function refuses it again (business
   rule). A value can arrive without being typed: pasted, scanned, restored from
   a draft, carried over from another screen, imported, or sent by an old app
   version.
3. **Fix by rule, not by screen.** When you find a bug in one field, search the
   whole codebase for every field of that kind and fix them all.
4. **Every bug found becomes a test** that would have caught it.

---

## 1. Money

- **Never use floating point for money.** Store whole paise/cents (integers) or
  round every result to 2 decimals. `10.10 + 20.20` must equal `30.30`, not
  `30.299999999999997`, and the whole balance must be spendable.
- **Money boxes accept:** digits and one decimal point, at most 2 decimals, a
  sensible maximum (e.g. 8 digits). **No minus sign, no letters, no 20-digit
  numbers** (a stray barcode scan into a price box is a real thing).
- **Empty ≠ zero.** Decide what an empty money box means and say it under the
  box ("Leave empty if paid in full", "Type 0 for a free repair"). Never silently
  save an empty or unparseable box as 0.
- **Format every amount the same way everywhere** through one formatter (e.g.
  ₹2,000 — never ₹2000 next to ₹2,000, never ₹400.5, never `₹-50`; negatives are
  `-₹50`).
- **More paid than owed is change, not income.** Record only the amount due;
  show "Change to give back". Same for an advance/deposit larger than the final
  charge.
- **Every way money comes in must land in the right bucket.** If there is a
  "split" payment, ask the amount per method. A deposit/down payment is real
  money in the drawer. Credit/finance amounts are not cash.
- **Store payments as dated entries (a ledger), never as one editable number.**
  Editing a ₹120 deposit to ₹20 is a −₹100 refund on today's date, not ₹100
  vanishing. Reports read the ledger by date.
- **Stored balances must agree with their history.** If you keep a running
  balance (wallet, stock count), also keep the moves, and check they add up.
- **Every total shown in two places must be computed by the same function**
  (the record, the printed bill/PDF, the report, the dashboard tile, the export).
  If they can disagree, they will.
- **A printed bill/invoice must add up line by line** (charge − deposit = balance,
  or "change given back").

## 2. Quantities and counts

- Whole numbers only where things are counted; refuse 0, negatives and decimals
  with a message — never silently turn `0`, `-3` or `1.5` into `1`.
- **Never silently cap.** Asking for 9 when 5 are available must say "Only 5
  left", not quietly add 5.
- **Check the whole cart, not each line.** Two lines of 5 against a shelf of 5 is
  10. "Left" = in stock − already in this cart/bill.
- **A unique item (one serial/IMEI) can't be added twice** to the same order —
  don't offer it again, and refuse it at save.
- **Undo exactly what was done.** Cancelling must return exactly what the sale
  took — never more.

## 3. Dates and times

- Decide for every date: may it be in the past? in the future? before the
  record's own start date? Enforce it in the date picker AND at save.
- "Came in", "paid on", "created" dates: **not in the future**.
- Follow-up/reminder dates: **not in the past**, and not on a closed/settled record.
- Money is reported on the day it actually moved, not on a date field the user
  can edit later.
- Show and compare dates in the user's local time.

## 4. Identifiers (phone, email, IMEI/serial, codes)

- Digits-only fields must refuse letters **with a message** — never strip them
  silently (`35A12B34` must not become `3512 34`, a number nobody typed).
- Validate length and check digits where they exist (IMEI Luhn, GSTIN, card).
- **Fixed-length boxes (phone, IMEI, PIN/ZIP code, OTP, card): stop at the
  length and show a counter** (`7/10`). An 11th digit in a 10-digit phone box
  must not go in at all; a missing digit must be visible before Save. A pasted
  `+91 98765 43210` or `098765-43210` is cleaned to the 10 digits, not refused
  and not counted as 13. This is a bug when missing, not a "nice to have".
- **The right keyboard for every box.** Number-only box → number pad; money →
  number pad **with a decimal point** (plain "number" has no point key on many
  Android keyboards, so ₹499.50 can't be typed); phone → dial pad; email →
  email keyboard with @. Decide it from the same shared rule as the box's
  typing filter, so the two can never disagree. On the web: `inputmode`
  (`numeric`, `decimal`, `tel`, `email`) and `type`.
- Email: something@something.tld — `a@b` is not valid.
- **Uniqueness:** a phone number (including a customer's *second* number), an
  email, an IMEI/serial already in the system must be caught on EVERY path that
  creates that record — the main "Add" form and every shortcut "Add new" inside
  other forms.
- **Show human numbers, never internal IDs** (`INV-2026-004`, not
  `s-1795442606251`) in lists, history lines and messages.

## 5. Forms

- **Required fields:** mark them with *, and when Save is pressed with one
  missing, **scroll to it, focus it and show the message under it.** Never fail
  silently or with a toast far from the field.
- The * must match the rule: if a field is only required in some cases, show the
  * only in those cases.
- **One message per problem, under the field it is about.** Never the same
  message twice; never a field error AND a contradicting hint at once.
- **A dialog or bottom sheet that rejects input must stay open with the typed
  text kept** and the error under the box. Closing it and losing the typing is a bug.
- **Validate in the sheet/form before closing it**, using the same rule the
  store uses.
- **Destructive or settling actions ask once** (delete, cancel, discard draft,
  mark lost/closed) and require a reason where the reason matters later
  (cancel a paid bill, return unrepaired). One tap must never throw away work.
- **When you know the answer, fill it in.** If the typed phone number matches a
  known customer, use their name and link the record even if the suggestion
  wasn't tapped.
- **Drafts:** say when an old draft is being resumed and offer "Start fresh". A
  draft must reopen exactly as it was left (empty stays empty; "paid in full"
  must not turn into a typed amount).
- Don't show stale or impossible actions (print a label for a sold item, set a
  reminder on a closed record, "collect" on a cancelled bill).

## 6. Flows and state changes

For every action, ask **"what is the reverse, and does it put everything back?"**

- **Cancel / refund:** ask how the money went back (method, or store credit),
  record it on its own date, give back any store credit/wallet that was used,
  return stock exactly. Never delete payments so history changes.
- **Reopen:** clear what belonged to the closed state (e.g. "won with order X").
- **Close without completing** (returned unrepaired, abandoned order): ask what
  happens to any deposit (refunded or kept as a fee).
- Status flows: decide which jumps are allowed (can it skip "In progress"?).
  Enforce in the store, not just by hiding buttons.
- Permissions: enforce on the server/store (database rules), not only in the UI.
- After any money/stock action, **check every place that shows it**: the record,
  the list row, the detail page, the PDF, the report, the dashboard, the export.

## 7. Lists, reports and dashboards

- Captions must say exactly what the number counts ("Completed bills, paid or
  still owed" — not "settled bills" if unpaid ones are included).
- Counts next to amounts must count the same things.
- If a summary shows only the top N, add an "N others" line — no money missing.
- Plurals: "1 item / 2 items", never "item(s)".
- A draft is not "paid"; a cancelled item is not "due".
- Don't print the same value twice in one row (title and subtitle both the
  invoice number; status pill and status text both "Open").

## 8. Text, languages and layout

- Every visible string goes through translation — including validation messages,
  hints, chips, built-in list values, and "N days". Data the user typed is shown
  as typed.
- Test every screen in the longest language you support and on a 360-px-wide
  phone: no overflow, no text cut to "Cond…", required * stays next to its label
  when the label wraps.
- Long values (a 20-character name, a maximum-size amount) must not break rows.
- Buttons never share a line with something that can grow (a balance, a name)
  unless it can wrap.
- **Sheets, pop-ups and full-screen pickers stay inside the safe area** — never
  under the status bar, clock, notch or the phone's own buttons. A picker is as
  tall as its list (scrolling when long), has a handle or close button, and a
  search box once the list can grow past a screen.
- **Anything you can tap must look tappable.** A list to pick from is not a
  list of plain text lines (that reads like rules or a description). Each
  pickable row gets a card/border, an icon, and a visible action ("+ Add",
  a chevron, a button). Rows that can't be picked are greyed, have no action,
  and say why.
- **Pickers are built for a real shop's size, not the 5 test records.** Assume
  hundreds of items: a search box, plus a one-row filter by the obvious group
  (brand for phones, category for products), most common first, with "All".
- **Onboarding, tours and "what's new" appear only after login**, once the app
  knows who is using it — never over the login page, and never marked "seen"
  before the person could actually see it. While the app is still checking the
  session, show a loading screen, not the home page.
- **Guided tours / coach marks break silently.** A step whose target isn't on
  screen shows only text, with no highlight. Write ONE automated test that
  runs every tour step on the real screens and fails when a target is missing,
  off screen or zero-size. Tours must: run on demo data that has every state
  they talk about (low stock, ratings, overdue…), open the tab/page the target
  lives on, scroll up as well as down to find it, and close **everything** they
  opened (sheets AND pushed pages) when they end.

## 9. Accessibility

- Every icon-only button has a label/tooltip.
- Tap targets ≥ 48 px. Don't rely on colour alone (red = error must also have text).

## 10. Data and storage

- New fields must have a safe default for records written before they existed
  ("missing" ≠ "empty").
- Never trust the client: re-check limits and rules on the server/store.
- Keep secrets (keystores, API keys) out of public repositories.

---

## Done checklist — run this before saying a feature is finished

For **every input** you added:
- [ ] Empty, 0, negative, decimal where whole is expected, letters, 20 digits,
      pasted text with symbols — each refused with a message or handled on purpose.
- [ ] Fixed-length box (phone, IMEI, PIN, OTP): stops at its length and shows
      a `n/10` counter.
- [ ] Opens the right keyboard: number pad, decimal pad for money, dial pad, email.
- [ ] Same rule on every screen that has this kind of field (search the code).
- [ ] Also enforced at save/store, not only in the box.

For **every action** you added:
- [ ] What undoes it? Does the undo put back money, stock, wallet and status exactly?
- [ ] Is a reason asked where one matters later? Is there a confirm for destructive steps?
- [ ] After it: do the record, list, detail, PDF, report, dashboard and export all agree?
- [ ] Does it work when done twice, or from two devices at once?

For **every screen** you added:
- [ ] Loading, empty and error states all show something (never a blank page).
- [ ] Longest language + 360-px phone: no overflow or truncation.
- [ ] Every icon button has a label.
- [ ] Every sheet/picker opens below the status bar and fits its content.
- [ ] Pickable rows look tappable (card, icon, Add/chevron); disabled rows say why.
- [ ] Every picker works with 500 items: search + group filter (brand/category).
- [ ] Nothing (tour, offer, prompt) pops up before login or during loading.
- [ ] Tour audit test passes: every step's highlight found, on screen, visible.

For **every bug** you fixed:
- [ ] A test that fails without the fix.
- [ ] Searched for the same pattern elsewhere and fixed it there too.

---

## Real examples (from one app's test, so you know these are not hypothetical)

| What went wrong | Rule |
|---|---|
| ₹9,999 paid on a ₹750 bill added ₹9,999 to Cash | §1 change, not income |
| Wallet ₹10.10 + ₹20.20 showed ₹30.299999999999997 and couldn't be spent | §1 no floats |
| Same phone added twice to one bill and sold | §2 unique items |
| 5 + 5 cables sold from a shelf of 5; cancelling created 10 | §2 whole cart, exact undo |
| "Split" payment had no amounts; the cash never reached the drawer figure | §1 every way money comes in |
| Editing a deposit from 120 to 20 made 100 disappear from yesterday | §1 ledger |
| A charge of −₹50 was accepted and lowered revenue | §1 no minus |
| Quantity 0, −3, 1.5 silently became 1 | §2 refuse, don't fix silently |
| IMEI "35A12B34…" saved as a different number | §4 never strip silently |
| Buy-phone "Add new customer" created a duplicate the main form would refuse | §4 every create path |
| Cancelling a bill deleted its payments; wallet money never came back | §6 cancel/refund |
| A bottom sheet closed on a wrong entry and lost the typing | §5 sheets stay open |
| "1 item(s)", "₹2000" next to "₹2,000" | §7, §1 formatting |
| Hindi screen showed English chips and checklist | §8 translate everything |
| Phone box took 11+ digits and showed no count of digits typed | §4 fixed-length boxes |
| Money boxes opened a number pad with no "." key; login email had no @ keyboard | §4 right keyboard |
| Stock and product pickers drew their title under the phone's clock and filled the screen | §8 safe area |
| Stock/product picker rows looked like plain text, nothing said "tap me" | §8 looks tappable |
| Picking from stock meant scrolling everything — no brand or category filter | §8 built for real size |
| 10 of 89 tour steps showed text with no highlight: a page the tour opened stayed on top; button on another tab; empty demo data; search only scrolled down | §8 tours |
| "Take the tour?" appeared before login and was then used up | §8 onboarding after login |
