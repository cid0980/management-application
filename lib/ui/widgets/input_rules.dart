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
/// - **Phone numbers:** the 10-digit mobile number only. A pasted
///   `+91 98765 43210` or `098765-43210` is cut down to its ten digits; an
///   eleventh digit cannot be typed; letters are refused. The box shows a
///   `7/10` counter so a missing digit is seen before Save.
///
/// Rules that need context (a price is required here, a quantity must not
/// pass the shelf there) stay with each form; these only stop what can
/// never be right.
const int kMaxMoneyDigits = 8;

/// An Indian mobile number: what every phone box in the app takes.
const int kPhoneDigits = 10;

/// An IMEI as printed on the box and shown by *#06#.
const int kImeiDigits = 15;

const Set<String> _phoneFields = {
  'phone',
  'altPhone',
  'customerPhone',
  'sellerPhone',
  'sellerAltPhone',
};

List<TextInputFormatter> phoneInput() => [_PhoneFormatter()];

/// How many digits a box holds, for its `n/10` counter (TextField.maxLength).
/// Null for boxes with no fixed length.
int? maxDigitsFor(String field) => _phoneFields.contains(field)
    ? kPhoneDigits
    : (field == 'imei' || field == 'imei2')
    ? kImeiDigits
    : null;

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
  'imei' || 'imei2' => digitsInput(kImeiDigits),
  'phone' ||
  'altPhone' ||
  'customerPhone' ||
  'sellerPhone' ||
  'sellerAltPhone' => phoneInput(),
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

/// Keeps a phone box to the ten digits of the number.
///
/// Typing `+91` first is allowed and dropped once the next digit comes, so
/// the box never holds a country code the counter would count. Another
/// country code, letters, or more than ten digits: the edit is refused and
/// the box stays as it was.
class _PhoneFormatter extends TextInputFormatter {
  static final _letters = RegExp(r'[^0-9+\-\s().]');
  static final _spacing = RegExp(r'[\s\-().]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_letters.hasMatch(newValue.text)) return oldValue;
    var t = newValue.text.replaceAll(_spacing, '');
    // "+" and "+9" on the way to "+91".
    if (t == '+' || t == '+9') return newValue.copyWith(text: t);
    if (t.startsWith('+91')) {
      t = t.substring(3);
    } else if (t.contains('+')) {
      return oldValue;
    }
    if (t.length == 12 && t.startsWith('91')) t = t.substring(2);
    t = t.replaceFirst(RegExp(r'^0+'), '');
    if (t.length > kPhoneDigits) return oldValue;
    if (t == newValue.text) return newValue;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
