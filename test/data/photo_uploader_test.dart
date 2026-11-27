import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/photo_uploader.dart';

void main() {
  test('without a shop there is nothing to upload to', () async {
    for (final shopId in [null, '']) {
      final uploader = photoUploaderFor(shopId: shopId, firebaseUp: true);
      expect(uploader, isA<NoPhotoUploader>());
      expect(uploader.isConfigured, isFalse);
    }
  });

  test('without Firebase there is nothing to upload to', () async {
    final uploader = photoUploaderFor(shopId: 's1', firebaseUp: false);
    expect(uploader, isA<NoPhotoUploader>());
    expect(await uploader.pickAndUpload(camera: true), isNull);
  });
}
