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
  String get setUpNewShop => 'Create account (new shop or invited staff)';

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
  String get dateTomorrow => 'Tomorrow';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get dateNextWeek => 'Next week';

  @override
  String dateInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'In 1 day',
    );
    return '$_temp0';
  }

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get navExpenses => 'Expenses';

  @override
  String get expenseAgain => 'Again? One tap fills it in';

  @override
  String get expenseNew => 'Add expense';

  @override
  String get expenseEdit => 'Expense';

  @override
  String get expenseSaved => 'Expense saved';

  @override
  String get expenseDeleteConfirm => 'Delete this expense?';

  @override
  String get expenseOwnerOnly =>
      'Only the owner can change or delete an expense once it is saved.';

  @override
  String get expenseNeedAmount => 'Type how much was paid';

  @override
  String get expenseNeedKind => 'Pick what it was for';

  @override
  String get expenseWhatFor => 'What for';

  @override
  String get expensePaidHow => 'Paid by';

  @override
  String get expenseDay => 'Day';

  @override
  String get expenseNote => 'Note';

  @override
  String get expenseNoteHint => 'e.g. A54 display from the supplier';

  @override
  String get expenseCash => 'Cash';

  @override
  String get expenseKindParts => 'Parts';

  @override
  String get expenseKindTea => 'Tea & food';

  @override
  String get expenseKindRent => 'Rent';

  @override
  String get expenseKindPower => 'Electricity';

  @override
  String get expenseKindSalary => 'Salary';

  @override
  String get expenseKindTransport => 'Transport';

  @override
  String get expenseKindSupplies => 'Shop supplies';

  @override
  String get expenseKindOther => 'Other';

  @override
  String get expensesCouldNotLoad => 'Could not load expenses';

  @override
  String get loadingExpenses => 'Getting the expenses…';

  @override
  String get expensesEmpty => 'No expenses yet';

  @override
  String get expensesEmptyDetail =>
      'Write down what the shop pays for — parts, tea, rent — and the reports show what is left.';

  @override
  String get expenseThisMonth => 'This month';

  @override
  String expenseCashPart(String amount) {
    return '$amount in cash';
  }

  @override
  String get reportMoneyOut => 'Money out';

  @override
  String get reportMoneyOutNone => 'No expenses in this period.';

  @override
  String get reportCashLeft => 'Cash left in the drawer';

  @override
  String get reportCashLeftHint =>
      'Cash taken on bills minus expenses paid in cash.';

  @override
  String get reportAfterExpenses => 'After expenses';

  @override
  String get exportExpenses => 'Expenses';

  @override
  String homeSpentToday(String amount) {
    return '$amount spent today';
  }

  @override
  String get loadingShopDetails => 'Getting the shop\'s details…';

  @override
  String get shopDetailsCouldNotLoad => 'Could not open the shop\'s details';

  @override
  String get shopDetailsNoAccount =>
      'This phone is not connected to the shop\'s account. Sign out and sign in again with internet on.';

  @override
  String get shopDetailsNotFound => 'The shop\'s record was not found.';

  @override
  String get handOverCheck => 'Check the phone';

  @override
  String get handOverPay => 'What they pay';

  @override
  String get handOverHowPaid => 'How they paid';

  @override
  String get handOverToCollect => 'To collect now';

  @override
  String get handOverNeedPrice => 'Type what is charged (0 for a free repair)';

  @override
  String handOverChecksLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count checks left',
      one: '1 check left',
    );
    return '$_temp0';
  }

  @override
  String handOverAndCollect(String amount) {
    return 'Hand over · collect $amount';
  }

  @override
  String get handOverButton => 'Hand over the phone';

  @override
  String get handOverCard => 'Before hand-over';

  @override
  String get saveAddAnotherPhone => 'Save & add another phone';

  @override
  String savedAddAnother(String number) {
    return '$number saved — now the next phone';
  }

  @override
  String visitAnotherPhoneFor(String name) {
    return 'Another phone for $name';
  }

  @override
  String visitSameAs(String number) {
    return 'Same visit as $number: one job card and one bill for all';
  }

  @override
  String get visitPhones => 'Phones in this visit';

  @override
  String get visitAddPhone => 'Add another phone';

  @override
  String visitPhoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phones, one job card and one bill',
      one: '1 phone, one job card and one bill',
    );
    return '$_temp0';
  }

  @override
  String get saveBuyAnotherFromSeller =>
      'Save, print label & buy another from this seller';

  @override
  String get buyNextFromSeller => 'now the next phone from this seller';

  @override
  String buyAnotherFrom(String name) {
    return 'Another phone from $name';
  }

  @override
  String get buyAnotherSameSeller =>
      'Seller, ID and signature carried over: one declaration for all';

  @override
  String get boughtTogether => 'Bought together';

  @override
  String boughtTogetherCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phones from this seller, one declaration',
      one: '1 phone from this seller, one declaration',
    );
    return '$_temp0';
  }

  @override
  String get buyAnotherFromSeller => 'Buy another from this seller';

  @override
  String billsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills',
      one: '1 bill',
    );
    return '$_temp0';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get alreadyOnBill => 'Already on this bill';

  @override
  String get allOnThisBill => 'All of it is already on this bill';

  @override
  String leftCount(int count) {
    return '$count left';
  }

  @override
  String onShelfCount(int count) {
    return '$count on the shelf';
  }

  @override
  String onlyLeftCount(int count) {
    return 'Only $count left — that is all there is';
  }

  @override
  String get quantityAtLeastOne => 'At least 1';

  @override
  String walletHoldsOnly(String amount) {
    return 'Their wallet holds ₹$amount';
  }

  @override
  String get splitSayHowMuch => 'Say how much came in by each way';

  @override
  String get downPaymentAtCounter => 'Down payment at the counter';

  @override
  String get downPaymentEmptyMeansNone =>
      'Empty means no down payment — the financier pays it all';

  @override
  String get downPaymentPaidBy => 'Down payment paid by';

  @override
  String get changeToGiveBack => 'Change to give back';

  @override
  String draftTotal(String total) {
    return '₹$total · draft, nothing paid yet';
  }

  @override
  String cancelledTotal(String total) {
    return '₹$total · cancelled';
  }

  @override
  String otherMethods(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count others',
      one: '1 other',
    );
    return '$_temp0';
  }

  @override
  String get billCancelledDone => 'Bill cancelled';

  @override
  String get billCancelKept => 'The bill is kept on record as cancelled.';

  @override
  String refundHow(String amount) {
    return '$amount was paid — how did it go back?';
  }

  @override
  String get refundToWallet => 'Leave on their wallet';

  @override
  String get cancelNeedReason => 'Say why — it goes on the record';

  @override
  String advanceWhatHappened(String amount) {
    return 'The $amount advance';
  }

  @override
  String get advanceGivenBack => 'Given back';

  @override
  String get advanceKeptAsFee => 'Kept as the fee';

  @override
  String get returnNeedReason => 'Say why — it goes on the record';

  @override
  String get changeGiveBack => 'Change to give back';

  @override
  String enquiryMarkAs(String status) {
    return 'Mark as $status';
  }

  @override
  String get enquiryMarkAsBody =>
      'The enquiry is settled and leaves the open list. It can be reopened.';

  @override
  String get makeABill => 'Make a bill';

  @override
  String get stocktakeTypeCount =>
      'Type what is on the shelf — 0 if it is empty';

  @override
  String get purchaseResumed => 'Carried on from an unfinished purchase';

  @override
  String get startFresh => 'Start fresh';

  @override
  String get discardPurchaseTitle => 'Throw this purchase away?';

  @override
  String get discardPurchaseBody =>
      'Everything typed in all six steps is lost.';

  @override
  String get discardPurchaseYes => 'Throw away';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

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
  String get signUpSubtitle =>
      'Invited by a shop? Use the email they invited and you join it straight away. Otherwise you set up your shop next.';

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
  String addedToShopLists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new values',
      one: '1 new value',
    );
    return 'Added to the shop lists: $_temp0';
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
  String get findAnIssue => 'Type to find an issue';

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
  String productSummary(int lines, int units, String cost, String retail) {
    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$lines products',
      one: '1 product',
    );
    String _temp1 = intl.Intl.pluralLogic(
      units,
      locale: localeName,
      other: '$units units',
      one: '1 unit',
    );
    return '$_temp0 · $_temp1 · cost ₹$cost · retail ₹$retail';
  }

  @override
  String get nothingOutstanding => 'Nothing outstanding';

  @override
  String get financedNotCountedHere =>
      'Financed sales are not counted here — those customers owe the shop nothing.';

  @override
  String owedByCustomers(String total, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers',
      one: '1 customer',
    );
    return '₹$total owed by $_temp0';
  }

  @override
  String get financedNotHere =>
      'Financed sales are not here: the customer owes nothing, and the financier\'s settlement is a different ledger.';

  @override
  String oldestDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'oldest $_temp0';
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
  String get ofWhichFromWallet => 'Also from the wallet';

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
  String keptAsDraftItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Kept as a draft — nothing has come off the shelf ($_temp0)';
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
  String fromRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return 'from $_temp0';
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
    return '$role · waiting for them to tap \"Create account\" with this email';
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
    return 'Saved. No email is sent: ask them to install the app and tap \"Create account\" with $email and a password of their own.';
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
  String modelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count models',
      one: '1 model',
    );
    return '$_temp0';
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
      'The phone\'s model name. Example: Galaxy A54, Y21. Find it in Settings > About phone.';

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
      'The maker\'s serial number, found in Settings > About phone. Not needed for most phones — fill it if you have it.';

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
  String get optionExpenseKinds => 'Expense types';

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
      'How much RAM the phone has. Find it in Settings > About phone. Example: 6GB.';

  @override
  String get helpRom =>
      'How much storage the phone has. Find it in Settings > Storage. Example: 128GB. More storage sells for more.';

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
      'The serial number from Settings > General > About. It is needed for every iPhone.';

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
      'Point the camera at the IMEI barcode: on the box, under the battery, or on the phone\'s screen after dialling *#06#.';

  @override
  String get imeiScanPointPhone =>
      'Phone switches on? Dial *#06# and scan the barcode on its screen. If not, scan the IMEI sticker on the phone.';

  @override
  String noModelsYet(String brand) {
    return 'No $brand models saved yet. Type it once and it is offered here next time.';
  }

  @override
  String get serialScanTitle => 'Scan the serial number';

  @override
  String get serialScanPoint =>
      'Point the camera at the barcode next to \"Serial No.\" on the box or label.';

  @override
  String get serialScanAgain => 'Scan again';

  @override
  String get serialScanNoCamera =>
      'The camera cannot be used. Type the serial number instead.';

  @override
  String get savingNow => 'Saving…';

  @override
  String get emailNeeded => 'Your email is needed';

  @override
  String get passwordNeeded => 'Your password is needed';

  @override
  String get printingNow => 'Printing…';

  @override
  String get loadingData => 'Getting your data…';

  @override
  String get loadingStill => 'Still working on it…';

  @override
  String get loadingAlmost => 'Almost there…';

  @override
  String get loadingSlow => 'Slow internet? Hang on…';

  @override
  String get loadingRepairs => 'Getting your repairs…';

  @override
  String get loadingPhones => 'Getting your phones…';

  @override
  String get loadingBills => 'Getting your bills…';

  @override
  String get loadingCustomers => 'Getting your customers…';

  @override
  String get loadingProducts => 'Getting your products…';

  @override
  String get loadingEnquiries => 'Getting enquiries…';

  @override
  String get loadingTasks => 'Getting tasks…';

  @override
  String get loadingRecord => 'Opening it…';

  @override
  String get loadingStaff => 'Getting your staff…';

  @override
  String get loadingRatings => 'Getting ratings…';

  @override
  String get loadingSearch => 'Searching…';

  @override
  String get loadingPrinters => 'Looking for printers…';

  @override
  String get loadingOlder => 'Getting older bills and jobs…';

  @override
  String get readNumbersButton => 'No barcode? Read the numbers';

  @override
  String get readingNumbers => 'Reading the numbers…';

  @override
  String get readNoImei =>
      'No IMEI found in the photo. Hold the phone closer, keep it sharp, and try again, or type it.';

  @override
  String get readNoSerial =>
      'No serial number found in the photo. Try again closer, or type it.';

  @override
  String readFailed(String reason) {
    return 'The camera could not read it: $reason';
  }

  @override
  String get tourWelcomeTitle => 'Welcome to your shop app';

  @override
  String get tourWelcomeBody =>
      'A one-minute look at each page and what it is for. Tap Next, or Skip any time. You can watch it again from Settings.';

  @override
  String get tourSearchTitle => 'Find anything';

  @override
  String get tourSearchBody =>
      'Type a name, phone number, IMEI, job number or bill number. The scan button reads a label or an IMEI barcode.';

  @override
  String get tourTodayTitle => 'Today\'s money';

  @override
  String get tourTodayBody =>
      'What came in today from bills and repairs, split into cash, UPI and card.';

  @override
  String get tourActionsTitle => 'Start here';

  @override
  String get tourActionsBody =>
      'The four jobs of the counter: a new sale, a new repair, buying a phone, and noting an enquiry.';

  @override
  String get tourQueueTitle => 'Repairs that need you';

  @override
  String get tourQueueBody =>
      'Late, due today and ready jobs. Tap one to see them; call or WhatsApp the customer from the card.';

  @override
  String get tourNavTitle => 'Move around';

  @override
  String get tourNavBody =>
      'Home, Mobiles, Repairs, Sales and More sit here on every page.';

  @override
  String get tourStockTitle => 'Phones in stock';

  @override
  String get tourStockBody =>
      'How many phones you hold, what they would sell for, and the profit in them.';

  @override
  String get tourStockTabsTitle => 'In stock, on the bench, sold';

  @override
  String get tourStockTabsBody =>
      'Tap to switch. Each phone shows its price, profit and how many days it has waited.';

  @override
  String get tourBuyTitle => 'Buying a phone';

  @override
  String get tourBuyBody =>
      'Five short steps: seller, phone, condition, money, photos. The price label prints at the end.';

  @override
  String get tourRepairsTitle => 'Every repair, by where it is';

  @override
  String get tourRepairsBody =>
      'Open, due today, overdue, ready. Open a job to change its status, charge it and hand it back.';

  @override
  String get tourNewRepairTitle => 'Taking in a repair';

  @override
  String get tourNewRepairBody =>
      'Phone number, brand, model and what is wrong. Save & print gives the customer their job card.';

  @override
  String get tourBillsTitle => 'Bills';

  @override
  String get tourBillsBody =>
      'Completed bills, drafts and cancelled ones. A bill can be finished without internet; it completes itself when the connection is back.';

  @override
  String get tourNewBillTitle => 'A new bill';

  @override
  String get tourNewBillBody =>
      'Add phones from stock, accessories or a typed line, take the payment, and share the bill.';

  @override
  String get tourSettingsTitle => 'Settings';

  @override
  String get tourSettingsBody =>
      'Your shop\'s lists, the label printer and the language. This tour is here too, under Help.';

  @override
  String get tourDoneTitle => 'That\'s the tour';

  @override
  String get tourDoneBody =>
      'The ? buttons next to boxes explain each one. Start with the button you need most.';

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourBack => 'Back';

  @override
  String get tourNext => 'Next';

  @override
  String get tourDone => 'Done';

  @override
  String get tourOfferTitle => 'New here?';

  @override
  String get tourOfferBody =>
      'Take a one-minute tour of the app: what each page is for and where to tap.';

  @override
  String get tourOfferStart => 'Show me around';

  @override
  String get tourOfferLater => 'Not now';

  @override
  String get setGroupHelp => 'Help';

  @override
  String get settingsTour => 'App tour';

  @override
  String get settingsTourSub => 'See how each page works, step by step';

  @override
  String tourStepOf(int n, int total) {
    return '$n of $total';
  }

  @override
  String get tourChRepairTitle => 'Take in a repair';

  @override
  String get tourChRepairBlurb =>
      'Fill a job card, then follow the job until the phone goes back';

  @override
  String get tourRepair1T => 'Repairs, by where they are';

  @override
  String get tourRepair1B =>
      'Open, due today, overdue and ready. Tap a tab to see those jobs. Swipe a job right to call the customer, left to WhatsApp them.';

  @override
  String get tourRepair2T => 'Taking one in';

  @override
  String get tourRepair2B =>
      'This starts a new repair. Watch: the tour fills one in with practice data.';

  @override
  String get tourRepair3T => 'The customer\'s number';

  @override
  String get tourRepair3B =>
      'Type it first: someone who has been before is found, and a tap fills their name.';

  @override
  String get tourRepair4T => 'Name';

  @override
  String get tourRepair4B => 'Optional: the number alone is enough.';

  @override
  String get tourRepair5T => 'Brand';

  @override
  String get tourRepair5B =>
      'Tap it in the row under the box, or type a new one; it joins your list.';

  @override
  String get tourRepair6T => 'Model';

  @override
  String get tourRepair6B =>
      'Once the brand is picked, its models appear in a row. Tap one.';

  @override
  String get tourRepair7T => 'IMEI';

  @override
  String get tourRepair7B =>
      'Off the phone (dial *#06#), not the box. The camera button scans it.';

  @override
  String get tourRepair8T => 'Lock';

  @override
  String get tourRepair8B =>
      'How it is locked, and the code, so the phone can be tested.';

  @override
  String get tourRepair9T => 'What is wrong';

  @override
  String get tourRepair9B =>
      'Tap one or more; typing finds the rest. The job card and the bill are made from these.';

  @override
  String get tourRepair10T => 'Estimate';

  @override
  String get tourRepair10B =>
      'The price you told them. Advance and parts cost go just below.';

  @override
  String get tourRepair11T => 'Promised date';

  @override
  String get tourRepair11B =>
      'When they get it back. Late jobs come up on Home.';

  @override
  String get tourRepair12T => 'Save';

  @override
  String get tourRepair12B =>
      'Save, or Save & print for their job card. A missing box turns red and the cursor goes to it.';

  @override
  String get tourRepair13T => 'A job\'s page';

  @override
  String get tourRepair13B =>
      'Tap a status as the work moves. Mark ready offers to WhatsApp the customer.';

  @override
  String get tourRepair15T => 'Before hand-over';

  @override
  String get tourRepair15B =>
      'How many checks are done. Tap it, or Hand the phone back, to open the hand-over page.';

  @override
  String get tourRepair16T => 'The hand-over';

  @override
  String get tourRepair16B =>
      'Tick each check, confirm the price and how they paid, then one button hands it back. Miss something and it takes you to it.';

  @override
  String get tourRepair14T => 'Charge, parts, hand back';

  @override
  String get tourRepair14B =>
      'Set what is charged, use parts from stock, print, and hand the phone back after the checklist.';

  @override
  String get tourChBuyTitle => 'Buy a phone';

  @override
  String get tourChBuyBlurb => 'Five steps from the seller to the price label';

  @override
  String get tourBuy1T => 'Buying a phone';

  @override
  String get tourBuy1B =>
      'Five short steps. Watch: the tour fills one in with practice data.';

  @override
  String get tourBuy2T => '1 · Seller';

  @override
  String get tourBuy2B =>
      'Search by name or number and tap them, or add someone new. Their ID goes under More details.';

  @override
  String get tourBuy3T => '2 · Phone';

  @override
  String get tourBuy3B =>
      'Brand, model, RAM and storage are a tap each in the rows.';

  @override
  String get tourBuy4T => 'Picked';

  @override
  String get tourBuy4B =>
      'Navy means chosen. A wrong tap is fixed with one more tap.';

  @override
  String get tourBuy5T => 'IMEI and serial';

  @override
  String get tourBuy5B =>
      'Scan the box, or read the numbers off the screen with the camera. An iPhone needs its serial too.';

  @override
  String get tourBuy6T => '3 · Condition';

  @override
  String get tourBuy6B =>
      'Mark anything that does not work. The grade A to D works itself out; battery health goes here too.';

  @override
  String get tourBuy7T => '4 · Money';

  @override
  String get tourBuy7B =>
      'What you paid and what it will sell for. The profit shows as you type.';

  @override
  String get tourBuy8T => '5 · Photos';

  @override
  String get tourBuy8B =>
      'Front and back photos, the seller\'s ID and signature. Save prints the price label.';

  @override
  String get tourBuy9T => 'A phone\'s page';

  @override
  String get tourBuy9B =>
      'Sell it on a bill, send it to the bench for repair, or reprint its label.';

  @override
  String get tourChBillTitle => 'Make a bill';

  @override
  String get tourChBillBlurb =>
      'Who buys, what, how they paid, and the bill afterwards';

  @override
  String get tourBill1T => 'Bills';

  @override
  String get tourBill1B => 'Completed bills, drafts and cancelled ones.';

  @override
  String get tourBill2T => 'Who is buying';

  @override
  String get tourBill2B =>
      'Their number finds them; a new number joins your customers.';

  @override
  String get tourBill3T => 'What they buy';

  @override
  String get tourBill3B =>
      'Add a phone from stock, an accessory, or type a line.';

  @override
  String get tourBill4T => 'How they paid';

  @override
  String get tourBill4B => 'Cash, UPI or card: a tap.';

  @override
  String get tourBill5T => 'Paid now';

  @override
  String get tourBill5B =>
      'Leave it empty for the full amount. Anything less stays as a due payment.';

  @override
  String get tourBill6T => 'Complete sale';

  @override
  String get tourBill6B =>
      'Gives the invoice number and takes the phone out of stock. Keep as draft to finish later.';

  @override
  String get tourBill7T => 'A bill\'s page';

  @override
  String get tourBill7B =>
      'Share or print the bill, take a part payment, or cancel it.';

  @override
  String get tourChCustomersTitle => 'Customers';

  @override
  String get tourChCustomersBlurb =>
      'Everyone who bought, sold or left a phone';

  @override
  String get tourCustomers1T => 'Customers';

  @override
  String get tourCustomers1B =>
      'Search by name or number. A tap opens their page.';

  @override
  String get tourCustomers2T => 'Adding someone';

  @override
  String get tourCustomers2B =>
      'Their number is the one thing needed. ID and address are for when they sell you a phone.';

  @override
  String get tourCustomers3T => 'A customer\'s page';

  @override
  String get tourCustomers3B =>
      'Call or WhatsApp them, their store credit, and every repair, bill and enquiry of theirs.';

  @override
  String get tourChProductsTitle => 'Products and stock';

  @override
  String get tourChProductsBlurb =>
      'Accessories and parts: what is on the shelf and what to order';

  @override
  String get tourProducts1T => 'Products';

  @override
  String get tourProducts1B =>
      'Accessories and parts you keep. Search by name or code.';

  @override
  String get tourProducts2T => 'Running low';

  @override
  String get tourProducts2B =>
      'Send the to-order list to your supplier on WhatsApp.';

  @override
  String get tourProducts3T => 'Adding a product';

  @override
  String get tourProducts3B =>
      'Name, selling price and category. The count on the shelf starts at zero.';

  @override
  String get tourProducts4T => 'A product\'s page';

  @override
  String get tourProducts4B =>
      'Stock in, damaged, a stock count, and its label.';

  @override
  String get tourChEnquiriesTitle => 'Enquiries';

  @override
  String get tourChEnquiriesBlurb =>
      'Note what people asked for and ring them back';

  @override
  String get tourEnquiries1T => 'Enquiries';

  @override
  String get tourEnquiries1B =>
      'People who asked for something you did not have yet. Ring them back when it comes in.';

  @override
  String get tourEnquiries2T => 'Noting one';

  @override
  String get tourEnquiries2B =>
      'Their number, what it is about, and what they asked. A follow-up date reminds you.';

  @override
  String get tourEnquiries3T => 'What came of it';

  @override
  String get tourEnquiries3B =>
      'Mark it won, lost or still open; start a repair straight from it.';

  @override
  String get tourChMoneyTitle => 'Money and reports';

  @override
  String get tourChMoneyBlurb => 'What came in, how, and who still owes';

  @override
  String get tourMoney1T => 'Reports';

  @override
  String get tourMoney1B =>
      'Pick a period: today, this week, this month, or your own dates.';

  @override
  String get tourMoney2T => 'How it came in';

  @override
  String get tourMoney2B =>
      'Cash, UPI and card, to match your drawer and your bank.';

  @override
  String get tourMoney3T => 'Share it';

  @override
  String get tourMoney3B => 'Send the report on WhatsApp, or save it.';

  @override
  String get tourMoney5T => 'Money out';

  @override
  String get tourMoney5B =>
      'Write down what the shop pays for: parts, tea, rent. Today\'s and this month\'s spending are at the top.';

  @override
  String get tourMoney6T => 'Adding one';

  @override
  String get tourMoney6B =>
      'The amount, then what it was for. Cash and today are already picked, so tea is the amount and two taps.';

  @override
  String get tourMoney7T => 'What is left';

  @override
  String get tourMoney7B =>
      'Reports take the expenses off. Cash left in the drawer is what you should count when closing.';

  @override
  String get tourMoney4T => 'Due payments';

  @override
  String get tourMoney4B =>
      'Everyone with money left on a bill. Remind sends them a polite WhatsApp.';

  @override
  String get tourChLabelsTitle => 'Labels, scanner and search';

  @override
  String get tourChLabelsBlurb =>
      'Find anything by its sticker, IMEI or a word';

  @override
  String get tourLabels1T => 'Search everything';

  @override
  String get tourLabels1B =>
      'Name, number, IMEI, job or bill, across repairs, phones, bills and customers.';

  @override
  String get tourLabels2T => 'Scanner';

  @override
  String get tourLabels2B =>
      'Scan a label or an IMEI to open what it belongs to, or to start a repair or a purchase.';

  @override
  String get tourLabels3T => 'Labels';

  @override
  String get tourLabels3B =>
      'Every number printed and what it is on. Reprint one from here.';

  @override
  String get tourChTeamTitle => 'Staff, tasks and ratings';

  @override
  String get tourChTeamBlurb =>
      'Your team, their jobs, and what customers said';

  @override
  String get tourTeam1T => 'Staff';

  @override
  String get tourTeam1B =>
      'Invite people by email as staff or admin. Staff do not see costs unless you allow it.';

  @override
  String get tourTeam2T => 'Tasks';

  @override
  String get tourTeam2B =>
      'Jobs for the team, once or repeating. Each person sees their own.';

  @override
  String get tourTeam3T => 'Ratings';

  @override
  String get tourTeam3B =>
      'What customers said after a repair, from the link sent when it was ready.';

  @override
  String get tourChSettingsTitle => 'Settings';

  @override
  String get tourChSettingsBlurb =>
      'Your lists, the label printer, language and more';

  @override
  String get tourSettings1T => 'Help';

  @override
  String get tourSettings1B => 'Every tour is here, any time.';

  @override
  String get tourSettings2T => 'Your lists';

  @override
  String get tourSettings2B =>
      'Brands, models, RAM, colours, complaints: the rows in the forms come from these.';

  @override
  String get tourSettings3T => 'Label printer';

  @override
  String get tourSettings3B =>
      'Pair the Bluetooth label printer and print a test label.';

  @override
  String get tourSettings4T => 'Public web address';

  @override
  String get tourSettings4B =>
      'Only for customer rating links and the page a label\'s QR opens: the website where those pages live.';

  @override
  String get tourChAroundTitle => 'Getting around';

  @override
  String get tourChAroundBlurb => 'What each page is for and where to tap';

  @override
  String get tourThisPage => 'Tour of this page';

  @override
  String get tourMenuTitle => 'App tours';

  @override
  String get tourPractice => 'Practice data: nothing here is saved';

  @override
  String get tourFilling => 'The tour is filling this in…';

  @override
  String get shortcutNewBill => 'New bill';

  @override
  String get reminderMorningTitle => 'Today at the shop';

  @override
  String get setGroupReminders => 'Reminders';

  @override
  String get settingsReminders => 'Morning reminder';

  @override
  String get remindersHelp =>
      'At opening time this phone says what the day holds: repairs due today, late and ready, and enquiries to ring back. Worked out from what this phone last saw, so open the app each day to keep it right.';

  @override
  String get remindersAt => 'When';

  @override
  String get remindersOff => 'Off on this phone';

  @override
  String reminderDue(int n) {
    return '$n due today';
  }

  @override
  String reminderLate(int n) {
    return '$n late';
  }

  @override
  String reminderReady(int n) {
    return '$n ready to hand back';
  }

  @override
  String reminderRingBack(int n) {
    return '$n to ring back';
  }

  @override
  String reminderRingBackTitle(String name) {
    return 'Ring back: $name';
  }

  @override
  String get exportCsv => 'Export';

  @override
  String get exportBills => 'Bills, as a spreadsheet (CSV)';

  @override
  String get exportRepairs => 'Repairs, as a spreadsheet (CSV)';

  @override
  String exportFailed(String reason) {
    return 'Could not export: $reason';
  }

  @override
  String get exportStock => 'Phones in stock today (CSV)';

  @override
  String reminderReorder(int n) {
    return '$n to reorder';
  }

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
  String importAddAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count customers',
      one: 'Add 1 customer',
    );
    return '$_temp0';
  }

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers added',
      one: '1 customer added',
    );
    return '$_temp0';
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
  String productSummaryRetail(int lines, int units, String retail) {
    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$lines products',
      one: '1 product',
    );
    String _temp1 = intl.Intl.pluralLogic(
      units,
      locale: localeName,
      other: '$units units',
      one: '1 unit',
    );
    return '$_temp0 · $_temp1 · retail ₹$retail';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
    );
    return '$_temp0';
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
      'Completed bills, on the day they were completed — paid or still owed';

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
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
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
  String get recentlyOpened => 'Recently opened';

  @override
  String get searchPages => 'Pages';

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
  String get hintExpenseKinds => 'Offered when adding an expense.';

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

  @override
  String get homeBuyPhone => 'Buy phone';

  @override
  String get homeEnquiry => 'Enquiry';

  @override
  String get tabRepairs => 'Repairs';

  @override
  String get homeTodaysSales => 'Today\'s sales';

  @override
  String homeBillsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills',
      one: '1 bill',
    );
    return '$_temp0';
  }

  @override
  String get homeNewRepair => 'New repair';

  @override
  String get homeNeedsAction => 'Repairs needing action';

  @override
  String homeAllCount(int count) {
    return 'All $count';
  }

  @override
  String get homeLate => 'Late';

  @override
  String get homeDueToday => 'Due today';

  @override
  String get homeReady => 'Ready';

  @override
  String get homeJob => 'Job';

  @override
  String homeDaysLate(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days late',
      one: '1 day late',
      zero: 'Late today',
    );
    return '$_temp0';
  }

  @override
  String homeDueAt(String time) {
    return 'Due $time';
  }

  @override
  String homeAmountDue(String amount) {
    return '$amount due';
  }

  @override
  String get homeNothingNeedsAction => 'Nothing here right now';

  @override
  String get homeAlsoToday => 'Also on the board';

  @override
  String get homeOpenJob => 'Open';

  @override
  String stockDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get saveFailedTitle => 'Not saved';

  @override
  String get saveNoInternet =>
      'No internet. Nothing you typed is lost — try again when the phone is online.';

  @override
  String get saveNotAllowed =>
      'This account is not allowed to save this. Ask the shop owner.';

  @override
  String get saveTimedOut =>
      'Not confirmed after 20 seconds. Check the internet, then save again.';

  @override
  String saveFailedReason(String reason) {
    return 'Could not save: $reason';
  }

  @override
  String get okButton => 'OK';

  @override
  String get markReady => 'Mark ready';

  @override
  String get lpHint =>
      'Kept on this phone. Use a 2-inch Bluetooth label printer that says TSPL, with 50 × 25 mm stickers.';

  @override
  String get lpBluetooth => 'Bluetooth printer';

  @override
  String get lpPhoneMenu => 'Phone\'s print menu';

  @override
  String get lpChoose => 'Choose printer';

  @override
  String get lpNone => 'No printer chosen';

  @override
  String get lpPairFirst =>
      'No paired printers. Turn the printer on, pair it in the phone\'s Bluetooth settings, then come back.';

  @override
  String get lpSize => 'Sticker size';

  @override
  String get lpDarkness => 'Darkness';

  @override
  String get lpTest => 'Print test label';

  @override
  String get lpTestSent => 'Test label sent to the printer';

  @override
  String get lpRefresh => 'Refresh';

  @override
  String get btNoPrinter => 'No label printer chosen. Pick one in Settings.';

  @override
  String get btOff => 'Bluetooth is off. Turn it on and print again.';

  @override
  String get btPermission => 'Allow Bluetooth for this app, then print again.';

  @override
  String get btConnect =>
      'Could not reach the printer. Is it on and near the phone?';

  @override
  String get btWrite =>
      'The printer did not take the label. Check the sticker roll and try again.';

  @override
  String get setGroupShop => 'Shop';

  @override
  String get setGroupLists => 'Phones & stock lists';

  @override
  String get setGroupRepairs => 'Repairs';

  @override
  String get setGroupPrinting => 'Printing';

  @override
  String get setGroupStaff => 'Staff & money';

  @override
  String get setGroupOnline => 'Online';

  @override
  String get setBrandsModels => 'Brands & models';

  @override
  String get setMemory => 'RAM & storage';

  @override
  String setBrandsModelsCount(int brands, int models) {
    String _temp0 = intl.Intl.pluralLogic(
      brands,
      locale: localeName,
      other: '$brands brands',
      one: '1 brand',
    );
    String _temp1 = intl.Intl.pluralLogic(
      models,
      locale: localeName,
      other: '$models models',
      one: '1 model',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String setItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'Empty',
    );
    return '$_temp0';
  }

  @override
  String get setSearchList => 'Search this list';

  @override
  String get setRename => 'Rename';

  @override
  String setMemoryCount(int ram, int rom) {
    return '$ram RAM sizes · $rom storage sizes';
  }

  @override
  String get setAddNew => 'Type a new one';

  @override
  String get whereIsItNow => 'Where is it now?';

  @override
  String get trackReceived => 'Received';

  @override
  String get trackWorking => 'Working';

  @override
  String get trackHandedBack => 'Handed back';

  @override
  String sellerSoldBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sold you $count phones before',
      one: 'Sold you 1 phone before',
    );
    return '$_temp0';
  }

  @override
  String get igstTitle => 'Customer in another state (IGST)';

  @override
  String get igstHint => 'The bill shows IGST instead of CGST + SGST.';

  @override
  String get batteryHealthLabel => 'Battery health %';

  @override
  String get batteryHealthHelp =>
      'As the phone shows it: on an iPhone, Settings > Battery > Battery Health. On Android, a battery or diagnostics app. Leave empty if you could not check.';

  @override
  String get batteryHealthHint => 'e.g. 91';

  @override
  String batteryHealthValue(int percent) {
    return 'Battery $percent%';
  }

  @override
  String get billQueuedOffline =>
      'No internet: the bill is kept on this phone and will be completed by itself as soon as the internet is back.';

  @override
  String get pendingInternet => 'Waiting for internet';

  @override
  String get tourRepairAnotherT => 'Two phones, one visit';

  @override
  String get tourRepairAnotherB =>
      'Customer brought more than one phone? Save & add another phone: the next job starts with their details filled, both jobs are linked, and one final bill covers them all.';

  @override
  String get tourBuyAnotherT => 'More phones from the same seller';

  @override
  String get tourBuyAnotherB =>
      'Buying several phones from one person? Save & buy another: the seller, ID and signature carry over, and one declaration lists every phone with the total.';

  @override
  String get tourBillStockT => 'Pick a phone from stock';

  @override
  String get tourBillStockB =>
      'Add from stock lists the phones ready to sell. Type a model or IMEI, or tap a brand, then + Add. Phones on the bench or sold are shown grey, with the reason.';

  @override
  String get tourImportT => 'Bring in your contacts';

  @override
  String get tourImportB =>
      'Paste a list of names and numbers (or read it from the clipboard). Numbers already in the book are skipped, so nobody is added twice.';

  @override
  String get importFromPhone => 'From phone contacts';

  @override
  String get importFromFile => 'From a file (CSV or VCF)';

  @override
  String get importContactsDenied =>
      'Allow Contacts for this app to import from the phone.';

  @override
  String get importOpenSettings => 'Settings';

  @override
  String get importFileUnreadable =>
      'That file couldn\'t be read. Use a .csv or .vcf file.';

  @override
  String get importTickAll => 'Tick all';

  @override
  String get importUntickAll => 'Untick all';

  @override
  String get homeSaleSub => 'Phones & accessories';

  @override
  String get homeDaybook => 'Daybook';

  @override
  String get homeHideAmounts => 'Hide amounts';

  @override
  String get homeShowAmounts => 'Show amounts';

  @override
  String get homeBenchClear => 'Bench is clear';

  @override
  String get homeNoCredit => 'No pending credit';

  @override
  String get homeLogLeads => 'Log walk-in leads';

  @override
  String homeDueCustomers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers pending',
      one: '1 customer pending',
    );
    return '$_temp0';
  }

  @override
  String widgetOwed(String amount) {
    return 'Customers owe $amount';
  }

  @override
  String get expenseTooMuch =>
      'That\'s more than ₹9,99,99,999 — check the amount';

  @override
  String get expenseFutureDay => 'Can\'t be a day that hasn\'t come yet';

  @override
  String get tourWidgetTitle => 'On your phone\'s home screen too';

  @override
  String get tourWidgetBody =>
      'Long-press an empty spot on the phone\'s home screen, tap Widgets, find Shop Manager and drag \"Shop today\" out. It shows today\'s sales and the repairs waiting; the green button refreshes it.';

  @override
  String get taskBlockPastDue => 'Pick today or a later day';

  @override
  String get photoTapToView => 'Tap to view';

  @override
  String get photoAdd => 'Add photo';

  @override
  String get photoNoneYet => 'No photo yet';

  @override
  String get lockShow => 'Show';

  @override
  String get lockHide => 'Hide';

  @override
  String get lockNone => 'No lock';

  @override
  String get lockNotGiven => 'Not given';

  @override
  String get tourTeamInviteT => 'Adding someone';

  @override
  String get tourTeamInviteB =>
      'Tap Invite, type the email they will sign in with, and pick Staff or Admin. When they sign up with that email, they join your shop by themselves — no code to share.';

  @override
  String get signatureTapToSign => 'Tap to sign';

  @override
  String get signatureFullScreen => 'Sign full screen';

  @override
  String get signatureDone => 'Done';

  @override
  String get wizDeclaration => 'Declaration';

  @override
  String get tourBuySignT => '6 · Declaration and signature';

  @override
  String get tourBuySignB =>
      'Read every line to the seller, tick that they agree and that you saw their photo ID, then tap the box — they sign on a full screen. A new purchase cannot be saved without the signature.';

  @override
  String widgetRepairs(String amount, int back, int taken) {
    return 'Repairs $amount · $back handed back · $taken taken in';
  }

  @override
  String widgetNet(String spent, String net) {
    return 'Spent $spent · Net $net';
  }

  @override
  String widgetLateJob(String device, String customer, String late) {
    return 'Most late: $device · $customer · $late';
  }

  @override
  String widgetStock(int phones, int low, int calls) {
    String _temp0 = intl.Intl.pluralLogic(
      phones,
      locale: localeName,
      other: '$phones phones',
      one: '1 phone',
    );
    String _temp1 = intl.Intl.pluralLogic(
      calls,
      locale: localeName,
      other: '$calls calls',
      one: '1 call',
    );
    return '$_temp0 in stock · $low products low · $_temp1 today';
  }

  @override
  String get idPhotosFirst => 'Add both sides of the ID card first, then tick';

  @override
  String idFromEarlier(String date) {
    return 'ID card photos from the $date purchase';
  }

  @override
  String widgetNetOnly(String amount) {
    return 'Net $amount';
  }

  @override
  String widgetSpentOnly(String amount) {
    return 'Spent $amount';
  }

  @override
  String get widgetRepairsLabel => 'Repairs';

  @override
  String widgetJobsTitle(int taken, int back) {
    return 'Repairs · $taken in · $back back';
  }

  @override
  String get widgetNoJobs => 'No repairs waiting';

  @override
  String widgetLeft(String time) {
    return '$time left';
  }

  @override
  String widgetLateBy(String time) {
    return '$time late';
  }

  @override
  String widgetUnitMin(int n) {
    return '${n}m';
  }

  @override
  String widgetUnitHour(int n) {
    return '${n}h';
  }

  @override
  String widgetUnitDay(int n) {
    return '${n}d';
  }

  @override
  String widgetChipLate(int n) {
    return '$n late';
  }

  @override
  String widgetChipDue(int n) {
    return '$n today';
  }

  @override
  String widgetChipReady(int n) {
    return '$n ready';
  }

  @override
  String widgetStockShort(int phones, int low, int calls) {
    return '$phones in stock · $low low · $calls calls';
  }

  @override
  String widgetOwedShort(String amount) {
    return 'Owed $amount';
  }

  @override
  String get moreGroupMoney => 'Money';

  @override
  String get moreGroupStock => 'Stock';

  @override
  String get moreGroupPeople => 'People';

  @override
  String get moreGroupWork => 'Work';

  @override
  String get moreGroupOther => 'Other';

  @override
  String appBuild(String number, String version) {
    return 'Build $number · version $version';
  }

  @override
  String appBuildLocal(String version) {
    return 'Test build (not from GitHub) · version $version';
  }

  @override
  String get openSaved => 'Open';

  @override
  String get promiseToday => 'Today';

  @override
  String get promiseTomorrow => 'Tomorrow';

  @override
  String promiseInDays(int n) {
    return '$n days';
  }

  @override
  String get promiseWeek => '1 week';

  @override
  String get technicianNobody => 'Nobody';

  @override
  String technicianNotLinked(String name) {
    return '$name (not linked)';
  }

  @override
  String get technicianChange => 'Change';

  @override
  String technicianChanged(String name) {
    return 'Technician: $name';
  }

  @override
  String get technicianPickHint =>
      'Their phone gets this job\'s reminders and alarms.';

  @override
  String get reminderMorningMineTitle => 'Your repairs today';

  @override
  String alarmHourTitle(String device) {
    return 'Due in 1 hour: $device';
  }

  @override
  String alarmDueTitle(String device) {
    return 'Due now, not ready: $device';
  }

  @override
  String assignedTitle(String device) {
    return 'New repair for you: $device';
  }

  @override
  String assignedBody(String customer, String when) {
    return '$customer · due $when';
  }

  @override
  String get settingsRepairAlarms => 'Repair alarms';

  @override
  String get settingsRepairAlarmsHelp =>
      'On each technician\'s phone: a repair given to them, an alarm an hour before it is promised, and another when it is due and not ready. A repair with no technician rings on the admins\' phones.';

  @override
  String get notSigned => 'Not signed';

  @override
  String agreedOn(String date) {
    return 'Agreed on $date';
  }

  @override
  String get notAgreed => 'Not agreed';

  @override
  String get idNotChecked => 'ID not checked';

  @override
  String technicianMe(String name) {
    return '$name (me)';
  }

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get pickTimeTitle => 'Pick a time';

  @override
  String get pickTimeDone => 'Done';

  @override
  String get pickTimeButton => 'Time';

  @override
  String get historyTitle => 'History';

  @override
  String get historyReceived => 'Taken in';

  @override
  String historyTechnician(String name) {
    return 'Given to $name';
  }

  @override
  String get historyTechnicianNone => 'Technician removed';

  @override
  String historyStatus(String status) {
    return 'Status: $status';
  }

  @override
  String historyPrice(String amount) {
    return 'Final price $amount';
  }

  @override
  String get historyHandedBack => 'Handed back';

  @override
  String historyHandedBackPaid(String amount) {
    return 'Handed back · $amount collected';
  }

  @override
  String get historyReturned => 'Returned unrepaired';

  @override
  String historyBy(String name) {
    return 'by $name';
  }

  @override
  String get tabMyJobs => 'My jobs';

  @override
  String readyTitle(String device) {
    return 'Ready: $device';
  }

  @override
  String readyBody(String customer, String by) {
    return '$customer · made ready by $by';
  }

  @override
  String reportBestDay(String day, String amount) {
    return 'Best day $day · $amount';
  }

  @override
  String get reportTapDay => 'Tap a day to see it';

  @override
  String reportDayLine(String day, String amount, String bills) {
    return '$day · $amount · $bills';
  }

  @override
  String get reportWhatTheyMean => 'What these figures mean';

  @override
  String reportWeekOf(String day) {
    return 'Week of $day';
  }

  @override
  String reportPhonesSoldFor(String sold, String cost) {
    return 'Phones sold for $sold · cost $cost';
  }

  @override
  String get tileFromStock => 'Phone from stock';

  @override
  String get tileProduct => 'Product';

  @override
  String get tileOtherItem => 'Other item';

  @override
  String get tileRepair => 'Repair';

  @override
  String get tileRepairDone => 'Repair done';

  @override
  String get tileLabel => 'Label';

  @override
  String tileLabelNumber(String number) {
    return 'Label $number';
  }

  @override
  String get tileDeclaration => 'Declaration';

  @override
  String get soldElsewhere => 'Sold elsewhere (no bill)';

  @override
  String get repairDoneTitle => 'Repair done: back on the shelf';

  @override
  String get repairDoneCost => 'What the repair cost';

  @override
  String get repairDoneWhat => 'What was done';

  @override
  String repairDoneCostNow(String amount) {
    return 'The phone now costs you $amount';
  }

  @override
  String get repairDonePrice => 'Selling price';

  @override
  String get repairDonePriceHint =>
      'Old price plus the repair, so the profit stays the same';

  @override
  String repairDoneProfit(String amount) {
    return 'Profit at this price: $amount';
  }

  @override
  String get repairDoneSave => 'Save and put on the shelf';

  @override
  String get repairDoneWhatNeeded => 'Say what was done';

  @override
  String get repairDonePriceNeeded => 'A selling price is needed';

  @override
  String alarmLateTitle(String device) {
    return 'Late, not ready: $device';
  }

  @override
  String get photoShrinking => 'Making it smaller…';

  @override
  String get photoUploadingStart => 'Uploading…';

  @override
  String photoUploading(int percent) {
    return 'Uploading $percent%';
  }

  @override
  String get photoSaved => 'Photo saved';

  @override
  String get photoTitle => 'Photo';

  @override
  String get photoZoomHint => 'Pinch or double-tap to zoom';

  @override
  String get photoDetails => 'Details';

  @override
  String get photoFileSize => 'File size';

  @override
  String get photoPixels => 'Picture size';

  @override
  String get photoTakenAt => 'Taken';

  @override
  String get photoTakenBy => 'Taken by';

  @override
  String get photoFrom => 'From';

  @override
  String get photoFromCamera => 'Camera';

  @override
  String get photoFromGallery => 'Gallery';

  @override
  String get photoOriginalSize => 'Before shrinking';

  @override
  String get photoPrivate => 'Only this shop\'s staff can see it';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String get photoLoadFailed =>
      'This photo could not be loaded. Check the internet and try again.';

  @override
  String get addressOptionalHelp => 'Optional. Kept on the customer\'s page.';
}
