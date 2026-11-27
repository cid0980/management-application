# Scaling: what loads, what it costs, what to change

Written 2026-11-22. **Steps 1–4 are now built** (same day, evening) — see
"Built" at the end.

## How the app loads data today

Every area opens a live Firestore listener on its **whole** collection when
the shop is opened (`lib/data/firestore_*_repository.dart`, `load()`):
customers, second-hand stock, products, service orders, sales, enquiries,
tasks, the label registry, ratings, settings. Screens, search, reports,
Due Payments and a customer's history all work on those full in-memory lists.

That is simple and instant while a shop is small. It grows with every bill.

## What that costs

Firestore bills one read per document a listener delivers, and a listener
that has been disconnected for more than 30 minutes is billed as a new query
— so in practice **every morning's app open re-reads the whole shop**.
Free quota is 50,000 reads/day **per Firebase project** (all shops share one),
then $0.03 per 100,000 reads (Standard edition; check the pricing page —
it varies by region).

A busy shop after two years, roughly:

| Collection | Documents |
|---|---|
| Sales | 6,000 |
| Service orders | 4,000 |
| Customers | 3,000 |
| Label registry | 6,000 |
| Second-hand handsets | 1,000 |
| Enquiries, products, tasks | 1,500 |
| **Total** | **~21,500** |

3 phones × 2 cold starts a day × 21,500 = **~130,000 reads per shop per day.**

- 1 shop: over the free quota by itself → about $0.02/day.
- 100 shops: ~13 million reads/day → about **$4/day, ~$120/month**.

The money is not the main problem. **Start-up time and phone memory are**: a
budget Android phone downloading and holding 21,500 records before Home is
usable will feel slow, on mobile data especially.

## The plan, in order of value

1. **Label registry — load on demand.** It is listened to only so a scan can
   resolve a number. A scan can `get` one document by number instead. This
   alone removes ~25% of the reads. Touches `label_repository.dart`,
   `public_scan_screen.dart`, `scanner_screen.dart`.
2. **Service orders and sales — keep the live window small.** Listen to
   what is open (not Completed/Returned; drafts; bills with a balance due)
   plus everything from the last 90 days. Older records are fetched by query
   when somebody asks: a report over an older range, a search that finds
   nothing locally, a customer's full history.
3. **Reports over old ranges — query on demand** (`where('completedAt', …)`),
   instead of filtering the in-memory list.
4. **Search — fall back to the server** for an exact IMEI, phone, job or bill
   number when the local window has no match.
5. **Customers and products** can stay fully loaded for a long time (they
   grow slowly and autocomplete needs them).

Do 1 and 2 before roughly **50 shops or one year of a busy shop's data**,
whichever comes first. Each step changes what "the list" means for several
screens, so each needs its own tests; none should be done blind.

## Already in place that helps

- Firestore's local cache keeps the app usable offline and makes a warm
  start cheap.
- Counters (invoice, job, label numbers) are single documents read in
  transactions, not counts of a collection.
- Security rules stop any shop from reading another's data, so a mistake in
  a query cannot leak — it can only cost reads.

## Built (22 Nov 2026)

1. **Label registry:** only the latest 300 labels are live
   (`kLiveLabels`, firestore_label_repository.dart). Older numbers are
   fetched one at a time on scan, on the public scan page and in the Labels
   search; before assigning, the server is asked whether the record already
   has a label.
2. **Repairs and bills — live window** (`live_window.dart`): repairs that are
   not Completed/Returned, drafts, bills with `balanceDue > 0` (so Due
   Payments stays complete), plus anything with `updatedAt` in the last 90
   days — queried both as ISO string and as Timestamp, because older builds
   wrote Timestamps. Merged by id.
3. **Reports** over a range that starts before the window fetch the bills
   completed and jobs closed in that range (`fetchCompletedBetween`,
   `fetchClosedBetween`), with a progress bar while they come.
4. **Search:** a job number, bill number or phone with no local match is
   asked of the server (`fetchOlder`). A customer's page fetches all their
   older repairs and bills. A record page for an old record fetches it
   (`fetchById`, `FetchingRecord`) before saying "not found".

Not done: customers and products stay fully loaded (plan step 5 says that
is fine for a long time). Firestore may ask for composite indexes for the
range queries the first time they run against a live project; the error
message carries a link that creates them.

## Built (27 Nov 2026)

5. **Second-hand stock — live window.** Listens to phones not sold, plus
   anything with `updatedAt` in the last 90 days. A phone page outside it is
   fetched (`fetchById`); a customer's page fetches the phones they sold the
   shop, the purchase form a returning seller's ID photos, search an IMEI or
   seller number, and Reports the phones bought or sold in an older range
   (`fetchOlder`, `fetchActiveBetween`). `sellerPhone` and `imei` are now
   stored clean so those queries match; older records typed with spaces are
   asked for in the common shapes too.
6. **Enquiries — live window.** Open enquiries (not Won/Lost/Closed) plus
   the last 90 days. A customer's page and search fetch older ones by
   customer or number; an enquiry page fetches its record.
7. **Signatures off the record.** A seller's signature (8–47 KB of text on
   every purchase record) is moved to Storage
   (`shops/<shop>/signatures/<record>.png`, lib/data/signatures.dart) and the
   record keeps its `fs://` address, so loading stock no longer downloads
   every signature. Old records are moved the first time a phone loads them.

Still fully loaded, on purpose: customers and products (step 5 above —
the pickers autocomplete over them), and tasks (a few dozen routines that
repeat daily, weekly or monthly; none of them ever closes).
