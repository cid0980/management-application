---
name: firebase-projects
description: Which Firebase project is which — fren-75087 is live, fm-shop-dev-71842 is this app's dev project
metadata:
  type: project
---

The user's Firebase account (ppugazhendi4@gmail.com) has two French-Mobiles
projects and they are NOT interchangeable:

- **`fren-75087`** — the owner's **live** second-hand stock. `../mobile_app`
  reads its `second_hand_mobiles` collection to fill the public shop window.
  Writing to it affects a live website. Its rules live in
  `../mobile_app/fren-rules/firestore.rules` and require a signed-in user.
- **`french-mobiles-marketplace`** — the customer-facing trade-in app
  (`../mobile_app`), a different product again.
- **`fm-shop-dev-71842`** — created 2026-10-24 for fm_shop. Firestore in
  `asia-south1`. Its rules are no longer the open ones: real Firebase Auth
  landed, and the multi-tenant rules in the repo's `firestore.rules` are what
  is deployed (confirmed 2026-10-26). `.firebaserc` already points here, the
  CLI is logged in, and deploying is
  `firebase deploy --only firestore:rules --project fm-shop-dev-71842`.

**Why:** the user chose a dev project rather than pointing a part-finished app
with live write paths at production data.

**How to apply:** never point fm_shop at `fren-75087` without being asked, and
always pass `--project fm-shop-dev-71842` explicitly when deploying. A rules
change is only live once deployed — `test/rules/` checks the FILE, so the two
can drift silently. See [[fm-shop-architecture]].
