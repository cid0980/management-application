import 'imei.dart';

/// THE NUMBERS IN A PHOTO'S TEXT
///
/// What the camera's text reading returns is every word on the screen or
/// sticker: "IMEI 1", "35 487910 452368 1", "Serial Number", "F2LX1234ABCD",
/// battery percentages, the time. This picks out what the forms want.
///
/// IMEIs: 15 digits that pass the check digit, with the spaces, slashes and
/// dashes some phones and stickers put inside them taken out, and the letters
/// text reading most often mistakes for digits (O for 0, I or l for 1)
/// corrected inside a run of digits. The check digit is what keeps a battery
/// percentage and a time from being read as an IMEI.
///
/// Serials: letters and digits together, 8 to 14 long, no other marks. A code
/// on a line that says "Serial" (or straight after it) comes first.
class TextCodes {
  const TextCodes({required this.imeis, required this.serials});

  final List<String> imeis;
  final List<String> serials;
}

TextCodes codesInText(String text) {
  final imeis = <String>[];
  final serials = <String>[];
  final preferred = <String>[];
  final lines = text.split(RegExp(r'[\r\n]+'));

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    // IMEIs: digits with the separators people print inside them.
    final squeezed = line
        .replaceAllMapped(
          RegExp(r'(?<=\d)[OoQD](?=\d)|(?<=\d)[Il|](?=\d)'),
          (m) => 'OoQD'.contains(m[0]!) ? '0' : '1',
        )
        .replaceAll(RegExp(r'(?<=\d)[\s/\-.]+(?=\d)'), '');
    for (final m in RegExp(r'(?<!\d)\d{15}(?!\d)').allMatches(squeezed)) {
      final imei = m[0]!;
      if (passesLuhn(imei) && !imeis.contains(imei)) imeis.add(imei);
    }

    // Serials: whole words of letters and digits.
    final saysSerial = RegExp(r'serial', caseSensitive: false).hasMatch(line);
    final prevSaysSerial =
        i > 0 && RegExp(r'serial', caseSensitive: false).hasMatch(lines[i - 1]);
    for (final m in RegExp(r'[A-Za-z0-9]+').allMatches(line)) {
      final word = m[0]!.toUpperCase();
      if (word.length < 8 || word.length > 14) continue;
      if (!RegExp(r'[A-Z]').hasMatch(word)) continue;
      if (!RegExp(r'[0-9]').hasMatch(word)) continue;
      final list = (saysSerial || prevSaysSerial) ? preferred : serials;
      if (!list.contains(word)) list.add(word);
    }
  }
  return TextCodes(
    imeis: imeis,
    serials: [...preferred, ...serials.where((s) => !preferred.contains(s))],
  );
}
