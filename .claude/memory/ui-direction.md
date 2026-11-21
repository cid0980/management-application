---
name: ui-direction
description: Chosen UI direction (2026-11-21) — theme 2d Soft Periwinkle + mint, Zepto/Instamart/Flipkart-style layout; not built in Flutter yet
metadata:
  type: project
---

On 2026-11-21 the user chose, from rendered options:

- **Layout:** like Zepto / Instamart / Flipkart (the user's own references;
  they said they have no taste in apps, so Claude leads design). Coloured
  header with search + scan, quick-action tiles, horizontally sliding
  "Needs you now" cards, product tiles with photos, brand circles, 2-column
  phone grid with grade tag, price, strike-through original, battery, Sell.
- **Theme 2d "Soft Periwinkle":** primary `#5A62D6`, page `#F6F6FE`,
  tile `#E8E9FB`, ink `#1D1F4A`, text-2 `#5D6080`, mint tag `#2DD4A7` on
  `#06372B`. Replaces the owner's earlier rose/green (app_theme.dart).
- **Font:** Anek Tamil (Tamil + Latin), bundled, not fetched at runtime.
- Mockups: `docs/design/periwinkle/` (mockup.html, home.png, mobiles.png).

Rejected: v1 "The Counter" cards, v2 shelf/ticket-rail concept ("all look
bad"), Indigo (primary too strong). Phones in mockups are drawn — the real app
needs real photos (Cloudinary build vars; see photo_uploader.dart).

**How to apply:** next UI step is Home + Mobiles in Flutter with this theme;
send screenshots for approval before other screens. Keep replies short — the
user reads on a phone.
