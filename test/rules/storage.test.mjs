// Photos and signatures: who may add and see them, and the per-shop monthly cap.
// Runs the real storage.rules and firestore.rules on the emulators:
//   firebase emulators:exec --only firestore,storage \
//     "node test/rules/storage.test.mjs firestore.rules storage.rules"
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { doc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'fm-shop-rules-test',
  firestore: {
    rules: readFileSync(process.argv[2], 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
  storage: {
    rules: readFileSync(process.argv[3], 'utf8'),
    host: '127.0.0.1',
    port: 9199,
  },
});

let passed = 0, failed = 0;
async function check(name, fn) {
  try { await fn(); console.log(`  PASS  ${name}`); passed++; }
  catch (e) { console.log(`  FAIL  ${name}\n        ${e.message}`); failed++; }
}

const now = new Date();
const month = `${now.getUTCFullYear()}${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
const lastMonth = (() => {
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 15));
  return `${d.getUTCFullYear()}${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
})();
const jpeg = (kb) => new Uint8Array(kb * 1024);
const meta = { contentType: 'image/jpeg' };

await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  for (const [shop, uid, role] of [
    ['shop-a', 'owner-a', 'admin'],
    ['shop-a', 'staff-a', 'staff'],
    ['shop-b', 'owner-b', 'admin'],
  ]) {
    await setDoc(doc(db, 'shops', shop), { name: shop, ownerUid: 'owner-' + shop.slice(-1) });
    await setDoc(doc(db, 'shops', shop, 'members', uid), { role });
  }
  await setDoc(doc(db, `shops/shop-a/usage/${month}`), { photos: 3 });
  // A small shop, to reach its limit quickly.
  await setDoc(doc(db, 'shops/shop-s'), { name: 'small', ownerUid: 'owner-s' });
  await setDoc(doc(db, 'shops/shop-s/members/owner-s'), { role: 'admin' });
  await setDoc(doc(db, 'limits/shop-s'), { photosPerMonth: 2 });
  await setDoc(doc(db, `shops/shop-s/usage/${month}`), { photos: 2 });
  await setDoc(doc(db, 'shops/shop-a/second_hand_mobiles/phone1'), { brand: 'Samsung' });
});

const stA = env.authenticatedContext('staff-a').storage();
const ownerA = env.authenticatedContext('owner-a').storage();
const ownerB = env.authenticatedContext('owner-b').storage();
const anon = env.unauthenticatedContext().storage();
const path = (n, shop = 'shop-a', m = month) => `shops/${shop}/photos/${m}/${n}.jpg`;

console.log('\n--- adding a photo ---');
await check('staff add a counted photo (n <= counter)', () =>
  assertSucceeds(stA.ref(path(1)).put(jpeg(120), meta)));
await check('a photo past the counter is refused', () =>
  assertFails(stA.ref(path(4)).put(jpeg(120), meta)));
await check('over 300 KB is refused', () =>
  assertFails(stA.ref(path(2)).put(jpeg(301), meta)));
await check('exactly 300 KB is allowed', () =>
  assertSucceeds(stA.ref(path(2)).put(jpeg(300), meta)));
await check('not a JPEG is refused', () =>
  assertFails(stA.ref(path(3)).put(jpeg(10), { contentType: 'application/pdf' })));
await check('a photo is never replaced (no reuse of a number)', () =>
  assertFails(stA.ref(path(1)).put(jpeg(50), meta)));
await check('last month cannot be filled', () =>
  assertFails(stA.ref(path(1, 'shop-a', lastMonth)).put(jpeg(50), meta)));
await check('a name that is not a number is refused', () =>
  assertFails(stA.ref(`shops/shop-a/photos/${month}/x.jpg`).put(jpeg(50), meta)));
await check('another shop cannot add to this shop', () =>
  assertFails(ownerB.ref(path(3)).put(jpeg(50), meta)));
await check('signed out: nothing', () =>
  assertFails(anon.ref(path(3)).put(jpeg(50), meta)));
await check('anywhere else in storage: nothing', () =>
  assertFails(ownerA.ref('public/x.jpg').put(jpeg(5), meta)));

console.log('\n--- seeing a photo ---');
await check('the shop sees its photo', () =>
  assertSucceeds(stA.ref(path(1)).getMetadata()));
await check('another shop cannot see it (ID cards stay private)', () =>
  assertFails(ownerB.ref(path(1)).getMetadata()));
await check('signed out cannot see it', () =>
  assertFails(anon.ref(path(1)).getMetadata()));

console.log('\n--- deleting ---');
await check('staff cannot delete a photo', () =>
  assertFails(stA.ref(path(2)).delete()));
await check('the admin can', () =>
  assertSucceeds(ownerA.ref(path(2)).delete()));

console.log('\n--- signatures ---');
const png = (kb) => new Uint8Array(kb * 1024);
const pngMeta = { contentType: 'image/png' };
const sig = (id, shop = 'shop-a') => `shops/${shop}/signatures/${id}.png`;
await check('staff add the signature of a phone they bought', () =>
  assertSucceeds(stA.ref(sig('phone1')).put(png(20), pngMeta)));
await check('a signature is never replaced', () =>
  assertFails(stA.ref(sig('phone1')).put(png(20), pngMeta)));
await check('no signature for a purchase that does not exist', () =>
  assertFails(stA.ref(sig('nophone')).put(png(20), pngMeta)));
await check('over 100 KB is refused', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'shops/shop-a/second_hand_mobiles/phone2'), { brand: 'Vivo' });
  });
  await assertFails(stA.ref(sig('phone2')).put(png(101), pngMeta));
});
await check('not a PNG is refused', () =>
  assertFails(stA.ref(sig('phone2')).put(png(10), meta)));
await check('another shop cannot add one here', () =>
  assertFails(ownerB.ref(sig('phone2')).put(png(10), pngMeta)));
await check('the shop sees it, another shop and signed out do not', async () => {
  await assertSucceeds(stA.ref(sig('phone1')).getMetadata());
  await assertFails(ownerB.ref(sig('phone1')).getMetadata());
  await assertFails(anon.ref(sig('phone1')).getMetadata());
});
await check('staff cannot delete a signature; the admin can', async () => {
  await assertFails(stA.ref(sig('phone1')).delete());
  await assertSucceeds(ownerA.ref(sig('phone1')).delete());
});

console.log('\n--- the monthly counter (firestore.rules) ---');
const dbA = env.authenticatedContext('staff-a').firestore();
const dbS = env.authenticatedContext('owner-s').firestore();
const dbB = env.authenticatedContext('owner-b').firestore();
await check('goes up by one', () =>
  assertSucceeds(updateDoc(doc(dbA, `shops/shop-a/usage/${month}`), { photos: 4 })));
await check('cannot jump ahead', () =>
  assertFails(updateDoc(doc(dbA, `shops/shop-a/usage/${month}`), { photos: 10 })));
await check('cannot go down (no reset)', () =>
  assertFails(updateDoc(doc(dbA, `shops/shop-a/usage/${month}`), { photos: 0 })));
await check('cannot be deleted', () =>
  assertFails(deleteDoc(doc(dbA, `shops/shop-a/usage/${month}`))));
await check('a new month starts at 1, not more', async () => {
  await assertFails(setDoc(doc(dbA, `shops/shop-a/usage/209901`), { photos: 5 }));
  await assertSucceeds(setDoc(doc(dbA, `shops/shop-a/usage/209901`), { photos: 1 }));
});
await check('no other fields on it', () =>
  assertFails(updateDoc(doc(dbA, `shops/shop-a/usage/${month}`), { photos: 5, x: 1 })));
await check('stops at the limit the app owner set (2)', () =>
  assertFails(updateDoc(doc(dbS, `shops/shop-s/usage/${month}`), { photos: 3 })));
await check('another shop cannot touch the counter', () =>
  assertFails(updateDoc(doc(dbB, `shops/shop-a/usage/${month}`), { photos: 5 })));
await check('the default limit is 500', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `shops/shop-a/usage/209902`), { photos: 499 });
  });
  await assertSucceeds(updateDoc(doc(dbA, `shops/shop-a/usage/209902`), { photos: 500 }));
  await assertFails(updateDoc(doc(dbA, `shops/shop-a/usage/209902`), { photos: 501 }));
});
await check('a shop cannot raise its own limit', () =>
  assertFails(setDoc(doc(dbS, 'limits/shop-s'), { photosPerMonth: 100000 })));

console.log(`\n${passed} passed, ${failed} failed`);
await env.cleanup();
process.exit(failed === 0 ? 0 : 1);
