---
name: multi-tenant
description: fm_shop is a SaaS product — many shops, isolated under shops/{shopId}, enforced by rules
metadata:
  type: project
---

fm_shop is being **sold to many mobile shops**, not built for one. Everything
lives under `shops/{shopId}/…` with `members/{uid}` deciding access, and one
shop must see nothing of another's.

Two layers, and they are not the same thing:

- `lib/data/firestore_paths.dart` — repositories get a `ShopScope` and there is
  no method returning a top-level collection of shop data, so a cross-shop read
  cannot be typed by accident.
- `firestore.rules` — what makes it actually impossible.

**Run `test/rules/` after ANY rules change.** It found a real hole on
2026-10-24: the member-create escape hatch (needed because a new owner has no
membership yet) let any signed-in person write themselves into any existing
shop as owner. Fixed with `getAfter` requiring the shop to name them as owner.
`get` does not work there — the shop doc is written in the same batch.

Counters are per shop: two shops both starting at label 26001 is correct.

**Why:** the user said "we gonna sell this app in market there is lot of mobile
shops are there so every one create their own collection".

**How to apply:** never add a repository that names a collection directly; take
a `ShopScope`. See [[firebase-projects]] and [[fm-shop-architecture]].
