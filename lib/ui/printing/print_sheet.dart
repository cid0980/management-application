import '../../data/firestore_errors.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../data/printing/documents.dart';
import '../../data/shop_repository.dart';
import '../../l10n/l10n.dart';

/// PRINT OR SEND
///
/// Every printed document goes through here: one sheet, two big buttons.
/// "Print" opens the phone's own print dialog (a Bluetooth or Wi-Fi printer);
/// "Send" opens the share sheet, which is how most bills actually reach a
/// customer — on WhatsApp.
///
/// The shop's name, address and GSTIN at the top of the page come from this
/// shop's own record, so two shops never print each other's header.
Future<void> showPrintSheet(
  BuildContext context, {
  required String title,
  required String fileName,
  required Future<Uint8List> Function(ShopHeader shop, bool includeLock) build,
  bool offerLockChoice = false,
}) async {
  final header = await _shopHeader(context);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => _PrintSheet(
      title: title,
      fileName: fileName,
      header: header,
      build: build,
      offerLockChoice: offerLockChoice,
    ),
  );
}

Future<ShopHeader> _shopHeader(BuildContext context) async {
  final auth = context.read<AuthState>();
  ShopRepository? shops;
  try {
    shops = context.read<ShopRepository?>();
  } on ProviderNotFoundException {
    shops = null;
  }
  final id = auth.shopId;
  if (shops != null && id != null && id.isNotEmpty) {
    try {
      final shop = await shops.load(id);
      if (shop != null) return ShopHeader.fromShop(shop);
    } catch (_) {
      // Offline: the name is enough to print with.
    }
  }
  return ShopHeader(name: auth.shopName ?? '');
}

class _PrintSheet extends StatefulWidget {
  const _PrintSheet({
    required this.title,
    required this.fileName,
    required this.header,
    required this.build,
    required this.offerLockChoice,
  });

  final String title;
  final String fileName;
  final ShopHeader header;
  final Future<Uint8List> Function(ShopHeader shop, bool includeLock) build;
  final bool offerLockChoice;

  @override
  State<_PrintSheet> createState() => _PrintSheetState();
}

class _PrintSheetState extends State<_PrintSheet> {
  /// Off by default: a job card can be left lying on the counter.
  bool _includeLock = false;
  bool _busy = false;

  Future<void> _go({required bool share}) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final bytes = await widget.build(widget.header, _includeLock);
      if (share) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: '${widget.fileName}.pdf',
        );
      } else {
        await Printing.layoutPdf(
          name: widget.fileName,
          onLayout: (_) async => bytes,
        );
      }
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.printFailed(plainError(e)))),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.printEnglishNote, style: theme.textTheme.bodySmall),
            if (widget.offerLockChoice)
              SwitchListTile(
                key: const Key('print-include-lock'),
                contentPadding: EdgeInsets.zero,
                value: _includeLock,
                title: Text(l10n.printLockCode),
                subtitle: Text(l10n.printLockCodeHint),
                onChanged: (v) => setState(() => _includeLock = v),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('print-now'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
              onPressed: _busy ? null : () => _go(share: false),
              icon: const Icon(Icons.print_outlined),
              label: Text(l10n.printNow),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('print-share'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
              onPressed: _busy ? null : () => _go(share: true),
              icon: const Icon(Icons.share_outlined),
              label: Text(l10n.printShare),
            ),
          ],
        ),
      ),
    );
  }
}
