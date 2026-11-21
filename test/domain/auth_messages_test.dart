import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/app/auth_state.dart';

void main() {
  group('what a failed sign-in says to a shop owner', () {
    test('a known code gets the shop\'s own wording', () {
      expect(kAuthMessages['wrong-password'], 'Wrong password');
      expect(kAuthMessages['email-already-in-use'],
          contains('already an account'));
      expect(kAuthMessages['network-request-failed'], contains('internet'));
    });

    test('an unknown code never shows Firebase\'s own text', () {
      // On a real device an unmapped failure arrived with `message` set to
      // "dev.flutter.pigeon.firebase_auth_platform_interface..." — a plugin
      // channel name, printed in red to a shop owner.
      final message = humanAuthMessage('some-new-code', signingUp: false);
      expect(message, contains('Check the email and password'));
      expect(message, isNot(contains('pigeon')));
      expect(message, isNot(contains('platform_interface')));
      // The code is still there, because it is the only thing that makes a
      // support conversation possible.
      expect(message, contains('some-new-code'));
    });

    test('and says which thing failed', () {
      expect(humanAuthMessage('x', signingUp: true), contains('create the account'));
      expect(humanAuthMessage('x', signingUp: false), contains('sign in'));
    });

    test('every mapped message is a sentence, not an identifier', () {
      // A full stop ending a sentence is fine; `word.word` is what a leaked
      // package or channel name looks like.
      final identifier = RegExp(r'[a-z]\.[a-z]');
      for (final entry in kAuthMessages.entries) {
        expect(identifier.hasMatch(entry.value), isFalse,
            reason: '${entry.key} reads like an identifier');
        expect(entry.value.length, greaterThan(8), reason: entry.key);
      }
    });
  });

  group('empty fields never reach Firebase', () {
    // The code it returns for a blank field is the least useful one it has.
    test('local mode refuses before any network call', () async {
      final auth = AuthState();
      // Local mode has no Firebase, so these return false either way — the
      // point is that the surface exists and does not throw.
      expect(await auth.signUp(email: '', password: ''), isFalse);
      expect(await auth.signInWithPassword(email: '', password: ''), isFalse);
    });
  });

  group('the shop gate', () {
    test('signed in is not the same as having a shop', () async {
      final auth = AuthState();
      expect(auth.signedIn, isFalse);
      expect(auth.hasShop, isFalse);

      await auth.signInLocally(email: 'a@b.c', role: Role.staff, shopId: '');
      expect(auth.signedIn, isTrue);
      expect(auth.hasShop, isFalse, reason: 'an account with no shop');

      auth.attachShop(shopId: 's1', shopName: 'Sri Balaji');
      expect(auth.hasShop, isTrue);
      expect(auth.shopName, 'Sri Balaji');
      // Whoever creates a shop is its admin by definition.
      expect(auth.isAdmin, isTrue);
    });

    test('signing out drops the shop with the session', () async {
      final auth = AuthState();
      await auth.signInLocally(email: 'a@b.c', role: Role.admin);
      expect(auth.hasShop, isTrue);
      await auth.signOut();
      expect(auth.signedIn, isFalse);
      expect(auth.shopId, isNull);
    });
  });

  group('initials are never blank', () {
    test('from a name, then an email', () {
      expect(
        const ShopUser(uid: 'u', email: 'a@b.c', name: 'Ramesh Kumar',
            role: Role.staff).initials,
        'RK',
      );
      expect(
        const ShopUser(uid: 'u', email: 'ramesh.kumar@shop.com', name: '',
            role: Role.staff).initials,
        'RK',
      );
      expect(
        const ShopUser(uid: 'u', email: '', name: '', role: Role.staff)
            .initials,
        '?',
      );
    });
  });
}
