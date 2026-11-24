// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'शॉप मैनेजर';

  @override
  String get navDashboard => 'होम';

  @override
  String get navCustomers => 'ग्राहक';

  @override
  String get navSecondHand => 'पुराने मोबाइल';

  @override
  String get navProducts => 'सामान';

  @override
  String get navService => 'सर्विस';

  @override
  String get navSales => 'बिक्री';

  @override
  String get navDuePayments => 'बकाया भुगतान';

  @override
  String get navEnquiries => 'पूछताछ';

  @override
  String get navScanner => 'स्कैनर';

  @override
  String get navLabels => 'लेबल';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get navReports => 'रिपोर्ट';

  @override
  String get navStaff => 'स्टाफ';

  @override
  String get navLogout => 'लॉग आउट';

  @override
  String get tabHome => 'होम';

  @override
  String get tabMobiles => 'मोबाइल';

  @override
  String get tabScan => 'स्कैन';

  @override
  String get tabMore => 'और';

  @override
  String get signInSubtitle => 'अपनी दुकान में साइन इन करें।';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signUp => 'साइन अप करें';

  @override
  String get setUpNewShop => 'नई दुकान बनाएँ';

  @override
  String get forgottenPassword => 'पासवर्ड भूल गए';

  @override
  String get createShopTitle => 'अपनी दुकान सेट करें';

  @override
  String get shopName => 'दुकान का नाम';

  @override
  String get shopPhone => 'फ़ोन';

  @override
  String get shopAddress => 'पता';

  @override
  String get shopGstin => 'GSTIN';

  @override
  String get createShop => 'दुकान बनाएँ';

  @override
  String get language => 'भाषा';

  @override
  String get languageHint =>
      'इस दुकान की भाषा। यहाँ सभी को यही दिखेगी; बाद में सेटिंग्स में बदल सकते हैं।';

  @override
  String get languageSaved => 'भाषा सेव हो गई';

  @override
  String get goodMorning => 'सुप्रभात';

  @override
  String get goodAfternoon => 'नमस्कार';

  @override
  String get goodEvening => 'शुभ संध्या';

  @override
  String greetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get overdueServiceOrders => 'देरी वाले सर्विस ऑर्डर';

  @override
  String get dateTomorrow => 'कल (आने वाला)';

  @override
  String get dateYesterday => 'कल (बीता)';

  @override
  String get dateNextWeek => 'अगले हफ़्ते';

  @override
  String dateInDays(int count) {
    return '$count दिन में';
  }

  @override
  String dateDaysAgo(int count) {
    return '$count दिन पहले';
  }

  @override
  String get navExpenses => 'खर्च';

  @override
  String get expenseAgain => 'फिर से? एक टैप में भर जाएगा';

  @override
  String get expenseNew => 'खर्च जोड़ें';

  @override
  String get expenseEdit => 'खर्च';

  @override
  String get expenseSaved => 'खर्च सेव हुआ';

  @override
  String get expenseDeleteConfirm => 'यह खर्च हटाएँ?';

  @override
  String get expenseOwnerOnly =>
      'सेव होने के बाद खर्च सिर्फ़ मालिक बदल या हटा सकता है।';

  @override
  String get expenseNeedAmount => 'कितना दिया, वह लिखें';

  @override
  String get expenseNeedKind => 'किसके लिए, वह चुनें';

  @override
  String get expenseWhatFor => 'किसके लिए';

  @override
  String get expensePaidHow => 'कैसे दिया';

  @override
  String get expenseDay => 'दिन';

  @override
  String get expenseNote => 'नोट';

  @override
  String get expenseNoteHint => 'जैसे सप्लायर से A54 डिस्प्ले';

  @override
  String get expenseCash => 'नकद';

  @override
  String get expenseKindParts => 'पार्ट्स';

  @override
  String get expenseKindTea => 'चाय-नाश्ता';

  @override
  String get expenseKindRent => 'किराया';

  @override
  String get expenseKindPower => 'बिजली';

  @override
  String get expenseKindSalary => 'तनख़्वाह';

  @override
  String get expenseKindTransport => 'आना-जाना';

  @override
  String get expenseKindSupplies => 'दुकान का सामान';

  @override
  String get expenseKindOther => 'अन्य';

  @override
  String get expensesCouldNotLoad => 'खर्च लोड नहीं हो सके';

  @override
  String get loadingExpenses => 'खर्च ला रहे हैं…';

  @override
  String get expensesEmpty => 'अभी कोई खर्च नहीं';

  @override
  String get expensesEmptyDetail =>
      'दुकान किस चीज़ के पैसे देती है — पार्ट्स, चाय, किराया — लिखें, रिपोर्ट बताएगी कितना बचा।';

  @override
  String get expenseThisMonth => 'इस महीने';

  @override
  String expenseCashPart(String amount) {
    return '$amount नकद';
  }

  @override
  String get reportMoneyOut => 'बाहर गया पैसा';

  @override
  String get reportMoneyOutNone => 'इस समय में कोई खर्च नहीं।';

  @override
  String get reportCashLeft => 'गल्ले में बची नकदी';

  @override
  String get reportCashLeftHint =>
      'बिलों से आई नकदी में से नकद दिए खर्च घटाकर।';

  @override
  String get reportAfterExpenses => 'खर्च के बाद';

  @override
  String get exportExpenses => 'खर्च';

  @override
  String homeSpentToday(String amount) {
    return 'आज $amount खर्च';
  }

  @override
  String get loadingShopDetails => 'दुकान की जानकारी ला रहे हैं…';

  @override
  String get shopDetailsCouldNotLoad => 'दुकान की जानकारी नहीं खुली';

  @override
  String get shopDetailsNoAccount =>
      'यह फ़ोन दुकान के खाते से नहीं जुड़ा है। इंटरनेट चालू करके साइन आउट और फिर साइन इन करें।';

  @override
  String get shopDetailsNotFound => 'दुकान का रिकॉर्ड नहीं मिला।';

  @override
  String get handOverCheck => 'फ़ोन जाँचें';

  @override
  String get handOverPay => 'वे कितना देंगे';

  @override
  String get handOverHowPaid => 'कैसे दिया';

  @override
  String get handOverToCollect => 'अभी लेना है';

  @override
  String get handOverNeedPrice => 'कितना लिया, लिखें (मुफ़्त हो तो 0)';

  @override
  String handOverChecksLeft(int count) {
    return '$count जाँच बाक़ी';
  }

  @override
  String handOverAndCollect(String amount) {
    return 'सौंपें · $amount लें';
  }

  @override
  String get handOverButton => 'फ़ोन सौंपें';

  @override
  String get handOverCard => 'सौंपने से पहले';

  @override
  String get saveAddAnotherPhone => 'सेव करें और एक और फ़ोन जोड़ें';

  @override
  String savedAddAnother(String number) {
    return '$number सेव हुआ — अब अगला फ़ोन';
  }

  @override
  String visitAnotherPhoneFor(String name) {
    return '$name का एक और फ़ोन';
  }

  @override
  String visitSameAs(String number) {
    return '$number वाली ही विज़िट: सबका एक जॉब कार्ड और एक बिल';
  }

  @override
  String get visitPhones => 'इस विज़िट के फ़ोन';

  @override
  String get visitAddPhone => 'एक और फ़ोन जोड़ें';

  @override
  String visitPhoneCount(int count) {
    return '$count फ़ोन, एक जॉब कार्ड और एक बिल';
  }

  @override
  String get saveBuyAnotherFromSeller =>
      'सेव करें, लेबल छापें और इसी विक्रेता से एक और खरीदें';

  @override
  String get buyNextFromSeller => 'अब इसी विक्रेता का अगला फ़ोन';

  @override
  String buyAnotherFrom(String name) {
    return '$name से एक और फ़ोन';
  }

  @override
  String get buyAnotherSameSeller =>
      'विक्रेता, ID और हस्ताक्षर वही: सबका एक घोषणा-पत्र';

  @override
  String get boughtTogether => 'साथ खरीदे गए';

  @override
  String boughtTogetherCount(int count) {
    return 'इस विक्रेता से $count फ़ोन, एक घोषणा-पत्र';
  }

  @override
  String get buyAnotherFromSeller => 'इसी विक्रेता से एक और खरीदें';

  @override
  String billsCount(int count) {
    return '$count बिल';
  }

  @override
  String itemsCount(int count) {
    return '$count आइटम';
  }

  @override
  String get alreadyOnBill => 'पहले से इस बिल पर';

  @override
  String get allOnThisBill => 'सब पहले से इस बिल पर हैं';

  @override
  String leftCount(int count) {
    return '$count बचे';
  }

  @override
  String onShelfCount(int count) {
    return 'शेल्फ़ पर $count';
  }

  @override
  String onlyLeftCount(int count) {
    return 'सिर्फ़ $count बचे — बस इतने ही हैं';
  }

  @override
  String get quantityAtLeastOne => 'कम से कम 1';

  @override
  String walletHoldsOnly(String amount) {
    return 'इनके वॉलेट में ₹$amount ही है';
  }

  @override
  String get splitSayHowMuch => 'हर तरीक़े से कितना आया, वह लिखें';

  @override
  String get downPaymentAtCounter => 'काउंटर पर डाउन पेमेंट';

  @override
  String get downPaymentEmptyMeansNone =>
      'खाली मतलब कोई डाउन पेमेंट नहीं — फ़ाइनेंसर पूरा देगा';

  @override
  String get downPaymentPaidBy => 'डाउन पेमेंट कैसे दिया';

  @override
  String get changeToGiveBack => 'वापस देने वाले पैसे';

  @override
  String draftTotal(String total) {
    return '₹$total · ड्राफ़्ट, अभी कुछ नहीं दिया';
  }

  @override
  String cancelledTotal(String total) {
    return '₹$total · रद्द';
  }

  @override
  String otherMethods(int count) {
    return '$count अन्य';
  }

  @override
  String get billCancelledDone => 'बिल रद्द हुआ';

  @override
  String get billCancelKept => 'बिल रद्द के रूप में रिकॉर्ड में रहेगा।';

  @override
  String refundHow(String amount) {
    return '$amount दिया गया था — वापस कैसे दिया?';
  }

  @override
  String get refundToWallet => 'उनके वॉलेट में रखें';

  @override
  String get cancelNeedReason => 'कारण लिखें — यह रिकॉर्ड में जाएगा';

  @override
  String advanceWhatHappened(String amount) {
    return '$amount का एडवांस';
  }

  @override
  String get advanceGivenBack => 'वापस दिया';

  @override
  String get advanceKeptAsFee => 'फ़ीस के रूप में रखा';

  @override
  String get returnNeedReason => 'कारण लिखें — यह रिकॉर्ड में जाएगा';

  @override
  String get changeGiveBack => 'वापस देना है';

  @override
  String enquiryMarkAs(String status) {
    return '$status चिह्नित करें';
  }

  @override
  String get enquiryMarkAsBody =>
      'पूछताछ निपट जाएगी और खुली सूची से हट जाएगी। फिर से खोली जा सकती है।';

  @override
  String get makeABill => 'बिल बनाएँ';

  @override
  String get stocktakeTypeCount => 'शेल्फ़ पर जितना है लिखें — खाली हो तो 0';

  @override
  String get purchaseResumed => 'अधूरी ख़रीद से जारी';

  @override
  String get startFresh => 'नए सिरे से शुरू करें';

  @override
  String get discardPurchaseTitle => 'यह ख़रीद हटाएँ?';

  @override
  String get discardPurchaseBody => 'पाँचों चरणों में लिखा सब मिट जाएगा।';

  @override
  String get discardPurchaseYes => 'हटाएँ';

  @override
  String daysCount(int count) {
    return '$count दिन';
  }

  @override
  String get today => 'आज';

  @override
  String get completedBillsOnly => 'सिर्फ़ पूरे हुए बिल';

  @override
  String get quickActions => 'तुरंत काम';

  @override
  String get newServiceOrder => 'नया सर्विस ऑर्डर';

  @override
  String get newPurchase => 'नई खरीद';

  @override
  String get newSale => 'नई बिक्री';

  @override
  String get tilePendingOrders => 'बाकी ऑर्डर';

  @override
  String get tileOverdue => 'देरी';

  @override
  String get tileDueToday => 'आज देने हैं';

  @override
  String get tileLowStock => 'कम स्टॉक';

  @override
  String get tileDuePayments => 'बकाया भुगतान';

  @override
  String get tilePendingBills => 'अधूरे बिल';

  @override
  String get tileOpenEnquiries => 'खुली पूछताछ';

  @override
  String get tileCustomers => 'ग्राहक';

  @override
  String get tileNewToday => 'आज नए';

  @override
  String get recentOrders => 'हाल के ऑर्डर';

  @override
  String get nothingTakenInYet => 'अभी कुछ नहीं आया';

  @override
  String get couldNotBeRead => 'पढ़ा नहीं जा सका';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सेव करें';

  @override
  String get signUpSubtitle => 'खाता बनाएँ, फिर अपनी दुकान सेट करें।';

  @override
  String get createAccount => 'खाता बनाएँ';

  @override
  String get haveAccount => 'मेरा खाता पहले से है';

  @override
  String resetLinkSent(String email) {
    return '$email पर रीसेट लिंक भेज दिया गया';
  }

  @override
  String get customerBookFailed => 'ग्राहक सूची लोड नहीं हो सकी';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get searchNameOrNumber => 'नाम या नंबर';

  @override
  String get add => 'जोड़ें';

  @override
  String addNamed(String what) {
    return '$what जोड़ें';
  }

  @override
  String get noNameGiven => 'नाम नहीं दिया';

  @override
  String get nobodyInBookYet => 'अभी कोई नहीं';

  @override
  String noMatchFor(String query) {
    return '\"$query\" से कुछ नहीं मिला';
  }

  @override
  String noCustomer(String id) {
    return 'ग्राहक $id नहीं है';
  }

  @override
  String get edit => 'बदलें';

  @override
  String get details => 'विवरण';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get secondNumber => 'दूसरा नंबर';

  @override
  String get name => 'नाम';

  @override
  String get address => 'पता';

  @override
  String get notes => 'नोट्स';

  @override
  String get soldToTheShop => 'दुकान को बेचा';

  @override
  String get nothingYet => 'अभी कुछ नहीं।';

  @override
  String wallet(String amount) {
    return 'वॉलेट ₹$amount';
  }

  @override
  String get addCredit => 'पैसे जोड़ें';

  @override
  String get spend => 'खर्च';

  @override
  String get noWalletMoves => 'वॉलेट में कोई लेन-देन नहीं।';

  @override
  String get addCreditToWallet => 'वॉलेट में पैसे जोड़ें';

  @override
  String get spendFromWallet => 'वॉलेट से खर्च';

  @override
  String get amount => 'रकम';

  @override
  String get whatItIsFor => 'किस लिए';

  @override
  String get required => 'ज़रूरी';

  @override
  String get apply => 'लागू करें';

  @override
  String walletIsNow(String amount) {
    return 'वॉलेट अब ₹$amount';
  }

  @override
  String get addACustomer => 'ग्राहक जोड़ें';

  @override
  String get discardThisDraft => 'यह ड्राफ़्ट हटाएँ';

  @override
  String get howTheShopFindsThem => 'दुकान उन्हें फिर कैसे ढूँढेगी';

  @override
  String get nameOptionalHelp => 'वैकल्पिक — सिर्फ़ नंबर भी ग्राहक है';

  @override
  String savedNamed(String what) {
    return '$what सेव हो गया';
  }

  @override
  String noSecondHandRecord(String id) {
    return 'पुराने मोबाइल का रिकॉर्ड $id नहीं है।';
  }

  @override
  String get deletedLabelNote =>
      'हटाए गए रिकॉर्ड का लेबल स्कैन करने पर यही दिखता है — लेबल नंबर नोट कर लेना बेहतर है।';

  @override
  String gradeNamed(String grade) {
    return 'ग्रेड $grade';
  }

  @override
  String labelNamed(String number) {
    return 'लेबल $number';
  }

  @override
  String get device => 'डिवाइस';

  @override
  String get money => 'पैसा';

  @override
  String get repairs => 'मरम्मत';

  @override
  String get condition => 'हालत';

  @override
  String get seller => 'बेचने वाला';

  @override
  String get brand => 'ब्रांड';

  @override
  String get model => 'मॉडल';

  @override
  String get variant => 'वेरिएंट';

  @override
  String get colour => 'रंग';

  @override
  String get imei2 => 'IMEI 2';

  @override
  String get serial => 'सीरियल';

  @override
  String get paidToSeller => 'बेचने वाले को दिया';

  @override
  String get otherCosts => 'अन्य खर्च';

  @override
  String get totalCost => 'कुल लागत';

  @override
  String get asking => 'माँग रहे हैं';

  @override
  String get expectedProfit => 'अनुमानित मुनाफ़ा';

  @override
  String get realisedProfit => 'मिला मुनाफ़ा';

  @override
  String get notSoldYet => 'अभी बिका नहीं';

  @override
  String get storedGrade => 'दर्ज ग्रेड';

  @override
  String get fromTheChecklist => 'चेकलिस्ट के अनुसार';

  @override
  String get answered => 'जवाब दिए';

  @override
  String outOf(String done, String total) {
    return '$total में से $done';
  }

  @override
  String get setByHand => 'हाथ से सेट किया';

  @override
  String get criticalFaultsOpen => 'गंभीर खराबी बाकी';

  @override
  String get notGraded => 'ग्रेड नहीं';

  @override
  String get idProof => 'पहचान पत्र';

  @override
  String get notRecorded => 'दर्ज नहीं';

  @override
  String get signed => 'हस्ताक्षर';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get backOnTheShelf => 'वापस शेल्फ़ पर';

  @override
  String get movedToTheBench => 'मरम्मत के लिए भेजा';

  @override
  String get repairFinished => 'मरम्मत पूरी';

  @override
  String get sendToTheBench => 'मरम्मत के लिए भेजें';

  @override
  String get markSold => 'बिका हुआ चिह्नित करें';

  @override
  String get assignAndPrintLabel => 'लेबल देकर प्रिंट करें';

  @override
  String get takeInAHandset => 'मोबाइल ख़रीदें';

  @override
  String get editPurchase => 'खरीद बदलें';

  @override
  String get imeiAndSerial => 'IMEI और सीरियल';

  @override
  String get pricing => 'क़ीमत';

  @override
  String get repairAndRefurb => 'मरम्मत और रीफ़र्बिशमेंट';

  @override
  String get addARepair => 'मरम्मत जोड़ें';

  @override
  String get stillOnTheBench => 'अभी मरम्मत में';

  @override
  String get stillOnTheBenchHint =>
      'मरम्मत पूरी होने तक बिक्री सूची में नहीं आएगा।';

  @override
  String get conditionAndGrade => 'हालत और ग्रेड';

  @override
  String get photos => 'फ़ोटो';

  @override
  String get frontView => 'सामने का फ़ोटो';

  @override
  String photoNumbered(String number) {
    return 'फ़ोटो $number';
  }

  @override
  String get addTheFrontView => 'सामने का फ़ोटो जोड़ें';

  @override
  String get addAPhoto => 'फ़ोटो जोड़ें';

  @override
  String get sellerSigned => 'बेचने वाले ने घोषणा पर हस्ताक्षर किए';

  @override
  String get sellerSignedHint =>
      'सिर्फ़ प्रिंट के लिए ज़रूरी — बिना हस्ताक्षर की घोषणा सबूत जैसी लगती है।';

  @override
  String get saveAndPrint => 'सेव करके प्रिंट करें';

  @override
  String get repairDoneBeforeResale => 'बिक्री से पहले की मरम्मत';

  @override
  String get whatWasDone => 'क्या किया गया';

  @override
  String get cost => 'लागत';

  @override
  String get worthALook => 'ध्यान देने लायक';

  @override
  String get notGradedNothingAnswered => 'ग्रेड नहीं — अभी कोई जवाब नहीं';

  @override
  String criticalNamed(String faults) {
    return 'गंभीर: $faults';
  }

  @override
  String get overrideLabel => 'बदलें: ';

  @override
  String get criticalCapsGrade => 'गंभीर — ग्रेड सीमित करता है';

  @override
  String costNamed(String amount) {
    return 'लागत ₹$amount';
  }

  @override
  String expectedProfitNamed(String amount) {
    return 'अनुमानित मुनाफ़ा ₹$amount';
  }

  @override
  String get stockCouldNotBeLoaded => 'स्टॉक लोड नहीं हो सका';

  @override
  String get searchStock => 'ब्रांड, मॉडल, IMEI, लेबल या बेचने वाला';

  @override
  String askingTotal(String amount) {
    return 'माँग ₹$amount';
  }

  @override
  String nothingInTab(String tab) {
    return '$tab में कुछ नहीं';
  }

  @override
  String get takeAHandsetIn => 'नीचे के बटन से मोबाइल ख़रीदें।';

  @override
  String get stockSearchCovers =>
      'खोज में ब्रांड, मॉडल, IMEI, लेबल नंबर और बेचने वाला शामिल है।';

  @override
  String get takeIn => 'ख़रीदें';

  @override
  String soldMade(String price, String profit) {
    return 'बिका ₹$price · मुनाफ़ा ₹$profit';
  }

  @override
  String askingCost(String asking, String cost) {
    return 'माँग ₹$asking · लागत ₹$cost';
  }

  @override
  String declarationQueued(String what) {
    return '$what सेव हो गया — घोषणा प्रिंट के लिए भेजी';
  }

  @override
  String addedToShopLists(int count) {
    return 'दुकान की सूचियों में जोड़ा: $count नई वैल्यू';
  }

  @override
  String noProduct(String id) {
    return 'सामान $id नहीं है।';
  }

  @override
  String get deletedShelfLabelNote =>
      'हटाए गए सामान का शेल्फ़ लेबल स्कैन करने पर यही दिखता है — लेबल नंबर नोट कर लेना बेहतर है।';

  @override
  String get outOfStockCannotSell => 'स्टॉक खत्म — नया आने तक बेच नहीं सकते।';

  @override
  String atOrBelowReorder(String level) {
    return 'रीऑर्डर स्तर $level पर या नीचे';
  }

  @override
  String historyDisagreesStock(String ledger, String count) {
    return 'इतिहास $ledger बनता है, $count नहीं। इस रिकॉर्ड को देखना होगा।';
  }

  @override
  String get whatItIs => 'यह क्या है';

  @override
  String get category => 'श्रेणी';

  @override
  String get notCategorised => 'कोई श्रेणी नहीं';

  @override
  String get supplier => 'सप्लायर';

  @override
  String get costPrice => 'लागत क़ीमत';

  @override
  String get sellingPrice => 'बिक्री क़ीमत';

  @override
  String get printedMaximum => 'प्रिंटेड अधिकतम';

  @override
  String get printedMaximumMrp => 'प्रिंटेड अधिकतम (MRP)';

  @override
  String get profitPerUnit => 'प्रति नग मुनाफ़ा';

  @override
  String profitPerUnitNamed(String amount) {
    return 'प्रति नग मुनाफ़ा ₹$amount';
  }

  @override
  String get stockAtCost => 'स्टॉक लागत पर';

  @override
  String get stockAtRetail => 'स्टॉक बिक्री क़ीमत पर';

  @override
  String get reordering => 'रीऑर्डर';

  @override
  String get reorderLevel => 'रीऑर्डर स्तर';

  @override
  String get noReorderLevelSet => 'सेट नहीं — सिर्फ़ स्टॉक खत्म होने पर दिखेगा';

  @override
  String get suggestedOrder => 'सुझाया ऑर्डर';

  @override
  String get stockHistory => 'स्टॉक इतिहास';

  @override
  String get noStockHistory =>
      'अभी कुछ नहीं। पहली डिलीवरी दर्ज करें, फिर इतिहास बताएगा स्टॉक कहाँ से आया।';

  @override
  String get receive => 'आया';

  @override
  String get stockTake => 'स्टॉक गिनती';

  @override
  String get damaged => 'खराब';

  @override
  String reprintLabel(String number) {
    return 'लेबल $number फिर प्रिंट करें';
  }

  @override
  String nowOnTheShelf(String count) {
    return 'अब $count शेल्फ़ पर';
  }

  @override
  String savedReceiveStock(String what) {
    return '$what सेव हो गया — गिनती उसके पेज से स्टॉक दर्ज करके सेट करें';
  }

  @override
  String get addAProduct => 'सामान जोड़ें';

  @override
  String get editProduct => 'सामान बदलें';

  @override
  String get whatTheCounterSearches => 'काउंटर पर जिससे खोजा जाए';

  @override
  String get variantFits => 'वेरिएंट (किस मॉडल के लिए, साइज़)';

  @override
  String get whenToReorder => 'कब रीऑर्डर करें';

  @override
  String get reorderLevelHelp =>
      'इस सामान पर कम स्टॉक अलर्ट नहीं चाहिए तो खाली छोड़ें';

  @override
  String onTheShelfNow(String count) {
    return 'अभी शेल्फ़ पर: $count। स्टॉक सामान के पेज से, कारण के साथ बदलता है — इस फ़ॉर्म से नहीं।';
  }

  @override
  String get newProductStartsAtZero =>
      'नया सामान शून्य से शुरू होता है। पहली डिलीवरी उसके पेज से दर्ज होती है, ताकि इतिहास बताए स्टॉक कहाँ से आया।';

  @override
  String get photo => 'फ़ोटो';

  @override
  String get mainPhoto => 'मुख्य फ़ोटो';

  @override
  String get addAnother => 'एक और जोड़ें';

  @override
  String get productsCouldNotBeLoaded => 'सामान लोड नहीं हो सका';

  @override
  String get searchProducts => 'नाम, ब्रांड, श्रेणी, SKU या सप्लायर';

  @override
  String costRetail(String cost, String retail) {
    return 'लागत ₹$cost · बिक्री ₹$retail';
  }

  @override
  String get nothingOnTheListYet =>
      'सूची अभी खाली है। नीचे के बटन से सामान जोड़ें।';

  @override
  String reorderAt(String level) {
    return '$level पर रीऑर्डर';
  }

  @override
  String get noReorderLevel => 'रीऑर्डर स्तर सेट नहीं';

  @override
  String get skuHelp => 'दुकान का अपना कोड — दुकान का लेबल नहीं';

  @override
  String noServiceOrder(String id) {
    return 'सर्विस ऑर्डर $id नहीं है।';
  }

  @override
  String get deletedJobCardNote =>
      'हटाए गए ऑर्डर का जॉब कार्ड स्कैन करने पर यही दिखता है — ऑर्डर नंबर नोट कर लेना बेहतर है।';

  @override
  String get customer => 'ग्राहक';

  @override
  String get lock => 'लॉक';

  @override
  String get unlockWith => 'अनलॉक करें';

  @override
  String get leftWithIt => 'साथ में दिया';

  @override
  String get nothingValue => 'कुछ नहीं';

  @override
  String get complaints => 'शिकायतें';

  @override
  String get estimateQuoted => 'दिया गया अनुमान';

  @override
  String get rawMaterial => 'सामान';

  @override
  String get outsideLabour => 'बाहर का काम';

  @override
  String get costs => 'खर्च';

  @override
  String get profitAtEstimate => 'अनुमान पर मुनाफ़ा';

  @override
  String get charged => 'लिया गया';

  @override
  String get notChargedYet => 'अभी नहीं लिया';

  @override
  String get profitMade => 'हुआ मुनाफ़ा';

  @override
  String get schedule => 'समय';

  @override
  String get cameIn => 'आया';

  @override
  String get promised => 'वादा';

  @override
  String get handedBack => 'वापस दिया';

  @override
  String get technician => 'टेक्नीशियन';

  @override
  String get nobodyYet => 'अभी कोई नहीं';

  @override
  String get notSet => 'सेट नहीं';

  @override
  String handedBackOn(String date) {
    return '$date को वापस दिया। इस पर कुछ बाकी नहीं।';
  }

  @override
  String get status => 'स्थिति';

  @override
  String get completedIsNotHere =>
      'पूरा हुआ यहाँ किसी के लिए नहीं है — नीचे की चेकलिस्ट पास करने पर ही फ़ोन वापस जाता है।';

  @override
  String statusNamed(String status) {
    return 'स्थिति: $status';
  }

  @override
  String get preDeliveryChecklist => 'देने से पहले की चेकलिस्ट';

  @override
  String get noChecklistConfigured =>
      'सेटिंग्स में कोई चेकलिस्ट नहीं है, इसलिए फ़ोन देने से पहले जाँचने को कुछ नहीं।';

  @override
  String savedJobCard(String what) {
    return '$what सेव हो गया — जॉब कार्ड प्रिंट के लिए भेजा';
  }

  @override
  String get takeInARepair => 'मरम्मत के लिए लें';

  @override
  String editNamed(String what) {
    return '$what बदलें';
  }

  @override
  String get findsWhoeverBeenHere => 'पहले आ चुके लोगों को ढूँढता है';

  @override
  String get patternAs => 'पैटर्न, जैसे 1-2-3-6-9';

  @override
  String get code => 'कोड';

  @override
  String get leftWithTheDevice => 'डिवाइस के साथ दिया';

  @override
  String get findAnIssue => 'खराबी खोजने के लिए लिखें';

  @override
  String get issuesAndComplaints => 'खराबी और शिकायतें';

  @override
  String get whatTheCustomerSaid => 'ग्राहक ने क्या कहा';

  @override
  String get estimateAndSchedule => 'अनुमान और समय';

  @override
  String costsProfitNamed(String costs, String profit) {
    return 'खर्च ₹$costs · अनुमान पर मुनाफ़ा ₹$profit';
  }

  @override
  String get deviceCameIn => 'डिवाइस आया';

  @override
  String get promisedToCustomer => 'ग्राहक से वादा';

  @override
  String get nobodyOnThatNumber =>
      'उस नंबर पर कोई नहीं — ऑर्डर में यहाँ लिखा नंबर और नाम रहेगा।';

  @override
  String get serviceOrdersCouldNotLoad => 'सर्विस ऑर्डर लोड नहीं हो सके';

  @override
  String get searchServiceOrders => 'ऑर्डर नंबर, ग्राहक, डिवाइस या IMEI';

  @override
  String get noComplaintRecorded => 'कोई शिकायत दर्ज नहीं';

  @override
  String get notSetTitle => 'सेट नहीं';

  @override
  String stockSummary(String count, String cost, String asking) {
    return '$count मौजूद · लागत ₹$cost · माँग ₹$asking';
  }

  @override
  String productSummary(int lines, int units, String cost, String retail) {
    return '$lines सामान · $units नग · लागत ₹$cost · बिक्री ₹$retail';
  }

  @override
  String get nothingOutstanding => 'कुछ बकाया नहीं';

  @override
  String get financedNotCountedHere =>
      'फ़ाइनेंस वाली बिक्री यहाँ नहीं गिनी जाती — उन ग्राहकों पर दुकान का कुछ बकाया नहीं।';

  @override
  String owedByCustomers(String total, int count) {
    return '$count ग्राहकों पर ₹$total बकाया';
  }

  @override
  String get financedNotHere =>
      'फ़ाइनेंस वाली बिक्री यहाँ नहीं: ग्राहक पर कुछ बकाया नहीं, और फ़ाइनेंसर का हिसाब अलग है।';

  @override
  String oldestDays(int days) {
    return 'सबसे पुराना $days दिन';
  }

  @override
  String billedPaidMethod(String total, String paid, String method) {
    return '₹$total बिल · ₹$paid चुकाया · $method';
  }

  @override
  String get openTheCustomer => 'ग्राहक खोलें';

  @override
  String noSale(String id) {
    return 'बिक्री $id नहीं है';
  }

  @override
  String get draftNothingOffShelf => 'ड्राफ़्ट — शेल्फ़ से कुछ नहीं निकला';

  @override
  String get completedStatus => 'पूरा हुआ';

  @override
  String get cancelledStatus => 'रद्द';

  @override
  String get draftStatus => 'ड्राफ़्ट';

  @override
  String get doneStatus => 'हो गया';

  @override
  String get items => 'आइटम';

  @override
  String get bill => 'बिल';

  @override
  String get gross => 'कुल';

  @override
  String get discount => 'छूट';

  @override
  String get total => 'कुल राशि';

  @override
  String get paid => 'चुकाया';

  @override
  String get fromTheWallet => 'वॉलेट से';

  @override
  String get customerOwes => 'ग्राहक पर बकाया';

  @override
  String get balance => 'बाकी';

  @override
  String nothingFinancedThrough(String method) {
    return 'कुछ नहीं — $method से फ़ाइनेंस';
  }

  @override
  String get finishThisBill => 'यह बिल पूरा करें';

  @override
  String collectAmount(Object amount) {
    return '₹$amount लें';
  }

  @override
  String get cancelThisBill => 'यह बिल रद्द करें';

  @override
  String get printInvoice => 'बिल प्रिंट करें';

  @override
  String invoiceQueued(String number) {
    return 'बिल $number प्रिंट के लिए भेजा';
  }

  @override
  String collectedStillOwed(String amount, String remaining) {
    return '₹$amount लिया — ₹$remaining अभी बाकी';
  }

  @override
  String collectedSettled(String amount) {
    return '₹$amount लिया — पूरा हुआ';
  }

  @override
  String get cancelledHandsetsBack => 'रद्द — मोबाइल वापस शेल्फ़ पर';

  @override
  String get draftCancelled => 'ड्राफ़्ट रद्द';

  @override
  String get collectFromCustomer => 'ग्राहक से लें';

  @override
  String owedPartPaymentsFine(String owed) {
    return '₹$owed बकाया — आंशिक भुगतान ठीक है';
  }

  @override
  String get collect => 'लें';

  @override
  String get handsetsGoBack =>
      'इस बिल के मोबाइल वापस शेल्फ़ पर जाएँगे। बिल रद्द चिह्नित करके रखा जाएगा।';

  @override
  String get nothingToPutBack =>
      'शेल्फ़ से कुछ नहीं निकला, इसलिए वापस रखने को कुछ नहीं।';

  @override
  String get why => 'क्यों';

  @override
  String get goesOnTheRecord => 'रिकॉर्ड में जाएगा';

  @override
  String get keepIt => 'रहने दें';

  @override
  String get keptAsDraft => 'ड्राफ़्ट में रखा — शेल्फ़ से कुछ नहीं निकला';

  @override
  String get newSaleTitle => 'नई बिक्री';

  @override
  String get editBill => 'बिल बदलें';

  @override
  String get closeWithoutSaving => 'बिना सेव किए बंद करें';

  @override
  String get addFromStock => 'स्टॉक से जोड़ें';

  @override
  String get addALine => 'लाइन जोड़ें';

  @override
  String get method => 'तरीका';

  @override
  String get paidAtTheCounter => 'काउंटर पर चुकाया';

  @override
  String get ofWhichFromWallet => 'वॉलेट से भी';

  @override
  String walletCovers(String balance, String covers) {
    return 'वॉलेट में ₹$balance — इस बिल का ₹$covers कवर करेगा';
  }

  @override
  String get billSummary => 'बिल सारांश';

  @override
  String get keepAsDraft => 'ड्राफ़्ट रखें';

  @override
  String get completeSale => 'बिक्री पूरी करें';

  @override
  String get nobodyOnThatNumberBill =>
      'उस नंबर पर कोई नहीं — बिल में यहाँ लिखा नंबर रहेगा।';

  @override
  String get inStock => 'स्टॉक में';

  @override
  String get nothingSellable => 'पुराने स्टॉक में बेचने लायक कुछ नहीं।';

  @override
  String get notSellable => 'बेचने लायक नहीं';

  @override
  String get salesCouldNotBeLoaded => 'बिक्री लोड नहीं हो सकी';

  @override
  String get searchSales => 'बिल, ग्राहक, आइटम या IMEI';

  @override
  String get drafts => 'ड्राफ़्ट';

  @override
  String get all => 'सब';

  @override
  String owedByCustomersShort(String amount) {
    return 'ग्राहकों पर ₹$amount बकाया';
  }

  @override
  String get noBillsHereYet => 'यहाँ अभी कोई बिल नहीं';

  @override
  String financedOwesNothing(String total) {
    return '₹$total · फ़ाइनेंस, ग्राहक पर कुछ नहीं';
  }

  @override
  String totalStillOwed(String total, String balance) {
    return '₹$total · ₹$balance बाकी';
  }

  @override
  String totalPaid(String total) {
    return '₹$total · चुकाया';
  }

  @override
  String keptAsDraftItems(int count) {
    return 'ड्राफ़्ट में रखा — शेल्फ़ से कुछ नहीं निकला ($count आइटम)';
  }

  @override
  String billStillOwed(String balance) {
    return ', ₹$balance बाकी';
  }

  @override
  String get addAProductLine => 'सामान जोड़ें';

  @override
  String get payment => 'भुगतान';

  @override
  String noEnquiry(String id) {
    return 'पूछताछ $id नहीं है';
  }

  @override
  String get whoAsked => 'किसने पूछा';

  @override
  String get takenBy => 'किसने लिया';

  @override
  String get whatTheyAsked => 'क्या पूछा';

  @override
  String get about => 'किस बारे में';

  @override
  String get inTheirWords => 'उन्हीं के शब्दों में';

  @override
  String get theirBudget => 'उनका बजट';

  @override
  String get theyDidNotSay => 'नहीं बताया';

  @override
  String get quoted => 'बताई क़ीमत';

  @override
  String get notQuoted => 'क़ीमत नहीं बताई';

  @override
  String quotedAgainstBudget(String quoted, String budget) {
    return '₹$budget बजट पर ₹$quoted बताया।';
  }

  @override
  String get followUp => 'फ़ॉलो-अप';

  @override
  String get askedOn => 'पूछा गया';

  @override
  String get ringBack => 'वापस कॉल करें';

  @override
  String get dealtWith => 'निपटाया';

  @override
  String get whatItBecame => 'क्या बना';

  @override
  String get setAFollowUp => 'फ़ॉलो-अप सेट करें';

  @override
  String get changeTheFollowUp => 'फ़ॉलो-अप बदलें';

  @override
  String ringBackOn(String date) {
    return '$date को वापस कॉल करें';
  }

  @override
  String savedColon(String what) {
    return 'सेव: $what';
  }

  @override
  String get recordAnEnquiry => 'पूछताछ दर्ज करें';

  @override
  String get editEnquiry => 'पूछताछ बदलें';

  @override
  String get pointIsRingingBack => 'इसे दर्ज करने का मतलब ही वापस कॉल करना है';

  @override
  String get nameOptionalEnough => 'वैकल्पिक — सिर्फ़ नंबर काफ़ी है';

  @override
  String get inTheirWordsHelp =>
      'जितना हो सके उन्हीं के शब्दों में — इसी से रिकॉर्ड काम का बनता है';

  @override
  String get brandIfNamed => 'ब्रांड, अगर बताया हो';

  @override
  String get modelIfNamed => 'मॉडल, अगर बताया हो';

  @override
  String get whatTheyWouldSpend => 'उन्होंने कितना खर्च करने को कहा';

  @override
  String get leaveEmptyIfNotSaid => 'न बताया हो तो खाली छोड़ें';

  @override
  String get whatTheyWereQuoted => 'उन्हें क्या क़ीमत बताई';

  @override
  String get ringThemBackOn => 'इन्हें वापस कॉल करें';

  @override
  String get notSetWillNotComeUp => 'सेट नहीं — यह अपने आप फिर नहीं आएगा';

  @override
  String get noFollowUpNeeded => 'फ़ॉलो-अप की ज़रूरत नहीं';

  @override
  String get enquiriesCouldNotLoad => 'पूछताछ लोड नहीं हो सकी';

  @override
  String get searchEnquiries => 'ग्राहक, नंबर, डिवाइस या जो पूछा';

  @override
  String get record => 'दर्ज करें';

  @override
  String get noFollowUpSet => 'फ़ॉलो-अप सेट नहीं';

  @override
  String ringBackNamed(String when) {
    return '$when वापस कॉल करें';
  }

  @override
  String get cameraNotWired =>
      'कैमरा स्कैन अभी नहीं जुड़ा है। नंबर टाइप करें — नियम वही रहेंगे।';

  @override
  String get labelNumberOrImei => 'लेबल नंबर या IMEI';

  @override
  String get labelIsFiveDigits =>
      'दुकान का लेबल पाँच अंकों का; IMEI चौदह से सोलह';

  @override
  String get lookItUp => 'ढूँढें';

  @override
  String labelNotInRegistry(String number) {
    return 'लेबल $number रजिस्टर में नहीं है';
  }

  @override
  String get nothingPrintedUnder =>
      'उस नंबर पर कुछ प्रिंट नहीं हुआ। स्टिकर का नंबर जाँचें या रजिस्टर में देखें।';

  @override
  String get openTheRegistry => 'रजिस्टर खोलें';

  @override
  String get notANumberShopUses => 'यह नंबर दुकान का नहीं है';

  @override
  String get nothingWasScanned => 'कुछ स्कैन नहीं हुआ।';

  @override
  String scannedNeither(String raw) {
    return '\"$raw\" स्कैन हुआ। दुकान का लेबल पाँच अंक, IMEI चौदह से सोलह — यह दोनों नहीं, शायद डिब्बे का बारकोड है।';
  }

  @override
  String get noTitleOnLabel => 'लेबल पर कोई नाम नहीं';

  @override
  String get changedSincePrinted =>
      'इस स्टिकर के प्रिंट होने के बाद बदला — ऊपर के मान मौजूदा हैं।';

  @override
  String get printedByNewerBuild =>
      'यह लेबल ऐप के ऐसे वर्शन ने प्रिंट किया जिसे यह नहीं समझता, इसलिए खोलने को कुछ नहीं। ऊपर जो है वही प्रिंट हुआ था।';

  @override
  String get recordBehindLabelGone =>
      'इस लेबल का रिकॉर्ड नहीं है। ऊपर जो है वही उस पर प्रिंट हुआ था।';

  @override
  String get notInDeviceTable =>
      'डिवाइस टेबल में नहीं — ब्रांड और मॉडल टाइप करने होंगे।';

  @override
  String looksLikeDevice(String device) {
    return '$device जैसा लगता है। फ़ॉर्म वही भरकर खुलेगा, बदला भी जा सकता है।';
  }

  @override
  String get factoryImeiNotLabel =>
      'यह फ़ैक्ट्री IMEI है, दुकान का लेबल नहीं — लंबाई से ही पता चल जाता है।';

  @override
  String get registryCouldNotLoad => 'लेबल रजिस्टर लोड नहीं हो सका';

  @override
  String nextLabel(String number) {
    return 'अगला लेबल: $number';
  }

  @override
  String get oneCounterExplainer =>
      'नंबर पूरी दुकान के लिए एक ही काउंटर से आते हैं, इसलिए दो लोग एक साथ देने पर भी एक ही नंबर नहीं मिलेगा। लेबल 26001 से शुरू होते हैं।';

  @override
  String get searchLabels => 'लेबल नंबर, रिकॉर्ड या जो प्रिंट हुआ';

  @override
  String get nothingPrintedYet =>
      'अभी कुछ प्रिंट नहीं हुआ। लेबल किसी रिकॉर्ड से दिया जाता है — मोबाइल या मरम्मत खोलकर प्रिंट करें।';

  @override
  String noLabelMatching(String query) {
    return '\"$query\" से कोई लेबल नहीं';
  }

  @override
  String get unreadableKind => 'अज्ञात प्रकार';

  @override
  String reprintedTimes(String count) {
    return '$count× दोबारा प्रिंट';
  }

  @override
  String stickerOutOfDate(String fields) {
    return 'स्टिकर पुराना: $fields';
  }

  @override
  String get recordGoneShowingPrinted =>
      'रिकॉर्ड नहीं — जो प्रिंट हुआ वही दिख रहा है';

  @override
  String get printThisLabelAgain => 'यह लेबल फिर प्रिंट करें';

  @override
  String get openTheRecord => 'रिकॉर्ड खोलें';

  @override
  String labelSentToPrinter(String number) {
    return 'लेबल $number प्रिंटर को भेजा';
  }

  @override
  String get nothingRegisteredUnder =>
      'उस नंबर पर कुछ दर्ज नहीं है। अगर यह दुकान का स्टिकर है, तो काउंटर पर नंबर बताएँ।';

  @override
  String get whatThisIs => 'यह क्या है';

  @override
  String get price => 'क़ीमत';

  @override
  String get someDetailsChanged =>
      'इस लेबल के प्रिंट होने के बाद कुछ विवरण बदले हैं। यहाँ जो दिख रहा है वह मौजूदा है।';

  @override
  String get shownAsRecorded => 'दुकान में अभी जैसा दर्ज है वैसा दिख रहा है।';

  @override
  String get askAtTheCounter =>
      'लेबल पर यही प्रिंट हुआ था। और जानकारी के लिए काउंटर पर पूछें।';

  @override
  String openNothingClosed(String open) {
    return '$open खुली · अभी कुछ बंद नहीं';
  }

  @override
  String openWonOfClosed(String open, String won, String closed, String rate) {
    return '$open खुली · बंद $closed में से $won बिज़नेस बनी ($rate%)';
  }

  @override
  String changedSinceStickerFields(String fields) {
    return 'इस स्टिकर के प्रिंट होने के बाद बदला: $fields। ऊपर के मान मौजूदा हैं।';
  }

  @override
  String get factoryImeiIntake =>
      'यह फ़ैक्ट्री IMEI है, दुकान का लेबल नहीं — लंबाई से ही फ़र्क़ पता चलता है। क्या नया लेना है?';

  @override
  String figuresAreShort(String areas) {
    return 'ये आँकड़े अधूरे हैं: $areas पढ़ा नहीं जा सका। यह रिपोर्ट दर्ज न करें।';
  }

  @override
  String get activity => 'गतिविधि';

  @override
  String get billsCompleted => 'पूरे हुए बिल';

  @override
  String get billsCancelled => 'रद्द बिल';

  @override
  String get jobsTakenIn => 'लिए गए काम';

  @override
  String get jobsCompleted => 'पूरे हुए काम';

  @override
  String get handsetsBought => 'ख़रीदे मोबाइल';

  @override
  String get handsetsSold => 'बेचे मोबाइल';

  @override
  String get customersAdded => 'जोड़े गए ग्राहक';

  @override
  String get howMarginMadeUp => 'मोबाइल का मुनाफ़ा कैसे बना';

  @override
  String soldForAmount(String amount) {
    return '₹$amount में बिका';
  }

  @override
  String costPurchaseRepairs(String amount) {
    return 'लागत ₹$amount — ख़रीद, मरम्मत और बाक़ी खर्च';
  }

  @override
  String get nothingHappened => 'इस अवधि में कुछ नहीं हुआ।';

  @override
  String fromRecords(int count) {
    return '$count रिकॉर्ड से';
  }

  @override
  String get areaSales => 'बिक्री';

  @override
  String get areaServiceOrders => 'सर्विस ऑर्डर';

  @override
  String get areaSecondHandStock => 'पुराना स्टॉक';

  @override
  String get areaCustomers => 'ग्राहक';

  @override
  String get staffOffline =>
      'ऑफ़लाइन में स्टाफ़ नहीं संभाला जा सकता — यह पेज दुकान को ही पढ़ता-लिखता है।';

  @override
  String workingHere(String count) {
    return '$count लोग यहाँ काम करते हैं';
  }

  @override
  String get invited => 'आमंत्रित';

  @override
  String get invite => 'आमंत्रित करें';

  @override
  String get nobodyWaitingToJoin => 'कोई जुड़ने का इंतज़ार नहीं कर रहा';

  @override
  String claimedOnFirstSignIn(String role) {
    return '$role · पहली बार साइन इन करने पर मिलेगा';
  }

  @override
  String get withdraw => 'वापस लें';

  @override
  String get inviteSomebody => 'किसी को आमंत्रित करें';

  @override
  String get claimFirstSignIn => 'पहली बार साइन इन करने पर उन्हें मिलेगा';

  @override
  String get send => 'भेजें';

  @override
  String inviteSentTo(String email) {
    return '$email को न्योता भेजा';
  }

  @override
  String get roleAdmin => 'एडमिन';

  @override
  String get roleStaff => 'स्टाफ़';

  @override
  String get owner => 'मालिक';

  @override
  String get you => 'आप';

  @override
  String makeRole(String role) {
    return '$role बनाएँ';
  }

  @override
  String get removeFromShop => 'दुकान से हटाएँ';

  @override
  String get roleChanged => 'भूमिका बदली';

  @override
  String removeNamed(String name) {
    return '$name को हटाएँ?';
  }

  @override
  String get loseAccessNow =>
      'उनकी पहुँच तुरंत चली जाएगी। उनके बनाए रिकॉर्ड वैसे ही रहेंगे।';

  @override
  String get keep => 'रहने दें';

  @override
  String get remove => 'हटाएँ';

  @override
  String get removed => 'हटा दिया';

  @override
  String get signOut => 'साइन आउट';

  @override
  String signedInAs(String email) {
    return '$email के रूप में साइन इन';
  }

  @override
  String get everythingBelongsToShop =>
      'यह ऐप जो भी दर्ज करता है — स्टॉक, ग्राहक, बिक्री, मरम्मत — वह आपकी दुकान का है और सिर्फ़ आपको और आपके जोड़े स्टाफ़ को दिखता है।';

  @override
  String get goesOnEveryBill => 'हर बिल और जॉब कार्ड पर आएगा';

  @override
  String get gstinOptional => 'वैकल्पिक — हो तो बिल पर छपेगा';

  @override
  String get createTheShop => 'दुकान बनाएँ';

  @override
  String get changeLaterInSettings =>
      'यह सब बाद में सेटिंग्स में बदल सकते हैं, और स्टाफ़ को ईमेल से जोड़ सकते हैं।';

  @override
  String get settingsCouldNotLoad => 'सेटिंग्स लोड नहीं हो सकीं';

  @override
  String get listsGrowThemselves => 'ये सूचियाँ अपने आप बढ़ती हैं';

  @override
  String get listsGrowExplainer =>
      'फ़ॉर्म में टाइप की गई नई वैल्यू सूची में जुड़ जाती है, ताकि अगले व्यक्ति को ड्रॉपडाउन में मिले। यह पेज सफ़ाई के लिए है — जो अब काम नहीं आता उसे हटाने, या ग़लत चीज़ ठीक करने।';

  @override
  String get emptyWillStartAgain =>
      'खाली। फ़ॉर्म में अगली बार टाइप की गई वैल्यू इसे फिर शुरू कर देगी।';

  @override
  String addToList(String list) {
    return '$list में जोड़ें';
  }

  @override
  String addedValue(String value) {
    return '\"$value\" जोड़ा गया';
  }

  @override
  String removeValue(String value) {
    return '\"$value\" हटाएँ?';
  }

  @override
  String get stopsBeingOffered =>
      'यह फ़ॉर्म में दिखना बंद हो जाएगा। जो रिकॉर्ड इसे पहले से इस्तेमाल करते हैं वे नहीं बदलेंगे।';

  @override
  String removedValue(String value) {
    return '\"$value\" हटा दिया';
  }

  @override
  String get modelsByBrand => 'मॉडल, ब्रांड के अनुसार';

  @override
  String get noBrandsYet => 'अभी कोई ब्रांड नहीं।';

  @override
  String get noModelsUnderBrand =>
      'अभी कोई नहीं। इस ब्रांड में अगली बार टाइप किया मॉडल यहाँ आएगा।';

  @override
  String removedModelFrom(String model, String brand) {
    return '$brand से \"$model\" हटाया';
  }

  @override
  String addModelUnder(String brand) {
    return '$brand में मॉडल जोड़ें';
  }

  @override
  String addedUnderBrand(String value, String brand) {
    return '$brand में \"$value\" जोड़ा';
  }

  @override
  String get checklistHint =>
      'मरम्मत वापस देने से पहले हर आइटम टिक होना चाहिए। क्रम वही है जिस क्रम में फ़ोन जाँचा जाता है।';

  @override
  String get checklistEmpty =>
      'खाली, इसलिए जाँचने को कुछ नहीं और कोई भी मरम्मत वापस दी जा सकती है।';

  @override
  String get signedOut => 'साइन आउट';

  @override
  String get notFound => 'नहीं मिला';

  @override
  String noScreenFor(String uri) {
    return '$uri के लिए कोई स्क्रीन नहीं';
  }

  @override
  String get labelTitle => 'लेबल';

  @override
  String get modelsOfferedHint =>
      'ब्रांड चुनते ही इनटेक में दिखते हैं — सिर्फ़ उसी ब्रांड के मॉडल।';

  @override
  String modelCount(int count) {
    return '$count मॉडल';
  }

  @override
  String get checklistEmptyCharged =>
      'खाली, इसलिए जाँचने को कुछ नहीं; पैसे लेने के बाद कोई भी मरम्मत वापस दी जा सकती है।';

  @override
  String alreadyOnTheList(String value) {
    return '\"$value\" पहले से सूची में है';
  }

  @override
  String alreadyUnderBrand(String value, String brand) {
    return '$brand में \"$value\" पहले से है';
  }

  @override
  String get stateInStock => 'स्टॉक में';

  @override
  String get stateBeingRepaired => 'मरम्मत में';

  @override
  String get stateSold => 'बिक गया';

  @override
  String get tabRepairing => 'मरम्मत में';

  @override
  String get tabToOrder => 'ऑर्डर करना है';

  @override
  String get tabOutOfStock => 'स्टॉक खत्म';

  @override
  String get levelLow => 'कम';

  @override
  String get tabOpen => 'खुले';

  @override
  String get tabDueToday => 'आज देने हैं';

  @override
  String get tabOverdue => 'देरी';

  @override
  String get statusReceived => 'मिल गया';

  @override
  String get statusInProgress => 'काम चल रहा है';

  @override
  String get statusPartsAwaiting => 'पार्ट्स का इंतज़ार';

  @override
  String get statusAwaitingApproval => 'ग्राहक की मंज़ूरी का इंतज़ार';

  @override
  String get statusCompleted => 'पूरा हुआ';

  @override
  String get statusReturned => 'वापस आया';

  @override
  String get tabDueTodayLower => 'आज';

  @override
  String get tabWon => 'मिल गया';

  @override
  String get kindProduct => 'सामान';

  @override
  String get kindSecondHand => 'पुराना मोबाइल';

  @override
  String get kindServiceOrder => 'सर्विस ऑर्डर';

  @override
  String get kindSale => 'बिक्री';

  @override
  String get optionBrands => 'ब्रांड';

  @override
  String get optionSuppliers => 'सप्लायर';

  @override
  String get optionColours => 'रंग';

  @override
  String get optionCategories => 'सामान की श्रेणियाँ';

  @override
  String get optionComplaintTypes => 'शिकायत के प्रकार';

  @override
  String get optionAccessories => 'डिवाइस के साथ दिया सामान';

  @override
  String get optionLockTypes => 'लॉक के प्रकार';

  @override
  String openTheKind(String kind) {
    return '$kind खोलें';
  }

  @override
  String get yourName => 'आपका नाम';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get moveUp => 'ऊपर ले जाएँ';

  @override
  String get moveDown => 'नीचे ले जाएँ';

  @override
  String get labelPrinter => 'लेबल प्रिंटर';

  @override
  String get printServerAddress => 'प्रिंट सर्वर पता';

  @override
  String get saveAddress => 'पता सेव करें';

  @override
  String get howMany => 'कितने';

  @override
  String get requiredGoesInHistory => 'ज़रूरी — यह इतिहास में जाएगा';

  @override
  String recordedCount(String count) {
    return 'दर्ज: $count';
  }

  @override
  String get countedOnShelf => 'शेल्फ़ पर गिना';

  @override
  String get differenceGoesInHistory => 'फ़र्क़ इतिहास में जाएगा';

  @override
  String get correctIt => 'ठीक करें';

  @override
  String get cancelTheBill => 'बिल रद्द करें';

  @override
  String get onTheShelf => 'शेल्फ़ पर';

  @override
  String get nothingInNewGoods => 'नए सामान का स्टॉक खाली है।';

  @override
  String get noneOnTheShelf => 'शेल्फ़ पर नहीं';

  @override
  String get whatIsBeingCharged => 'कितना लिया जा रहा है?';

  @override
  String get finalPrice => 'अंतिम क़ीमत';

  @override
  String get zeroIsAllowed => 'शून्य भी ठीक है — मुफ़्त मरम्मत एक फ़ैसला है';

  @override
  String get returnedWithoutRepair => 'बिना मरम्मत के वापस';

  @override
  String get returnIt => 'वापस करें';

  @override
  String get whatCameOfIt => 'इसका क्या हुआ';

  @override
  String get whatDidThisBecome => 'यह क्या बना?';

  @override
  String get saleRepairOrNote => 'बिक्री, मरम्मत या नोट';

  @override
  String get markWon => 'मिल गया चिह्नित करें';

  @override
  String get startARepair => 'मरम्मत शुरू करें';

  @override
  String get buyThisHandset => 'यह मोबाइल ख़रीदें';

  @override
  String get printDeclaration => 'घोषणा प्रिंट करें';

  @override
  String get whatDidItGoOutAt => 'कितने में गया?';

  @override
  String get soldPrice => 'बिक्री क़ीमत';

  @override
  String get whatItIsLine => 'यह क्या है';

  @override
  String get priceLabel => 'क़ीमत';

  @override
  String get quantity => 'मात्रा';

  @override
  String get discountRupees => 'छूट (₹)';

  @override
  String get handThePhoneBack => 'फ़ोन वापस दें';

  @override
  String get returnedUnrepaired => 'बिना मरम्मत वापस';

  @override
  String chargingAmount(String amount) {
    return '₹$amount लिया जा रहा है';
  }

  @override
  String get returnedToCustomer => 'ग्राहक को वापस दिया';

  @override
  String get helpWhatIsThis => 'यह क्या है?';

  @override
  String get helpGotIt => 'समझ गया';

  @override
  String get fieldVariant => 'स्टोरेज / RAM';

  @override
  String get fieldAskingPrice => 'बेचने का दाम';

  @override
  String get fieldSellerName => 'बेचने वाले का नाम';

  @override
  String get fieldSellerPhone => 'बेचने वाले का फ़ोन नंबर';

  @override
  String get checkWorks => 'चलता है';

  @override
  String get checklistTitle => 'हर हिस्सा जाँचें';

  @override
  String get gradeTitle => 'ग्रेड';

  @override
  String get profitTitle => 'आपका मुनाफ़ा';

  @override
  String get lossTitle => 'आपको नुकसान';

  @override
  String get helpStockTabsTitle => 'रंगों का मतलब';

  @override
  String get helpBrand =>
      'फ़ोन बनाने वाली कंपनी। उदाहरण: Samsung, Vivo, Apple। यह फ़ोन के पीछे लिखा होता है। जल्दी भरने के लिए नीचे दिए नाम को छुएँ।';

  @override
  String get helpModel =>
      'फ़ोन के मॉडल का नाम। उदाहरण: Galaxy A54, Y21। यह Settings → About phone में मिलेगा।';

  @override
  String get helpColour =>
      'फ़ोन के पीछे का रंग। उदाहरण: काला, नीला। शेल्फ़ पर सही फ़ोन ढूँढने में मदद करता है।';

  @override
  String get helpImei =>
      '15 अंकों का नंबर जो सिर्फ़ इसी एक फ़ोन का होता है। फ़ोन पर *#06# डायल करें, दिख जाएगा। नंबर फ़ोन से लें, डिब्बे से नहीं — डिब्बा किसी और फ़ोन का हो सकता है। चोरी के फ़ोन पकड़ने के लिए पुलिस इसी नंबर का इस्तेमाल करती है।';

  @override
  String get helpImei2 =>
      'दो सिम वाले फ़ोन में दूसरा IMEI भी होता है। *#06# दोनों दिखाता है। एक ही हो तो खाली छोड़ दें।';

  @override
  String get helpSerial =>
      'कंपनी का सीरियल नंबर, Settings → About phone में मिलेगा। ज़्यादातर फ़ोन के लिए ज़रूरी नहीं — हो तो भर दें।';

  @override
  String get helpPaid =>
      'इस फ़ोन को बेचने वाले को आपने जो पैसे दिए। उदाहरण: 6000। सिर्फ़ अंक लिखें, ₹ का निशान नहीं।';

  @override
  String get helpOtherCost =>
      'मरम्मत के अलावा इस फ़ोन पर हुआ कोई और ख़र्च। उदाहरण: लाने का ऑटो किराया, सफ़ाई, नया कवर। न हो तो खाली छोड़ दें।';

  @override
  String get helpAsking =>
      'जिस दाम पर आप यह फ़ोन बेचना चाहते हैं। नीचे का हरा बॉक्स तुरंत आपका मुनाफ़ा दिखाता है। अगर वह लाल हो जाए, तो इस दाम पर नुकसान होगा।';

  @override
  String get helpProfit =>
      'बेचने के दाम में से सारा ख़र्च घटाकर: जो दिया, मरम्मत और बाक़ी ख़र्च। हरा मतलब मुनाफ़ा, लाल मतलब नुकसान।';

  @override
  String get helpRepairs =>
      'इस फ़ोन को बेचने लायक बनाने के लिए किया काम और उसका ख़र्च। उदाहरण: नई बैटरी ₹800। यह ख़र्च में जुड़ता है, ताकि मुनाफ़ा सही रहे।';

  @override
  String get helpBench =>
      'अगर फ़ोन अभी मरम्मत में है तो इसे चालू करें। जब तक आप इसे बंद नहीं करते, यह बिक्री के लिए तैयार नहीं दिखेगा।';

  @override
  String get helpGrade =>
      'फ़ोन कितना अच्छा है, उसका अक्षर। A: सब कुछ चलता है। B: 1 से 3 चीज़ें नहीं चलतीं। C: 4 या ज़्यादा नहीं चलतीं, या डिस्प्ले बदला गया / सफ़ेद धब्बे। D: टूटा, मुड़ा या iCloud लॉक। ऐप जाँच से ख़ुद तय करता है — ख़ुद चुनने के लिए कोई अक्षर छुएँ।';

  @override
  String get helpChecklist =>
      'सब कुछ \'चलता है\' से शुरू होता है। सिर्फ़ ख़राब चीज़ के लिए \'नहीं चलता\' छुएँ। \'डिस्प्ले बदला गया\' जैसे सवालों के लिए \'हाँ\' तभी छुएँ जब यह सच हो।';

  @override
  String get helpPhotos =>
      'फ़ोन की फ़ोटो लें। पहली फ़ोटो सामने की होनी चाहिए। ख़रीदते वक़्त फ़ोन किस हालत में था, फ़ोटो उसका सबूत हैं।';

  @override
  String get helpSellerName =>
      'जिसने यह फ़ोन आपको बेचा, उसका पूरा नाम, जैसा उसके पहचान पत्र पर है।';

  @override
  String get helpSellerPhone =>
      'बेचने वाले का 10 अंकों का मोबाइल नंबर। बाद में पुलिस इस फ़ोन के बारे में पूछे तो ज़रूरी होगा।';

  @override
  String get helpIdProof =>
      'बेचने वाले ने कौन-सा पहचान पत्र दिखाया और उसके आख़िरी 4 अंक। उदाहरण: Aadhaar 4412। फ़ोन चोरी का निकले तो यह दुकान को बचाता है।';

  @override
  String get helpSigned =>
      'बेचने वाला जब काग़ज़ पर साइन कर दे कि फ़ोन उसका है, तब इसे चालू करें। घोषणा-पत्र प्रिंट करने के लिए ज़रूरी है।';

  @override
  String get helpNotes =>
      'इस फ़ोन के बारे में याद रखने लायक कोई और बात। उदाहरण: कैमरे पर हल्की खरोंच, चार्जर साथ है।';

  @override
  String get helpSearchStock =>
      'फ़ोन के बारे में जो भी पता हो लिखें — ब्रांड, मॉडल, IMEI नंबर, लेबल नंबर या बेचने वाले का नाम — सूची में सिर्फ़ मिलते-जुलते फ़ोन दिखेंगे।';

  @override
  String get helpStockTabs =>
      'हरा = बिकने को तैयार। नारंगी = मरम्मत में। स्लेटी = बिक चुका। सिर्फ़ वही फ़ोन देखने के लिए किसी बॉक्स को छुएँ।';

  @override
  String get chkFrontCamera => 'आगे का कैमरा (धूल नहीं)';

  @override
  String get chkRearCamera => 'पीछे का कैमरा (धूल नहीं)';

  @override
  String get chkFingerprint => 'फ़िंगरप्रिंट सेंसर';

  @override
  String get chkBatteryHealth => 'बैटरी हेल्थ %';

  @override
  String get newToShopList =>
      'नया — सेव करने पर आपकी दुकान की सूची में जुड़ जाएगा';

  @override
  String get pickBrandFirst => 'मॉडल देखने के लिए पहले ब्रांड चुनें';

  @override
  String exampleHint(String example) {
    return 'जैसे: $example';
  }

  @override
  String wizStepOf(String n, String total) {
    return 'चरण $n / $total';
  }

  @override
  String get wizPhoto => 'फ़ोटो';

  @override
  String get wizPhone => 'फ़ोन';

  @override
  String get wizMoney => 'पैसे';

  @override
  String get wizPhotoTitle => 'फ़ोन की फ़ोटो लें';

  @override
  String get wizPhotoHint =>
      'फ़ोन का सामने का हिस्सा, स्क्रीन चालू — ताकि कोई भी देख सके कि फ़ोन कैसा दिखता है।';

  @override
  String get wizPhoneTitle => 'यह कौन-सा फ़ोन है?';

  @override
  String get wizMoneyTitle => 'कितने पैसे?';

  @override
  String get wizSellerTitle => 'आपको किसने बेचा?';

  @override
  String get wizNext => 'आगे';

  @override
  String get wizBack => 'पीछे';

  @override
  String get wizMoreDetails => 'और जानकारी जोड़ें (वैकल्पिक)';

  @override
  String get wizHideDetails => 'अतिरिक्त जानकारी छिपाएँ';

  @override
  String get optionRam => 'RAM मेमोरी';

  @override
  String get optionExpenseKinds => 'खर्च के प्रकार';

  @override
  String get optionRom => 'स्टोरेज (ROM)';

  @override
  String get chkDisplayClarity => 'डिस्प्ले साफ़ दिखता है';

  @override
  String get chkWhiteSpots => 'डिस्प्ले पर सफ़ेद धब्बे';

  @override
  String get chkDisplayReplaced => 'डिस्प्ले बदला गया';

  @override
  String get chkPhysicalDamage => 'बॉडी टूटी / मुड़ी';

  @override
  String get chkFaceTouchId => 'फ़ेस आईडी / टच आईडी';

  @override
  String get chkIcloudLock => 'iCloud लॉक जाँच';

  @override
  String get chkTrueTone => 'True Tone डिस्प्ले';

  @override
  String get chkEarpiece => 'ईयरपीस स्पीकर';

  @override
  String get chkLoudspeaker => 'लाउडस्पीकर';

  @override
  String get chkMicrophone => 'माइक्रोफ़ोन';

  @override
  String get chkMobileData => 'मोबाइल डेटा';

  @override
  String get chkBluetooth => 'ब्लूटूथ';

  @override
  String get chkWifi => 'वाई-फ़ाई';

  @override
  String get chkPowerButton => 'पावर बटन';

  @override
  String get chkVolumeButtons => 'वॉल्यूम बटन';

  @override
  String get chkMuteSwitch => 'म्यूट स्विच';

  @override
  String get chkLightningPort => 'चार्जिंग पोर्ट (Lightning / USB-C)';

  @override
  String get chkSimSlot => 'सिम स्लॉट';

  @override
  String get chkFlashlight => 'टॉर्च';

  @override
  String get chkFaceUnlock => 'फ़ेस अनलॉक';

  @override
  String get chkChargingPort => 'चार्जिंग पोर्ट';

  @override
  String get chkSimSlot1 => 'सिम स्लॉट 1';

  @override
  String get chkSimSlot2 => 'सिम स्लॉट 2';

  @override
  String get chkSdCardSlot => 'मेमोरी कार्ड स्लॉट';

  @override
  String get chkProximitySensor => 'प्रॉक्सिमिटी सेंसर';

  @override
  String get catDisplay => 'डिस्प्ले';

  @override
  String get catPhysical => 'बॉडी';

  @override
  String get catSecurity => 'सुरक्षा';

  @override
  String get catBattery => 'बैटरी';

  @override
  String get catCamera => 'कैमरा';

  @override
  String get catAudio => 'आवाज़';

  @override
  String get catConnectivity => 'कनेक्टिविटी';

  @override
  String get catSim => 'सिम और कार्ड स्लॉट';

  @override
  String get checkNotWorking => 'नहीं चलता';

  @override
  String get answerYes => 'हाँ';

  @override
  String get answerNo => 'नहीं';

  @override
  String get checksCommon => 'हर फ़ोन की जाँच';

  @override
  String get checksIphone => 'iPhone की जाँच';

  @override
  String get checksAndroid => 'Android की जाँच';

  @override
  String get gradeAuto => 'जाँच से तय हुआ';

  @override
  String get gradeManual => 'हाथ से चुना गया';

  @override
  String faultsFound(String list) {
    return 'ख़राबी: $list';
  }

  @override
  String get noFaults => 'कोई ख़राबी नहीं';

  @override
  String get warrantyExpiry => 'वारंटी ख़त्म होने की तारीख़';

  @override
  String get accessoriesIncluded => 'साथ में सामान';

  @override
  String get describeWear => 'कितना घिसा है?';

  @override
  String get describeCondition => 'हालत बताइए';

  @override
  String get describeDamage => 'नुकसान बताइए';

  @override
  String get notesFeatures => 'ख़ास बातें / नोट्स';

  @override
  String get purchaseDate => 'ख़रीद की तारीख़';

  @override
  String get fieldSupplier => 'सप्लायर (अगर सीधे ग्राहक नहीं)';

  @override
  String get sellerSearch => 'नाम या फ़ोन से खोजें';

  @override
  String get sellerCantFind => 'बेचने वाला नहीं मिला?';

  @override
  String get addNewCustomer => 'नया ग्राहक जोड़ें';

  @override
  String get saveAndSelect => 'सेव करके चुनें';

  @override
  String get idTypeLabel => 'पहचान पत्र का प्रकार';

  @override
  String get idNumberLabel => 'पहचान पत्र नंबर';

  @override
  String get fieldAltPhone => 'दूसरा फ़ोन नंबर (वैकल्पिक)';

  @override
  String get sellerPicked => 'आपके ग्राहकों में से';

  @override
  String get changeSeller => 'बदलें';

  @override
  String get photoSlotFront => 'सामने से';

  @override
  String get photoSlotBack => 'पीछे से';

  @override
  String get photoSlotLeft => 'बायाँ हिस्सा';

  @override
  String get photoSlotRight => 'दायाँ हिस्सा';

  @override
  String get photoSlotTopBottom => 'ऊपर / नीचे';

  @override
  String get photoSlotExtra => 'अतिरिक्त';

  @override
  String get idCardFront => 'पहचान पत्र — आगे';

  @override
  String get idCardBack => 'पहचान पत्र — पीछे';

  @override
  String get idCardPhotosTitle => 'पहचान पत्र की फ़ोटो';

  @override
  String get tapToAddPhoto => 'जोड़ने के लिए छुएँ';

  @override
  String get wizCondition => 'हालत';

  @override
  String get wizConditionTitle => 'फ़ोन की हालत कैसी है?';

  @override
  String get wizPhotosTitle => 'फ़ोन की फ़ोटो लें';

  @override
  String get saveAndPrintLabel => 'सेव करके लेबल प्रिंट करें';

  @override
  String get serialAppleHint => 'iPhone के लिए ज़रूरी';

  @override
  String get checklistNeedsBrand =>
      'जाँच देखने के लिए \'फ़ोन\' चरण में ब्रांड चुनें।';

  @override
  String labelPrinted(String number) {
    return 'सेव हुआ — लेबल $number प्रिंटर को भेजा गया';
  }

  @override
  String get helpRam =>
      'फ़ोन में कितनी RAM है। Settings → About phone में मिलेगी। उदाहरण: 6GB।';

  @override
  String get helpRom =>
      'फ़ोन में कितनी स्टोरेज है। Settings → Storage में मिलेगी। उदाहरण: 128GB। ज़्यादा स्टोरेज वाला फ़ोन ज़्यादा दाम में बिकता है।';

  @override
  String get helpPurchaseDate =>
      'जिस दिन आपने यह फ़ोन ख़रीदा। आज की तारीख़ पहले से भरी है — दूसरे दिन ख़रीदा हो तभी बदलें।';

  @override
  String get helpSupplier =>
      'सिर्फ़ तब, जब डीलर या दूसरी दुकान से ख़रीदा हो। ग्राहक ने बेचा हो तो खाली छोड़ दें।';

  @override
  String get helpSellerSearch =>
      'बेचने वाले का नाम या फ़ोन नंबर लिखें। अगर वे पहले दुकान आ चुके हैं, तो नीचे दिखेंगे — सब कुछ भरने के लिए छुएँ।';

  @override
  String get helpAltPhone => 'पहला नंबर बंद हो तो बेचने वाले का दूसरा नंबर।';

  @override
  String get helpIdType =>
      'बेचने वाले ने कौन-सा पहचान पत्र दिखाया — आधार, PAN, ड्राइविंग लाइसेंस या वोटर आईडी।';

  @override
  String get helpIdNumber => 'उस पहचान पत्र पर छपा नंबर।';

  @override
  String get helpIdCardPhotos =>
      'बेचने वाले के पहचान पत्र की आगे और पीछे की फ़ोटो। बाद में पुलिस पूछे तो ये साबित करती हैं कि फ़ोन किसने बेचा।';

  @override
  String get helpGradeDetails =>
      'फ़ोन की हालत के बारे में कुछ शब्द, ताकि अगला व्यक्ति दोबारा जाँचे बिना जान ले।';

  @override
  String get helpSerialApple =>
      'Settings → General → About में सीरियल नंबर। हर iPhone के लिए ज़रूरी है।';

  @override
  String get navTasks => 'काम';

  @override
  String get navMyTasks => 'मेरे काम';

  @override
  String get tasksCouldNotLoad => 'काम लोड नहीं हो सके';

  @override
  String get taskTabToDo => 'करना है';

  @override
  String get taskTabDone => 'हो गया';

  @override
  String get taskFreqDaily => 'रोज़';

  @override
  String get taskFreqWeekly => 'हर हफ़्ते';

  @override
  String get taskFreqMonthly => 'हर महीने';

  @override
  String get taskFreqOnce => 'एक बार';

  @override
  String get taskTabUnassigned => 'किसी को नहीं';

  @override
  String get taskPriorityLow => 'कम';

  @override
  String get taskPriorityMedium => 'मध्यम';

  @override
  String get taskPriorityHigh => 'ज़रूरी';

  @override
  String get taskAdd => 'काम जोड़ें';

  @override
  String get taskNew => 'नया काम';

  @override
  String get taskEdit => 'काम बदलें';

  @override
  String get taskTitleLabel => 'क्या करना है';

  @override
  String get taskDescriptionLabel => 'और जानकारी';

  @override
  String get taskAssignLabel => 'कौन करेगा';

  @override
  String get taskFrequencyLabel => 'कितनी बार';

  @override
  String get taskPriorityLabel => 'कितना ज़रूरी';

  @override
  String get taskDueLabel => 'कब तक करना है';

  @override
  String get taskPickDate => 'दिन चुनें';

  @override
  String get taskMarkDone => 'हो गया';

  @override
  String get taskUndo => 'वापस लें';

  @override
  String get taskOverdue => 'देर हो गई';

  @override
  String taskDueOn(String date) {
    return '$date तक करना है';
  }

  @override
  String get taskNobodySees => 'किसी को नहीं दिया — स्टाफ़ को अभी नहीं दिखेगा';

  @override
  String get taskAllStaff => 'सब लोग';

  @override
  String get taskDelete => 'हटाएँ';

  @override
  String get taskDeleteConfirm => 'यह काम हटाएँ?';

  @override
  String get taskSaved => 'काम सेव हो गया';

  @override
  String get taskNoTasks => 'यहाँ कोई काम नहीं';

  @override
  String get taskBlockNoTitle => 'लिखें कि क्या करना है।';

  @override
  String get taskBlockNoDueDate => 'चुनें कि यह किस दिन तक करना है।';

  @override
  String get taskBlockAdminOnly => 'सिर्फ़ दुकान का मालिक काम बदल सकता है।';

  @override
  String get taskBlockNotYours => 'यह काम किसी और का है।';

  @override
  String get helpTaskTitle =>
      'काम कुछ आसान शब्दों में लिखें। उदाहरण: शोकेस साफ़ करें।';

  @override
  String get helpTaskAssign =>
      'वह स्टाफ़ जिसे यह काम करना है। सिर्फ़ उसी के फ़ोन पर दिखेगा। किसी को नहीं चुना तो किसी स्टाफ़ को नहीं दिखेगा।';

  @override
  String get helpTaskFrequency =>
      'काम कितनी बार वापस आता है। रोज़: हर सुबह फिर करना है। हर हफ़्ते: हफ़्ते में एक बार। हर महीने: महीने में एक बार। एक बार: एक बार किया तो ख़त्म।';

  @override
  String get helpTaskPriority =>
      'ज़रूरी काम सबसे ऊपर और लाल रंग में दिखते हैं। ज़रूरी सिर्फ़ उन कामों के लिए रखें जो रुक नहीं सकते।';

  @override
  String get helpTaskDue =>
      'यह काम ख़त्म करने का आख़िरी दिन। इस दिन के बाद देर हो गई दिखेगा।';

  @override
  String stockOnHand(String count) {
    return '$count मौजूद';
  }

  @override
  String stockSellingFor(String amount) {
    return 'बिक्री ₹$amount';
  }

  @override
  String stockPaidFor(String amount) {
    return 'दिए ₹$amount';
  }

  @override
  String addAsNewCustomer(String value) {
    return '\"$value\" को नए ग्राहक के रूप में जोड़ें';
  }

  @override
  String addAsNewBrand(String value) {
    return '\"$value\" को नए ब्रांड के रूप में जोड़ें';
  }

  @override
  String addAsNewModel(String value) {
    return '\"$value\" को नए मॉडल के रूप में जोड़ें';
  }

  @override
  String addAsNewRam(String value) {
    return '\"$value\" को नए RAM साइज़ के रूप में जोड़ें';
  }

  @override
  String addAsNewRom(String value) {
    return '\"$value\" को नए स्टोरेज साइज़ के रूप में जोड़ें';
  }

  @override
  String addAsNewColour(String value) {
    return '\"$value\" को नए रंग के रूप में जोड़ें';
  }

  @override
  String addAsNewSupplier(String value) {
    return '\"$value\" को नए सप्लायर के रूप में जोड़ें';
  }

  @override
  String get sellerSearchLabel => 'बेचने वाला';

  @override
  String get sellerSearchHint => 'नाम या फ़ोन नंबर लिखें';

  @override
  String get noMatchingRecord => 'कुछ नहीं मिला';

  @override
  String couldNotAddToList(String error) {
    return 'दुकान की सूची में नहीं जुड़ सका: $error';
  }

  @override
  String get signatureLabel => 'बेचने वाले के हस्ताक्षर';

  @override
  String get signatureClear => 'फिर से हस्ताक्षर करें';

  @override
  String get signatureHint => 'यहाँ उँगली से हस्ताक्षर करें';

  @override
  String get signatureOnRecord => 'पहले ही हस्ताक्षर हो चुके हैं';

  @override
  String get imeiScanTitle => 'IMEI स्कैन करें';

  @override
  String get imeiScanPoint =>
      'IMEI बारकोड की ओर कैमरा करें: डिब्बे पर, बैटरी के नीचे, या *#06# डायल करने के बाद फ़ोन की स्क्रीन पर।';

  @override
  String get imeiScanPointPhone =>
      'फ़ोन चालू होता है? *#06# डायल करें और स्क्रीन पर दिख रहा बारकोड स्कैन करें। नहीं तो फ़ोन पर लगा IMEI स्टिकर स्कैन करें।';

  @override
  String noModelsYet(String brand) {
    return '$brand के मॉडल अभी सेव नहीं हैं। एक बार टाइप करें, अगली बार यहीं दिखेगा।';
  }

  @override
  String get serialScanTitle => 'सीरियल नंबर स्कैन करें';

  @override
  String get serialScanPoint =>
      'डिब्बे या लेबल पर \"Serial No.\" के पास वाले बारकोड की ओर कैमरा करें।';

  @override
  String get serialScanAgain => 'फिर से स्कैन करें';

  @override
  String get serialScanNoCamera => 'कैमरा नहीं चल रहा। सीरियल नंबर टाइप करें।';

  @override
  String get savingNow => 'सेव हो रहा है…';

  @override
  String get emailNeeded => 'आपका ईमेल चाहिए';

  @override
  String get passwordNeeded => 'आपका पासवर्ड चाहिए';

  @override
  String get printingNow => 'प्रिंट हो रहा है…';

  @override
  String get loadingData => 'आपका डेटा ला रहे हैं…';

  @override
  String get loadingStill => 'अभी भी काम चल रहा है…';

  @override
  String get loadingAlmost => 'बस हो ही गया…';

  @override
  String get loadingSlow => 'इंटरनेट धीमा है? थोड़ा रुकिए…';

  @override
  String get loadingRepairs => 'रिपेयर ला रहे हैं…';

  @override
  String get loadingPhones => 'फ़ोन ला रहे हैं…';

  @override
  String get loadingBills => 'बिल ला रहे हैं…';

  @override
  String get loadingCustomers => 'ग्राहक ला रहे हैं…';

  @override
  String get loadingProducts => 'सामान ला रहे हैं…';

  @override
  String get loadingEnquiries => 'पूछताछ ला रहे हैं…';

  @override
  String get loadingTasks => 'काम ला रहे हैं…';

  @override
  String get loadingRecord => 'खोल रहे हैं…';

  @override
  String get loadingStaff => 'स्टाफ़ ला रहे हैं…';

  @override
  String get loadingRatings => 'रेटिंग ला रहे हैं…';

  @override
  String get loadingSearch => 'खोज रहे हैं…';

  @override
  String get loadingPrinters => 'प्रिंटर ढूँढ रहे हैं…';

  @override
  String get loadingOlder => 'पुराने बिल और काम ला रहे हैं…';

  @override
  String get readNumbersButton => 'बारकोड नहीं? नंबर पढ़ें';

  @override
  String get readingNumbers => 'नंबर पढ़ रहे हैं…';

  @override
  String get readNoImei =>
      'फ़ोटो में IMEI नहीं मिला। फ़ोन पास और साफ़ रखकर फिर कोशिश करें, या टाइप करें।';

  @override
  String get readNoSerial =>
      'फ़ोटो में सीरियल नंबर नहीं मिला। पास से फिर कोशिश करें, या टाइप करें।';

  @override
  String readFailed(String reason) {
    return 'कैमरा पढ़ नहीं सका: $reason';
  }

  @override
  String get tourWelcomeTitle => 'आपके दुकान ऐप में स्वागत है';

  @override
  String get tourWelcomeBody =>
      'हर पेज किस काम का है, एक मिनट में देखें। आगे दबाएँ, या कभी भी छोड़ें। सेटिंग्स से इसे फिर देख सकते हैं।';

  @override
  String get tourSearchTitle => 'कुछ भी खोजें';

  @override
  String get tourSearchBody =>
      'नाम, फ़ोन नंबर, IMEI, जॉब नंबर या बिल नंबर लिखें। स्कैन बटन लेबल या IMEI बारकोड पढ़ता है।';

  @override
  String get tourTodayTitle => 'आज की कमाई';

  @override
  String get tourTodayBody =>
      'आज बिल और रिपेयर से आया पैसा — नकद, UPI और कार्ड में बँटा हुआ।';

  @override
  String get tourActionsTitle => 'यहाँ से शुरू करें';

  @override
  String get tourActionsBody =>
      'काउंटर के चार काम: नई बिक्री, नया रिपेयर, फ़ोन ख़रीदना और पूछताछ लिखना।';

  @override
  String get tourQueueTitle => 'आपका इंतज़ार कर रहे रिपेयर';

  @override
  String get tourQueueBody =>
      'देर वाले, आज देने वाले और तैयार काम। दबाकर देखें; कार्ड से ही ग्राहक को कॉल या WhatsApp करें।';

  @override
  String get tourNavTitle => 'पेज बदलें';

  @override
  String get tourNavBody =>
      'होम, मोबाइल, रिपेयर, बिक्री और और भी — हर पेज पर यहीं हैं।';

  @override
  String get tourStockTitle => 'स्टॉक में फ़ोन';

  @override
  String get tourStockBody =>
      'कितने फ़ोन हैं, कितने में बिकेंगे और उनमें कितना मुनाफ़ा है।';

  @override
  String get tourStockTabsTitle => 'स्टॉक में, रिपेयर में, बिक चुके';

  @override
  String get tourStockTabsBody =>
      'बदलने के लिए दबाएँ। हर फ़ोन अपनी क़ीमत, मुनाफ़ा और कितने दिन से रखा है, दिखाता है।';

  @override
  String get tourBuyTitle => 'फ़ोन ख़रीदना';

  @override
  String get tourBuyBody =>
      'पाँच छोटे क़दम: बेचने वाला, फ़ोन, हालत, पैसा, फ़ोटो। आख़िर में क़ीमत का लेबल छपता है।';

  @override
  String get tourRepairsTitle => 'हर रिपेयर, उसकी स्थिति के हिसाब से';

  @override
  String get tourRepairsBody =>
      'खुले, आज के, देर वाले, तैयार। काम खोलकर स्थिति बदलें, पैसा लगाएँ और फ़ोन लौटाएँ।';

  @override
  String get tourNewRepairTitle => 'रिपेयर लेना';

  @override
  String get tourNewRepairBody =>
      'फ़ोन नंबर, ब्रांड, मॉडल और क्या ख़राबी है। सेव और प्रिंट से ग्राहक को जॉब कार्ड मिलता है।';

  @override
  String get tourBillsTitle => 'बिल';

  @override
  String get tourBillsBody =>
      'पूरे हुए बिल, ड्राफ़्ट और रद्द बिल। बिना इंटरनेट भी बिल पूरा कर सकते हैं; इंटरनेट आते ही अपने आप पूरा होगा।';

  @override
  String get tourNewBillTitle => 'नया बिल';

  @override
  String get tourNewBillBody =>
      'स्टॉक से फ़ोन, एक्सेसरी या लिखी हुई लाइन जोड़ें, पैसा लें और बिल भेजें।';

  @override
  String get tourSettingsTitle => 'सेटिंग्स';

  @override
  String get tourSettingsBody =>
      'दुकान की सूचियाँ, लेबल प्रिंटर और भाषा। यह टूर भी यहीं \'मदद\' में है।';

  @override
  String get tourDoneTitle => 'टूर पूरा हुआ';

  @override
  String get tourDoneBody =>
      'बॉक्स के पास वाले ? बटन हर चीज़ समझाते हैं। जो बटन सबसे ज़्यादा चाहिए, वहीं से शुरू करें।';

  @override
  String get tourSkip => 'छोड़ें';

  @override
  String get tourBack => 'पीछे';

  @override
  String get tourNext => 'आगे';

  @override
  String get tourDone => 'हो गया';

  @override
  String get tourOfferTitle => 'नए हैं?';

  @override
  String get tourOfferBody =>
      'एक मिनट का टूर: हर पेज किस काम का है और कहाँ दबाना है।';

  @override
  String get tourOfferStart => 'दिखाइए';

  @override
  String get tourOfferLater => 'अभी नहीं';

  @override
  String get setGroupHelp => 'मदद';

  @override
  String get settingsTour => 'ऐप टूर';

  @override
  String get settingsTourSub => 'हर पेज कैसे काम करता है, क़दम-दर-क़दम देखें';

  @override
  String tourStepOf(int n, int total) {
    return '$total में से $n';
  }

  @override
  String get tourChRepairTitle => 'रिपेयर लेना';

  @override
  String get tourChRepairBlurb => 'जॉब कार्ड भरें, फिर फ़ोन लौटने तक काम देखें';

  @override
  String get tourRepair1T => 'स्थिति के हिसाब से रिपेयर';

  @override
  String get tourRepair1B =>
      'खुले, आज के, देर वाले, तैयार। टैब दबाकर वे काम देखें। किसी काम को दाएँ खींचें तो ग्राहक को कॉल, बाएँ खींचें तो WhatsApp।';

  @override
  String get tourRepair2T => 'नया रिपेयर';

  @override
  String get tourRepair2B =>
      'यह नया रिपेयर शुरू करता है। देखिए: टूर अभ्यास डेटा से एक भरेगा।';

  @override
  String get tourRepair3T => 'ग्राहक का नंबर';

  @override
  String get tourRepair3B =>
      'पहले यही लिखें: पहले आए ग्राहक मिल जाते हैं, दबाने पर नाम भर जाता है।';

  @override
  String get tourRepair4T => 'नाम';

  @override
  String get tourRepair4B => 'ज़रूरी नहीं: सिर्फ़ नंबर काफ़ी है।';

  @override
  String get tourRepair5T => 'ब्रांड';

  @override
  String get tourRepair5B =>
      'बॉक्स के नीचे की पंक्ति में दबाएँ, या नया लिखें; वह सूची में जुड़ जाएगा।';

  @override
  String get tourRepair6T => 'मॉडल';

  @override
  String get tourRepair6B =>
      'ब्रांड चुनते ही उसके मॉडल पंक्ति में आते हैं। एक दबाएँ।';

  @override
  String get tourRepair7T => 'IMEI नंबर';

  @override
  String get tourRepair7B =>
      'डिब्बे से नहीं, फ़ोन से (*#06#)। कैमरा बटन स्कैन करता है।';

  @override
  String get tourRepair8T => 'लॉक';

  @override
  String get tourRepair8B =>
      'कैसे लॉक है और कोड क्या है, ताकि फ़ोन जाँचा जा सके।';

  @override
  String get tourRepair9T => 'क्या ख़राबी है';

  @override
  String get tourRepair9B =>
      'एक या ज़्यादा दबाएँ; लिखने से बाक़ी मिलते हैं। जॉब कार्ड और बिल इन्हीं से बनते हैं।';

  @override
  String get tourRepair10T => 'अनुमान';

  @override
  String get tourRepair10B =>
      'जो क़ीमत बताई। एडवांस और पुर्ज़ों का ख़र्च नीचे।';

  @override
  String get tourRepair11T => 'वादे की तारीख़';

  @override
  String get tourRepair11B => 'कब वापस मिलेगा। देर वाले काम होम पर दिखते हैं।';

  @override
  String get tourRepair12T => 'सेव';

  @override
  String get tourRepair12B =>
      'सेव करें, या जॉब कार्ड के लिए सेव और प्रिंट। खाली बॉक्स लाल होकर वहीं कर्सर जाता है।';

  @override
  String get tourRepair13T => 'एक काम का पेज';

  @override
  String get tourRepair13B =>
      'काम आगे बढ़े तो स्थिति दबाएँ। तैयार करने पर ग्राहक को WhatsApp भेज सकते हैं।';

  @override
  String get tourRepair15T => 'सौंपने से पहले';

  @override
  String get tourRepair15B =>
      'कितनी जाँच हो गईं। इसे दबाएँ, या फ़ोन वापस दें, तो सौंपने का पेज खुलेगा।';

  @override
  String get tourRepair16T => 'सौंपना';

  @override
  String get tourRepair16B =>
      'हर जाँच पर टिक करें, क़ीमत और भुगतान का तरीक़ा पक्का करें, फिर एक बटन से सौंप दें। कुछ छूटा तो वहीं ले जाएगा।';

  @override
  String get tourRepair14T => 'पैसा, पुर्ज़े, वापसी';

  @override
  String get tourRepair14B =>
      'पैसा तय करें, स्टॉक से पुर्ज़े लें, प्रिंट करें, और चेकलिस्ट के बाद फ़ोन लौटाएँ।';

  @override
  String get tourChBuyTitle => 'फ़ोन ख़रीदना';

  @override
  String get tourChBuyBlurb => 'बेचने वाले से क़ीमत लेबल तक पाँच क़दम';

  @override
  String get tourBuy1T => 'फ़ोन ख़रीदना';

  @override
  String get tourBuy1B => 'पाँच छोटे क़दम। देखिए: टूर अभ्यास डेटा से एक भरेगा।';

  @override
  String get tourBuy2T => '1 · बेचने वाला';

  @override
  String get tourBuy2B =>
      'नाम या नंबर से खोजकर दबाएँ, या नया जोड़ें। उनकी ID \'और जानकारी\' में।';

  @override
  String get tourBuy3T => '2 · फ़ोन';

  @override
  String get tourBuy3B =>
      'ब्रांड, मॉडल, RAM और स्टोरेज — पंक्ति में एक-एक टैप।';

  @override
  String get tourBuy4T => 'चुने गए';

  @override
  String get tourBuy4B => 'गहरा नीला = चुना हुआ। ग़लत टैप एक और टैप से ठीक।';

  @override
  String get tourBuy5T => 'IMEI और सीरियल';

  @override
  String get tourBuy5B =>
      'डिब्बा स्कैन करें, या कैमरे से स्क्रीन के नंबर पढ़ें। iPhone का सीरियल भी चाहिए।';

  @override
  String get tourBuy6T => '3 · हालत';

  @override
  String get tourBuy6B =>
      'जो काम नहीं करता उसे चिह्नित करें। A–D ग्रेड अपने आप बनता है; बैटरी हेल्थ भी यहीं।';

  @override
  String get tourBuy7T => '4 · पैसा';

  @override
  String get tourBuy7B =>
      'कितना दिया और कितने में बिकेगा। लिखते ही मुनाफ़ा दिखता है।';

  @override
  String get tourBuy8T => '5 · फ़ोटो';

  @override
  String get tourBuy8B =>
      'आगे-पीछे की फ़ोटो, बेचने वाले की ID और साइन। सेव करने पर क़ीमत लेबल छपता है।';

  @override
  String get tourBuy9T => 'एक फ़ोन का पेज';

  @override
  String get tourBuy9B => 'बिल पर बेचें, रिपेयर में भेजें, या लेबल फिर छापें।';

  @override
  String get tourChBillTitle => 'बिल बनाना';

  @override
  String get tourChBillBlurb => 'कौन, क्या, कैसे पैसा दिया, फिर बिल';

  @override
  String get tourBill1T => 'बिल';

  @override
  String get tourBill1B => 'पूरे हुए बिल, ड्राफ़्ट और रद्द बिल।';

  @override
  String get tourBill2T => 'कौन ख़रीद रहा है';

  @override
  String get tourBill2B =>
      'नंबर से वे मिल जाते हैं; नया नंबर ग्राहकों में जुड़ता है।';

  @override
  String get tourBill3T => 'क्या ख़रीद रहे हैं';

  @override
  String get tourBill3B => 'स्टॉक से फ़ोन, एक्सेसरी, या लिखी लाइन जोड़ें।';

  @override
  String get tourBill4T => 'कैसे पैसा दिया';

  @override
  String get tourBill4B => 'नकद, UPI या कार्ड: एक टैप।';

  @override
  String get tourBill5T => 'अभी दिया';

  @override
  String get tourBill5B =>
      'पूरी रक़म के लिए खाली छोड़ें। कम हो तो बाक़ी उधार में रहेगा।';

  @override
  String get tourBill6T => 'बिक्री पूरी करें';

  @override
  String get tourBill6B =>
      'बिल नंबर मिलता है और फ़ोन स्टॉक से निकलता है। बाद के लिए ड्राफ़्ट रखें।';

  @override
  String get tourBill7T => 'एक बिल का पेज';

  @override
  String get tourBill7B => 'बिल भेजें या छापें, बाक़ी पैसा लें, या रद्द करें।';

  @override
  String get tourChCustomersTitle => 'ग्राहक';

  @override
  String get tourChCustomersBlurb => 'जिसने ख़रीदा, बेचा या फ़ोन छोड़ा — सब';

  @override
  String get tourCustomers1T => 'ग्राहक';

  @override
  String get tourCustomers1B =>
      'नाम या नंबर से खोजें। दबाने पर उनका पेज खुलता है।';

  @override
  String get tourCustomers2T => 'किसी को जोड़ना';

  @override
  String get tourCustomers2B =>
      'सिर्फ़ नंबर ज़रूरी है। ID और पता तब, जब वे फ़ोन बेचें।';

  @override
  String get tourCustomers3T => 'एक ग्राहक का पेज';

  @override
  String get tourCustomers3B =>
      'कॉल या WhatsApp करें, उनका स्टोर क्रेडिट, और उनके सारे रिपेयर, बिल, पूछताछ।';

  @override
  String get tourChProductsTitle => 'सामान और स्टॉक';

  @override
  String get tourChProductsBlurb =>
      'एक्सेसरी और पुर्ज़े: शेल्फ़ पर क्या है, क्या मँगाना है';

  @override
  String get tourProducts1T => 'सामान';

  @override
  String get tourProducts1B => 'आपकी एक्सेसरी और पुर्ज़े। नाम या कोड से खोजें।';

  @override
  String get tourProducts2T => 'कम हो रहा है';

  @override
  String get tourProducts2B => 'मँगाने की सूची सप्लायर को WhatsApp पर भेजें।';

  @override
  String get tourProducts3T => 'सामान जोड़ना';

  @override
  String get tourProducts3B =>
      'नाम, बिक्री क़ीमत और श्रेणी। शेल्फ़ की गिनती शून्य से।';

  @override
  String get tourProducts4T => 'एक सामान का पेज';

  @override
  String get tourProducts4B => 'स्टॉक आया, ख़राब, गिनती, और उसका लेबल।';

  @override
  String get tourChEnquiriesTitle => 'पूछताछ';

  @override
  String get tourChEnquiriesBlurb =>
      'लोगों ने क्या माँगा लिखें और वापस कॉल करें';

  @override
  String get tourEnquiries1T => 'पूछताछ';

  @override
  String get tourEnquiries1B =>
      'जिन्होंने ऐसी चीज़ माँगी जो अभी नहीं थी। आते ही कॉल करें।';

  @override
  String get tourEnquiries2T => 'एक लिखना';

  @override
  String get tourEnquiries2B =>
      'नंबर, किस बारे में, और क्या पूछा। फ़ॉलो-अप तारीख़ याद दिलाएगी।';

  @override
  String get tourEnquiries3T => 'नतीजा क्या रहा';

  @override
  String get tourEnquiries3B =>
      'जीता, हारा या खुला चिह्नित करें; यहीं से रिपेयर शुरू करें।';

  @override
  String get tourChMoneyTitle => 'पैसा और रिपोर्ट';

  @override
  String get tourChMoneyBlurb => 'क्या आया, कैसे, और किसका बाक़ी है';

  @override
  String get tourMoney1T => 'रिपोर्ट';

  @override
  String get tourMoney1B =>
      'समय चुनें: आज, यह हफ़्ता, यह महीना, या अपनी तारीख़ें।';

  @override
  String get tourMoney2T => 'कैसे आया';

  @override
  String get tourMoney2B =>
      'नकद, UPI और कार्ड — गल्ले और बैंक से मिलाने के लिए।';

  @override
  String get tourMoney3T => 'भेजें';

  @override
  String get tourMoney3B => 'रिपोर्ट WhatsApp पर भेजें, या सेव करें।';

  @override
  String get tourMoney5T => 'बाहर गया पैसा';

  @override
  String get tourMoney5B =>
      'दुकान किस चीज़ के पैसे देती है, लिखें: पार्ट्स, चाय, किराया। आज और इस महीने का खर्च ऊपर दिखता है।';

  @override
  String get tourMoney6T => 'एक जोड़ना';

  @override
  String get tourMoney6B =>
      'रक़म, फिर किसके लिए। नकद और आज पहले से चुने हैं — चाय के लिए रक़म और दो टैप काफ़ी।';

  @override
  String get tourMoney7T => 'कितना बचा';

  @override
  String get tourMoney7B =>
      'रिपोर्ट खर्च घटा देती है। गल्ले में बची नकदी वही है जो बंद करते समय गिननी है।';

  @override
  String get tourMoney4T => 'बाक़ी पैसा';

  @override
  String get tourMoney4B =>
      'जिनके बिल पर पैसा बाक़ी है। याद दिलाएँ — विनम्र WhatsApp भेजता है।';

  @override
  String get tourChLabelsTitle => 'लेबल, स्कैनर और खोज';

  @override
  String get tourChLabelsBlurb => 'स्टिकर, IMEI या किसी शब्द से कुछ भी ढूँढें';

  @override
  String get tourLabels1T => 'सब कुछ खोजें';

  @override
  String get tourLabels1B =>
      'नाम, नंबर, IMEI, जॉब या बिल — रिपेयर, फ़ोन, बिल और ग्राहकों में।';

  @override
  String get tourLabels2T => 'स्कैनर';

  @override
  String get tourLabels2B =>
      'लेबल या IMEI स्कैन करें — जिसका है वह खुलेगा, या रिपेयर/ख़रीद शुरू होगी।';

  @override
  String get tourLabels3T => 'लेबल';

  @override
  String get tourLabels3B =>
      'छपा हर नंबर और वह किस पर है। यहीं से दोबारा छापें।';

  @override
  String get tourChTeamTitle => 'स्टाफ़, काम और रेटिंग';

  @override
  String get tourChTeamBlurb => 'आपकी टीम, उनके काम, और ग्राहकों की राय';

  @override
  String get tourTeam1T => 'स्टाफ़';

  @override
  String get tourTeam1B =>
      'ईमेल से स्टाफ़ या एडमिन बुलाएँ। अनुमति बिना स्टाफ़ लागत नहीं देखता।';

  @override
  String get tourTeam2T => 'काम';

  @override
  String get tourTeam2B =>
      'टीम के काम, एक बार या बार-बार। हर कोई अपने देखता है।';

  @override
  String get tourTeam3T => 'रेटिंग';

  @override
  String get tourTeam3B =>
      'रिपेयर के बाद ग्राहकों ने क्या कहा — तैयार होने पर भेजे लिंक से।';

  @override
  String get tourChSettingsTitle => 'सेटिंग्स';

  @override
  String get tourChSettingsBlurb => 'आपकी सूचियाँ, लेबल प्रिंटर, भाषा और भी';

  @override
  String get tourSettings1T => 'मदद';

  @override
  String get tourSettings1B => 'सारे टूर यहीं, कभी भी।';

  @override
  String get tourSettings2T => 'आपकी सूचियाँ';

  @override
  String get tourSettings2B =>
      'ब्रांड, मॉडल, RAM, रंग, शिकायतें: फ़ॉर्म की पंक्तियाँ इन्हीं से।';

  @override
  String get tourSettings3T => 'लेबल प्रिंटर';

  @override
  String get tourSettings3B =>
      'ब्लूटूथ लेबल प्रिंटर जोड़ें और टेस्ट लेबल छापें।';

  @override
  String get tourSettings4T => 'सार्वजनिक वेब पता';

  @override
  String get tourSettings4B =>
      'सिर्फ़ ग्राहक रेटिंग लिंक और लेबल के QR वाले पेज के लिए: वह वेबसाइट जहाँ ये पेज हैं।';

  @override
  String get tourChAroundTitle => 'ऐप में घूमना';

  @override
  String get tourChAroundBlurb => 'हर पेज किस काम का है और कहाँ दबाना है';

  @override
  String get tourThisPage => 'इस पेज का टूर';

  @override
  String get tourMenuTitle => 'ऐप टूर';

  @override
  String get tourPractice => 'अभ्यास डेटा: यहाँ कुछ भी सेव नहीं होता';

  @override
  String get tourFilling => 'टूर इसे भर रहा है…';

  @override
  String get shortcutNewBill => 'नया बिल';

  @override
  String get reminderMorningTitle => 'आज दुकान पर';

  @override
  String get setGroupReminders => 'रिमाइंडर';

  @override
  String get settingsReminders => 'सुबह का रिमाइंडर';

  @override
  String get remindersHelp =>
      'दुकान खुलते समय यह फ़ोन दिन का हाल बताएगा: आज देने वाले, देर वाले और तैयार रिपेयर, और वापस कॉल करने वाली पूछताछ। फ़ोन ने आख़िरी बार जो देखा उसी से — रोज़ ऐप खोलें।';

  @override
  String get remindersAt => 'कब';

  @override
  String get remindersOff => 'इस फ़ोन पर बंद';

  @override
  String reminderDue(int n) {
    return 'आज $n';
  }

  @override
  String reminderLate(int n) {
    return 'देर $n';
  }

  @override
  String reminderReady(int n) {
    return 'लौटाने को तैयार $n';
  }

  @override
  String reminderRingBack(int n) {
    return 'वापस कॉल $n';
  }

  @override
  String reminderRingBackTitle(String name) {
    return 'वापस कॉल करें: $name';
  }

  @override
  String get exportCsv => 'एक्सपोर्ट';

  @override
  String get exportBills => 'बिल, स्प्रेडशीट में (CSV)';

  @override
  String get exportRepairs => 'रिपेयर, स्प्रेडशीट में (CSV)';

  @override
  String exportFailed(String reason) {
    return 'एक्सपोर्ट नहीं हो सका: $reason';
  }

  @override
  String get exportStock => 'आज स्टॉक में फ़ोन (CSV)';

  @override
  String reminderReorder(int n) {
    return 'दोबारा मँगाने $n';
  }

  @override
  String get imeiScanSecond =>
      'मिल गया। दूसरा IMEI भी स्कैन करें, या हो गया दबाएँ।';

  @override
  String get imeiScanBoth => 'दोनों IMEI स्कैन हो गए।';

  @override
  String get imeiScanNoCamera => 'कैमरा नहीं चल रहा। IMEI टाइप करें।';

  @override
  String get imeiScanDone => 'हो गया';

  @override
  String get declarationTitle => 'बेचने वाले की घोषणा';

  @override
  String get declarationHint =>
      'हर पंक्ति बेचने वाले को पढ़कर सुनाएँ, फिर हस्ताक्षर करवाएँ।';

  @override
  String get declarationAgreed => 'बेचने वाले ने यह सब सुना और माना';

  @override
  String get idCheckedTitle => 'सरकारी फ़ोटो पहचान पत्र देखा गया';

  @override
  String get idCheckedHint =>
      'आपने बेचने वाले का आधार, पैन, वोटर आईडी या लाइसेंस देखा।';

  @override
  String get helpDeclaration =>
      'अगर फ़ोन चोरी का निकले तो यह दुकान को बचाता है। हर पंक्ति बेचने वाले को ज़ोर से पढ़ें। जब वे मान जाएँ, तो बॉक्स पर टिक करें और उँगली से हस्ताक्षर करवाएँ।';

  @override
  String get purchaseTerm1 =>
      'मैं इस फ़ोन का कानूनी मालिक हूँ और मुझे इसे बेचने का अधिकार है।';

  @override
  String get purchaseTerm2 =>
      'यह फ़ोन चोरी का या खोया हुआ नहीं है, गैरकानूनी तरीके से नहीं लिया गया, और किसी पुलिस शिकायत, FIR या अदालती मामले में नहीं है।';

  @override
  String get purchaseTerm3 =>
      'इस फ़ोन पर कोई लोन, EMI, बीमा दावा या किसी और का दावा नहीं है।';

  @override
  String get purchaseTerm4 =>
      'मैंने अपना निजी डेटा हटा दिया है, हर अकाउंट (Google, iCloud, Mi, Samsung और अन्य) से साइन आउट कर लिया है और हर स्क्रीन लॉक हटा दिया है।';

  @override
  String get purchaseTerm5 =>
      'मैं यह फ़ोन अपनी मर्ज़ी से, ऊपर लिखी रकम पर बेच रहा/रही हूँ, और मुझे वह पूरी रकम मिल गई है।';

  @override
  String get purchaseTerm6 =>
      'पैसे मिलते ही फ़ोन दुकान का हो जाता है। यह आख़िरी बिक्री है: यह मुझे वापस नहीं मिलेगा, और वापस ख़रीदने का कोई विकल्प नहीं है।';

  @override
  String get purchaseTerm7 =>
      'दुकान मुझसे पूछे बिना फ़ोन को तुरंत ठीक, नया या दोबारा बेच सकती है, और उस पर मेरा कोई दावा नहीं रहेगा।';

  @override
  String get purchaseTerm8 =>
      'इस बिक्री से पहले फ़ोन के मालिकाना हक़ या इस्तेमाल से दुकान पर आने वाले किसी भी नुकसान, दावे या कानूनी कार्रवाई की भरपाई मैं करूँगा/करूँगी।';

  @override
  String get purchaseTerm9 =>
      'मैंने वैध सरकारी फ़ोटो पहचान पत्र दिखाया है, और उसकी कॉपी इस फ़ॉर्म के साथ रखी गई है।';

  @override
  String get printNow => 'प्रिंट करें';

  @override
  String get printShare => 'भेजें (WhatsApp और अन्य)';

  @override
  String printFailed(String error) {
    return 'प्रिंट नहीं हो सका: $error';
  }

  @override
  String get printEnglishNote =>
      'हर प्रिंटर पर दिखे, इसलिए अंग्रेज़ी में प्रिंट होगा।';

  @override
  String get printLockCode => 'PIN या पैटर्न प्रिंट करें';

  @override
  String get printLockCodeHint =>
      'सिर्फ़ ग्राहक की सहमति हो तो। कार्ड काउंटर पर पड़ा रह सकता है।';

  @override
  String get printJobCardTitle => 'जॉब कार्ड';

  @override
  String get printFinalBillTitle => 'फ़ाइनल बिल';

  @override
  String get printBillTitle => 'बिल';

  @override
  String get printDeclarationTitle => 'ख़रीद घोषणा';

  @override
  String get printLabelTitle => 'लेबल';

  @override
  String get printLabelPdf => 'लेबल स्टिकर प्रिंट करें';

  @override
  String get scanWithCamera => 'कैमरे से स्कैन करें';

  @override
  String get scanTorch => 'टॉर्च';

  @override
  String get scanPointAtLabel =>
      'स्टिकर के बारकोड या IMEI बारकोड की ओर कैमरा करें।';

  @override
  String get scanOrType => 'या नंबर टाइप करें';

  @override
  String get patternDraw => 'उँगली से पैटर्न बनाएँ';

  @override
  String get patternClear => 'फिर से बनाएँ';

  @override
  String get patternTitle => 'ग्राहक का अनलॉक पैटर्न';

  @override
  String get contactCall => 'कॉल करें';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactNoNumber =>
      'इस रिकॉर्ड पर भेजने के लिए मोबाइल नंबर नहीं है।';

  @override
  String get contactCouldNotOpen => 'इस फ़ोन पर नहीं खुल सका।';

  @override
  String get contactRemind => 'WhatsApp पर याद दिलाएँ';

  @override
  String waHello(String name, String shop) {
    return 'नमस्ते $name, हम $shop से बोल रहे हैं।';
  }

  @override
  String waServiceReceived(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'नमस्ते $name, आपका $device (ऑर्डर $order) हमें मिल गया है। हम आपको बताते रहेंगे। - $shop';
  }

  @override
  String waServiceInProgress(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'नमस्ते $name, आपका $device (ऑर्डर $order) अभी ठीक किया जा रहा है। तैयार होते ही बताएँगे। - $shop';
  }

  @override
  String waServiceParts(String name, String device, String order, String shop) {
    return 'नमस्ते $name, आपके $device (ऑर्डर $order) के पार्ट्स का इंतज़ार है। आते ही बताएँगे। - $shop';
  }

  @override
  String waServiceApproval(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'नमस्ते $name, आपके $device (ऑर्डर $order) पर अतिरिक्त काम के लिए आपकी मंज़ूरी चाहिए। कृपया कॉल करें या आएँ। - $shop';
  }

  @override
  String waServiceReady(String name, String device, String order, String shop) {
    return 'नमस्ते $name, आपका $device (ऑर्डर $order) तैयार है। कृपया आकर ले जाएँ। - $shop';
  }

  @override
  String waServiceReturned(
    String name,
    String device,
    String order,
    String shop,
  ) {
    return 'नमस्ते $name, आपका $device (ऑर्डर $order) वापस दे दिया गया है। $shop चुनने के लिए धन्यवाद।';
  }

  @override
  String waDueReminder(String name, String amount, String bill, String shop) {
    return 'नमस्ते $name, विनम्र याद दिलाना है कि बिल $bill पर $amount अभी बाकी है। - $shop';
  }

  @override
  String waEnquiry(String name, String shop, String about) {
    return 'नमस्ते $name, आपकी पूछताछ के बारे में $shop से: $about';
  }

  @override
  String get reportDayByDay => 'दिन-ब-दिन कमाई';

  @override
  String get reportDayByDayHint =>
      'पूरे हुए बिल। ख़ाली दिन जगह छोड़कर दिखता है।';

  @override
  String get reportWhatSold => 'सबसे ज़्यादा क्या बिका';

  @override
  String reportSoldCount(String count) {
    return '$count बिके';
  }

  @override
  String get reportNoSales => 'इस समय में कोई पूरा बिल नहीं।';

  @override
  String get shopDetailsTitle => 'आपकी दुकान';

  @override
  String get shopDetailsHint => 'हर बिल, जॉब कार्ड और घोषणा के ऊपर छपता है।';

  @override
  String get shopDetailsSaved => 'दुकान की जानकारी सेव हो गई';

  @override
  String get shopDetailsSave => 'दुकान की जानकारी सेव करें';

  @override
  String get navImportContacts => 'संपर्क जोड़ें';

  @override
  String get importTitle => 'संपर्क जोड़ें';

  @override
  String get importHint =>
      'फ़ोन बुक या सूची चिपकाएँ। मोबाइल नंबर वाली हर पंक्ति एक ग्राहक बनेगी।';

  @override
  String get helpImport =>
      'अपने संपर्क या Excel, WhatsApp की सूची कॉपी करें, फिर चिपकाएँ दबाएँ। जोड़ें दबाने तक कुछ सेव नहीं होता। जो पहले से ग्राहक हैं, वे छोड़ दिए जाते हैं।';

  @override
  String get importPaste => 'चिपकाएँ';

  @override
  String get importRead => 'पढ़ें';

  @override
  String get importNoneFound => 'चिपकाए गए में कोई मोबाइल नंबर नहीं मिला।';

  @override
  String importSummary(String fresh, String skipped) {
    return '$fresh नए · $skipped पहले से ग्राहक';
  }

  @override
  String importAddAll(int count) {
    return '$count ग्राहक जोड़ें';
  }

  @override
  String importAdded(int count) {
    return '$count ग्राहक जोड़े गए';
  }

  @override
  String get photoTake => 'फ़ोटो लें';

  @override
  String get photoChoose => 'गैलरी से चुनें';

  @override
  String get navRatings => 'रेटिंग';

  @override
  String get rateTitle => 'अपनी मरम्मत को रेट करें';

  @override
  String get rateHowDidWeDo => 'हमारा काम कैसा रहा?';

  @override
  String get rateCommentHint => 'कुछ और कहना है? (वैकल्पिक)';

  @override
  String get rateSend => 'रेटिंग भेजें';

  @override
  String get rateThanks => 'धन्यवाद। आपकी रेटिंग भेज दी गई है।';

  @override
  String get rateAlreadyAnswered =>
      'इस काम की रेटिंग पहले ही दी जा चुकी है। धन्यवाद।';

  @override
  String get rateNotFound =>
      'यह रेटिंग लिंक मान्य नहीं है। दुकान द्वारा भेजा गया लिंक जांचें।';

  @override
  String get ratePickStars => 'रेटिंग चुनने के लिए सितारों पर टैप करें।';

  @override
  String get rateCommentTooLong => 'टिप्पणी 500 अक्षरों से कम रखें।';

  @override
  String get rateCouldNotSend =>
      'भेजा नहीं जा सका। कनेक्शन जांचें और फिर कोशिश करें।';

  @override
  String get askForRating => 'रेटिंग माँगें';

  @override
  String get sendRatingAgain => 'रेटिंग लिंक फिर से भेजें';

  @override
  String ratingReceived(int stars) {
    return 'ग्राहक ने 5 में से $stars दिए';
  }

  @override
  String get ratingNeedsWebAddress =>
      'रेटिंग लिंक भेजने के लिए सेटिंग्स में सार्वजनिक वेब पता सेट करें।';

  @override
  String get ratingLinkCopied =>
      'इस ऑर्डर पर व्हाट्सऐप नंबर नहीं है, इसलिए रेटिंग लिंक कॉपी किया गया।';

  @override
  String ratingsSummary(int answered, int sent) {
    return '$sent में से $answered ने जवाब दिया';
  }

  @override
  String get ratingsAverage => 'औसत';

  @override
  String get ratingsEmpty =>
      'अभी कोई रेटिंग नहीं। पूरे हुए सर्विस ऑर्डर से रेटिंग माँगें।';

  @override
  String get ratingWaiting => 'ग्राहक का इंतज़ार है';

  @override
  String get publicWebAddress => 'सार्वजनिक वेब पता';

  @override
  String get publicWebAddressTitle => 'ग्राहक लिंक';

  @override
  String get publicWebAddressHint =>
      'इस ऐप के सार्वजनिक पेज यहाँ चलते हैं। ग्राहकों को भेजे गए रेटिंग लिंक इसी से शुरू होते हैं।';

  @override
  String get publicWebAddressSaved => 'वेब पता सहेजा गया';

  @override
  String get ratingsNoAnswerYet => 'अभी कोई जवाब नहीं';

  @override
  String ratingJob(String number) {
    return 'काम $number';
  }

  @override
  String get setButton => 'सेट करें';

  @override
  String get setWhatIsCharged => 'लिया जाने वाला शुल्क सेट करें';

  @override
  String chargedAmount(String amount) {
    return 'लिया गया ₹$amount';
  }

  @override
  String get printFinalBill => 'अंतिम बिल प्रिंट करें';

  @override
  String get printJobCard => 'जॉब कार्ड प्रिंट करें';

  @override
  String get handedBackPrintBill =>
      'वापस दे दिया — अंतिम बिल प्रिंट किया जा सकता है';

  @override
  String stillToCheck(String items) {
    return 'अभी जाँचना बाकी: $items';
  }

  @override
  String stillToCheckMore(String items, int count) {
    return 'अभी जाँचना बाकी: $items और $count अन्य';
  }

  @override
  String get cannotHandBackYet => 'इसे अभी वापस नहीं दिया जा सकता';

  @override
  String get markedSold => 'बिका हुआ चिह्नित किया';

  @override
  String get alreadySold => 'पहले ही बिक चुका';

  @override
  String get onBenchNotReady => 'मरम्मत में — बेचने के लिए तैयार नहीं';

  @override
  String get atLeastSixChars => 'कम से कम छह अक्षर';

  @override
  String get addACheck => 'एक जाँच जोड़ें';

  @override
  String get printServerSaved => 'प्रिंट सर्वर सहेजा गया';

  @override
  String get printServerHint =>
      'काउंटर पीसी पर छोटा सर्वर जो लेबल प्रिंटर से बात करता है। प्रिंट करना कभी सेव को नहीं रोकता — बंद प्रिंटर की सूचना दी जाती है, यह गलती नहीं है।';

  @override
  String get stockCountMatched =>
      'गिनती पहले से मेल खाती थी — कुछ दर्ज नहीं हुआ';

  @override
  String stockCorrectedTo(int count) {
    return '$count पर ठीक किया गया, अंतर इतिहास में दर्ज है';
  }

  @override
  String historyDisagrees(String ledger, String balance) {
    return 'इतिहास का जोड़ ₹$ledger है, ₹$balance नहीं। इस रिकॉर्ड को जाँचना होगा।';
  }

  @override
  String get offlineModeNote =>
      'ऑफ़लाइन मोड — कोई खाता नहीं, और इस सत्र के बाद कुछ भी सहेजा नहीं जाता। ऐप देखने के लिए एक भूमिका चुनें।';

  @override
  String checklistCollisions(String items) {
    return 'विराम चिह्न और अक्षरों का आकार हटाने पर ये एक जैसे पढ़े जाते हैं: $items। इन्हें अलग रखा गया है, पर चेकलिस्ट पर ये दोहराव जैसे दिखेंगे।';
  }

  @override
  String get enquiryNobodyOnNumber =>
      'उस नंबर पर रजिस्टर में कोई नहीं — पूछताछ में यहाँ लिखा नंबर रहेगा।';

  @override
  String get wonAsksWhich =>
      'इसे जीता हुआ चिह्नित करने पर पूछा जाएगा कि यह कौन सी बिक्री या मरम्मत बनी।';

  @override
  String get wonOutcomeHelp =>
      'एक बिल नंबर, सर्विस ऑर्डर नंबर, या एक नोट। जिस जीती हुई पूछताछ के पीछे कुछ न हो, उसे गिना नहीं जा सकता।';

  @override
  String get deleteMyAccount => 'मेरा खाता हटाएँ';

  @override
  String get deleteAccountExplain =>
      'इससे आपका लॉगिन हट जाएगा और आप इस दुकान से बाहर हो जाएँगे। दुकान के रिकॉर्ड — स्टॉक, बिल, ग्राहक — दुकान के पास ही रहेंगे। इसे वापस नहीं किया जा सकता।';

  @override
  String get passwordToConfirm => 'पुष्टि के लिए आपका पासवर्ड';

  @override
  String get deleteForever => 'हमेशा के लिए हटाएँ';

  @override
  String get advancePaid => 'अग्रिम भुगतान';

  @override
  String get toCollect => 'लेते समय लेना है';

  @override
  String get statusReady => 'लेने के लिए तैयार';

  @override
  String get tileReadyForPickup => 'लेने के लिए तैयार';

  @override
  String waServiceReadyPay(
    String name,
    String device,
    String order,
    String amount,
    String shop,
  ) {
    return 'नमस्ते $name, आपका $device (ऑर्डर $order) तैयार है। देय राशि: ₹$amount। कृपया आकर ले जाएँ। - $shop';
  }

  @override
  String get paidEmptyMeansFull =>
      'पूरा भुगतान हुआ हो तो खाली छोड़ें। उधार बिक्री के लिए 0 लिखें।';

  @override
  String get staffSeeCostsTitle => 'स्टाफ़ लागत और मुनाफ़ा देख सकता है';

  @override
  String get staffSeeCostsHint =>
      'बंद: स्टाफ़ के फ़ोन पर दुकान की लागत और मुनाफ़ा छिपा रहता है। एडमिन हमेशा देखते हैं।';

  @override
  String productSummaryRetail(int lines, int units, String retail) {
    return '$lines उत्पाद · $units यूनिट · बिक्री ₹$retail';
  }

  @override
  String soldFor(String price) {
    return '₹$price में बिका';
  }

  @override
  String get reportHowPaid => 'भुगतान कैसे हुआ';

  @override
  String get reportWalletUsed => 'ग्राहक वॉलेट से';

  @override
  String get reportStillOwed => 'ग्राहकों पर अभी बकाया';

  @override
  String get reportFinanceNote =>
      'फ़ाइनेंस की रकम फ़ाइनेंस कंपनी देती है, गल्ले में नहीं आती।';

  @override
  String reportBillsCount(int count) {
    return '$count भुगतान';
  }

  @override
  String get lifeOverdue => 'देर से';

  @override
  String get lifeInShop => 'दुकान में';

  @override
  String get lifeFinished => 'पूरा हुआ';

  @override
  String get moveReceived => 'प्राप्त';

  @override
  String get moveSold => 'बिका';

  @override
  String get moveReturned => 'वापस आया';

  @override
  String get moveAdjustedUp => 'स्टॉक गिनती: दर्ज से ज़्यादा';

  @override
  String get moveAdjustedDown => 'स्टॉक गिनती: दर्ज से कम';

  @override
  String get moveDamaged => 'खराब या बट्टे खाते';

  @override
  String get scanModeLabel => 'दुकान का लेबल';

  @override
  String get scanModeRepair => 'नई मरम्मत';

  @override
  String get scanModePurchase => 'फ़ोन खरीदें';

  @override
  String get scanHintLabel =>
      'स्टिकर स्कैन करें, जिस रिकॉर्ड के लिए छपा था वह खुलेगा।';

  @override
  String get scanHintRepair =>
      'ब्रांड और मॉडल भरी मरम्मत शुरू करने के लिए फ़ोन का बारकोड स्कैन करें।';

  @override
  String get scanHintPurchase =>
      'ब्रांड और मॉडल भरी खरीद शुरू करने के लिए फ़ोन का बारकोड स्कैन करें।';

  @override
  String get enqFollowUpOverdue => 'फ़ॉलो-अप में देर';

  @override
  String get enqOpen => 'खुली';

  @override
  String get enqDealtWith => 'निपटाया गया';

  @override
  String get periodToday => 'आज';

  @override
  String get period7 => 'पिछले 7 दिन';

  @override
  String get period30 => 'पिछले 30 दिन';

  @override
  String get periodMonth => 'इस महीने';

  @override
  String get periodCustom => 'अपनी तारीखें';

  @override
  String get figTakings => 'कमाई';

  @override
  String get figTakingsNote =>
      'पूरे हुए बिल, पूरे होने के दिन — चुकाए हों या बाक़ी';

  @override
  String get figService => 'सर्विस की कमाई';

  @override
  String get figServiceNote => 'ग्राहक को लौटाए गए काम, लिए गए दाम पर';

  @override
  String get figMargin => 'पुराने फ़ोन का मुनाफ़ा';

  @override
  String get figMarginNote =>
      'बिक्री दाम में से खरीद, मरम्मत और दूसरे खर्च घटाकर। कमाई का हिस्सा है, उसके ऊपर नहीं';

  @override
  String get figOutstanding => 'बकाया';

  @override
  String get figOutstandingNote =>
      'सभी बिना भुगतान वाले बिलों पर अभी का बकाया — सिर्फ़ इस अवधि का नहीं। फ़ाइनेंस बिक्री नहीं गिनी जाती';

  @override
  String get repairWarranty => 'मरम्मत वारंटी';

  @override
  String get repairWarrantyHint =>
      'अंतिम बिल पर छपता है और फ़ोन वापस आने पर जाँचा जाता है।';

  @override
  String get warrantyNone => 'कोई नहीं';

  @override
  String warrantyDaysN(int days) {
    return '$days दिन';
  }

  @override
  String warrantyUntil(String date) {
    return '$date तक वारंटी';
  }

  @override
  String warrantyEnded(String date) {
    return 'वारंटी $date को खत्म';
  }

  @override
  String warrantyReturning(String date, String order, String until) {
    return 'यहाँ $date को ठीक किया गया ($order) — $until तक अभी वारंटी है।';
  }

  @override
  String get shareReport => 'रिपोर्ट भेजें';

  @override
  String checksTicked(int done, int total) {
    return '$total में से $done पर टिक';
  }

  @override
  String get beforeItGoesBack => 'लौटाने से पहले जाँचें';

  @override
  String get searchEverythingHint => 'नाम, नंबर, IMEI, जॉब या बिल खोजें';

  @override
  String get recentlyOpened => 'हाल में खोले गए';

  @override
  String get searchPages => 'पेज';

  @override
  String get searchEverythingTitle => 'कुछ भी खोजें';

  @override
  String get searchEverythingDetail =>
      'मरम्मत, फ़ोन, बिल, ग्राहक, उत्पाद और पूछताछ — सब एक साथ।';

  @override
  String searchMore(int count) {
    return 'इस सूची में $count और';
  }

  @override
  String get clear => 'साफ़ करें';

  @override
  String get collectedLaterTitle => 'बाद में लिया गया';

  @override
  String get paidAtPickup => 'लेते समय दिया';

  @override
  String howPaidAmount(String amount) {
    return '₹$amount लेना है — भुगतान कैसे हुआ?';
  }

  @override
  String get sendOrderList => 'ऑर्डर सूची व्हाट्सऐप पर भेजें';

  @override
  String get sellMakeBill => 'बेचें — बिल बनाएँ';

  @override
  String get soldWithoutBill => 'बिना बिल के बिका (डीलर को, कहीं और)';

  @override
  String get moveUsedOnRepair => 'मरम्मत में लगाया';

  @override
  String get usePartFromStock => 'स्टॉक से पार्ट लगाएँ';

  @override
  String get partsUsed => 'लगाए गए पार्ट';

  @override
  String partUsedSaved(String part) {
    return '$part स्टॉक से निकालकर इस काम में जोड़ा गया';
  }

  @override
  String get noPartsInStock =>
      'लगाने के लिए स्टॉक में कुछ नहीं। उत्पाद पेज पर पार्ट जोड़ें।';

  @override
  String get gstRateTitle => 'बिल पर GST';

  @override
  String get gstRateHint =>
      'आपकी कीमतों में शामिल GST दर। GSTIN होने पर बिल पर CGST और SGST दिखते हैं। पुराने फ़ोन शामिल नहीं (मार्जिन स्कीम)। दर अपने अकाउंटेंट से पक्की करें।';

  @override
  String get gstOff => 'बंद';

  @override
  String get hintBrands => 'हर इनटेक और खरीद फ़ॉर्म में दिखता है।';

  @override
  String get hintSuppliers => 'उत्पाद जोड़ते समय दिखता है।';

  @override
  String get hintColours => 'खरीद और उत्पाद फ़ॉर्म में दिखता है।';

  @override
  String get hintCategories => 'उत्पाद सूची को समूहों में बाँटता है।';

  @override
  String get hintComplaintTypes =>
      'जॉब कार्ड और अंतिम बिल दोनों इन्हीं से बनते हैं।';

  @override
  String get hintAccessories => 'इनटेक पर टिक होता है, जॉब कार्ड पर छपता है।';

  @override
  String get hintLockTypes => 'डिवाइस आते समय कैसे लॉक था।';

  @override
  String get hintRam => 'खरीद फ़ॉर्म में दिखता है।';

  @override
  String get hintExpenseKinds => 'खर्च जोड़ते समय दिखते हैं।';

  @override
  String get hintRom => 'खरीद फ़ॉर्म में दिखता है।';

  @override
  String get offlineBanner =>
      'ऑफ़लाइन — काम इस फ़ोन पर सेव है, इंटरनेट आने पर अपलोड होगा।';

  @override
  String plusFromRepairs(String amount) {
    return '+ मरम्मत से $amount';
  }

  @override
  String enquiryWonAs(String ref) {
    return 'मरम्मत ली गई — पूछताछ जीती हुई चिह्नित ($ref)';
  }

  @override
  String get tellTheCustomer => 'ग्राहक को बताएँ';

  @override
  String pricePaidBefore(int count, String paid) {
    return 'पहले $count बार $paid में खरीदा';
  }

  @override
  String priceSoldBefore(int count, String avg) {
    return '$count बिके, औसतन $avg में';
  }

  @override
  String get homeBuyPhone => 'फ़ोन खरीदें';

  @override
  String get homeEnquiry => 'पूछताछ';

  @override
  String get tabRepairs => 'रिपेयर';

  @override
  String get homeTodaysSales => 'आज की बिक्री';

  @override
  String homeBillsCount(int count) {
    return '$count बिल';
  }

  @override
  String get homeNewRepair => 'नया रिपेयर';

  @override
  String get homeNeedsAction => 'ध्यान देने वाले रिपेयर';

  @override
  String homeAllCount(int count) {
    return 'सभी $count';
  }

  @override
  String get homeLate => 'देरी';

  @override
  String get homeDueToday => 'आज देना है';

  @override
  String get homeReady => 'तैयार';

  @override
  String get homeJob => 'जॉब';

  @override
  String homeDaysLate(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन देरी',
      one: '1 दिन देरी',
      zero: 'आज देरी',
    );
    return '$_temp0';
  }

  @override
  String homeDueAt(String time) {
    return '$time तक';
  }

  @override
  String homeAmountDue(String amount) {
    return '$amount बाकी';
  }

  @override
  String get homeNothingNeedsAction => 'अभी कुछ नहीं';

  @override
  String get homeAlsoToday => 'और भी';

  @override
  String get homeOpenJob => 'खोलें';

  @override
  String stockDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन',
      one: '1 दिन',
      zero: 'आज',
    );
    return '$_temp0';
  }

  @override
  String get saveFailedTitle => 'सेव नहीं हुआ';

  @override
  String get saveNoInternet =>
      'इंटरनेट नहीं है। आपने जो भरा है वह सुरक्षित है — इंटरनेट आने पर फिर से कोशिश करें।';

  @override
  String get saveNotAllowed =>
      'इस खाते को यह सेव करने की अनुमति नहीं है। दुकान के मालिक से पूछें।';

  @override
  String get saveTimedOut =>
      '20 सेकंड में पुष्टि नहीं हुई। इंटरनेट देखें, फिर से सेव करें।';

  @override
  String saveFailedReason(String reason) {
    return 'सेव नहीं हो सका: $reason';
  }

  @override
  String get okButton => 'ठीक है';

  @override
  String get markReady => 'तैयार मार्क करें';

  @override
  String get lpHint =>
      'इसी फ़ोन पर सेव। TSPL लिखा 2-इंच ब्लूटूथ लेबल प्रिंटर, 50 × 25 मिमी स्टिकर के साथ इस्तेमाल करें।';

  @override
  String get lpBluetooth => 'ब्लूटूथ प्रिंटर';

  @override
  String get lpPhoneMenu => 'फ़ोन का प्रिंट मेनू';

  @override
  String get lpChoose => 'प्रिंटर चुनें';

  @override
  String get lpNone => 'कोई प्रिंटर नहीं चुना';

  @override
  String get lpPairFirst =>
      'कोई जुड़ा प्रिंटर नहीं। प्रिंटर चालू करें, फ़ोन की ब्लूटूथ सेटिंग में जोड़ें, फिर वापस आएँ।';

  @override
  String get lpSize => 'स्टिकर का आकार';

  @override
  String get lpDarkness => 'गहराई';

  @override
  String get lpTest => 'टेस्ट लेबल प्रिंट करें';

  @override
  String get lpTestSent => 'टेस्ट लेबल प्रिंटर को भेजा गया';

  @override
  String get lpRefresh => 'रीफ़्रेश';

  @override
  String get btNoPrinter => 'कोई लेबल प्रिंटर नहीं चुना। सेटिंग में चुनें।';

  @override
  String get btOff => 'ब्लूटूथ बंद है। चालू करके फिर प्रिंट करें।';

  @override
  String get btPermission => 'इस ऐप को ब्लूटूथ की अनुमति दें, फिर प्रिंट करें।';

  @override
  String get btConnect =>
      'प्रिंटर से जुड़ नहीं सका। क्या वह चालू है और फ़ोन के पास है?';

  @override
  String get btWrite =>
      'प्रिंटर ने लेबल नहीं लिया। स्टिकर रोल देखें और फिर कोशिश करें।';

  @override
  String get setGroupShop => 'दुकान';

  @override
  String get setGroupLists => 'फ़ोन और स्टॉक की सूचियाँ';

  @override
  String get setGroupRepairs => 'रिपेयर';

  @override
  String get setGroupPrinting => 'प्रिंटिंग';

  @override
  String get setGroupStaff => 'स्टाफ़ और पैसा';

  @override
  String get setGroupOnline => 'ऑनलाइन';

  @override
  String get setBrandsModels => 'ब्रांड और मॉडल';

  @override
  String get setMemory => 'RAM और स्टोरेज';

  @override
  String setBrandsModelsCount(int brands, int models) {
    return '$brands ब्रांड · $models मॉडल';
  }

  @override
  String setItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आइटम',
      one: '1 आइटम',
      zero: 'खाली',
    );
    return '$_temp0';
  }

  @override
  String get setSearchList => 'इस सूची में खोजें';

  @override
  String get setRename => 'नाम बदलें';

  @override
  String setMemoryCount(int ram, int rom) {
    return '$ram RAM साइज़ · $rom स्टोरेज साइज़';
  }

  @override
  String get setAddNew => 'नया लिखें';

  @override
  String get whereIsItNow => 'अभी कहाँ है?';

  @override
  String get trackReceived => 'मिला';

  @override
  String get trackWorking => 'काम चल रहा';

  @override
  String get trackHandedBack => 'वापस दिया';

  @override
  String sellerSoldBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'पहले $count फ़ोन बेच चुके हैं',
      one: 'पहले 1 फ़ोन बेच चुके हैं',
    );
    return '$_temp0';
  }

  @override
  String get igstTitle => 'दूसरे राज्य का ग्राहक (IGST)';

  @override
  String get igstHint => 'बिल पर CGST + SGST की जगह IGST दिखेगा।';

  @override
  String get batteryHealthLabel => 'बैटरी हेल्थ %';

  @override
  String get batteryHealthHelp =>
      'जैसा फ़ोन दिखाता है: iPhone में Settings → Battery → Battery Health. Android में बैटरी या diagnostics ऐप। देख न सकें तो खाली छोड़ें।';

  @override
  String get batteryHealthHint => 'जैसे 91';

  @override
  String batteryHealthValue(int percent) {
    return 'बैटरी $percent%';
  }

  @override
  String get billQueuedOffline =>
      'इंटरनेट नहीं है: बिल इस फ़ोन पर रखा गया है, इंटरनेट आते ही अपने आप पूरा हो जाएगा।';

  @override
  String get pendingInternet => 'इंटरनेट का इंतज़ार';

  @override
  String get tourRepairAnotherT => 'दो फ़ोन, एक विज़िट';

  @override
  String get tourRepairAnotherB =>
      'ग्राहक एक से ज़्यादा फ़ोन लाए? \"सेव करें और एक और फ़ोन जोड़ें\": अगला काम उनकी जानकारी के साथ शुरू होगा, दोनों काम जुड़े रहेंगे, और एक ही फ़ाइनल बिल में सब आएगा।';

  @override
  String get tourBuyAnotherT => 'उसी विक्रेता से और फ़ोन';

  @override
  String get tourBuyAnotherB =>
      'एक ही व्यक्ति से कई फ़ोन ख़रीद रहे हैं? \"सेव करें और एक और ख़रीदें\": विक्रेता, ID और हस्ताक्षर साथ चलते हैं, और एक ही घोषणा-पत्र में हर फ़ोन कुल रक़म के साथ आता है।';

  @override
  String get tourBillStockT => 'स्टॉक से फ़ोन चुनें';

  @override
  String get tourBillStockB =>
      '\"स्टॉक से जोड़ें\" बिकने को तैयार फ़ोन दिखाता है। मॉडल या IMEI टाइप करें, या ब्रांड पर टैप करें, फिर + जोड़ें। मरम्मत में या बिके हुए फ़ोन वजह के साथ धूसर दिखते हैं।';

  @override
  String get tourImportT => 'अपने संपर्क लाएँ';

  @override
  String get tourImportB =>
      'नाम और नंबरों की सूची पेस्ट करें (या क्लिपबोर्ड से पढ़ें)। जो नंबर पहले से हैं वे छोड़ दिए जाते हैं, कोई दो बार नहीं जुड़ता।';

  @override
  String get importFromPhone => 'फ़ोन संपर्कों से';

  @override
  String get importFromFile => 'फ़ाइल से (CSV या VCF)';

  @override
  String get importContactsDenied =>
      'फ़ोन से लाने के लिए इस ऐप को Contacts की अनुमति दें।';

  @override
  String get importOpenSettings => 'सेटिंग्स';

  @override
  String get importFileUnreadable =>
      'वह फ़ाइल पढ़ी नहीं जा सकी। .csv या .vcf फ़ाइल चुनें।';

  @override
  String get importTickAll => 'सभी चुनें';

  @override
  String get importUntickAll => 'सभी हटाएँ';
}
