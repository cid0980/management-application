import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/label_repository.dart';
import '../../../domain/devices/tac_registry.dart';
import '../../../domain/labels/intake_prefill.dart';
import '../../../domain/labels/label_entry.dart';
import '../../../domain/labels/scan_resolution.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';
import '../../widgets/barcode_scan.dart';

/// THE SCANNER
///
/// Three modes, because the scanner is used for three jobs: find the record a
/// sticker belongs to, take a phone in for repair, or buy one. The mode decides
/// what a scan *does*; it never decides what the code *is*.
///
/// That separation is the fix for the bug this page is named after. Scanning
/// the back of a phone in label mode used to return "not found", staff read it
/// as "the sticker was never printed", and printed a second one. Now the code
/// is classified first — 14 to 16 digits is an IMEI, full stop — so label mode
/// can answer "that is an IMEI, did you mean to start an intake".
///
/// **Typing the number is a first-class way in, not a fallback.** Stickers get
/// scratched, phones get scanned through a case, and the camera needs a
/// permission that is not always there. Someone holding a label can always
/// read the number out.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _code = TextEditingController();
  ScannerMode _mode = ScannerMode.label;
  ScanOutcome? _outcome;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final repo = context.read<LabelRepository>();
    final tacs = context.read<TacRegistry>();
    // Only the latest labels are kept on the phone: an older sticker is
    // fetched from the server first. Offline, it resolves from what is here.
    final number = int.tryParse(_code.text.trim());
    if (number != null &&
        _code.text.trim().length <= 8 &&
        repo.byNumber(number) == null) {
      try {
        await repo.fetch(number);
      } catch (_) {
        // Not reachable: resolveScan says "not a label we know".
      }
      if (!mounted) return;
    }
    setState(() {
      _outcome = resolveScan(
        _code.text,
        mode: _mode,
        lookupLabel: repo.byNumber,
        liveRecord: repo.liveRecordFor,
        tacs: tacs,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<ScannerMode>(
          segments: [
            for (final mode in ScannerMode.values)
              ButtonSegment(
                value: mode,
                label: Text(scannerModeLabel(context, mode)),
              ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() {
            _mode = s.first;
            // The previous result belonged to the previous question.
            _outcome = null;
          }),
        ),
        const SizedBox(height: 8),
        Text(scannerModeHint(context, _mode), style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        // The camera reads the code and hands it to the same resolveScan as
        // the box below, so nothing about what a code means lives in the
        // camera path.
        FilledButton.icon(
          key: const Key('scan-camera'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            shape: const StadiumBorder(),
          ),
          onPressed: () async {
            final code = await scanOneBarcode(context);
            if (code == null || !mounted) return;
            _code.text = code;
            _scan();
          },
          icon: const Icon(Icons.qr_code_scanner, size: 28),
          label: Text(context.l10n.scanWithCamera),
        ),
        const SizedBox(height: 16),
        Text(context.l10n.scanOrType, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        TextField(
          key: const Key('scan-code'),
          controller: _code,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.labelNumberOrImei,
            border: const OutlineInputBorder(),
            isDense: true,
            helperText: context.l10n.labelIsFiveDigits,
          ),
          onSubmitted: (_) => _scan(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('scan-go'),
          onPressed: _scan,
          icon: const Icon(Icons.search),
          label: Text(context.l10n.lookItUp),
        ),
        const SizedBox(height: 16),
        if (_outcome != null) _Result(outcome: _outcome!, mode: _mode),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.outcome, required this.mode});

  final ScanOutcome outcome;
  final ScannerMode mode;

  @override
  Widget build(BuildContext context) {
    return switch (outcome) {
      ScanOpensRecord(:final view) => _LabelResult(view: view),
      ScanUnknownLabel(:final number) => _Message(
        icon: Icons.help_outline,
        title: context.l10n.labelNotInRegistry('$number'),
        // The number is on the sticker and is what someone will quote down
        // the phone, so it is said back plainly.
        detail: context.l10n.nothingPrintedUnder,
        action: FilledButton(
          onPressed: () => context.go('/admin/labels'),
          child: Text(context.l10n.openTheRegistry),
        ),
      ),
      ScanIsImei() => _ImeiResult(result: outcome as ScanIsImei, mode: mode),
      ScanUnreadable(:final raw) => _Message(
        icon: Icons.block,
        title: context.l10n.notANumberShopUses,
        detail: raw.isEmpty
            ? context.l10n.nothingWasScanned
            : context.l10n.scannedNeither(raw),
      ),
    };
  }
}

/// A label that resolved.
class _LabelResult extends StatelessWidget {
  const _LabelResult({required this.view});

  final LabelView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = view.entry;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.labelNamed('${entry.number}'),
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              view.title.isEmpty ? context.l10n.noTitleOnLabel : view.title,
              style: theme.textTheme.titleMedium,
            ),
            if (view.subtitle.isNotEmpty) Text(view.subtitle),
            const SizedBox(height: 8),
            Text(
              [
                if (entry.kind != null) labelKindLabel(context, entry.kind),
                if (view.price != null) '₹${view.price}',
                if (view.status.isNotEmpty) view.status,
              ].join(' · '),
            ),
            if (view.isStale)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  // The sticker says one thing and the screen says another.
                  // Which is right is not something to leave to a guess.
                  context.l10n.changedSinceStickerFields(
                    view.staleFields.join(', '),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            if (!view.recordExists)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  entry.kind == null
                      ? context.l10n.printedByNewerBuild
                      // The copy on the entry is why this resolves at all.
                      : context.l10n.recordBehindLabelGone,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            if (view.canOpen)
              FilledButton.icon(
                key: const Key('scan-open'),
                // The record itself, not a summary: staff scan a label because
                // they are holding the phone and have something to do about it.
                onPressed: () => context.go(view.route!),
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  context.l10n.openTheKind(
                    labelKindLabel(context, entry.kind).toLowerCase(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// An IMEI. In an intake mode this starts the form; in label mode it is the
/// answer that used to be "not found".
class _ImeiResult extends StatelessWidget {
  const _ImeiResult({required this.result, required this.mode});

  final ScanIsImei result;
  final ScannerMode mode;

  /// What travels to the intake form. A TAC the table does not know sends the
  /// IMEI alone — the form opens either way, just with less filled in.
  String get _query => IntakePrefill.toQuery(
    imei: result.imei,
    brand: result.device?.brand,
    model: result.device?.model,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final device = result.device;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IMEI ${result.imei}', style: theme.textTheme.titleMedium),
            if (result.tac != null)
              Text('TAC ${result.tac}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              device == null
                  // The ordinary case. The form opens anyway, just with less
                  // filled in.
                  ? context.l10n.notInDeviceTable
                  : context.l10n.looksLikeDevice(device.device),
            ),
            if (result.wasLookingForALabel)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  // This sentence is the whole reason the page classifies
                  // before it looks anything up.
                  context.l10n.factoryImeiIntake,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('scan-intake-service'),
                  // The query is built by the module that also reads it, so
                  // the two cannot drift apart.
                  onPressed: () => context.go('/service$_query'),
                  icon: const Icon(Icons.build_outlined),
                  label: Text(context.l10n.startARepair),
                ),
                OutlinedButton.icon(
                  key: const Key('scan-intake-purchase'),
                  onPressed: () => context.go('/inventory/second-hand$_query'),
                  icon: const Icon(Icons.smartphone_outlined),
                  label: Text(context.l10n.buyThisHandset),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail!, style: theme.textTheme.bodySmall),
            ],
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
