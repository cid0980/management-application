/// PHOTOS
///
/// Ported from the French Mobiles Flutter port (`data/cloudinary.dart`).
/// `image_picker` shrinks the photo as it reads it (1280 px, JPEG at 80%, the
/// web app's limits) and it is posted to an unsigned Cloudinary preset, which
/// returns the address the record keeps.
///
/// **Configured once for the whole app, at build time** — the app's owner
/// holds the photo account, so no shop owner is asked to set one up:
///
///     flutter run --dart-define=CLOUDINARY_CLOUD_NAME=… \
///                 --dart-define=CLOUDINARY_UPLOAD_PRESET=…
///
/// Without those, photo slots work as they always have: tapping one records
/// that the photo was taken, so a purchase can still be saved.
///
/// Nothing here is secret: an unsigned preset is public by design, and the
/// cloud name is in every image address.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
const _uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

class PhotoUploadError implements Exception {
  const PhotoUploadError(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class PhotoUploader {
  /// Whether photos can actually be uploaded from this build.
  bool get isConfigured;

  /// Take or choose a photo and return its web address, or null when the
  /// person backed out.
  Future<String?> pickAndUpload({required bool camera});
}

class CloudinaryPhotoUploader implements PhotoUploader {
  CloudinaryPhotoUploader({
    http.Client? client,
    this.cloudName = _cloudName,
    this.uploadPreset = _uploadPreset,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String cloudName;
  final String uploadPreset;

  @override
  bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  @override
  Future<String?> pickAndUpload({required bool camera}) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (file == null) return null;
    return upload(await file.readAsBytes(), file.name);
  }

  Future<String> upload(List<int> bytes, String filename) async {
    if (!isConfigured) {
      throw const PhotoUploadError('Photo upload is not set up in this app.');
    }
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
            ),
          )
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename),
          );
    final response = await _client.send(request);
    final body = await response.stream.bytesToString();
    if (response.statusCode >= 400) {
      throw PhotoUploadError(
        'The photo did not upload (${response.statusCode}).',
      );
    }
    final decoded = jsonDecode(body);
    final url = decoded is Map ? decoded['secure_url'] : null;
    if (url is! String || url.isEmpty) {
      throw const PhotoUploadError('The upload returned no photo address.');
    }
    return url;
  }
}
