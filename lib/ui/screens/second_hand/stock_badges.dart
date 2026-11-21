import 'package:flutter/material.dart';

import '../../../domain/inventory/stock_state.dart';
import '../../../l10n/display_labels.dart';
import '../../theme/app_theme.dart';

/// THE STOCK COLOURS, IN ONE PLACE
///
/// The list, the detail page and anything else showing a handset draw its
/// state and its profit from here, so green means the same thing everywhere.

/// Green and "+" for money made, red and "−" for money lost. The sign is
/// there for the colour-blind; the colour is there for the hurried.
class ProfitPill extends StatelessWidget {
  const ProfitPill({super.key, required this.profit});

  final num profit;

  @override
  Widget build(BuildContext context) {
    final c = context.shopColors;
    final loss = profit < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: loss ? c.stopSoft : c.goodSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            loss ? Icons.trending_down : Icons.trending_up,
            size: 16,
            color: loss ? c.stop : c.good,
          ),
          const SizedBox(width: 4),
          Text(
            '${loss ? '−' : '+'}₹${profit.abs()}',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: loss ? c.stop : c.good),
          ),
        ],
      ),
    );
  }
}

/// Go, wait, gone — the same three colours as the tab dots.
(Color, Color) stateColours(BuildContext context, String status) {
  final c = context.shopColors;
  return switch (stockStateOf(status)) {
    kRepairing => (c.waitSoft, c.wait),
    kSold => (c.doneSoft, c.done),
    _ => (c.goodSoft, c.good),
  };
}

/// The label comes from `stock_state.dart` so the list and the sale picker
/// cannot describe the same device differently.
class StateChip extends StatelessWidget {
  const StateChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final state = stockStateOf(status);
    final (Color bg, Color fg) = stateColours(context, status);
    final icon = switch (state) {
      kRepairing => Icons.build,
      kSold => Icons.check_circle,
      _ => Icons.storefront,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            stockStateLabel(context, state),
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
