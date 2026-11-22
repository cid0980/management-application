/// READING PRINTED NUMBERS WITH THE CAMERA
///
/// For an IMEI or serial with no barcode — a *#06# screen that shows only the
/// digits, an iPhone's Settings › About, a sticker — the camera takes a photo
/// and Google's on-device text reading (ML Kit, no internet needed) reads the
/// words in it. `codesInText` then picks out the IMEIs and serials.
///
/// Phones only: the web preview has no text reading, and [canReadText] says
/// so, so the button is not offered there.
library;

export 'text_reader_none.dart' if (dart.library.io) 'text_reader_mlkit.dart';
