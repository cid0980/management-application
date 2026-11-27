import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/signatures.dart';

void main() {
  final png = [137, 80, 78, 71, 1, 2, 3];
  final dataUrl = 'data:image/png;base64,${base64Encode(png)}';

  test('a signature on the record is read from its data URL', () {
    expect(isSignatureDataUrl(dataUrl), isTrue);
    expect(signatureFromDataUrl(dataUrl), png);
  });

  test('a stored signature, a blank or rubbish is not a data URL', () {
    for (final v in [
      null,
      '',
      'fs://shops/s1/signatures/a.png',
      'data:image/png;base64',
    ]) {
      expect(isSignatureDataUrl(v), isFalse, reason: '$v');
      expect(signatureFromDataUrl(v), isNull, reason: '$v');
    }
    expect(signatureFromDataUrl('data:image/png;base64,***'), isNull);
  });

  test('loading: inline is decoded, nothing is nothing', () async {
    expect(await loadSignature(dataUrl), png);
    expect(await loadSignature(null), isNull);
    expect(await loadSignature('https://example.com/a.png'), isNull);
  });
}
