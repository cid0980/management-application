/// WHAT A LABEL POINTS AT
///
/// One `label_registry` for the whole shop, so a label number is unique across
/// every kind of record. Two registries would mean label 26042 being both a
/// handset and a service order, and the scanner choosing.
///
/// A scanned label opens the **record itself** — `/service/:id`, not a
/// read-only summary. The summary was the original behaviour and it was the
/// wrong one: staff scan a label because they are holding the phone and have
/// something to do about it, and a page they cannot act on sends them off to
/// find the record by hand.
library;

enum LabelTargetKind { product, secondHand, service, sale }

const Map<LabelTargetKind, String> kLabelTargetLabels = {
  LabelTargetKind.product: 'Product',
  LabelTargetKind.secondHand: 'Second-hand handset',
  LabelTargetKind.service: 'Service order',
  LabelTargetKind.sale: 'Sale',
};

/// The same paths the web app uses, so a label printed two years ago still
/// resolves.
const Map<LabelTargetKind, String> kLabelTargetRoutes = {
  LabelTargetKind.product: '/products',
  LabelTargetKind.secondHand: '/inventory/second-hand',
  LabelTargetKind.service: '/service',
  LabelTargetKind.sale: '/sales',
};

/// Where a scan of this label lands.
String routeForTarget(LabelTargetKind kind, String recordId) =>
    '${kLabelTargetRoutes[kind]}/$recordId';

/// Read a stored kind.
///
/// An unrecognised kind is null rather than a guess. A label whose kind this
/// build does not understand must not open a random record — the registry page
/// shows it as unreadable and the number is still there to go on.
LabelTargetKind? targetKindFrom(Object? raw) => switch (raw?.toString()) {
  'product' => LabelTargetKind.product,
  'secondHand' || 'second_hand' || 'second-hand' => LabelTargetKind.secondHand,
  'service' || 'service_order' => LabelTargetKind.service,
  'sale' => LabelTargetKind.sale,
  _ => null,
};
