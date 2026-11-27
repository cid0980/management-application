# Private photo storage (Firebase Storage)

Every photo goes to the shop's own Firebase Storage; there is no other photo
host. In `fm-shop-dev-71842` these steps are done (bucket in **us-west1**,
rules published 27 Nov 2026). They are kept for setting up another project.

## 1. Firebase console (the owner)

1. **Upgrade to Blaze** (Project settings > Usage and billing). A card is needed.
2. **Budget alert:** Google Cloud console > Billing > Budgets & alerts > create
   one (for example ₹500 a month). It emails; it does not stop spending.
3. **Storage > Get started**, location **us-central1**, **us-west1** or
   **us-east1** (the free 5 GB stored and 100 GB downloaded a month only apply
   to these US regions).
4. **Storage > Rules:** paste the whole of `storage.rules` from this repo,
   Publish. If the console asks to let Storage read Firestore (the rules check
   the shop's members and photo counter there), allow it.
5. **Firestore > Rules:** paste the whole of `firestore.rules`, Publish (it now
   has the photo counter and `limits`).

## 2. Limits (what Blaze can cost)

Enforced by the rules, whatever app is used:

- one photo at most **300 KB**, JPEG only (the app shrinks each towards **120 KB**);
- **500 photos per shop per month** unless raised;
- a photo cannot be replaced, and only that shop's signed-in people can add or
  see its photos.

So one shop can store at most 500 × 300 KB = **150 MB a month**.

To give a shop more: Firestore > Start collection `limits` > document id = the
shop's id > field `photosPerMonth` (number), e.g. 1500. Shops cannot change
this themselves.

## 3. App Check (after the Play Store release)

The app already sends App Check tokens (Play Integrity). In the console:
App Check > register the Android app with Play Integrity, watch the
"verified requests" share for a few days, then **Enforce** for Firestore and
Storage. Do not enforce before the app is installed from the Play Store:
APKs from GitHub are not recognised by Play Integrity and would be locked out.
