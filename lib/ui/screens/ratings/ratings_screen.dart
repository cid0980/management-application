import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/rating_repository.dart';
import '../../../domain/ratings/rating.dart';
import '../../../l10n/l10n.dart';
import '../../widgets/loading.dart';

/// WHAT CUSTOMERS SAID — admin only
///
/// The average counts answers only (a link nobody opened is not a zero), and
/// the response rate is shown next to it, because an average of five from two
/// answers out of forty links is a different story from five out of forty.
class RatingsScreen extends StatelessWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final repo = context.watch<RatingRepository>();
    if (repo.loading && repo.ratings.isEmpty) {
      return LoadingWords(first: context.l10n.loadingRatings);
    }
    if (repo.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(repo.error!, textAlign: TextAlign.center),
        ),
      );
    }
    final all = sortedForAdmin(repo.ratings);
    if (all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_outline, size: 48),
              const SizedBox(height: 12),
              Text(l10n.ratingsEmpty, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    final s = summarize(all);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ratingsAverage,
                      style: theme.textTheme.labelLarge,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.average == null
                              ? '–'
                              : s.average!.toStringAsFixed(1),
                          key: const Key('ratings-average'),
                          style: theme.textTheme.headlineMedium,
                        ),
                        if (s.average != null)
                          Icon(
                            Icons.star_rounded,
                            size: 28,
                            color: Colors.amber.shade700,
                          ),
                      ],
                    ),
                    Text(
                      s.answered == 0
                          ? l10n.ratingsNoAnswerYet
                          : l10n.ratingsSummary(s.answered, s.sent),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      for (var star = 5; star >= 1; star--)
                        _Bar(
                          star: star,
                          count: s.byStars[star - 1],
                          of: s.answered,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final r in all) _RatingTile(rating: r),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.star, required this.count, required this.of});

  final int star;
  final int count;
  final int of;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(width: 18, child: Text('$star')),
        Expanded(
          child: LinearProgressIndicator(
            value: of == 0 ? 0 : count / of,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 28, child: Text('$count', textAlign: TextAlign.end)),
      ],
    ),
  );
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({required this.rating});

  final Rating rating;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = [
      rating.customerFirstName,
      rating.device,
    ].where((s) => s.isNotEmpty).join(', ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title.isEmpty ? l10n.ratingJob(rating.orderNumber) : title),
      subtitle: Text(
        rating.answered
            ? (rating.comment.isEmpty
                  ? l10n.ratingJob(rating.orderNumber)
                  : rating.comment)
            : l10n.ratingWaiting,
      ),
      trailing: rating.answered
          ? Row(
              key: Key('rating-stars-${rating.stars}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 5; i++)
                  Icon(
                    i < rating.stars!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 18,
                    color: Colors.amber.shade800,
                  ),
              ],
            )
          : const Icon(Icons.hourglass_empty, size: 20),
    );
  }
}
