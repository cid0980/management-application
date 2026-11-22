import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/enquiry_repository.dart';
import '../../data/second_hand_repository.dart';
import '../../data/service_repository.dart';

/// Every (brand, model) the shop's records carry — repairs, phones bought,
/// enquiries — for `modelChoices`. A screen without one of these stores (a
/// test, a trimmed-down page) simply has fewer records, not an error.
List<(String, String)> modelRecords(BuildContext context) {
  T? maybe<T>() {
    try {
      return Provider.of<T>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  return [
    for (final o in maybe<ServiceRepository>()?.orders ?? const [])
      (o.brand, o.model),
    for (final d in maybe<SecondHandRepository>()?.devices ?? const [])
      (d.brand, d.model),
    for (final e in maybe<EnquiryRepository>()?.enquiries ?? const [])
      (e.brand, e.model),
  ];
}
