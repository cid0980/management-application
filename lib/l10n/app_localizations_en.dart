// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shop Manager';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navSecondHand => 'Second-Hand';

  @override
  String get navProducts => 'Products';

  @override
  String get navService => 'Service';

  @override
  String get navSales => 'Sales';

  @override
  String get navDuePayments => 'Due Payments';

  @override
  String get navEnquiries => 'Enquiries';

  @override
  String get navScanner => 'Scanner';

  @override
  String get navLabels => 'Labels';

  @override
  String get navSettings => 'Settings';

  @override
  String get navReports => 'Reports';

  @override
  String get navStaff => 'Staff';

  @override
  String get navLogout => 'Logout';

  @override
  String get tabHome => 'Home';

  @override
  String get tabMobiles => 'Mobiles';

  @override
  String get tabScan => 'Scan';

  @override
  String get tabMore => 'More';

  @override
  String get signInSubtitle => 'Sign in to your shop.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get setUpNewShop => 'Set up a new shop';

  @override
  String get forgottenPassword => 'Forgotten password';

  @override
  String get createShopTitle => 'Set up your shop';

  @override
  String get shopName => 'Shop name';

  @override
  String get shopPhone => 'Phone';

  @override
  String get shopAddress => 'Address';

  @override
  String get shopGstin => 'GSTIN';

  @override
  String get createShop => 'Create shop';

  @override
  String get language => 'Language';

  @override
  String get languageHint =>
      'The language this shop works in. Everyone here sees the same one; you can change it later in Settings.';

  @override
  String get languageSaved => 'Language saved';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String greetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get overdueServiceOrders => 'Overdue service orders';

  @override
  String get today => 'Today';

  @override
  String get completedBillsOnly => 'Completed bills only';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get newServiceOrder => 'New service order';

  @override
  String get newPurchase => 'New purchase';

  @override
  String get newSale => 'New sale';

  @override
  String get tilePendingOrders => 'Pending Orders';

  @override
  String get tileOverdue => 'Overdue';

  @override
  String get tileDueToday => 'Due Today';

  @override
  String get tileLowStock => 'Low Stock';

  @override
  String get tileDuePayments => 'Due Payments';

  @override
  String get tilePendingBills => 'Pending Bills';

  @override
  String get tileOpenEnquiries => 'Open Enquiries';

  @override
  String get tileCustomers => 'Customers';

  @override
  String get tileNewToday => 'New Today';

  @override
  String get recentOrders => 'Recent orders';

  @override
  String get nothingTakenInYet => 'Nothing taken in yet';

  @override
  String get couldNotBeRead => 'Could not be read';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get signUpSubtitle => 'Create an account, then set up your shop.';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String resetLinkSent(String email) {
    return 'Reset link sent to $email';
  }

  @override
  String get customerBookFailed => 'The customer book could not be loaded';

  @override
  String get tryAgain => 'Try again';

  @override
  String get searchNameOrNumber => 'Name or number';

  @override
  String get add => 'Add';

  @override
  String addNamed(String what) {
    return 'Add $what';
  }

  @override
  String get noNameGiven => 'No name given';

  @override
  String get nobodyInBookYet => 'Nobody in the book yet';

  @override
  String noMatchFor(String query) {
    return 'No match for \"$query\"';
  }

  @override
  String noCustomer(String id) {
    return 'No customer $id';
  }

  @override
  String get edit => 'Edit';

  @override
  String get details => 'Details';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get secondNumber => 'Second number';

  @override
  String get name => 'Name';

  @override
  String get address => 'Address';

  @override
  String get notes => 'Notes';

  @override
  String get soldToTheShop => 'Sold to the shop';

  @override
  String get nothingYet => 'Nothing yet.';

  @override
  String wallet(String amount) {
    return 'Wallet ₹$amount';
  }

  @override
  String get addCredit => 'Add credit';

  @override
  String get spend => 'Spend';

  @override
  String get noWalletMoves => 'No wallet moves yet.';

  @override
  String get addCreditToWallet => 'Add credit to the wallet';

  @override
  String get spendFromWallet => 'Spend from the wallet';

  @override
  String get amount => 'Amount';

  @override
  String get whatItIsFor => 'What it is for';

  @override
  String get required => 'Required';

  @override
  String get apply => 'Apply';

  @override
  String walletIsNow(String amount) {
    return 'Wallet is now ₹$amount';
  }

  @override
  String get addACustomer => 'Add a customer';

  @override
  String get discardThisDraft => 'Discard this draft';

  @override
  String get howTheShopFindsThem => 'How the shop finds them again';

  @override
  String get nameOptionalHelp => 'Optional — a number on its own is a customer';

  @override
  String savedNamed(String what) {
    return 'Saved $what';
  }

  @override
  String noSecondHandRecord(String id) {
    return 'No second-hand record $id.';
  }

  @override
  String get deletedLabelNote =>
      'A label scanned for a record that has since been deleted lands here — the label number is still worth noting down.';

  @override
  String gradeNamed(String grade) {
    return 'Grade $grade';
  }

  @override
  String labelNamed(String number) {
    return 'Label $number';
  }

  @override
  String get device => 'Device';

  @override
  String get money => 'Money';

  @override
  String get repairs => 'Repairs';

  @override
  String get condition => 'Condition';

  @override
  String get seller => 'Seller';

  @override
  String get brand => 'Brand';

  @override
  String get model => 'Model';

  @override
  String get variant => 'Variant';

  @override
  String get colour => 'Colour';

  @override
  String get imei2 => 'IMEI 2';

  @override
  String get serial => 'Serial';

  @override
  String get paidToSeller => 'Paid to seller';

  @override
  String get otherCosts => 'Other costs';

  @override
  String get totalCost => 'Total cost';

  @override
  String get asking => 'Asking';

  @override
  String get expectedProfit => 'Expected profit';

  @override
  String get realisedProfit => 'Realised profit';

  @override
  String get notSoldYet => 'not sold yet';

  @override
  String get storedGrade => 'Stored grade';

  @override
  String get fromTheChecklist => 'From the checklist';

  @override
  String get answered => 'Answered';

  @override
  String outOf(String done, String total) {
    return '$done of $total';
  }

  @override
  String get setByHand => 'Set by hand';

  @override
  String get criticalFaultsOpen => 'Critical faults open';

  @override
  String get notGraded => 'not graded';

  @override
  String get idProof => 'ID proof';

  @override
  String get notRecorded => 'not recorded';

  @override
  String get signed => 'Signed';

  @override
  String get yes => 'yes';

  @override
  String get no => 'no';

  @override
  String get backOnTheShelf => 'Back on the shelf';

  @override
  String get movedToTheBench => 'Moved to the bench';

  @override
  String get repairFinished => 'Repair finished';

  @override
  String get sendToTheBench => 'Send to the bench';

  @override
  String get markSold => 'Mark sold';

  @override
  String get assignAndPrintLabel => 'Assign and print a label';

  @override
  String get takeInAHandset => 'Take in a handset';

  @override
  String get editPurchase => 'Edit purchase';

  @override
  String get imeiAndSerial => 'IMEI & serial';

  @override
  String get pricing => 'Pricing';

  @override
  String get repairAndRefurb => 'Repair & refurbishment';

  @override
  String get addARepair => 'Add a repair';

  @override
  String get stillOnTheBench => 'Still on the bench';

  @override
  String get stillOnTheBenchHint =>
      'Kept out of the sale picker until the repair is done.';

  @override
  String get conditionAndGrade => 'Condition & grade';

  @override
  String get photos => 'Photos';

  @override
  String get frontView => 'Front view';

  @override
  String photoNumbered(String number) {
    return 'Photo $number';
  }

  @override
  String get addTheFrontView => 'Add the front view';

  @override
  String get addAPhoto => 'Add a photo';

  @override
  String get sellerSigned => 'Seller has signed the declaration';

  @override
  String get sellerSignedHint =>
      'Needed only to print it — a declaration nobody signed looks like proof.';

  @override
  String get saveAndPrint => 'Save & print';

  @override
  String get repairDoneBeforeResale => 'Repair done before resale';

  @override
  String get whatWasDone => 'What was done';

  @override
  String get cost => 'Cost';

  @override
  String get worthALook => 'Worth a look';

  @override
  String get notGradedNothingAnswered => 'Not graded — nothing answered yet';

  @override
  String criticalNamed(String faults) {
    return 'Critical: $faults';
  }

  @override
  String get overrideLabel => 'Override: ';

  @override
  String get criticalCapsGrade => 'Critical — caps the grade';

  @override
  String costNamed(String amount) {
    return 'Cost ₹$amount';
  }

  @override
  String expectedProfitNamed(String amount) {
    return 'Expected profit ₹$amount';
  }

  @override
  String get stockCouldNotBeLoaded => 'Stock could not be loaded';

  @override
  String get searchStock => 'Brand, model, IMEI, label or seller';

  @override
  String askingTotal(String amount) {
    return 'asking ₹$amount';
  }

  @override
  String nothingInTab(String tab) {
    return 'Nothing in $tab';
  }

  @override
  String get takeAHandsetIn => 'Take a handset in with the button below.';

  @override
  String get stockSearchCovers =>
      'The search covers brand, model, IMEI, label number and seller.';

  @override
  String get takeIn => 'Take in';

  @override
  String soldMade(String price, String profit) {
    return 'Sold ₹$price · made ₹$profit';
  }

  @override
  String askingCost(String asking, String cost) {
    return 'Asking ₹$asking · cost ₹$cost';
  }

  @override
  String declarationQueued(String what) {
    return 'Saved $what — declaration queued to print';
  }

  @override
  String addedToShopLists(String count) {
    return 'Added to the shop lists: $count new value(s)';
  }

  @override
  String noProduct(String id) {
    return 'No product $id.';
  }

  @override
  String get deletedShelfLabelNote =>
      'A shelf label scanned for a product that has since been deleted lands here — the label number is still worth noting down.';

  @override
  String get outOfStockCannotSell =>
      'Out of stock — this cannot be sold until some comes in.';

  @override
  String atOrBelowReorder(String level) {
    return 'At or below the reorder level of $level';
  }

  @override
  String historyDisagreesStock(String ledger, String count) {
    return 'The history adds up to $ledger, not $count. This record needs looking at.';
  }

  @override
  String get whatItIs => 'What it is';

  @override
  String get category => 'Category';

  @override
  String get notCategorised => 'not categorised';

  @override
  String get supplier => 'Supplier';

  @override
  String get costPrice => 'Cost price';

  @override
  String get sellingPrice => 'Selling price';

  @override
  String get printedMaximum => 'Printed maximum';

  @override
  String get printedMaximumMrp => 'Printed maximum (MRP)';

  @override
  String get profitPerUnit => 'Profit per unit';

  @override
  String profitPerUnitNamed(String amount) {
    return 'Profit per unit ₹$amount';
  }

  @override
  String get stockAtCost => 'Stock at cost';

  @override
  String get stockAtRetail => 'Stock at retail';

  @override
  String get reordering => 'Reordering';

  @override
  String get reorderLevel => 'Reorder level';

  @override
  String get noReorderLevelSet =>
      'not set — this will only ever show as out of stock';

  @override
  String get suggestedOrder => 'Suggested order';

  @override
  String get stockHistory => 'Stock history';

  @override
  String get noStockHistory =>
      'Nothing yet. Record the first delivery and the history will say where the stock came from.';

  @override
  String get receive => 'Receive';

  @override
  String get stockTake => 'Stock-take';

  @override
  String get damaged => 'Damaged';

  @override
  String reprintLabel(String number) {
    return 'Reprint label $number';
  }

  @override
  String nowOnTheShelf(String count) {
    return 'Now $count on the shelf';
  }

  @override
  String savedReceiveStock(String what) {
    return 'Saved $what — receive stock from its page to set the count';
  }

  @override
  String get addAProduct => 'Add a product';

  @override
  String get editProduct => 'Edit product';

  @override
  String get whatTheCounterSearches => 'What the counter searches for';

  @override
  String get variantFits => 'Variant (model it fits, size)';

  @override
  String get whenToReorder => 'When to reorder';

  @override
  String get reorderLevelHelp =>
      'Leave empty for no low-stock alert on this product';

  @override
  String onTheShelfNow(String count) {
    return 'On the shelf now: $count. Stock is changed from the product page, with a reason — never from this form.';
  }

  @override
  String get newProductStartsAtZero =>
      'A new product starts at zero. Its first delivery is recorded from its page, so the history says where the stock came from.';

  @override
  String get photo => 'Photo';

  @override
  String get mainPhoto => 'Main photo';

  @override
  String get addAnother => 'Add another';

  @override
  String get productsCouldNotBeLoaded => 'Products could not be loaded';

  @override
  String get searchProducts => 'Name, brand, category, SKU or supplier';

  @override
  String costRetail(String cost, String retail) {
    return 'cost ₹$cost · retail ₹$retail';
  }

  @override
  String get nothingOnTheListYet =>
      'Nothing on the list yet. Add a product with the button below.';

  @override
  String reorderAt(String level) {
    return 'Reorder at $level';
  }

  @override
  String get noReorderLevel => 'No reorder level set';

  @override
  String get skuHelp => 'The shop\'s own code — not the shop label';

  @override
  String noServiceOrder(String id) {
    return 'No service order $id.';
  }

  @override
  String get deletedJobCardNote =>
      'A job card scanned for an order that has since been deleted lands here — the order number is still worth noting down.';

  @override
  String get customer => 'Customer';

  @override
  String get lock => 'Lock';

  @override
  String get unlockWith => 'Unlock with';

  @override
  String get leftWithIt => 'Left with it';

  @override
  String get nothingValue => 'nothing';

  @override
  String get complaints => 'Complaints';

  @override
  String get estimateQuoted => 'Estimate quoted';

  @override
  String get rawMaterial => 'Raw material';

  @override
  String get outsideLabour => 'Outside labour';

  @override
  String get costs => 'Costs';

  @override
  String get profitAtEstimate => 'Profit at the estimate';

  @override
  String get charged => 'Charged';

  @override
  String get notChargedYet => 'not charged yet';

  @override
  String get profitMade => 'Profit made';

  @override
  String get schedule => 'Schedule';

  @override
  String get cameIn => 'Came in';

  @override
  String get promised => 'Promised';

  @override
  String get handedBack => 'Handed back';

  @override
  String get technician => 'Technician';

  @override
  String get nobodyYet => 'nobody yet';

  @override
  String get notSet => 'not set';

  @override
  String handedBackOn(String date) {
    return 'Handed back on $date. Nothing more is owed on it.';
  }

  @override
  String get status => 'Status';

  @override
  String get completedIsNotHere =>
      'Completed is not here for anyone — a phone goes back by passing the pre-delivery checklist below.';

  @override
  String statusNamed(String status) {
    return 'Status: $status';
  }

  @override
  String get preDeliveryChecklist => 'Pre-delivery checklist';

  @override
  String get noChecklistConfigured =>
      'No checklist configured in settings, so there is nothing to verify before handing a phone back.';

  @override
  String savedJobCard(String what) {
    return 'Saved $what — job card queued to print';
  }

  @override
  String get takeInARepair => 'Take in a repair';

  @override
  String editNamed(String what) {
    return 'Edit $what';
  }

  @override
  String get findsWhoeverBeenHere => 'Finds whoever has been here before';

  @override
  String get patternAs => 'Pattern, as 1-2-3-6-9';

  @override
  String get code => 'Code';

  @override
  String get leftWithTheDevice => 'Left with the device';

  @override
  String get issuesAndComplaints => 'Issues & complaints';

  @override
  String get whatTheCustomerSaid => 'What the customer said';

  @override
  String get estimateAndSchedule => 'Estimate & schedule';

  @override
  String costsProfitNamed(String costs, String profit) {
    return 'Costs ₹$costs · profit at the estimate ₹$profit';
  }

  @override
  String get deviceCameIn => 'Device came in';

  @override
  String get promisedToCustomer => 'Promised to the customer';

  @override
  String get nobodyOnThatNumber =>
      'Nobody in the book on that number — the order will carry the number and the name typed here.';

  @override
  String get serviceOrdersCouldNotLoad => 'Service orders could not be loaded';

  @override
  String get searchServiceOrders => 'Order number, customer, device or IMEI';

  @override
  String get noComplaintRecorded => 'No complaint recorded';

  @override
  String get notSetTitle => 'Not set';

  @override
  String stockSummary(String count, String cost, String asking) {
    return '$count on hand · cost ₹$cost · asking ₹$asking';
  }

  @override
  String productSummary(
    String lines,
    String units,
    String cost,
    String retail,
  ) {
    return '$lines product(s) · $units unit(s) · cost ₹$cost · retail ₹$retail';
  }

  @override
  String get nothingOutstanding => 'Nothing outstanding';

  @override
  String get financedNotCountedHere =>
      'Financed sales are not counted here — those customers owe the shop nothing.';

  @override
  String owedByCustomers(String total, String count) {
    return '₹$total owed by $count customer(s)';
  }

  @override
  String get financedNotHere =>
      'Financed sales are not here: the customer owes nothing, and the financier\'s settlement is a different ledger.';

  @override
  String oldestDays(String days) {
    return 'oldest $days day(s)';
  }

  @override
  String billedPaidMethod(String total, String paid, String method) {
    return '₹$total billed · ₹$paid paid · $method';
  }

  @override
  String get openTheCustomer => 'Open the customer';

  @override
  String noSale(String id) {
    return 'No sale $id';
  }

  @override
  String get draftNothingOffShelf => 'Draft — nothing has come off the shelf';

  @override
  String get completedStatus => 'Completed';

  @override
  String get cancelledStatus => 'Cancelled';

  @override
  String get draftStatus => 'Draft';

  @override
  String get doneStatus => 'Done';

  @override
  String get items => 'Items';

  @override
  String get bill => 'Bill';

  @override
  String get gross => 'Gross';

  @override
  String get discount => 'Discount';

  @override
  String get total => 'Total';

  @override
  String get paid => 'Paid';

  @override
  String get fromTheWallet => 'From the wallet';

  @override
  String get customerOwes => 'Customer owes';

  @override
  String get balance => 'Balance';

  @override
  String nothingFinancedThrough(String method) {
    return 'nothing — financed through $method';
  }

  @override
  String get finishThisBill => 'Finish this bill';

  @override
  String collectAmount(Object amount) {
    return 'Collect ₹$amount';
  }

  @override
  String get cancelThisBill => 'Cancel this bill';

  @override
  String get printInvoice => 'Print invoice';

  @override
  String invoiceQueued(String number) {
    return 'Invoice $number queued to print';
  }

  @override
  String collectedStillOwed(String amount, String remaining) {
    return 'Collected ₹$amount — ₹$remaining still owed';
  }

  @override
  String collectedSettled(String amount) {
    return 'Collected ₹$amount — settled';
  }

  @override
  String get cancelledHandsetsBack =>
      'Cancelled — the handsets are back on the shelf';

  @override
  String get draftCancelled => 'Draft cancelled';

  @override
  String get collectFromCustomer => 'Collect from the customer';

  @override
  String owedPartPaymentsFine(String owed) {
    return '₹$owed owed — part payments are fine';
  }

  @override
  String get collect => 'Collect';

  @override
  String get handsetsGoBack =>
      'Any handsets on this bill go back on the shelf. The bill itself is kept, marked cancelled.';

  @override
  String get nothingToPutBack =>
      'Nothing has come off the shelf, so there is nothing to put back.';

  @override
  String get why => 'Why';

  @override
  String get goesOnTheRecord => 'Goes on the record';

  @override
  String get keepIt => 'Keep it';

  @override
  String get keptAsDraft => 'Kept as a draft — nothing has come off the shelf';

  @override
  String get newSaleTitle => 'New sale';

  @override
  String get editBill => 'Edit bill';

  @override
  String get closeWithoutSaving => 'Close without saving';

  @override
  String get addFromStock => 'Add from stock';

  @override
  String get addALine => 'Add a line';

  @override
  String get method => 'Method';

  @override
  String get paidAtTheCounter => 'Paid at the counter';

  @override
  String get ofWhichFromWallet => 'Of which, from the wallet';

  @override
  String walletCovers(String balance, String covers) {
    return 'Wallet holds ₹$balance — covers ₹$covers of this bill';
  }

  @override
  String get billSummary => 'Bill summary';

  @override
  String get keepAsDraft => 'Keep as draft';

  @override
  String get completeSale => 'Complete sale';

  @override
  String get nobodyOnThatNumberBill =>
      'Nobody in the book on that number — the bill will carry the number typed here.';

  @override
  String get inStock => 'In stock';

  @override
  String get nothingSellable => 'Nothing sellable in second-hand stock.';

  @override
  String get notSellable => 'Not sellable';

  @override
  String get salesCouldNotBeLoaded => 'Sales could not be loaded';

  @override
  String get searchSales => 'Invoice, customer, item or IMEI';

  @override
  String get drafts => 'Drafts';

  @override
  String get all => 'All';

  @override
  String owedByCustomersShort(String amount) {
    return '₹$amount owed by customers';
  }

  @override
  String get noBillsHereYet => 'No bills here yet';

  @override
  String financedOwesNothing(String total) {
    return '₹$total · financed, customer owes nothing';
  }

  @override
  String totalStillOwed(String total, String balance) {
    return '₹$total · ₹$balance still owed';
  }

  @override
  String totalPaid(String total) {
    return '₹$total · paid';
  }

  @override
  String keptAsDraftItems(String count) {
    return 'Kept as a draft — nothing has come off the shelf ($count item(s))';
  }

  @override
  String billStillOwed(String balance) {
    return ', ₹$balance still owed';
  }

  @override
  String get addAProductLine => 'Add a product';

  @override
  String get payment => 'Payment';

  @override
  String noEnquiry(String id) {
    return 'No enquiry $id';
  }

  @override
  String get whoAsked => 'Who asked';

  @override
  String get takenBy => 'Taken by';

  @override
  String get whatTheyAsked => 'What they asked';

  @override
  String get about => 'About';

  @override
  String get inTheirWords => 'In their words';

  @override
  String get theirBudget => 'Their budget';

  @override
  String get theyDidNotSay => 'they did not say';

  @override
  String get quoted => 'Quoted';

  @override
  String get notQuoted => 'not quoted';

  @override
  String quotedAgainstBudget(String quoted, String budget) {
    return 'Quoted ₹$quoted against a ₹$budget budget.';
  }

  @override
  String get followUp => 'Follow-up';

  @override
  String get askedOn => 'Asked on';

  @override
  String get ringBack => 'Ring back';

  @override
  String get dealtWith => 'Dealt with';

  @override
  String get whatItBecame => 'What it became';

  @override
  String get setAFollowUp => 'Set a follow-up';

  @override
  String get changeTheFollowUp => 'Change the follow-up';

  @override
  String ringBackOn(String date) {
    return 'Ring back on $date';
  }

  @override
  String savedColon(String what) {
    return 'Saved: $what';
  }

  @override
  String get recordAnEnquiry => 'Record an enquiry';

  @override
  String get editEnquiry => 'Edit enquiry';

  @override
  String get pointIsRingingBack =>
      'The point of recording this is ringing them back';

  @override
  String get nameOptionalEnough => 'Optional — a number on its own is enough';

  @override
  String get inTheirWordsHelp =>
      'In their words where you can — this is what makes the record worth keeping';

  @override
  String get brandIfNamed => 'Brand, if they named one';

  @override
  String get modelIfNamed => 'Model, if they named one';

  @override
  String get whatTheyWouldSpend => 'What they said they would spend';

  @override
  String get leaveEmptyIfNotSaid => 'Leave empty if they did not say';

  @override
  String get whatTheyWereQuoted => 'What they were quoted';

  @override
  String get ringThemBackOn => 'Ring them back on';

  @override
  String get notSetWillNotComeUp =>
      'Not set — this will not come up again on its own';

  @override
  String get noFollowUpNeeded => 'No follow-up needed';

  @override
  String get enquiriesCouldNotLoad => 'Enquiries could not be loaded';

  @override
  String get searchEnquiries => 'Customer, number, device or what they asked';

  @override
  String get record => 'Record';

  @override
  String get noFollowUpSet => 'No follow-up set';

  @override
  String ringBackNamed(String when) {
    return 'Ring back $when';
  }

  @override
  String get cameraNotWired =>
      'Camera scanning is not wired up yet. Type or paste the number — the same rules apply either way.';

  @override
  String get labelNumberOrImei => 'Label number or IMEI';

  @override
  String get labelIsFiveDigits =>
      'A shop label is five digits; an IMEI is fourteen to sixteen';

  @override
  String get lookItUp => 'Look it up';

  @override
  String labelNotInRegistry(String number) {
    return 'Label $number is not in the registry';
  }

  @override
  String get nothingPrintedUnder =>
      'Nothing has been printed under that number. Check the number on the sticker, or look it up in the registry.';

  @override
  String get openTheRegistry => 'Open the registry';

  @override
  String get notANumberShopUses => 'Not a number this shop uses';

  @override
  String get nothingWasScanned => 'Nothing was scanned.';

  @override
  String scannedNeither(String raw) {
    return 'Scanned \"$raw\". Shop labels are five digits and an IMEI is fourteen to sixteen — this is neither, so it is probably a barcode off a retail box.';
  }

  @override
  String get noTitleOnLabel => 'No title on the label';

  @override
  String get changedSincePrinted =>
      'Changed since this sticker was printed — the values above are the current ones.';

  @override
  String get printedByNewerBuild =>
      'This label was printed by a version of the app this one does not understand, so there is nowhere to open. What is shown above is what was printed.';

  @override
  String get recordBehindLabelGone =>
      'The record behind this label is gone. What is shown above is what was printed on it.';

  @override
  String get notInDeviceTable =>
      'Not in the device table — the brand and model will need typing in.';

  @override
  String looksLikeDevice(String device) {
    return 'Looks like a $device. The form opens with that filled in, and stays editable.';
  }

  @override
  String get factoryImeiNotLabel =>
      'That is a factory IMEI, not a shop label — length alone tells them apart.';

  @override
  String get registryCouldNotLoad => 'The label registry could not be loaded';

  @override
  String nextLabel(String number) {
    return 'Next label: $number';
  }

  @override
  String get oneCounterExplainer =>
      'Numbers come off one counter for the whole shop, so two people assigning at the same moment cannot get the same one. Labels start at 26001.';

  @override
  String get searchLabels => 'Label number, record or what was printed';

  @override
  String get nothingPrintedYet =>
      'Nothing printed yet. A label is assigned from a record — open a handset or a repair and print one there.';

  @override
  String noLabelMatching(String query) {
    return 'No label matching \"$query\"';
  }

  @override
  String get unreadableKind => 'Unreadable kind';

  @override
  String reprintedTimes(String count) {
    return 'reprinted $count×';
  }

  @override
  String stickerOutOfDate(String fields) {
    return 'Sticker out of date: $fields';
  }

  @override
  String get recordGoneShowingPrinted =>
      'Record gone — showing what was printed';

  @override
  String get printThisLabelAgain => 'Print this label again';

  @override
  String get openTheRecord => 'Open the record';

  @override
  String labelSentToPrinter(String number) {
    return 'Label $number sent to the printer';
  }

  @override
  String get nothingRegisteredUnder =>
      'Nothing is registered under that number. If this is a sticker from the shop, quote the number at the counter.';

  @override
  String get whatThisIs => 'What this is';

  @override
  String get price => 'Price';

  @override
  String get someDetailsChanged =>
      'Some details have changed since this label was printed. What is shown here is current.';

  @override
  String get shownAsRecorded => 'Shown as currently recorded by the shop.';

  @override
  String get askAtTheCounter =>
      'This is what was printed on the label. Please ask at the counter for anything more.';

  @override
  String openNothingClosed(String open) {
    return '$open open · nothing closed yet';
  }

  @override
  String openWonOfClosed(String open, String won, String closed, String rate) {
    return '$open open · $won of $closed closed became business ($rate%)';
  }

  @override
  String changedSinceStickerFields(String fields) {
    return 'Changed since this sticker was printed: $fields. The values above are the current ones.';
  }

  @override
  String get factoryImeiIntake =>
      'That is a factory IMEI, not a shop label — length alone tells them apart. Did you mean to start an intake?';

  @override
  String figuresAreShort(String areas) {
    return 'These figures are short: $areas could not be read. Do not file this report.';
  }

  @override
  String get activity => 'Activity';

  @override
  String get billsCompleted => 'Bills completed';

  @override
  String get billsCancelled => 'Bills cancelled';

  @override
  String get jobsTakenIn => 'Jobs taken in';

  @override
  String get jobsCompleted => 'Jobs completed';

  @override
  String get handsetsBought => 'Handsets bought';

  @override
  String get handsetsSold => 'Handsets sold';

  @override
  String get customersAdded => 'Customers added';

  @override
  String get howMarginMadeUp => 'How the handset margin is made up';

  @override
  String soldForAmount(String amount) {
    return 'Sold for ₹$amount';
  }

  @override
  String costPurchaseRepairs(String amount) {
    return 'Cost ₹$amount — purchase, repairs and anything else spent';
  }

  @override
  String get nothingHappened => 'Nothing happened in this period.';

  @override
  String fromRecords(String count) {
    return 'from $count record(s)';
  }

  @override
  String get areaSales => 'sales';

  @override
  String get areaServiceOrders => 'service orders';

  @override
  String get areaSecondHandStock => 'second-hand stock';

  @override
  String get areaCustomers => 'customers';

  @override
  String get staffOffline =>
      'Staff cannot be managed while the app is offline — this page reads and writes the shop itself.';

  @override
  String workingHere(String count) {
    return '$count working here';
  }

  @override
  String get invited => 'Invited';

  @override
  String get invite => 'Invite';

  @override
  String get nobodyWaitingToJoin => 'Nobody is waiting to join';

  @override
  String claimedOnFirstSignIn(String role) {
    return '$role · claimed when they first sign in';
  }

  @override
  String get withdraw => 'Withdraw';

  @override
  String get inviteSomebody => 'Invite somebody';

  @override
  String get claimFirstSignIn => 'They claim it the first time they sign in';

  @override
  String get send => 'Send';

  @override
  String inviteSentTo(String email) {
    return 'Invite sent to $email';
  }

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleStaff => 'Staff';

  @override
  String get owner => 'Owner';

  @override
  String get you => 'You';

  @override
  String makeRole(String role) {
    return 'Make $role';
  }

  @override
  String get removeFromShop => 'Remove from shop';

  @override
  String get roleChanged => 'Role changed';

  @override
  String removeNamed(String name) {
    return 'Remove $name?';
  }

  @override
  String get loseAccessNow =>
      'They lose access to this shop straight away. Their work stays on the records they made.';

  @override
  String get keep => 'Keep';

  @override
  String get remove => 'Remove';

  @override
  String get removed => 'Removed';

  @override
  String get signOut => 'Sign out';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get everythingBelongsToShop =>
      'Everything this app records — stock, customers, sales, repairs — belongs to your shop and is visible only to you and the staff you add.';

  @override
  String get goesOnEveryBill => 'Goes on every bill and job card';

  @override
  String get gstinOptional => 'Optional — printed on invoices if you have one';

  @override
  String get createTheShop => 'Create the shop';

  @override
  String get changeLaterInSettings =>
      'You can change any of this later in Settings, and add staff by their email address.';

  @override
  String get settingsCouldNotLoad => 'Settings could not be loaded';

  @override
  String get listsGrowThemselves => 'These lists grow by themselves';

  @override
  String get listsGrowExplainer =>
      'A value typed into a form that is not on a list joins it, so the next person finds it in the dropdown. This page is for tidying up — removing what the shop no longer uses, or fixing something that got in.';

  @override
  String get emptyWillStartAgain =>
      'Empty. The next value typed into a form will start it off again.';

  @override
  String addToList(String list) {
    return 'Add to $list';
  }

  @override
  String addedValue(String value) {
    return 'Added \"$value\"';
  }

  @override
  String removeValue(String value) {
    return 'Remove \"$value\"?';
  }

  @override
  String get stopsBeingOffered =>
      'It stops being offered in forms. Records that already use it are not changed.';

  @override
  String removedValue(String value) {
    return 'Removed \"$value\"';
  }

  @override
  String get modelsByBrand => 'Models, by brand';

  @override
  String get noBrandsYet => 'No brands yet.';

  @override
  String get noModelsUnderBrand =>
      'None yet. The next model typed in under this brand will land here.';

  @override
  String removedModelFrom(String model, String brand) {
    return 'Removed \"$model\" from $brand';
  }

  @override
  String addModelUnder(String brand) {
    return 'Add a model under $brand';
  }

  @override
  String addedUnderBrand(String value, String brand) {
    return 'Added \"$value\" under $brand';
  }

  @override
  String get checklistHint =>
      'Every item has to be ticked before a repair can be handed back. The order is the order somebody works through the phone.';

  @override
  String get checklistEmpty =>
      'Empty, so there is nothing to verify and any repair can be handed back.';

  @override
  String get signedOut => 'Signed out';

  @override
  String get notFound => 'Not found';

  @override
  String noScreenFor(String uri) {
    return 'No screen for $uri';
  }

  @override
  String get labelTitle => 'Label';

  @override
  String get modelsOfferedHint =>
      'Offered on an intake once a brand is chosen — only that brand\'s models.';

  @override
  String modelCount(String count) {
    return '$count model(s)';
  }

  @override
  String get checklistEmptyCharged =>
      'Empty, so there is nothing to verify and any repair can be handed back once it has been charged.';

  @override
  String alreadyOnTheList(String value) {
    return '\"$value\" is already on the list';
  }

  @override
  String alreadyUnderBrand(String value, String brand) {
    return '\"$value\" is already under $brand';
  }

  @override
  String get stateInStock => 'In stock';

  @override
  String get stateBeingRepaired => 'Being repaired';

  @override
  String get stateSold => 'Sold';

  @override
  String get tabRepairing => 'Repairing';

  @override
  String get tabToOrder => 'To order';

  @override
  String get tabOutOfStock => 'Out of stock';

  @override
  String get levelLow => 'Low';

  @override
  String get tabOpen => 'Open';

  @override
  String get tabDueToday => 'Due Today';

  @override
  String get tabOverdue => 'Overdue';

  @override
  String get statusReceived => 'Received';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusPartsAwaiting => 'Parts Awaiting';

  @override
  String get statusAwaitingApproval => 'Awaiting Customer Approval';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusReturned => 'Returned';

  @override
  String get tabDueTodayLower => 'Due today';

  @override
  String get tabWon => 'Won';

  @override
  String get kindProduct => 'Product';

  @override
  String get kindSecondHand => 'Second-hand handset';

  @override
  String get kindServiceOrder => 'Service order';

  @override
  String get kindSale => 'Sale';

  @override
  String get optionBrands => 'Brands';

  @override
  String get optionSuppliers => 'Suppliers';

  @override
  String get optionColours => 'Colours';

  @override
  String get optionCategories => 'Product categories';

  @override
  String get optionComplaintTypes => 'Complaint types';

  @override
  String get optionAccessories => 'Accessories left with a device';

  @override
  String get optionLockTypes => 'Lock types';

  @override
  String openTheKind(String kind) {
    return 'Open the $kind';
  }

  @override
  String get yourName => 'Your name';

  @override
  String get continueLabel => 'Continue';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get labelPrinter => 'Label printer';

  @override
  String get printServerAddress => 'Print server address';

  @override
  String get saveAddress => 'Save address';

  @override
  String get howMany => 'How many';

  @override
  String get requiredGoesInHistory => 'Required — it goes in the history';

  @override
  String recordedCount(String count) {
    return 'Recorded: $count';
  }

  @override
  String get countedOnShelf => 'Counted on the shelf';

  @override
  String get differenceGoesInHistory => 'The difference goes in the history';

  @override
  String get correctIt => 'Correct it';

  @override
  String get cancelTheBill => 'Cancel the bill';

  @override
  String get onTheShelf => 'On the shelf';

  @override
  String get nothingInNewGoods => 'Nothing in new-goods stock.';

  @override
  String get noneOnTheShelf => 'None on the shelf';

  @override
  String get whatIsBeingCharged => 'What is being charged?';

  @override
  String get finalPrice => 'Final price';

  @override
  String get zeroIsAllowed =>
      'Zero is allowed — a goodwill repair is a decision';

  @override
  String get returnedWithoutRepair => 'Returned without being repaired';

  @override
  String get returnIt => 'Return it';

  @override
  String get whatCameOfIt => 'What came of it';

  @override
  String get whatDidThisBecome => 'What did this become?';

  @override
  String get saleRepairOrNote => 'Sale, repair, or a note';

  @override
  String get markWon => 'Mark won';

  @override
  String get startARepair => 'Start a repair';

  @override
  String get buyThisHandset => 'Buy this handset';

  @override
  String get printDeclaration => 'Print declaration';

  @override
  String get whatDidItGoOutAt => 'What did it go out at?';

  @override
  String get soldPrice => 'Sold price';

  @override
  String get whatItIsLine => 'What it is';

  @override
  String get priceLabel => 'Price';

  @override
  String get quantity => 'Quantity';

  @override
  String get discountRupees => 'Discount (₹)';

  @override
  String get handThePhoneBack => 'Hand the phone back';

  @override
  String get returnedUnrepaired => 'Returned unrepaired';

  @override
  String chargingAmount(String amount) {
    return 'Charging ₹$amount';
  }

  @override
  String get returnedToCustomer => 'Returned to the customer';

  @override
  String get helpWhatIsThis => 'What is this?';

  @override
  String get helpGotIt => 'Got it';

  @override
  String get fieldVariant => 'Storage / RAM';

  @override
  String get fieldAskingPrice => 'Selling price';

  @override
  String get fieldSellerName => 'Seller\'s name';

  @override
  String get fieldSellerPhone => 'Seller\'s phone number';

  @override
  String get checkWorks => 'Works';

  @override
  String get checklistTitle => 'Check each part';

  @override
  String get gradeTitle => 'Grade';

  @override
  String get profitTitle => 'Your profit';

  @override
  String get lossTitle => 'You will lose';

  @override
  String get helpStockTabsTitle => 'What the colours mean';

  @override
  String get helpBrand =>
      'The company that made the phone. Example: Samsung, Vivo, Apple. It is written on the back of the phone. Tap a name below to fill it quickly.';

  @override
  String get helpModel =>
      'The phone\'s model name. Example: Galaxy A54, Y21. Find it in Settings → About phone.';

  @override
  String get helpColour =>
      'The colour of the phone\'s back. Example: Black, Blue. Helps find the right phone on the shelf.';

  @override
  String get helpImei =>
      'A 15-digit number that belongs to this one phone only. Dial *#06# on the phone to see it. Copy it from the phone, not from the box — the box can belong to a different phone. Police use this number to trace stolen phones.';

  @override
  String get helpImei2 =>
      'Phones with two SIM slots have a second IMEI. *#06# shows both. Leave empty if there is only one.';

  @override
  String get helpSerial =>
      'The maker\'s serial number, found in Settings → About phone. Not needed for most phones — fill it if you have it.';

  @override
  String get helpPaid =>
      'The money you gave the person who sold you this phone. Example: 6000. Only numbers, no ₹ sign.';

  @override
  String get helpOtherCost =>
      'Any other money spent on this phone that is not a repair. Example: auto fare to collect it, cleaning, a new cover. Leave empty if none.';

  @override
  String get helpAsking =>
      'The price you want to sell this phone for. The green box below shows your profit straight away. If it turns red, you will lose money at this price.';

  @override
  String get helpProfit =>
      'Selling price minus everything spent: what you paid, repairs and other costs. Green means profit, red means loss.';

  @override
  String get helpRepairs =>
      'Work done to make this phone ready to sell, and what it cost. Example: new battery ₹800. It is added to the cost, so the profit stays correct.';

  @override
  String get helpBench =>
      'Turn this on if the phone is still being repaired. It will not be shown as ready to sell until you turn it off.';

  @override
  String get helpGrade =>
      'A letter for how good the phone is. A: everything works. B: 1 to 3 things not working. C: 4 or more not working, or the display was replaced or has white spots. D: damaged, bent or iCloud locked. The app works it out from the checks — tap a letter to choose it yourself.';

  @override
  String get helpChecklist =>
      'Everything starts as Working. Tap Not working only for what is broken. For questions like \"Display replaced\", tap Yes only if it is true.';

  @override
  String get helpPhotos =>
      'Take photos of the phone. The first one must be the front. Photos prove what state the phone was in when you bought it.';

  @override
  String get helpSellerName =>
      'Full name of the person who sold you this phone, as on their ID card.';

  @override
  String get helpSellerPhone =>
      'The seller\'s 10-digit mobile number. Needed if the police ask about this phone later.';

  @override
  String get helpIdProof =>
      'Which ID the seller showed, and its last 4 digits. Example: Aadhaar 4412. This protects the shop if the phone turns out to be stolen.';

  @override
  String get helpSigned =>
      'Turn on after the seller has signed the paper saying the phone is theirs to sell. Needed to print the declaration.';

  @override
  String get helpNotes =>
      'Anything else worth remembering about this phone. Example: small scratch on the camera, comes with charger.';

  @override
  String get helpSearchStock =>
      'Type anything you know about the phone — brand, model, the IMEI number, the label number or the seller\'s name — and the list shows only matching phones.';

  @override
  String get helpStockTabs =>
      'Green = ready to sell. Orange = being repaired. Grey = already sold. Tap a box to see only those phones.';

  @override
  String get chkFrontCamera => 'Front Camera (Clear dust)';

  @override
  String get chkRearCamera => 'Rear Camera (Clear dust)';

  @override
  String get chkFingerprint => 'Fingerprint Sensor';

  @override
  String get chkBatteryHealth => 'Battery Health %';

  @override
  String get newToShopList =>
      'New — it will be added to your shop\'s list when you save';

  @override
  String get pickBrandFirst => 'Choose the brand first to see its models';

  @override
  String exampleHint(String example) {
    return 'e.g. $example';
  }

  @override
  String wizStepOf(String n, String total) {
    return 'Step $n of $total';
  }

  @override
  String get wizPhoto => 'Photo';

  @override
  String get wizPhone => 'Phone';

  @override
  String get wizMoney => 'Money';

  @override
  String get wizPhotoTitle => 'Take a photo of the phone';

  @override
  String get wizPhotoHint =>
      'The front of the phone, screen on, so anyone can see what it looks like.';

  @override
  String get wizPhoneTitle => 'Which phone is it?';

  @override
  String get wizMoneyTitle => 'How much money?';

  @override
  String get wizSellerTitle => 'Who sold it to you?';

  @override
  String get wizNext => 'Next';

  @override
  String get wizBack => 'Back';

  @override
  String get wizMoreDetails => 'Add more details (optional)';

  @override
  String get wizHideDetails => 'Hide extra details';

  @override
  String get optionRam => 'RAM';

  @override
  String get optionRom => 'Storage (ROM)';

  @override
  String get chkDisplayClarity => 'Display Clarity';

  @override
  String get chkWhiteSpots => 'White Spots on Display';

  @override
  String get chkDisplayReplaced => 'Display Replaced';

  @override
  String get chkPhysicalDamage => 'Physical Damage / Bent';

  @override
  String get chkFaceTouchId => 'Face ID / Touch ID';

  @override
  String get chkIcloudLock => 'iCloud Lock Check';

  @override
  String get chkTrueTone => 'True Tone Display';

  @override
  String get chkEarpiece => 'Earpiece Speaker';

  @override
  String get chkLoudspeaker => 'Loudspeaker';

  @override
  String get chkMicrophone => 'Microphone';

  @override
  String get chkMobileData => 'Mobile Data';

  @override
  String get chkBluetooth => 'Bluetooth';

  @override
  String get chkWifi => 'Wi-Fi';

  @override
  String get chkPowerButton => 'Power Button';

  @override
  String get chkVolumeButtons => 'Volume Buttons';

  @override
  String get chkMuteSwitch => 'Mute Switch';

  @override
  String get chkLightningPort => 'Lightning / USB-C Port';

  @override
  String get chkSimSlot => 'SIM Slot';

  @override
  String get chkFlashlight => 'Flashlight';

  @override
  String get chkFaceUnlock => 'Face Unlock';

  @override
  String get chkChargingPort => 'Charging Port';

  @override
  String get chkSimSlot1 => 'SIM Slot 1';

  @override
  String get chkSimSlot2 => 'SIM Slot 2';

  @override
  String get chkSdCardSlot => 'SD Card Slot';

  @override
  String get chkProximitySensor => 'Proximity Sensor';

  @override
  String get catDisplay => 'Display';

  @override
  String get catPhysical => 'Physical';

  @override
  String get catSecurity => 'Security';

  @override
  String get catBattery => 'Battery';

  @override
  String get catCamera => 'Camera';

  @override
  String get catAudio => 'Audio';

  @override
  String get catConnectivity => 'Connectivity';

  @override
  String get catSim => 'SIM & card slots';

  @override
  String get checkNotWorking => 'Not working';

  @override
  String get answerYes => 'Yes';

  @override
  String get answerNo => 'No';

  @override
  String get checksCommon => 'Checks for every phone';

  @override
  String get checksIphone => 'iPhone checks';

  @override
  String get checksAndroid => 'Android checks';

  @override
  String get gradeAuto => 'Worked out from the checks';

  @override
  String get gradeManual => 'Chosen by hand';

  @override
  String faultsFound(String list) {
    return 'Faults: $list';
  }

  @override
  String get noFaults => 'No faults found';

  @override
  String get warrantyExpiry => 'Warranty ends on';

  @override
  String get accessoriesIncluded => 'Accessories included';

  @override
  String get describeWear => 'What wear does it have?';

  @override
  String get describeCondition => 'Describe its condition';

  @override
  String get describeDamage => 'Describe the damage';

  @override
  String get notesFeatures => 'Special features / notes';

  @override
  String get purchaseDate => 'Purchase date';

  @override
  String get fieldSupplier => 'Supplier (if not a walk-in)';

  @override
  String get sellerSearch => 'Search by name or phone';

  @override
  String get sellerCantFind => 'Can\'t find the seller?';

  @override
  String get addNewCustomer => 'Add new customer';

  @override
  String get saveAndSelect => 'Save & select';

  @override
  String get idTypeLabel => 'ID type';

  @override
  String get idNumberLabel => 'ID number';

  @override
  String get fieldAltPhone => 'Another phone number (optional)';

  @override
  String get sellerPicked => 'From your customers';

  @override
  String get changeSeller => 'Change';

  @override
  String get photoSlotFront => 'Front view';

  @override
  String get photoSlotBack => 'Back view';

  @override
  String get photoSlotLeft => 'Left side';

  @override
  String get photoSlotRight => 'Right side';

  @override
  String get photoSlotTopBottom => 'Top / bottom';

  @override
  String get photoSlotExtra => 'Extra';

  @override
  String get idCardFront => 'ID card — front';

  @override
  String get idCardBack => 'ID card — back';

  @override
  String get idCardPhotosTitle => 'ID card photos';

  @override
  String get tapToAddPhoto => 'Tap to add';

  @override
  String get wizCondition => 'Condition';

  @override
  String get wizConditionTitle => 'What condition is it in?';

  @override
  String get wizPhotosTitle => 'Take photos of the phone';

  @override
  String get saveAndPrintLabel => 'Save & print label';

  @override
  String get serialAppleHint => 'Needed for an iPhone';

  @override
  String get checklistNeedsBrand =>
      'Choose the brand on the Phone step to see its checks.';

  @override
  String labelPrinted(String number) {
    return 'Saved — label $number sent to the printer';
  }

  @override
  String get helpRam =>
      'How much RAM the phone has. Find it in Settings → About phone. Example: 6GB.';

  @override
  String get helpRom =>
      'How much storage the phone has. Find it in Settings → Storage. Example: 128GB. More storage sells for more.';

  @override
  String get helpPurchaseDate =>
      'The day you bought this phone. Today is already filled in — change it only if you bought it on another day.';

  @override
  String get helpSupplier =>
      'Only if you bought it from a dealer or another shop. Leave it empty when a customer sold it to you.';

  @override
  String get helpSellerSearch =>
      'Type the seller\'s name or phone number. If they have come to the shop before, they appear below — tap to fill everything in.';

  @override
  String get helpAltPhone =>
      'A second number for the seller, in case the first one is switched off.';

  @override
  String get helpIdType =>
      'Which ID the seller showed you — Aadhaar, PAN, driving licence or voter ID.';

  @override
  String get helpIdNumber => 'The number printed on that ID card.';

  @override
  String get helpIdCardPhotos =>
      'Photos of the seller\'s ID card, front and back. They prove who sold the phone if the police ask later.';

  @override
  String get helpGradeDetails =>
      'A few words about the phone\'s state, so the next person knows without checking again.';

  @override
  String get helpSerialApple =>
      'The serial number from Settings → General → About. It is needed for every iPhone.';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navMyTasks => 'My Tasks';

  @override
  String get tasksCouldNotLoad => 'Tasks could not be loaded';

  @override
  String get taskTabToDo => 'To do';

  @override
  String get taskTabDone => 'Done';

  @override
  String get taskFreqDaily => 'Daily';

  @override
  String get taskFreqWeekly => 'Weekly';

  @override
  String get taskFreqMonthly => 'Monthly';

  @override
  String get taskFreqOnce => 'One time';

  @override
  String get taskTabUnassigned => 'Nobody yet';

  @override
  String get taskPriorityLow => 'Low';

  @override
  String get taskPriorityMedium => 'Medium';

  @override
  String get taskPriorityHigh => 'High';

  @override
  String get taskAdd => 'Add task';

  @override
  String get taskNew => 'New task';

  @override
  String get taskEdit => 'Edit task';

  @override
  String get taskTitleLabel => 'What has to be done';

  @override
  String get taskDescriptionLabel => 'More details';

  @override
  String get taskAssignLabel => 'Who does it';

  @override
  String get taskFrequencyLabel => 'How often';

  @override
  String get taskPriorityLabel => 'How important';

  @override
  String get taskDueLabel => 'Do it by';

  @override
  String get taskPickDate => 'Pick a day';

  @override
  String get taskMarkDone => 'Done';

  @override
  String get taskUndo => 'Undo';

  @override
  String get taskOverdue => 'Late';

  @override
  String taskDueOn(String date) {
    return 'Do it by $date';
  }

  @override
  String get taskNobodySees => 'Given to nobody — staff cannot see it yet';

  @override
  String get taskAllStaff => 'Everyone';

  @override
  String get taskDelete => 'Delete';

  @override
  String get taskDeleteConfirm => 'Delete this task?';

  @override
  String get taskSaved => 'Task saved';

  @override
  String get taskNoTasks => 'No tasks here';

  @override
  String get taskBlockNoTitle => 'Write what has to be done.';

  @override
  String get taskBlockNoDueDate => 'Pick the day this has to be done by.';

  @override
  String get taskBlockAdminOnly => 'Only the shop owner can change tasks.';

  @override
  String get taskBlockNotYours => 'This task belongs to someone else.';

  @override
  String get helpTaskTitle =>
      'Write the job in a few plain words. Example: Clean the display cabinet.';

  @override
  String get helpTaskAssign =>
      'The staff member who must do this job. Only that person sees it on their phone. If you choose nobody, no staff member will see it.';

  @override
  String get helpTaskFrequency =>
      'How often the job comes back. Daily: every morning it must be done again. Weekly: once each week. Monthly: once each month. One time: do it once and it is finished.';

  @override
  String get helpTaskPriority =>
      'High jobs are shown first and in red. Use High only for jobs that cannot wait.';

  @override
  String get helpTaskDue =>
      'The last day to finish this job. After this day it shows as Late.';

  @override
  String stockOnHand(String count) {
    return '$count on hand';
  }

  @override
  String stockSellingFor(String amount) {
    return 'Selling for ₹$amount';
  }

  @override
  String stockPaidFor(String amount) {
    return 'Paid ₹$amount';
  }

  @override
  String addAsNewCustomer(String value) {
    return 'Add \"$value\" as a new customer';
  }

  @override
  String addAsNewBrand(String value) {
    return 'Add \"$value\" as a new brand';
  }

  @override
  String addAsNewModel(String value) {
    return 'Add \"$value\" as a new model';
  }

  @override
  String addAsNewRam(String value) {
    return 'Add \"$value\" as a new RAM size';
  }

  @override
  String addAsNewRom(String value) {
    return 'Add \"$value\" as a new storage size';
  }

  @override
  String addAsNewColour(String value) {
    return 'Add \"$value\" as a new colour';
  }

  @override
  String addAsNewSupplier(String value) {
    return 'Add \"$value\" as a new supplier';
  }

  @override
  String get sellerSearchLabel => 'Seller';

  @override
  String get sellerSearchHint => 'Type a name or phone number';

  @override
  String get noMatchingRecord => 'Nothing matches';

  @override
  String couldNotAddToList(String error) {
    return 'Could not add it to the shop\'s list: $error';
  }

  @override
  String get signatureLabel => 'Seller\'s signature';

  @override
  String get signatureClear => 'Sign again';

  @override
  String get signatureHint => 'Sign here with a finger';

  @override
  String get signatureOnRecord => 'Signed already';

  @override
  String get imeiScanTitle => 'Scan the IMEI';

  @override
  String get imeiScanPoint =>
      'Point the camera at the IMEI barcode on the box or under the battery.';

  @override
  String get imeiScanSecond => 'Got it. Scan the second IMEI too, or tap Done.';

  @override
  String get imeiScanBoth => 'Both IMEIs scanned.';

  @override
  String get imeiScanNoCamera =>
      'The camera cannot be used. Type the IMEI instead.';

  @override
  String get imeiScanDone => 'Done';

  @override
  String get declarationTitle => 'Seller\'s declaration';

  @override
  String get declarationHint =>
      'Read every line to the seller, then let them sign.';

  @override
  String get declarationAgreed =>
      'The seller has heard and agreed to all of this';

  @override
  String get idCheckedTitle => 'Government photo ID checked';

  @override
  String get idCheckedHint =>
      'You looked at the seller\'s Aadhaar, PAN, voter ID or licence.';

  @override
  String get helpDeclaration =>
      'This protects the shop if the phone turns out to be stolen. Read each line aloud to the seller. When they agree, tick the box and let them sign with a finger.';

  @override
  String get purchaseTerm1 =>
      'I am the lawful owner of this phone and I have the right to sell it.';

  @override
  String get purchaseTerm2 =>
      'The phone is not stolen or lost, was not obtained unlawfully, and is not part of any police complaint, FIR or court case.';

  @override
  String get purchaseTerm3 =>
      'The phone has no loan, EMI, insurance claim or anyone else\'s claim on it.';

  @override
  String get purchaseTerm4 =>
      'I have removed my personal data, signed out of every account (Google, iCloud, Mi, Samsung and others) and removed every screen lock.';

  @override
  String get purchaseTerm5 =>
      'I am selling this phone of my own free will, for the amount written above, and I have received that amount in full.';

  @override
  String get purchaseTerm6 =>
      'The phone belongs to the shop once I am paid. This is a final sale: it will not be returned to me, and there is no buy-back.';

  @override
  String get purchaseTerm7 =>
      'The shop may repair, refurbish or resell the phone straight away without asking me, and I will have no claim on it.';

  @override
  String get purchaseTerm8 =>
      'I will make good any loss, claim or legal action against the shop that comes from the phone\'s past ownership or use before this sale.';

  @override
  String get purchaseTerm9 =>
      'I have shown valid government photo ID, and a copy is kept with this form.';

  @override
  String get printNow => 'Print';

  @override
  String get printShare => 'Send (WhatsApp and more)';

  @override
  String printFailed(String error) {
    return 'Could not print: $error';
  }

  @override
  String get printEnglishNote =>
      'Printed in English, so every printer can show it.';

  @override
  String get printLockCode => 'Print the PIN or pattern';

  @override
  String get printLockCodeHint =>
      'Only if the customer agrees. The card may lie on the counter.';

  @override
  String get printJobCardTitle => 'Job card';

  @override
  String get printFinalBillTitle => 'Final bill';

  @override
  String get printBillTitle => 'Bill';

  @override
  String get printDeclarationTitle => 'Purchase declaration';

  @override
  String get printLabelTitle => 'Label';

  @override
  String get printLabelPdf => 'Print label sticker';

  @override
  String get scanWithCamera => 'Scan with camera';

  @override
  String get scanTorch => 'Torch';

  @override
  String get scanPointAtLabel =>
      'Point the camera at the sticker\'s barcode or the IMEI barcode.';

  @override
  String get scanOrType => 'Or type the number';

  @override
  String get patternDraw => 'Draw the pattern with a finger';

  @override
  String get patternClear => 'Draw again';

  @override
  String get patternTitle => 'The customer\'s unlock pattern';

  @override
  String get contactCall => 'Call';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactNoNumber =>
      'There is no mobile number on this record to send to.';

  @override
  String get contactCouldNotOpen => 'Could not open it on this phone.';

  @override
  String get contactRemind => 'Remind on WhatsApp';

  @override
  String waHello(String name, String shop) {
    return 'Hello $name, this is $shop.';
  }

  @override
  String waServiceReceived(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'Hello $name, we have received your $device (order $order). We will keep you updated. - $shop';
  }

  @override
  String waServiceInProgress(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'Hello $name, your $device (order $order) is being repaired now. We will tell you when it is ready. - $shop';
  }

  @override
  String waServiceParts(String name, String device, String order, String shop) {
    return 'Hello $name, we are waiting for parts for your $device (order $order). We will update you when they arrive. - $shop';
  }

  @override
  String waServiceApproval(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'Hello $name, your $device (order $order) needs your approval for extra work. Please call or visit us. - $shop';
  }

  @override
  String waServiceReady(String name, String device, String order, String shop) {
    return 'Hello $name, your $device (order $order) is ready. Please come and collect it. - $shop';
  }

  @override
  String waServiceReturned(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'Hello $name, your $device (order $order) has been handed back. Thank you for choosing $shop.';
  }

  @override
  String waDueReminder(String name, String amount, String bill, String shop) {
    return 'Hello $name, a gentle reminder that $amount is still pending on bill $bill. - $shop';
  }

  @override
  String waEnquiry(String name, String shop, String about) {
    return 'Hello $name, this is $shop about your enquiry: $about';
  }

  @override
  String get reportDayByDay => 'Takings day by day';

  @override
  String get reportDayByDayHint =>
      'Completed bills. A quiet day shows as a gap.';

  @override
  String get reportWhatSold => 'What sold best';

  @override
  String reportSoldCount(String count) {
    return '$count sold';
  }

  @override
  String get reportNoSales => 'No completed bills in this period.';

  @override
  String get shopDetailsTitle => 'Your shop';

  @override
  String get shopDetailsHint =>
      'Printed at the top of every bill, job card and declaration.';

  @override
  String get shopDetailsSaved => 'Shop details saved';

  @override
  String get shopDetailsSave => 'Save shop details';

  @override
  String get navImportContacts => 'Import contacts';

  @override
  String get importTitle => 'Import contacts';

  @override
  String get importHint =>
      'Paste a phone book or a list. Every line with a mobile number becomes a customer.';

  @override
  String get helpImport =>
      'Copy your contacts or a list from Excel or WhatsApp, then tap Paste. Nothing is saved until you tap Add. People already in your customers are skipped.';

  @override
  String get importPaste => 'Paste';

  @override
  String get importRead => 'Read it';

  @override
  String get importNoneFound => 'No mobile numbers found in what was pasted.';

  @override
  String importSummary(String fresh, String skipped) {
    return '$fresh new · $skipped already in your customers';
  }

  @override
  String importAddAll(String count) {
    return 'Add $count customers';
  }

  @override
  String importAdded(String count) {
    return '$count customers added';
  }

  @override
  String get photoTake => 'Take a photo';

  @override
  String get photoChoose => 'Choose from gallery';

  @override
  String get navRatings => 'Ratings';

  @override
  String get rateTitle => 'Rate your repair';

  @override
  String get rateHowDidWeDo => 'How did we do?';

  @override
  String get rateCommentHint => 'Anything to add? (optional)';

  @override
  String get rateSend => 'Send rating';

  @override
  String get rateThanks => 'Thank you. Your rating has been sent.';

  @override
  String get rateAlreadyAnswered =>
      'This job has already been rated. Thank you.';

  @override
  String get rateNotFound =>
      'This rating link is not valid. Check the link the shop sent you.';

  @override
  String get ratePickStars => 'Tap the stars to choose a rating.';

  @override
  String get rateCommentTooLong => 'Keep the comment under 500 characters.';

  @override
  String get rateCouldNotSend =>
      'Could not send. Check your connection and try again.';

  @override
  String get askForRating => 'Ask for a rating';

  @override
  String get sendRatingAgain => 'Send rating link again';

  @override
  String ratingReceived(int stars) {
    return 'Customer rated $stars of 5';
  }

  @override
  String get ratingNeedsWebAddress =>
      'Set the public web address in Settings to share rating links.';

  @override
  String get ratingLinkCopied =>
      'No WhatsApp number on this order, so the rating link was copied.';

  @override
  String ratingsSummary(int answered, int sent) {
    return '$answered of $sent answered';
  }

  @override
  String get ratingsAverage => 'Average';

  @override
  String get ratingsEmpty =>
      'No ratings yet. Ask for one from a finished service order.';

  @override
  String get ratingWaiting => 'Waiting for the customer';

  @override
  String get publicWebAddress => 'Public web address';

  @override
  String get publicWebAddressTitle => 'Customer links';

  @override
  String get publicWebAddressHint =>
      'Where this app\'s public pages are served. Rating links sent to customers start with it.';

  @override
  String get publicWebAddressSaved => 'Web address saved';

  @override
  String get ratingsNoAnswerYet => 'No answers yet';

  @override
  String ratingJob(String number) {
    return 'Job $number';
  }

  @override
  String get setButton => 'Set';

  @override
  String get setWhatIsCharged => 'Set what is charged';

  @override
  String chargedAmount(String amount) {
    return 'Charged ₹$amount';
  }

  @override
  String get printFinalBill => 'Print final bill';

  @override
  String get printJobCard => 'Print job card';

  @override
  String get handedBackPrintBill => 'Handed back — final bill can be printed';

  @override
  String stillToCheck(String items) {
    return 'Still to check: $items';
  }

  @override
  String stillToCheckMore(String items, int count) {
    return 'Still to check: $items and $count more';
  }

  @override
  String get cannotHandBackYet => 'Cannot hand this back yet';

  @override
  String get markedSold => 'Marked sold';

  @override
  String get alreadySold => 'Already sold';

  @override
  String get onBenchNotReady => 'On the bench — not ready to sell';

  @override
  String get atLeastSixChars => 'At least six characters';

  @override
  String get addACheck => 'Add a check';

  @override
  String get printServerSaved => 'Print server saved';

  @override
  String get printServerHint =>
      'The small server on the counter PC that talks to the label printer. Printing never blocks a save — a printer that is off is reported, not an error.';

  @override
  String get stockCountMatched =>
      'The count already matched — nothing recorded';

  @override
  String stockCorrectedTo(int count) {
    return 'Corrected to $count, with the difference in the history';
  }

  @override
  String historyDisagrees(String ledger, String balance) {
    return 'The history adds up to ₹$ledger, not ₹$balance. This record needs looking at.';
  }

  @override
  String get offlineModeNote =>
      'Offline mode — no account, and nothing is saved beyond this session. Pick a role to walk the app.';

  @override
  String checklistCollisions(String items) {
    return 'These read as the same item once punctuation and case are dropped: $items. They are kept apart, but they will look like duplicates on the checklist.';
  }

  @override
  String get enquiryNobodyOnNumber =>
      'Nobody in the book on that number — the enquiry will carry the number typed here.';

  @override
  String get wonAsksWhich =>
      'Marking this Won asks which sale or repair it became.';

  @override
  String get wonOutcomeHelp =>
      'An invoice number, a service order number, or a note. A won enquiry with nothing to point at cannot be counted.';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deleteAccountExplain =>
      'This deletes your login and takes you out of this shop. The shop\'s own records — stock, bills, customers — stay with the shop. This cannot be undone.';

  @override
  String get passwordToConfirm => 'Your password, to confirm';

  @override
  String get deleteForever => 'Delete for ever';

  @override
  String get advancePaid => 'Advance paid';

  @override
  String get toCollect => 'To collect at pickup';

  @override
  String get statusReady => 'Ready for pickup';

  @override
  String get tileReadyForPickup => 'Ready for Pickup';

  @override
  String waServiceReadyPay(
    String name,
    String device,
    String order,
    String amount,
    String shop,
  ) {
    return 'Hello $name, your $device (order $order) is ready. Amount to pay: ₹$amount. Please come and collect it. - $shop';
  }

  @override
  String get paidEmptyMeansFull =>
      'Leave empty if paid in full. Type 0 for a credit sale.';

  @override
  String get staffSeeCostsTitle => 'Staff can see cost and profit';

  @override
  String get staffSeeCostsHint =>
      'Off: staff phones hide what the shop paid and what it makes. Admins always see them.';

  @override
  String productSummaryRetail(String lines, String units, String retail) {
    return '$lines product(s) · $units unit(s) · retail ₹$retail';
  }

  @override
  String soldFor(String price) {
    return 'Sold ₹$price';
  }

  @override
  String get reportHowPaid => 'How it was paid';

  @override
  String get reportWalletUsed => 'Customer wallet used';

  @override
  String get reportStillOwed => 'Still owed by customers';

  @override
  String get reportFinanceNote =>
      'Finance amounts are paid by the finance company, not into the drawer.';

  @override
  String reportBillsCount(int count) {
    return '$count bill(s)';
  }

  @override
  String get lifeOverdue => 'Overdue';

  @override
  String get lifeInShop => 'In the shop';

  @override
  String get lifeFinished => 'Finished';

  @override
  String get moveReceived => 'Received';

  @override
  String get moveSold => 'Sold';

  @override
  String get moveReturned => 'Returned';

  @override
  String get moveAdjustedUp => 'Stock-take: more than recorded';

  @override
  String get moveAdjustedDown => 'Stock-take: less than recorded';

  @override
  String get moveDamaged => 'Damaged or written off';

  @override
  String get scanModeLabel => 'Shop label';

  @override
  String get scanModeRepair => 'New repair';

  @override
  String get scanModePurchase => 'Buy a handset';

  @override
  String get scanHintLabel =>
      'Scan a sticker to open the record it was printed for.';

  @override
  String get scanHintRepair =>
      'Scan the phone\'s barcode to start a repair with the brand and model filled in.';

  @override
  String get scanHintPurchase =>
      'Scan the phone\'s barcode to start a purchase with the brand and model filled in.';

  @override
  String get enqFollowUpOverdue => 'Follow-up overdue';

  @override
  String get enqOpen => 'Open';

  @override
  String get enqDealtWith => 'Dealt with';

  @override
  String get periodToday => 'Today';

  @override
  String get period7 => 'Last 7 days';

  @override
  String get period30 => 'Last 30 days';

  @override
  String get periodMonth => 'This month';

  @override
  String get periodCustom => 'Custom';

  @override
  String get figTakings => 'Takings';

  @override
  String get figTakingsNote =>
      'Completed bills, dated on the day they were settled';

  @override
  String get figService => 'Service revenue';

  @override
  String get figServiceNote =>
      'Jobs that went back to the customer, at the price charged';

  @override
  String get figMargin => 'Second-hand margin';

  @override
  String get figMarginNote =>
      'Sale price less purchase, repairs and other costs. Part of takings, not on top of it';

  @override
  String get figOutstanding => 'Outstanding';

  @override
  String get figOutstandingNote =>
      'Owed right now, across all unpaid bills — not just this period. Financed sales are not counted';

  @override
  String get repairWarranty => 'Repair warranty';

  @override
  String get repairWarrantyHint =>
      'Printed on the final bill and checked when a phone comes back.';

  @override
  String get warrantyNone => 'None';

  @override
  String warrantyDaysN(int days) {
    return '$days days';
  }

  @override
  String warrantyUntil(String date) {
    return 'Under warranty until $date';
  }

  @override
  String warrantyEnded(String date) {
    return 'Warranty ended $date';
  }

  @override
  String warrantyReturning(String date, String order, String until) {
    return 'Repaired here on $date ($order) — still under warranty until $until.';
  }

  @override
  String get shareReport => 'Share report';

  @override
  String checksTicked(int done, int total) {
    return '$done of $total ticked';
  }

  @override
  String get beforeItGoesBack => 'Check before it goes back';

  @override
  String get searchEverythingHint => 'Search name, number, IMEI, job or bill';

  @override
  String get searchEverythingTitle => 'Find anything';

  @override
  String get searchEverythingDetail =>
      'Repairs, phones, bills, customers, products and enquiries, all at once.';

  @override
  String searchMore(int count) {
    return 'and $count more in this list';
  }

  @override
  String get clear => 'Clear';

  @override
  String get collectedLaterTitle => 'Collected later';

  @override
  String get paidAtPickup => 'Paid at pickup';

  @override
  String howPaidAmount(String amount) {
    return '₹$amount to collect — how was it paid?';
  }

  @override
  String get sendOrderList => 'Send order list on WhatsApp';

  @override
  String get sellMakeBill => 'Sell — make a bill';

  @override
  String get soldWithoutBill => 'Sold without a bill (to a dealer, elsewhere)';

  @override
  String get moveUsedOnRepair => 'Used on a repair';

  @override
  String get usePartFromStock => 'Use a part from stock';

  @override
  String get partsUsed => 'Parts used';

  @override
  String partUsedSaved(String part) {
    return '$part taken off stock and added to this job';
  }

  @override
  String get noPartsInStock =>
      'Nothing in stock to use. Add parts on the Products page.';

  @override
  String get gstRateTitle => 'GST on bills';

  @override
  String get gstRateHint =>
      'The GST rate your prices include. Bills show CGST and SGST when you also have a GSTIN. Used handsets are left out (margin scheme). Check the rate with your accountant.';

  @override
  String get gstOff => 'Off';

  @override
  String get hintBrands => 'Offered on every intake and purchase form.';

  @override
  String get hintSuppliers => 'Offered when adding a product.';

  @override
  String get hintColours => 'Offered on purchase and product forms.';

  @override
  String get hintCategories => 'Groups the products list.';

  @override
  String get hintComplaintTypes =>
      'The job card and the final bill are both built from these.';

  @override
  String get hintAccessories => 'Ticked at intake, printed on the job card.';

  @override
  String get hintLockTypes => 'How a device was locked when it came in.';

  @override
  String get hintRam => 'Offered on the purchase form.';

  @override
  String get hintRom => 'Offered on the purchase form.';

  @override
  String get offlineBanner =>
      'Offline — work is saved on this phone and uploads when the internet is back.';

  @override
  String plusFromRepairs(String amount) {
    return '+ $amount from repairs';
  }

  @override
  String enquiryWonAs(String ref) {
    return 'Repair taken in — enquiry marked Won ($ref)';
  }

  @override
  String get tellTheCustomer => 'Tell the customer';

  @override
  String pricePaidBefore(int count, String paid) {
    return 'Bought $count of these before, for $paid';
  }

  @override
  String priceSoldBefore(int count, String avg) {
    return '$count sold, for $avg on average';
  }
}
