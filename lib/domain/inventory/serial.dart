/// A SERIAL NUMBER OFF A BARCODE
///
/// A phone box carries several barcodes: the IMEIs (15 digits), the shop
/// barcode (EAN/UPC, 12–13 digits), a part number (`MPXT3HN/A`) and the
/// serial. Only the serial is letters and digits, 8 to 14 long, so that is
/// all that is taken. Anything else is null.
///
/// Apple's box labels put an `S` in front of the serial in the barcode
/// (a field marker, not part of the number). An iPhone serial is 12 (older)
/// or 10 (2021 on) characters, so for Apple an 11- or 13-long code starting
/// with S loses the S. The box stays editable, so a wrong guess is one tap.
String? serialFromBarcode(String raw, {bool apple = false}) {
  var code = raw.replaceAll(RegExp(r'\s'), '').toUpperCase();
  if (!RegExp(r'^[A-Z0-9]{8,14}$').hasMatch(code)) return null;
  if (!RegExp(r'[A-Z]').hasMatch(code) || !RegExp(r'[0-9]').hasMatch(code)) {
    return null;
  }
  if (apple &&
      code.startsWith('S') &&
      (code.length == 11 || code.length == 13)) {
    code = code.substring(1);
  }
  return code;
}
