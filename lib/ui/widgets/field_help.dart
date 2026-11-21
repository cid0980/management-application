import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// THE "?" NEXT TO EVERY FIELD
///
/// Many of the people at the counter did not go far in school, and a label
/// like "IMEI" or "Asking price" means nothing on its own. Every field gets a
/// "?" that opens a short, plain explanation with an example — what goes
/// here, where to find it, why the shop wants it.
///
/// It opens a small bubble right beside the "?", not a page or a sheet: the
/// field stays in view, so the explanation and the thing it explains are read
/// together. It stays until it is tapped away — a tooltip that fades on a
/// timer is gone before a slow reader is done with it.
class HelpButton extends StatefulWidget {
  const HelpButton({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  State<HelpButton> createState() => _HelpButtonState();
}

class _HelpButtonState extends State<HelpButton> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();

  /// Opens upward when the "?" sits in the bottom half of the screen, so the
  /// bubble never runs off the bottom or under the keyboard.
  bool _above = false;

  void _toggle() {
    if (_portal.isShowing) {
      _portal.hide();
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    final screen = MediaQuery.sizeOf(context).height;
    if (box != null && box.hasSize) {
      final y = box.localToGlobal(Offset.zero).dy;
      _above = y > screen / 2;
    }
    _portal.show();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (overlay) => _Bubble(
          link: _link,
          above: _above,
          title: widget.title,
          body: widget.body,
          onClose: _portal.hide,
        ),
        child: IconButton(
          tooltip: context.l10n.helpWhatIsThis,
          // Teal, the supporting colour: it reads as "tap me for help" and
          // not as part of the value typed in the field. The icon is small;
          // the IconButton keeps the tap area at 48.
          icon: Icon(Icons.help, color: scheme.secondary),
          onPressed: _toggle,
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.link,
    required this.above,
    required this.title,
    required this.body,
    required this.onClose,
  });

  final LayerLink link;
  final bool above;
  final String title;
  final String body;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = (MediaQuery.sizeOf(context).width - 32).clamp(0.0, 320.0);
    return Stack(
      children: [
        // Any tap outside the bubble closes it, and is swallowed: a tap meant
        // to dismiss help must not also press whatever was underneath.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: above ? Alignment.topRight : Alignment.bottomRight,
          followerAnchor: above ? Alignment.bottomRight : Alignment.topRight,
          child: GestureDetector(
            onTap: onClose,
            // Soft teal with dark blue text: the system's colour for a tip.
            child: Material(
              color: theme.colorScheme.secondaryContainer,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.secondary),
              ),
              child: Container(
                width: width,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.close,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A section or row title with its "?" beside it, for the things that are not
/// text fields — a switch, the checklist, the photos.
class HelpTitle extends StatelessWidget {
  const HelpTitle({
    super.key,
    required this.text,
    required this.help,
    this.icon,
    this.style,
  });

  final String text;
  final String help;
  final IconData? icon;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(text, style: style ?? theme.textTheme.titleMedium),
        ),
        HelpButton(title: text, body: help),
      ],
    );
  }
}
