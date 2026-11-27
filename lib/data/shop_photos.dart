import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'photo_uploader.dart';

/// PHOTOS IN THE SHOP'S OWN PRIVATE STORAGE (Firebase Storage)
///
/// Why not public links: a bought phone carries photos of the seller's ID
/// card. In Firebase Storage a photo is under its shop
/// (`shops/<shop>/photos/<month>/<n>.jpg`) and storage.rules lets only that
/// shop's signed-in people put or read one — no link opens it for anybody
/// else.
///
/// **What it may cost is capped by the rules, not by this app** (a changed
/// copy of the app could skip any check made here):
/// - one photo is at most [kMaxPhotoBytes] and must be a JPEG (the app aims
///   for [kTargetPhotoBytes]);
/// - each shop has a counter per month (`shops/<shop>/usage/<yyyymm>`) that
///   only ever goes up by one, to at most the shop's limit
///   (`limits/<shop>.photosPerMonth`, set by the app's owner in the console;
///   [kDefaultPhotosPerMonth] when not set);
/// - a photo's number must be one the counter has reached, in the current
///   month, and a photo can never be replaced. So a shop can never store
///   more than limit × [kMaxPhotoBytes] in a month.
///
/// A record keeps `fs://<path>`; [PhotoBytes] loads it with the person's
/// sign-in and keeps a copy on the phone, so a photo is downloaded once.

/// The most one photo may weigh — what storage.rules allows.
const kMaxPhotoBytes = 300 * 1024;

/// What the app shrinks a photo towards, so a shop's storage grows by a
/// predictable amount per photo. [kMaxPhotoBytes] is only the hard stop.
const kTargetPhotoBytes = 120 * 1024;

/// Photos a shop may add in a month unless the app's owner sets more.
const kDefaultPhotosPerMonth = 500;

/// Said when a shop has used its month's photos.
const kErrPhotoLimit =
    "This shop has used this month's photos. Ask the app's owner to raise the limit.";

/// The month a photo is counted in, as storage.rules works it out: UTC,
/// `yyyymm`.
String photoMonthKey(DateTime now) {
  final u = now.toUtc();
  return '${u.year}${u.month.toString().padLeft(2, '0')}';
}

/// The number the next photo takes, or null when [current] has reached
/// [limit].
int? nextPhotoSlot(int current, int limit) =>
    current < 0 ? 1 : (current >= limit ? null : current + 1);

/// A photo address a record can show: one in the shop's storage.
bool isShopPhoto(String value) => value.startsWith('fs://');

/// A photo shrunk towards [targetBytes]: lower quality, then smaller, a few
/// times, keeping the first that reaches the target. When none does, the
/// smallest try is used if it is within [maxBytes]; null if not even that.
Future<Uint8List?> shrinkToFit(
  Uint8List bytes, {
  int targetBytes = kTargetPhotoBytes,
  int maxBytes = kMaxPhotoBytes,
  required Future<Uint8List> Function(Uint8List, int quality, int width)
  compress,
}) async {
  if (bytes.length <= targetBytes) return bytes;
  var smallest = bytes;
  for (final (quality, width) in const [
    (70, 1024),
    (60, 1024),
    (55, 900),
    (50, 800),
    (45, 720),
  ]) {
    final out = await compress(bytes, quality, width);
    if (out.length <= targetBytes) return out;
    if (out.length < smallest.length) smallest = out;
  }
  return smallest.length <= maxBytes ? smallest : null;
}

/// What a photo carries besides the picture (Storage custom metadata), for
/// the details on the full-screen view.
const kPhotoTakenAt = 'takenAt';
const kPhotoTakenBy = 'takenBy';
const kPhotoSource = 'source';
const kPhotoOriginalBytes = 'originalBytes';

class FirebasePhotoUploader implements PhotoUploader {
  FirebasePhotoUploader({
    required this.shopId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final String shopId;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  /// A number taken from the counter whose upload then failed. The counter
  /// never goes down, so the next photo this month uses it rather than
  /// spending another.
  ({String month, int slot})? _unused;

  @override
  bool get isConfigured => shopId.isNotEmpty;

  @override
  Future<String?> pickAndUpload({
    required bool camera,
    PhotoProgress? onProgress,
  }) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (file == null) return null;
    onProgress?.call(PhotoStage.shrinking, null);
    final picked = await file.readAsBytes();
    final bytes = await shrinkToFit(
      picked,
      compress: (b, q, w) => FlutterImageCompress.compressWithList(
        b,
        quality: q,
        minWidth: w,
        minHeight: w,
      ),
    );
    if (bytes == null) {
      throw const PhotoUploadError('The photo is too big. Try again.');
    }
    onProgress?.call(PhotoStage.uploading, null);
    final now = DateTime.now();
    final month = photoMonthKey(now);
    final kept = _unused;
    final slot = kept != null && kept.month == month
        ? kept.slot
        : await _reserveSlot(month);
    _unused = (month: month, slot: slot);
    final path = 'shops/$shopId/photos/$month/$slot.jpg';
    final user = _auth.currentUser;
    final task = _storage
        .ref(path)
        .putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              kPhotoTakenAt: now.toUtc().toIso8601String(),
              kPhotoTakenBy: (user?.displayName ?? '').isNotEmpty
                  ? user!.displayName!
                  : user?.email ?? '',
              kPhotoSource: camera ? 'camera' : 'gallery',
              kPhotoOriginalBytes: '${picked.length}',
            },
          ),
        );
    final progress = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) {
        onProgress?.call(
          PhotoStage.uploading,
          s.bytesTransferred / s.totalBytes,
        );
      }
    }, onError: (Object _) {});
    try {
      await task;
    } finally {
      await progress.cancel();
    }
    _unused = null;
    PhotoBytes.instance.remember('fs://$path', bytes);
    return 'fs://$path';
  }

  /// The next number in this month's counter, taken in one step so two
  /// phones never get the same one. Refused (by the rules too) past the
  /// shop's limit.
  Future<int> _reserveSlot(String month) async {
    final limitDoc = await _db.doc('limits/$shopId').get();
    final limit =
        (limitDoc.data()?['photosPerMonth'] as num?)?.toInt() ??
        kDefaultPhotosPerMonth;
    final counter = _db.doc('shops/$shopId/usage/$month');
    return _db.runTransaction((tx) async {
      final snap = await tx.get(counter);
      final current = (snap.data()?['photos'] as num?)?.toInt() ?? 0;
      final next = nextPhotoSlot(current, limit);
      if (next == null) throw const PhotoUploadError(kErrPhotoLimit);
      tx.set(counter, {'photos': next});
      return next;
    });
  }
}

/// What the full-screen view says about a photo. Anything not known — an
/// older photo uploaded before these were kept, or no internet for the
/// stored details — is null and not shown.
class PhotoDetails {
  const PhotoDetails({
    required this.bytes,
    this.width,
    this.height,
    this.takenAt,
    this.takenBy = '',
    this.source = '',
    this.originalBytes,
  });

  final int bytes;
  final int? width;
  final int? height;
  final DateTime? takenAt;
  final String takenBy;

  /// `camera` or `gallery`.
  final String source;

  /// How big the picture was before the app shrank it.
  final int? originalBytes;

  /// Read from the picture itself and from what Storage keeps with it.
  static Future<PhotoDetails> of(String ref, Uint8List picture) async {
    int? width, height;
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(picture);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      width = descriptor.width;
      height = descriptor.height;
      descriptor.dispose();
      buffer.dispose();
    } catch (_) {
      // Not a picture the phone can read; the size is still known.
    }
    FullMetadata? meta;
    if (ref.startsWith('fs://')) {
      try {
        meta = await FirebaseStorage.instance
            .ref(ref.substring('fs://'.length))
            .getMetadata();
      } catch (_) {
        meta = null;
      }
    }
    final custom = meta?.customMetadata ?? const <String, String>{};
    return PhotoDetails(
      bytes: picture.length,
      width: width,
      height: height,
      takenAt:
          DateTime.tryParse(custom[kPhotoTakenAt] ?? '')?.toLocal() ??
          meta?.timeCreated?.toLocal(),
      takenBy: custom[kPhotoTakenBy] ?? '',
      source: custom[kPhotoSource] ?? '',
      originalBytes: int.tryParse(custom[kPhotoOriginalBytes] ?? ''),
    );
  }
}

/// `58 KB`, `2.1 MB` — a file size as the counter would say it.
String photoSizeText(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).ceil()} KB';

/// Loads `fs://` photos with the person's sign-in, and keeps them: in
/// memory for this run and in the phone's cache folder after, so a photo is
/// downloaded once, not every time a page opens.
class PhotoBytes {
  PhotoBytes._();
  static final instance = PhotoBytes._();

  final _memory = <String, Uint8List>{};
  final _loading = <String, Future<Uint8List?>>{};

  void remember(String ref, Uint8List bytes) {
    _memory[ref] = bytes;
    _writeDisk(ref, bytes);
  }

  Uint8List? cached(String ref) => _memory[ref];

  Future<Uint8List?> load(String ref) {
    final hit = _memory[ref];
    if (hit != null) return Future.value(hit);
    return _loading.putIfAbsent(ref, () async {
      try {
        final disk = await _readDisk(ref);
        if (disk != null) return _memory[ref] = disk;
        final data = await FirebaseStorage.instance
            .ref(ref.substring('fs://'.length))
            .getData(kMaxPhotoBytes + 1024);
        if (data == null) return null;
        remember(ref, data);
        return data;
      } finally {
        // A failed load can be tried again from the page.
        _loading.remove(ref);
      }
    });
  }

  static String _fileName(String ref) =>
      ref.substring('fs://'.length).replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  Future<File?> _file(String ref) async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationCacheDirectory();
      return File('${dir.path}/shop_photos/${_fileName(ref)}');
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _readDisk(String ref) async {
    final f = await _file(ref);
    if (f == null || !await f.exists()) return null;
    return f.readAsBytes();
  }

  Future<void> _writeDisk(String ref, Uint8List bytes) async {
    try {
      final f = await _file(ref);
      if (f == null) return;
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes, flush: true);
    } catch (_) {
      // No cache folder: the photo is just downloaded again next time.
    }
  }
}
