import '../../data/firestore_errors.dart';
import '../../l10n/rule_messages.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/photo_uploader.dart';
import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// A RECORD'S PHOTOS, LOADED ONLY WHEN ASKED FOR
///
/// The same strip on every record page (a phone in stock, a product, a
/// repair): the photos it has, and empty dashed slots for the ones it does
/// not have yet — so the page shows where pictures go, and an owner can add
/// one there and then.
///
/// **A photo is not downloaded until someone taps it.** A record page is
/// opened many times a day on shop data; pulling every picture each time
/// spends mobile data and the photo host's quota for pictures nobody looked
/// at. A tile says "Tap to view"; the first tap loads it, a second opens it
/// full screen.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({
    super.key,
    required this.photos,
    this.onAdd,
    this.slots = 3,
    this.keyPrefix = 'photo',
    this.title,
  });

  /// The strip's heading; "Photos" when not given.
  final String? title;

  /// Uploaded photos (http addresses). Anything else is ignored: a tile
  /// cannot show a photo it has no address for.
  final List<String> photos;

  /// Saves a newly uploaded photo's address on the record. Null: no
  /// adding here (staff, or a record that cannot change).
  final Future<void> Function(String url)? onAdd;

  /// How many places the strip shows at least, filled or empty.
  final int slots;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final shown = [
      for (final p in photos)
        if (p.startsWith('http')) p,
    ];
    final empty = (slots - shown.length).clamp(onAdd == null ? 0 : 1, slots);
    PhotoUploader? uploader;
    try {
      uploader = context.read<PhotoUploader>();
    } on ProviderNotFoundException {
      uploader = null;
    }
    final canUpload =
        onAdd != null && uploader != null && uploader.isConfigured;

    return Card(
      key: Key('$keyPrefix-strip'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shown.isEmpty
                  ? (title ?? l10n.photos)
                  : '${title ?? l10n.photos} · ${shown.length}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 118,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (i, url) in shown.indexed)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _PhotoTile(key: Key('$keyPrefix-$i'), url: url),
                    ),
                  for (var i = 0; i < empty; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _EmptySlot(
                        key: Key('$keyPrefix-empty-$i'),
                        onTap: canUpload
                            ? () => _add(context, uploader!, onAdd!)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _add(
    BuildContext context,
    PhotoUploader uploader,
    Future<void> Function(String url) onAdd,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final camera = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                key: const Key('photo-take'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => Navigator.of(sheet).pop(true),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.photoTake),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('photo-choose'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => Navigator.of(sheet).pop(false),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.photoChoose),
              ),
            ],
          ),
        ),
      ),
    );
    if (camera == null) return;
    try {
      final url = await uploader.pickAndUpload(camera: camera);
      if (url != null) await onAdd(url);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(ruleTextIn(lang, plainError(e)))),
      );
    }
  }
}

/// One photo: "Tap to view" until tapped, then the picture; tapped again,
/// full screen.
class _PhotoTile extends StatefulWidget {
  const _PhotoTile({super.key, required this.url});

  final String url;

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  bool _load = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppTheme.surfaceCalm,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!_load) {
            setState(() => _load = true);
          } else {
            _openFull(context, widget.url);
          }
        },
        child: SizedBox(
          width: 96,
          height: 118,
          child: _load
              ? Image.network(
                  widget.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppTheme.border,
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_outlined, color: AppTheme.primary),
                    const SizedBox(height: 6),
                    Text(
                      l10n.photoTapToView,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  static void _openFull(BuildContext context, String url) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (page) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 5,
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where a photo can go: dashed, with a camera when one can be added here.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final can = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: CustomPaint(
        painter: _Dashes(),
        child: SizedBox(
          width: 96,
          height: 118,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                can ? Icons.add_a_photo_outlined : Icons.photo_outlined,
                color: can ? AppTheme.primary : AppTheme.border,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  can ? l10n.photoAdd : l10n.photoNoneYet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dashes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashes oldDelegate) => false;
}
