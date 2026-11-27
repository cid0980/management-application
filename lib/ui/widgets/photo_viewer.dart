import 'package:flutter/material.dart';

import '../../data/shop_photos.dart';
import '../../l10n/l10n.dart';
import 'shop_photo_image.dart';

/// A PHOTO, FULL SCREEN
///
/// Pinch or double-tap to zoom, drag to look around, and its details along
/// the bottom: how big it is, when and by whom it was taken, and from where.
///
/// The phone's Back and the close button both close it, back to the page it
/// was opened from; a [BackButtonListener] makes sure Back means this page
/// and never the one under it.
Future<void> openPhotoViewer(BuildContext context, String ref) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PhotoViewerPage(ref: ref),
      ),
    );

class PhotoViewerPage extends StatefulWidget {
  const PhotoViewerPage({super.key, required this.ref});

  /// The photo's address (`fs://…`).
  final String ref;

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  final _zoom = TransformationController();
  Offset _doubleTapAt = Offset.zero;
  bool _showDetails = true;
  late final Future<PhotoDetails?> _details = _loadDetails();

  Future<PhotoDetails?> _loadDetails() async {
    final bytes = await PhotoBytes.instance.load(widget.ref);
    if (bytes == null) return null;
    return PhotoDetails.of(widget.ref, bytes);
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  /// Double-tap: zoomed in on where the finger was, or back to the whole
  /// photo.
  void _toggleZoom() {
    if (_zoom.value.getMaxScaleOnAxis() > 1.01) {
      _zoom.value = Matrix4.identity();
      return;
    }
    const scale = 2.5;
    final p = _doubleTapAt;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BackButtonListener(
      onBackButtonPressed: () async {
        _close();
        return true;
      },
      child: Scaffold(
        key: const Key('photo-viewer'),
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            key: const Key('photo-close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close),
            onPressed: _close,
          ),
          title: Text(l10n.photoTitle),
          actions: [
            IconButton(
              key: const Key('photo-details-toggle'),
              tooltip: l10n.photoDetails,
              icon: Icon(
                _showDetails ? Icons.info : Icons.info_outline,
                color: Colors.white,
              ),
              onPressed: () => setState(() => _showDetails = !_showDetails),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
                onDoubleTap: _toggleZoom,
                child: InteractiveViewer(
                  key: const Key('photo-zoom'),
                  transformationController: _zoom,
                  minScale: 1,
                  maxScale: 6,
                  child: SizedBox.expand(
                    child: ShopPhotoImage(widget.ref, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            if (_showDetails)
              _DetailsPanel(details: _details, hint: l10n.photoZoomHint),
          ],
        ),
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.details, required this.hint});

  final Future<PhotoDetails?> details;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const label = TextStyle(color: Colors.white60, fontSize: 13);
    const value = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    Widget row(String name, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(name, style: label)),
          Expanded(child: Text(text, style: value)),
        ],
      ),
    );
    return Container(
      key: const Key('photo-details'),
      width: double.infinity,
      color: const Color(0xFF161616),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SafeArea(
        top: false,
        child: FutureBuilder<PhotoDetails?>(
          future: details,
          builder: (context, snap) {
            final d = snap.data;
            final m = MaterialLocalizations.of(context);
            final taken = d?.takenAt;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hint, style: label),
                if (snap.connectionState == ConnectionState.done && d == null)
                  row(l10n.photoDetails, l10n.photoLoadFailed),
                if (d != null) ...[
                  row(l10n.photoFileSize, photoSizeText(d.bytes)),
                  if (d.width != null && d.height != null)
                    row(l10n.photoPixels, '${d.width} × ${d.height}'),
                  if (taken != null)
                    row(
                      l10n.photoTakenAt,
                      '${m.formatMediumDate(taken)}, '
                      '${m.formatTimeOfDay(TimeOfDay.fromDateTime(taken))}',
                    ),
                  if (d.takenBy.isNotEmpty) row(l10n.photoTakenBy, d.takenBy),
                  if (d.source.isNotEmpty)
                    row(
                      l10n.photoFrom,
                      d.source == 'camera'
                          ? l10n.photoFromCamera
                          : l10n.photoFromGallery,
                    ),
                  if (d.originalBytes != null)
                    row(
                      l10n.photoOriginalSize,
                      photoSizeText(d.originalBytes!),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(l10n.photoPrivate, style: label)),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
