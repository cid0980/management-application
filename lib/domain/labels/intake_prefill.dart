/// WHAT A SCAN HANDS AN INTAKE FORM
///
/// Scanning the back of a phone is the start of a job, not the end of a
/// lookup. The scanner resolves an IMEI, asks the device table what the TAC
/// means, and then has to get that to a form — which is a different screen, so
/// it travels as query parameters on the route (`/service?imei=…&brand=…`).
///
/// Query parameters because a label on a counter PC gets bookmarked and a link
/// gets sent over WhatsApp. Anything that works as a URL keeps working.
///
/// **It prefills; it never decides.** The device table is incomplete and a
/// refurbished handset can carry a TAC that does not match what is in the
/// hand, so every prefilled field stays editable and nothing here can block a
/// save. A prefill that is wrong has to be as easy to correct as an empty
/// field is to fill.
library;

import '../inventory/imei.dart';

class IntakePrefill {
  const IntakePrefill({
    this.imei = '',
    this.brand = '',
    this.model = '',
    this.customerPhone = '',
    this.customerName = '',
    this.notes = '',
  });

  final String imei;
  final String brand;
  final String model;

  /// Who it is for and what they said — carried over when an enquiry turns
  /// into a repair, so nothing is typed twice.
  final String customerPhone;
  final String customerName;
  final String notes;

  bool get isEmpty =>
      imei.isEmpty &&
      brand.isEmpty &&
      model.isEmpty &&
      customerPhone.isEmpty &&
      customerName.isEmpty &&
      notes.isEmpty;

  /// Read a route's query parameters.
  ///
  /// Anything unreadable is simply dropped — a hand-edited URL opens an empty
  /// form rather than an error. The form is the point; the prefill is a
  /// convenience.
  static IntakePrefill fromQuery(Map<String, String> query) {
    final imei = normalizeImei(query['imei']);
    return IntakePrefill(
      // Only a plausible IMEI is carried over. A shop label in this parameter
      // would otherwise land in the IMEI field and fail validation there,
      // which reads as the form being broken.
      imei: looksLikeImei(imei) ? imei : '',
      brand: (query['brand'] ?? '').trim(),
      model: (query['model'] ?? '').trim(),
    );
  }

  /// The query string for a route, omitting what there is nothing to say
  /// about.
  static String toQuery({String? imei, String? brand, String? model}) {
    final parts = <String>[
      if ((imei ?? '').isNotEmpty) 'imei=${Uri.encodeQueryComponent(imei!)}',
      if ((brand ?? '').isNotEmpty) 'brand=${Uri.encodeQueryComponent(brand!)}',
      if ((model ?? '').isNotEmpty) 'model=${Uri.encodeQueryComponent(model!)}',
    ];
    return parts.isEmpty ? '' : '?${parts.join('&')}';
  }
}
