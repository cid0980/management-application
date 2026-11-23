import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/auth_state.dart';

import '../../domain/common/contact_links.dart';
import '../../l10n/l10n.dart';

/// CALL AND WHATSAPP, SIDE BY SIDE
///
/// Ported from the French Mobiles Flutter port, where every customer, repair
/// and enquiry page had them. Two big buttons, the same everywhere: ring the
/// customer, or open WhatsApp with a message already written in the shop's
/// language and signed with the shop's name.
///
/// A record with no usable mobile number still shows the buttons, and says
/// why when tapped — a button that silently does nothing is the one people
/// stop trusting.
class ContactButtons extends StatelessWidget {
  const ContactButtons({super.key, required this.phone, required this.message});

  final String phone;
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: const StadiumBorder(),
    );
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('contact-call'),
            style: style,
            onPressed: () => openContactLink(context, callUri(phone)),
            icon: const Icon(Icons.call_outlined),
            label: Text(l10n.contactCall),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('contact-whatsapp'),
            style: style.copyWith(
              foregroundColor: const WidgetStatePropertyAll(Color(0xFF128C4A)),
              side: const WidgetStatePropertyAll(
                BorderSide(color: Color(0xFF128C4A)),
              ),
            ),
            onPressed: () =>
                openContactLink(context, whatsAppUri(phone, message)),
            icon: const Icon(Icons.chat_outlined),
            label: Text(l10n.contactWhatsApp),
          ),
        ),
      ],
    );
  }
}

/// Opens the dialler or WhatsApp, or says why it could not.
Future<void> openContactLink(BuildContext context, Uri? uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  if (uri == null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.contactNoNumber)));
    return;
  }
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.contactCouldNotOpen)));
  }
}

/// The shop's name, to sign a message with. Empty rather than an error where
/// nobody is signed in (a screen shown on its own, as in a test).
String shopNameOf(BuildContext context) {
  try {
    return Provider.of<AuthState>(context, listen: false).shopName ?? '';
  } on ProviderNotFoundException {
    return '';
  }
}

/// SWIPE TO CALL OR MESSAGE
///
/// A row in a list of people's records (a repair, an enquiry) slides: to the
/// right rings the customer, to the left opens WhatsApp with [message]
/// already written. The row springs back; nothing is removed. Green and the
/// icon show under the row as it moves, so it is plain what letting go does.
///
/// With no usable number the row does not slide at all.
class SwipeToContact extends StatelessWidget {
  const SwipeToContact({
    super.key,
    required this.id,
    required this.phone,
    required this.message,
    required this.child,
  });

  /// The record's id, so each row slides on its own.
  final String id;
  final String phone;
  final String Function() message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (callUri(phone) == null) return child;
    final l10n = context.l10n;
    Widget under(Alignment align, IconData icon, String label, Color colour) =>
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: align,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
    return Dismissible(
      key: ValueKey('swipe-$id'),
      // Far enough that a scroll that wanders sideways does not ring anyone.
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      background: under(
        Alignment.centerLeft,
        Icons.call,
        l10n.contactCall,
        const Color(0xFF1E6FD9),
      ),
      secondaryBackground: under(
        Alignment.centerRight,
        Icons.chat,
        l10n.contactWhatsApp,
        const Color(0xFF128C4A),
      ),
      confirmDismiss: (direction) async {
        final uri = direction == DismissDirection.startToEnd
            ? callUri(phone)
            : whatsAppUri(phone, message());
        await openContactLink(context, uri);
        // Never removed: the row comes back.
        return false;
      },
      child: child,
    );
  }
}
