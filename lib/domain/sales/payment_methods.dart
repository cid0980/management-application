/// PAYMENT METHODS
///
/// Finance (EMI) sales work differently from the others: the customer pays a
/// down payment at the counter and the finance company pays the rest, so the
/// CUSTOMER owes nothing once the sale is done. That is why a financed sale is
/// recorded as fully paid — it must not appear in Due Payments, which chases
/// customers. What is still outstanding is the financier's settlement to the
/// shop, which is a different ledger.
library;

const List<String> kFinanceProviders = [
  'Bajaj Finance',
  'IDFC Finance',
  'Samsung Finance',
  'Poonawalla',
  'TVS Credit',
];

const List<String> kDirectPaymentMethods = ['Cash', 'UPI', 'Card', 'Split'];

const List<String> kPaymentMethods = [
  ...kDirectPaymentMethods,
  ...kFinanceProviders,
];

bool isFinanceMethod(String? method) => kFinanceProviders.contains(method);

/// What the customer still owes the shop after this sale.
///
/// A financed sale leaves nothing on the customer: the financier owes the
/// shop, and that is not this number.
num balanceDueFor({
  required num total,
  required num paid,
  required String? method,
}) {
  if (isFinanceMethod(method)) return 0;
  final due = total - paid;
  return due > 0 ? due : 0;
}
