import 'package:flutter/services.dart';

/// WHAT A NUMBER BOX ACCEPTS — ONE RULE FOR THE WHOLE APP
///
/// Every money box, quantity box and code box takes its typing rules from
/// here, so a price on the repair form and a price on the expense form
/// cannot disagree about what a price is:
///
/// - **Money:** digits and one point, at most two decimals (paise), at most
///   [kMaxMoneyDigits] digits before the point (₹9,99,99,999). No minus sign,
///   no letters, nothing that could have come from a stray barcode scan.
/// - **Whole numbers** (quantities, counts, days): digits only.
/// - **Codes** (IMEI, battery %): digits only, with a length cap.
///
/// Rules that need context (a price is required here, a quantity must not
/// pass the shelf there) stay with each form; these only stop what can
/// never be right.
const int kMaxMoneyDigits = 8;

List<TextInputFormatter> moneyInput() => [_MoneyFormatter()];

List<TextInputFormatter> wholeNumberInput({int maxDigits = 6}) => [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(maxDigits),
];

List<TextInputFormatter> digitsInput(int maxLength) => [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(maxLength),
];

/// The typing rule for a form field, by its key — what the shared `_field`
/// helpers of the forms use. Null for a field with no rule (names, notes).
List<TextInputFormatter>? inputRuleFor(String field) => switch (field) {
  'estimatedPrice' ||
  'advancePaid' ||
  'rawMaterialCost' ||
  'outsideLabourCost' ||
  'purchasePrice' ||
  'askingPrice' ||
  'otherCost' ||
  'costPrice' ||
  'sellingPrice' ||
  'mrp' ||
  'budget' ||
  'quotedPrice' => moneyInput(),
  'imei' || 'imei2' => digitsInput(16),
  'batteryHealth' => digitsInput(3),
  'reorderLevel' || 'stock' || 'openingStock' => wholeNumberInput(maxDigits: 5),
  _ => null,
};

class _MoneyFormatter extends TextInputFormatter {
  static final _shape = RegExp(r'^\d*\.?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // A pasted "₹1,500" keeps its digits and point; anything else goes.
    final text = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final whole = text.split('.').first;
    if (!_shape.hasMatch(text) || whole.length > kMaxMoneyDigits) {
      return oldValue;
    }
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
