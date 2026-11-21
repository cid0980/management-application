// Does Shop A's staff see anything of Shop B's?
//
// This is the single property the whole multi-tenant change rests on, and the
// Dart side cannot prove it: ShopScope makes a cross-shop read hard to write,
// but only the rules make it impossible. These run against the Firestore
// emulator with the real firestore.rules file.
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { doc, getDoc, setDoc, collection, getDocs, writeBatch } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'fm-shop-rules-test',
  firestore: {
    rules: readFileSync(process.argv[2], 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

let passed = 0, failed = 0;
async function check(name, fn) {
  try { await fn(); console.log(`  PASS  ${name}`); passed++; }
  catch (e) { console.log(`  FAIL  ${name}\n        ${e.message}`); failed++; }
}

// Seed two shops with a member each, bypassing rules.
await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  for (const [shop, uid, email] of [
    ['shop-a', 'uid-a', 'a@shop.com'],
    ['shop-b', 'uid-b', 'b@shop.com'],
  ]) {
    await setDoc(doc(db, 'shops', shop), { name: shop, ownerUid: uid });
    await setDoc(doc(db, 'shops', shop, 'members', uid),
      { role: 'admin', email, isOwner: true });
    await setDoc(doc(db, 'shops', shop, 'second_hand_mobiles', 'sh-1'),
      { brand: 'Samsung', askingPrice: 18500 });
    await setDoc(doc(db, 'shops', shop, 'customers', 'c-1'),
      { name: 'A customer', phone: '9876543210' });
    await setDoc(doc(db, 'shops', shop, 'counters', 'labels'), { value: 26001 });
  }
  await setDoc(doc(db, 'invites', 'newstaff@shop.com'),
    { shopId: 'shop-a', shopName: 'shop-a', role: 'staff' });

});

const a = env.authenticatedContext('uid-a', { email: 'a@shop.com' }).firestore();
const b = env.authenticatedContext('uid-b', { email: 'b@shop.com' }).firestore();
const stranger = env.authenticatedContext('uid-x', { email: 'x@nowhere.com' }).firestore();
const anon = env.unauthenticatedContext().firestore();

console.log('\n--- a member reads their OWN shop ---');
await check('own stock', () =>
  assertSucceeds(getDoc(doc(a, 'shops/shop-a/second_hand_mobiles/sh-1'))));
await check('own customers', () =>
  assertSucceeds(getDocs(collection(a, 'shops/shop-a/customers'))));
await check('own counters', () =>
  assertSucceeds(getDoc(doc(a, 'shops/shop-a/counters/labels'))));
await check('own shop document', () =>
  assertSucceeds(getDoc(doc(a, 'shops/shop-a'))));
await check('writes own stock', () =>
  assertSucceeds(setDoc(doc(a, 'shops/shop-a/second_hand_mobiles/sh-2'),
    { brand: 'Vivo' })));

console.log('\n--- THE IMPORTANT PART: shop A cannot touch shop B ---');
await check("cannot read B's stock", () =>
  assertFails(getDoc(doc(a, 'shops/shop-b/second_hand_mobiles/sh-1'))));
await check("cannot list B's stock", () =>
  assertFails(getDocs(collection(a, 'shops/shop-b/second_hand_mobiles'))));
await check("cannot read B's customers", () =>
  assertFails(getDocs(collection(a, 'shops/shop-b/customers'))));
await check("cannot read B's counters", () =>
  assertFails(getDoc(doc(a, 'shops/shop-b/counters/labels'))));
await check("cannot read B's shop document", () =>
  assertFails(getDoc(doc(a, 'shops/shop-b'))));
await check("cannot WRITE into B's stock", () =>
  assertFails(setDoc(doc(a, 'shops/shop-b/second_hand_mobiles/evil'),
    { brand: 'injected' })));
await check("cannot add themselves to B as a member", () =>
  assertFails(setDoc(doc(a, 'shops/shop-b/members/uid-a'), { role: 'admin' })));
await check('and the same the other way round', () =>
  assertFails(getDoc(doc(b, 'shops/shop-a/second_hand_mobiles/sh-1'))));

console.log('\n--- nobody can enumerate the shops ---');
await check('a member cannot list all shops', () =>
  assertFails(getDocs(collection(a, 'shops'))));
await check('a stranger cannot list all shops', () =>
  assertFails(getDocs(collection(stranger, 'shops'))));

console.log('\n--- somebody in no shop at all ---');
await check("cannot read A's stock", () =>
  assertFails(getDoc(doc(stranger, 'shops/shop-a/second_hand_mobiles/sh-1'))));
await check('cannot make themselves a member of A', () =>
  assertFails(setDoc(doc(stranger, 'shops/shop-a/members/uid-x'),
    { role: 'admin', isOwner: true })));

console.log('\n--- but creating your OWN shop still works ---');
await check('a new owner creates a shop and their own membership', () =>
  assertSucceeds((async () => {
    const db = env.authenticatedContext('uid-new-owner',
      { email: 'owner@new.com' }).firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, 'shops', 'shop-new'),
      { name: 'New Shop', ownerUid: 'uid-new-owner' });
    batch.set(doc(db, 'shops', 'shop-new', 'members', 'uid-new-owner'),
      { role: 'admin', email: 'owner@new.com', isOwner: true });
    return batch.commit();
  })()));
await check('but not a shop owned by somebody else', () =>
  assertFails((async () => {
    const db = env.authenticatedContext('uid-thief',
      { email: 'thief@x.com' }).firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, 'shops', 'shop-stolen'),
      { name: 'Stolen', ownerUid: 'uid-a' });
    batch.set(doc(db, 'shops', 'shop-stolen', 'members', 'uid-thief'),
      { role: 'admin', isOwner: true });
    return batch.commit();
  })()));

console.log('\n--- signed out ---');
await check('reads nothing', () =>
  assertFails(getDoc(doc(anon, 'shops/shop-a/second_hand_mobiles/sh-1'))));
await check('writes nothing', () =>
  assertFails(setDoc(doc(anon, 'shops/shop-a/second_hand_mobiles/x'), {})));

console.log('\n--- invites ---');
await check('you can read the invite addressed to you', () =>
  assertSucceeds(getDoc(doc(
    env.authenticatedContext('uid-new', { email: 'newstaff@shop.com' })
      .firestore(), 'invites/newstaff@shop.com'))));
await check("you cannot read somebody else's invite", () =>
  assertFails(getDoc(doc(stranger, 'invites/newstaff@shop.com'))));
await check('you cannot list all invites', () =>
  assertFails(getDocs(collection(stranger, 'invites'))));

console.log(`\n${passed} passed, ${failed} failed`);
await env.cleanup();
process.exit(failed === 0 ? 0 : 1);
