import 'option_set.dart';

/// THE MODELS OFFERED FOR A BRAND
///
/// The shop's own list for the brand is only a start: a shop made before
/// models were a list has none, and the built-in list covers six brands. So
/// every model the shop's records already carry under that brand — repairs,
/// phones bought, enquiries — is offered too, most used first, then the rest
/// of the list by name. A model typed once is in the row the next time, even
/// before anybody files it in Settings.
///
/// [records] are (brand, model) pairs. Case and spacing do not make a second
/// model; the list's spelling wins, then the first one seen.
List<String> modelChoices(
  OptionSet listed,
  String brand,
  Iterable<(String, String)> records,
) {
  final key = normalizeOption(brand);
  if (key.isEmpty) return const [];
  final used = <String>[];
  for (final (b, m) in records) {
    if (normalizeOption(b) == key && normalizeOption(m).isNotEmpty) {
      used.add(m.trim());
    }
  }
  final seen = <String>{};
  final all = <String>[];
  for (final m in [...listed.sorted, ...used]) {
    if (seen.add(normalizeOption(m))) all.add(m);
  }
  return byUse(all, used);
}
