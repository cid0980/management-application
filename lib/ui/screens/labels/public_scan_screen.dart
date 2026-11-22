import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/label_repository.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';

/// THE PUBLIC SCAN PAGE — `/scan/:labelNumber`
///
/// What a label's printed QR code points at. **Public**, deliberately: a scan
/// has to work in the hand of someone who has never signed in, which is the
/// whole point of printing it on a sticker. A customer can point a phone at
/// their own job card.
///
/// Because it is public it is a **summary**, and that is the one place in the
/// app where a summary is the right answer — the opposite of the in-app
/// scanner, which opens the record itself because staff have something to do
/// about it.
///
/// So this page shows what is on the sticker and nothing more. No price the
/// shop paid, no seller, no margin, no customer details beyond what is already
/// printed on the thing in their hand.
class PublicScanScreen extends StatefulWidget {
  const PublicScanScreen({super.key, required this.labelNumber});

  final String labelNumber;

  @override
  State<PublicScanScreen> createState() => _PublicScanScreenState();
}

class _PublicScanScreenState extends State<PublicScanScreen> {
  /// An older label is not kept on the phone: fetched once, then [resolve]
  /// finds it.
  bool _fetching = false;
  bool _fetched = false;

  void _fetchOnce(LabelRepository repo, int number) {
    if (_fetched) return;
    _fetched = true;
    _fetching = true;
    repo.fetch(number).catchError((Object _) => null).whenComplete(() {
      if (mounted) setState(() => _fetching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelNumber = widget.labelNumber;
    final number = int.tryParse(labelNumber.trim());
    final repo = context.watch<LabelRepository>();
    final view = number == null ? null : repo.resolve(number);
    if (view == null && number != null && !_fetched) {
      _fetchOnce(repo, number);
    }
    if (view == null && _fetching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (view == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.help_outline, size: 40),
              const SizedBox(height: 12),
              Text(
                context.l10n.labelNamed(labelNumber),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.nothingRegisteredUnder,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          context.l10n.labelNamed('${view.entry.number}'),
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        Text(
          view.title.isEmpty ? 'French Mobiles' : view.title,
          style: theme.textTheme.headlineSmall,
        ),
        if (view.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(view.subtitle),
        ],
        const SizedBox(height: 16),
        if (view.entry.kind != null)
          _Row(
            context.l10n.whatThisIs,
            labelKindLabel(context, view.entry.kind),
          ),
        if (view.price != null) _Row(context.l10n.price, '₹${view.price}'),
        if (view.status.isNotEmpty) _Row(context.l10n.status, view.status),
        const SizedBox(height: 24),
        Text(
          // Said plainly, because the alternative is a customer reading a
          // stale price off a sticker and the shop arguing about it.
          view.isStale
              ? context.l10n.someDetailsChanged
              : context.l10n.shownAsRecorded,
          style: theme.textTheme.bodySmall,
        ),
        if (!view.recordExists)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.l10n.askAtTheCounter,
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
