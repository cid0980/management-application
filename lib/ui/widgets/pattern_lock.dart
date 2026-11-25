import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// THE UNLOCK PATTERN
///
/// Ported from the French Mobiles Flutter port (`ui/widgets/pattern_lock.dart`)
/// into this app's colours, languages and stored format.
///
/// Drawn the way the customer's phone draws it — a 3 × 3 grid of joined dots —
/// because the person at the counter is copying it off the phone in front of
/// them. Typing "1-2-3-6-9" asked them to turn a shape into numbers in their
/// head, which is exactly where it went wrong.
///
/// The value is what this app has always stored for a pattern: the dots
/// numbered 1–9 left to right, top to bottom, joined with dashes — `1-2-3-6-9`
/// — so old orders, the job card and the technician all read it the same way.
class PatternLock extends StatefulWidget {
  const PatternLock({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 240,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final double size;

  /// `1-2-3-6-9` -> dot indices 0, 1, 2, 5, 8. Anything unreadable is dropped
  /// rather than guessed at.
  static List<int> parse(String value) => [
    for (final part in value.split(RegExp(r'[-,\s]+')))
      if (int.tryParse(part) case final n? when n >= 1 && n <= 9) n - 1,
  ];

  static String format(List<int> dots) => dots.map((i) => i + 1).join('-');

  @override
  State<PatternLock> createState() => _PatternLockState();
}

class _PatternLockState extends State<PatternLock> {
  late final List<int> _dots = PatternLock.parse(widget.value);
  Offset? _finger;

  Offset _centre(int index, double cell) =>
      Offset(cell * (index % 3 + 0.5), cell * (index ~/ 3 + 0.5));

  void _hit(Offset at, double cell) {
    for (var i = 0; i < 9; i++) {
      if (!_dots.contains(i) &&
          (at - _centre(i, cell)).distance < cell * 0.34) {
        setState(() => _dots.add(i));
        widget.onChanged(PatternLock.format(_dots));
        return;
      }
    }
  }

  void _clear() {
    setState(_dots.clear);
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cell = widget.size / 3;
    return Column(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          // Claims the finger at once, so drawing never scrolls the form.
          child: RawGestureDetector(
            key: const Key('pattern-lock'),
            gestures: {
              _GridPan: GestureRecognizerFactoryWithHandlers<_GridPan>(
                _GridPan.new,
                (r) {
                  r.onDown = (d) {
                    // A new stroke starts a new pattern.
                    if (_dots.isNotEmpty) _clear();
                    _hit(d.localPosition, cell);
                  };
                  r.onUpdate = (d) {
                    setState(() => _finger = d.localPosition);
                    _hit(d.localPosition, cell);
                  };
                  r.onEnd = (_) => setState(() => _finger = null);
                },
              ),
            },
            child: CustomPaint(
              painter: _Painter(
                dots: _dots,
                finger: _finger,
                cell: cell,
                line: theme.colorScheme.primary,
                idle: AppTheme.borderSubtle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _dots.isEmpty ? l10n.patternDraw : PatternLock.format(_dots),
              style: theme.textTheme.titleSmall,
            ),
            if (_dots.isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                key: const Key('pattern-clear'),
                onPressed: _clear,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.patternClear),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _GridPan extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _Painter extends CustomPainter {
  _Painter({
    required this.dots,
    required this.finger,
    required this.cell,
    required this.line,
    required this.idle,
  });

  final List<int> dots;
  final Offset? finger;
  final double cell;
  final Color line;
  final Color idle;

  Offset _c(int i) => Offset(cell * (i % 3 + 0.5), cell * (i ~/ 3 + 0.5));

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = line
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (dots.length > 1) {
      final path = Path()..moveTo(_c(dots.first).dx, _c(dots.first).dy);
      for (final i in dots.skip(1)) {
        path.lineTo(_c(i).dx, _c(i).dy);
      }
      canvas.drawPath(path, stroke);
    }
    if (finger != null && dots.isNotEmpty) {
      canvas.drawLine(_c(dots.last), finger!, stroke);
    }
    for (var i = 0; i < 9; i++) {
      final on = dots.contains(i);
      canvas.drawCircle(_c(i), on ? 16 : 10, Paint()..color = on ? line : idle);
      if (on) {
        // The order it was drawn in, so a start point is never ambiguous.
        final text = TextPainter(
          text: TextSpan(
            text: '${dots.indexOf(i) + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, _c(i) - Offset(text.width / 2, text.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_Painter old) => true;
}

/// A pattern drawn, not entered: the nine dots, the lines between them in
/// order, the first dot ringed — what the repair page shows the technician.
class PatternView extends StatelessWidget {
  const PatternView({super.key, required this.value, this.size = 120});

  final String value;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _PatternViewPainter(PatternLock.parse(value))),
  );
}

class _PatternViewPainter extends CustomPainter {
  _PatternViewPainter(this.dots);

  final List<int> dots;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 3;
    Offset at(int i) => Offset(cell * (i % 3 + 0.5), cell * (i ~/ 3 + 0.5));
    final line = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var k = 1; k < dots.length; k++) {
      canvas.drawLine(at(dots[k - 1]), at(dots[k]), line);
    }
    for (var i = 0; i < 9; i++) {
      final used = dots.contains(i);
      canvas.drawCircle(
        at(i),
        used ? 7 : 5,
        Paint()..color = used ? AppTheme.primary : AppTheme.borderSubtle,
      );
    }
    if (dots.isNotEmpty) {
      canvas.drawCircle(
        at(dots.first),
        12,
        Paint()
          ..color = AppTheme.lime
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_PatternViewPainter old) => old.dots.join() != dots.join();
}
