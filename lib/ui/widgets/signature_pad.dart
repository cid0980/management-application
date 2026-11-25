import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// A SIGNATURE
///
/// Ported from the French Mobiles Flutter port (`ui/widgets/signature_pad.dart`)
/// into this app's colours and languages.
///
/// A second-hand purchase is a legal declaration, so the seller signs it with
/// a finger. The strokes are kept as a list and drawn with a CustomPainter,
/// which is what lets them be turned into a PNG for the record and the printed
/// form.
///
/// Gestures are caught on the pad only, so the form behind it still scrolls
/// everywhere else.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.onSigned,
    this.height = 180,
    this.label,
    this.initiallySigned = false,
  });

  /// Called with the signature as a PNG data URL once a stroke is finished,
  /// and with null when it is cleared.
  final ValueChanged<String?> onSigned;
  final double height;
  final String? label;

  /// A signature is already on the record (an edit, or a restored draft).
  /// The strokes are not kept, so the pad says so instead of looking blank.
  final bool initiallySigned;

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  late bool _onRecord = widget.initiallySigned;
  double _width = 320;

  bool get isEmpty => _strokes.isEmpty && !_onRecord;

  void clear() {
    setState(() {
      _strokes.clear();
      _onRecord = false;
    });
    widget.onSigned(null);
  }

  /// The signature as a transparent PNG, or null when nothing was drawn.
  ///
  /// Twice the screen size: sharp enough to print, small enough to sit on the
  /// phone's record without making it heavy.
  Future<Uint8List?> toPng({double pixelRatio = 2}) async {
    if (_strokes.isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    _StrokePainter(
      _strokes,
      Colors.black,
    ).paint(canvas, Size(_width, widget.height));
    final image = await recorder.endRecording().toImage(
      (_width * pixelRatio).round(),
      (widget.height * pixelRatio).round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _report() async {
    final png = await toPng();
    if (!mounted) return;
    widget.onSigned(
      png == null ? null : 'data:image/png;base64,${base64Encode(png)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final signed = _strokes.isNotEmpty || _onRecord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label ?? l10n.signatureLabel,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (signed)
              TextButton.icon(
                key: const Key('signature-clear'),
                onPressed: clear,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.signatureClear),
              ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, box) {
            _width = box.maxWidth;
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                key: const Key('signature-pad'),
                height: widget.height,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: signed ? AppTheme.action : AppTheme.borderSubtle,
                    width: signed ? 2 : 1,
                  ),
                ),
                // Claims the finger the moment it lands. With a plain pan
                // detector the form's scroll won any stroke that went mostly
                // downwards, so half a signature scrolled the page instead.
                child: RawGestureDetector(
                  gestures: {
                    _InkPanRecognizer:
                        GestureRecognizerFactoryWithHandlers<_InkPanRecognizer>(
                          _InkPanRecognizer.new,
                          (r) {
                            r.onStart = (d) => setState(() {
                              _onRecord = false;
                              _strokes.add([d.localPosition]);
                            });
                            r.onUpdate = (d) => setState(
                              () => _strokes.last.add(d.localPosition),
                            );
                            r.onEnd = (_) => _report();
                          },
                        ),
                  },
                  child: CustomPaint(
                    painter: _StrokePainter(_strokes, AppTheme.text),
                    child: _strokes.isEmpty
                        ? Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _onRecord ? Icons.check_circle : Icons.draw,
                                  color: _onRecord
                                      ? context.shopColors.good
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _onRecord
                                      ? l10n.signatureOnRecord
                                      : l10n.signatureHint,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.expand(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A pan that wins as soon as the finger touches down, so a scrolling page
/// behind the pad never takes the stroke.
class _InkPanRecognizer extends PanGestureRecognizer {
  _InkPanRecognizer() {
    dragStartBehavior = DragStartBehavior.down;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.strokes, this.colour);

  final List<List<Offset>> strokes;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.6, Paint()..color = colour);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) => true;
}

/// THE SIGNATURE ON A FORM: A PREVIEW, SIGNED FULL SCREEN
///
/// Signing on a pad inside a long scrolling form put the line away from the
/// finger: the page moved under it — the keyboard closing as the pad was
/// touched, the form scrolling to a field — and the stroke landed where the
/// pad used to be. So the form only shows the signature (or "Tap to sign"),
/// and signing happens on a page of its own: nothing scrolls, no keyboard,
/// a big pad, Clear and Done.
class SignatureField extends StatelessWidget {
  const SignatureField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.required = false,
    this.error,
  });

  /// A PNG data URL, a marker that a signature is on record, or null.
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? label;
  final bool required;
  final String? error;

  /// Tests only: signs without drawing.
  @visibleForTesting
  static Future<String?> Function(BuildContext context)? debugSigner;

  Future<void> _sign(BuildContext context) async {
    final signer = debugSigner;
    final title = label ?? context.l10n.signatureLabel;
    final signed = signer != null
        ? await signer(context)
        : await signFullScreen(context, title: title);
    if (signed != null) onChanged(signed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final v = value ?? '';
    final signed = v.isNotEmpty;
    Uint8List? png;
    if (v.startsWith('data:image')) {
      try {
        png = base64Decode(v.substring(v.indexOf(',') + 1));
      } catch (_) {
        png = null;
      }
    }
    final bad = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label ?? l10n.signatureLabel,
                  children: [
                    if (required)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ],
                ),
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (signed)
              TextButton.icon(
                key: const Key('signature-clear'),
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.signatureClear),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Material(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: bad
                  ? theme.colorScheme.error
                  : signed
                  ? AppTheme.action
                  : AppTheme.border,
              width: bad || signed ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('signature-pad'),
            onTap: () => _sign(context),
            child: SizedBox(
              height: 140,
              child: png != null
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.memory(png, fit: BoxFit.contain),
                    )
                  : Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            signed ? Icons.check_circle : Icons.draw,
                            color: signed
                                ? context.shopColors.good
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            signed
                                ? l10n.signatureOnRecord
                                : l10n.signatureTapToSign,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('signature-fullscreen'),
          onPressed: () => _sign(context),
          icon: const Icon(Icons.fullscreen),
          label: Text(signed ? l10n.signatureClear : l10n.signatureFullScreen),
        ),
        if (bad)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// A page of its own for signing: a big pad that does not move, Clear, and
/// Done. Returns the signature as a PNG data URL, or null if left unsigned.
Future<String?> signFullScreen(BuildContext context, {required String title}) {
  // No keyboard up while signing: it closing mid-stroke moves the page.
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _SignPage(title: title),
    ),
  );
}

class _SignPage extends StatefulWidget {
  const _SignPage({required this.title});

  final String title;

  @override
  State<_SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<_SignPage> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              key: const Key('signature-done'),
              onPressed: _value == null
                  ? null
                  : () => Navigator.of(context).pop(_value),
              child: Text(l10n.signatureDone),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: LayoutBuilder(
            builder: (context, box) => SignaturePad(
              key: const Key('signature-full-pad'),
              height: (box.maxHeight - 48).clamp(160, 2000).toDouble(),
              label: l10n.signatureHint,
              onSigned: (v) => setState(() => _value = v),
            ),
          ),
        ),
      ),
    );
  }
}
