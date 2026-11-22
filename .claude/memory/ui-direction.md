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

Not done / known: offline save of a NEW repair or bill still needs the
internet (order/invoice numbers come from a Firestore transaction); the
guard now says so instead of hanging. Job page has no "Where is it now"
track — the status chips do that job. Import contacts label untranslated.

How to preview: scratchpad preview_build.sh pattern — temporarily seed
main.dart (default seeds + signInLocally admin), build web, restore
main.dart; serve build/web; hash routes (#/service/so-1).
