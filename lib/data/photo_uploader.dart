/// PHOTOS
///
/// Every photo goes to the shop's own private Firebase Storage
/// (shop_photos.dart). There is no other photo host: a seller's ID card must
/// never be a public link.
///
/// Without a shop or a working Firebase (a tour, a build that could not
/// start Firebase), photo slots work as they always have: tapping one
/// records that the photo was taken, so a purchase can still be saved.
library;

import 'shop_photos.dart';

class PhotoUploadError implements Exception {
  const PhotoUploadError(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class PhotoUploader {
  /// Whether photos can actually be uploaded from this build.
  bool get isConfigured;

  /// Take or choose a photo and return its address, or null when the
  /// person backed out.
  Future<String?> pickAndUpload({required bool camera});
}

/// No photo store to upload to: slots only record that a photo was taken.
class NoPhotoUploader implements PhotoUploader {
  const NoPhotoUploader();

  @override
  bool get isConfigured => false;

  @override
  Future<String?> pickAndUpload({required bool camera}) async => null;
}

/// The uploader for a shop: its private Firebase Storage, or none when there
/// is no shop or Firebase did not start.
PhotoUploader photoUploaderFor({String? shopId, required bool firebaseUp}) =>
    firebaseUp && shopId != null && shopId.isNotEmpty
    ? FirebasePhotoUploader(shopId: shopId)
    : const NoPhotoUploader();
