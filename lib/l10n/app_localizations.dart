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
  /// **'Management System'**
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
  /// **'Set up a new shop'**
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
  /// **'Create an account, then set up your shop.'**
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
  /// **'Added to the shop lists: {count} new value(s)'**
  String addedToShopLists(String count);

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
  /// **'{lines} product(s) · {units} unit(s) · cost ₹{cost} · retail ₹{retail}'**
  String productSummary(String lines, String units, String cost, String retail);

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
  /// **'₹{total} owed by {count} customer(s)'**
  String owedByCustomers(String total, String count);

  /// Under the due-payments heading
  ///
  /// In en, this message translates to:
  /// **'Financed sales are not here: the customer owes nothing, and the financier\'s settlement is a different ledger.'**
  String get financedNotHere;

  /// How long a balance has been outstanding
  ///
  /// In en, this message translates to:
  /// **'oldest {days} day(s)'**
  String oldestDays(String days);

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
  /// **'Of which, from the wallet'**
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
  /// **'Kept as a draft — nothing has come off the shelf ({count} item(s))'**
  String keptAsDraftItems(String count);

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
  /// **'from {count} record(s)'**
  String fromRecords(String count);

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
  /// **'{role} · claimed when they first sign in'**
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
  /// **'Invite sent to {email}'**
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
  /// **'{count} model(s)'**
  String modelCount(String count);

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
  /// **'Point the camera at the IMEI barcode on the box or under the battery.'**
  String get imeiScanPoint;

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
  /// **'Add {count} customers'**
  String importAddAll(String count);

  /// Import contacts
  ///
  /// In en, this message translates to:
  /// **'{count} customers added'**
  String importAdded(String count);

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
  /// **'{lines} product(s) · {units} unit(s) · retail ₹{retail}'**
  String productSummaryRetail(String lines, String units, String retail);

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
  /// **'{count} bill(s)'**
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
  /// **'Completed bills, dated on the day they were settled'**
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
  /// **'{days} days'**
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
