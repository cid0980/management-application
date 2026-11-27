import 'package:flutter/material.dart';

import '../../data/shop_photos.dart';
import '../theme/app_theme.dart';

/// A record's photo in the shop's private storage (`fs://`, loaded with the
/// person's sign-in and kept on the phone — see shop_photos.dart).
class ShopPhotoImage extends StatelessWidget {
  const ShopPhotoImage(this.ref, {super.key, this.fit = BoxFit.cover});

  final String ref;
  final BoxFit fit;

  static const _broken = Center(
    child: Icon(Icons.broken_image_outlined, color: AppTheme.border),
  );
  static const _spinner = Center(
    child: SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!ref.startsWith('fs://')) return _broken;
    final hit = PhotoBytes.instance.cached(ref);
    if (hit != null) return Image.memory(hit, fit: fit);
    return FutureBuilder(
      future: PhotoBytes.instance.load(ref),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _spinner;
        final bytes = snap.data;
        if (snap.hasError || bytes == null) return _broken;
        return Image.memory(bytes, fit: fit);
      },
    );
  }
}
