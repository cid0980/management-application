/// WHAT A STORED VALUE IS CALLED ON SCREEN
///
/// Statuses, tabs, stock states and label kinds are **keys, not words**.
/// `canComplete` compares against `'Completed'`, `firestore.rules` compares
/// against the same string, and a handset's state is written to Firestore as
/// `sold`. Translating the stored value would break every one of those, and
/// would make a shop that switched language unable to read its own old
/// records.
///
/// So the English string stays in storage and in the rules, and this is the
/// only place that turns one into words a shop reads. Every function here
/// **falls back to the stored value**: a status written by a newer build, or a
/// complaint type the shop typed itself, shows as itself rather than
/// disappearing.
///
/// Anything the shop typed — brands, models, colours, complaint types,
/// accessories — is not here at all. Those are the shop's own words in the
/// shop's own language already, and inventing translations for them would be
/// putting words in somebody's mouth.
library;

import 'package:flutter/widgets.dart';

import '../domain/enquiries/enquiry_list.dart';
import '../domain/inventory/stock_list.dart';
import '../domain/inventory/stock_state.dart';
import '../domain/labels/label_target.dart';
import '../domain/products/product_list.dart';
import '../domain/products/stock_level.dart';
import '../domain/settings/shop_settings.dart';
import 'l10n.dart';
import '../domain/service/order_state.dart';
import '../domain/enquiries/enquiry_state.dart';
import '../domain/products/stock_movement.dart';
import '../domain/labels/scan_resolution.dart';
import '../domain/reports/shop_report.dart';

/// A second-hand handset's state: `available`, `repairing`, `sold`.
String stockStateLabel(BuildContext context, String? state) => switch (state) {
  kAvailable => context.l10n.stateInStock,
  kRepairing => context.l10n.stateBeingRepaired,
  kSold => context.l10n.stateSold,
  // A state this build has never seen still reads as itself — that is
  // what keeps an old record visible instead of blank.
  _ => kStockLabels[state] ?? state ?? '',
};

String stockTabLabel(BuildContext context, StockTab tab) => switch (tab) {
  StockTab.available => context.l10n.stateInStock,
  StockTab.repairing => context.l10n.tabRepairing,
  StockTab.sold => context.l10n.stateSold,
  StockTab.all => context.l10n.all,
};

String productTabLabel(BuildContext context, ProductTab tab) => switch (tab) {
  ProductTab.all => context.l10n.all,
  ProductTab.toOrder => context.l10n.tabToOrder,
  ProductTab.outOfStock => context.l10n.tabOutOfStock,
};

String stockLevelLabel(BuildContext context, StockLevel level) =>
    switch (level) {
      StockLevel.inStock => context.l10n.stateInStock,
      StockLevel.low => context.l10n.levelLow,
      StockLevel.outOfStock => context.l10n.tabOutOfStock,
    };

String enquiryTabLabel(BuildContext context, EnquiryTab tab) => switch (tab) {
  EnquiryTab.open => context.l10n.tabOpen,
  EnquiryTab.dueToday => context.l10n.tabDueTodayLower,
  EnquiryTab.overdue => context.l10n.tabOverdue,
  EnquiryTab.won => context.l10n.tabWon,
  EnquiryTab.all => context.l10n.all,
};

/// A service order's status, and the tabs that are built from the same
/// strings. Both go through here so a tab and the status it filters on cannot
/// end up with two different words.
String serviceStatusLabel(BuildContext context, String status) =>
    switch (status) {
      'Open' => context.l10n.tabOpen,
      'Due Today' => context.l10n.tabDueToday,
      'Overdue' => context.l10n.tabOverdue,
      'All' => context.l10n.all,
      'Received' => context.l10n.statusReceived,
      'In Progress' => context.l10n.statusInProgress,
      'Parts Awaiting' => context.l10n.statusPartsAwaiting,
      'Awaiting Customer Approval' => context.l10n.statusAwaitingApproval,
      'Ready' => context.l10n.statusReady,
      'Completed' => context.l10n.statusCompleted,
      'Returned' => context.l10n.statusReturned,
      // A status an older or newer build wrote. Shown as itself; the list
      // would otherwise lose the order entirely.
      _ => status,
    };

String labelKindLabel(BuildContext context, LabelTargetKind? kind) =>
    switch (kind) {
      LabelTargetKind.product => context.l10n.kindProduct,
      LabelTargetKind.secondHand => context.l10n.kindSecondHand,
      LabelTargetKind.service => context.l10n.kindServiceOrder,
      LabelTargetKind.sale => context.l10n.kindSale,
      null => context.l10n.unreadableKind,
    };

String optionKindLabel(BuildContext context, OptionKind kind) => switch (kind) {
  OptionKind.brands => context.l10n.optionBrands,
  OptionKind.suppliers => context.l10n.optionSuppliers,
  OptionKind.colours => context.l10n.optionColours,
  OptionKind.categories => context.l10n.optionCategories,
  OptionKind.complaintTypes => context.l10n.optionComplaintTypes,
  OptionKind.accessories => context.l10n.optionAccessories,
  OptionKind.lockTypes => context.l10n.optionLockTypes,
  OptionKind.ram => context.l10n.optionRam,
  OptionKind.rom => context.l10n.optionRom,
  OptionKind.expenseKinds => context.l10n.optionExpenseKinds,
};

/// A condition-checklist item, by its stored key. The English is the same
/// sentence `condition_grade.dart` carries; the key is what is stored, so the
/// answers survive a change of language.
String checklistLabel(BuildContext context, String key, String fallback) =>
    switch (key) {
      'display_clarity' => context.l10n.chkDisplayClarity,
      'white_spots' => context.l10n.chkWhiteSpots,
      'display_replaced' => context.l10n.chkDisplayReplaced,
      'physical_damage' => context.l10n.chkPhysicalDamage,
      'face_touch_id' => context.l10n.chkFaceTouchId,
      'icloud_lock' => context.l10n.chkIcloudLock,
      'battery_health' => context.l10n.chkBatteryHealth,
      'true_tone' => context.l10n.chkTrueTone,
      'front_camera' => context.l10n.chkFrontCamera,
      'rear_camera' => context.l10n.chkRearCamera,
      'earpiece' => context.l10n.chkEarpiece,
      'loudspeaker' => context.l10n.chkLoudspeaker,
      'microphone' => context.l10n.chkMicrophone,
      'mobile_data' => context.l10n.chkMobileData,
      'bluetooth' => context.l10n.chkBluetooth,
      'wifi' => context.l10n.chkWifi,
      'power_button' => context.l10n.chkPowerButton,
      'volume_buttons' => context.l10n.chkVolumeButtons,
      'mute_switch' => context.l10n.chkMuteSwitch,
      'lightning_port' => context.l10n.chkLightningPort,
      'sim_slot' => context.l10n.chkSimSlot,
      'flashlight' => context.l10n.chkFlashlight,
      'fingerprint' => context.l10n.chkFingerprint,
      'face_unlock' => context.l10n.chkFaceUnlock,
      'charging_port' => context.l10n.chkChargingPort,
      'sim_slot_1' => context.l10n.chkSimSlot1,
      'sim_slot_2' => context.l10n.chkSimSlot2,
      'sd_card_slot' => context.l10n.chkSdCardSlot,
      'proximity_sensor' => context.l10n.chkProximitySensor,
      // An item the shop added to its own checklist is in its own words.
      _ => fallback,
    };

/// A checklist group — Display, Camera, Audio...
String checklistCategoryLabel(BuildContext context, String category) =>
    switch (category) {
      'Display' => context.l10n.catDisplay,
      'Physical' => context.l10n.catPhysical,
      'Security' => context.l10n.catSecurity,
      'Battery' => context.l10n.catBattery,
      'Camera' => context.l10n.catCamera,
      'Audio' => context.l10n.catAudio,
      'Connectivity' => context.l10n.catConnectivity,
      'SIM' => context.l10n.catSim,
      _ => category,
    };

String orderLifecycleLabel(BuildContext context, OrderLifecycle l) =>
    switch (l) {
      OrderLifecycle.overdue => context.l10n.lifeOverdue,
      OrderLifecycle.open => context.l10n.lifeInShop,
      OrderLifecycle.closed => context.l10n.lifeFinished,
    };

String enquiryLifecycleLabel(BuildContext context, EnquiryLifecycle l) =>
    switch (l) {
      EnquiryLifecycle.overdue => context.l10n.enqFollowUpOverdue,
      EnquiryLifecycle.open => context.l10n.enqOpen,
      EnquiryLifecycle.closed => context.l10n.enqDealtWith,
    };

String stockMoveLabel(BuildContext context, StockMoveKind k) => switch (k) {
  StockMoveKind.received => context.l10n.moveReceived,
  StockMoveKind.sold => context.l10n.moveSold,
  StockMoveKind.returned => context.l10n.moveReturned,
  StockMoveKind.adjustedUp => context.l10n.moveAdjustedUp,
  StockMoveKind.adjustedDown => context.l10n.moveAdjustedDown,
  StockMoveKind.damaged => context.l10n.moveDamaged,
  StockMoveKind.usedOnRepair => context.l10n.moveUsedOnRepair,
};

String scannerModeLabel(BuildContext context, ScannerMode m) => switch (m) {
  ScannerMode.label => context.l10n.scanModeLabel,
  ScannerMode.intakeService => context.l10n.scanModeRepair,
  ScannerMode.intakePurchase => context.l10n.scanModePurchase,
};

String scannerModeHint(BuildContext context, ScannerMode m) => switch (m) {
  ScannerMode.label => context.l10n.scanHintLabel,
  ScannerMode.intakeService => context.l10n.scanHintRepair,
  ScannerMode.intakePurchase => context.l10n.scanHintPurchase,
};

String reportPeriodLabel(BuildContext context, ReportPeriod p) => switch (p) {
  ReportPeriod.today => context.l10n.periodToday,
  ReportPeriod.sevenDays => context.l10n.period7,
  ReportPeriod.thirtyDays => context.l10n.period30,
  ReportPeriod.thisMonth => context.l10n.periodMonth,
  ReportPeriod.custom => context.l10n.periodCustom,
};

/// A report figure's title and basis in the shop's language. Keyed by the
/// English label the report builds it with; one this build does not know
/// shows as written.
(String, String) reportFigureText(
  BuildContext context,
  String label,
  String note,
) => switch (label) {
  'Takings' => (context.l10n.figTakings, context.l10n.figTakingsNote),
  'Service revenue' => (context.l10n.figService, context.l10n.figServiceNote),
  'Second-hand margin' => (context.l10n.figMargin, context.l10n.figMarginNote),
  'Outstanding' => (
    context.l10n.figOutstanding,
    context.l10n.figOutstandingNote,
  ),
  _ => (label, note),
};

String optionKindHint(BuildContext context, OptionKind kind) => switch (kind) {
  OptionKind.brands => context.l10n.hintBrands,
  OptionKind.suppliers => context.l10n.hintSuppliers,
  OptionKind.colours => context.l10n.hintColours,
  OptionKind.categories => context.l10n.hintCategories,
  OptionKind.complaintTypes => context.l10n.hintComplaintTypes,
  OptionKind.accessories => context.l10n.hintAccessories,
  OptionKind.lockTypes => context.l10n.hintLockTypes,
  OptionKind.ram => context.l10n.hintRam,
  OptionKind.rom => context.l10n.hintRom,
  OptionKind.expenseKinds => context.l10n.hintExpenseKinds,
};
