import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Android and iPhone read text; anything else does not.
bool get canReadText => Platform.isAndroid || Platform.isIOS;

/// Opens the camera for one photo and returns every word read in it, line by
/// line. Null when the photo was cancelled.
Future<String?> readTextWithCamera() async {
  final photo = await ImagePicker().pickImage(
    source: ImageSource.camera,
    // Big enough for small print on a sticker, small enough to read fast.
    maxWidth: 2400,
    imageQuality: 92,
  );
  if (photo == null) return null;
  final reader = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final read = await reader.processImage(InputImage.fromFilePath(photo.path));
    return read.text;
  } finally {
    await reader.close();
    // The photo was only for reading; it is not kept.
    try {
      await File(photo.path).delete();
    } on FileSystemException {
      // Already gone, or not ours to delete: nothing to do.
    }
  }
}
