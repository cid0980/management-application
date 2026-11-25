import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
  ];

  /// The app's own name, in the title bar
  ///
  /// In en, this message translates to:
  /// **'Shop Manager'**
  String get appTitle;

  /// Drawer: the board staff open on
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Drawer: the customer book
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// Drawer: second-hand handset stock
  ///
  /// In en, this message translates to:
  /// **'Second-Hand'**
  String get navSecondHand;

  /// Drawer: new goods — chargers, cases, screen guards
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// Drawer: repair jobs
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get navService;

  /// Drawer: bills
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get navSales;

  /// Drawer: what customers still owe
  ///
  /// In en, this message translates to:
  /// **'Due Payments'**
  String get navDuePayments;

  /// Drawer: walk-in questions
  ///
  /// In en, this message translates to:
  /// **'Enquiries'**
  String get navEnquiries;

  /// Drawer: the barcode and IMEI scanner
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get navScanner;

  /// Drawer: the label registry
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get navLabels;

  /// Drawer: the shop's own vocabulary and options
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Drawer: revenue and activity
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// Drawer: who works here
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get navStaff;

  /// Drawer: sign out
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get navLogout;

  /// Bottom bar
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Bottom bar: second-hand handsets
  ///
  /// In en, this message translates to:
  /// **'Mobiles'**
  String get tabMobiles;

  /// Bottom bar: the raised scan button
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get tabScan;

  /// Bottom bar: the page listing every other area, and logout
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tabMore;

  /// Under the app name on the login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to your shop.'**
  String get signInSubtitle;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// Link under the sign-in button
  ///
  /// In en, this message translates to:
  /// **'Create account (new shop or invited staff)'**
  String get setUpNewShop;

  /// Link under the sign-in button
  ///
  /// In en, this message translates to:
  /// **'Forgotten password'**
  String get forgottenPassword;

  /// Create-shop screen heading
  ///
  /// In en, this message translates to:
  /// **'Set up your shop'**
  String get createShopTitle;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopName;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get shopPhone;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get shopAddress;

  /// Field label; the tax number is not translated
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get shopGstin;

  /// Button at the end of shop setup
  ///
  /// In en, this message translates to:
  /// **'Create shop'**
  String get createShop;

  /// Section heading and field label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Explains that the language belongs to the shop, not the phone
  ///
  /// In en, this message translates to:
  /// **'The language this shop works in. Everyone here sees the same one; you can change it later in Settings.'**
  String get languageHint;

  /// Snack bar after changing the language
  ///
  /// In en, this message translates to:
  /// **'Language saved'**
  String get languageSaved;

  /// Greeting before noon
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// Greeting from noon to five
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// Greeting after five
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// The greeting with the person's first name after it
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingNamed(String greeting, String name);

  /// Dashboard alert row
  ///
  /// In en, this message translates to:
  /// **'Overdue service orders'**
  String get overdueServiceOrders;

  /// No description provided for @dateTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dateTomorrow;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get dateNextWeek;

  /// No description provided for @dateInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{In 1 day} other{In {count} days}}'**
  String dateInDays(int count);

  /// No description provided for @dateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String dateDaysAgo(int count);

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @expenseAgain.
  ///
  /// In en, this message translates to:
  /// **'Again? One tap fills it in'**
  String get expenseAgain;

  /// No description provided for @expenseNew.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expenseNew;

  /// No description provided for @expenseEdit.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseEdit;

  /// No description provided for @expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved'**
  String get expenseSaved;

  /// No description provided for @expenseDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense?'**
  String get expenseDeleteConfirm;

  /// No description provided for @expenseOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can change or delete an expense once it is saved.'**
  String get expenseOwnerOnly;

  /// No description provided for @expenseNeedAmount.
  ///
  /// In en, this message translates to:
  /// **'Type how much was paid'**
  String get expenseNeedAmount;

  /// No description provided for @expenseNeedKind.
  ///
  /// In en, this message translates to:
  /// **'Pick what it was for'**
  String get expenseNeedKind;

  /// No description provided for @expenseWhatFor.
  ///
  /// In en, this message translates to:
  /// **'What for'**
  String get expenseWhatFor;

  /// No description provided for @expensePaidHow.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get expensePaidHow;

  /// No description provided for @expenseDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get expenseDay;

  /// No description provided for @expenseNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get expenseNote;

  /// No description provided for @expenseNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. A54 display from the supplier'**
  String get expenseNoteHint;

  /// No description provided for @expenseCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get expenseCash;

  /// No description provided for @expenseKindParts.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get expenseKindParts;

  /// No description provided for @expenseKindTea.
  ///
  /// In en, this message translates to:
  /// **'Tea & food'**
  String get expenseKindTea;

  /// No description provided for @expenseKindRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get expenseKindRent;

  /// No description provided for @expenseKindPower.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get expenseKindPower;

  /// No description provided for @expenseKindSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get expenseKindSalary;

  /// No description provided for @expenseKindTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expenseKindTransport;

  /// No description provided for @expenseKindSupplies.
  ///
  /// In en, this message translates to:
  /// **'Shop supplies'**
  String get expenseKindSupplies;

  /// No description provided for @expenseKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expenseKindOther;

  /// No description provided for @expensesCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load expenses'**
  String get expensesCouldNotLoad;

  /// No description provided for @loadingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Getting the expenses…'**
  String get loadingExpenses;

  /// No description provided for @expensesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get expensesEmpty;

  /// No description provided for @expensesEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'Write down what the shop pays for — parts, tea, rent — and the reports show what is left.'**
  String get expensesEmptyDetail;

  /// No description provided for @expenseThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get expenseThisMonth;

  /// No description provided for @expenseCashPart.
  ///
  /// In en, this message translates to:
  /// **'{amount} in cash'**
  String expenseCashPart(String amount);

  /// No description provided for @reportMoneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get reportMoneyOut;

  /// No description provided for @reportMoneyOutNone.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period.'**
  String get reportMoneyOutNone;

  /// No description provided for @reportCashLeft.
  ///
  /// In en, this message translates to:
  /// **'Cash left in the drawer'**
  String get reportCashLeft;

  /// No description provided for @reportCashLeftHint.
  ///
  /// In en, this message translates to:
  /// **'Cash taken on bills minus expenses paid in cash.'**
  String get reportCashLeftHint;

  /// No description provided for @reportAfterExpenses.
  ///
  /// In en, this message translates to:
  /// **'After expenses'**
  String get reportAfterExpenses;

  /// No description provided for @exportExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get exportExpenses;

  /// No description provided for @homeSpentToday.
  ///
  /// In en, this message translates to:
  /// **'{amount} spent today'**
  String homeSpentToday(String amount);

  /// No description provided for @loadingShopDetails.
  ///
  /// In en, this message translates to:
  /// **'Getting the shop\'s details…'**
  String get loadingShopDetails;

  /// No description provided for @shopDetailsCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not open the shop\'s details'**
  String get shopDetailsCouldNotLoad;

  /// No description provided for @shopDetailsNoAccount.
  ///
  /// In en, this message translates to:
  /// **'This phone is not connected to the shop\'s account. Sign out and sign in again with internet on.'**
  String get shopDetailsNoAccount;

  /// No description provided for @shopDetailsNotFound.
  ///
  /// In en, this message translates to:
  /// **'The shop\'s record was not found.'**
  String get shopDetailsNotFound;

  /// No description provided for @handOverCheck.
  ///
  /// In en, this message translates to:
  /// **'Check the phone'**
  String get handOverCheck;

  /// No description provided for @handOverPay.
  ///
  /// In en, this message translates to:
  /// **'What they pay'**
  String get handOverPay;

  /// No description provided for @handOverHowPaid.
  ///
  /// In en, this message translates to:
  /// **'How they paid'**
  String get handOverHowPaid;

  /// No description provided for @handOverToCollect.
  ///
  /// In en, this message translates to:
  /// **'To collect now'**
  String get handOverToCollect;

  /// No description provided for @handOverNeedPrice.
  ///
  /// In en, this message translates to:
  /// **'Type what is charged (0 for a free repair)'**
  String get handOverNeedPrice;

  /// No description provided for @handOverChecksLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 check left} other{{count} checks left}}'**
  String handOverChecksLeft(int count);

  /// No description provided for @handOverAndCollect.
  ///
  /// In en, this message translates to:
  /// **'Hand over · collect {amount}'**
  String handOverAndCollect(String amount);

  /// No description provided for @handOverButton.
  ///
  /// In en, this message translates to:
  /// **'Hand over the phone'**
  String get handOverButton;

  /// No description provided for @handOverCard.
  ///
  /// In en, this message translates to:
  /// **'Before hand-over'**
  String get handOverCard;

  /// No description provided for @saveAddAnotherPhone.
  ///
  /// In en, this message translates to:
  /// **'Save & add another phone'**
  String get saveAddAnotherPhone;

  /// No description provided for @savedAddAnother.
  ///
  /// In en, this message translates to:
  /// **'{number} saved — now the next phone'**
  String savedAddAnother(String number);

  /// No description provided for @visitAnotherPhoneFor.
  ///
  /// In en, this message translates to:
  /// **'Another phone for {name}'**
  String visitAnotherPhoneFor(String name);

  /// No description provided for @visitSameAs.
  ///
  /// In en, this message translates to:
  /// **'Same visit as {number}: one job card and one bill for all'**
  String visitSameAs(String number);

  /// No description provided for @visitPhones.
  ///
  /// In en, this message translates to:
  /// **'Phones in this visit'**
  String get visitPhones;

  /// No description provided for @visitAddPhone.
  ///
  /// In en, this message translates to:
  /// **'Add another phone'**
  String get visitAddPhone;

  /// No description provided for @visitPhoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 phone, one job card and one bill} other{{count} phones, one job card and one bill}}'**
  String visitPhoneCount(int count);

  /// No description provided for @saveBuyAnotherFromSeller.
  ///
  /// In en, this message translates to:
  /// **'Save, print label & buy another from this seller'**
  String get saveBuyAnotherFromSeller;

  /// No description provided for @buyNextFromSeller.
  ///
  /// In en, this message translates to:
  /// **'now the next phone from this seller'**
  String get buyNextFromSeller;

  /// No description provided for @buyAnotherFrom.
  ///
  /// In en, this message translates to:
  /// **'Another phone from {name}'**
  String buyAnotherFrom(String name);

  /// No description provided for @buyAnotherSameSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller, ID and signature carried over: one declaration for all'**
  String get buyAnotherSameSeller;

  /// No description provided for @boughtTogether.
  ///
  /// In en, this message translates to:
  /// **'Bought together'**
  String get boughtTogether;

  /// No description provided for @boughtTogetherCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 phone from this seller, one declaration} other{{count} phones from this seller, one declaration}}'**
  String boughtTogetherCount(int count);

  /// No description provided for @buyAnotherFromSeller.
  ///
  /// In en, this message translates to:
  /// **'Buy another from this seller'**
  String get buyAnotherFromSeller;

  /// No description provided for @billsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bill} other{{count} bills}}'**
  String billsCount(int count);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @alreadyOnBill.
  ///
  /// In en, this message translates to:
  /// **'Already on this bill'**
  String get alreadyOnBill;

  /// No description provided for @allOnThisBill.
  ///
  /// In en, this message translates to:
  /// **'All of it is already on this bill'**
  String get allOnThisBill;

  /// No description provided for @leftCount.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String leftCount(int count);

  /// No description provided for @onShelfCount.
  ///
  /// In en, this message translates to:
  /// **'{count} on the shelf'**
  String onShelfCount(int count);

  /// No description provided for @onlyLeftCount.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left — that is all there is'**
  String onlyLeftCount(int count);

  /// No description provided for @quantityAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'At least 1'**
  String get quantityAtLeastOne;

  /// No description provided for @walletHoldsOnly.
  ///
  /// In en, this message translates to:
  /// **'Their wallet holds ₹{amount}'**
  String walletHoldsOnly(String amount);

  /// No description provided for @splitSayHowMuch.
  ///
  /// In en, this message translates to:
  /// **'Say how much came in by each way'**
  String get splitSayHowMuch;

  /// No description provided for @downPaymentAtCounter.
  ///
  /// In en, this message translates to:
  /// **'Down payment at the counter'**
  String get downPaymentAtCounter;

  /// No description provided for @downPaymentEmptyMeansNone.
  ///
  /// In en, this message translates to:
  /// **'Empty means no down payment — the financier pays it all'**
  String get downPaymentEmptyMeansNone;

  /// No description provided for @downPaymentPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Down payment paid by'**
  String get downPaymentPaidBy;

  /// No description provided for @changeToGiveBack.
  ///
  /// In en, this message translates to:
  /// **'Change to give back'**
  String get changeToGiveBack;

  /// No description provided for @draftTotal.
  ///
  /// In en, this message translates to:
  /// **'₹{total} · draft, nothing paid yet'**
  String draftTotal(String total);

  /// No description provided for @cancelledTotal.
  ///
  /// In en, this message translates to:
  /// **'₹{total} · cancelled'**
  String cancelledTotal(String total);

  /// No description provided for @otherMethods.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 other} other{{count} others}}'**
  String otherMethods(int count);

  /// No description provided for @billCancelledDone.
  ///
  /// In en, this message translates to:
  /// **'Bill cancelled'**
  String get billCancelledDone;

  /// No description provided for @billCancelKept.
  ///
  /// In en, this message translates to:
  /// **'The bill is kept on record as cancelled.'**
  String get billCancelKept;

  /// No description provided for @refundHow.
  ///
  /// In en, this message translates to:
  /// **'{amount} was paid — how did it go back?'**
  String refundHow(String amount);

  /// No description provided for @refundToWallet.
  ///
  /// In en, this message translates to:
  /// **'Leave on their wallet'**
  String get refundToWallet;

  /// No description provided for @cancelNeedReason.
  ///
  /// In en, this message translates to:
  /// **'Say why — it goes on the record'**
  String get cancelNeedReason;

  /// No description provided for @advanceWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'The {amount} advance'**
  String advanceWhatHappened(String amount);

  /// No description provided for @advanceGivenBack.
  ///
  /// In en, this message translates to:
  /// **'Given back'**
  String get advanceGivenBack;

  /// No description provided for @advanceKeptAsFee.
  ///
  /// In en, this message translates to:
  /// **'Kept as the fee'**
  String get advanceKeptAsFee;

  /// No description provided for @returnNeedReason.
  ///
  /// In en, this message translates to:
  /// **'Say why — it goes on the record'**
  String get returnNeedReason;

  /// No description provided for @changeGiveBack.
  ///
  /// In en, this message translates to:
  /// **'Change to give back'**
  String get changeGiveBack;

  /// No description provided for @enquiryMarkAs.
  ///
  /// In en, this message translates to:
  /// **'Mark as {status}'**
  String enquiryMarkAs(String status);

  /// No description provided for @enquiryMarkAsBody.
  ///
  /// In en, this message translates to:
  /// **'The enquiry is settled and leaves the open list. It can be reopened.'**
  String get enquiryMarkAsBody;

  /// No description provided for @makeABill.
  ///
  /// In en, this message translates to:
  /// **'Make a bill'**
  String get makeABill;

  /// No description provided for @stocktakeTypeCount.
  ///
  /// In en, this message translates to:
  /// **'Type what is on the shelf — 0 if it is empty'**
  String get stocktakeTypeCount;

  /// No description provided for @purchaseResumed.
  ///
  /// In en, this message translates to:
  /// **'Carried on from an unfinished purchase'**
  String get purchaseResumed;

  /// No description provided for @startFresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get startFresh;

  /// No description provided for @discardPurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Throw this purchase away?'**
  String get discardPurchaseTitle;

  /// No description provided for @discardPurchaseBody.
  ///
  /// In en, this message translates to:
  /// **'Everything typed in all five steps is lost.'**
  String get discardPurchaseBody;

  /// No description provided for @discardPurchaseYes.
  ///
  /// In en, this message translates to:
  /// **'Throw away'**
  String get discardPurchaseYes;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// Dashboard: today's takings card
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Under today's takings: drafts are not money
  ///
  /// In en, this message translates to:
  /// **'Completed bills only'**
  String get completedBillsOnly;

  /// Dashboard section heading
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// Quick action
  ///
  /// In en, this message translates to:
  /// **'New service order'**
  String get newServiceOrder;

  /// Quick action: buying a second-hand handset in
  ///
  /// In en, this message translates to:
  /// **'New purchase'**
  String get newPurchase;

  /// Quick action
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get newSale;

  /// Dashboard tile
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get tilePendingOrders;

  /// Dashboard tile
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tileOverdue;

  /// Dashboard tile: promised back today
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get tileDueToday;

  /// Dashboard tile
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get tileLowStock;

  /// Dashboard tile
  ///
  /// In en, this message translates to:
  /// **'Due Payments'**
  String get tileDuePayments;

  /// Dashboard tile: bills started and not finished
  ///
  /// In en, this message translates to:
  /// **'Pending Bills'**
  String get tilePendingBills;

  /// Dashboard tile
  ///
  /// In en, this message translates to:
  /// **'Open Enquiries'**
  String get tileOpenEnquiries;

  /// Dashboard tile
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get tileCustomers;

  /// Dashboard tile: customers added today
  ///
  /// In en, this message translates to:
  /// **'New Today'**
  String get tileNewToday;

  /// Dashboard section heading
  ///
  /// In en, this message translates to:
  /// **'Recent orders'**
  String get recentOrders;

  /// Dashboard: no service orders at all
  ///
  /// In en, this message translates to:
  /// **'Nothing taken in yet'**
  String get nothingTakenInYet;

  /// On a tile whose count failed — never shown as a zero
  ///
  /// In en, this message translates to:
  /// **'Could not be read'**
  String get couldNotBeRead;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Under the app name while signing up
  ///
  /// In en, this message translates to:
  /// **'Invited by a shop? Use the email they invited and you join it straight away. Otherwise you set up your shop next.'**
  String get signUpSubtitle;

  /// Button while signing up
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// Link back to signing in
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// Snack bar after a password reset
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email}'**
  String resetLinkSent(String email);

  /// Customer list: the read failed
  ///
  /// In en, this message translates to:
  /// **'The customer book could not be loaded'**
  String get customerBookFailed;

  /// Retry button on a failed load
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Search box in the customer list
  ///
  /// In en, this message translates to:
  /// **'Name or number'**
  String get searchNameOrNumber;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Button that adds the thing just typed
  ///
  /// In en, this message translates to:
  /// **'Add {what}'**
  String addNamed(String what);

  /// A customer recorded by number alone
  ///
  /// In en, this message translates to:
  /// **'No name given'**
  String get noNameGiven;

  /// Empty customer list
  ///
  /// In en, this message translates to:
  /// **'Nobody in the book yet'**
  String get nobodyInBookYet;

  /// Search found nothing
  ///
  /// In en, this message translates to:
  /// **'No match for \"{query}\"'**
  String noMatchFor(String query);

  /// The record is gone
  ///
  /// In en, this message translates to:
  /// **'No customer {id}'**
  String noCustomer(String id);

  /// Button and tooltip
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Section heading on a detail page
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Second number'**
  String get secondNumber;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Handsets this customer sold in
  ///
  /// In en, this message translates to:
  /// **'Sold to the shop'**
  String get soldToTheShop;

  /// Empty section on a detail page
  ///
  /// In en, this message translates to:
  /// **'Nothing yet.'**
  String get nothingYet;

  /// The customer's shop credit
  ///
  /// In en, this message translates to:
  /// **'Wallet ₹{amount}'**
  String wallet(String amount);

  /// Wallet button
  ///
  /// In en, this message translates to:
  /// **'Add credit'**
  String get addCredit;

  /// Wallet button
  ///
  /// In en, this message translates to:
  /// **'Spend'**
  String get spend;

  /// Empty wallet history
  ///
  /// In en, this message translates to:
  /// **'No wallet moves yet.'**
  String get noWalletMoves;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Add credit to the wallet'**
  String get addCreditToWallet;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Spend from the wallet'**
  String get spendFromWallet;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Why a wallet move was made
  ///
  /// In en, this message translates to:
  /// **'What it is for'**
  String get whatItIsFor;

  /// Helper text under a field that must be filled
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Confirm button in a dialog
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Snack bar after a wallet move
  ///
  /// In en, this message translates to:
  /// **'Wallet is now ₹{amount}'**
  String walletIsNow(String amount);

  /// Form sheet title
  ///
  /// In en, this message translates to:
  /// **'Add a customer'**
  String get addACustomer;

  /// Tooltip on the X of a form sheet
  ///
  /// In en, this message translates to:
  /// **'Discard this draft'**
  String get discardThisDraft;

  /// Helper under the phone field
  ///
  /// In en, this message translates to:
  /// **'How the shop finds them again'**
  String get howTheShopFindsThem;

  /// Helper under the name field
  ///
  /// In en, this message translates to:
  /// **'Optional — a number on its own is a customer'**
  String get nameOptionalHelp;

  /// Snack bar after saving a record
  ///
  /// In en, this message translates to:
  /// **'Saved {what}'**
  String savedNamed(String what);

  /// The handset record is gone
  ///
  /// In en, this message translates to:
  /// **'No second-hand record {id}.'**
  String noSecondHandRecord(String id);

  /// Explains an empty handset page reached from a label
  ///
  /// In en, this message translates to:
  /// **'A label scanned for a record that has since been deleted lands here — the label number is still worth noting down.'**
  String get deletedLabelNote;

  /// Chip on a handset
  ///
  /// In en, this message translates to:
  /// **'Grade {grade}'**
  String gradeNamed(String grade);

  /// Chip showing the sticker number
  ///
  /// In en, this message translates to:
  /// **'Label {number}'**
  String labelNamed(String number);

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get money;

  /// Section heading and a cost line
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get repairs;

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// Field label: the RAM/storage version
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get variant;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colour;

  /// Field label for a dual-SIM handset's second IMEI
  ///
  /// In en, this message translates to:
  /// **'IMEI 2'**
  String get imei2;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get serial;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Paid to seller'**
  String get paidToSeller;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Other costs'**
  String get otherCosts;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get totalCost;

  /// Money row: the shelf price
  ///
  /// In en, this message translates to:
  /// **'Asking'**
  String get asking;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Expected profit'**
  String get expectedProfit;

  /// Money row: what it actually made
  ///
  /// In en, this message translates to:
  /// **'Realised profit'**
  String get realisedProfit;

  /// Value where a profit is not known yet
  ///
  /// In en, this message translates to:
  /// **'not sold yet'**
  String get notSoldYet;

  /// Condition row
  ///
  /// In en, this message translates to:
  /// **'Stored grade'**
  String get storedGrade;

  /// Condition row
  ///
  /// In en, this message translates to:
  /// **'From the checklist'**
  String get fromTheChecklist;

  /// Condition row
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// A count against a total
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String outOf(String done, String total);

  /// Condition row: the grade was overridden
  ///
  /// In en, this message translates to:
  /// **'Set by hand'**
  String get setByHand;

  /// Condition row
  ///
  /// In en, this message translates to:
  /// **'Critical faults open'**
  String get criticalFaultsOpen;

  /// Where no grade could be worked out
  ///
  /// In en, this message translates to:
  /// **'not graded'**
  String get notGraded;

  /// Seller row
  ///
  /// In en, this message translates to:
  /// **'ID proof'**
  String get idProof;

  /// Value for something nobody filled in
  ///
  /// In en, this message translates to:
  /// **'not recorded'**
  String get notRecorded;

  /// Seller row: did they sign the declaration
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get signed;

  /// Value
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get yes;

  /// Value
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get no;

  /// Snack bar after taking a handset off the bench
  ///
  /// In en, this message translates to:
  /// **'Back on the shelf'**
  String get backOnTheShelf;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Moved to the bench'**
  String get movedToTheBench;

  /// Button: take it off the bench
  ///
  /// In en, this message translates to:
  /// **'Repair finished'**
  String get repairFinished;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Send to the bench'**
  String get sendToTheBench;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Mark sold'**
  String get markSold;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Assign and print a label'**
  String get assignAndPrintLabel;

  /// Form sheet title for a purchase
  ///
  /// In en, this message translates to:
  /// **'Take in a handset'**
  String get takeInAHandset;

  /// Form sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit purchase'**
  String get editPurchase;

  /// Form section
  ///
  /// In en, this message translates to:
  /// **'IMEI & serial'**
  String get imeiAndSerial;

  /// Form section
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// Form section
  ///
  /// In en, this message translates to:
  /// **'Repair & refurbishment'**
  String get repairAndRefurb;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add a repair'**
  String get addARepair;

  /// Switch on the purchase form
  ///
  /// In en, this message translates to:
  /// **'Still on the bench'**
  String get stillOnTheBench;

  /// Under that switch
  ///
  /// In en, this message translates to:
  /// **'Kept out of the sale picker until the repair is done.'**
  String get stillOnTheBenchHint;

  /// Form section
  ///
  /// In en, this message translates to:
  /// **'Condition & grade'**
  String get conditionAndGrade;

  /// Form section
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// The first photo of a handset
  ///
  /// In en, this message translates to:
  /// **'Front view'**
  String get frontView;

  /// A later photo
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String photoNumbered(String number);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add the front view'**
  String get addTheFrontView;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addAPhoto;

  /// Switch on the purchase form
  ///
  /// In en, this message translates to:
  /// **'Seller has signed the declaration'**
  String get sellerSigned;

  /// Under that switch
  ///
  /// In en, this message translates to:
  /// **'Needed only to print it — a declaration nobody signed looks like proof.'**
  String get sellerSignedHint;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Save & print'**
  String get saveAndPrint;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Repair done before resale'**
  String get repairDoneBeforeResale;

  /// Field label in the repair dialog
  ///
  /// In en, this message translates to:
  /// **'What was done'**
  String get whatWasDone;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// Heading over warnings that do not block a save
  ///
  /// In en, this message translates to:
  /// **'Worth a look'**
  String get worthALook;

  /// Condition summary with an empty checklist
  ///
  /// In en, this message translates to:
  /// **'Not graded — nothing answered yet'**
  String get notGradedNothingAnswered;

  /// The critical faults found
  ///
  /// In en, this message translates to:
  /// **'Critical: {faults}'**
  String criticalNamed(String faults);

  /// Before the grade override dropdown
  ///
  /// In en, this message translates to:
  /// **'Override: '**
  String get overrideLabel;

  /// Under a critical checklist item
  ///
  /// In en, this message translates to:
  /// **'Critical — caps the grade'**
  String get criticalCapsGrade;

  /// Running total on the purchase form
  ///
  /// In en, this message translates to:
  /// **'Cost ₹{amount}'**
  String costNamed(String amount);

  /// Running total on the purchase form
  ///
  /// In en, this message translates to:
  /// **'Expected profit ₹{amount}'**
  String expectedProfitNamed(String amount);

  /// Second-hand list: the read failed
  ///
  /// In en, this message translates to:
  /// **'Stock could not be loaded'**
  String get stockCouldNotBeLoaded;

  /// Search box in the stock list
  ///
  /// In en, this message translates to:
  /// **'Brand, model, IMEI, label or seller'**
  String get searchStock;

  /// Total asking price of the stock on screen
  ///
  /// In en, this message translates to:
  /// **'asking ₹{amount}'**
  String askingTotal(String amount);

  /// Empty tab
  ///
  /// In en, this message translates to:
  /// **'Nothing in {tab}'**
  String nothingInTab(String tab);

  /// Empty stock list
  ///
  /// In en, this message translates to:
  /// **'Take a handset in with the button below.'**
  String get takeAHandsetIn;

  /// When a stock search finds nothing
  ///
  /// In en, this message translates to:
  /// **'The search covers brand, model, IMEI, label number and seller.'**
  String get stockSearchCovers;

  /// Button that starts a purchase
  ///
  /// In en, this message translates to:
  /// **'Take in'**
  String get takeIn;

  /// Subtitle of a sold handset
  ///
  /// In en, this message translates to:
  /// **'Sold ₹{price} · made ₹{profit}'**
  String soldMade(String price, String profit);

  /// Subtitle of a handset in stock
  ///
  /// In en, this message translates to:
  /// **'Asking ₹{asking} · cost ₹{cost}'**
  String askingCost(String asking, String cost);

  /// Snack bar after saving a purchase with a declaration
  ///
  /// In en, this message translates to:
  /// **'Saved {what} — declaration queued to print'**
  String declarationQueued(String what);

  /// Snack bar when a typed value joins the dropdowns
  ///
  /// In en, this message translates to:
  /// **'Added to the shop lists: {count, plural, =1{1 new value} other{{count} new values}}'**
  String addedToShopLists(int count);

  /// The product record is gone
  ///
  /// In en, this message translates to:
  /// **'No product {id}.'**
  String noProduct(String id);

  /// Explains an empty product page reached from a label
  ///
  /// In en, this message translates to:
  /// **'A shelf label scanned for a product that has since been deleted lands here — the label number is still worth noting down.'**
  String get deletedShelfLabelNote;

  /// Banner on a product with no stock
  ///
  /// In en, this message translates to:
  /// **'Out of stock — this cannot be sold until some comes in.'**
  String get outOfStockCannotSell;

  /// Banner on a low-stock product
  ///
  /// In en, this message translates to:
  /// **'At or below the reorder level of {level}'**
  String atOrBelowReorder(String level);

  /// The stored count and its movements disagree
  ///
  /// In en, this message translates to:
  /// **'The history adds up to {ledger}, not {count}. This record needs looking at.'**
  String historyDisagreesStock(String ledger, String count);

  /// Section heading on a product
  ///
  /// In en, this message translates to:
  /// **'What it is'**
  String get whatItIs;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Value where no category was picked
  ///
  /// In en, this message translates to:
  /// **'not categorised'**
  String get notCategorised;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get costPrice;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get sellingPrice;

  /// MRP on a product detail page
  ///
  /// In en, this message translates to:
  /// **'Printed maximum'**
  String get printedMaximum;

  /// MRP field label on the form
  ///
  /// In en, this message translates to:
  /// **'Printed maximum (MRP)'**
  String get printedMaximumMrp;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Profit per unit'**
  String get profitPerUnit;

  /// Running total on the product form
  ///
  /// In en, this message translates to:
  /// **'Profit per unit ₹{amount}'**
  String profitPerUnitNamed(String amount);

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Stock at cost'**
  String get stockAtCost;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Stock at retail'**
  String get stockAtRetail;

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Reordering'**
  String get reordering;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Reorder level'**
  String get reorderLevel;

  /// Value where no threshold was set
  ///
  /// In en, this message translates to:
  /// **'not set — this will only ever show as out of stock'**
  String get noReorderLevelSet;

  /// How many to reorder
  ///
  /// In en, this message translates to:
  /// **'Suggested order'**
  String get suggestedOrder;

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Stock history'**
  String get stockHistory;

  /// Empty stock history
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Record the first delivery and the history will say where the stock came from.'**
  String get noStockHistory;

  /// Button: record a delivery
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// Button: count the shelf
  ///
  /// In en, this message translates to:
  /// **'Stock-take'**
  String get stockTake;

  /// Button: write stock off
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get damaged;

  /// Button on a record that already has a label
  ///
  /// In en, this message translates to:
  /// **'Reprint label {number}'**
  String reprintLabel(String number);

  /// Snack bar after a stock movement
  ///
  /// In en, this message translates to:
  /// **'Now {count} on the shelf'**
  String nowOnTheShelf(String count);

  /// Snack bar after adding a product
  ///
  /// In en, this message translates to:
  /// **'Saved {what} — receive stock from its page to set the count'**
  String savedReceiveStock(String what);

  /// Form sheet title
  ///
  /// In en, this message translates to:
  /// **'Add a product'**
  String get addAProduct;

  /// Form sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// Helper under the product name
  ///
  /// In en, this message translates to:
  /// **'What the counter searches for'**
  String get whatTheCounterSearches;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Variant (model it fits, size)'**
  String get variantFits;

  /// Form section
  ///
  /// In en, this message translates to:
  /// **'When to reorder'**
  String get whenToReorder;

  /// Helper under the reorder level
  ///
  /// In en, this message translates to:
  /// **'Leave empty for no low-stock alert on this product'**
  String get reorderLevelHelp;

  /// Note on the product form
  ///
  /// In en, this message translates to:
  /// **'On the shelf now: {count}. Stock is changed from the product page, with a reason — never from this form.'**
  String onTheShelfNow(String count);

  /// Note on the product form
  ///
  /// In en, this message translates to:
  /// **'A new product starts at zero. Its first delivery is recorded from its page, so the history says where the stock came from.'**
  String get newProductStartsAtZero;

  /// Form section
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// The first product photo
  ///
  /// In en, this message translates to:
  /// **'Main photo'**
  String get mainPhoto;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add another'**
  String get addAnother;

  /// Product list: the read failed
  ///
  /// In en, this message translates to:
  /// **'Products could not be loaded'**
  String get productsCouldNotBeLoaded;

  /// Search box in the product list
  ///
  /// In en, this message translates to:
  /// **'Name, brand, category, SKU or supplier'**
  String get searchProducts;

  /// Totals over the product list
  ///
  /// In en, this message translates to:
  /// **'cost ₹{cost} · retail ₹{retail}'**
  String costRetail(String cost, String retail);

  /// Empty product list
  ///
  /// In en, this message translates to:
  /// **'Nothing on the list yet. Add a product with the button below.'**
  String get nothingOnTheListYet;

  /// Subtitle on a product row
  ///
  /// In en, this message translates to:
  /// **'Reorder at {level}'**
  String reorderAt(String level);

  /// Subtitle on a product row
  ///
  /// In en, this message translates to:
  /// **'No reorder level set'**
  String get noReorderLevel;

  /// Helper under the SKU field
  ///
  /// In en, this message translates to:
  /// **'The shop\'s own code — not the shop label'**
  String get skuHelp;

  /// The order record is gone
  ///
  /// In en, this message translates to:
  /// **'No service order {id}.'**
  String noServiceOrder(String id);

  /// Explains an empty order page reached from a label
  ///
  /// In en, this message translates to:
  /// **'A job card scanned for an order that has since been deleted lands here — the order number is still worth noting down.'**
  String get deletedJobCardNote;

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// Field label: the screen lock type
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// Field label: the pattern or PIN
  ///
  /// In en, this message translates to:
  /// **'Unlock with'**
  String get unlockWith;

  /// Accessories left with the handset
  ///
  /// In en, this message translates to:
  /// **'Left with it'**
  String get leftWithIt;

  /// Value where no accessories were left
  ///
  /// In en, this message translates to:
  /// **'nothing'**
  String get nothingValue;

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaints;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Estimate quoted'**
  String get estimateQuoted;

  /// Money row: parts
  ///
  /// In en, this message translates to:
  /// **'Raw material'**
  String get rawMaterial;

  /// Money row: work sent out
  ///
  /// In en, this message translates to:
  /// **'Outside labour'**
  String get outsideLabour;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get costs;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Profit at the estimate'**
  String get profitAtEstimate;

  /// Money row: what the customer actually paid
  ///
  /// In en, this message translates to:
  /// **'Charged'**
  String get charged;

  /// Value where a job has no final price
  ///
  /// In en, this message translates to:
  /// **'not charged yet'**
  String get notChargedYet;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Profit made'**
  String get profitMade;

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// Date row
  ///
  /// In en, this message translates to:
  /// **'Came in'**
  String get cameIn;

  /// Date row: when it was promised back
  ///
  /// In en, this message translates to:
  /// **'Promised'**
  String get promised;

  /// Date row
  ///
  /// In en, this message translates to:
  /// **'Handed back'**
  String get handedBack;

  /// Who is working on it
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technician;

  /// Value where nobody is assigned
  ///
  /// In en, this message translates to:
  /// **'nobody yet'**
  String get nobodyYet;

  /// Value for a date nobody filled in
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get notSet;

  /// Banner on a closed order
  ///
  /// In en, this message translates to:
  /// **'Handed back on {date}. Nothing more is owed on it.'**
  String handedBackOn(String date);

  /// Section heading on an order
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Why Completed is missing from the status list
  ///
  /// In en, this message translates to:
  /// **'Completed is not here for anyone — a phone goes back by passing the pre-delivery checklist below.'**
  String get completedIsNotHere;

  /// Snack bar after a status change
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusNamed(String status);

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Pre-delivery checklist'**
  String get preDeliveryChecklist;

  /// When the checklist is empty
  ///
  /// In en, this message translates to:
  /// **'No checklist configured in settings, so there is nothing to verify before handing a phone back.'**
  String get noChecklistConfigured;

  /// Snack bar after taking a repair in
  ///
  /// In en, this message translates to:
  /// **'Saved {what} — job card queued to print'**
  String savedJobCard(String what);

  /// Form sheet title
  ///
  /// In en, this message translates to:
  /// **'Take in a repair'**
  String get takeInARepair;

  /// Form sheet title when editing
  ///
  /// In en, this message translates to:
  /// **'Edit {what}'**
  String editNamed(String what);

  /// Helper under the phone field
  ///
  /// In en, this message translates to:
  /// **'Finds whoever has been here before'**
  String get findsWhoeverBeenHere;

  /// Helper for a pattern lock
  ///
  /// In en, this message translates to:
  /// **'Pattern, as 1-2-3-6-9'**
  String get patternAs;

  /// Field label for a PIN or password
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// Heading over the accessory chips
  ///
  /// In en, this message translates to:
  /// **'Left with the device'**
  String get leftWithTheDevice;

  /// Search box above the repair complaints row
  ///
  /// In en, this message translates to:
  /// **'Type to find an issue'**
  String get findAnIssue;

  /// Form section
  ///
  /// In en, this message translates to:
  /// **'Issues & complaints'**
  String get issuesAndComplaints;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'What the customer said'**
  String get whatTheCustomerSaid;

  /// Form section
  ///
  /// In en, this message translates to:
  /// **'Estimate & schedule'**
  String get estimateAndSchedule;

  /// Running total on the intake form
  ///
  /// In en, this message translates to:
  /// **'Costs ₹{costs} · profit at the estimate ₹{profit}'**
  String costsProfitNamed(String costs, String profit);

  /// Date field label
  ///
  /// In en, this message translates to:
  /// **'Device came in'**
  String get deviceCameIn;

  /// Date field label
  ///
  /// In en, this message translates to:
  /// **'Promised to the customer'**
  String get promisedToCustomer;

  /// When a phone number matches no customer
  ///
  /// In en, this message translates to:
  /// **'Nobody in the book on that number — the order will carry the number and the name typed here.'**
  String get nobodyOnThatNumber;

  /// Service list: the read failed
  ///
  /// In en, this message translates to:
  /// **'Service orders could not be loaded'**
  String get serviceOrdersCouldNotLoad;

  /// Search box in the service list
  ///
  /// In en, this message translates to:
  /// **'Order number, customer, device or IMEI'**
  String get searchServiceOrders;

  /// Subtitle on an order with no complaint
  ///
  /// In en, this message translates to:
  /// **'No complaint recorded'**
  String get noComplaintRecorded;

  /// Subtitle of a date field nobody has filled in
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSetTitle;

  /// Totals over the second-hand list
  ///
  /// In en, this message translates to:
  /// **'{count} on hand · cost ₹{cost} · asking ₹{asking}'**
  String stockSummary(String count, String cost, String asking);

  /// Totals over the product list
  ///
  /// In en, this message translates to:
  /// **'{lines, plural, =1{1 product} other{{lines} products}} · {units, plural, =1{1 unit} other{{units} units}} · cost ₹{cost} · retail ₹{retail}'**
  String productSummary(int lines, int units, String cost, String retail);

  /// Empty due-payments list
  ///
  /// In en, this message translates to:
  /// **'Nothing outstanding'**
  String get nothingOutstanding;

  /// Empty due-payments list
  ///
  /// In en, this message translates to:
  /// **'Financed sales are not counted here — those customers owe the shop nothing.'**
  String get financedNotCountedHere;

  /// Heading over the due-payments list
  ///
  /// In en, this message translates to:
  /// **'₹{total} owed by {count, plural, =1{1 customer} other{{count} customers}}'**
  String owedByCustomers(String total, int count);

  /// Under the due-payments heading
  ///
  /// In en, this message translates to:
  /// **'Financed sales are not here: the customer owes nothing, and the financier\'s settlement is a different ledger.'**
  String get financedNotHere;

  /// How long a balance has been outstanding
  ///
  /// In en, this message translates to:
  /// **'oldest {days, plural, =1{1 day} other{{days} days}}'**
  String oldestDays(int days);

  /// A bill line in due payments
  ///
  /// In en, this message translates to:
  /// **'₹{total} billed · ₹{paid} paid · {method}'**
  String billedPaidMethod(String total, String paid, String method);

  /// Button in due payments
  ///
  /// In en, this message translates to:
  /// **'Open the customer'**
  String get openTheCustomer;

  /// The bill record is gone
  ///
  /// In en, this message translates to:
  /// **'No sale {id}'**
  String noSale(String id);

  /// Status line on a draft bill
  ///
  /// In en, this message translates to:
  /// **'Draft — nothing has come off the shelf'**
  String get draftNothingOffShelf;

  /// Status of a finished bill
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// Status of a cancelled bill
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// Status chip on a bill
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftStatus;

  /// Short status chip on a bill
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneStatus;

  /// Section heading on a bill
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// Section heading: the totals
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get bill;

  /// Bill row before discount
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get gross;

  /// Bill row
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// Bill row
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Bill row
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// Bill row
  ///
  /// In en, this message translates to:
  /// **'From the wallet'**
  String get fromTheWallet;

  /// Bill row
  ///
  /// In en, this message translates to:
  /// **'Customer owes'**
  String get customerOwes;

  /// Bill row
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// Value where a financier pays the rest
  ///
  /// In en, this message translates to:
  /// **'nothing — financed through {method}'**
  String nothingFinancedThrough(String method);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Finish this bill'**
  String get finishThisBill;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Collect ₹{amount}'**
  String collectAmount(Object amount);

  /// Button and dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel this bill'**
  String get cancelThisBill;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Print invoice'**
  String get printInvoice;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Invoice {number} queued to print'**
  String invoiceQueued(String number);

  /// Snack bar after a part payment
  ///
  /// In en, this message translates to:
  /// **'Collected ₹{amount} — ₹{remaining} still owed'**
  String collectedStillOwed(String amount, String remaining);

  /// Snack bar after the final payment
  ///
  /// In en, this message translates to:
  /// **'Collected ₹{amount} — settled'**
  String collectedSettled(String amount);

  /// Snack bar after cancelling a completed bill
  ///
  /// In en, this message translates to:
  /// **'Cancelled — the handsets are back on the shelf'**
  String get cancelledHandsetsBack;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Draft cancelled'**
  String get draftCancelled;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Collect from the customer'**
  String get collectFromCustomer;

  /// Helper in the collect dialog
  ///
  /// In en, this message translates to:
  /// **'₹{owed} owed — part payments are fine'**
  String owedPartPaymentsFine(String owed);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collect;

  /// In the cancel dialog for a completed bill
  ///
  /// In en, this message translates to:
  /// **'Any handsets on this bill go back on the shelf. The bill itself is kept, marked cancelled.'**
  String get handsetsGoBack;

  /// In the cancel dialog for a draft
  ///
  /// In en, this message translates to:
  /// **'Nothing has come off the shelf, so there is nothing to put back.'**
  String get nothingToPutBack;

  /// Field label asking for a reason
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get why;

  /// Helper under a reason field
  ///
  /// In en, this message translates to:
  /// **'Goes on the record'**
  String get goesOnTheRecord;

  /// Button that cancels a cancellation
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// Snack bar after saving a draft bill
  ///
  /// In en, this message translates to:
  /// **'Kept as a draft — nothing has come off the shelf'**
  String get keptAsDraft;

  /// Form sheet title
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get newSaleTitle;

  /// Form sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit bill'**
  String get editBill;

  /// Tooltip on the X of the bill sheet
  ///
  /// In en, this message translates to:
  /// **'Close without saving'**
  String get closeWithoutSaving;

  /// Button on the bill
  ///
  /// In en, this message translates to:
  /// **'Add from stock'**
  String get addFromStock;

  /// Button: a free-text bill line
  ///
  /// In en, this message translates to:
  /// **'Add a line'**
  String get addALine;

  /// Payment method field
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Paid at the counter'**
  String get paidAtTheCounter;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Also from the wallet'**
  String get ofWhichFromWallet;

  /// Helper under the wallet field
  ///
  /// In en, this message translates to:
  /// **'Wallet holds ₹{balance} — covers ₹{covers} of this bill'**
  String walletCovers(String balance, String covers);

  /// Form section
  ///
  /// In en, this message translates to:
  /// **'Bill summary'**
  String get billSummary;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Keep as draft'**
  String get keepAsDraft;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Complete sale'**
  String get completeSale;

  /// When a phone number matches no customer
  ///
  /// In en, this message translates to:
  /// **'Nobody in the book on that number — the bill will carry the number typed here.'**
  String get nobodyOnThatNumberBill;

  /// Heading in the stock picker
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// Empty stock picker
  ///
  /// In en, this message translates to:
  /// **'Nothing sellable in second-hand stock.'**
  String get nothingSellable;

  /// Heading over handsets on the bench or sold
  ///
  /// In en, this message translates to:
  /// **'Not sellable'**
  String get notSellable;

  /// Sale list: the read failed
  ///
  /// In en, this message translates to:
  /// **'Sales could not be loaded'**
  String get salesCouldNotBeLoaded;

  /// Search box in the sale list
  ///
  /// In en, this message translates to:
  /// **'Invoice, customer, item or IMEI'**
  String get searchSales;

  /// Tab in the sale list
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// Tab in a list
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Banner over the sale list
  ///
  /// In en, this message translates to:
  /// **'₹{amount} owed by customers'**
  String owedByCustomersShort(String amount);

  /// Empty sale list
  ///
  /// In en, this message translates to:
  /// **'No bills here yet'**
  String get noBillsHereYet;

  /// Subtitle on a financed bill
  ///
  /// In en, this message translates to:
  /// **'₹{total} · financed, customer owes nothing'**
  String financedOwesNothing(String total);

  /// Subtitle on an unpaid bill
  ///
  /// In en, this message translates to:
  /// **'₹{total} · ₹{balance} still owed'**
  String totalStillOwed(String total, String balance);

  /// Subtitle on a settled bill
  ///
  /// In en, this message translates to:
  /// **'₹{total} · paid'**
  String totalPaid(String total);

  /// Snack bar after saving a draft bill
  ///
  /// In en, this message translates to:
  /// **'Kept as a draft — nothing has come off the shelf ({count, plural, =1{1 item} other{{count} items}})'**
  String keptAsDraftItems(int count);

  /// Added to the completed-bill snack bar
  ///
  /// In en, this message translates to:
  /// **', ₹{balance} still owed'**
  String billStillOwed(String balance);

  /// Button on the bill that adds a product line
  ///
  /// In en, this message translates to:
  /// **'Add a product'**
  String get addAProductLine;

  /// Form section on the bill
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// The enquiry record is gone
  ///
  /// In en, this message translates to:
  /// **'No enquiry {id}'**
  String noEnquiry(String id);

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Who asked'**
  String get whoAsked;

  /// Who recorded the enquiry
  ///
  /// In en, this message translates to:
  /// **'Taken by'**
  String get takenBy;

  /// Section heading and field label
  ///
  /// In en, this message translates to:
  /// **'What they asked'**
  String get whatTheyAsked;

  /// Field label: the subject of an enquiry
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'In their words'**
  String get inTheirWords;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Their budget'**
  String get theirBudget;

  /// Value where no budget was given
  ///
  /// In en, this message translates to:
  /// **'they did not say'**
  String get theyDidNotSay;

  /// Money row
  ///
  /// In en, this message translates to:
  /// **'Quoted'**
  String get quoted;

  /// Value where nothing was quoted
  ///
  /// In en, this message translates to:
  /// **'not quoted'**
  String get notQuoted;

  /// Warning when a quote is over budget
  ///
  /// In en, this message translates to:
  /// **'Quoted ₹{quoted} against a ₹{budget} budget.'**
  String quotedAgainstBudget(String quoted, String budget);

  /// Section heading
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get followUp;

  /// Date row
  ///
  /// In en, this message translates to:
  /// **'Asked on'**
  String get askedOn;

  /// Date row
  ///
  /// In en, this message translates to:
  /// **'Ring back'**
  String get ringBack;

  /// Date row
  ///
  /// In en, this message translates to:
  /// **'Dealt with'**
  String get dealtWith;

  /// The sale or repair an enquiry turned into
  ///
  /// In en, this message translates to:
  /// **'What it became'**
  String get whatItBecame;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Set a follow-up'**
  String get setAFollowUp;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Change the follow-up'**
  String get changeTheFollowUp;

  /// Snack bar after setting a follow-up
  ///
  /// In en, this message translates to:
  /// **'Ring back on {date}'**
  String ringBackOn(String date);

  /// Snack bar after saving an enquiry
  ///
  /// In en, this message translates to:
  /// **'Saved: {what}'**
  String savedColon(String what);

  /// Form sheet title
  ///
  /// In en, this message translates to:
  /// **'Record an enquiry'**
  String get recordAnEnquiry;

  /// Form sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit enquiry'**
  String get editEnquiry;

  /// Helper under the phone field
  ///
  /// In en, this message translates to:
  /// **'The point of recording this is ringing them back'**
  String get pointIsRingingBack;

  /// Helper under the name field
  ///
  /// In en, this message translates to:
  /// **'Optional — a number on its own is enough'**
  String get nameOptionalEnough;

  /// Helper under the question field
  ///
  /// In en, this message translates to:
  /// **'In their words where you can — this is what makes the record worth keeping'**
  String get inTheirWordsHelp;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Brand, if they named one'**
  String get brandIfNamed;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Model, if they named one'**
  String get modelIfNamed;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'What they said they would spend'**
  String get whatTheyWouldSpend;

  /// Helper under the budget field
  ///
  /// In en, this message translates to:
  /// **'Leave empty if they did not say'**
  String get leaveEmptyIfNotSaid;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'What they were quoted'**
  String get whatTheyWereQuoted;

  /// Date field on the enquiry form
  ///
  /// In en, this message translates to:
  /// **'Ring them back on'**
  String get ringThemBackOn;

  /// Under an empty follow-up date
  ///
  /// In en, this message translates to:
  /// **'Not set — this will not come up again on its own'**
  String get notSetWillNotComeUp;

  /// Tooltip on the clear-date button
  ///
  /// In en, this message translates to:
  /// **'No follow-up needed'**
  String get noFollowUpNeeded;

  /// Enquiry list: the read failed
  ///
  /// In en, this message translates to:
  /// **'Enquiries could not be loaded'**
  String get enquiriesCouldNotLoad;

  /// Search box in the enquiry list
  ///
  /// In en, this message translates to:
  /// **'Customer, number, device or what they asked'**
  String get searchEnquiries;

  /// Button that records an enquiry
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// Subtitle on an enquiry row
  ///
  /// In en, this message translates to:
  /// **'No follow-up set'**
  String get noFollowUpSet;

  /// Subtitle on an enquiry row
  ///
  /// In en, this message translates to:
  /// **'Ring back {when}'**
  String ringBackNamed(String when);

  /// Note on the scanner screen
  ///
  /// In en, this message translates to:
  /// **'Camera scanning is not wired up yet. Type or paste the number — the same rules apply either way.'**
  String get cameraNotWired;

  /// Field label on the scanner
  ///
  /// In en, this message translates to:
  /// **'Label number or IMEI'**
  String get labelNumberOrImei;

  /// Helper under the scanner field
  ///
  /// In en, this message translates to:
  /// **'A shop label is five digits; an IMEI is fourteen to sixteen'**
  String get labelIsFiveDigits;

  /// Button on the scanner
  ///
  /// In en, this message translates to:
  /// **'Look it up'**
  String get lookItUp;

  /// Scan result
  ///
  /// In en, this message translates to:
  /// **'Label {number} is not in the registry'**
  String labelNotInRegistry(String number);

  /// Scan result detail
  ///
  /// In en, this message translates to:
  /// **'Nothing has been printed under that number. Check the number on the sticker, or look it up in the registry.'**
  String get nothingPrintedUnder;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Open the registry'**
  String get openTheRegistry;

  /// Scan result
  ///
  /// In en, this message translates to:
  /// **'Not a number this shop uses'**
  String get notANumberShopUses;

  /// Scan result detail
  ///
  /// In en, this message translates to:
  /// **'Nothing was scanned.'**
  String get nothingWasScanned;

  /// Scan result detail
  ///
  /// In en, this message translates to:
  /// **'Scanned \"{raw}\". Shop labels are five digits and an IMEI is fourteen to sixteen — this is neither, so it is probably a barcode off a retail box.'**
  String scannedNeither(String raw);

  /// Where a label snapshot has no title
  ///
  /// In en, this message translates to:
  /// **'No title on the label'**
  String get noTitleOnLabel;

  /// When a label is out of date
  ///
  /// In en, this message translates to:
  /// **'Changed since this sticker was printed — the values above are the current ones.'**
  String get changedSincePrinted;

  /// Unreadable label kind
  ///
  /// In en, this message translates to:
  /// **'This label was printed by a version of the app this one does not understand, so there is nowhere to open. What is shown above is what was printed.'**
  String get printedByNewerBuild;

  /// The record was deleted
  ///
  /// In en, this message translates to:
  /// **'The record behind this label is gone. What is shown above is what was printed on it.'**
  String get recordBehindLabelGone;

  /// TAC lookup found nothing
  ///
  /// In en, this message translates to:
  /// **'Not in the device table — the brand and model will need typing in.'**
  String get notInDeviceTable;

  /// TAC lookup result
  ///
  /// In en, this message translates to:
  /// **'Looks like a {device}. The form opens with that filled in, and stays editable.'**
  String looksLikeDevice(String device);

  /// Scanning an IMEI in label mode
  ///
  /// In en, this message translates to:
  /// **'That is a factory IMEI, not a shop label — length alone tells them apart.'**
  String get factoryImeiNotLabel;

  /// Label registry: the read failed
  ///
  /// In en, this message translates to:
  /// **'The label registry could not be loaded'**
  String get registryCouldNotLoad;

  /// Heading on the registry
  ///
  /// In en, this message translates to:
  /// **'Next label: {number}'**
  String nextLabel(String number);

  /// Explains the label counter
  ///
  /// In en, this message translates to:
  /// **'Numbers come off one counter for the whole shop, so two people assigning at the same moment cannot get the same one. Labels start at 26001.'**
  String get oneCounterExplainer;

  /// Search box in the registry
  ///
  /// In en, this message translates to:
  /// **'Label number, record or what was printed'**
  String get searchLabels;

  /// Empty registry
  ///
  /// In en, this message translates to:
  /// **'Nothing printed yet. A label is assigned from a record — open a handset or a repair and print one there.'**
  String get nothingPrintedYet;

  /// Registry search found nothing
  ///
  /// In en, this message translates to:
  /// **'No label matching \"{query}\"'**
  String noLabelMatching(String query);

  /// A label whose kind this build does not know
  ///
  /// In en, this message translates to:
  /// **'Unreadable kind'**
  String get unreadableKind;

  /// How many times a label was reprinted
  ///
  /// In en, this message translates to:
  /// **'reprinted {count}×'**
  String reprintedTimes(String count);

  /// Which fields changed since printing
  ///
  /// In en, this message translates to:
  /// **'Sticker out of date: {fields}'**
  String stickerOutOfDate(String fields);

  /// On a registry row whose record was deleted
  ///
  /// In en, this message translates to:
  /// **'Record gone — showing what was printed'**
  String get recordGoneShowingPrinted;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Print this label again'**
  String get printThisLabelAgain;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Open the record'**
  String get openTheRecord;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Label {number} sent to the printer'**
  String labelSentToPrinter(String number);

  /// Public scan page, unknown label
  ///
  /// In en, this message translates to:
  /// **'Nothing is registered under that number. If this is a sticker from the shop, quote the number at the counter.'**
  String get nothingRegisteredUnder;

  /// Row on the public scan page
  ///
  /// In en, this message translates to:
  /// **'What this is'**
  String get whatThisIs;

  /// Row on the public scan page
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Public scan page
  ///
  /// In en, this message translates to:
  /// **'Some details have changed since this label was printed. What is shown here is current.'**
  String get someDetailsChanged;

  /// Public scan page
  ///
  /// In en, this message translates to:
  /// **'Shown as currently recorded by the shop.'**
  String get shownAsRecorded;

  /// Public scan page
  ///
  /// In en, this message translates to:
  /// **'This is what was printed on the label. Please ask at the counter for anything more.'**
  String get askAtTheCounter;

  /// Enquiry conversion line
  ///
  /// In en, this message translates to:
  /// **'{open} open · nothing closed yet'**
  String openNothingClosed(String open);

  /// Enquiry conversion line
  ///
  /// In en, this message translates to:
  /// **'{open} open · {won} of {closed} closed became business ({rate}%)'**
  String openWonOfClosed(String open, String won, String closed, String rate);

  /// Stale label on the scanner
  ///
  /// In en, this message translates to:
  /// **'Changed since this sticker was printed: {fields}. The values above are the current ones.'**
  String changedSinceStickerFields(String fields);

  /// Scanning an IMEI in label mode
  ///
  /// In en, this message translates to:
  /// **'That is a factory IMEI, not a shop label — length alone tells them apart. Did you mean to start an intake?'**
  String get factoryImeiIntake;

  /// Warning over a report with unreadable areas
  ///
  /// In en, this message translates to:
  /// **'These figures are short: {areas} could not be read. Do not file this report.'**
  String figuresAreShort(String areas);

  /// Reports section heading
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// Activity row
  ///
  /// In en, this message translates to:
  /// **'Bills completed'**
  String get billsCompleted;

  /// Activity row
  ///
  /// In en, this message translates to:
  /// **'Bills cancelled'**
  String get billsCancelled;

  /// Activity row
  ///
  /// In en, this message translates to:
  /// **'Jobs taken in'**
  String get jobsTakenIn;

  /// Activity row
  ///
  /// In en, this message translates to:
  /// **'Jobs completed'**
  String get jobsCompleted;

  /// Activity row
  ///
  /// In en, this message translates to:
  /// **'Handsets bought'**
  String get handsetsBought;

  /// Activity row
  ///
  /// In en, this message translates to:
  /// **'Handsets sold'**
  String get handsetsSold;

  /// Activity row
  ///
  /// In en, this message translates to:
  /// **'Customers added'**
  String get customersAdded;

  /// Reports card heading
  ///
  /// In en, this message translates to:
  /// **'How the handset margin is made up'**
  String get howMarginMadeUp;

  /// Reports card line
  ///
  /// In en, this message translates to:
  /// **'Sold for ₹{amount}'**
  String soldForAmount(String amount);

  /// Reports card line
  ///
  /// In en, this message translates to:
  /// **'Cost ₹{amount} — purchase, repairs and anything else spent'**
  String costPurchaseRepairs(String amount);

  /// Empty report
  ///
  /// In en, this message translates to:
  /// **'Nothing happened in this period.'**
  String get nothingHappened;

  /// Under a report figure
  ///
  /// In en, this message translates to:
  /// **'from {count, plural, =1{1 record} other{{count} records}}'**
  String fromRecords(int count);

  /// Named in the unreadable-areas warning
  ///
  /// In en, this message translates to:
  /// **'sales'**
  String get areaSales;

  /// Named in the unreadable-areas warning
  ///
  /// In en, this message translates to:
  /// **'service orders'**
  String get areaServiceOrders;

  /// Named in the unreadable-areas warning
  ///
  /// In en, this message translates to:
  /// **'second-hand stock'**
  String get areaSecondHandStock;

  /// Named in the unreadable-areas warning
  ///
  /// In en, this message translates to:
  /// **'customers'**
  String get areaCustomers;

  /// Staff page without Firebase
  ///
  /// In en, this message translates to:
  /// **'Staff cannot be managed while the app is offline — this page reads and writes the shop itself.'**
  String get staffOffline;

  /// Heading on the staff page
  ///
  /// In en, this message translates to:
  /// **'{count} working here'**
  String workingHere(String count);

  /// Staff page section
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get invited;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// Empty invite list
  ///
  /// In en, this message translates to:
  /// **'Nobody is waiting to join'**
  String get nobodyWaitingToJoin;

  /// Subtitle of a pending invite
  ///
  /// In en, this message translates to:
  /// **'{role} · waiting for them to tap \"Create account\" with this email'**
  String claimedOnFirstSignIn(String role);

  /// Tooltip on an invite
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Invite somebody'**
  String get inviteSomebody;

  /// Helper under the invite email
  ///
  /// In en, this message translates to:
  /// **'They claim it the first time they sign in'**
  String get claimFirstSignIn;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Saved. No email is sent: ask them to install the app and tap \"Create account\" with {email} and a password of their own.'**
  String inviteSentTo(String email);

  /// A shop role
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// A shop role
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// Badge on the shop's owner
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// Badge on your own row
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Menu item that changes somebody's role
  ///
  /// In en, this message translates to:
  /// **'Make {role}'**
  String makeRole(String role);

  /// Menu item
  ///
  /// In en, this message translates to:
  /// **'Remove from shop'**
  String get removeFromShop;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Role changed'**
  String get roleChanged;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeNamed(String name);

  /// Confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'They lose access to this shop straight away. Their work stays on the records they made.'**
  String get loseAccessNow;

  /// Button that cancels a removal
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get removed;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// On the create-shop page
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// Explains tenant isolation on shop setup
  ///
  /// In en, this message translates to:
  /// **'Everything this app records — stock, customers, sales, repairs — belongs to your shop and is visible only to you and the staff you add.'**
  String get everythingBelongsToShop;

  /// Helper under the shop name
  ///
  /// In en, this message translates to:
  /// **'Goes on every bill and job card'**
  String get goesOnEveryBill;

  /// Helper under GSTIN
  ///
  /// In en, this message translates to:
  /// **'Optional — printed on invoices if you have one'**
  String get gstinOptional;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Create the shop'**
  String get createTheShop;

  /// Under the create-shop button
  ///
  /// In en, this message translates to:
  /// **'You can change any of this later in Settings, and add staff by their email address.'**
  String get changeLaterInSettings;

  /// Settings: the read failed
  ///
  /// In en, this message translates to:
  /// **'Settings could not be loaded'**
  String get settingsCouldNotLoad;

  /// Settings heading
  ///
  /// In en, this message translates to:
  /// **'These lists grow by themselves'**
  String get listsGrowThemselves;

  /// Explains self-growing option lists
  ///
  /// In en, this message translates to:
  /// **'A value typed into a form that is not on a list joins it, so the next person finds it in the dropdown. This page is for tidying up — removing what the shop no longer uses, or fixing something that got in.'**
  String get listsGrowExplainer;

  /// An empty option list
  ///
  /// In en, this message translates to:
  /// **'Empty. The next value typed into a form will start it off again.'**
  String get emptyWillStartAgain;

  /// Hint in the add-value field
  ///
  /// In en, this message translates to:
  /// **'Add to {list}'**
  String addToList(String list);

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Added \"{value}\"'**
  String addedValue(String value);

  /// Confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Remove \"{value}\"?'**
  String removeValue(String value);

  /// Confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'It stops being offered in forms. Records that already use it are not changed.'**
  String get stopsBeingOffered;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Removed \"{value}\"'**
  String removedValue(String value);

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'Models, by brand'**
  String get modelsByBrand;

  /// Empty brand list
  ///
  /// In en, this message translates to:
  /// **'No brands yet.'**
  String get noBrandsYet;

  /// Empty model list
  ///
  /// In en, this message translates to:
  /// **'None yet. The next model typed in under this brand will land here.'**
  String get noModelsUnderBrand;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Removed \"{model}\" from {brand}'**
  String removedModelFrom(String model, String brand);

  /// Hint in the add-model field
  ///
  /// In en, this message translates to:
  /// **'Add a model under {brand}'**
  String addModelUnder(String brand);

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Added \"{value}\" under {brand}'**
  String addedUnderBrand(String value, String brand);

  /// Settings section hint
  ///
  /// In en, this message translates to:
  /// **'Every item has to be ticked before a repair can be handed back. The order is the order somebody works through the phone.'**
  String get checklistHint;

  /// Empty checklist warning
  ///
  /// In en, this message translates to:
  /// **'Empty, so there is nothing to verify and any repair can be handed back.'**
  String get checklistEmpty;

  /// Drawer header when nobody is signed in
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get signedOut;

  /// Router error page title
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// Router error page
  ///
  /// In en, this message translates to:
  /// **'No screen for {uri}'**
  String noScreenFor(String uri);

  /// App bar on the public scan page
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelTitle;

  /// Settings section hint
  ///
  /// In en, this message translates to:
  /// **'Offered on an intake once a brand is chosen — only that brand\'s models.'**
  String get modelsOfferedHint;

  /// How many models a brand has
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 model} other{{count} models}}'**
  String modelCount(int count);

  /// Empty checklist warning
  ///
  /// In en, this message translates to:
  /// **'Empty, so there is nothing to verify and any repair can be handed back once it has been charged.'**
  String get checklistEmptyCharged;

  /// Snack bar when a value is a duplicate
  ///
  /// In en, this message translates to:
  /// **'\"{value}\" is already on the list'**
  String alreadyOnTheList(String value);

  /// Snack bar when a model is a duplicate
  ///
  /// In en, this message translates to:
  /// **'\"{value}\" is already under {brand}'**
  String alreadyUnderBrand(String value, String brand);

  /// A handset that can be sold
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get stateInStock;

  /// A handset on the bench
  ///
  /// In en, this message translates to:
  /// **'Being repaired'**
  String get stateBeingRepaired;

  /// A handset that has gone out
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get stateSold;

  /// Stock tab
  ///
  /// In en, this message translates to:
  /// **'Repairing'**
  String get tabRepairing;

  /// Product tab: low or out of stock
  ///
  /// In en, this message translates to:
  /// **'To order'**
  String get tabToOrder;

  /// Product tab and stock level
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get tabOutOfStock;

  /// Stock level
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get levelLow;

  /// Service and enquiry tab
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get tabOpen;

  /// Service tab
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get tabDueToday;

  /// Service tab
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tabOverdue;

  /// Service status: just taken in
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get statusReceived;

  /// Service status
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// Service status
  ///
  /// In en, this message translates to:
  /// **'Parts Awaiting'**
  String get statusPartsAwaiting;

  /// Service status
  ///
  /// In en, this message translates to:
  /// **'Awaiting Customer Approval'**
  String get statusAwaitingApproval;

  /// Service status: handed back
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Service status: came back with a complaint
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get statusReturned;

  /// Enquiry tab
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get tabDueTodayLower;

  /// Enquiry tab: became business
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get tabWon;

  /// What a label is stuck to
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get kindProduct;

  /// What a label is stuck to
  ///
  /// In en, this message translates to:
  /// **'Second-hand handset'**
  String get kindSecondHand;

  /// What a label is stuck to
  ///
  /// In en, this message translates to:
  /// **'Service order'**
  String get kindServiceOrder;

  /// What a label is stuck to
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get kindSale;

  /// Settings list
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get optionBrands;

  /// Settings list
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get optionSuppliers;

  /// Settings list
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get optionColours;

  /// Settings list
  ///
  /// In en, this message translates to:
  /// **'Product categories'**
  String get optionCategories;

  /// Settings list
  ///
  /// In en, this message translates to:
  /// **'Complaint types'**
  String get optionComplaintTypes;

  /// Settings list
  ///
  /// In en, this message translates to:
  /// **'Accessories left with a device'**
  String get optionAccessories;

  /// Settings list
  ///
  /// In en, this message translates to:
  /// **'Lock types'**
  String get optionLockTypes;

  /// Button on a scan result
  ///
  /// In en, this message translates to:
  /// **'Open the {kind}'**
  String openTheKind(String kind);

  /// Field label while signing up
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Tooltip on a checklist item
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// Tooltip on a checklist item
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'Label printer'**
  String get labelPrinter;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Print server address'**
  String get printServerAddress;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddress;

  /// Field label for a quantity
  ///
  /// In en, this message translates to:
  /// **'How many'**
  String get howMany;

  /// Helper under a reason field
  ///
  /// In en, this message translates to:
  /// **'Required — it goes in the history'**
  String get requiredGoesInHistory;

  /// What the app thinks is on the shelf
  ///
  /// In en, this message translates to:
  /// **'Recorded: {count}'**
  String recordedCount(String count);

  /// Field label in a stock take
  ///
  /// In en, this message translates to:
  /// **'Counted on the shelf'**
  String get countedOnShelf;

  /// Helper in a stock take
  ///
  /// In en, this message translates to:
  /// **'The difference goes in the history'**
  String get differenceGoesInHistory;

  /// Button in a stock take
  ///
  /// In en, this message translates to:
  /// **'Correct it'**
  String get correctIt;

  /// Button in the cancel dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel the bill'**
  String get cancelTheBill;

  /// Heading in the product picker
  ///
  /// In en, this message translates to:
  /// **'On the shelf'**
  String get onTheShelf;

  /// Empty product picker
  ///
  /// In en, this message translates to:
  /// **'Nothing in new-goods stock.'**
  String get nothingInNewGoods;

  /// Subtitle of an out-of-stock product
  ///
  /// In en, this message translates to:
  /// **'None on the shelf'**
  String get noneOnTheShelf;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'What is being charged?'**
  String get whatIsBeingCharged;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Final price'**
  String get finalPrice;

  /// Helper under the final price
  ///
  /// In en, this message translates to:
  /// **'Zero is allowed — a goodwill repair is a decision'**
  String get zeroIsAllowed;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Returned without being repaired'**
  String get returnedWithoutRepair;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Return it'**
  String get returnIt;

  /// Section heading on an enquiry
  ///
  /// In en, this message translates to:
  /// **'What came of it'**
  String get whatCameOfIt;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'What did this become?'**
  String get whatDidThisBecome;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Sale, repair, or a note'**
  String get saleRepairOrNote;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Mark won'**
  String get markWon;

  /// Button on a scan result
  ///
  /// In en, this message translates to:
  /// **'Start a repair'**
  String get startARepair;

  /// Button on a scan result
  ///
  /// In en, this message translates to:
  /// **'Buy this handset'**
  String get buyThisHandset;

  /// Button on a purchase
  ///
  /// In en, this message translates to:
  /// **'Print declaration'**
  String get printDeclaration;

  /// Dialog title when marking a handset sold
  ///
  /// In en, this message translates to:
  /// **'What did it go out at?'**
  String get whatDidItGoOutAt;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Sold price'**
  String get soldPrice;

  /// Field label on a free-text bill line
  ///
  /// In en, this message translates to:
  /// **'What it is'**
  String get whatItIsLine;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Discount (₹)'**
  String get discountRupees;

  /// Button that completes a repair
  ///
  /// In en, this message translates to:
  /// **'Hand the phone back'**
  String get handThePhoneBack;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Returned unrepaired'**
  String get returnedUnrepaired;

  /// Snack bar after setting the final price
  ///
  /// In en, this message translates to:
  /// **'Charging ₹{amount}'**
  String chargingAmount(String amount);

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Returned to the customer'**
  String get returnedToCustomer;

  /// No description provided for @helpWhatIsThis.
  ///
  /// In en, this message translates to:
  /// **'What is this?'**
  String get helpWhatIsThis;

  /// No description provided for @helpGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get helpGotIt;

  /// No description provided for @fieldVariant.
  ///
  /// In en, this message translates to:
  /// **'Storage / RAM'**
  String get fieldVariant;

  /// No description provided for @fieldAskingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get fieldAskingPrice;

  /// No description provided for @fieldSellerName.
  ///
  /// In en, this message translates to:
  /// **'Seller\'s name'**
  String get fieldSellerName;

  /// No description provided for @fieldSellerPhone.
  ///
  /// In en, this message translates to:
  /// **'Seller\'s phone number'**
  String get fieldSellerPhone;

  /// No description provided for @checkWorks.
  ///
  /// In en, this message translates to:
  /// **'Works'**
  String get checkWorks;

  /// No description provided for @checklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Check each part'**
  String get checklistTitle;

  /// No description provided for @gradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gradeTitle;

  /// No description provided for @profitTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profit'**
  String get profitTitle;

  /// No description provided for @lossTitle.
  ///
  /// In en, this message translates to:
  /// **'You will lose'**
  String get lossTitle;

  /// No description provided for @helpStockTabsTitle.
  ///
  /// In en, this message translates to:
  /// **'What the colours mean'**
  String get helpStockTabsTitle;

  /// No description provided for @helpBrand.
  ///
  /// In en, this message translates to:
  /// **'The company that made the phone. Example: Samsung, Vivo, Apple. It is written on the back of the phone. Tap a name below to fill it quickly.'**
  String get helpBrand;

  /// No description provided for @helpModel.
  ///
  /// In en, this message translates to:
  /// **'The phone\'s model name. Example: Galaxy A54, Y21. Find it in Settings → About phone.'**
  String get helpModel;

  /// No description provided for @helpColour.
  ///
  /// In en, this message translates to:
  /// **'The colour of the phone\'s back. Example: Black, Blue. Helps find the right phone on the shelf.'**
  String get helpColour;

  /// No description provided for @helpImei.
  ///
  /// In en, this message translates to:
  /// **'A 15-digit number that belongs to this one phone only. Dial *#06# on the phone to see it. Copy it from the phone, not from the box — the box can belong to a different phone. Police use this number to trace stolen phones.'**
  String get helpImei;

  /// No description provided for @helpImei2.
  ///
  /// In en, this message translates to:
  /// **'Phones with two SIM slots have a second IMEI. *#06# shows both. Leave empty if there is only one.'**
  String get helpImei2;

  /// No description provided for @helpSerial.
  ///
  /// In en, this message translates to:
  /// **'The maker\'s serial number, found in Settings → About phone. Not needed for most phones — fill it if you have it.'**
  String get helpSerial;

  /// No description provided for @helpPaid.
  ///
  /// In en, this message translates to:
  /// **'The money you gave the person who sold you this phone. Example: 6000. Only numbers, no ₹ sign.'**
  String get helpPaid;

  /// No description provided for @helpOtherCost.
  ///
  /// In en, this message translates to:
  /// **'Any other money spent on this phone that is not a repair. Example: auto fare to collect it, cleaning, a new cover. Leave empty if none.'**
  String get helpOtherCost;

  /// No description provided for @helpAsking.
  ///
  /// In en, this message translates to:
  /// **'The price you want to sell this phone for. The green box below shows your profit straight away. If it turns red, you will lose money at this price.'**
  String get helpAsking;

  /// No description provided for @helpProfit.
  ///
  /// In en, this message translates to:
  /// **'Selling price minus everything spent: what you paid, repairs and other costs. Green means profit, red means loss.'**
  String get helpProfit;

  /// No description provided for @helpRepairs.
  ///
  /// In en, this message translates to:
  /// **'Work done to make this phone ready to sell, and what it cost. Example: new battery ₹800. It is added to the cost, so the profit stays correct.'**
  String get helpRepairs;

  /// No description provided for @helpBench.
  ///
  /// In en, this message translates to:
  /// **'Turn this on if the phone is still being repaired. It will not be shown as ready to sell until you turn it off.'**
  String get helpBench;

  /// No description provided for @helpGrade.
  ///
  /// In en, this message translates to:
  /// **'A letter for how good the phone is. A: everything works. B: 1 to 3 things not working. C: 4 or more not working, or the display was replaced or has white spots. D: damaged, bent or iCloud locked. The app works it out from the checks — tap a letter to choose it yourself.'**
  String get helpGrade;

  /// No description provided for @helpChecklist.
  ///
  /// In en, this message translates to:
  /// **'Everything starts as Working. Tap Not working only for what is broken. For questions like \"Display replaced\", tap Yes only if it is true.'**
  String get helpChecklist;

  /// No description provided for @helpPhotos.
  ///
  /// In en, this message translates to:
  /// **'Take photos of the phone. The first one must be the front. Photos prove what state the phone was in when you bought it.'**
  String get helpPhotos;

  /// No description provided for @helpSellerName.
  ///
  /// In en, this message translates to:
  /// **'Full name of the person who sold you this phone, as on their ID card.'**
  String get helpSellerName;

  /// No description provided for @helpSellerPhone.
  ///
  /// In en, this message translates to:
  /// **'The seller\'s 10-digit mobile number. Needed if the police ask about this phone later.'**
  String get helpSellerPhone;

  /// No description provided for @helpIdProof.
  ///
  /// In en, this message translates to:
  /// **'Which ID the seller showed, and its last 4 digits. Example: Aadhaar 4412. This protects the shop if the phone turns out to be stolen.'**
  String get helpIdProof;

  /// No description provided for @helpSigned.
  ///
  /// In en, this message translates to:
  /// **'Turn on after the seller has signed the paper saying the phone is theirs to sell. Needed to print the declaration.'**
  String get helpSigned;

  /// No description provided for @helpNotes.
  ///
  /// In en, this message translates to:
  /// **'Anything else worth remembering about this phone. Example: small scratch on the camera, comes with charger.'**
  String get helpNotes;

  /// No description provided for @helpSearchStock.
  ///
  /// In en, this message translates to:
  /// **'Type anything you know about the phone — brand, model, the IMEI number, the label number or the seller\'s name — and the list shows only matching phones.'**
  String get helpSearchStock;

  /// No description provided for @helpStockTabs.
  ///
  /// In en, this message translates to:
  /// **'Green = ready to sell. Orange = being repaired. Grey = already sold. Tap a box to see only those phones.'**
  String get helpStockTabs;

  /// No description provided for @chkFrontCamera.
  ///
  /// In en, this message translates to:
  /// **'Front Camera (Clear dust)'**
  String get chkFrontCamera;

  /// No description provided for @chkRearCamera.
  ///
  /// In en, this message translates to:
  /// **'Rear Camera (Clear dust)'**
  String get chkRearCamera;

  /// No description provided for @chkFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint Sensor'**
  String get chkFingerprint;

  /// No description provided for @chkBatteryHealth.
  ///
  /// In en, this message translates to:
  /// **'Battery Health %'**
  String get chkBatteryHealth;

  /// No description provided for @newToShopList.
  ///
  /// In en, this message translates to:
  /// **'New — it will be added to your shop\'s list when you save'**
  String get newToShopList;

  /// No description provided for @pickBrandFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose the brand first to see its models'**
  String get pickBrandFirst;

  /// Placeholder in an empty Device field, showing a real value from the shop's list
  ///
  /// In en, this message translates to:
  /// **'e.g. {example}'**
  String exampleHint(String example);

  /// No description provided for @wizStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String wizStepOf(String n, String total);

  /// No description provided for @wizPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get wizPhoto;

  /// No description provided for @wizPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get wizPhone;

  /// No description provided for @wizMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get wizMoney;

  /// No description provided for @wizPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the phone'**
  String get wizPhotoTitle;

  /// No description provided for @wizPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'The front of the phone, screen on, so anyone can see what it looks like.'**
  String get wizPhotoHint;

  /// No description provided for @wizPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Which phone is it?'**
  String get wizPhoneTitle;

  /// No description provided for @wizMoneyTitle.
  ///
  /// In en, this message translates to:
  /// **'How much money?'**
  String get wizMoneyTitle;

  /// No description provided for @wizSellerTitle.
  ///
  /// In en, this message translates to:
  /// **'Who sold it to you?'**
  String get wizSellerTitle;

  /// No description provided for @wizNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get wizNext;

  /// No description provided for @wizBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wizBack;

  /// No description provided for @wizMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Add more details (optional)'**
  String get wizMoreDetails;

  /// No description provided for @wizHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide extra details'**
  String get wizHideDetails;

  /// No description provided for @optionRam.
  ///
  /// In en, this message translates to:
  /// **'RAM'**
  String get optionRam;

  /// No description provided for @optionExpenseKinds.
  ///
  /// In en, this message translates to:
  /// **'Expense types'**
  String get optionExpenseKinds;

  /// No description provided for @optionRom.
  ///
  /// In en, this message translates to:
  /// **'Storage (ROM)'**
  String get optionRom;

  /// No description provided for @chkDisplayClarity.
  ///
  /// In en, this message translates to:
  /// **'Display Clarity'**
  String get chkDisplayClarity;

  /// No description provided for @chkWhiteSpots.
  ///
  /// In en, this message translates to:
  /// **'White Spots on Display'**
  String get chkWhiteSpots;

  /// No description provided for @chkDisplayReplaced.
  ///
  /// In en, this message translates to:
  /// **'Display Replaced'**
  String get chkDisplayReplaced;

  /// No description provided for @chkPhysicalDamage.
  ///
  /// In en, this message translates to:
  /// **'Physical Damage / Bent'**
  String get chkPhysicalDamage;

  /// No description provided for @chkFaceTouchId.
  ///
  /// In en, this message translates to:
  /// **'Face ID / Touch ID'**
  String get chkFaceTouchId;

  /// No description provided for @chkIcloudLock.
  ///
  /// In en, this message translates to:
  /// **'iCloud Lock Check'**
  String get chkIcloudLock;

  /// No description provided for @chkTrueTone.
  ///
  /// In en, this message translates to:
  /// **'True Tone Display'**
  String get chkTrueTone;

  /// No description provided for @chkEarpiece.
  ///
  /// In en, this message translates to:
  /// **'Earpiece Speaker'**
  String get chkEarpiece;

  /// No description provided for @chkLoudspeaker.
  ///
  /// In en, this message translates to:
  /// **'Loudspeaker'**
  String get chkLoudspeaker;

  /// No description provided for @chkMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get chkMicrophone;

  /// No description provided for @chkMobileData.
  ///
  /// In en, this message translates to:
  /// **'Mobile Data'**
  String get chkMobileData;

  /// No description provided for @chkBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get chkBluetooth;

  /// No description provided for @chkWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get chkWifi;

  /// No description provided for @chkPowerButton.
  ///
  /// In en, this message translates to:
  /// **'Power Button'**
  String get chkPowerButton;

  /// No description provided for @chkVolumeButtons.
  ///
  /// In en, this message translates to:
  /// **'Volume Buttons'**
  String get chkVolumeButtons;

  /// No description provided for @chkMuteSwitch.
  ///
  /// In en, this message translates to:
  /// **'Mute Switch'**
  String get chkMuteSwitch;

  /// No description provided for @chkLightningPort.
  ///
  /// In en, this message translates to:
  /// **'Lightning / USB-C Port'**
  String get chkLightningPort;

  /// No description provided for @chkSimSlot.
  ///
  /// In en, this message translates to:
  /// **'SIM Slot'**
  String get chkSimSlot;

  /// No description provided for @chkFlashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get chkFlashlight;

  /// No description provided for @chkFaceUnlock.
  ///
  /// In en, this message translates to:
  /// **'Face Unlock'**
  String get chkFaceUnlock;

  /// No description provided for @chkChargingPort.
  ///
  /// In en, this message translates to:
  /// **'Charging Port'**
  String get chkChargingPort;

  /// No description provided for @chkSimSlot1.
  ///
  /// In en, this message translates to:
  /// **'SIM Slot 1'**
  String get chkSimSlot1;

  /// No description provided for @chkSimSlot2.
  ///
  /// In en, this message translates to:
  /// **'SIM Slot 2'**
  String get chkSimSlot2;

  /// No description provided for @chkSdCardSlot.
  ///
  /// In en, this message translates to:
  /// **'SD Card Slot'**
  String get chkSdCardSlot;

  /// No description provided for @chkProximitySensor.
  ///
  /// In en, this message translates to:
  /// **'Proximity Sensor'**
  String get chkProximitySensor;

  /// No description provided for @catDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get catDisplay;

  /// No description provided for @catPhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get catPhysical;

  /// No description provided for @catSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get catSecurity;

  /// No description provided for @catBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get catBattery;

  /// No description provided for @catCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get catCamera;

  /// No description provided for @catAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get catAudio;

  /// No description provided for @catConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity'**
  String get catConnectivity;

  /// No description provided for @catSim.
  ///
  /// In en, this message translates to:
  /// **'SIM & card slots'**
  String get catSim;

  /// No description provided for @checkNotWorking.
  ///
  /// In en, this message translates to:
  /// **'Not working'**
  String get checkNotWorking;

  /// No description provided for @answerYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get answerYes;

  /// No description provided for @answerNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get answerNo;

  /// No description provided for @checksCommon.
  ///
  /// In en, this message translates to:
  /// **'Checks for every phone'**
  String get checksCommon;

  /// No description provided for @checksIphone.
  ///
  /// In en, this message translates to:
  /// **'iPhone checks'**
  String get checksIphone;

  /// No description provided for @checksAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android checks'**
  String get checksAndroid;

  /// No description provided for @gradeAuto.
  ///
  /// In en, this message translates to:
  /// **'Worked out from the checks'**
  String get gradeAuto;

  /// No description provided for @gradeManual.
  ///
  /// In en, this message translates to:
  /// **'Chosen by hand'**
  String get gradeManual;

  /// No description provided for @faultsFound.
  ///
  /// In en, this message translates to:
  /// **'Faults: {list}'**
  String faultsFound(String list);

  /// No description provided for @noFaults.
  ///
  /// In en, this message translates to:
  /// **'No faults found'**
  String get noFaults;

  /// No description provided for @warrantyExpiry.
  ///
  /// In en, this message translates to:
  /// **'Warranty ends on'**
  String get warrantyExpiry;

  /// No description provided for @accessoriesIncluded.
  ///
  /// In en, this message translates to:
  /// **'Accessories included'**
  String get accessoriesIncluded;

  /// No description provided for @describeWear.
  ///
  /// In en, this message translates to:
  /// **'What wear does it have?'**
  String get describeWear;

  /// No description provided for @describeCondition.
  ///
  /// In en, this message translates to:
  /// **'Describe its condition'**
  String get describeCondition;

  /// No description provided for @describeDamage.
  ///
  /// In en, this message translates to:
  /// **'Describe the damage'**
  String get describeDamage;

  /// No description provided for @notesFeatures.
  ///
  /// In en, this message translates to:
  /// **'Special features / notes'**
  String get notesFeatures;

  /// No description provided for @purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get purchaseDate;

  /// No description provided for @fieldSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier (if not a walk-in)'**
  String get fieldSupplier;

  /// No description provided for @sellerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone'**
  String get sellerSearch;

  /// No description provided for @sellerCantFind.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find the seller?'**
  String get sellerCantFind;

  /// No description provided for @addNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add new customer'**
  String get addNewCustomer;

  /// No description provided for @saveAndSelect.
  ///
  /// In en, this message translates to:
  /// **'Save & select'**
  String get saveAndSelect;

  /// No description provided for @idTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'ID type'**
  String get idTypeLabel;

  /// No description provided for @idNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'ID number'**
  String get idNumberLabel;

  /// No description provided for @fieldAltPhone.
  ///
  /// In en, this message translates to:
  /// **'Another phone number (optional)'**
  String get fieldAltPhone;

  /// No description provided for @sellerPicked.
  ///
  /// In en, this message translates to:
  /// **'From your customers'**
  String get sellerPicked;

  /// No description provided for @changeSeller.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeSeller;

  /// No description provided for @photoSlotFront.
  ///
  /// In en, this message translates to:
  /// **'Front view'**
  String get photoSlotFront;

  /// No description provided for @photoSlotBack.
  ///
  /// In en, this message translates to:
  /// **'Back view'**
  String get photoSlotBack;

  /// No description provided for @photoSlotLeft.
  ///
  /// In en, this message translates to:
  /// **'Left side'**
  String get photoSlotLeft;

  /// No description provided for @photoSlotRight.
  ///
  /// In en, this message translates to:
  /// **'Right side'**
  String get photoSlotRight;

  /// No description provided for @photoSlotTopBottom.
  ///
  /// In en, this message translates to:
  /// **'Top / bottom'**
  String get photoSlotTopBottom;

  /// No description provided for @photoSlotExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get photoSlotExtra;

  /// No description provided for @idCardFront.
  ///
  /// In en, this message translates to:
  /// **'ID card — front'**
  String get idCardFront;

  /// No description provided for @idCardBack.
  ///
  /// In en, this message translates to:
  /// **'ID card — back'**
  String get idCardBack;

  /// No description provided for @idCardPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'ID card photos'**
  String get idCardPhotosTitle;

  /// No description provided for @tapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAddPhoto;

  /// No description provided for @wizCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get wizCondition;

  /// No description provided for @wizConditionTitle.
  ///
  /// In en, this message translates to:
  /// **'What condition is it in?'**
  String get wizConditionTitle;

  /// No description provided for @wizPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Take photos of the phone'**
  String get wizPhotosTitle;

  /// No description provided for @saveAndPrintLabel.
  ///
  /// In en, this message translates to:
  /// **'Save & print label'**
  String get saveAndPrintLabel;

  /// No description provided for @serialAppleHint.
  ///
  /// In en, this message translates to:
  /// **'Needed for an iPhone'**
  String get serialAppleHint;

  /// No description provided for @checklistNeedsBrand.
  ///
  /// In en, this message translates to:
  /// **'Choose the brand on the Phone step to see its checks.'**
  String get checklistNeedsBrand;

  /// No description provided for @labelPrinted.
  ///
  /// In en, this message translates to:
  /// **'Saved — label {number} sent to the printer'**
  String labelPrinted(String number);

  /// No description provided for @helpRam.
  ///
  /// In en, this message translates to:
  /// **'How much RAM the phone has. Find it in Settings → About phone. Example: 6GB.'**
  String get helpRam;

  /// No description provided for @helpRom.
  ///
  /// In en, this message translates to:
  /// **'How much storage the phone has. Find it in Settings → Storage. Example: 128GB. More storage sells for more.'**
  String get helpRom;

  /// No description provided for @helpPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'The day you bought this phone. Today is already filled in — change it only if you bought it on another day.'**
  String get helpPurchaseDate;

  /// No description provided for @helpSupplier.
  ///
  /// In en, this message translates to:
  /// **'Only if you bought it from a dealer or another shop. Leave it empty when a customer sold it to you.'**
  String get helpSupplier;

  /// No description provided for @helpSellerSearch.
  ///
  /// In en, this message translates to:
  /// **'Type the seller\'s name or phone number. If they have come to the shop before, they appear below — tap to fill everything in.'**
  String get helpSellerSearch;

  /// No description provided for @helpAltPhone.
  ///
  /// In en, this message translates to:
  /// **'A second number for the seller, in case the first one is switched off.'**
  String get helpAltPhone;

  /// No description provided for @helpIdType.
  ///
  /// In en, this message translates to:
  /// **'Which ID the seller showed you — Aadhaar, PAN, driving licence or voter ID.'**
  String get helpIdType;

  /// No description provided for @helpIdNumber.
  ///
  /// In en, this message translates to:
  /// **'The number printed on that ID card.'**
  String get helpIdNumber;

  /// No description provided for @helpIdCardPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos of the seller\'s ID card, front and back. They prove who sold the phone if the police ask later.'**
  String get helpIdCardPhotos;

  /// No description provided for @helpGradeDetails.
  ///
  /// In en, this message translates to:
  /// **'A few words about the phone\'s state, so the next person knows without checking again.'**
  String get helpGradeDetails;

  /// No description provided for @helpSerialApple.
  ///
  /// In en, this message translates to:
  /// **'The serial number from Settings → General → About. It is needed for every iPhone.'**
  String get helpSerialApple;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navMyTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get navMyTasks;

  /// No description provided for @tasksCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Tasks could not be loaded'**
  String get tasksCouldNotLoad;

  /// No description provided for @taskTabToDo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get taskTabToDo;

  /// No description provided for @taskTabDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskTabDone;

  /// No description provided for @taskFreqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get taskFreqDaily;

  /// No description provided for @taskFreqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get taskFreqWeekly;

  /// No description provided for @taskFreqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get taskFreqMonthly;

  /// No description provided for @taskFreqOnce.
  ///
  /// In en, this message translates to:
  /// **'One time'**
  String get taskFreqOnce;

  /// No description provided for @taskTabUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Nobody yet'**
  String get taskTabUnassigned;

  /// No description provided for @taskPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get taskPriorityLow;

  /// No description provided for @taskPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get taskPriorityMedium;

  /// No description provided for @taskPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get taskPriorityHigh;

  /// No description provided for @taskAdd.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get taskAdd;

  /// No description provided for @taskNew.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskNew;

  /// No description provided for @taskEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskEdit;

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What has to be done'**
  String get taskTitleLabel;

  /// No description provided for @taskDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get taskDescriptionLabel;

  /// No description provided for @taskAssignLabel.
  ///
  /// In en, this message translates to:
  /// **'Who does it'**
  String get taskAssignLabel;

  /// No description provided for @taskFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get taskFrequencyLabel;

  /// No description provided for @taskPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'How important'**
  String get taskPriorityLabel;

  /// No description provided for @taskDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Do it by'**
  String get taskDueLabel;

  /// No description provided for @taskPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a day'**
  String get taskPickDate;

  /// No description provided for @taskMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskMarkDone;

  /// No description provided for @taskUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get taskUndo;

  /// No description provided for @taskOverdue.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get taskOverdue;

  /// No description provided for @taskDueOn.
  ///
  /// In en, this message translates to:
  /// **'Do it by {date}'**
  String taskDueOn(String date);

  /// No description provided for @taskNobodySees.
  ///
  /// In en, this message translates to:
  /// **'Given to nobody — staff cannot see it yet'**
  String get taskNobodySees;

  /// No description provided for @taskAllStaff.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get taskAllStaff;

  /// No description provided for @taskDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get taskDelete;

  /// No description provided for @taskDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get taskDeleteConfirm;

  /// No description provided for @taskSaved.
  ///
  /// In en, this message translates to:
  /// **'Task saved'**
  String get taskSaved;

  /// No description provided for @taskNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks here'**
  String get taskNoTasks;

  /// No description provided for @taskBlockNoTitle.
  ///
  /// In en, this message translates to:
  /// **'Write what has to be done.'**
  String get taskBlockNoTitle;

  /// No description provided for @taskBlockNoDueDate.
  ///
  /// In en, this message translates to:
  /// **'Pick the day this has to be done by.'**
  String get taskBlockNoDueDate;

  /// No description provided for @taskBlockAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the shop owner can change tasks.'**
  String get taskBlockAdminOnly;

  /// No description provided for @taskBlockNotYours.
  ///
  /// In en, this message translates to:
  /// **'This task belongs to someone else.'**
  String get taskBlockNotYours;

  /// No description provided for @helpTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Write the job in a few plain words. Example: Clean the display cabinet.'**
  String get helpTaskTitle;

  /// No description provided for @helpTaskAssign.
  ///
  /// In en, this message translates to:
  /// **'The staff member who must do this job. Only that person sees it on their phone. If you choose nobody, no staff member will see it.'**
  String get helpTaskAssign;

  /// No description provided for @helpTaskFrequency.
  ///
  /// In en, this message translates to:
  /// **'How often the job comes back. Daily: every morning it must be done again. Weekly: once each week. Monthly: once each month. One time: do it once and it is finished.'**
  String get helpTaskFrequency;

  /// No description provided for @helpTaskPriority.
  ///
  /// In en, this message translates to:
  /// **'High jobs are shown first and in red. Use High only for jobs that cannot wait.'**
  String get helpTaskPriority;

  /// No description provided for @helpTaskDue.
  ///
  /// In en, this message translates to:
  /// **'The last day to finish this job. After this day it shows as Late.'**
  String get helpTaskDue;

  /// Second-hand summary card
  ///
  /// In en, this message translates to:
  /// **'{count} on hand'**
  String stockOnHand(String count);

  /// Second-hand summary card
  ///
  /// In en, this message translates to:
  /// **'Selling for ₹{amount}'**
  String stockSellingFor(String amount);

  /// Second-hand summary card
  ///
  /// In en, this message translates to:
  /// **'Paid ₹{amount}'**
  String stockPaidFor(String amount);

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Add \"{value}\" as a new customer'**
  String addAsNewCustomer(String value);

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Add \"{value}\" as a new brand'**
  String addAsNewBrand(String value);

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Add \"{value}\" as a new model'**
  String addAsNewModel(String value);

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Add \"{value}\" as a new RAM size'**
  String addAsNewRam(String value);

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Add \"{value}\" as a new storage size'**
  String addAsNewRom(String value);

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Add \"{value}\" as a new colour'**
  String addAsNewColour(String value);

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Add \"{value}\" as a new supplier'**
  String addAsNewSupplier(String value);

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get sellerSearchLabel;

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Type a name or phone number'**
  String get sellerSearchHint;

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get noMatchingRecord;

  /// Search-or-add fields on the forms
  ///
  /// In en, this message translates to:
  /// **'Could not add it to the shop\'s list: {error}'**
  String couldNotAddToList(String error);

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Seller\'s signature'**
  String get signatureLabel;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Sign again'**
  String get signatureClear;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Sign here with a finger'**
  String get signatureHint;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Signed already'**
  String get signatureOnRecord;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Scan the IMEI'**
  String get imeiScanTitle;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the IMEI barcode: on the box, under the battery, or on the phone\'s screen after dialling *#06#.'**
  String get imeiScanPoint;

  /// IMEI camera prompt on New repair, where the phone is in hand
  ///
  /// In en, this message translates to:
  /// **'Phone switches on? Dial *#06# and scan the barcode on its screen. If not, scan the IMEI sticker on the phone.'**
  String get imeiScanPointPhone;

  /// Under Model when the chosen brand has no models yet
  ///
  /// In en, this message translates to:
  /// **'No {brand} models saved yet. Type it once and it is offered here next time.'**
  String noModelsYet(String brand);

  /// Serial number barcode scanner
  ///
  /// In en, this message translates to:
  /// **'Scan the serial number'**
  String get serialScanTitle;

  /// Serial number barcode scanner
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the barcode next to \"Serial No.\" on the box or label.'**
  String get serialScanPoint;

  /// Serial number barcode scanner
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get serialScanAgain;

  /// Serial number barcode scanner
  ///
  /// In en, this message translates to:
  /// **'The camera cannot be used. Type the serial number instead.'**
  String get serialScanNoCamera;

  /// Shown over the screen while a save is going on
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingNow;

  /// Sign-in box left empty
  ///
  /// In en, this message translates to:
  /// **'Your email is needed'**
  String get emailNeeded;

  /// Sign-in box left empty
  ///
  /// In en, this message translates to:
  /// **'Your password is needed'**
  String get passwordNeeded;

  /// Shown over the screen while a label prints
  ///
  /// In en, this message translates to:
  /// **'Printing…'**
  String get printingNow;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting your data…'**
  String get loadingData;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Still working on it…'**
  String get loadingStill;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Almost there…'**
  String get loadingAlmost;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Slow internet? Hang on…'**
  String get loadingSlow;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting your repairs…'**
  String get loadingRepairs;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting your phones…'**
  String get loadingPhones;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting your bills…'**
  String get loadingBills;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting your customers…'**
  String get loadingCustomers;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting your products…'**
  String get loadingProducts;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting enquiries…'**
  String get loadingEnquiries;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting tasks…'**
  String get loadingTasks;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Opening it…'**
  String get loadingRecord;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting your staff…'**
  String get loadingStaff;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting ratings…'**
  String get loadingRatings;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get loadingSearch;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Looking for printers…'**
  String get loadingPrinters;

  /// Loading words while data comes
  ///
  /// In en, this message translates to:
  /// **'Getting older bills and jobs…'**
  String get loadingOlder;

  /// Camera text reading
  ///
  /// In en, this message translates to:
  /// **'No barcode? Read the numbers'**
  String get readNumbersButton;

  /// Camera text reading
  ///
  /// In en, this message translates to:
  /// **'Reading the numbers…'**
  String get readingNumbers;

  /// Camera text reading
  ///
  /// In en, this message translates to:
  /// **'No IMEI found in the photo. Hold the phone closer, keep it sharp, and try again, or type it.'**
  String get readNoImei;

  /// Camera text reading
  ///
  /// In en, this message translates to:
  /// **'No serial number found in the photo. Try again closer, or type it.'**
  String get readNoSerial;

  /// Text reading failed
  ///
  /// In en, this message translates to:
  /// **'The camera could not read it: {reason}'**
  String readFailed(String reason);

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Welcome to your shop app'**
  String get tourWelcomeTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'A one-minute look at each page and what it is for. Tap Next, or Skip any time. You can watch it again from Settings.'**
  String get tourWelcomeBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Find anything'**
  String get tourSearchTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Type a name, phone number, IMEI, job number or bill number. The scan button reads a label or an IMEI barcode.'**
  String get tourSearchBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Today\'s money'**
  String get tourTodayTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'What came in today from bills and repairs, split into cash, UPI and card.'**
  String get tourTodayBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get tourActionsTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'The four jobs of the counter: a new sale, a new repair, buying a phone, and noting an enquiry.'**
  String get tourActionsBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Repairs that need you'**
  String get tourQueueTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Late, due today and ready jobs. Tap one to see them; call or WhatsApp the customer from the card.'**
  String get tourQueueBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Move around'**
  String get tourNavTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Home, Mobiles, Repairs, Sales and More sit here on every page.'**
  String get tourNavBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Phones in stock'**
  String get tourStockTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'How many phones you hold, what they would sell for, and the profit in them.'**
  String get tourStockBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'In stock, on the bench, sold'**
  String get tourStockTabsTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Tap to switch. Each phone shows its price, profit and how many days it has waited.'**
  String get tourStockTabsBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Buying a phone'**
  String get tourBuyTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Five short steps: seller, phone, condition, money, photos. The price label prints at the end.'**
  String get tourBuyBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Every repair, by where it is'**
  String get tourRepairsTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Open, due today, overdue, ready. Open a job to change its status, charge it and hand it back.'**
  String get tourRepairsBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Taking in a repair'**
  String get tourNewRepairTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Phone number, brand, model and what is wrong. Save & print gives the customer their job card.'**
  String get tourNewRepairBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get tourBillsTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Completed bills, drafts and cancelled ones. A bill can be finished without internet; it completes itself when the connection is back.'**
  String get tourBillsBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'A new bill'**
  String get tourNewBillTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Add phones from stock, accessories or a typed line, take the payment, and share the bill.'**
  String get tourNewBillBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tourSettingsTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Your shop\'s lists, the label printer and the language. This tour is here too, under Help.'**
  String get tourSettingsBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'That\'s the tour'**
  String get tourDoneTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'The ? buttons next to boxes explain each one. Start with the button you need most.'**
  String get tourDoneBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tourBack;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tourDone;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get tourOfferTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Take a one-minute tour of the app: what each page is for and where to tap.'**
  String get tourOfferBody;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Show me around'**
  String get tourOfferStart;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get tourOfferLater;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get setGroupHelp;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'App tour'**
  String get settingsTour;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'See how each page works, step by step'**
  String get settingsTourSub;

  /// App tour step count
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String tourStepOf(int n, int total);

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Take in a repair'**
  String get tourChRepairTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Fill a job card, then follow the job until the phone goes back'**
  String get tourChRepairBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Repairs, by where they are'**
  String get tourRepair1T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Open, due today, overdue and ready. Tap a tab to see those jobs. Swipe a job right to call the customer, left to WhatsApp them.'**
  String get tourRepair1B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Taking one in'**
  String get tourRepair2T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'This starts a new repair. Watch: the tour fills one in with practice data.'**
  String get tourRepair2B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'The customer\'s number'**
  String get tourRepair3T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Type it first: someone who has been before is found, and a tap fills their name.'**
  String get tourRepair3B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tourRepair4T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Optional: the number alone is enough.'**
  String get tourRepair4B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get tourRepair5T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Tap it in the row under the box, or type a new one; it joins your list.'**
  String get tourRepair5B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get tourRepair6T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Once the brand is picked, its models appear in a row. Tap one.'**
  String get tourRepair6B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'IMEI'**
  String get tourRepair7T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Off the phone (dial *#06#), not the box. The camera button scans it.'**
  String get tourRepair7B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get tourRepair8T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'How it is locked, and the code, so the phone can be tested.'**
  String get tourRepair8B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'What is wrong'**
  String get tourRepair9T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Tap one or more; typing finds the rest. The job card and the bill are made from these.'**
  String get tourRepair9B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get tourRepair10T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'The price you told them. Advance and parts cost go just below.'**
  String get tourRepair10B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Promised date'**
  String get tourRepair11T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'When they get it back. Late jobs come up on Home.'**
  String get tourRepair11B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tourRepair12T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Save, or Save & print for their job card. A missing box turns red and the cursor goes to it.'**
  String get tourRepair12B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'A job\'s page'**
  String get tourRepair13T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Tap a status as the work moves. Mark ready offers to WhatsApp the customer.'**
  String get tourRepair13B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Before hand-over'**
  String get tourRepair15T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'How many checks are done. Tap it, or Hand the phone back, to open the hand-over page.'**
  String get tourRepair15B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'The hand-over'**
  String get tourRepair16T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Tick each check, confirm the price and how they paid, then one button hands it back. Miss something and it takes you to it.'**
  String get tourRepair16B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Charge, parts, hand back'**
  String get tourRepair14T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Set what is charged, use parts from stock, print, and hand the phone back after the checklist.'**
  String get tourRepair14B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Buy a phone'**
  String get tourChBuyTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Five steps from the seller to the price label'**
  String get tourChBuyBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Buying a phone'**
  String get tourBuy1T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Five short steps. Watch: the tour fills one in with practice data.'**
  String get tourBuy1B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'1 · Seller'**
  String get tourBuy2T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Search by name or number and tap them, or add someone new. Their ID goes under More details.'**
  String get tourBuy2B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'2 · Phone'**
  String get tourBuy3T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Brand, model, RAM and storage are a tap each in the rows.'**
  String get tourBuy3B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Picked'**
  String get tourBuy4T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Navy means chosen. A wrong tap is fixed with one more tap.'**
  String get tourBuy4B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'IMEI and serial'**
  String get tourBuy5T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Scan the box, or read the numbers off the screen with the camera. An iPhone needs its serial too.'**
  String get tourBuy5B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'3 · Condition'**
  String get tourBuy6T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Mark anything that does not work. The grade A to D works itself out; battery health goes here too.'**
  String get tourBuy6B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'4 · Money'**
  String get tourBuy7T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'What you paid and what it will sell for. The profit shows as you type.'**
  String get tourBuy7B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'5 · Photos'**
  String get tourBuy8T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Front and back photos, the seller\'s ID and signature. Save prints the price label.'**
  String get tourBuy8B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'A phone\'s page'**
  String get tourBuy9T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Sell it on a bill, send it to the bench for repair, or reprint its label.'**
  String get tourBuy9B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Make a bill'**
  String get tourChBillTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Who buys, what, how they paid, and the bill afterwards'**
  String get tourChBillBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get tourBill1T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Completed bills, drafts and cancelled ones.'**
  String get tourBill1B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Who is buying'**
  String get tourBill2T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Their number finds them; a new number joins your customers.'**
  String get tourBill2B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'What they buy'**
  String get tourBill3T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Add a phone from stock, an accessory, or type a line.'**
  String get tourBill3B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'How they paid'**
  String get tourBill4T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Cash, UPI or card: a tap.'**
  String get tourBill4B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Paid now'**
  String get tourBill5T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Leave it empty for the full amount. Anything less stays as a due payment.'**
  String get tourBill5B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Complete sale'**
  String get tourBill6T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Gives the invoice number and takes the phone out of stock. Keep as draft to finish later.'**
  String get tourBill6B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'A bill\'s page'**
  String get tourBill7T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Share or print the bill, take a part payment, or cancel it.'**
  String get tourBill7B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get tourChCustomersTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Everyone who bought, sold or left a phone'**
  String get tourChCustomersBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get tourCustomers1T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Search by name or number. A tap opens their page.'**
  String get tourCustomers1B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Adding someone'**
  String get tourCustomers2T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Their number is the one thing needed. ID and address are for when they sell you a phone.'**
  String get tourCustomers2B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'A customer\'s page'**
  String get tourCustomers3T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Call or WhatsApp them, their store credit, and every repair, bill and enquiry of theirs.'**
  String get tourCustomers3B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Products and stock'**
  String get tourChProductsTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Accessories and parts: what is on the shelf and what to order'**
  String get tourChProductsBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get tourProducts1T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Accessories and parts you keep. Search by name or code.'**
  String get tourProducts1B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Running low'**
  String get tourProducts2T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Send the to-order list to your supplier on WhatsApp.'**
  String get tourProducts2B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Adding a product'**
  String get tourProducts3T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Name, selling price and category. The count on the shelf starts at zero.'**
  String get tourProducts3B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'A product\'s page'**
  String get tourProducts4T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Stock in, damaged, a stock count, and its label.'**
  String get tourProducts4B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Enquiries'**
  String get tourChEnquiriesTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Note what people asked for and ring them back'**
  String get tourChEnquiriesBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Enquiries'**
  String get tourEnquiries1T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'People who asked for something you did not have yet. Ring them back when it comes in.'**
  String get tourEnquiries1B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Noting one'**
  String get tourEnquiries2T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Their number, what it is about, and what they asked. A follow-up date reminds you.'**
  String get tourEnquiries2B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'What came of it'**
  String get tourEnquiries3T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Mark it won, lost or still open; start a repair straight from it.'**
  String get tourEnquiries3B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Money and reports'**
  String get tourChMoneyTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'What came in, how, and who still owes'**
  String get tourChMoneyBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get tourMoney1T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Pick a period: today, this week, this month, or your own dates.'**
  String get tourMoney1B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'How it came in'**
  String get tourMoney2T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Cash, UPI and card, to match your drawer and your bank.'**
  String get tourMoney2B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Share it'**
  String get tourMoney3T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Send the report on WhatsApp, or save it.'**
  String get tourMoney3B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get tourMoney5T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Write down what the shop pays for: parts, tea, rent. Today\'s and this month\'s spending are at the top.'**
  String get tourMoney5B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Adding one'**
  String get tourMoney6T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'The amount, then what it was for. Cash and today are already picked, so tea is the amount and two taps.'**
  String get tourMoney6B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'What is left'**
  String get tourMoney7T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Reports take the expenses off. Cash left in the drawer is what you should count when closing.'**
  String get tourMoney7B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Due payments'**
  String get tourMoney4T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Everyone with money left on a bill. Remind sends them a polite WhatsApp.'**
  String get tourMoney4B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Labels, scanner and search'**
  String get tourChLabelsTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Find anything by its sticker, IMEI or a word'**
  String get tourChLabelsBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Search everything'**
  String get tourLabels1T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Name, number, IMEI, job or bill, across repairs, phones, bills and customers.'**
  String get tourLabels1B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get tourLabels2T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Scan a label or an IMEI to open what it belongs to, or to start a repair or a purchase.'**
  String get tourLabels2B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get tourLabels3T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Every number printed and what it is on. Reprint one from here.'**
  String get tourLabels3B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Staff, tasks and ratings'**
  String get tourChTeamTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Your team, their jobs, and what customers said'**
  String get tourChTeamBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get tourTeam1T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Invite people by email as staff or admin. Staff do not see costs unless you allow it.'**
  String get tourTeam1B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tourTeam2T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Jobs for the team, once or repeating. Each person sees their own.'**
  String get tourTeam2B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get tourTeam3T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'What customers said after a repair, from the link sent when it was ready.'**
  String get tourTeam3B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tourChSettingsTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Your lists, the label printer, language and more'**
  String get tourChSettingsBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get tourSettings1T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Every tour is here, any time.'**
  String get tourSettings1B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Your lists'**
  String get tourSettings2T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Brands, models, RAM, colours, complaints: the rows in the forms come from these.'**
  String get tourSettings2B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Label printer'**
  String get tourSettings3T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Pair the Bluetooth label printer and print a test label.'**
  String get tourSettings3B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Public web address'**
  String get tourSettings4T;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Only for customer rating links and the page a label\'s QR opens: the website where those pages live.'**
  String get tourSettings4B;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Getting around'**
  String get tourChAroundTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'What each page is for and where to tap'**
  String get tourChAroundBlurb;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Tour of this page'**
  String get tourThisPage;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'App tours'**
  String get tourMenuTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Practice data: nothing here is saved'**
  String get tourPractice;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'The tour is filling this in…'**
  String get tourFilling;

  /// App icon shortcut
  ///
  /// In en, this message translates to:
  /// **'New bill'**
  String get shortcutNewBill;

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'Today at the shop'**
  String get reminderMorningTitle;

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get setGroupReminders;

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'Morning reminder'**
  String get settingsReminders;

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'At opening time this phone says what the day holds: repairs due today, late and ready, and enquiries to ring back. Worked out from what this phone last saw, so open the app each day to keep it right.'**
  String get remindersHelp;

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get remindersAt;

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'Off on this phone'**
  String get remindersOff;

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'{n} due today'**
  String reminderDue(int n);

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'{n} late'**
  String reminderLate(int n);

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'{n} ready to hand back'**
  String reminderReady(int n);

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'{n} to ring back'**
  String reminderRingBack(int n);

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'Ring back: {name}'**
  String reminderRingBackTitle(String name);

  /// Reports export
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportCsv;

  /// Reports export
  ///
  /// In en, this message translates to:
  /// **'Bills, as a spreadsheet (CSV)'**
  String get exportBills;

  /// Reports export
  ///
  /// In en, this message translates to:
  /// **'Repairs, as a spreadsheet (CSV)'**
  String get exportRepairs;

  /// Reports export failed
  ///
  /// In en, this message translates to:
  /// **'Could not export: {reason}'**
  String exportFailed(String reason);

  /// Reports export
  ///
  /// In en, this message translates to:
  /// **'Phones in stock today (CSV)'**
  String get exportStock;

  /// Reminders
  ///
  /// In en, this message translates to:
  /// **'{n} to reorder'**
  String reminderReorder(int n);

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Got it. Scan the second IMEI too, or tap Done.'**
  String get imeiScanSecond;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Both IMEIs scanned.'**
  String get imeiScanBoth;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'The camera cannot be used. Type the IMEI instead.'**
  String get imeiScanNoCamera;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get imeiScanDone;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Seller\'s declaration'**
  String get declarationTitle;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Read every line to the seller, then let them sign.'**
  String get declarationHint;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'The seller has heard and agreed to all of this'**
  String get declarationAgreed;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'Government photo ID checked'**
  String get idCheckedTitle;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'You looked at the seller\'s Aadhaar, PAN, voter ID or licence.'**
  String get idCheckedHint;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'This protects the shop if the phone turns out to be stolen. Read each line aloud to the seller. When they agree, tick the box and let them sign with a finger.'**
  String get helpDeclaration;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'I am the lawful owner of this phone and I have the right to sell it.'**
  String get purchaseTerm1;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'The phone is not stolen or lost, was not obtained unlawfully, and is not part of any police complaint, FIR or court case.'**
  String get purchaseTerm2;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'The phone has no loan, EMI, insurance claim or anyone else\'s claim on it.'**
  String get purchaseTerm3;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'I have removed my personal data, signed out of every account (Google, iCloud, Mi, Samsung and others) and removed every screen lock.'**
  String get purchaseTerm4;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'I am selling this phone of my own free will, for the amount written above, and I have received that amount in full.'**
  String get purchaseTerm5;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'The phone belongs to the shop once I am paid. This is a final sale: it will not be returned to me, and there is no buy-back.'**
  String get purchaseTerm6;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'The shop may repair, refurbish or resell the phone straight away without asking me, and I will have no claim on it.'**
  String get purchaseTerm7;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'I will make good any loss, claim or legal action against the shop that comes from the phone\'s past ownership or use before this sale.'**
  String get purchaseTerm8;

  /// Purchase declaration, signature and IMEI scan
  ///
  /// In en, this message translates to:
  /// **'I have shown valid government photo ID, and a copy is kept with this form.'**
  String get purchaseTerm9;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printNow;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Send (WhatsApp and more)'**
  String get printShare;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Could not print: {error}'**
  String printFailed(String error);

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Printed in English, so every printer can show it.'**
  String get printEnglishNote;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Print the PIN or pattern'**
  String get printLockCode;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Only if the customer agrees. The card may lie on the counter.'**
  String get printLockCodeHint;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Job card'**
  String get printJobCardTitle;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Final bill'**
  String get printFinalBillTitle;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get printBillTitle;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Purchase declaration'**
  String get printDeclarationTitle;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get printLabelTitle;

  /// Printing documents
  ///
  /// In en, this message translates to:
  /// **'Print label sticker'**
  String get printLabelPdf;

  /// Camera scanning
  ///
  /// In en, this message translates to:
  /// **'Scan with camera'**
  String get scanWithCamera;

  /// Camera scanning
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get scanTorch;

  /// Camera scanning
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the sticker\'s barcode or the IMEI barcode.'**
  String get scanPointAtLabel;

  /// Camera scanning
  ///
  /// In en, this message translates to:
  /// **'Or type the number'**
  String get scanOrType;

  /// Unlock pattern grid
  ///
  /// In en, this message translates to:
  /// **'Draw the pattern with a finger'**
  String get patternDraw;

  /// Unlock pattern grid
  ///
  /// In en, this message translates to:
  /// **'Draw again'**
  String get patternClear;

  /// Unlock pattern grid
  ///
  /// In en, this message translates to:
  /// **'The customer\'s unlock pattern'**
  String get patternTitle;

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get contactCall;

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsApp;

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'There is no mobile number on this record to send to.'**
  String get contactNoNumber;

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Could not open it on this phone.'**
  String get contactCouldNotOpen;

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Remind on WhatsApp'**
  String get contactRemind;

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, this is {shop}.'**
  String waHello(String name, String shop);

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, we have received your {device} (order {order}). We will keep you updated. - {shop}'**
  String waServiceReceived(
    String name,
    String device,
    String order,
    String shop,
  );

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, your {device} (order {order}) is being repaired now. We will tell you when it is ready. - {shop}'**
  String waServiceInProgress(
    String name,
    String device,
    String order,
    String shop,
  );

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, we are waiting for parts for your {device} (order {order}). We will update you when they arrive. - {shop}'**
  String waServiceParts(String name, String device, String order, String shop);

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, your {device} (order {order}) needs your approval for extra work. Please call or visit us. - {shop}'**
  String waServiceApproval(
    String name,
    String device,
    String order,
    String shop,
  );

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, your {device} (order {order}) is ready. Please come and collect it. - {shop}'**
  String waServiceReady(String name, String device, String order, String shop);

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, your {device} (order {order}) has been handed back. Thank you for choosing {shop}.'**
  String waServiceReturned(
    String name,
    String device,
    String order,
    String shop,
  );

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, a gentle reminder that {amount} is still pending on bill {bill}. - {shop}'**
  String waDueReminder(String name, String amount, String bill, String shop);

  /// Calling and WhatsApp messages to customers
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, this is {shop} about your enquiry: {about}'**
  String waEnquiry(String name, String shop, String about);

  /// Reports: day by day and best sellers
  ///
  /// In en, this message translates to:
  /// **'Takings day by day'**
  String get reportDayByDay;

  /// Reports: day by day and best sellers
  ///
  /// In en, this message translates to:
  /// **'Completed bills. A quiet day shows as a gap.'**
  String get reportDayByDayHint;

  /// Reports: day by day and best sellers
  ///
  /// In en, this message translates to:
  /// **'What sold best'**
  String get reportWhatSold;

  /// Reports: day by day and best sellers
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String reportSoldCount(String count);

  /// Reports: day by day and best sellers
  ///
  /// In en, this message translates to:
  /// **'No completed bills in this period.'**
  String get reportNoSales;

  /// Settings: the shop's own details
  ///
  /// In en, this message translates to:
  /// **'Your shop'**
  String get shopDetailsTitle;

  /// Settings: the shop's own details
  ///
  /// In en, this message translates to:
  /// **'Printed at the top of every bill, job card and declaration.'**
  String get shopDetailsHint;

  /// Settings: the shop's own details
  ///
  /// In en, this message translates to:
  /// **'Shop details saved'**
  String get shopDetailsSaved;

  /// Settings: the shop's own details
  ///
  /// In en, this message translates to:
  /// **'Save shop details'**
  String get shopDetailsSave;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'Import contacts'**
  String get navImportContacts;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'Import contacts'**
  String get importTitle;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'Paste a phone book or a list. Every line with a mobile number becomes a customer.'**
  String get importHint;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'Copy your contacts or a list from Excel or WhatsApp, then tap Paste. Nothing is saved until you tap Add. People already in your customers are skipped.'**
  String get helpImport;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get importPaste;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'Read it'**
  String get importRead;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'No mobile numbers found in what was pasted.'**
  String get importNoneFound;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'{fresh} new · {skipped} already in your customers'**
  String importSummary(String fresh, String skipped);

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 customer} other{Add {count} customers}}'**
  String importAddAll(int count);

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 customer added} other{{count} customers added}}'**
  String importAdded(int count);

  /// Photo slot choices
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoTake;

  /// Photo slot choices
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoChoose;

  /// No description provided for @navRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get navRatings;

  /// No description provided for @rateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate your repair'**
  String get rateTitle;

  /// No description provided for @rateHowDidWeDo.
  ///
  /// In en, this message translates to:
  /// **'How did we do?'**
  String get rateHowDidWeDo;

  /// No description provided for @rateCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Anything to add? (optional)'**
  String get rateCommentHint;

  /// No description provided for @rateSend.
  ///
  /// In en, this message translates to:
  /// **'Send rating'**
  String get rateSend;

  /// No description provided for @rateThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your rating has been sent.'**
  String get rateThanks;

  /// No description provided for @rateAlreadyAnswered.
  ///
  /// In en, this message translates to:
  /// **'This job has already been rated. Thank you.'**
  String get rateAlreadyAnswered;

  /// No description provided for @rateNotFound.
  ///
  /// In en, this message translates to:
  /// **'This rating link is not valid. Check the link the shop sent you.'**
  String get rateNotFound;

  /// No description provided for @ratePickStars.
  ///
  /// In en, this message translates to:
  /// **'Tap the stars to choose a rating.'**
  String get ratePickStars;

  /// No description provided for @rateCommentTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the comment under 500 characters.'**
  String get rateCommentTooLong;

  /// No description provided for @rateCouldNotSend.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Check your connection and try again.'**
  String get rateCouldNotSend;

  /// No description provided for @askForRating.
  ///
  /// In en, this message translates to:
  /// **'Ask for a rating'**
  String get askForRating;

  /// No description provided for @sendRatingAgain.
  ///
  /// In en, this message translates to:
  /// **'Send rating link again'**
  String get sendRatingAgain;

  /// No description provided for @ratingReceived.
  ///
  /// In en, this message translates to:
  /// **'Customer rated {stars} of 5'**
  String ratingReceived(int stars);

  /// No description provided for @ratingNeedsWebAddress.
  ///
  /// In en, this message translates to:
  /// **'Set the public web address in Settings to share rating links.'**
  String get ratingNeedsWebAddress;

  /// No description provided for @ratingLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'No WhatsApp number on this order, so the rating link was copied.'**
  String get ratingLinkCopied;

  /// No description provided for @ratingsSummary.
  ///
  /// In en, this message translates to:
  /// **'{answered} of {sent} answered'**
  String ratingsSummary(int answered, int sent);

  /// No description provided for @ratingsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get ratingsAverage;

  /// No description provided for @ratingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet. Ask for one from a finished service order.'**
  String get ratingsEmpty;

  /// No description provided for @ratingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the customer'**
  String get ratingWaiting;

  /// No description provided for @publicWebAddress.
  ///
  /// In en, this message translates to:
  /// **'Public web address'**
  String get publicWebAddress;

  /// No description provided for @publicWebAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer links'**
  String get publicWebAddressTitle;

  /// No description provided for @publicWebAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Where this app\'s public pages are served. Rating links sent to customers start with it.'**
  String get publicWebAddressHint;

  /// No description provided for @publicWebAddressSaved.
  ///
  /// In en, this message translates to:
  /// **'Web address saved'**
  String get publicWebAddressSaved;

  /// No description provided for @ratingsNoAnswerYet.
  ///
  /// In en, this message translates to:
  /// **'No answers yet'**
  String get ratingsNoAnswerYet;

  /// No description provided for @ratingJob.
  ///
  /// In en, this message translates to:
  /// **'Job {number}'**
  String ratingJob(String number);

  /// No description provided for @setButton.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setButton;

  /// No description provided for @setWhatIsCharged.
  ///
  /// In en, this message translates to:
  /// **'Set what is charged'**
  String get setWhatIsCharged;

  /// No description provided for @chargedAmount.
  ///
  /// In en, this message translates to:
  /// **'Charged ₹{amount}'**
  String chargedAmount(String amount);

  /// No description provided for @printFinalBill.
  ///
  /// In en, this message translates to:
  /// **'Print final bill'**
  String get printFinalBill;

  /// No description provided for @printJobCard.
  ///
  /// In en, this message translates to:
  /// **'Print job card'**
  String get printJobCard;

  /// No description provided for @handedBackPrintBill.
  ///
  /// In en, this message translates to:
  /// **'Handed back — final bill can be printed'**
  String get handedBackPrintBill;

  /// No description provided for @stillToCheck.
  ///
  /// In en, this message translates to:
  /// **'Still to check: {items}'**
  String stillToCheck(String items);

  /// No description provided for @stillToCheckMore.
  ///
  /// In en, this message translates to:
  /// **'Still to check: {items} and {count} more'**
  String stillToCheckMore(String items, int count);

  /// No description provided for @cannotHandBackYet.
  ///
  /// In en, this message translates to:
  /// **'Cannot hand this back yet'**
  String get cannotHandBackYet;

  /// No description provided for @markedSold.
  ///
  /// In en, this message translates to:
  /// **'Marked sold'**
  String get markedSold;

  /// No description provided for @alreadySold.
  ///
  /// In en, this message translates to:
  /// **'Already sold'**
  String get alreadySold;

  /// No description provided for @onBenchNotReady.
  ///
  /// In en, this message translates to:
  /// **'On the bench — not ready to sell'**
  String get onBenchNotReady;

  /// No description provided for @atLeastSixChars.
  ///
  /// In en, this message translates to:
  /// **'At least six characters'**
  String get atLeastSixChars;

  /// No description provided for @addACheck.
  ///
  /// In en, this message translates to:
  /// **'Add a check'**
  String get addACheck;

  /// No description provided for @printServerSaved.
  ///
  /// In en, this message translates to:
  /// **'Print server saved'**
  String get printServerSaved;

  /// No description provided for @printServerHint.
  ///
  /// In en, this message translates to:
  /// **'The small server on the counter PC that talks to the label printer. Printing never blocks a save — a printer that is off is reported, not an error.'**
  String get printServerHint;

  /// No description provided for @stockCountMatched.
  ///
  /// In en, this message translates to:
  /// **'The count already matched — nothing recorded'**
  String get stockCountMatched;

  /// No description provided for @stockCorrectedTo.
  ///
  /// In en, this message translates to:
  /// **'Corrected to {count}, with the difference in the history'**
  String stockCorrectedTo(int count);

  /// No description provided for @historyDisagrees.
  ///
  /// In en, this message translates to:
  /// **'The history adds up to ₹{ledger}, not ₹{balance}. This record needs looking at.'**
  String historyDisagrees(String ledger, String balance);

  /// No description provided for @offlineModeNote.
  ///
  /// In en, this message translates to:
  /// **'Offline mode — no account, and nothing is saved beyond this session. Pick a role to walk the app.'**
  String get offlineModeNote;

  /// No description provided for @checklistCollisions.
  ///
  /// In en, this message translates to:
  /// **'These read as the same item once punctuation and case are dropped: {items}. They are kept apart, but they will look like duplicates on the checklist.'**
  String checklistCollisions(String items);

  /// No description provided for @enquiryNobodyOnNumber.
  ///
  /// In en, this message translates to:
  /// **'Nobody in the book on that number — the enquiry will carry the number typed here.'**
  String get enquiryNobodyOnNumber;

  /// No description provided for @wonAsksWhich.
  ///
  /// In en, this message translates to:
  /// **'Marking this Won asks which sale or repair it became.'**
  String get wonAsksWhich;

  /// No description provided for @wonOutcomeHelp.
  ///
  /// In en, this message translates to:
  /// **'An invoice number, a service order number, or a note. A won enquiry with nothing to point at cannot be counted.'**
  String get wonOutcomeHelp;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deleteAccountExplain.
  ///
  /// In en, this message translates to:
  /// **'This deletes your login and takes you out of this shop. The shop\'s own records — stock, bills, customers — stay with the shop. This cannot be undone.'**
  String get deleteAccountExplain;

  /// No description provided for @passwordToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Your password, to confirm'**
  String get passwordToConfirm;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete for ever'**
  String get deleteForever;

  /// No description provided for @advancePaid.
  ///
  /// In en, this message translates to:
  /// **'Advance paid'**
  String get advancePaid;

  /// No description provided for @toCollect.
  ///
  /// In en, this message translates to:
  /// **'To collect at pickup'**
  String get toCollect;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get statusReady;

  /// No description provided for @tileReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get tileReadyForPickup;

  /// No description provided for @waServiceReadyPay.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, your {device} (order {order}) is ready. Amount to pay: ₹{amount}. Please come and collect it. - {shop}'**
  String waServiceReadyPay(
    String name,
    String device,
    String order,
    String amount,
    String shop,
  );

  /// No description provided for @paidEmptyMeansFull.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if paid in full. Type 0 for a credit sale.'**
  String get paidEmptyMeansFull;

  /// No description provided for @staffSeeCostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff can see cost and profit'**
  String get staffSeeCostsTitle;

  /// No description provided for @staffSeeCostsHint.
  ///
  /// In en, this message translates to:
  /// **'Off: staff phones hide what the shop paid and what it makes. Admins always see them.'**
  String get staffSeeCostsHint;

  /// No description provided for @productSummaryRetail.
  ///
  /// In en, this message translates to:
  /// **'{lines, plural, =1{1 product} other{{lines} products}} · {units, plural, =1{1 unit} other{{units} units}} · retail ₹{retail}'**
  String productSummaryRetail(int lines, int units, String retail);

  /// No description provided for @soldFor.
  ///
  /// In en, this message translates to:
  /// **'Sold ₹{price}'**
  String soldFor(String price);

  /// No description provided for @reportHowPaid.
  ///
  /// In en, this message translates to:
  /// **'How it was paid'**
  String get reportHowPaid;

  /// No description provided for @reportWalletUsed.
  ///
  /// In en, this message translates to:
  /// **'Customer wallet used'**
  String get reportWalletUsed;

  /// No description provided for @reportStillOwed.
  ///
  /// In en, this message translates to:
  /// **'Still owed by customers'**
  String get reportStillOwed;

  /// No description provided for @reportFinanceNote.
  ///
  /// In en, this message translates to:
  /// **'Finance amounts are paid by the finance company, not into the drawer.'**
  String get reportFinanceNote;

  /// No description provided for @reportBillsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment} other{{count} payments}}'**
  String reportBillsCount(int count);

  /// No description provided for @lifeOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get lifeOverdue;

  /// No description provided for @lifeInShop.
  ///
  /// In en, this message translates to:
  /// **'In the shop'**
  String get lifeInShop;

  /// No description provided for @lifeFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get lifeFinished;

  /// No description provided for @moveReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get moveReceived;

  /// No description provided for @moveSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get moveSold;

  /// No description provided for @moveReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get moveReturned;

  /// No description provided for @moveAdjustedUp.
  ///
  /// In en, this message translates to:
  /// **'Stock-take: more than recorded'**
  String get moveAdjustedUp;

  /// No description provided for @moveAdjustedDown.
  ///
  /// In en, this message translates to:
  /// **'Stock-take: less than recorded'**
  String get moveAdjustedDown;

  /// No description provided for @moveDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged or written off'**
  String get moveDamaged;

  /// No description provided for @scanModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop label'**
  String get scanModeLabel;

  /// No description provided for @scanModeRepair.
  ///
  /// In en, this message translates to:
  /// **'New repair'**
  String get scanModeRepair;

  /// No description provided for @scanModePurchase.
  ///
  /// In en, this message translates to:
  /// **'Buy a handset'**
  String get scanModePurchase;

  /// No description provided for @scanHintLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan a sticker to open the record it was printed for.'**
  String get scanHintLabel;

  /// No description provided for @scanHintRepair.
  ///
  /// In en, this message translates to:
  /// **'Scan the phone\'s barcode to start a repair with the brand and model filled in.'**
  String get scanHintRepair;

  /// No description provided for @scanHintPurchase.
  ///
  /// In en, this message translates to:
  /// **'Scan the phone\'s barcode to start a purchase with the brand and model filled in.'**
  String get scanHintPurchase;

  /// No description provided for @enqFollowUpOverdue.
  ///
  /// In en, this message translates to:
  /// **'Follow-up overdue'**
  String get enqFollowUpOverdue;

  /// No description provided for @enqOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get enqOpen;

  /// No description provided for @enqDealtWith.
  ///
  /// In en, this message translates to:
  /// **'Dealt with'**
  String get enqDealtWith;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @period7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get period7;

  /// No description provided for @period30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get period30;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodMonth;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get periodCustom;

  /// No description provided for @figTakings.
  ///
  /// In en, this message translates to:
  /// **'Takings'**
  String get figTakings;

  /// No description provided for @figTakingsNote.
  ///
  /// In en, this message translates to:
  /// **'Completed bills, on the day they were completed — paid or still owed'**
  String get figTakingsNote;

  /// No description provided for @figService.
  ///
  /// In en, this message translates to:
  /// **'Service revenue'**
  String get figService;

  /// No description provided for @figServiceNote.
  ///
  /// In en, this message translates to:
  /// **'Jobs that went back to the customer, at the price charged'**
  String get figServiceNote;

  /// No description provided for @figMargin.
  ///
  /// In en, this message translates to:
  /// **'Second-hand margin'**
  String get figMargin;

  /// No description provided for @figMarginNote.
  ///
  /// In en, this message translates to:
  /// **'Sale price less purchase, repairs and other costs. Part of takings, not on top of it'**
  String get figMarginNote;

  /// No description provided for @figOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get figOutstanding;

  /// No description provided for @figOutstandingNote.
  ///
  /// In en, this message translates to:
  /// **'Owed right now, across all unpaid bills — not just this period. Financed sales are not counted'**
  String get figOutstandingNote;

  /// No description provided for @repairWarranty.
  ///
  /// In en, this message translates to:
  /// **'Repair warranty'**
  String get repairWarranty;

  /// No description provided for @repairWarrantyHint.
  ///
  /// In en, this message translates to:
  /// **'Printed on the final bill and checked when a phone comes back.'**
  String get repairWarrantyHint;

  /// No description provided for @warrantyNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get warrantyNone;

  /// No description provided for @warrantyDaysN.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String warrantyDaysN(int days);

  /// No description provided for @warrantyUntil.
  ///
  /// In en, this message translates to:
  /// **'Under warranty until {date}'**
  String warrantyUntil(String date);

  /// No description provided for @warrantyEnded.
  ///
  /// In en, this message translates to:
  /// **'Warranty ended {date}'**
  String warrantyEnded(String date);

  /// No description provided for @warrantyReturning.
  ///
  /// In en, this message translates to:
  /// **'Repaired here on {date} ({order}) — still under warranty until {until}.'**
  String warrantyReturning(String date, String order, String until);

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Share report'**
  String get shareReport;

  /// No description provided for @checksTicked.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} ticked'**
  String checksTicked(int done, int total);

  /// No description provided for @beforeItGoesBack.
  ///
  /// In en, this message translates to:
  /// **'Check before it goes back'**
  String get beforeItGoesBack;

  /// No description provided for @searchEverythingHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, number, IMEI, job or bill'**
  String get searchEverythingHint;

  /// Search page, before typing: records opened lately on this phone.
  ///
  /// In en, this message translates to:
  /// **'Recently opened'**
  String get recentlyOpened;

  /// No description provided for @searchPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get searchPages;

  /// No description provided for @searchEverythingTitle.
  ///
  /// In en, this message translates to:
  /// **'Find anything'**
  String get searchEverythingTitle;

  /// No description provided for @searchEverythingDetail.
  ///
  /// In en, this message translates to:
  /// **'Repairs, phones, bills, customers, products and enquiries, all at once.'**
  String get searchEverythingDetail;

  /// No description provided for @searchMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more in this list'**
  String searchMore(int count);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @collectedLaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Collected later'**
  String get collectedLaterTitle;

  /// No description provided for @paidAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Paid at pickup'**
  String get paidAtPickup;

  /// No description provided for @howPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} to collect — how was it paid?'**
  String howPaidAmount(String amount);

  /// No description provided for @sendOrderList.
  ///
  /// In en, this message translates to:
  /// **'Send order list on WhatsApp'**
  String get sendOrderList;

  /// No description provided for @sellMakeBill.
  ///
  /// In en, this message translates to:
  /// **'Sell — make a bill'**
  String get sellMakeBill;

  /// No description provided for @soldWithoutBill.
  ///
  /// In en, this message translates to:
  /// **'Sold without a bill (to a dealer, elsewhere)'**
  String get soldWithoutBill;

  /// No description provided for @moveUsedOnRepair.
  ///
  /// In en, this message translates to:
  /// **'Used on a repair'**
  String get moveUsedOnRepair;

  /// No description provided for @usePartFromStock.
  ///
  /// In en, this message translates to:
  /// **'Use a part from stock'**
  String get usePartFromStock;

  /// No description provided for @partsUsed.
  ///
  /// In en, this message translates to:
  /// **'Parts used'**
  String get partsUsed;

  /// No description provided for @partUsedSaved.
  ///
  /// In en, this message translates to:
  /// **'{part} taken off stock and added to this job'**
  String partUsedSaved(String part);

  /// No description provided for @noPartsInStock.
  ///
  /// In en, this message translates to:
  /// **'Nothing in stock to use. Add parts on the Products page.'**
  String get noPartsInStock;

  /// No description provided for @gstRateTitle.
  ///
  /// In en, this message translates to:
  /// **'GST on bills'**
  String get gstRateTitle;

  /// No description provided for @gstRateHint.
  ///
  /// In en, this message translates to:
  /// **'The GST rate your prices include. Bills show CGST and SGST when you also have a GSTIN. Used handsets are left out (margin scheme). Check the rate with your accountant.'**
  String get gstRateHint;

  /// No description provided for @gstOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get gstOff;

  /// No description provided for @hintBrands.
  ///
  /// In en, this message translates to:
  /// **'Offered on every intake and purchase form.'**
  String get hintBrands;

  /// No description provided for @hintSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Offered when adding a product.'**
  String get hintSuppliers;

  /// No description provided for @hintColours.
  ///
  /// In en, this message translates to:
  /// **'Offered on purchase and product forms.'**
  String get hintColours;

  /// No description provided for @hintCategories.
  ///
  /// In en, this message translates to:
  /// **'Groups the products list.'**
  String get hintCategories;

  /// No description provided for @hintComplaintTypes.
  ///
  /// In en, this message translates to:
  /// **'The job card and the final bill are both built from these.'**
  String get hintComplaintTypes;

  /// No description provided for @hintAccessories.
  ///
  /// In en, this message translates to:
  /// **'Ticked at intake, printed on the job card.'**
  String get hintAccessories;

  /// No description provided for @hintLockTypes.
  ///
  /// In en, this message translates to:
  /// **'How a device was locked when it came in.'**
  String get hintLockTypes;

  /// No description provided for @hintRam.
  ///
  /// In en, this message translates to:
  /// **'Offered on the purchase form.'**
  String get hintRam;

  /// No description provided for @hintExpenseKinds.
  ///
  /// In en, this message translates to:
  /// **'Offered when adding an expense.'**
  String get hintExpenseKinds;

  /// No description provided for @hintRom.
  ///
  /// In en, this message translates to:
  /// **'Offered on the purchase form.'**
  String get hintRom;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — work is saved on this phone and uploads when the internet is back.'**
  String get offlineBanner;

  /// No description provided for @plusFromRepairs.
  ///
  /// In en, this message translates to:
  /// **'+ {amount} from repairs'**
  String plusFromRepairs(String amount);

  /// No description provided for @enquiryWonAs.
  ///
  /// In en, this message translates to:
  /// **'Repair taken in — enquiry marked Won ({ref})'**
  String enquiryWonAs(String ref);

  /// No description provided for @tellTheCustomer.
  ///
  /// In en, this message translates to:
  /// **'Tell the customer'**
  String get tellTheCustomer;

  /// No description provided for @pricePaidBefore.
  ///
  /// In en, this message translates to:
  /// **'Bought {count} of these before, for {paid}'**
  String pricePaidBefore(int count, String paid);

  /// No description provided for @priceSoldBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} sold, for {avg} on average'**
  String priceSoldBefore(int count, String avg);

  /// No description provided for @homeBuyPhone.
  ///
  /// In en, this message translates to:
  /// **'Buy phone'**
  String get homeBuyPhone;

  /// No description provided for @homeEnquiry.
  ///
  /// In en, this message translates to:
  /// **'Enquiry'**
  String get homeEnquiry;

  /// No description provided for @tabRepairs.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get tabRepairs;

  /// No description provided for @homeTodaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get homeTodaysSales;

  /// No description provided for @homeBillsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bill} other{{count} bills}}'**
  String homeBillsCount(int count);

  /// No description provided for @homeNewRepair.
  ///
  /// In en, this message translates to:
  /// **'New repair'**
  String get homeNewRepair;

  /// No description provided for @homeNeedsAction.
  ///
  /// In en, this message translates to:
  /// **'Repairs needing action'**
  String get homeNeedsAction;

  /// No description provided for @homeAllCount.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String homeAllCount(int count);

  /// No description provided for @homeLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get homeLate;

  /// No description provided for @homeDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get homeDueToday;

  /// No description provided for @homeReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get homeReady;

  /// No description provided for @homeJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get homeJob;

  /// No description provided for @homeDaysLate.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Late today} =1{1 day late} other{{days} days late}}'**
  String homeDaysLate(int days);

  /// No description provided for @homeDueAt.
  ///
  /// In en, this message translates to:
  /// **'Due {time}'**
  String homeDueAt(String time);

  /// No description provided for @homeAmountDue.
  ///
  /// In en, this message translates to:
  /// **'{amount} due'**
  String homeAmountDue(String amount);

  /// No description provided for @homeNothingNeedsAction.
  ///
  /// In en, this message translates to:
  /// **'Nothing here right now'**
  String get homeNothingNeedsAction;

  /// No description provided for @homeAlsoToday.
  ///
  /// In en, this message translates to:
  /// **'Also on the board'**
  String get homeAlsoToday;

  /// No description provided for @homeOpenJob.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get homeOpenJob;

  /// No description provided for @stockDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Today} =1{1 day} other{{days} days}}'**
  String stockDays(int days);

  /// No description provided for @saveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get saveFailedTitle;

  /// No description provided for @saveNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet. Nothing you typed is lost — try again when the phone is online.'**
  String get saveNoInternet;

  /// No description provided for @saveNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This account is not allowed to save this. Ask the shop owner.'**
  String get saveNotAllowed;

  /// No description provided for @saveTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed after 20 seconds. Check the internet, then save again.'**
  String get saveTimedOut;

  /// No description provided for @saveFailedReason.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {reason}'**
  String saveFailedReason(String reason);

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @markReady.
  ///
  /// In en, this message translates to:
  /// **'Mark ready'**
  String get markReady;

  /// No description provided for @lpHint.
  ///
  /// In en, this message translates to:
  /// **'Kept on this phone. Use a 2-inch Bluetooth label printer that says TSPL, with 50 × 25 mm stickers.'**
  String get lpHint;

  /// No description provided for @lpBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth printer'**
  String get lpBluetooth;

  /// No description provided for @lpPhoneMenu.
  ///
  /// In en, this message translates to:
  /// **'Phone\'s print menu'**
  String get lpPhoneMenu;

  /// No description provided for @lpChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose printer'**
  String get lpChoose;

  /// No description provided for @lpNone.
  ///
  /// In en, this message translates to:
  /// **'No printer chosen'**
  String get lpNone;

  /// No description provided for @lpPairFirst.
  ///
  /// In en, this message translates to:
  /// **'No paired printers. Turn the printer on, pair it in the phone\'s Bluetooth settings, then come back.'**
  String get lpPairFirst;

  /// No description provided for @lpSize.
  ///
  /// In en, this message translates to:
  /// **'Sticker size'**
  String get lpSize;

  /// No description provided for @lpDarkness.
  ///
  /// In en, this message translates to:
  /// **'Darkness'**
  String get lpDarkness;

  /// No description provided for @lpTest.
  ///
  /// In en, this message translates to:
  /// **'Print test label'**
  String get lpTest;

  /// No description provided for @lpTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test label sent to the printer'**
  String get lpTestSent;

  /// No description provided for @lpRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get lpRefresh;

  /// No description provided for @btNoPrinter.
  ///
  /// In en, this message translates to:
  /// **'No label printer chosen. Pick one in Settings.'**
  String get btNoPrinter;

  /// No description provided for @btOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn it on and print again.'**
  String get btOff;

  /// No description provided for @btPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth for this app, then print again.'**
  String get btPermission;

  /// No description provided for @btConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the printer. Is it on and near the phone?'**
  String get btConnect;

  /// No description provided for @btWrite.
  ///
  /// In en, this message translates to:
  /// **'The printer did not take the label. Check the sticker roll and try again.'**
  String get btWrite;

  /// No description provided for @setGroupShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get setGroupShop;

  /// No description provided for @setGroupLists.
  ///
  /// In en, this message translates to:
  /// **'Phones & stock lists'**
  String get setGroupLists;

  /// No description provided for @setGroupRepairs.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get setGroupRepairs;

  /// No description provided for @setGroupPrinting.
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get setGroupPrinting;

  /// No description provided for @setGroupStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff & money'**
  String get setGroupStaff;

  /// No description provided for @setGroupOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get setGroupOnline;

  /// No description provided for @setBrandsModels.
  ///
  /// In en, this message translates to:
  /// **'Brands & models'**
  String get setBrandsModels;

  /// No description provided for @setMemory.
  ///
  /// In en, this message translates to:
  /// **'RAM & storage'**
  String get setMemory;

  /// No description provided for @setBrandsModelsCount.
  ///
  /// In en, this message translates to:
  /// **'{brands, plural, =1{1 brand} other{{brands} brands}} · {models, plural, =1{1 model} other{{models} models}}'**
  String setBrandsModelsCount(int brands, int models);

  /// No description provided for @setItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Empty} =1{1 item} other{{count} items}}'**
  String setItemsCount(int count);

  /// No description provided for @setSearchList.
  ///
  /// In en, this message translates to:
  /// **'Search this list'**
  String get setSearchList;

  /// No description provided for @setRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get setRename;

  /// No description provided for @setMemoryCount.
  ///
  /// In en, this message translates to:
  /// **'{ram} RAM sizes · {rom} storage sizes'**
  String setMemoryCount(int ram, int rom);

  /// No description provided for @setAddNew.
  ///
  /// In en, this message translates to:
  /// **'Type a new one'**
  String get setAddNew;

  /// No description provided for @whereIsItNow.
  ///
  /// In en, this message translates to:
  /// **'Where is it now?'**
  String get whereIsItNow;

  /// No description provided for @trackReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get trackReceived;

  /// No description provided for @trackWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get trackWorking;

  /// No description provided for @trackHandedBack.
  ///
  /// In en, this message translates to:
  /// **'Handed back'**
  String get trackHandedBack;

  /// No description provided for @sellerSoldBefore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sold you 1 phone before} other{Sold you {count} phones before}}'**
  String sellerSoldBefore(int count);

  /// No description provided for @igstTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer in another state (IGST)'**
  String get igstTitle;

  /// No description provided for @igstHint.
  ///
  /// In en, this message translates to:
  /// **'The bill shows IGST instead of CGST + SGST.'**
  String get igstHint;

  /// No description provided for @batteryHealthLabel.
  ///
  /// In en, this message translates to:
  /// **'Battery health %'**
  String get batteryHealthLabel;

  /// No description provided for @batteryHealthHelp.
  ///
  /// In en, this message translates to:
  /// **'As the phone shows it: on an iPhone, Settings → Battery → Battery Health. On Android, a battery or diagnostics app. Leave empty if you could not check.'**
  String get batteryHealthHelp;

  /// No description provided for @batteryHealthHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 91'**
  String get batteryHealthHint;

  /// No description provided for @batteryHealthValue.
  ///
  /// In en, this message translates to:
  /// **'Battery {percent}%'**
  String batteryHealthValue(int percent);

  /// No description provided for @billQueuedOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet: the bill is kept on this phone and will be completed by itself as soon as the internet is back.'**
  String get billQueuedOffline;

  /// No description provided for @pendingInternet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for internet'**
  String get pendingInternet;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Two phones, one visit'**
  String get tourRepairAnotherT;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Customer brought more than one phone? Save & add another phone: the next job starts with their details filled, both jobs are linked, and one final bill covers them all.'**
  String get tourRepairAnotherB;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'More phones from the same seller'**
  String get tourBuyAnotherT;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Buying several phones from one person? Save & buy another: the seller, ID and signature carry over, and one declaration lists every phone with the total.'**
  String get tourBuyAnotherB;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Pick a phone from stock'**
  String get tourBillStockT;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Add from stock lists the phones ready to sell. Type a model or IMEI, or tap a brand, then + Add. Phones on the bench or sold are shown grey, with the reason.'**
  String get tourBillStockB;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Bring in your contacts'**
  String get tourImportT;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Paste a list of names and numbers (or read it from the clipboard). Numbers already in the book are skipped, so nobody is added twice.'**
  String get tourImportB;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'From phone contacts'**
  String get importFromPhone;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'From a file (CSV or VCF)'**
  String get importFromFile;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'Allow Contacts for this app to import from the phone.'**
  String get importContactsDenied;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get importOpenSettings;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'That file couldn\'t be read. Use a .csv or .vcf file.'**
  String get importFileUnreadable;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'Tick all'**
  String get importTickAll;

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'Untick all'**
  String get importUntickAll;

  /// Home
  ///
  /// In en, this message translates to:
  /// **'Phones & accessories'**
  String get homeSaleSub;

  /// Home
  ///
  /// In en, this message translates to:
  /// **'Daybook'**
  String get homeDaybook;

  /// Home
  ///
  /// In en, this message translates to:
  /// **'Hide amounts'**
  String get homeHideAmounts;

  /// Home
  ///
  /// In en, this message translates to:
  /// **'Show amounts'**
  String get homeShowAmounts;

  /// Home
  ///
  /// In en, this message translates to:
  /// **'Bench is clear'**
  String get homeBenchClear;

  /// Home
  ///
  /// In en, this message translates to:
  /// **'No pending credit'**
  String get homeNoCredit;

  /// Home
  ///
  /// In en, this message translates to:
  /// **'Log walk-in leads'**
  String get homeLogLeads;

  /// Home
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 customer pending} other{{count} customers pending}}'**
  String homeDueCustomers(int count);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'Customers owe {amount}'**
  String widgetOwed(String amount);

  /// Expenses
  ///
  /// In en, this message translates to:
  /// **'That\'s more than ₹9,99,99,999 — check the amount'**
  String get expenseTooMuch;

  /// Expenses
  ///
  /// In en, this message translates to:
  /// **'Can\'t be a day that hasn\'t come yet'**
  String get expenseFutureDay;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'On your phone\'s home screen too'**
  String get tourWidgetTitle;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Long-press an empty spot on the phone\'s home screen, tap Widgets, find Shop Manager and drag \"Shop today\" out. It shows today\'s sales and the repairs waiting; the green button refreshes it.'**
  String get tourWidgetBody;

  /// Tasks
  ///
  /// In en, this message translates to:
  /// **'Pick today or a later day'**
  String get taskBlockPastDue;

  /// Record pages
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get photoTapToView;

  /// Record pages
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get photoAdd;

  /// Record pages
  ///
  /// In en, this message translates to:
  /// **'No photo yet'**
  String get photoNoneYet;

  /// Record pages
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get lockShow;

  /// Record pages
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get lockHide;

  /// Record pages
  ///
  /// In en, this message translates to:
  /// **'No lock'**
  String get lockNone;

  /// Record pages
  ///
  /// In en, this message translates to:
  /// **'Not given'**
  String get lockNotGiven;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Adding someone'**
  String get tourTeamInviteT;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Tap Invite, type the email they will sign in with, and pick Staff or Admin. When they sign up with that email, they join your shop by themselves — no code to share.'**
  String get tourTeamInviteB;

  /// Buy phone
  ///
  /// In en, this message translates to:
  /// **'Tap to sign'**
  String get signatureTapToSign;

  /// Buy phone
  ///
  /// In en, this message translates to:
  /// **'Sign full screen'**
  String get signatureFullScreen;

  /// Buy phone
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get signatureDone;

  /// Buy phone
  ///
  /// In en, this message translates to:
  /// **'Declaration'**
  String get wizDeclaration;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'6 · Declaration and signature'**
  String get tourBuySignT;

  /// App tour
  ///
  /// In en, this message translates to:
  /// **'Read every line to the seller, tick that they agree and that you saw their photo ID, then tap the box — they sign on a full screen. A new purchase cannot be saved without the signature.'**
  String get tourBuySignB;

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'Repairs {amount} · {back} handed back · {taken} taken in'**
  String widgetRepairs(String amount, int back, int taken);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} · Net {net}'**
  String widgetNet(String spent, String net);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'Most late: {device} · {customer} · {late}'**
  String widgetLateJob(String device, String customer, String late);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'{phones, plural, =1{1 phone} other{{phones} phones}} in stock · {low} products low · {calls, plural, =1{1 call} other{{calls} calls}} today'**
  String widgetStock(int phones, int low, int calls);

  /// Buy phone
  ///
  /// In en, this message translates to:
  /// **'Add both sides of the ID card first, then tick'**
  String get idPhotosFirst;

  /// Buy phone
  ///
  /// In en, this message translates to:
  /// **'ID card photos from the {date} purchase'**
  String idFromEarlier(String date);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'Net {amount}'**
  String widgetNetOnly(String amount);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'Spent {amount}'**
  String widgetSpentOnly(String amount);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get widgetRepairsLabel;

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'Repairs · {taken} in · {back} back'**
  String widgetJobsTitle(int taken, int back);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'No repairs waiting'**
  String get widgetNoJobs;

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String widgetLeft(String time);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'{time} late'**
  String widgetLateBy(String time);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String widgetUnitMin(int n);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String widgetUnitHour(int n);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String widgetUnitDay(int n);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'{n} late'**
  String widgetChipLate(int n);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'{n} today'**
  String widgetChipDue(int n);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'{n} ready'**
  String widgetChipReady(int n);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'{phones} in stock · {low} low · {calls} calls'**
  String widgetStockShort(int phones, int low, int calls);

  /// Home-screen widget
  ///
  /// In en, this message translates to:
  /// **'Owed {amount}'**
  String widgetOwedShort(String amount);

  /// More page / Settings
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get moreGroupMoney;

  /// More page / Settings
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get moreGroupStock;

  /// More page / Settings
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get moreGroupPeople;

  /// More page / Settings
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get moreGroupWork;

  /// More page / Settings
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get moreGroupOther;

  /// More page / Settings
  ///
  /// In en, this message translates to:
  /// **'Build {number} · version {version}'**
  String appBuild(String number, String version);

  /// More page / Settings
  ///
  /// In en, this message translates to:
  /// **'Test build (not from GitHub) · version {version}'**
  String appBuildLocal(String version);

  /// Button on the message after a save: opens the record
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openSaved;

  /// New repair: quick picks for the promised day
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get promiseToday;

  /// New repair: quick picks for the promised day
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get promiseTomorrow;

  /// New repair: quick picks for the promised day
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String promiseInDays(int n);

  /// New repair: quick picks for the promised day
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get promiseWeek;

  /// Repair technician
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get technicianNobody;

  /// Repair technician
  ///
  /// In en, this message translates to:
  /// **'{name} (not linked)'**
  String technicianNotLinked(String name);

  /// Repair technician
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get technicianChange;

  /// Repair technician
  ///
  /// In en, this message translates to:
  /// **'Technician: {name}'**
  String technicianChanged(String name);

  /// Repair technician
  ///
  /// In en, this message translates to:
  /// **'Their phone gets this job\'s reminders and alarms.'**
  String get technicianPickHint;

  /// Repair alarms and notifications
  ///
  /// In en, this message translates to:
  /// **'Your repairs today'**
  String get reminderMorningMineTitle;

  /// Repair alarms and notifications
  ///
  /// In en, this message translates to:
  /// **'Due in 1 hour: {device}'**
  String alarmHourTitle(String device);

  /// Repair alarms and notifications
  ///
  /// In en, this message translates to:
  /// **'Due now, not ready: {device}'**
  String alarmDueTitle(String device);

  /// Repair alarms and notifications
  ///
  /// In en, this message translates to:
  /// **'New repair for you: {device}'**
  String assignedTitle(String device);

  /// Repair alarms and notifications
  ///
  /// In en, this message translates to:
  /// **'{customer} · due {when}'**
  String assignedBody(String customer, String when);

  /// Repair alarms and notifications
  ///
  /// In en, this message translates to:
  /// **'Repair alarms'**
  String get settingsRepairAlarms;

  /// Repair alarms and notifications
  ///
  /// In en, this message translates to:
  /// **'On each technician\'s phone: a repair given to them, an alarm an hour before it is promised, and another when it is due and not ready. A repair with no technician rings on the admins\' phones.'**
  String get settingsRepairAlarmsHelp;

  /// Phone page declaration / technician
  ///
  /// In en, this message translates to:
  /// **'Not signed'**
  String get notSigned;

  /// Phone page declaration / technician
  ///
  /// In en, this message translates to:
  /// **'Agreed on {date}'**
  String agreedOn(String date);

  /// Phone page declaration / technician
  ///
  /// In en, this message translates to:
  /// **'Not agreed'**
  String get notAgreed;

  /// Phone page declaration / technician
  ///
  /// In en, this message translates to:
  /// **'ID not checked'**
  String get idNotChecked;

  /// Phone page declaration / technician
  ///
  /// In en, this message translates to:
  /// **'{name} (me)'**
  String technicianMe(String name);

  /// Eye button on a password box
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// Eye button on a password box
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Time picker
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get pickTimeTitle;

  /// Time picker
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pickTimeDone;

  /// Time picker
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get pickTimeButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
