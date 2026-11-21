/// MONEY, WRITTEN THE INDIAN WAY
///
/// Ported from the French Mobiles Flutter port (`french_mobiles_core`
/// `money.dart` and `number_to_words.dart`), which ported them from the web
/// app.
///
/// **Indian grouping, not thousands.** 125000 is `1,25,000` here: the last
/// three digits together, then every two above them. A shop reading lakhs off
/// a bill thinks in that grouping.
///
/// **The amount in words** is what makes a printed bill stand up when a
/// customer disputes a figure later: `One Lakh Twenty Five Thousand Rupees
/// Only`.
library;

/// Groups the digits of a whole number the Indian way: `125000` -> `1,25,000`.
String groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final chunks = <String>[];
  while (rest.length > 2) {
    chunks.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) chunks.insert(0, rest);
  return '${chunks.join(',')},$last3';
}

/// `125000` -> `1,25,000`; `99.5` -> `99.5`. Up to two decimal places, trailing
/// zeros dropped — paise, never more.
String formatIndianNumber(num value) {
  final negative = value < 0;
  var paise = (value.abs() * 100).round();
  final whole = paise ~/ 100;
  paise %= 100;
  final decimals = paise == 0
      ? ''
      : '.${paise.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '')}';
  return '${negative ? '-' : ''}${groupIndian(whole.toString())}$decimals';
}

/// The one way money is written on paper: `₹1,25,000`.
String rupees(num? value) => '₹${formatIndianNumber(value ?? 0)}';

const List<String> _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];

const List<String> _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

String _words(int n) {
  if (n < 20) return _ones[n];
  if (n < 100) {
    return _tens[n ~/ 10] + (n % 10 != 0 ? ' ${_ones[n % 10]}' : '');
  }
  if (n < 1000) {
    return '${_ones[n ~/ 100]} Hundred'
        '${n % 100 != 0 ? ' ${_words(n % 100)}' : ''}';
  }
  if (n < 100000) {
    return '${_words(n ~/ 1000)} Thousand'
        '${n % 1000 != 0 ? ' ${_words(n % 1000)}' : ''}';
  }
  if (n < 10000000) {
    return '${_words(n ~/ 100000)} Lakh'
        '${n % 100000 != 0 ? ' ${_words(n % 100000)}' : ''}';
  }
  return '${_words(n ~/ 10000000)} Crore'
      '${n % 10000000 != 0 ? ' ${_words(n % 10000000)}' : ''}';
}

/// `125000` -> `One Lakh Twenty Five Thousand Rupees Only`.
///
/// A negative amount is written as its size: a bill never prints "minus" in
/// words, it prints a refund line instead.
String amountInWords(num amount) {
  final value = amount.abs();
  final paiseTotal = (value * 100).round();
  final whole = paiseTotal ~/ 100;
  final paise = paiseTotal % 100;
  if (whole == 0 && paise == 0) return 'Zero Rupees Only';
  final parts = <String>[
    if (whole > 0) '${_words(whole)} Rupees',
    if (paise > 0) '${_words(paise)} Paise',
  ];
  return '${parts.join(' and ')} Only';
}
