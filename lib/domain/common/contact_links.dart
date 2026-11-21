/// CALLING AND WHATSAPP
///
/// Ported from the French Mobiles Flutter port (`french_mobiles_core`
/// `phone.dart`): the links that open the dialler and WhatsApp on a
/// customer's number, with a message already written.
///
/// WhatsApp wants the number with its country code and nothing else. A
/// ten-digit Indian mobile gets `91` in front; a number that is not a
/// diallable Indian mobile gets no link at all, so the screen can say why
/// rather than open WhatsApp on a number that does not exist.
library;

import 'phone.dart';

/// `9876543210` -> `919876543210`, or null when WhatsApp would refuse it.
String? whatsAppNumber(String? raw) =>
    isDiallablePhone(raw) ? '91${normalizePhone(raw)}' : null;

/// The link that opens a chat with [message] already typed, or null.
Uri? whatsAppUri(String? phone, [String message = '']) {
  final number = whatsAppNumber(phone);
  if (number == null) return null;
  return Uri.https('wa.me', '/$number', {
    if (message.isNotEmpty) 'text': message,
  });
}

/// The link that opens the dialler on [phone], or null.
Uri? callUri(String? phone) => isDiallablePhone(phone)
    ? Uri(scheme: 'tel', path: normalizePhone(phone))
    : null;
