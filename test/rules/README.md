# Tenant isolation tests

`flutter test` cannot prove the one property this product rests on: that
Shop A sees nothing of Shop B's. `ShopScope` in `lib/data/firestore_paths.dart`
makes a cross-shop read hard to write by accident, but only `firestore.rules`
makes it impossible — a modified client, a stolen API key or a plain bug all
stop there and nowhere else.

These run the real rules file against the Firestore emulator.

```bash
cd test/rules && npm install          # once
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
firebase emulators:exec --only firestore --project fm-shop-rules-test \
  "node test/rules/isolation.test.mjs firestore.rules"
```

`firebase` is pinned to `^12` because that is what
`@firebase/rules-unit-testing` declares as its peer — `^13` makes `npm install`
fail with ERESOLVE before a single test runs.

Run it after **any** change to `firestore.rules`. It has already earned its
keep: the first version of the member-create rule let any signed-in person
write themselves into any existing shop as owner and read everything in it.
Nothing in the Dart tests could have caught that.
