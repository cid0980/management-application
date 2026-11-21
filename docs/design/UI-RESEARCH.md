# UI / UX research — tools, packages and guide files (2026-11-21)

Goal: make fm_shop feel like a **full, lived-in shop app** instead of an empty
form tool, using **direction C — "Your colours, lighter"** (rose + dark green,
softened). Stay on Flutter.

Every package below was checked on pub.dev on **2026-11-21** against this
project's toolchain: **Flutter 3.47.7 / Dart 3.13.5** (see README).

---

## 1. Why the app feels empty today

Found from the code and `.claude/memory/ui-pages.md`:

- The colours are not the problem. `lib/ui/theme/app_theme.dart` is a
  deliberate palette ("Sage + Rose", picked 2026-11-11) that overrides the
  generated Material scheme colour by colour.
- The **emptiness** comes from:
  1. Lists that are only text rows: no thumbnails, brand marks or status colour.
  2. Plain-text empty states with no picture and no next step (problem 6 in the
     memory notes).
  3. A dashboard with numbers but **no trend**: nothing shows today vs this week.
  4. No motion: screens snap in and lists pop in all at once.
  5. Long paragraphs filling space that pictures, chips or numbers should fill.
  6. No loading state, so the screen is blank until Firestore answers.

---

## 2. Flutter packages — checked and compatible

✅ = works with Flutter 3.47.7 / Dart 3.13.5 · ⚠️ = works, read the note · ❌ = will not install

### Fill the screen with meaning

| Package | Version (date) | What it gives fm_shop | Status |
|---|---|---|---|
| `fl_chart` | 1.3.1 (2026-11-09) | Small 7-day takings line on Home, bars on Reports | ✅ |
| `skeletonizer` | 3.0.0 (2026-09-11) | Grey "shape" placeholders while Firestore loads, built from the real widgets | ✅ |
| `flutter_svg` | 2.5.0 (2026-11-19) | SVG illustrations for empty states, brand logos for phones | ✅ |
| `gap` | 3.1.0 (2026-11-04) | `Gap(12)` instead of `SizedBox`: consistent spacing, less code | ✅ |

### Motion — makes the app feel alive

| Package | Version (date) | Use | Status |
|---|---|---|---|
| `animations` (Flutter team) | 3.0.0 (2026-08-19) | Card → detail "container transform", shared-axis page changes | ✅ |
| `flutter_animate` | 4.5.2 (2024-11-25) | One-line fade/slide-in for list rows and cards | ⚠️ Last release Nov 2024. Works, but no updates for 2 years |
| `lottie` | 3.8.2 (2026-11-02) | Small animated success tick after a sale/print | ✅ |
| `rive` | 0.14.11 (2026-08-03) | Interactive animations. More than we need | ⚠️ Skip for now |

### Interaction

| Package | Version (date) | Use | Status |
|---|---|---|---|
| `flutter_slidable` | 5.2.0 (2026-11-01) | Swipe a row → Call / WhatsApp / Mark done | ✅ |
| `toastification` | 3.2.2 (2026-10-25) | Nicer "Saved" / "Printed" messages than plain SnackBar | ✅ |
| `wolt_modal_sheet` | 0.12.0 (2026-10-27) | Multi-page bottom sheets (take-in flow in steps) | ✅ |

### Icons and fonts

| Package | Version (date) | Note | Status |
|---|---|---|---|
| `hugeicons` | 4.4.0 (2026-10-30) | Large modern icon set, rounded style suits C | ✅ |
| `lucide_icons_flutter` | 4.0.3 (2026-11-10) | Clean line icons | ✅ |
| `phosphor_flutter` | 2.1.0 (2024-05-10) | Nice set, but no release since May 2024 | ⚠️ |
| `google_fonts` | 9.0.0 (2026-09-28) | Downloads fonts at runtime by default | ⚠️ Bundle the files in `assets/fonts/` instead. Shop phones can be offline, and Tamil/Hindi need **Noto Sans Tamil / Noto Sans Devanagari** (the app already bundles Noto Sans for PDFs) |

### Whole theming / component kits

| Package | Version (date) | Verdict |
|---|---|---|
| `flex_color_scheme` | 9.0.0 (2026-09-15) | ✅ Compatible. Useful for consistent component themes, **but** our palette is already hand-tuned, so not needed now |
| `material_3_expressive` | 1.2.3 (2026-11-18) | ⚠️ Community package, not the Flutter team. Newer Material "expressive" shapes. Don't build the app on it |
| `shadcn_ui` | 0.61.2 (2026-11-20) | ⚠️ Compatible, but it's a different design language. Mixing it with Material = inconsistent app |
| `syncfusion_flutter_charts` | 35.2.12 (2026-11-18) | ⚠️ Commercial licence (free community licence only below their revenue limit). `fl_chart` is enough |
| `getwidget` | 7.0.2 (2026-05-24) | ⚠️ Generic look; adds weight, little value |
| `forui` | 0.28.0 (2026-11-15) | ❌ Needs Flutter ≥ 3.50 / Dart ≥ 3.14 |
| `flutter_staggered_animations` | 1.1.1 (2022) | ❌ Requires Dart < 3.0 |
| `empty_widget` | 0.0.5 (2021) | ❌ Requires Dart < 3.0 |
| `shimmer` | 4.0.0 (2026-08-21) | ✅ Works, but `skeletonizer` does the same job better |

**Recommended short list (7):** `fl_chart`, `skeletonizer`, `flutter_svg`,
`animations`, `flutter_slidable`, `gap`, `hugeicons`. Optional: `lottie`,
`toastification`.

---

## 3. Guide / `.md` files for the AI (Claude) to follow

| File / source | What it is | Use it? |
|---|---|---|
| **DESIGN.md** (Google Stitch format, 2026) | One markdown file in the repo root: colours, type, spacing, components, do's and don'ts. Coding agents read it to keep UI consistent | **Yes.** Write our own from direction C + `app_theme.dart`. Claude Code does not auto-load it, so link it from a `CLAUDE.md` |
| **VoltAgent/awesome-design-md** (GitHub) | 84 example DESIGN.md files from real products | Reference for format only. Don't copy another brand |
| **flutter/skills** (official, Flutter team) | Agent skills. UI-relevant: `flutter-fix-layout-issues` (overflows), `flutter-build-responsive-layout`, `flutter-add-widget-preview` | **Yes.** `fix-layout-issues` directly matches our chip-row overflow |
| **anthropics/skills → frontend-design** | Anthropic's design-quality guidance (pick a direction, deliberate typography, avoid template look) | Yes, as a reference. It's web-focused, but the principles apply |
| Flutter `rules.md` (docs.flutter.dev/ai) | Former official AI rules file | ⚠️ The Flutter repo now says the rules folder no longer holds rule files; the skills/plugins replace it |
| Third-party Flutter skills (zakariaf/Flutter-Skills, etc.) | Community skill packs | Optional; many assume Riverpod/BLoC, while we use Provider |

---

## 4. UX patterns that stop a screen feeling empty

From empty-state guidance (Atlassian, SAP Fiori, Toptal, Canva, UX Planet):

1. **Empty state = picture + one line + one button.** "No phones in stock yet →
   Take in a phone." Never a paragraph.
2. **Show what will appear.** The first-day Home shows the card layout with ₹0
   and a hint, not a blank space.
3. **Skeletons while loading**, never a blank screen or a lone spinner.
4. **Every list row gets a visual anchor**: a brand logo/letter circle, a
   coloured status chip and the amount on the right.
5. **Trend, not just totals**: a sparkline of the last 7 days under "Today ₹".
6. **Activity feed on Home**: "Sold iPhone 13 · ₹32,000 · 10 min ago". It's the
   single biggest "this app is alive" signal.
7. **Collapsible help**: the long explanations become a `?` that expands.
8. **Motion with purpose**: list rows fade in staggered (≈ 30 ms each), and
   cards expand into their detail page.
9. Keep the colour rules from `app_theme.dart`: rose = structure, green =
   action, meaning colours always with a word.

## 5. Where to get pictures and references

| Source | Use | Cost / licence (verify on the site) |
|---|---|---|
| **unDraw** | Empty-state illustrations; colour can be set to our rose `#A65D64` | Free; can't be redistributed as a pack. Very common, so recolour it |
| **Storyset** | Alternative illustrations | Free with attribution |
| **Mobbin** | Screens from real shipped apps (search "POS", "inventory", "orders") | Freemium |
| **Dribbble** | Visual inspiration | Free to browse |
| **Material 3 site** (m3.material.io) | Official component and motion guidance | Free |

---

## 6. Proposed next steps

1. Write `DESIGN.md` for direction C, and a `CLAUDE.md` that points to it.
2. Add the 7 recommended packages; run `flutter analyze` + `flutter test`.
3. Build shared widgets once: `EmptyState`, `StatusChip`, `ListRowAvatar`,
   `SkeletonList`, `Sparkline`.
4. Restyle **Home** first (activity feed + sparkline + lighter C cards), then
   screenshot it on the phone. Then do Mobiles.

---

## Sources

- pub.dev API, checked 2026-11-21: versions and SDK limits for every package above
- [Flutter team agent skills — github.com/flutter/skills](https://github.com/flutter/skills)
- [Flutter: AI rules / get started with AI](https://docs.flutter.dev/ai/ai-rules)
- [Anthropic frontend-design SKILL.md](https://github.com/anthropics/skills/tree/main/skills/frontend-design)
- [VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md)
- [Google Stitch — DESIGN.md overview](https://stitch.withgoogle.com/docs/design-md/overview/)
- [Better Stack — DESIGN.md guide](https://betterstack.com/community/guides/ai/design-md-ai/)
- [DEV — AGENTS.md, SKILL.md, DESIGN.md](https://dev.to/aws-builders/agentsmd-skillmd-designmd-how-ai-instructions-split-into-three-layers-d0g)
- [Atlassian — empty state](https://atlassian.design/foundations/content/designing-messages/empty-state)
- [SAP Fiori — designing for empty states](https://www.sap.com/design-system/fiori-design-web/v1-96/foundations/best-practices/global-patterns/designing-for-empty-states)
- [Toptal — empty state UX](https://www.toptal.com/designers/ux/empty-state-ux-design)
- [Canva — empty states](https://www.canva.dev/docs/apps/designing-apps/empty-states)
- [Muzli — free illustration libraries 2026](https://muz.li/blog/best-free-illustration-libraries-for-designers-2026/)
- [Mobbin](https://mobbin.com/)
