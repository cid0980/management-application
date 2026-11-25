import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// ONE ICON PER KIND OF FACT, THE SAME ON EVERY PAGE
///
/// A record page reads "📞 98765 43210", not "Phone: 98765 43210": the icon
/// says what the value is, so the words go. The same thing has the same icon
/// everywhere (the phone number on a customer, a seller, an enquiry). Rows
/// whose meaning an icon cannot carry — a breakdown of money (paid to the
/// seller, repairs, other costs) — keep their words.
///
/// Matched on the row's label in the app's language, so every page gets its
/// icons from this one table. A long press on an icon says what it means.
IconData? factIcon(AppLocalizations l, String label) {
  if (label.trim().isEmpty) return null;
  if (label == 'IMEI') return Icons.tag;
  final table = <String, IconData>{
    // People and how to reach them.
    l.name: Icons.person_outline,
    l.shopPhone: Icons.call_outlined,
    l.phoneNumber: Icons.call_outlined,
    l.secondNumber: Icons.phone_forwarded_outlined,
    l.fieldAltPhone: Icons.phone_forwarded_outlined,
    l.email: Icons.mail_outline,
    l.address: Icons.place_outlined,
    l.idProof: Icons.badge_outlined,
    l.supplier: Icons.local_shipping_outlined,
    l.fieldSupplier: Icons.local_shipping_outlined,
    l.takenBy: Icons.support_agent,
    l.dealtWith: Icons.support_agent,
    l.technician: Icons.engineering_outlined,
    // The phone itself.
    l.brand: Icons.sell_outlined,
    l.model: Icons.smartphone,
    l.variant: Icons.memory,
    l.fieldVariant: Icons.memory,
    l.optionRam: Icons.memory,
    l.optionRom: Icons.sd_storage_outlined,
    l.colour: Icons.palette_outlined,
    l.serial: Icons.qr_code_2,
    l.category: Icons.category_outlined,
    l.leftWithIt: Icons.cable,
    l.storedGrade: Icons.star_outline,
    l.repairWarranty: Icons.verified_user_outlined,
    // When.
    l.purchaseDate: Icons.event_outlined,
    l.cameIn: Icons.move_to_inbox_outlined,
    l.promised: Icons.event_available_outlined,
    l.handedBack: Icons.outbox_outlined,
    l.askedOn: Icons.event_outlined,
    l.ringBack: Icons.phone_callback_outlined,
    // What was said.
    l.inTheirWords: Icons.format_quote,
    l.notes: Icons.sticky_note_2_outlined,
    l.theirBudget: Icons.account_balance_wallet_outlined,
    l.whatItBecame: Icons.flag_outlined,
  };
  return table[label];
}

/// The icon in its soft square, with what it means on a long press.
class FactIcon extends StatelessWidget {
  const FactIcon(this.icon, {super.key, required this.meaning, this.size = 34});

  final IconData icon;
  final String meaning;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: meaning,
      triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, size: size * 0.55, color: scheme.primary),
      ),
    );
  }
}

/// The icon at the left of a form's box, by the box's name: the same as on
/// the record page, so the form and the page look alike. Money boxes show ₹
/// instead, and free-text boxes nothing.
IconData? fieldIcon(String key) => switch (key) {
  'customerPhone' || 'sellerPhone' || 'phone' => Icons.call_outlined,
  'altPhone' ||
  'sellerAltPhone' ||
  'secondPhone' => Icons.phone_forwarded_outlined,
  'customerName' || 'sellerName' || 'name' => Icons.person_outline,
  'email' => Icons.mail_outline,
  'address' => Icons.place_outlined,
  'brand' => Icons.sell_outlined,
  'model' => Icons.smartphone,
  'imei' || 'imei2' => Icons.tag,
  'serial' || 'serialNumber' || 'sku' => Icons.qr_code_2,
  'colour' || 'color' => Icons.palette_outlined,
  'storage' || 'ram' || 'variant' => Icons.memory,
  'batteryHealth' => Icons.battery_std,
  'lockValue' => Icons.lock_outline,
  'technician' => Icons.engineering_outlined,
  'supplier' => Icons.local_shipping_outlined,
  'sellerIdProof' || 'idProof' => Icons.badge_outlined,
  'category' => Icons.category_outlined,
  'quantity' || 'stockCount' || 'stock' => Icons.inventory_2_outlined,
  'reorderLevel' => Icons.low_priority,
  'handledBy' => Icons.support_agent,
  'question' => Icons.help_outline,
  'complaintNotes' || 'notes' => Icons.sticky_note_2_outlined,
  _ => null,
};
