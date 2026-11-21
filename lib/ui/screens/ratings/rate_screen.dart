import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/rating_repository.dart';
import '../../../domain/ratings/rating.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';

/// THE CUSTOMER'S RATING PAGE — `/rate/:token`
///
/// Public, like the scan page: the person opening it is a customer with a
/// WhatsApp message, not a member of staff. So it shows only what the shop
/// already put on their job card — shop, device, job number, first name —
/// and asks one question.
///
/// Three ends, each said plainly: a link that leads nowhere, a job already
/// rated (the first answer stands), and thanks.
class RateScreen extends StatefulWidget {
  const RateScreen({super.key, required this.token});

  final String token;

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  late final Future<Rating?> _rating = context.read<PublicRatings>().fetch(
    widget.token,
  );
  final _comment = TextEditingController();
  int? _stars;
  bool _sending = false;
  bool _sent = false;
  String? _problem;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send(Rating rating) async {
    final l10n = context.l10n;
    final local = validateAnswer(rating, _stars, _comment.text);
    if (local != null) {
      setState(() => _problem = _messageFor(local, l10n));
      return;
    }
    setState(() {
      _sending = true;
      _problem = null;
    });
    try {
      final refusal = await context.read<PublicRatings>().answer(
        widget.token,
        _stars,
        _comment.text,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        if (refusal == null) {
          _sent = true;
        } else {
          _problem = _messageFor(refusal, l10n);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _problem = l10n.rateCouldNotSend;
      });
    }
  }

  String _messageFor(RatingRefusal r, AppLocalizations l10n) => switch (r) {
    RatingRefusal.noStars || RatingRefusal.badStars => l10n.ratePickStars,
    RatingRefusal.commentTooLong => l10n.rateCommentTooLong,
    RatingRefusal.alreadyAnswered => l10n.rateAlreadyAnswered,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rateTitle)),
      body: FutureBuilder<Rating?>(
        future: _rating,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final rating = snap.data;
          if (snap.hasError || rating == null) {
            return _Message(icon: Icons.link_off, text: l10n.rateNotFound);
          }
          if (_sent) {
            return _Message(icon: Icons.favorite, text: l10n.rateThanks);
          }
          if (rating.answered) {
            return _Message(
              icon: Icons.check_circle_outline,
              text: l10n.rateAlreadyAnswered,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (rating.shopName.isNotEmpty)
                Text(rating.shopName, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                [
                  rating.device,
                  if (rating.orderNumber.isNotEmpty)
                    l10n.ratingJob(rating.orderNumber),
                ].where((s) => s.isNotEmpty).join(', '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(l10n.rateHowDidWeDo, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      key: Key('star-$i'),
                      iconSize: 44,
                      tooltip: '$i',
                      onPressed: _sending
                          ? null
                          : () => setState(() {
                              _stars = i;
                              _problem = null;
                            }),
                      icon: Icon(
                        (_stars ?? 0) >= i ? Icons.star : Icons.star_border,
                        color: Colors.amber.shade700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('rate-comment'),
                controller: _comment,
                maxLines: 4,
                maxLength: kRatingCommentMax,
                decoration: InputDecoration(
                  hintText: l10n.rateCommentHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_problem != null) ...[
                const SizedBox(height: 8),
                Text(
                  _problem!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('rate-send'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _sending ? null : () => _send(rating),
                child: Text(l10n.rateSend),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
