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
