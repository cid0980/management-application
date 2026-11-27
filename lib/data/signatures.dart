import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'shop_photos.dart';

/// SELLERS' SIGNATURES, OUT OF THE RECORD
///
/// The pad hands back a PNG as a data URL (8–47 KB of text). Kept on the
/// purchase record, every phone downloads every signature each time the
/// stock list loads. So a signature is moved to the shop's private storage
/// (`shops/<shop>/signatures/<record>.png`) and the record keeps only its
/// `fs://` address.
///
/// The record is saved first, with the data URL, so a purchase never waits
/// on an upload and still saves offline; the stock store moves it as soon as
/// it can (firestore_second_hand_repository.dart). Old records are moved the
/// same way the first time a phone loads them.
///
/// storage.rules lets a member create one signature per purchase record
/// that exists, a PNG of at most [kMaxSignatureBytes], never replaced.

/// The most one signature may weigh — what storage.rules allows.
const kMaxSignatureBytes = 100 * 1024;

bool isSignatureDataUrl(String? value) =>
    value != null && value.startsWith('data:image') && value.contains(',');

/// The PNG inside a data URL, or null when it is not one.
Uint8List? signatureFromDataUrl(String? value) {
  if (!isSignatureDataUrl(value)) return null;
  try {
    return base64Decode(value!.substring(value.indexOf(',') + 1));
  } catch (_) {
    return null;
  }
}

/// A signature's PNG, wherever it is kept; null when there is none or it
/// cannot be loaded (the declaration then prints a blank line to sign).
Future<Uint8List?> loadSignature(String? value) async {
  final inline = signatureFromDataUrl(value);
  if (inline != null) return inline;
  if (value == null || !value.startsWith('fs://')) return null;
  try {
    return await PhotoBytes.instance.load(value);
  } catch (_) {
    return null;
  }
}

/// Puts a signature in the shop's storage and returns its `fs://` address.
typedef SignatureSaver = Future<String> Function(
  String recordId,
  Uint8List png,
);

/// The [SignatureSaver] for a shop's Firebase Storage.
SignatureSaver firebaseSignatureSaver(
  String shopId, {
  FirebaseStorage? storage,
}) => (recordId, png) async {
  final path = 'shops/$shopId/signatures/$recordId.png';
  final ref = (storage ?? FirebaseStorage.instance).ref(path);
  try {
    await ref.putData(png, SettableMetadata(contentType: 'image/png'));
  } on FirebaseException catch (e) {
    // The rules refuse a second write: another phone moved it first. It is
    // there if its details can be read; if not, the refusal stands.
    if (e.code != 'unauthorized') rethrow;
    await ref.getMetadata();
  }
  PhotoBytes.instance.remember('fs://$path', png);
  return 'fs://$path';
};
