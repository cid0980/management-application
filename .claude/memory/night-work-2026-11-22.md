---
name: night-work-2026-11-22
description: What the overnight session (21–22 Nov 2026) built and found, and what still needs the owner's accounts
metadata:
  type: project
---

Overnight (user asleep, asked for backend + Play Store readiness), all on
`main` as Asen. Verified each step with `flutter analyze` (clean) and
`flutter test` (1148 pass at 23:03 UTC), rules with the Firestore emulator
(`test/rules/`, 48 pass).

**Found by walking the app as an owner** (web build in headless Chromium,
offline mode — see "How to walk" below):
- Home New sale/service/purchase opened lists → now open the form
- Home tiles opened the wrong tab → `?tab=` links
- repair/sale/enquiry customers never reached the customer book → `fileCustomer`
- customers added from the purchase form had no createdAt → stamped in stores
- sale with Paid left empty was recorded as fully owed → `amountPaidFrom`
- sale form had no Name box for a new number → added
- no "Ready for pickup" status → `Ready` (open, never overdue)
- no repair advance → `advancePaid`, job card + bill
- no shop repair warranty → Settings, stamped at hand-back, intake warning
- brands alphabetical (Samsung off-screen) → `byUse`
- default suppliers were one shop's Chennai traders → empty
- staff saw cost/profit → Settings switch `staffSeeCosts` (default off)
- Reports had no payment-method split → `paymentSplit`; Share report PDF
- ~90 English strings on screen in Tamil/Hindi shops → translated

**Security fix:** the shop catch-all rule also matched members/invites, so
staff could make themselves admin. Fixed + tested. Needs
`firebase deploy --only firestore:rules`.

**Play Store:** INTERNET permission was debug-only (release build could not
reach Firebase); cleartext for LAN printer; upload-key signing; in-app
account deletion; docs/PLAY_STORE.md, privacy-policy.md, delete-account.md.

**Still needs the owner:** final app ID/name, live Firebase + rules deploy,
upload key, Cloudinary build vars, web hosting for rating links and the two
public pages, 12-tester closed test.

**How to walk the app here:** `flutter create --platforms=web .` (do NOT
commit web/, it is in .git/info/exclude; revert .metadata/pubspec.lock it
touches), `flutter build web --no-web-resources-cdn`, serve build/web, drive
with Playwright after clicking `flt-semantics-placeholder`. The purchase
form's seller box dropped its first typed character under that harness —
probably the web semantics layer; check on a real phone.

**Don't:** run `dart format test/` (reformats 59 untouched files).

## Second block (22 Nov, from ~08:20 IST)

Added, all tested (1175 Flutter tests at 03:38 UTC):
- help/error text wraps app-wide (theme helperMaxLines)
- hand-back: when only the checklist blocks, a sheet lists the unticked
  checks + hand-back button (ServiceRepository.preDeliveryChecklist)
- global search from Home → /search (domain/search/global_search.dart)
- Sale.collections: later balance payments with day + method; collect
  dialog asks Cash/UPI/Card; paymentSplit counts them on their own day
- repairs in the day's money: advanceMethod at intake, pickupPayment asked
  at hand-back (askPaymentMethod), repairPayments() into paymentSplit
- products: "Send order list on WhatsApp" (orderListMessage)
- handset page: "Sell — make a bill" (bill pre-filled via handsetLine);
  the old no-bill path is "Sold without a bill"
- parts from stock on a repair: StockMoveKind.usedOnRepair + PartUse;
  costs include parts
- GST: Shop.gstRate (Off/5/18), TAX INVOICE with CGST/SGST from inclusive
  totals; used handsets left out (margin scheme); intra-state only
- rule messages (94) translated via l10n/rule_messages.dart (ruleText);
  18 messages with numbers/names still English
- offline banner (settings listener isFromCache, 4 s delay)
- docs/SCALING.md: whole-collection listeners; plan (labels on demand,
  90-day live window) NOT implemented — changes many screens

Walk tool note: controller port 9999 got stuck; ctl.js now takes PORT env,
c.sh defaults to 9997. Start detached with setsid nohup.
- later still: 18 dynamic messages translated by pattern; Home "+ ₹X from
  repairs"; app icon + adaptive icon + 512 store icon + 1024x500 feature
  graphic (docs/store/, regenerate with the make-*.js scripts); app name
  "Shop Manager" everywhere (placeholder until owner picks); enquiry →
  "Start a repair" prefilled, enquiry auto-Won with the job number;
  marking Ready offers "Tell the customer" WhatsApp. 1179 tests at 03:52.
- Public /scan page is effectively unused: printed labels carry only the
  number (Code128), not a URL, and a signed-out visitor has no shop data.
