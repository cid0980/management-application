/// EMAIL ADDRESSES — ONE RULE FOR THE WHOLE APP
///
/// A customer's email and a staff invite used to be checked two ways: a
/// customer needed something@something.something, an invite took `a@b` — an
/// invite nobody could ever claim, because nobody signs in with `a@b`.
///
/// Still loose on purpose: no spaces, one @ with something before it, and a
/// dot in the part after it with at least two characters past the last dot.
/// Addresses that look odd are often real; this only stops the ones that
/// cannot be.
library;

final _shape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s.]{2,}$');

bool isEmailAddress(String? value) {
  final text = (value ?? '').trim();
  return _shape.hasMatch(text) && text.indexOf('@') == text.lastIndexOf('@');
}
