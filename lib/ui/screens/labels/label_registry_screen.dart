import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/label_repository.dart';
import '../../../data/print_server.dart';
import '../../../domain/labels/label_entry.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';

/// THE LABEL REGISTRY
///
/// Every label the shop has printed, and what it points at. The page people
/// open when someone reads a number down the phone.
///
/// The number at the top is the **next** label, shown without consuming it.
/// Reading it must not take it: a page that burns a number every time somebody
/// opens it leaves gaps nobody can account for, and the shop counts its
/// stickers.
class LabelRegistryScreen extends StatefulWidget {
  const LabelRegistryScreen({super.key});

  @override
  State<LabelRegistryScreen> createState() => _LabelRegistryScreenState();
}

class _LabelRegistryScreenState extends State<LabelRegistryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<LabelRepository>();
    final theme = Theme.of(context);

    if (repo.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.registryCouldNotLoad),
              const SizedBox(height: 8),
              Text(repo.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: repo.load,
                child: Text(context.l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    final rows = [
      for (final e in repo.entries)
        if (_matches(e)) e,
    ]..sort((a, b) => b.number.compareTo(a.number));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.nextLabel('${repo.nextNumber}'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                // Written down because it is the rule that stops two staff
                // getting the same sticker.
                context.l10n.oneCounterExplainer,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const Key('label-search'),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: context.l10n.searchLabels,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _query.isEmpty
                          ? context.l10n.nothingPrintedYet
                          : context.l10n.noLabelMatching(_query),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _LabelRow(entry: rows[i]),
                ),
        ),
      ],
    );
  }

  bool _matches(LabelEntry entry) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      entry.number.toString(),
      entry.recordId,
      if (entry.kind != null) labelKindLabel(context, entry.kind),
      ...entry.snapshot.values.map((v) => v?.toString() ?? ''),
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.entry});

  final LabelEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<LabelRepository>();
    // Resolved, so the row shows the current price rather than the printed
    // one — the same overlay the scanner uses.
    final view = repo.resolve(entry.number);

    return ListTile(
      leading: CircleAvatar(
        child: Text(
          entry.number.toString().substring(
            entry.number.toString().length > 3
                ? entry.number.toString().length - 3
                : 0,
          ),
          style: theme.textTheme.labelSmall,
        ),
      ),
      title: Text('${entry.number} · ${view?.title ?? ''}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              // An unreadable kind still lists: the number is real and stuck
              // to something.
              entry.kind == null
                  ? context.l10n.unreadableKind
                  : labelKindLabel(context, entry.kind),
              if (view?.price != null) '₹${view!.price}',
              if (entry.reprints > 0)
                context.l10n.reprintedTimes('${entry.reprints}'),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          if (view != null && view.isStale)
            Text(
              context.l10n.stickerOutOfDate(view.staleFields.join(', ')),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          if (view != null && !view.recordExists)
            Text(
              context.l10n.recordGoneShowingPrinted,
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('reprint-${entry.number}'),
            tooltip: context.l10n.printThisLabelAgain,
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _reprint(context, view),
          ),
          if (view?.canOpen == true)
            IconButton(
              key: Key('open-${entry.number}'),
              tooltip: context.l10n.openTheRecord,
              icon: const Icon(Icons.open_in_new),
              onPressed: () => context.go(view!.route!),
            ),
        ],
      ),
      isThreeLine: true,
    );
  }

  Future<void> _reprint(BuildContext context, LabelView? view) async {
    final repo = context.read<LabelRepository>();
    final printer = context.read<PrintServer>();
    final messenger = ScaffoldMessenger.of(context);

    // The number is kept. A new number for the same record is a second sticker
    // that resolves somewhere the first one did not.
    final updated = await repo.markReprinted(entry.number);
    final result = await printer.printLabel(
      LabelPrintJob(
        number: updated.number,
        title: view?.title ?? '',
        subtitle: view?.subtitle ?? '',
        price: view?.price,
      ),
    );
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.sent
              ? context.l10n.labelSentToPrinter('${updated.number}')
              // A failed print is not a failed anything else.
              : result.error!,
        ),
      ),
    );
  }
}
