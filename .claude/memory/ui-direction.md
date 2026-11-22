---
name: ui-direction
description: Chosen UI direction (2026-11-22) — plain Material 3 "app feel": navy + white, Roboto, top bar C (navy with search inside). Replaces the periwinkle direction.
metadata:
  type: project
---

On 2026-11-22 the user rejected the periwinkle + Anek Tamil mockups (v1–v3,
`docs/design/periwinkle/`) as "generic / looks AI". They showed screenshots
of a plain repair app (OK Repair: navy header, white cards, labelled rows,
Roboto) and said it "gives an app feel" and ours did not.

Why ours did not (agreed): display font (Anek Tamil) for English, small dense
text, many sections and side-scrolling strips, pastel tiles, no title bar.

**Chosen now** (Flutter mockup approved, top bar option C):
- Plain Material 3 parts, system font (Roboto; Android's Noto for Tamil/Hindi).
- Navy `#0C1A3D` header and main buttons, white cards with a thin border
  `#D9DEE7`, page `#F1F3F7`, text `#151B28` / `#5B6475`.
- Colour only for status: red late/due, amber pending/due today, green
  paid/ready.
- Top bar C: navy, shop name + bell + avatar, search box (with scan button)
  inside the navy block.
- Home, one column, big text: Today's sales card (big amount, "+ from
  repairs", Cash/UPI/Card boxes, "N bills" pill) → 2×2 buttons (New sale
  filled; New repair, Buy phone, Enquiry outlined) → "Repairs needing
  action" with Late/Due today/Ready chips and job cards (Job no., status
  pill, device, problem · due, customer · phone, Call / WhatsApp / Open).
- Bottom bar: Home · Mobiles · Repairs · Sales · More (no raised Scan).
- Mockup source was a throwaway Flutter project in the session scratchpad.

**How to apply:** design first, show a screenshot, get OK, then code. The user
interrupts when building starts before they approve. Keep replies short.

## Built (22 Nov 2026, afternoon) — all on main as Asen

The user approved the style and asked to code every page without waiting.
Done, each step with analyze clean and all tests passing (1199):
- Theme v4 navy (app_theme.dart), phone's own font; Anek Tamil removed.
- Home (dashboard_screen.dart): option C top block, sales card, 4 buttons,
  job cards Late/Due today/Ready, "Also on the board" counts.
- Shared pieces: ui/widgets/shop_ui.dart (NavySearchBlock, StatusPill,
  CountChip/ChipRow, FactsCard/FactRow, FormSection, ActionBar,
  ListSection); empty_state.dart has EmptyState(action) + ErrorState;
  save_guard.dart (guardSave/guardRun: failed save → dialog, form stays).
- Lists (Mobiles, Repairs, Sales, Products, Enquiries, Customers): navy
  search block, counted chips, cards, spinner/error/empty states. Mobiles
  shows days in stock (isStale after 30 days, stock_list.dart).
- Record pages: labelled cards (_Block → FactsCard), repair header card,
  phone photos, loading vs not-found, ActionBar (next step full width).
- Forms open over the whole app (useRootNavigator), FormSection headings,
  Buy phone segmented step bar.
- More grouped in cards; login navy block; search page box white on navy.
- Tests use test/chips.dart (chipLabelled/tapChip/selectedChipLabel).

Offline: plain writes go through localWrite (queued, no spinner). A NEW
repair taken in offline gets a T number (SO-YYYYMMDD-Thhmmss,
offlineServiceOrderNumber) because the counter is a transaction. A NEW
bill still needs the internet (invoice counter + stock transaction); the
save guard says "No internet" for it. Job page has no "Where is it now"
track — the status chips do that job. Import contacts label untranslated.

How to preview: scratchpad preview_build.sh pattern — temporarily seed
main.dart (default seeds + signInLocally admin), build web, restore
main.dart; serve build/web; hash routes (#/service/so-1).

## Evening, 22 Nov 2026 (all on main as Asen; 1249 tests)

- Compact pass: type scale body 15–16 / headings 17–21, 48 dp buttons,
  3-line Mobiles cards, tighter cards everywhere. The owner wants calm
  screens with room to breathe, not big crowded ones.
- Settings is a grouped menu; each setting its own page
  (/admin/settings/<page>, models at /admin/settings/models/<brand>).
  Lists are rows with Rename/Remove + Add box + search (_ListEditor).
- Back arrow in the top bar on every page below a tab.
- Mockup items built: repair "Where is it now?" track; Buy phone one-tap
  brand/RAM/storage, Works/Faulty rows, "sold you N phones before";
  repair lock buttons; phone page actions under the header.
- Bluetooth TSPL label printer (Settings → Label printer, per phone); the
  shop-PC print server was removed on the owner's word ("we don't build
  any server on PC").
- Speed: labels latest 300 live; repairs/bills live window (open + 90 d),
  older on demand (live_window.dart, docs/SCALING.md "Built").
- IGST switch on New sale (only when the shop charges GST).
- Battery health % on Buy phone; pill on Mobiles cards.
- Offline bill: kept as pendingCompletion draft, completed automatically
  online (pending_bills.dart); a handset sold meanwhile is refused.
- GitHub Actions builds the APK on every push to main
  (.github/workflows/build-apk.yml): Actions tab → run → Artifacts.
  Debug-signed until the upload key is added as repository secrets.
