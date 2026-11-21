---
name: fm-shop-architecture
description: fm_shop keeps every shop rule in a pure domain module with a test naming the rule
metadata:
  type: project
---

fm_shop (Flutter port of the French-Mobiles-2026 React PWA) follows one
convention that is not obvious from the code alone: **every rule stated in
docs/FLOW.md lives in exactly one pure-Dart module under `lib/domain/`, with a
test whose name is the rule in plain words.** Modules carry long header comments
explaining the shop incident each rule came from.

Screens talk to a repository in `lib/data/` and never to Firestore. As of
2026-10-24 Firebase is still unconfigured, so each repository has an
`InMemory*` implementation seeded with the record shapes that have caused
trouble (a handset on the bench, one sold, one with an unrecognised status, a
customer with no name). Wiring the backend up means swapping the provider in
`lib/main.dart`, not touching a screen.

**Why:** the user's instruction was "we focus on function not ui" — the value is
in the rules being stated and tested, not in the widgets.

**How to apply:** when adding an area, write the domain module and its tests
first, then the repository, then the screens; match the existing comment density
and the "why it is this way" tone. Build order so far: Customers, Second-Hand,
Service, Sales. See [[no-apk-builds]] for verification.
