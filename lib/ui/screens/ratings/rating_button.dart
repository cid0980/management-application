import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/auth_state.dart';
import '../../../data/rating_repository.dart';
import '../../../data/settings_repository.dart';
import '../../../domain/common/contact_links.dart';
import '../../../domain/ratings/rating.dart';
import '../../../domain/service/service_order.dart';
import '../../../l10n/l10n.dart';

/// "Ask for a rating" on a finished job.
///
/// Asking twice gives the same link — one link per job — so the button is
/// safe to press again when the customer says they never got the message.
/// The link goes out on WhatsApp with a message already written; with no
/// WhatsApp-able number it is copied instead, and with no public web address
/// in Settings nothing is sent and the page says what to set.
///
/// Draws nothing when the app has no ratings store above it, so screens
/// pumped bare in a test are unaffected.
class RatingButton extends StatelessWidget {
  const RatingButton({super.key, required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    RatingRepository? repo;
    try {
      repo = context.watch<RatingRepository>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    if (!canRequestRating(order)) return const SizedBox.shrink();
    final l10n = context.l10n;
    final existing = repo.forOrder(order.id);
    if (existing != null && existing.answered) {
      return OutlinedButton.icon(
        key: const Key('rating-received'),
        onPressed: null,
        icon: const Icon(Icons.star),
        label: Text(l10n.ratingReceived(existing.stars!)),
      );
    }
    return OutlinedButton.icon(
      key: const Key('ask-rating'),
      onPressed: () => _ask(context, repo!),
      icon: const Icon(Icons.star_outline),
      label: Text(existing == null ? l10n.askForRating : l10n.sendRatingAgain),
    );
  }

  Future<void> _ask(BuildContext context, RatingRepository repo) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final address = context
        .read<SettingsRepository>()
        .settings
        .publicWebAddress;
    final shopName = context.read<AuthState>().shopName ?? '';
    if (ratingLink(address, 'x') == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ratingNeedsWebAddress)),
      );
      return;
    }
    try {
      final rating = await repo.requestFor(order, shopName: shopName);
      final link = ratingLink(address, rating.token)!;
      final wa = whatsAppUri(
        order.customerPhone,
        ratingMessage(
          shopName: rating.shopName,
          firstName: rating.customerFirstName,
          device: rating.device,
          link: link,
        ),
      );
      if (wa != null &&
          await launchUrl(wa, mode: LaunchMode.externalApplication)) {
        return;
      }
      await Clipboard.setData(ClipboardData(text: link.toString()));
      messenger.showSnackBar(SnackBar(content: Text(l10n.ratingLinkCopied)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
