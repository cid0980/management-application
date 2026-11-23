import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// An expense kind (stored in English) in the phone's language.
String expenseKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'Parts' => l10n.expenseKindParts,
  'Tea & food' => l10n.expenseKindTea,
  'Rent' => l10n.expenseKindRent,
  'Electricity' => l10n.expenseKindPower,
  'Salary' => l10n.expenseKindSalary,
  'Transport' => l10n.expenseKindTransport,
  'Shop supplies' => l10n.expenseKindSupplies,
  'Other' => l10n.expenseKindOther,
  _ => kind,
};

IconData expenseKindIcon(String kind) => switch (kind) {
  'Parts' => Icons.memory_outlined,
  'Tea & food' => Icons.local_cafe_outlined,
  'Rent' => Icons.storefront_outlined,
  'Electricity' => Icons.bolt_outlined,
  'Salary' => Icons.badge_outlined,
  'Transport' => Icons.two_wheeler_outlined,
  'Shop supplies' => Icons.shopping_bag_outlined,
  _ => Icons.payments_outlined,
};

/// Cash, UPI and Card read the same in every language the app speaks.
String expenseMethodLabel(AppLocalizations l10n, String method) =>
    method == 'Cash' ? l10n.expenseCash : method;
