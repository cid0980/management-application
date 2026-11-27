# Launching on Google Play — checklist

Written 2026-11-22. Requirements change; check each against the Play Console
help pages on the day you submit.

## Already done in the code

| Requirement | Where |
|---|---|
| Target API 36 (Android 16) | Flutter 3.47.7 default (`targetSdkVersion = 36`) |
| Internet permission in the **release** manifest | `android/app/src/main/AndroidManifest.xml` |
| Label printing over the shop network (plain `http://192.168.x.x`) | `usesCleartextTraffic="true"` in the manifest |
| Camera optional, so camera-less devices can install | `uses-feature … required="false"` |
| App name in one place | `android/app/src/main/res/values/strings.xml` (now **Shop Manager**) |
| Release signing from an upload key kept out of git | `android/app/build.gradle.kts` reads `android/key.properties` |
| **In-app account deletion** | More → Delete my account (`AuthState.deleteAccount`) |
| Security rules: no cross-shop reads, staff cannot make themselves admin | `firestore.rules`, 48 emulator tests in `test/rules/` |
| Tamil, Hindi, English | `lib/l10n/*.arb` |
| App icon (all densities + adaptive) and 512×512 store icon | `android/app/src/main/res/mipmap-*`, `docs/store/` |
| 1024×500 feature graphic | `docs/store/feature-graphic-1024x500.png` |

## You have to do these (need your accounts)

1. **Decide the app's final name and application ID.**
   `applicationId = "com.frenchmobiles.fm_shop"` can never change after the
   first upload. If the app is sold to many shops, a neutral ID (for example
   `com.<yourcompany>.shopmanager`) is better than one shop's name. Change it
   in `android/app/build.gradle.kts` *and* re-run `flutterfire configure`,
   because `google-services.json` is tied to the ID.
2. **Point the app at the live Firebase project** and deploy the rules:
   ```bash
   firebase use fren-75087
   firebase deploy --only firestore:rules
   ```
3. **Create an upload key** (once; back it up — losing it is painful):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Then create `android/key.properties` (already in `.gitignore`):
   ```
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=/home/you/upload-keystore.jks
   ```
4. **Build:** photos go to Firebase Storage (docs/PHOTOS_SETUP.md), so the
   build needs no photo settings:
   ```bash
   flutter build appbundle --release
   ```
   Upload the `.aab` from `build/app/outputs/bundle/release/`.
5. **Host two public pages** (the privacy policy and the delete-account
   page — Play needs a **web link** for deletion, not only the in-app
   button). The texts are ready in `docs/privacy-policy.md` and
   `docs/delete-account.md`; put them on Firebase Hosting, Google Sites or any
   public page. The GitHub repo is private, so links into it will not work.
6. **Closed test first.** A personal developer account made after
   13 Nov 2023 must run a closed test with at least **12 testers for 14
   continuous days** before production. Shop staff and friends with Android
   phones are enough; they must actually open the app.
7. **App access for reviewers.** The app needs a login, so give Play a
   demo email and password for a shop with some sample records in it.
8. **Store listing:** short description and full description (drafted
   below), the icon and feature graphic (in `docs/store/`), and at least two
   phone screenshots — take those after the new design is built.

## Data safety form — suggested answers

Check every answer against what you actually do before submitting.

| Question | Answer |
|---|---|
| Does the app collect or share user data? | Collects. Does not share with third parties (Firebase is a service provider acting for you). |
| Encrypted in transit? | Yes (Firebase uses HTTPS). The label printer link is on the shop's own network only. |
| Can users request deletion? | Yes — in the app (More → Delete my account) and at the web link. |
| Personal info: email address | Collected, required, for account management. |
| Personal info: name, phone number | Collected (staff name; the shop's customers' names and numbers typed in by staff), for app functionality. |
| Photos | Collected, optional (handset photos, ID cards on purchases), for app functionality. |
| Financial info | Purchase history (bills the shop makes), for app functionality. No card numbers are stored. |
| Location, contacts, messages, health | Not collected. (Import Contacts reads a vCard file the user picks; it is not access to the phone's contacts.) |
| Device or other IDs | Not collected about the user. IMEIs belong to the customers' handsets being repaired or sold. |

## Store listing draft (English)

**Short description (≤ 80 chars):**
Run your mobile shop: repairs, second-hand phones, sales, bills and stock.

**Full description:**
Shop Manager is built for mobile phone shops.

• Repairs — take in a phone with its IMEI, lock and complaints, print a job
  card, and hand it back only after the pre-delivery checklist.
• Second-hand phones — buy with a condition checklist and grade, print a
  label, and know what is in stock, on the bench or sold.
• Sales — scan a label, take Cash, UPI, card or finance, and print the bill.
• Customers — everyone you have served, with their repairs, bills and
  wallet balance; call or WhatsApp in one tap.
• Stock, enquiries, due payments, tasks for staff and daily reports.
• Works in English, தமிழ் and हिन्दी. Staff share one shop with their own
  logins; owners decide who is admin.

Sources used for the requirements above (check them again on the day):
Google Play Console Help, "Understanding Google Play's app account deletion
requirements" (answer 13327111); third-party 2026 guides on API 36 and the
12-testers / 14-days closed test.
