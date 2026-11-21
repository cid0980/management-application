import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/data/photo_uploader.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('a build without the photo account says so instead of uploading', () {
    final uploader = CloudinaryPhotoUploader(cloudName: '', uploadPreset: '');
    expect(uploader.isConfigured, isFalse);
    expect(
      () => uploader.upload([1, 2, 3], 'a.jpg'),
      throwsA(isA<PhotoUploadError>()),
    );
  });

  test('an upload returns the photo address the record keeps', () async {
    late http.BaseRequest sent;
    final uploader = CloudinaryPhotoUploader(
      cloudName: 'shopcloud',
      uploadPreset: 'unsigned',
      client: MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({'secure_url': 'https://res.cloudinary.com/x/a.jpg'}),
          200,
        );
      }),
    );
    final url = await uploader.upload([1, 2, 3], 'a.jpg');
    expect(url, 'https://res.cloudinary.com/x/a.jpg');
    expect(sent.url.toString(),
        'https://api.cloudinary.com/v1_1/shopcloud/image/upload');
  });

  test('a refused upload is an error with the reason, not a blank photo',
      () async {
    final uploader = CloudinaryPhotoUploader(
      cloudName: 'shopcloud',
      uploadPreset: 'unsigned',
      client: MockClient((_) async => http.Response('bad preset', 400)),
    );
    expect(
      () => uploader.upload([1], 'a.jpg'),
      throwsA(isA<PhotoUploadError>()),
    );
  });
}
