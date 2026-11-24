import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/sales_repository.dart';
import '../../data/service_repository.dart';

/// A record's internal id (`s-1795442606251`, `so-…`) as the number people
/// know it by — the invoice or job number — for history lines that point at
/// a bill or a repair. Unknown ids come back as they are.
String recordNumber(BuildContext context, String id) {
  T? maybe<T>() {
    try {
      return context.read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  final sale = maybe<SalesRepository>()?.byId(id);
  if (sale != null && sale.invoiceNumber.isNotEmpty) return sale.invoiceNumber;
  final order = maybe<ServiceRepository>()?.byId(id);
  if (order != null && order.orderNumber.isNotEmpty) return order.orderNumber;
  return id;
}

/// [text] with [id] written as its number (see [recordNumber]).
String withRecordNumber(BuildContext context, String text, String? id) {
  if (id == null || id.isEmpty || !text.contains(id)) return text;
  return text.replaceAll(id, recordNumber(context, id));
}
