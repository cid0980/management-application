// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'மேலாண்மை அமைப்பு';

  @override
  String get navDashboard => 'முகப்பு';

  @override
  String get navCustomers => 'வாடிக்கையாளர்கள்';

  @override
  String get navSecondHand => 'பழைய மொபைல்கள்';

  @override
  String get navProducts => 'பொருட்கள்';

  @override
  String get navService => 'சர்வீஸ்';

  @override
  String get navSales => 'விற்பனை';

  @override
  String get navDuePayments => 'நிலுவைத் தொகை';

  @override
  String get navEnquiries => 'விசாரணைகள்';

  @override
  String get navScanner => 'ஸ்கேனர்';

  @override
  String get navLabels => 'லேபிள்கள்';

  @override
  String get navSettings => 'அமைப்புகள்';

  @override
  String get navReports => 'அறிக்கைகள்';

  @override
  String get navStaff => 'பணியாளர்கள்';

  @override
  String get navLogout => 'வெளியேறு';

  @override
  String get tabHome => 'முகப்பு';

  @override
  String get tabMobiles => 'மொபைல்';

  @override
  String get tabScan => 'ஸ்கேன்';

  @override
  String get tabMore => 'மேலும்';

  @override
  String get signInSubtitle => 'உங்கள் கடைக்குள் நுழையுங்கள்.';

  @override
  String get email => 'மின்னஞ்சல்';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get signIn => 'உள்நுழை';

  @override
  String get signUp => 'பதிவு செய்';

  @override
  String get setUpNewShop => 'புதிய கடையை உருவாக்கு';

  @override
  String get forgottenPassword => 'கடவுச்சொல் மறந்துவிட்டதா';

  @override
  String get createShopTitle => 'உங்கள் கடையை அமைக்கவும்';

  @override
  String get shopName => 'கடையின் பெயர்';

  @override
  String get shopPhone => 'தொலைபேசி';

  @override
  String get shopAddress => 'முகவரி';

  @override
  String get shopGstin => 'GSTIN';

  @override
  String get createShop => 'கடையை உருவாக்கு';

  @override
  String get language => 'மொழி';

  @override
  String get languageHint =>
      'இந்தக் கடை பயன்படுத்தும் மொழி. இங்குள்ள அனைவரும் ஒரே மொழியைப் பார்ப்பார்கள்; பிறகு அமைப்புகளில் மாற்றலாம்.';

  @override
  String get languageSaved => 'மொழி சேமிக்கப்பட்டது';

  @override
  String get goodMorning => 'காலை வணக்கம்';

  @override
  String get goodAfternoon => 'மதிய வணக்கம்';

  @override
  String get goodEvening => 'மாலை வணக்கம்';

  @override
  String greetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get overdueServiceOrders => 'தாமதமான சர்வீஸ் ஆர்டர்கள்';

  @override
  String get today => 'இன்று';

  @override
  String get completedBillsOnly => 'முடிந்த பில்கள் மட்டும்';

  @override
  String get quickActions => 'விரைவு செயல்கள்';

  @override
  String get newServiceOrder => 'புதிய சர்வீஸ் ஆர்டர்';

  @override
  String get newPurchase => 'புதிய கொள்முதல்';

  @override
  String get newSale => 'புதிய விற்பனை';

  @override
  String get tilePendingOrders => 'நிலுவை ஆர்டர்கள்';

  @override
  String get tileOverdue => 'தாமதம்';

  @override
  String get tileDueToday => 'இன்று ஒப்படைக்க';

  @override
  String get tileLowStock => 'குறைந்த இருப்பு';

  @override
  String get tileDuePayments => 'நிலுவைத் தொகை';

  @override
  String get tilePendingBills => 'முடிக்காத பில்கள்';

  @override
  String get tileOpenEnquiries => 'திறந்த விசாரணைகள்';

  @override
  String get tileCustomers => 'வாடிக்கையாளர்கள்';

  @override
  String get tileNewToday => 'இன்று புதிதாக';

  @override
  String get recentOrders => 'சமீபத்திய ஆர்டர்கள்';

  @override
  String get nothingTakenInYet => 'இன்னும் எதுவும் வரவில்லை';

  @override
  String get couldNotBeRead => 'படிக்க முடியவில்லை';

  @override
  String get cancel => 'ரத்து';

  @override
  String get save => 'சேமி';

  @override
  String get signUpSubtitle =>
      'கணக்கை உருவாக்கி, பிறகு உங்கள் கடையை அமைக்கவும்.';

  @override
  String get createAccount => 'கணக்கை உருவாக்கு';

  @override
  String get haveAccount => 'என்னிடம் ஏற்கனவே கணக்கு உள்ளது';

  @override
  String resetLinkSent(String email) {
    return '$email க்கு மீட்டமைப்பு இணைப்பு அனுப்பப்பட்டது';
  }

  @override
  String get customerBookFailed => 'வாடிக்கையாளர் பட்டியலை ஏற்ற முடியவில்லை';

  @override
  String get tryAgain => 'மீண்டும் முயற்சி';

  @override
  String get searchNameOrNumber => 'பெயர் அல்லது எண்';

  @override
  String get add => 'சேர்';

  @override
  String addNamed(String what) {
    return '$what சேர்';
  }

  @override
  String get noNameGiven => 'பெயர் இல்லை';

  @override
  String get nobodyInBookYet => 'இன்னும் யாரும் இல்லை';

  @override
  String noMatchFor(String query) {
    return '\"$query\" க்கு பொருத்தம் இல்லை';
  }

  @override
  String noCustomer(String id) {
    return 'வாடிக்கையாளர் $id இல்லை';
  }

  @override
  String get edit => 'திருத்து';

  @override
  String get details => 'விவரங்கள்';

  @override
  String get phoneNumber => 'தொலைபேசி எண்';

  @override
  String get secondNumber => 'இரண்டாவது எண்';

  @override
  String get name => 'பெயர்';

  @override
  String get address => 'முகவரி';

  @override
  String get notes => 'குறிப்புகள்';

  @override
  String get soldToTheShop => 'கடைக்கு விற்றவை';

  @override
  String get nothingYet => 'இன்னும் எதுவும் இல்லை.';

  @override
  String wallet(String amount) {
    return 'வாலட் ₹$amount';
  }

  @override
  String get addCredit => 'பணம் சேர்';

  @override
  String get spend => 'செலவு';

  @override
  String get noWalletMoves => 'வாலட் பரிவர்த்தனைகள் இல்லை.';

  @override
  String get addCreditToWallet => 'வாலட்டில் பணம் சேர்';

  @override
  String get spendFromWallet => 'வாலட்டிலிருந்து செலவு';

  @override
  String get amount => 'தொகை';

  @override
  String get whatItIsFor => 'எதற்காக';

  @override
  String get required => 'கட்டாயம்';

  @override
  String get apply => 'சரி';

  @override
  String walletIsNow(String amount) {
    return 'வாலட் இப்போது ₹$amount';
  }

  @override
  String get addACustomer => 'வாடிக்கையாளரைச் சேர்';

  @override
  String get discardThisDraft => 'இந்த வரைவை நீக்கு';

  @override
  String get howTheShopFindsThem => 'கடை அவர்களை மீண்டும் கண்டுபிடிக்கும் வழி';

  @override
  String get nameOptionalHelp =>
      'விருப்பம் — எண் மட்டுமே இருந்தாலும் வாடிக்கையாளர் தான்';

  @override
  String savedNamed(String what) {
    return '$what சேமிக்கப்பட்டது';
  }

  @override
  String noSecondHandRecord(String id) {
    return 'பழைய மொபைல் பதிவு $id இல்லை.';
  }

  @override
  String get deletedLabelNote =>
      'நீக்கப்பட்ட பதிவின் லேபிளை ஸ்கேன் செய்தால் இங்கு வரும் — லேபிள் எண்ணைக் குறித்து வைப்பது நல்லது.';

  @override
  String gradeNamed(String grade) {
    return 'தரம் $grade';
  }

  @override
  String labelNamed(String number) {
    return 'லேபிள் $number';
  }

  @override
  String get device => 'சாதனம்';

  @override
  String get money => 'பணம்';

  @override
  String get repairs => 'பழுதுபார்ப்பு';

  @override
  String get condition => 'நிலை';

  @override
  String get seller => 'விற்றவர்';

  @override
  String get brand => 'பிராண்ட்';

  @override
  String get model => 'மாடல்';

  @override
  String get variant => 'வகை';

  @override
  String get colour => 'நிறம்';

  @override
  String get imei2 => 'IMEI 2';

  @override
  String get serial => 'சீரியல்';

  @override
  String get paidToSeller => 'விற்றவருக்குக் கொடுத்தது';

  @override
  String get otherCosts => 'பிற செலவுகள்';

  @override
  String get totalCost => 'மொத்தச் செலவு';

  @override
  String get asking => 'கேட்கும் விலை';

  @override
  String get expectedProfit => 'எதிர்பார்க்கும் லாபம்';

  @override
  String get realisedProfit => 'கிடைத்த லாபம்';

  @override
  String get notSoldYet => 'இன்னும் விற்கவில்லை';

  @override
  String get storedGrade => 'பதிவு செய்த தரம்';

  @override
  String get fromTheChecklist => 'சரிபார்ப்புப் பட்டியலின்படி';

  @override
  String get answered => 'பதிலளித்தவை';

  @override
  String outOf(String done, String total) {
    return '$total இல் $done';
  }

  @override
  String get setByHand => 'கையால் அமைக்கப்பட்டது';

  @override
  String get criticalFaultsOpen => 'முக்கியக் கோளாறுகள் உள்ளன';

  @override
  String get notGraded => 'தரம் இல்லை';

  @override
  String get idProof => 'அடையாளச் சான்று';

  @override
  String get notRecorded => 'பதிவு செய்யவில்லை';

  @override
  String get signed => 'கையொப்பம்';

  @override
  String get yes => 'ஆம்';

  @override
  String get no => 'இல்லை';

  @override
  String get backOnTheShelf => 'மீண்டும் விற்பனைக்கு';

  @override
  String get movedToTheBench => 'பழுதுபார்க்க அனுப்பப்பட்டது';

  @override
  String get repairFinished => 'பழுது முடிந்தது';

  @override
  String get sendToTheBench => 'பழுதுபார்க்க அனுப்பு';

  @override
  String get markSold => 'விற்றதாகக் குறி';

  @override
  String get assignAndPrintLabel => 'லேபிள் ஒதுக்கி அச்சிடு';

  @override
  String get takeInAHandset => 'மொபைலை வாங்கு';

  @override
  String get editPurchase => 'கொள்முதலைத் திருத்து';

  @override
  String get imeiAndSerial => 'IMEI & சீரியல்';

  @override
  String get pricing => 'விலை';

  @override
  String get repairAndRefurb => 'பழுது & புதுப்பித்தல்';

  @override
  String get addARepair => 'பழுதைச் சேர்';

  @override
  String get stillOnTheBench => 'இன்னும் பழுதுபார்ப்பில்';

  @override
  String get stillOnTheBenchHint =>
      'பழுது முடியும் வரை விற்பனைப் பட்டியலில் வராது.';

  @override
  String get conditionAndGrade => 'நிலை & தரம்';

  @override
  String get photos => 'புகைப்படங்கள்';

  @override
  String get frontView => 'முன் பக்கம்';

  @override
  String photoNumbered(String number) {
    return 'புகைப்படம் $number';
  }

  @override
  String get addTheFrontView => 'முன் பக்கப் படத்தைச் சேர்';

  @override
  String get addAPhoto => 'படத்தைச் சேர்';

  @override
  String get sellerSigned => 'விற்றவர் உறுதிமொழியில் கையொப்பமிட்டார்';

  @override
  String get sellerSignedHint =>
      'அச்சிட மட்டுமே தேவை — யாரும் கையொப்பமிடாத உறுதிமொழி ஆதாரம் போல் தோன்றும்.';

  @override
  String get saveAndPrint => 'சேமித்து அச்சிடு';

  @override
  String get repairDoneBeforeResale => 'விற்பனைக்கு முன் செய்த பழுது';

  @override
  String get whatWasDone => 'என்ன செய்யப்பட்டது';

  @override
  String get cost => 'செலவு';

  @override
  String get worthALook => 'கவனிக்க வேண்டியவை';

  @override
  String get notGradedNothingAnswered =>
      'தரம் இல்லை — இன்னும் எதற்கும் பதில் இல்லை';

  @override
  String criticalNamed(String faults) {
    return 'முக்கியம்: $faults';
  }

  @override
  String get overrideLabel => 'கையால் மாற்று: ';

  @override
  String get criticalCapsGrade => 'முக்கியம் — தரத்தை வரம்பிடும்';

  @override
  String costNamed(String amount) {
    return 'செலவு ₹$amount';
  }

  @override
  String expectedProfitNamed(String amount) {
    return 'எதிர்பார்க்கும் லாபம் ₹$amount';
  }

  @override
  String get stockCouldNotBeLoaded => 'இருப்பை ஏற்ற முடியவில்லை';

  @override
  String get searchStock => 'பிராண்ட், மாடல், IMEI, லேபிள் அல்லது விற்றவர்';

  @override
  String askingTotal(String amount) {
    return 'கேட்கும் விலை ₹$amount';
  }

  @override
  String nothingInTab(String tab) {
    return '$tab இல் எதுவும் இல்லை';
  }

  @override
  String get takeAHandsetIn => 'கீழே உள்ள பொத்தானால் மொபைலை வாங்குங்கள்.';

  @override
  String get stockSearchCovers =>
      'தேடல் பிராண்ட், மாடல், IMEI, லேபிள் எண், விற்றவர் அனைத்தையும் பார்க்கும்.';

  @override
  String get takeIn => 'வாங்கு';

  @override
  String soldMade(String price, String profit) {
    return 'விற்றது ₹$price · லாபம் ₹$profit';
  }

  @override
  String askingCost(String asking, String cost) {
    return 'கேட்கும் ₹$asking · செலவு ₹$cost';
  }

  @override
  String declarationQueued(String what) {
    return '$what சேமிக்கப்பட்டது — உறுதிமொழி அச்சிட வரிசையில்';
  }

  @override
  String addedToShopLists(String count) {
    return 'கடைப் பட்டியல்களில் சேர்க்கப்பட்டது: $count புதிய மதிப்பு';
  }

  @override
  String noProduct(String id) {
    return 'பொருள் $id இல்லை.';
  }

  @override
  String get deletedShelfLabelNote =>
      'நீக்கப்பட்ட பொருளின் அலமாரி லேபிளை ஸ்கேன் செய்தால் இங்கு வரும் — லேபிள் எண்ணைக் குறித்து வைப்பது நல்லது.';

  @override
  String get outOfStockCannotSell =>
      'இருப்பு இல்லை — புதிதாக வரும் வரை விற்க முடியாது.';

  @override
  String atOrBelowReorder(String level) {
    return 'மறு ஆர்டர் அளவு $level ஐ எட்டிவிட்டது';
  }

  @override
  String historyDisagreesStock(String ledger, String count) {
    return 'வரலாறு $ledger ஆகக் கூடுகிறது, $count அல்ல. இந்தப் பதிவைப் பார்க்க வேண்டும்.';
  }

  @override
  String get whatItIs => 'இது என்ன';

  @override
  String get category => 'வகை';

  @override
  String get notCategorised => 'வகை இல்லை';

  @override
  String get supplier => 'சப்ளையர்';

  @override
  String get costPrice => 'வாங்கிய விலை';

  @override
  String get sellingPrice => 'விற்கும் விலை';

  @override
  String get printedMaximum => 'அச்சிட்ட அதிகபட்ச விலை';

  @override
  String get printedMaximumMrp => 'அச்சிட்ட அதிகபட்ச விலை (MRP)';

  @override
  String get profitPerUnit => 'ஒன்றுக்கு லாபம்';

  @override
  String profitPerUnitNamed(String amount) {
    return 'ஒன்றுக்கு லாபம் ₹$amount';
  }

  @override
  String get stockAtCost => 'இருப்பு வாங்கிய விலையில்';

  @override
  String get stockAtRetail => 'இருப்பு விற்கும் விலையில்';

  @override
  String get reordering => 'மறு ஆர்டர்';

  @override
  String get reorderLevel => 'மறு ஆர்டர் அளவு';

  @override
  String get noReorderLevelSet =>
      'அமைக்கவில்லை — இருப்பு தீர்ந்தால் மட்டுமே காட்டும்';

  @override
  String get suggestedOrder => 'பரிந்துரைக்கும் ஆர்டர்';

  @override
  String get stockHistory => 'இருப்பு வரலாறு';

  @override
  String get noStockHistory =>
      'இன்னும் எதுவும் இல்லை. முதல் டெலிவரியைப் பதிவு செய்தால் இருப்பு எங்கிருந்து வந்தது என வரலாறு சொல்லும்.';

  @override
  String get receive => 'வரவு';

  @override
  String get stockTake => 'இருப்பு எண்ணிக்கை';

  @override
  String get damaged => 'சேதம்';

  @override
  String reprintLabel(String number) {
    return 'லேபிள் $number மீண்டும் அச்சிடு';
  }

  @override
  String nowOnTheShelf(String count) {
    return 'இப்போது $count இருப்பு';
  }

  @override
  String savedReceiveStock(String what) {
    return '$what சேமிக்கப்பட்டது — எண்ணிக்கையை அதன் பக்கத்தில் வரவு வைத்து அமைக்கவும்';
  }

  @override
  String get addAProduct => 'பொருளைச் சேர்';

  @override
  String get editProduct => 'பொருளைத் திருத்து';

  @override
  String get whatTheCounterSearches => 'கவுண்டரில் தேடப்படும் பெயர்';

  @override
  String get variantFits => 'வகை (எந்த மாடலுக்கு, அளவு)';

  @override
  String get whenToReorder => 'எப்போது மறு ஆர்டர்';

  @override
  String get reorderLevelHelp =>
      'குறைந்த இருப்பு எச்சரிக்கை வேண்டாமெனில் காலியாக விடுங்கள்';

  @override
  String onTheShelfNow(String count) {
    return 'இப்போது இருப்பு: $count. இருப்பு பொருளின் பக்கத்தில், காரணத்துடன் மாற்றப்படும் — இந்தப் படிவத்தில் அல்ல.';
  }

  @override
  String get newProductStartsAtZero =>
      'புதிய பொருள் பூஜ்ஜியத்தில் தொடங்கும். முதல் டெலிவரி அதன் பக்கத்தில் பதிவாகும், அதனால் இருப்பு எங்கிருந்து வந்தது என்று வரலாறு சொல்லும்.';

  @override
  String get photo => 'புகைப்படம்';

  @override
  String get mainPhoto => 'முதன்மைப் படம்';

  @override
  String get addAnother => 'இன்னொன்றைச் சேர்';

  @override
  String get productsCouldNotBeLoaded => 'பொருட்களை ஏற்ற முடியவில்லை';

  @override
  String get searchProducts => 'பெயர், பிராண்ட், வகை, SKU அல்லது சப்ளையர்';

  @override
  String costRetail(String cost, String retail) {
    return 'வாங்கியது ₹$cost · விற்பனை ₹$retail';
  }

  @override
  String get nothingOnTheListYet =>
      'இன்னும் பட்டியலில் எதுவும் இல்லை. கீழே உள்ள பொத்தானால் சேர்க்கவும்.';

  @override
  String reorderAt(String level) {
    return '$level இல் மறு ஆர்டர்';
  }

  @override
  String get noReorderLevel => 'மறு ஆர்டர் அளவு இல்லை';

  @override
  String get skuHelp => 'கடையின் சொந்தக் குறியீடு — கடை லேபிள் அல்ல';

  @override
  String noServiceOrder(String id) {
    return 'சர்வீஸ் ஆர்டர் $id இல்லை.';
  }

  @override
  String get deletedJobCardNote =>
      'நீக்கப்பட்ட ஆர்டரின் ஜாப் கார்டை ஸ்கேன் செய்தால் இங்கு வரும் — ஆர்டர் எண்ணைக் குறித்து வைப்பது நல்லது.';

  @override
  String get customer => 'வாடிக்கையாளர்';

  @override
  String get lock => 'பூட்டு';

  @override
  String get unlockWith => 'பூட்டைத் திறக்க';

  @override
  String get leftWithIt => 'உடன் கொடுத்தவை';

  @override
  String get nothingValue => 'எதுவும் இல்லை';

  @override
  String get complaints => 'புகார்கள்';

  @override
  String get estimateQuoted => 'சொன்ன மதிப்பீடு';

  @override
  String get rawMaterial => 'பொருட்கள்';

  @override
  String get outsideLabour => 'வெளி வேலை';

  @override
  String get costs => 'செலவுகள்';

  @override
  String get profitAtEstimate => 'மதிப்பீட்டின்படி லாபம்';

  @override
  String get charged => 'வசூலித்தது';

  @override
  String get notChargedYet => 'இன்னும் வசூலிக்கவில்லை';

  @override
  String get profitMade => 'கிடைத்த லாபம்';

  @override
  String get schedule => 'அட்டவணை';

  @override
  String get cameIn => 'வந்த நாள்';

  @override
  String get promised => 'சொன்ன நாள்';

  @override
  String get handedBack => 'திருப்பிக் கொடுத்தது';

  @override
  String get technician => 'டெக்னீஷியன்';

  @override
  String get nobodyYet => 'இன்னும் யாரும் இல்லை';

  @override
  String get notSet => 'அமைக்கவில்லை';

  @override
  String handedBackOn(String date) {
    return '$date அன்று திருப்பிக் கொடுக்கப்பட்டது. இதில் நிலுவை இல்லை.';
  }

  @override
  String get status => 'நிலை';

  @override
  String get completedIsNotHere =>
      'முடிந்தது என்பது யாருக்கும் இங்கு இல்லை — கீழே உள்ள சரிபார்ப்புப் பட்டியலை முடித்தால் மட்டுமே மொபைல் திரும்பும்.';

  @override
  String statusNamed(String status) {
    return 'நிலை: $status';
  }

  @override
  String get preDeliveryChecklist => 'ஒப்படைக்கும் முன் சரிபார்ப்பு';

  @override
  String get noChecklistConfigured =>
      'அமைப்புகளில் சரிபார்ப்புப் பட்டியல் இல்லை, எனவே ஒப்படைக்கும் முன் சரிபார்க்க எதுவும் இல்லை.';

  @override
  String savedJobCard(String what) {
    return '$what சேமிக்கப்பட்டது — ஜாப் கார்டு அச்சிட வரிசையில்';
  }

  @override
  String get takeInARepair => 'பழுதுக்கு வாங்கு';

  @override
  String editNamed(String what) {
    return '$what திருத்து';
  }

  @override
  String get findsWhoeverBeenHere => 'முன்பு வந்தவர்களைக் கண்டுபிடிக்கும்';

  @override
  String get patternAs => 'பேட்டர்ன், 1-2-3-6-9 போல';

  @override
  String get code => 'குறியீடு';

  @override
  String get leftWithTheDevice => 'மொபைலுடன் கொடுத்தவை';

  @override
  String get issuesAndComplaints => 'கோளாறுகள் & புகார்கள்';

  @override
  String get whatTheCustomerSaid => 'வாடிக்கையாளர் சொன்னது';

  @override
  String get estimateAndSchedule => 'மதிப்பீடு & அட்டவணை';

  @override
  String costsProfitNamed(String costs, String profit) {
    return 'செலவுகள் ₹$costs · மதிப்பீட்டின்படி லாபம் ₹$profit';
  }

  @override
  String get deviceCameIn => 'மொபைல் வந்த நாள்';

  @override
  String get promisedToCustomer => 'வாடிக்கையாளருக்குச் சொன்ன நாள்';

  @override
  String get nobodyOnThatNumber =>
      'அந்த எண்ணில் யாரும் இல்லை — ஆர்டரில் இங்கு எழுதிய எண்ணும் பெயரும் இருக்கும்.';

  @override
  String get serviceOrdersCouldNotLoad => 'சர்வீஸ் ஆர்டர்களை ஏற்ற முடியவில்லை';

  @override
  String get searchServiceOrders =>
      'ஆர்டர் எண், வாடிக்கையாளர், மொபைல் அல்லது IMEI';

  @override
  String get noComplaintRecorded => 'புகார் எதுவும் பதிவாகவில்லை';

  @override
  String get notSetTitle => 'அமைக்கவில்லை';

  @override
  String stockSummary(String count, String cost, String asking) {
    return '$count இருப்பு · செலவு ₹$cost · கேட்கும் ₹$asking';
  }

  @override
  String productSummary(
    String lines,
    String units,
    String cost,
    String retail,
  ) {
    return '$lines பொருட்கள் · $units எண்ணிக்கை · செலவு ₹$cost · விற்பனை ₹$retail';
  }

  @override
  String get nothingOutstanding => 'நிலுவை எதுவும் இல்லை';

  @override
  String get financedNotCountedHere =>
      'தவணை விற்பனைகள் இங்கு சேர்க்கப்படவில்லை — அந்த வாடிக்கையாளர்கள் கடைக்கு எதுவும் தர வேண்டியதில்லை.';

  @override
  String owedByCustomers(String total, String count) {
    return '$count வாடிக்கையாளரிடம் ₹$total நிலுவை';
  }

  @override
  String get financedNotHere =>
      'தவணை விற்பனைகள் இங்கு இல்லை: வாடிக்கையாளர் எதுவும் தர வேண்டியதில்லை, நிதி நிறுவனத்தின் தொகை வேறு கணக்கு.';

  @override
  String oldestDays(String days) {
    return 'பழையது $days நாட்கள்';
  }

  @override
  String billedPaidMethod(String total, String paid, String method) {
    return '₹$total பில் · ₹$paid செலுத்தியது · $method';
  }

  @override
  String get openTheCustomer => 'வாடிக்கையாளரைத் திற';

  @override
  String noSale(String id) {
    return 'விற்பனை $id இல்லை';
  }

  @override
  String get draftNothingOffShelf =>
      'வரைவு — இருப்பிலிருந்து எதுவும் எடுக்கப்படவில்லை';

  @override
  String get completedStatus => 'முடிந்தது';

  @override
  String get cancelledStatus => 'ரத்து';

  @override
  String get draftStatus => 'வரைவு';

  @override
  String get doneStatus => 'முடிந்தது';

  @override
  String get items => 'பொருட்கள்';

  @override
  String get bill => 'பில்';

  @override
  String get gross => 'மொத்தம்';

  @override
  String get discount => 'தள்ளுபடி';

  @override
  String get total => 'மொத்தத் தொகை';

  @override
  String get paid => 'செலுத்தியது';

  @override
  String get fromTheWallet => 'வாலட்டிலிருந்து';

  @override
  String get customerOwes => 'வாடிக்கையாளர் தர வேண்டியது';

  @override
  String get balance => 'மீதி';

  @override
  String nothingFinancedThrough(String method) {
    return 'எதுவும் இல்லை — $method மூலம் தவணை';
  }

  @override
  String get finishThisBill => 'இந்தப் பில்லை முடி';

  @override
  String collectAmount(Object amount) {
    return '₹$amount வசூலி';
  }

  @override
  String get cancelThisBill => 'இந்தப் பில்லை ரத்து செய்';

  @override
  String get printInvoice => 'பில்லை அச்சிடு';

  @override
  String invoiceQueued(String number) {
    return 'பில் $number அச்சிட வரிசையில்';
  }

  @override
  String collectedStillOwed(String amount, String remaining) {
    return '₹$amount வசூலிக்கப்பட்டது — ₹$remaining நிலுவை';
  }

  @override
  String collectedSettled(String amount) {
    return '₹$amount வசூலிக்கப்பட்டது — முடிந்தது';
  }

  @override
  String get cancelledHandsetsBack =>
      'ரத்து செய்யப்பட்டது — மொபைல்கள் மீண்டும் இருப்பில்';

  @override
  String get draftCancelled => 'வரைவு ரத்து செய்யப்பட்டது';

  @override
  String get collectFromCustomer => 'வாடிக்கையாளரிடம் வசூலி';

  @override
  String owedPartPaymentsFine(String owed) {
    return '₹$owed நிலுவை — பகுதியாகச் செலுத்தலாம்';
  }

  @override
  String get collect => 'வசூலி';

  @override
  String get handsetsGoBack =>
      'இந்தப் பில்லில் உள்ள மொபைல்கள் மீண்டும் இருப்புக்குச் செல்லும். பில் ரத்து எனக் குறிக்கப்பட்டு வைக்கப்படும்.';

  @override
  String get nothingToPutBack =>
      'இருப்பிலிருந்து எதுவும் எடுக்கப்படவில்லை, எனவே திருப்பி வைக்க எதுவும் இல்லை.';

  @override
  String get why => 'ஏன்';

  @override
  String get goesOnTheRecord => 'பதிவில் சேரும்';

  @override
  String get keepIt => 'வேண்டாம்';

  @override
  String get keptAsDraft =>
      'வரைவாகச் சேமிக்கப்பட்டது — இருப்பிலிருந்து எதுவும் எடுக்கப்படவில்லை';

  @override
  String get newSaleTitle => 'புதிய விற்பனை';

  @override
  String get editBill => 'பில்லைத் திருத்து';

  @override
  String get closeWithoutSaving => 'சேமிக்காமல் மூடு';

  @override
  String get addFromStock => 'இருப்பிலிருந்து சேர்';

  @override
  String get addALine => 'வரியைச் சேர்';

  @override
  String get method => 'முறை';

  @override
  String get paidAtTheCounter => 'கவுண்டரில் செலுத்தியது';

  @override
  String get ofWhichFromWallet => 'அதில் வாலட்டிலிருந்து';

  @override
  String walletCovers(String balance, String covers) {
    return 'வாலட்டில் ₹$balance — இந்தப் பில்லில் ₹$covers ஈடுசெய்யும்';
  }

  @override
  String get billSummary => 'பில் சுருக்கம்';

  @override
  String get keepAsDraft => 'வரைவாக வை';

  @override
  String get completeSale => 'விற்பனையை முடி';

  @override
  String get nobodyOnThatNumberBill =>
      'அந்த எண்ணில் யாரும் இல்லை — பில்லில் இங்கு எழுதிய எண் இருக்கும்.';

  @override
  String get inStock => 'இருப்பில்';

  @override
  String get nothingSellable =>
      'பழைய மொபைல் இருப்பில் விற்கக்கூடியது எதுவும் இல்லை.';

  @override
  String get notSellable => 'விற்க முடியாதவை';

  @override
  String get salesCouldNotBeLoaded => 'விற்பனைகளை ஏற்ற முடியவில்லை';

  @override
  String get searchSales => 'பில், வாடிக்கையாளர், பொருள் அல்லது IMEI';

  @override
  String get drafts => 'வரைவுகள்';

  @override
  String get all => 'அனைத்தும்';

  @override
  String owedByCustomersShort(String amount) {
    return 'வாடிக்கையாளர்களிடம் ₹$amount நிலுவை';
  }

  @override
  String get noBillsHereYet => 'இங்கு இன்னும் பில்கள் இல்லை';

  @override
  String financedOwesNothing(String total) {
    return '₹$total · தவணை, வாடிக்கையாளர் நிலுவை இல்லை';
  }

  @override
  String totalStillOwed(String total, String balance) {
    return '₹$total · ₹$balance நிலுவை';
  }

  @override
  String totalPaid(String total) {
    return '₹$total · செலுத்தப்பட்டது';
  }

  @override
  String keptAsDraftItems(String count) {
    return 'வரைவாகச் சேமிக்கப்பட்டது — இருப்பிலிருந்து எதுவும் எடுக்கப்படவில்லை ($count பொருட்கள்)';
  }

  @override
  String billStillOwed(String balance) {
    return ', ₹$balance நிலுவை';
  }

  @override
  String get addAProductLine => 'பொருளைச் சேர்';

  @override
  String get payment => 'பணம் செலுத்துதல்';

  @override
  String noEnquiry(String id) {
    return 'விசாரணை $id இல்லை';
  }

  @override
  String get whoAsked => 'யார் கேட்டார்';

  @override
  String get takenBy => 'பதிவு செய்தவர்';

  @override
  String get whatTheyAsked => 'என்ன கேட்டார்கள்';

  @override
  String get about => 'எதைப் பற்றி';

  @override
  String get inTheirWords => 'அவர்கள் சொன்னபடி';

  @override
  String get theirBudget => 'அவர்கள் சொன்ன தொகை';

  @override
  String get theyDidNotSay => 'சொல்லவில்லை';

  @override
  String get quoted => 'சொன்ன விலை';

  @override
  String get notQuoted => 'விலை சொல்லவில்லை';

  @override
  String quotedAgainstBudget(String quoted, String budget) {
    return '₹$budget பட்ஜெட்டுக்கு ₹$quoted சொல்லப்பட்டது.';
  }

  @override
  String get followUp => 'பின்தொடர்தல்';

  @override
  String get askedOn => 'கேட்ட நாள்';

  @override
  String get ringBack => 'திரும்ப அழைக்க';

  @override
  String get dealtWith => 'முடிக்கப்பட்டது';

  @override
  String get whatItBecame => 'என்னவாக மாறியது';

  @override
  String get setAFollowUp => 'பின்தொடர தேதி வை';

  @override
  String get changeTheFollowUp => 'பின்தொடர் தேதியை மாற்று';

  @override
  String ringBackOn(String date) {
    return '$date அன்று திரும்ப அழைக்க';
  }

  @override
  String savedColon(String what) {
    return 'சேமிக்கப்பட்டது: $what';
  }

  @override
  String get recordAnEnquiry => 'விசாரணையைப் பதிவு செய்';

  @override
  String get editEnquiry => 'விசாரணையைத் திருத்து';

  @override
  String get pointIsRingingBack =>
      'இதைப் பதிவு செய்வதன் நோக்கமே திரும்ப அழைப்பதுதான்';

  @override
  String get nameOptionalEnough => 'விருப்பம் — எண் மட்டுமே போதும்';

  @override
  String get inTheirWordsHelp =>
      'முடிந்தவரை அவர்கள் சொன்னபடியே — அதுதான் இந்தப் பதிவை பயனுள்ளதாக்கும்';

  @override
  String get brandIfNamed => 'பிராண்ட், சொல்லியிருந்தால்';

  @override
  String get modelIfNamed => 'மாடல், சொல்லியிருந்தால்';

  @override
  String get whatTheyWouldSpend => 'எவ்வளவு செலவிடுவதாகச் சொன்னார்கள்';

  @override
  String get leaveEmptyIfNotSaid => 'சொல்லவில்லை என்றால் காலியாக விடுங்கள்';

  @override
  String get whatTheyWereQuoted => 'அவர்களுக்குச் சொன்ன விலை';

  @override
  String get ringThemBackOn => 'திரும்ப அழைக்க வேண்டிய நாள்';

  @override
  String get notSetWillNotComeUp => 'அமைக்கவில்லை — இது தானாக மீண்டும் வராது';

  @override
  String get noFollowUpNeeded => 'பின்தொடர தேவையில்லை';

  @override
  String get enquiriesCouldNotLoad => 'விசாரணைகளை ஏற்ற முடியவில்லை';

  @override
  String get searchEnquiries => 'வாடிக்கையாளர், எண், மொபைல் அல்லது கேட்டது';

  @override
  String get record => 'பதிவு செய்';

  @override
  String get noFollowUpSet => 'பின்தொடர் தேதி இல்லை';

  @override
  String ringBackNamed(String when) {
    return '$when திரும்ப அழைக்க';
  }

  @override
  String get cameraNotWired =>
      'கேமரா ஸ்கேன் இன்னும் இணைக்கப்படவில்லை. எண்ணைத் தட்டச்சு செய்யுங்கள் — விதிகள் ஒன்றுதான்.';

  @override
  String get labelNumberOrImei => 'லேபிள் எண் அல்லது IMEI';

  @override
  String get labelIsFiveDigits =>
      'கடை லேபிள் ஐந்து இலக்கம்; IMEI பதினான்கு முதல் பதினாறு வரை';

  @override
  String get lookItUp => 'தேடு';

  @override
  String labelNotInRegistry(String number) {
    return 'லேபிள் $number பதிவேட்டில் இல்லை';
  }

  @override
  String get nothingPrintedUnder =>
      'அந்த எண்ணில் எதுவும் அச்சிடப்படவில்லை. ஸ்டிக்கரில் உள்ள எண்ணைச் சரிபார்க்கவும்.';

  @override
  String get openTheRegistry => 'பதிவேட்டைத் திற';

  @override
  String get notANumberShopUses => 'இந்தக் கடை பயன்படுத்தும் எண் அல்ல';

  @override
  String get nothingWasScanned => 'எதுவும் ஸ்கேன் செய்யப்படவில்லை.';

  @override
  String scannedNeither(String raw) {
    return '\"$raw\" ஸ்கேன் செய்யப்பட்டது. கடை லேபிள் ஐந்து இலக்கம், IMEI பதினான்கு முதல் பதினாறு — இது இரண்டும் அல்ல, பெட்டியின் பார்கோடாக இருக்கலாம்.';
  }

  @override
  String get noTitleOnLabel => 'லேபிளில் தலைப்பு இல்லை';

  @override
  String get changedSincePrinted =>
      'இந்த ஸ்டிக்கர் அச்சிட்டபின் மாறியவை — மேலே உள்ளவை தற்போதையவை.';

  @override
  String get printedByNewerBuild =>
      'இந்த லேபிளை இந்தப் பதிப்பு புரியாத வேறொரு பதிப்பு அச்சிட்டது, எனவே திறக்க இடம் இல்லை. மேலே உள்ளது அச்சிட்டதுதான்.';

  @override
  String get recordBehindLabelGone =>
      'இந்த லேபிளின் பதிவு இல்லை. மேலே உள்ளது அதில் அச்சிட்டதுதான்.';

  @override
  String get notInDeviceTable =>
      'சாதனப் பட்டியலில் இல்லை — பிராண்ட், மாடலைத் தட்டச்சு செய்ய வேண்டும்.';

  @override
  String looksLikeDevice(String device) {
    return '$device போல் தெரிகிறது. படிவம் அதனுடன் திறக்கும், மாற்றவும் முடியும்.';
  }

  @override
  String get factoryImeiNotLabel =>
      'அது தொழிற்சாலை IMEI, கடை லேபிள் அல்ல — நீளமே வித்தியாசத்தைச் சொல்லும்.';

  @override
  String get registryCouldNotLoad => 'லேபிள் பதிவேட்டை ஏற்ற முடியவில்லை';

  @override
  String nextLabel(String number) {
    return 'அடுத்த லேபிள்: $number';
  }

  @override
  String get oneCounterExplainer =>
      'எண்கள் கடை முழுவதற்கும் ஒரே கவுண்டரிலிருந்து வரும், எனவே ஒரே நேரத்தில் இருவர் ஒதுக்கினாலும் ஒரே எண் கிடைக்காது. லேபிள்கள் 26001 இல் தொடங்கும்.';

  @override
  String get searchLabels => 'லேபிள் எண், பதிவு அல்லது அச்சிட்டது';

  @override
  String get nothingPrintedYet =>
      'இன்னும் எதுவும் அச்சிடப்படவில்லை. லேபிள் ஒரு பதிவிலிருந்து ஒதுக்கப்படும் — மொபைல் அல்லது பழுதைத் திறந்து அச்சிடுங்கள்.';

  @override
  String noLabelMatching(String query) {
    return '\"$query\" க்கு லேபிள் இல்லை';
  }

  @override
  String get unreadableKind => 'புரியாத வகை';

  @override
  String reprintedTimes(String count) {
    return '$count× மீண்டும் அச்சிடப்பட்டது';
  }

  @override
  String stickerOutOfDate(String fields) {
    return 'ஸ்டிக்கர் பழையது: $fields';
  }

  @override
  String get recordGoneShowingPrinted =>
      'பதிவு இல்லை — அச்சிட்டதைக் காட்டுகிறது';

  @override
  String get printThisLabelAgain => 'இந்த லேபிளை மீண்டும் அச்சிடு';

  @override
  String get openTheRecord => 'பதிவைத் திற';

  @override
  String labelSentToPrinter(String number) {
    return 'லேபிள் $number அச்சுப்பொறிக்கு அனுப்பப்பட்டது';
  }

  @override
  String get nothingRegisteredUnder =>
      'அந்த எண்ணில் எதுவும் பதிவாகவில்லை. இது கடையின் ஸ்டிக்கர் எனில், கவுண்டரில் எண்ணைச் சொல்லுங்கள்.';

  @override
  String get whatThisIs => 'இது என்ன';

  @override
  String get price => 'விலை';

  @override
  String get someDetailsChanged =>
      'இந்த லேபிள் அச்சிட்டபின் சில விவரங்கள் மாறியுள்ளன. இங்கு காட்டுவது தற்போதையது.';

  @override
  String get shownAsRecorded =>
      'கடையில் தற்போது பதிவாகியுள்ளபடி காட்டப்படுகிறது.';

  @override
  String get askAtTheCounter =>
      'லேபிளில் அச்சிட்டது இதுதான். மேலும் விவரங்களுக்கு கவுண்டரில் கேளுங்கள்.';

  @override
  String openNothingClosed(String open) {
    return '$open திறந்துள்ளது · இன்னும் எதுவும் முடியவில்லை';
  }

  @override
  String openWonOfClosed(String open, String won, String closed, String rate) {
    return '$open திறந்துள்ளது · முடிந்த $closed இல் $won வியாபாரமானது ($rate%)';
  }

  @override
  String changedSinceStickerFields(String fields) {
    return 'இந்த ஸ்டிக்கர் அச்சிட்டபின் மாறியவை: $fields. மேலே உள்ளவை தற்போதையவை.';
  }

  @override
  String get factoryImeiIntake =>
      'அது தொழிற்சாலை IMEI, கடை லேபிள் அல்ல — நீளமே வித்தியாசத்தைச் சொல்லும். புதிதாக வாங்கப் போகிறீர்களா?';

  @override
  String figuresAreShort(String areas) {
    return 'இந்த எண்கள் முழுமையல்ல: $areas படிக்க முடியவில்லை. இந்த அறிக்கையைப் பயன்படுத்த வேண்டாம்.';
  }

  @override
  String get activity => 'செயல்பாடு';

  @override
  String get billsCompleted => 'முடிந்த பில்கள்';

  @override
  String get billsCancelled => 'ரத்து செய்த பில்கள்';

  @override
  String get jobsTakenIn => 'வாங்கிய வேலைகள்';

  @override
  String get jobsCompleted => 'முடிந்த வேலைகள்';

  @override
  String get handsetsBought => 'வாங்கிய மொபைல்கள்';

  @override
  String get handsetsSold => 'விற்ற மொபைல்கள்';

  @override
  String get customersAdded => 'சேர்த்த வாடிக்கையாளர்கள்';

  @override
  String get howMarginMadeUp => 'மொபைல் லாபம் எப்படி வருகிறது';

  @override
  String soldForAmount(String amount) {
    return '₹$amount க்கு விற்றது';
  }

  @override
  String costPurchaseRepairs(String amount) {
    return 'செலவு ₹$amount — கொள்முதல், பழுது, பிற செலவுகள்';
  }

  @override
  String get nothingHappened => 'இந்தக் காலத்தில் எதுவும் நடக்கவில்லை.';

  @override
  String fromRecords(String count) {
    return '$count பதிவுகளிலிருந்து';
  }

  @override
  String get areaSales => 'விற்பனை';

  @override
  String get areaServiceOrders => 'சர்வீஸ் ஆர்டர்கள்';

  @override
  String get areaSecondHandStock => 'பழைய மொபைல் இருப்பு';

  @override
  String get areaCustomers => 'வாடிக்கையாளர்கள்';

  @override
  String get staffOffline =>
      'ஆஃப்லைனில் பணியாளர்களை நிர்வகிக்க முடியாது — இந்தப் பக்கம் கடையையே படித்து எழுதுகிறது.';

  @override
  String workingHere(String count) {
    return '$count பேர் வேலை செய்கிறார்கள்';
  }

  @override
  String get invited => 'அழைக்கப்பட்டவர்கள்';

  @override
  String get invite => 'அழை';

  @override
  String get nobodyWaitingToJoin => 'யாரும் சேரக் காத்திருக்கவில்லை';

  @override
  String claimedOnFirstSignIn(String role) {
    return '$role · முதல் முறை உள்நுழையும்போது சேரும்';
  }

  @override
  String get withdraw => 'திரும்பப் பெறு';

  @override
  String get inviteSomebody => 'ஒருவரை அழை';

  @override
  String get claimFirstSignIn =>
      'முதல் முறை உள்நுழையும்போது இது அவர்களுக்குக் கிடைக்கும்';

  @override
  String get send => 'அனுப்பு';

  @override
  String inviteSentTo(String email) {
    return '$email க்கு அழைப்பு அனுப்பப்பட்டது';
  }

  @override
  String get roleAdmin => 'நிர்வாகி';

  @override
  String get roleStaff => 'பணியாளர்';

  @override
  String get owner => 'உரிமையாளர்';

  @override
  String get you => 'நீங்கள்';

  @override
  String makeRole(String role) {
    return '$role ஆக்கு';
  }

  @override
  String get removeFromShop => 'கடையிலிருந்து நீக்கு';

  @override
  String get roleChanged => 'பங்கு மாற்றப்பட்டது';

  @override
  String removeNamed(String name) {
    return '$name ஐ நீக்கவா?';
  }

  @override
  String get loseAccessNow =>
      'அவர்களுக்கு உடனடியாக அணுகல் போய்விடும். அவர்கள் செய்த பதிவுகள் அப்படியே இருக்கும்.';

  @override
  String get keep => 'வைத்திரு';

  @override
  String get remove => 'நீக்கு';

  @override
  String get removed => 'நீக்கப்பட்டது';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String signedInAs(String email) {
    return '$email ஆக உள்நுழைந்துள்ளீர்கள்';
  }

  @override
  String get everythingBelongsToShop =>
      'இந்த ஆப் பதிவு செய்யும் அனைத்தும் — இருப்பு, வாடிக்கையாளர்கள், விற்பனை, பழுது — உங்கள் கடைக்கே சொந்தம், நீங்களும் நீங்கள் சேர்க்கும் பணியாளர்களும் மட்டுமே பார்க்க முடியும்.';

  @override
  String get goesOnEveryBill => 'ஒவ்வொரு பில்லிலும் ஜாப் கார்டிலும் வரும்';

  @override
  String get gstinOptional => 'விருப்பம் — இருந்தால் பில்லில் அச்சிடப்படும்';

  @override
  String get createTheShop => 'கடையை உருவாக்கு';

  @override
  String get changeLaterInSettings =>
      'இதையெல்லாம் பிறகு அமைப்புகளில் மாற்றலாம், பணியாளர்களை மின்னஞ்சல் மூலம் சேர்க்கலாம்.';

  @override
  String get settingsCouldNotLoad => 'அமைப்புகளை ஏற்ற முடியவில்லை';

  @override
  String get listsGrowThemselves => 'இந்தப் பட்டியல்கள் தாமாக வளரும்';

  @override
  String get listsGrowExplainer =>
      'படிவத்தில் தட்டச்சு செய்த புதிய மதிப்பு பட்டியலில் சேரும், அடுத்தவர் அதைப் பட்டியலில் காண்பார். இந்தப் பக்கம் ஒழுங்குபடுத்தத்தான் — தேவையில்லாததை நீக்கவோ, தவறாகச் சேர்ந்ததைச் சரிசெய்யவோ.';

  @override
  String get emptyWillStartAgain =>
      'காலி. படிவத்தில் அடுத்து தட்டச்சு செய்யும் மதிப்பு மீண்டும் தொடங்கும்.';

  @override
  String addToList(String list) {
    return '$list இல் சேர்';
  }

  @override
  String addedValue(String value) {
    return '\"$value\" சேர்க்கப்பட்டது';
  }

  @override
  String removeValue(String value) {
    return '\"$value\" ஐ நீக்கவா?';
  }

  @override
  String get stopsBeingOffered =>
      'இது படிவங்களில் காட்டப்படாது. ஏற்கனவே அதைப் பயன்படுத்தும் பதிவுகள் மாறாது.';

  @override
  String removedValue(String value) {
    return '\"$value\" நீக்கப்பட்டது';
  }

  @override
  String get modelsByBrand => 'மாடல்கள், பிராண்ட் வாரியாக';

  @override
  String get noBrandsYet => 'இன்னும் பிராண்டுகள் இல்லை.';

  @override
  String get noModelsUnderBrand =>
      'இன்னும் இல்லை. இந்தப் பிராண்டில் அடுத்து தட்டச்சு செய்யும் மாடல் இங்கு வரும்.';

  @override
  String removedModelFrom(String model, String brand) {
    return '$brand இலிருந்து \"$model\" நீக்கப்பட்டது';
  }

  @override
  String addModelUnder(String brand) {
    return '$brand இல் மாடலைச் சேர்';
  }

  @override
  String addedUnderBrand(String value, String brand) {
    return '$brand இல் \"$value\" சேர்க்கப்பட்டது';
  }

  @override
  String get checklistHint =>
      'பழுது திரும்பக் கொடுக்கும் முன் ஒவ்வொன்றையும் சரிபார்க்க வேண்டும். வரிசை என்பது மொபைலைச் சரிபார்க்கும் வரிசை.';

  @override
  String get checklistEmpty =>
      'காலி, எனவே சரிபார்க்க எதுவும் இல்லை, எந்தப் பழுதையும் திருப்பிக் கொடுக்கலாம்.';

  @override
  String get signedOut => 'வெளியேறிவிட்டீர்கள்';

  @override
  String get notFound => 'கிடைக்கவில்லை';

  @override
  String noScreenFor(String uri) {
    return '$uri க்கு திரை இல்லை';
  }

  @override
  String get labelTitle => 'லேபிள்';

  @override
  String get modelsOfferedHint =>
      'பிராண்ட் தேர்ந்தெடுத்ததும் வாங்கும் படிவத்தில் காட்டப்படும் — அந்தப் பிராண்டின் மாடல்கள் மட்டும்.';

  @override
  String modelCount(String count) {
    return '$count மாடல்கள்';
  }

  @override
  String get checklistEmptyCharged =>
      'காலி, எனவே சரிபார்க்க எதுவும் இல்லை; கட்டணம் வசூலித்ததும் எந்தப் பழுதையும் திருப்பிக் கொடுக்கலாம்.';

  @override
  String alreadyOnTheList(String value) {
    return '\"$value\" ஏற்கனவே பட்டியலில் உள்ளது';
  }

  @override
  String alreadyUnderBrand(String value, String brand) {
    return '$brand இல் \"$value\" ஏற்கனவே உள்ளது';
  }

  @override
  String get stateInStock => 'இருப்பில்';

  @override
  String get stateBeingRepaired => 'பழுதுபார்ப்பில்';

  @override
  String get stateSold => 'விற்கப்பட்டது';

  @override
  String get tabRepairing => 'பழுதுபார்ப்பில்';

  @override
  String get tabToOrder => 'ஆர்டர் செய்ய';

  @override
  String get tabOutOfStock => 'இருப்பு இல்லை';

  @override
  String get levelLow => 'குறைவு';

  @override
  String get tabOpen => 'திறந்துள்ளது';

  @override
  String get tabDueToday => 'இன்று ஒப்படைக்க';

  @override
  String get tabOverdue => 'தாமதம்';

  @override
  String get statusReceived => 'வாங்கப்பட்டது';

  @override
  String get statusInProgress => 'வேலையில்';

  @override
  String get statusPartsAwaiting => 'பாகங்களுக்குக் காத்திருப்பு';

  @override
  String get statusAwaitingApproval => 'வாடிக்கையாளர் ஒப்புதலுக்காக';

  @override
  String get statusCompleted => 'முடிந்தது';

  @override
  String get statusReturned => 'திரும்ப வந்தது';

  @override
  String get tabDueTodayLower => 'இன்று';

  @override
  String get tabWon => 'வெற்றி';

  @override
  String get kindProduct => 'பொருள்';

  @override
  String get kindSecondHand => 'பழைய மொபைல்';

  @override
  String get kindServiceOrder => 'சர்வீஸ் ஆர்டர்';

  @override
  String get kindSale => 'விற்பனை';

  @override
  String get optionBrands => 'பிராண்டுகள்';

  @override
  String get optionSuppliers => 'சப்ளையர்கள்';

  @override
  String get optionColours => 'நிறங்கள்';

  @override
  String get optionCategories => 'பொருள் வகைகள்';

  @override
  String get optionComplaintTypes => 'புகார் வகைகள்';

  @override
  String get optionAccessories => 'மொபைலுடன் கொடுக்கப்படுபவை';

  @override
  String get optionLockTypes => 'பூட்டு வகைகள்';

  @override
  String openTheKind(String kind) {
    return '$kind ஐத் திற';
  }

  @override
  String get yourName => 'உங்கள் பெயர்';

  @override
  String get continueLabel => 'தொடர்';

  @override
  String get moveUp => 'மேலே நகர்த்து';

  @override
  String get moveDown => 'கீழே நகர்த்து';

  @override
  String get labelPrinter => 'லேபிள் அச்சுப்பொறி';

  @override
  String get printServerAddress => 'அச்சு சர்வர் முகவரி';

  @override
  String get saveAddress => 'முகவரியைச் சேமி';

  @override
  String get howMany => 'எத்தனை';

  @override
  String get requiredGoesInHistory => 'அவசியம் — வரலாற்றில் சேரும்';

  @override
  String recordedCount(String count) {
    return 'பதிவில்: $count';
  }

  @override
  String get countedOnShelf => 'அலமாரியில் எண்ணியது';

  @override
  String get differenceGoesInHistory => 'வித்தியாசம் வரலாற்றில் சேரும்';

  @override
  String get correctIt => 'சரிசெய்';

  @override
  String get cancelTheBill => 'பில்லை ரத்து செய்';

  @override
  String get onTheShelf => 'அலமாரியில்';

  @override
  String get nothingInNewGoods => 'புதிய பொருட்கள் இருப்பில் எதுவும் இல்லை.';

  @override
  String get noneOnTheShelf => 'அலமாரியில் இல்லை';

  @override
  String get whatIsBeingCharged => 'எவ்வளவு வசூலிக்கப்படுகிறது?';

  @override
  String get finalPrice => 'இறுதி விலை';

  @override
  String get zeroIsAllowed => 'பூஜ்ஜியமும் சரி — இலவசப் பழுது ஒரு முடிவு';

  @override
  String get returnedWithoutRepair =>
      'பழுதுபார்க்காமல் திருப்பிக் கொடுக்கப்பட்டது';

  @override
  String get returnIt => 'திருப்பிக் கொடு';

  @override
  String get whatCameOfIt => 'என்ன ஆனது';

  @override
  String get whatDidThisBecome => 'இது என்னவாக மாறியது?';

  @override
  String get saleRepairOrNote => 'விற்பனை, பழுது அல்லது குறிப்பு';

  @override
  String get markWon => 'வெற்றி எனக் குறி';

  @override
  String get startARepair => 'பழுதைத் தொடங்கு';

  @override
  String get buyThisHandset => 'இந்த மொபைலை வாங்கு';

  @override
  String get printDeclaration => 'உறுதிமொழியை அச்சிடு';

  @override
  String get whatDidItGoOutAt => 'எவ்வளவுக்கு விற்றது?';

  @override
  String get soldPrice => 'விற்ற விலை';

  @override
  String get whatItIsLine => 'இது என்ன';

  @override
  String get priceLabel => 'விலை';

  @override
  String get quantity => 'எண்ணிக்கை';

  @override
  String get discountRupees => 'தள்ளுபடி (₹)';

  @override
  String get handThePhoneBack => 'மொபைலைத் திருப்பிக் கொடு';

  @override
  String get returnedUnrepaired => 'பழுதுபார்க்காமல் திருப்பியது';

  @override
  String chargingAmount(String amount) {
    return '₹$amount வசூலிக்கப்படுகிறது';
  }

  @override
  String get returnedToCustomer =>
      'வாடிக்கையாளரிடம் திருப்பிக் கொடுக்கப்பட்டது';

  @override
  String get helpWhatIsThis => 'இது என்ன?';

  @override
  String get helpGotIt => 'புரிந்தது';

  @override
  String get fieldVariant => 'சேமிப்பு / RAM';

  @override
  String get fieldAskingPrice => 'விற்கும் விலை';

  @override
  String get fieldSellerName => 'விற்றவர் பெயர்';

  @override
  String get fieldSellerPhone => 'விற்றவர் தொலைபேசி எண்';

  @override
  String get checkWorks => 'வேலை செய்கிறது';

  @override
  String get checklistTitle => 'ஒவ்வொரு பகுதியையும் சோதியுங்கள்';

  @override
  String get gradeTitle => 'தரம்';

  @override
  String get profitTitle => 'உங்கள் லாபம்';

  @override
  String get lossTitle => 'உங்களுக்கு நஷ்டம்';

  @override
  String get helpStockTabsTitle => 'நிறங்களின் பொருள்';

  @override
  String get helpBrand =>
      'போனைத் தயாரித்த நிறுவனம். உதாரணம்: Samsung, Vivo, Apple. போனின் பின்புறத்தில் எழுதியிருக்கும். விரைவாக நிரப்ப கீழே உள்ள பெயரைத் தொடுங்கள்.';

  @override
  String get helpModel =>
      'போனின் மாடல் பெயர். உதாரணம்: Galaxy A54, Y21. Settings → About phone-இல் பார்க்கலாம்.';

  @override
  String get helpColour =>
      'போனின் பின்பக்க நிறம். உதாரணம்: கருப்பு, நீலம். அலமாரியில் சரியான போனைக் கண்டுபிடிக்க உதவும்.';

  @override
  String get helpImei =>
      'இந்த ஒரு போனுக்கு மட்டுமே உரிய 15 இலக்க எண். போனில் *#06# டயல் செய்தால் தெரியும். பெட்டியிலிருந்து அல்ல, போனிலிருந்தே எடுங்கள் — பெட்டி வேறு போனுடையதாக இருக்கலாம். திருட்டு போன்களைக் கண்டுபிடிக்க காவல்துறை இந்த எண்ணைப் பயன்படுத்தும்.';

  @override
  String get helpImei2 =>
      'இரண்டு SIM உள்ள போன்களுக்கு இரண்டாவது IMEI இருக்கும். *#06# இரண்டையும் காட்டும். ஒன்று மட்டும் இருந்தால் காலியாக விடுங்கள்.';

  @override
  String get helpSerial =>
      'தயாரிப்பாளரின் சீரியல் எண், Settings → About phone-இல் இருக்கும். பெரும்பாலான போன்களுக்குத் தேவையில்லை — இருந்தால் நிரப்புங்கள்.';

  @override
  String get helpPaid =>
      'இந்த போனை விற்றவருக்கு நீங்கள் கொடுத்த பணம். உதாரணம்: 6000. எண்கள் மட்டும், ₹ குறி வேண்டாம்.';

  @override
  String get helpOtherCost =>
      'பழுது அல்லாத, இந்த போனுக்கு செலவான பிற பணம். உதாரணம்: எடுத்து வர ஆட்டோ கட்டணம், சுத்தம் செய்தல், புதிய கவர். இல்லையென்றால் காலியாக விடுங்கள்.';

  @override
  String get helpAsking =>
      'இந்த போனை நீங்கள் விற்க விரும்பும் விலை. கீழே உள்ள பச்சைப் பெட்டி உங்கள் லாபத்தை உடனே காட்டும். அது சிவப்பாக மாறினால், இந்த விலையில் நஷ்டம் வரும்.';

  @override
  String get helpProfit =>
      'விற்கும் விலையிலிருந்து எல்லா செலவையும் கழித்தது: கொடுத்த பணம், பழுது, பிற செலவுகள். பச்சை என்றால் லாபம், சிவப்பு என்றால் நஷ்டம்.';

  @override
  String get helpRepairs =>
      'இந்த போனை விற்கத் தயாராக்கச் செய்த வேலையும் அதன் செலவும். உதாரணம்: புதிய பேட்டரி ₹800. இது செலவில் சேர்க்கப்படும், அதனால் லாபம் சரியாக இருக்கும்.';

  @override
  String get helpBench =>
      'போன் இன்னும் பழுதுபார்ப்பில் இருந்தால் இதை இயக்குங்கள். இதை அணைக்கும் வரை விற்கத் தயார் எனக் காட்டாது.';

  @override
  String get helpGrade =>
      'போன் எவ்வளவு நன்றாக உள்ளது என்பதற்கான எழுத்து. A: எல்லாம் வேலை செய்கிறது. B: 1 முதல் 3 வேலை செய்யவில்லை. C: 4 அல்லது அதற்கு மேல் வேலை செய்யவில்லை, அல்லது திரை மாற்றப்பட்டது / வெள்ளைப் புள்ளிகள். D: சேதம், வளைவு அல்லது iCloud பூட்டு. சோதனைகளிலிருந்து ஆப் கணக்கிடும் — நீங்களே தேர்ந்தெடுக்க ஒரு எழுத்தைத் தொடுங்கள்.';

  @override
  String get helpChecklist =>
      'எல்லாம் \'வேலை செய்கிறது\' என்றே தொடங்கும். பழுதானதற்கு மட்டும் \'வேலை செய்யவில்லை\' தொடுங்கள். \'திரை மாற்றப்பட்டது\' போன்ற கேள்விகளுக்கு உண்மையாக இருந்தால் மட்டும் \'ஆம்\' தொடுங்கள்.';

  @override
  String get helpPhotos =>
      'போனைப் புகைப்படம் எடுங்கள். முதல் படம் முன்பக்கமாக இருக்க வேண்டும். வாங்கும்போது போன் எந்த நிலையில் இருந்தது என்பதற்கு புகைப்படங்களே சான்று.';

  @override
  String get helpSellerName =>
      'இந்த போனை உங்களுக்கு விற்றவரின் முழுப் பெயர், அவரது அடையாள அட்டையில் உள்ளபடி.';

  @override
  String get helpSellerPhone =>
      'விற்றவரின் 10 இலக்க மொபைல் எண். பின்னர் இந்த போன் பற்றி காவல்துறை கேட்டால் தேவைப்படும்.';

  @override
  String get helpIdProof =>
      'விற்றவர் காட்டிய அடையாள அட்டை, அதன் கடைசி 4 இலக்கங்கள். உதாரணம்: Aadhaar 4412. போன் திருட்டுப் போனாக இருந்தால் இது கடையைப் பாதுகாக்கும்.';

  @override
  String get helpSigned =>
      'போன் தன்னுடையது, விற்க உரிமை உண்டு என்ற படிவத்தில் விற்றவர் கையெழுத்திட்ட பிறகு இயக்குங்கள். உறுதிமொழியை அச்சிட இது தேவை.';

  @override
  String get helpNotes =>
      'இந்த போன் பற்றி நினைவில் வைக்க வேண்டிய வேறு ஏதேனும். உதாரணம்: கேமராவில் சிறு கீறல், சார்ஜருடன் வருகிறது.';

  @override
  String get helpSearchStock =>
      'போன் பற்றி உங்களுக்குத் தெரிந்த எதையும் தட்டச்சு செய்யுங்கள் — பிராண்ட், மாடல், IMEI எண், லேபிள் எண் அல்லது விற்றவர் பெயர் — பொருந்தும் போன்கள் மட்டும் காட்டப்படும்.';

  @override
  String get helpStockTabs =>
      'பச்சை = விற்கத் தயார். ஆரஞ்சு = பழுதுபார்ப்பில். சாம்பல் = ஏற்கனவே விற்றது. அந்த போன்களை மட்டும் பார்க்க ஒரு பெட்டியைத் தொடுங்கள்.';

  @override
  String get chkFrontCamera => 'முன் கேமரா (தூசி இல்லை)';

  @override
  String get chkRearCamera => 'பின் கேமரா (தூசி இல்லை)';

  @override
  String get chkFingerprint => 'கைரேகை சென்சார்';

  @override
  String get chkBatteryHealth => 'பேட்டரி ஆரோக்கியம் %';

  @override
  String get newToShopList =>
      'புதியது — சேமிக்கும்போது உங்கள் கடைப் பட்டியலில் சேர்க்கப்படும்';

  @override
  String get pickBrandFirst =>
      'மாடல்களைப் பார்க்க முதலில் பிராண்டைத் தேர்ந்தெடுங்கள்';

  @override
  String exampleHint(String example) {
    return 'உதா: $example';
  }

  @override
  String wizStepOf(String n, String total) {
    return 'படி $n / $total';
  }

  @override
  String get wizPhoto => 'படம்';

  @override
  String get wizPhone => 'போன்';

  @override
  String get wizMoney => 'பணம்';

  @override
  String get wizPhotoTitle => 'போனைப் புகைப்படம் எடுங்கள்';

  @override
  String get wizPhotoHint =>
      'போனின் முன்பக்கம், திரை ஒளிர்ந்த நிலையில் — எப்படி இருக்கிறது என்று யாரும் பார்க்கலாம்.';

  @override
  String get wizPhoneTitle => 'இது எந்த போன்?';

  @override
  String get wizMoneyTitle => 'எவ்வளவு பணம்?';

  @override
  String get wizSellerTitle => 'உங்களுக்கு யார் விற்றார்?';

  @override
  String get wizNext => 'அடுத்து';

  @override
  String get wizBack => 'பின்';

  @override
  String get wizMoreDetails => 'மேலும் விவரங்கள் சேர்க்க (விருப்பம்)';

  @override
  String get wizHideDetails => 'கூடுதல் விவரங்களை மறை';

  @override
  String get optionRam => 'RAM நினைவகம்';

  @override
  String get optionRom => 'சேமிப்பகம் (ROM)';

  @override
  String get chkDisplayClarity => 'திரை தெளிவு';

  @override
  String get chkWhiteSpots => 'திரையில் வெள்ளைப் புள்ளிகள்';

  @override
  String get chkDisplayReplaced => 'திரை மாற்றப்பட்டது';

  @override
  String get chkPhysicalDamage => 'உடல் சேதம் / வளைவு';

  @override
  String get chkFaceTouchId => 'முக அடையாளம் / கைரேகை (Face ID / Touch ID)';

  @override
  String get chkIcloudLock => 'iCloud பூட்டு சோதனை';

  @override
  String get chkTrueTone => 'True Tone திரை';

  @override
  String get chkEarpiece => 'இயர்பீஸ் ஸ்பீக்கர்';

  @override
  String get chkLoudspeaker => 'ஒலிபெருக்கி';

  @override
  String get chkMicrophone => 'மைக்ரோஃபோன்';

  @override
  String get chkMobileData => 'மொபைல் டேட்டா';

  @override
  String get chkBluetooth => 'ப்ளூடூத்';

  @override
  String get chkWifi => 'வைஃபை';

  @override
  String get chkPowerButton => 'பவர் பட்டன்';

  @override
  String get chkVolumeButtons => 'வால்யூம் பட்டன்கள்';

  @override
  String get chkMuteSwitch => 'மியூட் சுவிட்ச்';

  @override
  String get chkLightningPort => 'சார்ஜிங் போர்ட் (Lightning / USB-C)';

  @override
  String get chkSimSlot => 'சிம் ஸ்லாட்';

  @override
  String get chkFlashlight => 'டார்ச் லைட்';

  @override
  String get chkFaceUnlock => 'முக அன்லாக்';

  @override
  String get chkChargingPort => 'சார்ஜிங் போர்ட்';

  @override
  String get chkSimSlot1 => 'சிம் ஸ்லாட் 1';

  @override
  String get chkSimSlot2 => 'சிம் ஸ்லாட் 2';

  @override
  String get chkSdCardSlot => 'மெமரி கார்டு ஸ்லாட்';

  @override
  String get chkProximitySensor => 'அருகாமை சென்சார்';

  @override
  String get catDisplay => 'திரை';

  @override
  String get catPhysical => 'உடல்';

  @override
  String get catSecurity => 'பாதுகாப்பு';

  @override
  String get catBattery => 'பேட்டரி';

  @override
  String get catCamera => 'கேமரா';

  @override
  String get catAudio => 'ஒலி';

  @override
  String get catConnectivity => 'இணைப்பு';

  @override
  String get catSim => 'சிம் & கார்டு ஸ்லாட்கள்';

  @override
  String get checkNotWorking => 'வேலை செய்யவில்லை';

  @override
  String get answerYes => 'ஆம்';

  @override
  String get answerNo => 'இல்லை';

  @override
  String get checksCommon => 'எல்லா போன்களுக்குமான சோதனைகள்';

  @override
  String get checksIphone => 'iPhone சோதனைகள்';

  @override
  String get checksAndroid => 'Android சோதனைகள்';

  @override
  String get gradeAuto => 'சோதனைகளிலிருந்து கணக்கிடப்பட்டது';

  @override
  String get gradeManual => 'கையால் தேர்ந்தெடுக்கப்பட்டது';

  @override
  String faultsFound(String list) {
    return 'பழுதுகள்: $list';
  }

  @override
  String get noFaults => 'பழுது எதுவும் இல்லை';

  @override
  String get warrantyExpiry => 'உத்தரவாதம் முடியும் தேதி';

  @override
  String get accessoriesIncluded => 'உடன் வரும் பொருட்கள்';

  @override
  String get describeWear => 'என்ன தேய்மானம் உள்ளது?';

  @override
  String get describeCondition => 'அதன் நிலையை விவரியுங்கள்';

  @override
  String get describeDamage => 'சேதத்தை விவரியுங்கள்';

  @override
  String get notesFeatures => 'சிறப்பு அம்சங்கள் / குறிப்புகள்';

  @override
  String get purchaseDate => 'வாங்கிய தேதி';

  @override
  String get fieldSupplier => 'சப்ளையர் (நேரடி விற்பனை இல்லையெனில்)';

  @override
  String get sellerSearch => 'பெயர் அல்லது எண் மூலம் தேடுங்கள்';

  @override
  String get sellerCantFind => 'விற்றவரைக் காணவில்லையா?';

  @override
  String get addNewCustomer => 'புதிய வாடிக்கையாளரைச் சேர்';

  @override
  String get saveAndSelect => 'சேமித்து தேர்ந்தெடு';

  @override
  String get idTypeLabel => 'அடையாள வகை';

  @override
  String get idNumberLabel => 'அடையாள எண்';

  @override
  String get fieldAltPhone => 'மற்றொரு தொலைபேசி எண் (விருப்பம்)';

  @override
  String get sellerPicked => 'உங்கள் வாடிக்கையாளர்களிலிருந்து';

  @override
  String get changeSeller => 'மாற்று';

  @override
  String get photoSlotFront => 'முன்பக்கம்';

  @override
  String get photoSlotBack => 'பின்பக்கம்';

  @override
  String get photoSlotLeft => 'இடது பக்கம்';

  @override
  String get photoSlotRight => 'வலது பக்கம்';

  @override
  String get photoSlotTopBottom => 'மேல் / கீழ்';

  @override
  String get photoSlotExtra => 'கூடுதல்';

  @override
  String get idCardFront => 'அடையாள அட்டை — முன்';

  @override
  String get idCardBack => 'அடையாள அட்டை — பின்';

  @override
  String get idCardPhotosTitle => 'அடையாள அட்டைப் படங்கள்';

  @override
  String get tapToAddPhoto => 'சேர்க்கத் தொடுங்கள்';

  @override
  String get wizCondition => 'நிலை';

  @override
  String get wizConditionTitle => 'அது எந்த நிலையில் உள்ளது?';

  @override
  String get wizPhotosTitle => 'போனைப் புகைப்படங்கள் எடுங்கள்';

  @override
  String get saveAndPrintLabel => 'சேமித்து லேபிள் அச்சிடு';

  @override
  String get serialAppleHint => 'iPhone-க்கு தேவை';

  @override
  String get checklistNeedsBrand =>
      'சோதனைகளைப் பார்க்க \'போன்\' படியில் பிராண்டைத் தேர்ந்தெடுங்கள்.';

  @override
  String labelPrinted(String number) {
    return 'சேமிக்கப்பட்டது — லேபிள் $number அச்சுக்கு அனுப்பப்பட்டது';
  }

  @override
  String get helpRam =>
      'போனில் எவ்வளவு RAM உள்ளது. Settings → About phone-இல் பார்க்கலாம். உதாரணம்: 6GB.';

  @override
  String get helpRom =>
      'போனில் எவ்வளவு சேமிப்பகம் உள்ளது. Settings → Storage-இல் பார்க்கலாம். உதாரணம்: 128GB. அதிக சேமிப்பகம் அதிக விலைக்கு விற்கும்.';

  @override
  String get helpPurchaseDate =>
      'இந்த போனை வாங்கிய நாள். இன்றைய தேதி ஏற்கனவே உள்ளது — வேறு நாளில் வாங்கியிருந்தால் மட்டும் மாற்றுங்கள்.';

  @override
  String get helpSupplier =>
      'டீலர் அல்லது வேறு கடையிடமிருந்து வாங்கியிருந்தால் மட்டும். வாடிக்கையாளர் விற்றிருந்தால் காலியாக விடுங்கள்.';

  @override
  String get helpSellerSearch =>
      'விற்றவரின் பெயர் அல்லது தொலைபேசி எண்ணைத் தட்டச்சு செய்யுங்கள். முன்பு கடைக்கு வந்திருந்தால் கீழே தோன்றுவார் — எல்லாவற்றையும் நிரப்பத் தொடுங்கள்.';

  @override
  String get helpAltPhone =>
      'முதல் எண் அணைக்கப்பட்டிருந்தால், விற்றவரின் இரண்டாவது எண்.';

  @override
  String get helpIdType =>
      'விற்றவர் காட்டிய அடையாள அட்டை — ஆதார், PAN, ஓட்டுநர் உரிமம் அல்லது வாக்காளர் அட்டை.';

  @override
  String get helpIdNumber => 'அந்த அடையாள அட்டையில் உள்ள எண்.';

  @override
  String get helpIdCardPhotos =>
      'விற்றவரின் அடையாள அட்டையின் முன், பின் படங்கள். பின்னர் காவல்துறை கேட்டால் யார் விற்றார் என்பதற்கு இவை சான்று.';

  @override
  String get helpGradeDetails =>
      'அடுத்தவர் மீண்டும் சோதிக்காமல் தெரிந்துகொள்ள, போனின் நிலை பற்றி சில வார்த்தைகள்.';

  @override
  String get helpSerialApple =>
      'Settings → General → About-இல் உள்ள சீரியல் எண். ஒவ்வொரு iPhone-க்கும் தேவை.';

  @override
  String get navTasks => 'பணிகள்';

  @override
  String get navMyTasks => 'என் பணிகள்';

  @override
  String get tasksCouldNotLoad => 'பணிகளை ஏற்ற முடியவில்லை';

  @override
  String get taskTabToDo => 'செய்ய வேண்டியவை';

  @override
  String get taskTabDone => 'முடிந்தவை';

  @override
  String get taskFreqDaily => 'தினமும்';

  @override
  String get taskFreqWeekly => 'வாரம் ஒருமுறை';

  @override
  String get taskFreqMonthly => 'மாதம் ஒருமுறை';

  @override
  String get taskFreqOnce => 'ஒரு முறை';

  @override
  String get taskTabUnassigned => 'யாருக்கும் இல்லை';

  @override
  String get taskPriorityLow => 'குறைவு';

  @override
  String get taskPriorityMedium => 'நடுத்தரம்';

  @override
  String get taskPriorityHigh => 'அவசரம்';

  @override
  String get taskAdd => 'பணி சேர்';

  @override
  String get taskNew => 'புதிய பணி';

  @override
  String get taskEdit => 'பணியைத் திருத்து';

  @override
  String get taskTitleLabel => 'என்ன செய்ய வேண்டும்';

  @override
  String get taskDescriptionLabel => 'கூடுதல் விவரம்';

  @override
  String get taskAssignLabel => 'யார் செய்வார்';

  @override
  String get taskFrequencyLabel => 'எத்தனை முறை';

  @override
  String get taskPriorityLabel => 'எவ்வளவு முக்கியம்';

  @override
  String get taskDueLabel => 'எந்த நாளுக்குள்';

  @override
  String get taskPickDate => 'நாளைத் தேர்ந்தெடு';

  @override
  String get taskMarkDone => 'முடிந்தது';

  @override
  String get taskUndo => 'திரும்பப் பெறு';

  @override
  String get taskOverdue => 'தாமதம்';

  @override
  String taskDueOn(String date) {
    return '$date-க்குள் செய்யவும்';
  }

  @override
  String get taskNobodySees =>
      'யாருக்கும் கொடுக்கவில்லை — பணியாளர்களுக்கு இன்னும் தெரியாது';

  @override
  String get taskAllStaff => 'எல்லோரும்';

  @override
  String get taskDelete => 'நீக்கு';

  @override
  String get taskDeleteConfirm => 'இந்தப் பணியை நீக்கவா?';

  @override
  String get taskSaved => 'பணி சேமிக்கப்பட்டது';

  @override
  String get taskNoTasks => 'இங்கே பணிகள் இல்லை';

  @override
  String get taskBlockNoTitle => 'என்ன செய்ய வேண்டும் என்று எழுதவும்.';

  @override
  String get taskBlockNoDueDate =>
      'எந்த நாளுக்குள் செய்ய வேண்டும் என்று தேர்ந்தெடுக்கவும்.';

  @override
  String get taskBlockAdminOnly =>
      'கடை உரிமையாளர் மட்டுமே பணிகளை மாற்ற முடியும்.';

  @override
  String get taskBlockNotYours => 'இந்தப் பணி வேறொருவருடையது.';

  @override
  String get helpTaskTitle =>
      'வேலையைச் சில எளிய வார்த்தைகளில் எழுதவும். உதாரணம்: கண்ணாடி அலமாரியைத் துடைக்கவும்.';

  @override
  String get helpTaskAssign =>
      'இந்த வேலையைச் செய்ய வேண்டிய பணியாளர். அவர் போனில் மட்டுமே இது தெரியும். யாரையும் தேர்ந்தெடுக்காவிட்டால், எந்தப் பணியாளருக்கும் தெரியாது.';

  @override
  String get helpTaskFrequency =>
      'வேலை எத்தனை முறை திரும்ப வரும். தினமும்: ஒவ்வொரு காலையும் மீண்டும் செய்ய வேண்டும். வாரம் ஒருமுறை: ஒவ்வொரு வாரமும் ஒரு முறை. மாதம் ஒருமுறை: ஒவ்வொரு மாதமும் ஒரு முறை. ஒரு முறை: ஒரு தடவை செய்தால் முடிந்தது.';

  @override
  String get helpTaskPriority =>
      'அவசர வேலைகள் முதலில், சிவப்பு நிறத்தில் காட்டப்படும். காத்திருக்க முடியாத வேலைகளுக்கு மட்டும் அவசரம் என்று வைக்கவும்.';

  @override
  String get helpTaskDue =>
      'இந்த வேலையை முடிக்க வேண்டிய கடைசி நாள். இந்த நாளுக்குப் பிறகு தாமதம் என்று காட்டும்.';

  @override
  String stockOnHand(String count) {
    return '$count இருப்பு';
  }

  @override
  String stockSellingFor(String amount) {
    return 'விற்பனை விலை ₹$amount';
  }

  @override
  String stockPaidFor(String amount) {
    return 'செலுத்தியது ₹$amount';
  }

  @override
  String addAsNewCustomer(String value) {
    return '\"$value\"-ஐ புதிய வாடிக்கையாளராகச் சேர்';
  }

  @override
  String addAsNewBrand(String value) {
    return '\"$value\"-ஐ புதிய பிராண்டாகச் சேர்';
  }

  @override
  String addAsNewModel(String value) {
    return '\"$value\"-ஐ புதிய மாடலாகச் சேர்';
  }

  @override
  String addAsNewRam(String value) {
    return '\"$value\"-ஐ புதிய RAM அளவாகச் சேர்';
  }

  @override
  String addAsNewRom(String value) {
    return '\"$value\"-ஐ புதிய சேமிப்பக அளவாகச் சேர்';
  }

  @override
  String addAsNewColour(String value) {
    return '\"$value\"-ஐ புதிய நிறமாகச் சேர்';
  }

  @override
  String addAsNewSupplier(String value) {
    return '\"$value\"-ஐ புதிய சப்ளையராகச் சேர்';
  }

  @override
  String get sellerSearchLabel => 'விற்றவர்';

  @override
  String get sellerSearchHint => 'பெயர் அல்லது போன் எண்ணை டைப் செய்யவும்';

  @override
  String get noMatchingRecord => 'எதுவும் பொருந்தவில்லை';

  @override
  String couldNotAddToList(String error) {
    return 'கடையின் பட்டியலில் சேர்க்க முடியவில்லை: $error';
  }

  @override
  String get signatureLabel => 'விற்றவரின் கையொப்பம்';

  @override
  String get signatureClear => 'மீண்டும் கையொப்பமிடு';

  @override
  String get signatureHint => 'இங்கே விரலால் கையொப்பமிடவும்';

  @override
  String get signatureOnRecord => 'ஏற்கனவே கையொப்பமிட்டார்';

  @override
  String get imeiScanTitle => 'IMEI-ஐ ஸ்கேன் செய்';

  @override
  String get imeiScanPoint =>
      'பெட்டியில் அல்லது பேட்டரியின் கீழ் உள்ள IMEI பார்கோடை நோக்கி கேமராவைக் காட்டவும்.';

  @override
  String get imeiScanSecond =>
      'கிடைத்தது. இரண்டாவது IMEI-யையும் ஸ்கேன் செய்யவும், அல்லது முடிந்தது அழுத்தவும்.';

  @override
  String get imeiScanBoth => 'இரண்டு IMEI-களும் ஸ்கேன் ஆனது.';

  @override
  String get imeiScanNoCamera =>
      'கேமராவைப் பயன்படுத்த முடியவில்லை. IMEI-ஐ டைப் செய்யவும்.';

  @override
  String get imeiScanDone => 'முடிந்தது';

  @override
  String get declarationTitle => 'விற்றவரின் உறுதிமொழி';

  @override
  String get declarationHint =>
      'ஒவ்வொரு வரியையும் விற்றவருக்குப் படித்துக் காட்டி, பிறகு கையொப்பமிடச் சொல்லவும்.';

  @override
  String get declarationAgreed =>
      'விற்றவர் இவை அனைத்தையும் கேட்டு ஒப்புக்கொண்டார்';

  @override
  String get idCheckedTitle => 'அரசு புகைப்பட அடையாள அட்டை சரிபார்க்கப்பட்டது';

  @override
  String get idCheckedHint =>
      'விற்றவரின் ஆதார், பான், வாக்காளர் அட்டை அல்லது உரிமத்தைப் பார்த்தீர்கள்.';

  @override
  String get helpDeclaration =>
      'போன் திருடப்பட்டது எனத் தெரிந்தால் இது கடையைப் பாதுகாக்கும். ஒவ்வொரு வரியையும் விற்றவருக்கு உரக்கப் படிக்கவும். அவர் ஒப்புக்கொண்டதும், பெட்டியில் டிக் செய்து விரலால் கையொப்பமிடச் சொல்லவும்.';

  @override
  String get purchaseTerm1 =>
      'நான் இந்த போனின் சட்டப்படியான உரிமையாளர், இதை விற்க எனக்கு உரிமை உண்டு.';

  @override
  String get purchaseTerm2 =>
      'இந்த போன் திருடப்பட்டதோ தொலைந்ததோ அல்ல, சட்டவிரோதமாகப் பெறப்பட்டதல்ல, எந்த காவல் புகார், FIR அல்லது நீதிமன்ற வழக்கிலும் இல்லை.';

  @override
  String get purchaseTerm3 =>
      'இந்த போன் மீது கடன், EMI, காப்பீட்டு கோரிக்கை அல்லது வேறு யாருடைய உரிமைகோரலும் இல்லை.';

  @override
  String get purchaseTerm4 =>
      'என் தனிப்பட்ட தகவல்களை நீக்கிவிட்டேன், எல்லா கணக்குகளிலிருந்தும் (Google, iCloud, Mi, Samsung மற்றும் பிற) வெளியேறிவிட்டேன், எல்லா திரைப் பூட்டுகளையும் நீக்கிவிட்டேன்.';

  @override
  String get purchaseTerm5 =>
      'மேலே எழுதப்பட்ட தொகைக்கு, என் சொந்த விருப்பத்தின் பேரில் இந்த போனை விற்கிறேன், அந்தத் தொகையை முழுமையாகப் பெற்றுக்கொண்டேன்.';

  @override
  String get purchaseTerm6 =>
      'எனக்குப் பணம் கிடைத்ததும் போன் கடைக்குச் சொந்தமாகும். இது இறுதி விற்பனை: இது எனக்குத் திருப்பித் தரப்படாது, திரும்ப வாங்கும் வசதியும் இல்லை.';

  @override
  String get purchaseTerm7 =>
      'கடை என்னிடம் கேட்காமலேயே போனை உடனே பழுதுபார்க்கலாம், புதுப்பிக்கலாம் அல்லது மறுவிற்பனை செய்யலாம், அதன் மீது எனக்கு எந்த உரிமையும் இருக்காது.';

  @override
  String get purchaseTerm8 =>
      'இந்த விற்பனைக்கு முன் போனின் முந்தைய உரிமை அல்லது பயன்பாட்டால் கடைக்கு ஏற்படும் எந்த இழப்பு, கோரிக்கை அல்லது சட்ட நடவடிக்கைக்கும் நான் பொறுப்பேற்பேன்.';

  @override
  String get purchaseTerm9 =>
      'நான் செல்லுபடியாகும் அரசு புகைப்பட அடையாள அட்டையைக் காட்டியுள்ளேன், அதன் நகல் இந்தப் படிவத்துடன் வைக்கப்பட்டுள்ளது.';

  @override
  String get printNow => 'அச்சிடு';

  @override
  String get printShare => 'அனுப்பு (WhatsApp மற்றும் பிற)';

  @override
  String printFailed(String error) {
    return 'அச்சிட முடியவில்லை: $error';
  }

  @override
  String get printEnglishNote =>
      'எல்லா பிரிண்டரிலும் தெரிய, ஆங்கிலத்தில் அச்சிடப்படும்.';

  @override
  String get printLockCode => 'PIN அல்லது பேட்டர்னை அச்சிடு';

  @override
  String get printLockCodeHint =>
      'வாடிக்கையாளர் ஒப்புக்கொண்டால் மட்டும். அட்டை கவுண்டரில் கிடக்கலாம்.';

  @override
  String get printJobCardTitle => 'வேலை அட்டை';

  @override
  String get printFinalBillTitle => 'இறுதி பில்';

  @override
  String get printBillTitle => 'பில்';

  @override
  String get printDeclarationTitle => 'வாங்குதல் உறுதிமொழி';

  @override
  String get printLabelTitle => 'லேபிள்';

  @override
  String get printLabelPdf => 'லேபிள் ஸ்டிக்கரை அச்சிடு';

  @override
  String get scanWithCamera => 'கேமராவால் ஸ்கேன் செய்';

  @override
  String get scanTorch => 'டார்ச்';

  @override
  String get scanPointAtLabel =>
      'ஸ்டிக்கரின் பார்கோடு அல்லது IMEI பார்கோடை நோக்கி கேமராவைக் காட்டவும்.';

  @override
  String get scanOrType => 'அல்லது எண்ணை டைப் செய்யவும்';

  @override
  String get patternDraw => 'பேட்டர்னை விரலால் வரையவும்';

  @override
  String get patternClear => 'மீண்டும் வரை';

  @override
  String get patternTitle => 'வாடிக்கையாளரின் திறப்பு பேட்டர்ன்';

  @override
  String get contactCall => 'அழை';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactNoNumber => 'இந்தப் பதிவில் அனுப்ப மொபைல் எண் இல்லை.';

  @override
  String get contactCouldNotOpen => 'இந்த போனில் திறக்க முடியவில்லை.';

  @override
  String get contactRemind => 'WhatsApp-இல் நினைவூட்டு';

  @override
  String waHello(String name, String shop) {
    return 'வணக்கம் $name, நாங்கள் $shop.';
  }

  @override
  String waServiceReceived(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'வணக்கம் $name, உங்கள் $device (ஆர்டர் $order) எங்களிடம் வந்துவிட்டது. தகவல் தெரிவிப்போம். - $shop';
  }

  @override
  String waServiceInProgress(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'வணக்கம் $name, உங்கள் $device (ஆர்டர் $order) இப்போது பழுது பார்க்கப்படுகிறது. தயாரானதும் சொல்வோம். - $shop';
  }

  @override
  String waServiceParts(String name, String device, String order, String shop) {
    return 'வணக்கம் $name, உங்கள் $device (ஆர்டர் $order)-க்கான உதிரிபாகங்களுக்காகக் காத்திருக்கிறோம். வந்ததும் சொல்வோம். - $shop';
  }

  @override
  String waServiceApproval(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'வணக்கம் $name, உங்கள் $device (ஆர்டர் $order)-க்குக் கூடுதல் வேலைக்கு உங்கள் ஒப்புதல் தேவை. அழைக்கவும் அல்லது கடைக்கு வரவும். - $shop';
  }

  @override
  String waServiceReady(String name, String device, String order, String shop) {
    return 'வணக்கம் $name, உங்கள் $device (ஆர்டர் $order) தயார். வந்து பெற்றுக்கொள்ளவும். - $shop';
  }

  @override
  String waServiceReturned(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'வணக்கம் $name, உங்கள் $device (ஆர்டர் $order) திருப்பித் தரப்பட்டது. $shop-ஐத் தேர்ந்தெடுத்ததற்கு நன்றி.';
  }

  @override
  String waDueReminder(String name, String amount, String bill, String shop) {
    return 'வணக்கம் $name, பில் $bill-இல் $amount இன்னும் நிலுவையில் உள்ளது என்பதை அன்புடன் நினைவூட்டுகிறோம். - $shop';
  }

  @override
  String waEnquiry(String name, String shop, String about) {
    return 'வணக்கம் $name, உங்கள் விசாரணை பற்றி $shop: $about';
  }

  @override
  String get reportDayByDay => 'நாள் வாரியான வருவாய்';

  @override
  String get reportDayByDayHint =>
      'முடிந்த பில்கள். அமைதியான நாள் இடைவெளியாகத் தெரியும்.';

  @override
  String get reportWhatSold => 'அதிகம் விற்றவை';

  @override
  String reportSoldCount(String count) {
    return '$count விற்றது';
  }

  @override
  String get reportNoSales => 'இந்தக் காலத்தில் முடிந்த பில்கள் இல்லை.';

  @override
  String get shopDetailsTitle => 'உங்கள் கடை';

  @override
  String get shopDetailsHint =>
      'ஒவ்வொரு பில், வேலை அட்டை, உறுதிமொழியின் மேலே அச்சிடப்படும்.';

  @override
  String get shopDetailsSaved => 'கடை விவரங்கள் சேமிக்கப்பட்டன';

  @override
  String get shopDetailsSave => 'கடை விவரங்களைச் சேமி';

  @override
  String get navImportContacts => 'தொடர்புகளை இறக்கு';

  @override
  String get importTitle => 'தொடர்புகளை இறக்கு';

  @override
  String get importHint =>
      'போன் புத்தகம் அல்லது பட்டியலை ஒட்டவும். மொபைல் எண் உள்ள ஒவ்வொரு வரியும் வாடிக்கையாளர் ஆகும்.';

  @override
  String get helpImport =>
      'உங்கள் தொடர்புகளை அல்லது Excel, WhatsApp பட்டியலை நகலெடுத்து, ஒட்டு அழுத்தவும். சேர் அழுத்தும் வரை எதுவும் சேமிக்கப்படாது. ஏற்கனவே உள்ள வாடிக்கையாளர்கள் தவிர்க்கப்படுவர்.';

  @override
  String get importPaste => 'ஒட்டு';

  @override
  String get importRead => 'படி';

  @override
  String get importNoneFound => 'ஒட்டியதில் மொபைல் எண்கள் இல்லை.';

  @override
  String importSummary(String fresh, String skipped) {
    return '$fresh புதியவர் · $skipped ஏற்கனவே உள்ளனர்';
  }

  @override
  String importAddAll(String count) {
    return '$count வாடிக்கையாளர்களைச் சேர்';
  }

  @override
  String importAdded(String count) {
    return '$count வாடிக்கையாளர்கள் சேர்க்கப்பட்டனர்';
  }

  @override
  String get photoTake => 'புகைப்படம் எடு';

  @override
  String get photoChoose => 'கேலரியிலிருந்து தேர்ந்தெடு';

  @override
  String get navRatings => 'மதிப்பீடுகள்';

  @override
  String get rateTitle => 'உங்கள் பழுதுபார்ப்பை மதிப்பிடுங்கள்';

  @override
  String get rateHowDidWeDo => 'நாங்கள் எப்படிச் செய்தோம்?';

  @override
  String get rateCommentHint => 'ஏதாவது சொல்ல வேண்டுமா? (விருப்பம்)';

  @override
  String get rateSend => 'மதிப்பீட்டை அனுப்பு';

  @override
  String get rateThanks => 'நன்றி. உங்கள் மதிப்பீடு அனுப்பப்பட்டது.';

  @override
  String get rateAlreadyAnswered =>
      'இந்த வேலை ஏற்கனவே மதிப்பிடப்பட்டது. நன்றி.';

  @override
  String get rateNotFound =>
      'இந்த மதிப்பீட்டு இணைப்பு செல்லாது. கடை அனுப்பிய இணைப்பைச் சரிபார்க்கவும்.';

  @override
  String get ratePickStars =>
      'மதிப்பீட்டைத் தேர்வுசெய்ய நட்சத்திரங்களைத் தட்டவும்.';

  @override
  String get rateCommentTooLong => 'கருத்தை 500 எழுத்துகளுக்குள் வைக்கவும்.';

  @override
  String get rateCouldNotSend =>
      'அனுப்ப முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get askForRating => 'மதிப்பீடு கேள்';

  @override
  String get sendRatingAgain => 'மதிப்பீட்டு இணைப்பை மீண்டும் அனுப்பு';

  @override
  String ratingReceived(int stars) {
    return 'வாடிக்கையாளர் 5-க்கு $stars மதிப்பிட்டார்';
  }

  @override
  String get ratingNeedsWebAddress =>
      'மதிப்பீட்டு இணைப்புகளைப் பகிர, அமைப்புகளில் பொது இணைய முகவரியை அமைக்கவும்.';

  @override
  String get ratingLinkCopied =>
      'இந்த ஆர்டரில் வாட்ஸ்அப் எண் இல்லை, எனவே மதிப்பீட்டு இணைப்பு நகலெடுக்கப்பட்டது.';

  @override
  String ratingsSummary(int answered, int sent) {
    return '$sent-இல் $answered பதிலளிக்கப்பட்டது';
  }

  @override
  String get ratingsAverage => 'சராசரி';

  @override
  String get ratingsEmpty =>
      'இன்னும் மதிப்பீடுகள் இல்லை. முடிந்த சர்வீஸ் ஆர்டரிலிருந்து ஒன்றைக் கேளுங்கள்.';

  @override
  String get ratingWaiting => 'வாடிக்கையாளருக்காகக் காத்திருக்கிறது';

  @override
  String get publicWebAddress => 'பொது இணைய முகவரி';

  @override
  String get publicWebAddressTitle => 'வாடிக்கையாளர் இணைப்புகள்';

  @override
  String get publicWebAddressHint =>
      'இந்த ஆப்பின் பொதுப் பக்கங்கள் இருக்கும் இடம். வாடிக்கையாளர்களுக்கு அனுப்பும் மதிப்பீட்டு இணைப்புகள் இதில் தொடங்கும்.';

  @override
  String get publicWebAddressSaved => 'இணைய முகவரி சேமிக்கப்பட்டது';

  @override
  String get ratingsNoAnswerYet => 'இன்னும் பதில்கள் இல்லை';

  @override
  String ratingJob(String number) {
    return 'வேலை $number';
  }

  @override
  String get setButton => 'அமை';

  @override
  String get setWhatIsCharged => 'வசூலிக்கும் தொகையை அமை';

  @override
  String chargedAmount(String amount) {
    return 'வசூலித்தது ₹$amount';
  }

  @override
  String get printFinalBill => 'இறுதி பில் அச்சிடு';

  @override
  String get printJobCard => 'ஜாப் கார்டு அச்சிடு';

  @override
  String get handedBackPrintBill =>
      'திருப்பிக் கொடுக்கப்பட்டது — இறுதி பில்லை அச்சிடலாம்';

  @override
  String stillToCheck(String items) {
    return 'இன்னும் சரிபார்க்க வேண்டியவை: $items';
  }

  @override
  String stillToCheckMore(String items, int count) {
    return 'இன்னும் சரிபார்க்க வேண்டியவை: $items மற்றும் இன்னும் $count';
  }

  @override
  String get cannotHandBackYet => 'இதை இன்னும் திருப்பிக் கொடுக்க முடியாது';

  @override
  String get markedSold => 'விற்றதாகக் குறிக்கப்பட்டது';

  @override
  String get alreadySold => 'ஏற்கனவே விற்கப்பட்டது';

  @override
  String get onBenchNotReady => 'பழுதுபார்ப்பில் — விற்கத் தயாராக இல்லை';

  @override
  String get atLeastSixChars => 'குறைந்தது ஆறு எழுத்துகள்';

  @override
  String get addACheck => 'ஒரு சரிபார்ப்பைச் சேர்';

  @override
  String get printServerSaved => 'பிரிண்ட் சர்வர் சேமிக்கப்பட்டது';

  @override
  String get printServerHint =>
      'லேபிள் பிரிண்டருடன் பேசும் கவுண்டர் கணினியில் உள்ள சிறிய சர்வர். அச்சிடுவது சேமிப்பைத் தடுக்காது — அணைந்திருக்கும் பிரிண்டர் தெரிவிக்கப்படும், அது பிழையல்ல.';

  @override
  String get stockCountMatched =>
      'எண்ணிக்கை ஏற்கனவே பொருந்தியது — எதுவும் பதிவு செய்யப்படவில்லை';

  @override
  String stockCorrectedTo(int count) {
    return '$count ஆகத் திருத்தப்பட்டது, வித்தியாசம் வரலாற்றில் உள்ளது';
  }

  @override
  String historyDisagrees(String ledger, String balance) {
    return 'வரலாற்றின் கூட்டுத்தொகை ₹$ledger, ₹$balance அல்ல. இந்தப் பதிவைச் சரிபார்க்க வேண்டும்.';
  }

  @override
  String get offlineModeNote =>
      'ஆஃப்லைன் பயன்முறை — கணக்கு இல்லை, இந்த அமர்வுக்குப் பிறகு எதுவும் சேமிக்கப்படாது. ஆப்பைப் பார்க்க ஒரு பங்கைத் தேர்வுசெய்யவும்.';

  @override
  String checklistCollisions(String items) {
    return 'நிறுத்தக்குறிகளும் எழுத்து அளவும் நீக்கப்பட்டால் இவை ஒரே உருப்படியாகப் படிக்கப்படும்: $items. இவை தனித்தனியாக வைக்கப்படும், ஆனால் சரிபார்ப்புப் பட்டியலில் இரட்டிப்பாகத் தோன்றும்.';
  }

  @override
  String get enquiryNobodyOnNumber =>
      'அந்த எண்ணில் யாரும் பதிவேட்டில் இல்லை — இங்கே தட்டச்சு செய்த எண் விசாரணையில் இருக்கும்.';

  @override
  String get wonAsksWhich =>
      'இதை வென்றதாகக் குறித்தால், அது எந்த விற்பனை அல்லது பழுதுபார்ப்பாக மாறியது என்று கேட்கும்.';

  @override
  String get wonOutcomeHelp =>
      'ஒரு பில் எண், சர்வீஸ் ஆர்டர் எண் அல்லது ஒரு குறிப்பு. சுட்டிக்காட்ட எதுவும் இல்லாத வென்ற விசாரணையைக் கணக்கிட முடியாது.';

  @override
  String get deleteMyAccount => 'என் கணக்கை நீக்கு';

  @override
  String get deleteAccountExplain =>
      'இது உங்கள் உள்நுழைவை நீக்கி, இந்தக் கடையிலிருந்து உங்களை வெளியேற்றும். கடையின் பதிவுகள் — ஸ்டாக், பில்கள், வாடிக்கையாளர்கள் — கடையிடமே இருக்கும். இதைத் திரும்பப் பெற முடியாது.';

  @override
  String get passwordToConfirm => 'உறுதிப்படுத்த உங்கள் கடவுச்சொல்';

  @override
  String get deleteForever => 'நிரந்தரமாக நீக்கு';

  @override
  String get advancePaid => 'முன்பணம் செலுத்தியது';

  @override
  String get toCollect => 'எடுக்கும்போது வசூலிக்க வேண்டியது';

  @override
  String get statusReady => 'எடுக்கத் தயார்';

  @override
  String get tileReadyForPickup => 'எடுக்கத் தயார்';

  @override
  String waServiceReadyPay(
    String name,
    String device,
    String order,
    String amount,
    String shop,
  ) {
    return 'வணக்கம் $name, உங்கள் $device (ஆர்டர் $order) தயாராக உள்ளது. செலுத்த வேண்டிய தொகை: ₹$amount. வந்து பெற்றுக்கொள்ளுங்கள். - $shop';
  }

  @override
  String get paidEmptyMeansFull =>
      'முழுமையாகச் செலுத்தியிருந்தால் காலியாக விடவும். கடன் விற்பனைக்கு 0 என்று உள்ளிடவும்.';

  @override
  String get staffSeeCostsTitle =>
      'பணியாளர்கள் அடக்க விலையையும் லாபத்தையும் பார்க்கலாம்';

  @override
  String get staffSeeCostsHint =>
      'அணைத்தால்: கடை செலுத்தியதும் ஈட்டுவதும் பணியாளர் போன்களில் மறைக்கப்படும். நிர்வாகிகள் எப்போதும் பார்ப்பார்கள்.';

  @override
  String productSummaryRetail(String lines, String units, String retail) {
    return '$lines பொருள்(கள்) · $units அலகு(கள்) · விற்பனை ₹$retail';
  }

  @override
  String soldFor(String price) {
    return '₹$price-க்கு விற்கப்பட்டது';
  }

  @override
  String get reportHowPaid => 'எப்படிச் செலுத்தப்பட்டது';

  @override
  String get reportWalletUsed => 'வாடிக்கையாளர் வாலட் பயன்பாடு';

  @override
  String get reportStillOwed => 'வாடிக்கையாளர்கள் இன்னும் தர வேண்டியது';

  @override
  String get reportFinanceNote =>
      'நிதி நிறுவனத் தொகைகள் நிதி நிறுவனத்தால் செலுத்தப்படும், கல்லாப்பெட்டிக்கு வராது.';

  @override
  String reportBillsCount(int count) {
    return '$count பில்(கள்)';
  }

  @override
  String get lifeOverdue => 'தாமதம்';

  @override
  String get lifeInShop => 'கடையில் உள்ளது';

  @override
  String get lifeFinished => 'முடிந்தது';

  @override
  String get moveReceived => 'பெறப்பட்டது';

  @override
  String get moveSold => 'விற்கப்பட்டது';

  @override
  String get moveReturned => 'திருப்பி வந்தது';

  @override
  String get moveAdjustedUp => 'ஸ்டாக் சரிபார்ப்பு: பதிவை விட அதிகம்';

  @override
  String get moveAdjustedDown => 'ஸ்டாக் சரிபார்ப்பு: பதிவை விட குறைவு';

  @override
  String get moveDamaged => 'சேதமடைந்தது அல்லது கழிக்கப்பட்டது';

  @override
  String get scanModeLabel => 'கடை லேபிள்';

  @override
  String get scanModeRepair => 'புதிய பழுதுபார்ப்பு';

  @override
  String get scanModePurchase => 'போன் வாங்கு';

  @override
  String get scanHintLabel =>
      'ஸ்டிக்கரை ஸ்கேன் செய்து அது அச்சிடப்பட்ட பதிவைத் திறக்கவும்.';

  @override
  String get scanHintRepair =>
      'பிராண்டும் மாடலும் நிரப்பப்பட்ட பழுதுபார்ப்பைத் தொடங்க போனின் பார்கோடை ஸ்கேன் செய்யவும்.';

  @override
  String get scanHintPurchase =>
      'பிராண்டும் மாடலும் நிரப்பப்பட்ட கொள்முதலைத் தொடங்க போனின் பார்கோடை ஸ்கேன் செய்யவும்.';

  @override
  String get enqFollowUpOverdue => 'பின்தொடர்தல் தாமதம்';

  @override
  String get enqOpen => 'திறந்தது';

  @override
  String get enqDealtWith => 'முடிக்கப்பட்டது';

  @override
  String get periodToday => 'இன்று';

  @override
  String get period7 => 'கடந்த 7 நாட்கள்';

  @override
  String get period30 => 'கடந்த 30 நாட்கள்';

  @override
  String get periodMonth => 'இந்த மாதம்';

  @override
  String get periodCustom => 'தனிப்பயன்';

  @override
  String get figTakings => 'வசூல்';

  @override
  String get figTakingsNote => 'முடிந்த பில்கள், செலுத்தப்பட்ட நாளின் தேதியில்';

  @override
  String get figService => 'சர்வீஸ் வருமானம்';

  @override
  String get figServiceNote =>
      'வாடிக்கையாளரிடம் திரும்பிய வேலைகள், வசூலித்த விலையில்';

  @override
  String get figMargin => 'பழைய போன் லாபம்';

  @override
  String get figMarginNote =>
      'விற்பனை விலை கழித்தல் கொள்முதல், பழுது மற்றும் பிற செலவுகள். வசூலின் ஒரு பகுதி, கூடுதல் அல்ல';

  @override
  String get figOutstanding => 'நிலுவை';

  @override
  String get figOutstandingNote =>
      'செலுத்தப்படாத எல்லா பில்களிலும் இப்போது நிலுவையில் உள்ளது — இந்தக் காலத்துக்கு மட்டுமல்ல. நிதி விற்பனைகள் கணக்கில் இல்லை';

  @override
  String get repairWarranty => 'பழுதுபார்ப்பு உத்தரவாதம்';

  @override
  String get repairWarrantyHint =>
      'இறுதி பில்லில் அச்சிடப்படும்; போன் திரும்ப வரும்போது சரிபார்க்கப்படும்.';

  @override
  String get warrantyNone => 'இல்லை';

  @override
  String warrantyDaysN(int days) {
    return '$days நாட்கள்';
  }

  @override
  String warrantyUntil(String date) {
    return '$date வரை உத்தரவாதம்';
  }

  @override
  String warrantyEnded(String date) {
    return 'உத்தரவாதம் $date அன்று முடிந்தது';
  }

  @override
  String warrantyReturning(String date, String order, String until) {
    return 'இங்கே $date அன்று பழுதுபார்க்கப்பட்டது ($order) — $until வரை இன்னும் உத்தரவாதம் உள்ளது.';
  }

  @override
  String get shareReport => 'அறிக்கையைப் பகிர்';

  @override
  String checksTicked(int done, int total) {
    return '$total-இல் $done சரிபார்க்கப்பட்டது';
  }

  @override
  String get beforeItGoesBack => 'திருப்பிக் கொடுக்கும் முன் சரிபார்க்கவும்';

  @override
  String get searchEverythingHint => 'பெயர், எண், IMEI, வேலை அல்லது பில் தேடு';

  @override
  String get searchEverythingTitle => 'எதையும் தேடுங்கள்';

  @override
  String get searchEverythingDetail =>
      'பழுதுபார்ப்புகள், போன்கள், பில்கள், வாடிக்கையாளர்கள், பொருட்கள், விசாரணைகள் — எல்லாம் ஒரே இடத்தில்.';

  @override
  String searchMore(int count) {
    return 'இந்தப் பட்டியலில் இன்னும் $count';
  }

  @override
  String get clear => 'அழி';

  @override
  String get collectedLaterTitle => 'பின்னர் வசூலித்தது';

  @override
  String get paidAtPickup => 'எடுக்கும்போது செலுத்தியது';

  @override
  String howPaidAmount(String amount) {
    return '₹$amount வசூலிக்க வேண்டும் — எப்படிச் செலுத்தப்பட்டது?';
  }

  @override
  String get sendOrderList => 'ஆர்டர் பட்டியலை வாட்ஸ்அப்பில் அனுப்பு';

  @override
  String get sellMakeBill => 'விற்பனை — பில் போடு';

  @override
  String get soldWithoutBill =>
      'பில் இல்லாமல் விற்கப்பட்டது (டீலருக்கு, வேறு இடத்தில்)';

  @override
  String get moveUsedOnRepair => 'பழுதுபார்ப்பில் பயன்படுத்தப்பட்டது';

  @override
  String get usePartFromStock => 'ஸ்டாக்கிலிருந்து பாகம் எடு';

  @override
  String get partsUsed => 'பயன்படுத்திய பாகங்கள்';

  @override
  String partUsedSaved(String part) {
    return '$part ஸ்டாக்கிலிருந்து எடுக்கப்பட்டு இந்த வேலையில் சேர்க்கப்பட்டது';
  }

  @override
  String get noPartsInStock =>
      'பயன்படுத்த ஸ்டாக்கில் எதுவும் இல்லை. பொருட்கள் பக்கத்தில் பாகங்களைச் சேர்க்கவும்.';

  @override
  String get gstRateTitle => 'பில்களில் GST';

  @override
  String get gstRateHint =>
      'உங்கள் விலைகளில் உள்ள GST விகிதம். GSTIN இருந்தால் பில்களில் CGST, SGST காட்டப்படும். பழைய போன்கள் சேர்க்கப்படாது (மார்ஜின் திட்டம்). விகிதத்தை உங்கள் கணக்காளரிடம் உறுதிப்படுத்தவும்.';

  @override
  String get gstOff => 'இல்லை';

  @override
  String get hintBrands =>
      'ஒவ்வொரு உள்வரவு மற்றும் கொள்முதல் படிவத்திலும் காட்டப்படும்.';

  @override
  String get hintSuppliers => 'பொருள் சேர்க்கும்போது காட்டப்படும்.';

  @override
  String get hintColours =>
      'கொள்முதல் மற்றும் பொருள் படிவங்களில் காட்டப்படும்.';

  @override
  String get hintCategories => 'பொருட்கள் பட்டியலைக் குழுவாக்கும்.';

  @override
  String get hintComplaintTypes =>
      'ஜாப் கார்டும் இறுதி பில்லும் இவற்றிலிருந்தே உருவாகும்.';

  @override
  String get hintAccessories =>
      'உள்வரவில் டிக் செய்யப்பட்டு, ஜாப் கார்டில் அச்சிடப்படும்.';

  @override
  String get hintLockTypes => 'சாதனம் வந்தபோது எப்படிப் பூட்டப்பட்டிருந்தது.';

  @override
  String get hintRam => 'கொள்முதல் படிவத்தில் காட்டப்படும்.';

  @override
  String get hintRom => 'கொள்முதல் படிவத்தில் காட்டப்படும்.';

  @override
  String get offlineBanner =>
      'ஆஃப்லைன் — வேலை இந்த போனில் சேமிக்கப்படுகிறது, இணையம் வந்ததும் பதிவேற்றப்படும்.';
}
