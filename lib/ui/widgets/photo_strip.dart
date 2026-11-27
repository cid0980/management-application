import '../../data/firestore_errors.dart';
import '../../l10n/rule_messages.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/photo_uploader.dart';
import '../../data/shop_photos.dart';
import 'photo_viewer.dart';
import 'shop_photo_image.dart';
import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// A RECORD'S PHOTOS, LOADED ONLY WHEN ASKED FOR
///
/// The same strip on every record page (a phone in stock, a product, a
/// repair) and on the repair form: the photos it has, and empty dashed slots
/// for the ones it does not have yet — so the page shows where pictures go,
/// and one can be added there and then.
///
/// **A photo is not downloaded until someone taps it.** A record page is
/// opened many times a day on shop data; pulling every picture each time
/// spends mobile data and the storage quota for pictures nobody looked at. A
/// tile says "Tap to view"; a tap opens it full screen (photo_viewer.dart),
/// and the tile shows it from then on.
///
/// **An upload says what it is doing.** Taking a photo, shrinking it and
/// sending it take a few seconds on shop wifi; the slot shows each step and
/// how far the upload has got, then "Photo saved".
class PhotoStrip extends StatefulWidget {
  const PhotoStrip({
    super.key,
    required this.photos,
    this.onAdd,
    this.onRemove,
    this.slots = 3,
    this.keyPrefix = 'photo',
    this.title,
  });

  /// The strip's heading; "Photos" when not given.
  final String? title;

  /// Uploaded photos (`fs://` addresses). Anything else is ignored: a tile
  /// cannot show a photo it has no address for.
  final List<String> photos;

  /// Saves a newly uploaded photo's address on the record. Null: no
  /// adding here (staff, or a record that cannot change).
  final Future<void> Function(String url)? onAdd;

  /// Takes a photo off (the repair form, before it is saved). Null: photos
  /// cannot be removed here.
  final void Function(String url)? onRemove;

  /// How many places the strip shows at least, filled or empty.
  final int slots;
  final String keyPrefix;

  @override
  State<PhotoStrip> createState() => _PhotoStripState();
}

class _PhotoStripState extends State<PhotoStrip> {
  /// The upload under way, if any: its step and how far it has got.
  PhotoStage? _stage;
  double? _fraction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final shown = [
      for (final p in widget.photos)
        if (isShopPhoto(p)) p,
    ];
    final uploading = _stage != null;
    final empty = (widget.slots - shown.length - (uploading ? 1 : 0)).clamp(
      widget.onAdd == null || uploading ? 0 : 1,
      widget.slots,
    );
    PhotoUploader? uploader;
    try {
      uploader = context.read<PhotoUploader>();
    } on ProviderNotFoundException {
      uploader = null;
    }
    final canUpload =
        widget.onAdd != null &&
        uploader != null &&
        uploader.isConfigured &&
        !uploading;
    final title = widget.title ?? l10n.photos;

    return Card(
      key: Key('${widget.keyPrefix}-strip'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shown.isEmpty ? title : '$title · ${shown.length}',
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
                      child: _PhotoTile(
                        key: Key('${widget.keyPrefix}-$i'),
                        url: url,
                        onRemove: widget.onRemove == null
                            ? null
                            : () => widget.onRemove!(url),
                      ),
                    ),
                  if (uploading)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _UploadingTile(
                        key: Key('${widget.keyPrefix}-uploading'),
                        stage: _stage!,
                        fraction: _fraction,
                      ),
                    ),
                  for (var i = 0; i < empty; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _EmptySlot(
                        key: Key('${widget.keyPrefix}-empty-$i'),
                        onTap: canUpload ? () => _add(uploader!) : null,
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

  Future<void> _add(PhotoUploader uploader) async {
    final messenger = ScaffoldMessenger.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final camera = await pickPhotoSource(context);
    if (camera == null || !mounted) return;
    try {
      final url = await uploader.pickAndUpload(
        camera: camera,
        onProgress: (stage, fraction) {
          if (mounted) {
            setState(() {
              _stage = stage;
              _fraction = fraction;
            });
          }
        },
      );
      if (url != null) {
        await widget.onAdd!(url);
        messenger.showSnackBar(SnackBar(content: Text(l10n.photoSaved)));
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(ruleTextIn(lang, plainError(e)))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _stage = null;
          _fraction = null;
        });
      }
    }
  }
}

/// Camera or gallery: true for the camera, null when the person closed it.
Future<bool?> pickPhotoSource(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<bool>(
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
}

/// The slot of a photo on its way: which step, and how far.
class _UploadingTile extends StatelessWidget {
  const _UploadingTile({super.key, required this.stage, this.fraction});

  final PhotoStage stage;
  final double? fraction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = fraction;
    final text = switch (stage) {
      PhotoStage.shrinking => l10n.photoShrinking,
      PhotoStage.uploading when f != null => l10n.photoUploading(
        (f * 100).round(),
      ),
      PhotoStage.uploading => l10n.photoUploadingStart,
    };
    return Container(
      width: 96,
      height: 118,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCalm,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              value: stage == PhotoStage.uploading ? f : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One photo: "Tap to view" until opened, the picture after. A tap opens
/// it full screen.
class _PhotoTile extends StatefulWidget {
  const _PhotoTile({super.key, required this.url, this.onRemove});

  final String url;
  final VoidCallback? onRemove;

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Shown as a picture once it is on the phone (opened, or just taken).
    final here = PhotoBytes.instance.cached(widget.url) != null;
    return SizedBox(
      width: 96,
      height: 118,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: AppTheme.surfaceCalm,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  await openPhotoViewer(context, widget.url);
                  if (mounted) setState(() {});
                },
                child: here
                    ? ShopPhotoImage(widget.url)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            color: AppTheme.primary,
                          ),
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
          ),
          if (widget.onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: IconButton.filledTonal(
                key: Key('${(widget.key as ValueKey<String>?)?.value}-remove'),
                tooltip: l10n.photoRemove,
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                icon: const Icon(Icons.close),
                onPressed: widget.onRemove,
              ),
            ),
        ],
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
