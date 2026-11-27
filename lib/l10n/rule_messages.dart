/// THE APP'S OWN RULE MESSAGES, IN THE SHOP'S LANGUAGE
///
/// Validation errors and refusals are written once, in English, next to the
/// rule they come from (`lib/domain/…`), because that is where they are
/// tested. This translates them on their way to the screen: [ruleText] looks
/// the English up and returns Tamil or Hindi when the shop works in one.
///
/// A message with a number or a name in it ("An IMEI is 14 to 16 digits; this
/// is 12") is not in the table and is shown as written — see the test that
/// lists which ones.
library;

import 'package:flutter/widgets.dart';

const Map<String, (String, String)> kRuleTranslations = {
  'Paid now cannot be more than the price': (
    'இப்போது கொடுத்தது விலையை விட அதிகமாக இருக்க முடியாது',
    'अभी दिया कीमत से ज़्यादा नहीं हो सकता',
  ),
  'The refund cannot be less than zero': (
    'திருப்பித் தருவது பூஜ்ஜியத்தை விடக் குறைவாக இருக்க முடியாது',
    'वापसी शून्य से कम नहीं हो सकती',
  ),
  'Battery health is 1 to 100%': (
    'பேட்டரி நிலை 1 முதல் 100% வரை',
    'बैटरी हेल्थ 1 से 100% तक',
  ),
  'The discount cannot be more than the line': (
    'தள்ளுபடி அந்த வரியின் தொகையை விட அதிகமாக இருக்க முடியாது',
    'छूट उस लाइन की रकम से ज़्यादा नहीं हो सकती',
  ),
  'A pattern joins at least 4 dots — draw it again': (
    'பேட்டர்ன் குறைந்தது 4 புள்ளிகளை இணைக்கும் — மீண்டும் வரையுங்கள்',
    'पैटर्न में कम से कम 4 बिंदु जुड़ते हैं — फिर से बनाएँ',
  ),
  "This shop has used this month's photos. Ask the app's owner to raise the limit.":
      (
        'இந்தக் கடை இந்த மாதத்திற்கான படங்களை முடித்துவிட்டது. வரம்பை உயர்த்த ஆப் உரிமையாளரிடம் கேளுங்கள்.',
        'इस दुकान ने इस महीने की फ़ोटो पूरी कर ली हैं। सीमा बढ़ाने के लिए ऐप के मालिक से कहें।',
      ),
  'The photo is too big. Try again.': (
    'படம் மிகப் பெரியது. மீண்டும் முயற்சிக்கவும்.',
    'फ़ोटो बहुत बड़ी है। फिर कोशिश करें।',
  ),
  'Give the customer an estimate': (
    'வாடிக்கையாளருக்கு ஒரு மதிப்பீட்டுத் தொகையைச் சொல்லுங்கள்',
    'ग्राहक को अनुमानित कीमत बताएँ',
  ),
  "No internet connection. Check the shop's internet and try again.": (
    'இணைய இணைப்பு இல்லை. கடையின் இணையத்தைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
    'इंटरनेट कनेक्शन नहीं है। दुकान का इंटरनेट जाँचें और फिर कोशिश करें।',
  ),
  'Not allowed. Ask the shop owner to check your access.': (
    'அனுமதி இல்லை. உங்கள் அணுகலைச் சரிபார்க்க கடை உரிமையாளரிடம் கேளுங்கள்.',
    'अनुमति नहीं है। दुकान मालिक से अपनी पहुँच जाँचने को कहें।',
  ),
  'Please sign in again.': (
    'மீண்டும் உள்நுழையவும்.',
    'कृपया फिर से साइन इन करें।',
  ),
  'Too many tries. Wait a minute and try again.': (
    'பல முறை முயற்சித்தீர்கள். ஒரு நிமிடம் காத்திருந்து மீண்டும் முயற்சிக்கவும்.',
    'बहुत बार कोशिश हुई। एक मिनट रुककर फिर कोशिश करें।',
  ),
  'Somebody else changed this at the same moment. Try again.': (
    'இதே நேரத்தில் வேறொருவர் இதை மாற்றினார். மீண்டும் முயற்சிக்கவும்.',
    'इसी समय किसी और ने इसे बदला। फिर कोशिश करें।',
  ),
  'It is not there any more. It may have been removed.': (
    'இது இப்போது இல்லை. நீக்கப்பட்டிருக்கலாம்.',
    'यह अब नहीं है। शायद हटा दिया गया।',
  ),
  'Something went wrong. Please try again.': (
    'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.',
    'कुछ गलत हुआ। फिर कोशिश करें।',
  ),
  'That account has been disabled': (
    'அந்தக் கணக்கு முடக்கப்பட்டுள்ளது',
    'वह खाता बंद कर दिया गया है',
  ),
  'No account with that email — sign up instead': (
    'அந்த மின்னஞ்சலில் கணக்கு இல்லை — புதிய கணக்கை உருவாக்கவும்',
    'उस ईमेल से कोई खाता नहीं — नया खाता बनाएँ',
  ),
  'Wrong password': ('தவறான கடவுச்சொல்', 'गलत पासवर्ड'),
  'That email and password do not match an account': (
    'அந்த மின்னஞ்சலும் கடவுச்சொல்லும் எந்தக் கணக்குடனும் பொருந்தவில்லை',
    'यह ईमेल और पासवर्ड किसी खाते से मेल नहीं खाते',
  ),
  'There is already an account with that email': (
    'அந்த மின்னஞ்சலில் ஏற்கனவே ஒரு கணக்கு உள்ளது',
    'उस ईमेल से पहले से एक खाता है',
  ),
  'That password is too short — use at least six characters': (
    'கடவுச்சொல் மிகச் சிறியது — குறைந்தது ஆறு எழுத்துகள் தேவை',
    'पासवर्ड बहुत छोटा है — कम से कम छह अक्षर रखें',
  ),
  "Could not reach the server. Check the shop's internet.": (
    'சர்வரை அடைய முடியவில்லை. கடையின் இணையத்தைச் சரிபார்க்கவும்.',
    'सर्वर तक नहीं पहुँच सके। दुकान का इंटरनेट जाँचें।',
  ),
  'Enter your email': ('உங்கள் மின்னஞ்சலை உள்ளிடவும்', 'अपना ईमेल डालें'),
  'Enter your password': (
    'உங்கள் கடவுச்சொல்லை உள்ளிடவும்',
    'अपना पासवर्ड डालें',
  ),
  'Something went wrong. Check the email and password.': (
    'ஏதோ தவறு நடந்தது. மின்னஞ்சலையும் கடவுச்சொல்லையும் சரிபார்க்கவும்.',
    'कुछ गलत हुआ। ईमेल और पासवर्ड जाँचें।',
  ),
  'Fill in every field': ('எல்லாப் புலங்களையும் நிரப்பவும்', 'हर खाना भरें'),
  'Email sign-in is not switched on for this app yet': (
    'இந்த ஆப்பிற்கு மின்னஞ்சல் உள்நுழைவு இன்னும் இயக்கப்படவில்லை',
    'इस ऐप के लिए ईमेल साइन-इन अभी चालू नहीं है',
  ),
  'Could not create the account. Check the email and password, then try again.':
      (
        'கணக்கை உருவாக்க முடியவில்லை. மின்னஞ்சலையும் கடவுச்சொல்லையும் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
        'खाता नहीं बना। ईमेल और पासवर्ड जाँचकर फिर कोशिश करें।',
      ),
  'Could not sign in. Check the email and password, then try again.': (
    'உள்நுழைய முடியவில்லை. மின்னஞ்சலையும் கடவுச்சொல்லையும் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
    'साइन इन नहीं हुआ। ईमेल और पासवर्ड जाँचकर फिर कोशिश करें।',
  ),
  'Nothing on the bill yet': (
    'பில்லில் இன்னும் எதுவும் இல்லை',
    'बिल में अभी कुछ नहीं',
  ),
  'A customer is needed — pick one or add them': (
    'வாடிக்கையாளர் தேவை — ஒருவரைத் தேர்வுசெய்யவும் அல்லது சேர்க்கவும்',
    'ग्राहक चाहिए — किसी को चुनें या जोड़ें',
  ),
  'A line needs saying what it is': (
    'ஒவ்வொரு வரியிலும் அது என்ன என்று குறிப்பிட வேண்டும்',
    'हर लाइन में लिखें कि वह क्या है',
  ),
  'A line cannot have a negative price': (
    'ஒரு வரியின் விலை எதிர்மறையாக இருக்க முடியாது',
    'किसी लाइन का दाम माइनस में नहीं हो सकता',
  ),
  'A discount is larger than its line — it has been capped at the line total': (
    'தள்ளுபடி வரியை விடப் பெரியது — வரி மொத்தத்துக்குக் குறைக்கப்பட்டது',
    'छूट लाइन से ज़्यादा है — लाइन के कुल तक सीमित की गई',
  ),
  'An amount paid cannot be negative': (
    'செலுத்திய தொகை எதிர்மறையாக இருக்க முடியாது',
    'दी गई रकम माइनस में नहीं हो सकती',
  ),
  'Say why it is going back unrepaired': (
    'பழுது பார்க்காமல் ஏன் திருப்பப்படுகிறது என்று சொல்லவும்',
    'बिना ठीक किए क्यों लौटाया जा रहा है, बताएँ',
  ),
  'Say why the bill is cancelled': (
    'பில் ஏன் ரத்து செய்யப்படுகிறது என்று சொல்லவும்',
    'बिल क्यों रद्द हो रहा है, बताएँ',
  ),
  'Write RAM as the box does, like 8GB': (
    'பெட்டியில் உள்ளபடி RAM எழுதவும், எ.கா. 8GB',
    'RAM डिब्बे जैसा लिखें, जैसे 8GB',
  ),
  'Write storage as the box does, like 128GB or 1TB': (
    'பெட்டியில் உள்ளபடி சேமிப்பை எழுதவும், எ.கா. 128GB அல்லது 1TB',
    'स्टोरेज डिब्बे जैसा लिखें, जैसे 128GB या 1TB',
  ),
  'Battery health is 0 to 100%': (
    'பேட்டரி நிலை 0 முதல் 100% வரை',
    'बैटरी हेल्थ 0 से 100% तक होती है',
  ),
  'This IMEI\'s check digit does not add up — re-scan it': (
    'இந்த IMEI-யின் சரிபார்ப்பு இலக்கம் பொருந்தவில்லை — மீண்டும் ஸ்கேன் செய்யவும்',
    'इस IMEI का चेक अंक नहीं मिलता — फिर से स्कैन करें',
  ),
  'This IMEI is already on a phone in stock': (
    'இந்த IMEI ஏற்கனவே கையிருப்பில் உள்ள ஒரு போனில் உள்ளது',
    'यह IMEI पहले से स्टॉक के एक फ़ोन पर है',
  ),
  'More from the wallet than the whole bill': (
    'முழு பில்லை விட வாலட்டிலிருந்து அதிகம்',
    'पूरे बिल से ज़्यादा वॉलेट से',
  ),
  'A phone number is needed — it is how the shop finds them': (
    'போன் எண் தேவை — கடை அவர்களைக் கண்டுபிடிப்பது அதன் மூலமே',
    'फ़ोन नंबर चाहिए — दुकान इसी से उन्हें ढूँढती है',
  ),
  'That is not a ten-digit mobile number': (
    'அது பத்து இலக்க மொபைல் எண் அல்ல',
    'यह दस अंकों का मोबाइल नंबर नहीं है',
  ),
  'Both numbers are the same': (
    'இரண்டு எண்களும் ஒன்றே',
    'दोनों नंबर एक ही हैं',
  ),
  'That is not an email address': (
    'அது மின்னஞ்சல் முகவரி அல்ல',
    'यह ईमेल पता नहीं है',
  ),
  'Brand is needed': ('பிராண்ட் தேவை', 'ब्रांड चाहिए'),
  'Model is needed': ('மாடல் தேவை', 'मॉडल चाहिए'),
  'RAM is needed': ('RAM தேவை', 'RAM चाहिए'),
  'Storage (ROM) is needed': ('ஸ்டோரேஜ் (ROM) தேவை', 'स्टोरेज (ROM) चाहिए'),
  'The serial number is needed for an iPhone': (
    'ஐபோனுக்கு சீரியல் எண் தேவை',
    'आईफ़ोन के लिए सीरियल नंबर चाहिए',
  ),
  'IMEI is needed — take it off the phone, not the box': (
    'IMEI தேவை — பெட்டியிலிருந்து அல்ல, போனிலிருந்து எடுக்கவும்',
    'IMEI चाहिए — डिब्बे से नहीं, फ़ोन से लें',
  ),
  'Check digit does not add up — worth re-scanning': (
    'சரிபார்ப்பு இலக்கம் பொருந்தவில்லை — மீண்டும் ஸ்கேன் செய்வது நல்லது',
    'चेक अंक मेल नहीं खाता — दोबारा स्कैन करें',
  ),
  'An IMEI is 14 to 16 digits': (
    'IMEI 14 முதல் 16 இலக்கங்கள்',
    'IMEI 14 से 16 अंकों का होता है',
  ),
  'The two IMEIs are the same number': (
    'இரண்டு IMEI-களும் ஒரே எண்',
    'दोनों IMEI एक ही नंबर हैं',
  ),
  'What was paid for it is needed': (
    'அதற்குச் செலுத்திய தொகை தேவை',
    'इसके लिए दी गई रकम चाहिए',
  ),
  'A selling price cannot be negative': (
    'விற்பனை விலை எதிர்மறையாக இருக்க முடியாது',
    'बिक्री दाम माइनस में नहीं हो सकता',
  ),
  'The selling price is needed': ('விற்பனை விலை தேவை', 'बिक्री दाम चाहिए'),
  'The purchase date is needed': ('வாங்கிய தேதி தேவை', 'खरीद की तारीख चाहिए'),
  'A front view of the device is needed': (
    'சாதனத்தின் முன்பக்கப் படம் தேவை',
    'डिवाइस की सामने की फ़ोटो चाहिए',
  ),
  'The seller\'s name is needed for the declaration': (
    'அறிவிப்புக்கு விற்பவரின் பெயர் தேவை',
    'घोषणा के लिए बेचने वाले का नाम चाहिए',
  ),
  'The seller\'s phone number is needed': (
    'விற்பவரின் போன் எண் தேவை',
    'बेचने वाले का फ़ोन नंबर चाहिए',
  ),
  'A repair cannot cost a negative amount': (
    'பழுதுபார்ப்புச் செலவு எதிர்மறையாக இருக்க முடியாது',
    'मरम्मत का खर्च माइनस में नहीं हो सकता',
  ),
  'A costed repair needs saying what it was': (
    'செலவிட்ட பழுதுபார்ப்பு என்ன என்று குறிப்பிட வேண்டும்',
    'जिस मरम्मत का खर्च है, वह क्या थी लिखें',
  ),
  'The seller has to sign the declaration': (
    'விற்பவர் அறிவிப்பில் கையெழுத்திட வேண்டும்',
    'बेचने वाले को घोषणा पर दस्तख़त करने होंगे',
  ),
  'An ID proof reference is needed to print': (
    'அச்சிட அடையாளச் சான்று குறிப்பு தேவை',
    'प्रिंट के लिए पहचान पत्र का नंबर चाहिए',
  ),
  'The shop\'s name is needed — it goes on every bill': (
    'கடையின் பெயர் தேவை — அது எல்லா பில்களிலும் வரும்',
    'दुकान का नाम चाहिए — यह हर बिल पर आता है',
  ),
  'That is too short to be a shop name': (
    'கடைப் பெயருக்கு அது மிகவும் சிறியது',
    'दुकान के नाम के लिए यह बहुत छोटा है',
  ),
  'No phone number, so bills will not carry one': (
    'போன் எண் இல்லை, எனவே பில்களில் அது வராது',
    'फ़ोन नंबर नहीं, इसलिए बिल पर नहीं आएगा',
  ),
  'No IMEI — take it off the phone if it powers on, not the box': (
    'IMEI இல்லை — போன் ஆன் ஆனால் பெட்டியிலிருந்து அல்ல, போனிலிருந்து எடுக்கவும்',
    'IMEI नहीं — फ़ोन चालू हो तो डिब्बे से नहीं, फ़ोन से लें',
  ),
  'Say what is wrong with it — at least one complaint': (
    'என்ன பிரச்சனை என்று சொல்லுங்கள் — குறைந்தது ஒரு புகார்',
    'क्या खराबी है बताएँ — कम से कम एक शिकायत',
  ),
  'A phone cannot come in on a day still to come': (
    'இன்னும் வராத நாளில் போன் வர முடியாது',
    'आने वाले दिन में फ़ोन नहीं आ सकता',
  ),
  'The promised date is before the device came in': (
    'வாக்களித்த தேதி சாதனம் வந்த தேதிக்கு முன்பு உள்ளது',
    'वादे की तारीख डिवाइस आने से पहले की है',
  ),
  'When the device came in is needed': (
    'சாதனம் எப்போது வந்தது என்பது தேவை',
    'डिवाइस कब आया, यह चाहिए',
  ),
  'What the customer was promised is needed': (
    'வாடிக்கையாளருக்கு வாக்களித்தது தேவை',
    'ग्राहक से किया वादा चाहिए',
  ),
  'An estimate cannot be negative': (
    'மதிப்பீடு எதிர்மறையாக இருக்க முடியாது',
    'अनुमान माइनस में नहीं हो सकता',
  ),
  'An advance cannot be negative': (
    'முன்பணம் எதிர்மறையாக இருக்க முடியாது',
    'अग्रिम माइनस में नहीं हो सकता',
  ),
  'A cost cannot be negative': (
    'செலவு எதிர்மறையாக இருக்க முடியாது',
    'खर्च माइनस में नहीं हो सकता',
  ),
  'No estimate given — the customer has not been quoted': (
    'மதிப்பீடு கொடுக்கப்படவில்லை — வாடிக்கையாளருக்கு விலை சொல்லப்படவில்லை',
    'अनुमान नहीं दिया — ग्राहक को दाम नहीं बताया गया',
  ),
  'Nobody is on this job yet': (
    'இந்த வேலையில் இன்னும் யாரும் இல்லை',
    'इस काम पर अभी कोई नहीं है',
  ),
  'This order has already been handed back': (
    'இந்த ஆர்டர் ஏற்கனவே திருப்பிக் கொடுக்கப்பட்டது',
    'यह ऑर्डर पहले ही लौटाया जा चुका है',
  ),
  'Every pre-delivery check has to be ticked before the phone goes back': (
    'போன் திரும்பும் முன் ஒவ்வொரு சரிபார்ப்பும் டிக் செய்யப்பட வேண்டும்',
    'फ़ोन लौटाने से पहले हर जाँच पर टिक होना चाहिए',
  ),
  'Say what is being charged — zero is allowed, but say it': (
    'என்ன வசூலிக்கப்படுகிறது என்று சொல்லுங்கள் — பூஜ்ஜியமும் சரி, ஆனால் சொல்லுங்கள்',
    'कितना लिया जा रहा है बताएँ — शून्य भी चलेगा, पर बताएँ',
  ),
  'A name is needed — it is what the counter searches for': (
    'பெயர் தேவை — கவுண்டர் தேடுவது அதைத்தான்',
    'नाम चाहिए — काउंटर इसी से खोजता है',
  ),
  'No category, so this will not group with anything on the list': (
    'வகை இல்லை, எனவே இது பட்டியலில் எதனுடனும் சேராது',
    'श्रेणी नहीं, इसलिए यह सूची में किसी के साथ नहीं जुड़ेगा',
  ),
  'A selling price is needed': ('விற்பனை விலை தேவை', 'बिक्री दाम चाहिए'),
  'A price cannot be negative': (
    'விலை எதிர்மறையாக இருக்க முடியாது',
    'दाम माइनस में नहीं हो सकता',
  ),
  'A reorder level cannot be negative': (
    'மறுஆர்டர் அளவு எதிர்மறையாக இருக்க முடியாது',
    'दोबारा ऑर्डर का स्तर माइनस में नहीं हो सकता',
  ),
  'No cost price, so the margin on this product cannot be worked out': (
    'அடக்க விலை இல்லை, எனவே இந்தப் பொருளின் லாபத்தைக் கணக்கிட முடியாது',
    'लागत दाम नहीं, इसलिए इस उत्पाद का मुनाफ़ा नहीं निकल सकता',
  ),
  'No photo — the counter has only the name to go on when searching': (
    'படம் இல்லை — தேடும்போது கவுண்டருக்குப் பெயர் மட்டுமே உள்ளது',
    'फ़ोटो नहीं — खोजते समय काउंटर के पास सिर्फ़ नाम है',
  ),
  'No reorder level, so this will never show as low — only as out of stock': (
    'மறுஆர்டர் அளவு இல்லை, எனவே இது குறைவாக எனக் காட்டாது — தீர்ந்ததாக மட்டுமே',
    'दोबारा ऑर्डर का स्तर नहीं, इसलिए यह कम नहीं दिखेगा — सिर्फ़ खत्म होने पर',
  ),
  'A number is needed — the point of recording this is ringing them back': (
    'எண் தேவை — இதைப் பதிவு செய்வதன் நோக்கமே அவர்களைத் திரும்ப அழைப்பதுதான்',
    'नंबर चाहिए — इसे दर्ज करने का मक़सद ही उन्हें वापस फ़ोन करना है',
  ),
  'Say what they asked': (
    'அவர்கள் என்ன கேட்டார்கள் என்று சொல்லுங்கள்',
    'उन्होंने क्या पूछा, बताएँ',
  ),
  'No follow-up date, so this will not come up again on its own': (
    'பின்தொடர்தல் தேதி இல்லை, எனவே இது தானாக மீண்டும் வராது',
    'फ़ॉलो-अप की तारीख नहीं, इसलिए यह अपने आप दोबारा नहीं आएगा',
  ),
  'Nobody recorded as having taken this': (
    'இதை யார் எடுத்தார்கள் என்று பதிவு இல்லை',
    'यह किसने लिया, दर्ज नहीं',
  ),
  'Enter an amount above zero': (
    'பூஜ்ஜியத்துக்கு மேல் தொகையை உள்ளிடவும்',
    'शून्य से ज़्यादा रकम लिखें',
  ),
  'That is more than is owed on this bill — put the extra in the wallet instead':
      (
        'இந்த பில்லில் நிலுவையை விட அதிகம் — கூடுதலை வாலட்டில் வைக்கவும்',
        'यह इस बिल के बकाये से ज़्यादा है — बाकी वॉलेट में डालें',
      ),
  'Only an admin may collect a balance': (
    'நிர்வாகி மட்டுமே நிலுவையை வசூலிக்க முடியும்',
    'सिर्फ़ एडमिन बकाया ले सकता है',
  ),
  'Nothing is owed on this bill': (
    'இந்த பில்லில் எந்த நிலுவையும் இல்லை',
    'इस बिल पर कुछ बकाया नहीं',
  ),
  'daily': ('தினசரி', 'रोज़'),
  'weekly': ('வாராந்திர', 'हर हफ़्ते'),
  'monthly': ('மாதாந்திர', 'हर महीने'),
  'one-time': ('ஒருமுறை', 'एक बार'),
  'Write what has to be done.': (
    'என்ன செய்ய வேண்டும் என்று எழுதுங்கள்.',
    'क्या करना है, लिखें।',
  ),
  'The seller has to sign before the phone is bought': (
    'போனை வாங்கும் முன் விற்பவர் கையொப்பமிட வேண்டும்',
    'फ़ोन ख़रीदने से पहले विक्रेता को हस्ताक्षर करना होगा',
  ),
  'Add both sides of the ID card': (
    'அடையாள அட்டையின் இரு பக்கங்களையும் சேர்க்கவும்',
    'पहचान-पत्र के दोनों तरफ़ की फ़ोटो जोड़ें',
  ),
  'Pick today or a later day.': (
    'இன்றோ அதற்குப் பிறகோ ஒரு நாளைத் தேர்வுசெய்யவும்.',
    'आज या बाद का कोई दिन चुनें।',
  ),
  'Pick the day this has to be done by.': (
    'இது எந்த நாளுக்குள் செய்ய வேண்டும் என்று தேர்வுசெய்யவும்.',
    'यह किस दिन तक करना है, चुनें।',
  ),
  'Only the shop owner can change tasks.': (
    'கடை உரிமையாளர் மட்டுமே பணிகளை மாற்ற முடியும்.',
    'सिर्फ़ दुकान का मालिक काम बदल सकता है।',
  ),
  'This task belongs to someone else.': (
    'இந்தப் பணி வேறொருவருடையது.',
    'यह काम किसी और का है।',
  ),
  'A wallet move needs an amount above zero and below ₹10 crore': (
    'வாலட் மாற்றத்துக்குப் பூஜ்ஜியத்துக்கு மேல், ₹10 கோடிக்குக் கீழ் தொகை தேவை',
    'वॉलेट लेन-देन के लिए शून्य से ज़्यादा और ₹10 करोड़ से कम रकम चाहिए',
  ),
  'The wallet does not hold that much — take the rest another way': (
    'வாலட்டில் அவ்வளவு இல்லை — மீதியை வேறு வழியில் பெறவும்',
    'वॉलेट में इतना नहीं है — बाकी किसी और तरीके से लें',
  ),
  'Say what this wallet move is for': (
    'இந்த வாலட் மாற்றம் எதற்கு என்று சொல்லுங்கள்',
    'यह वॉलेट लेन-देन किसलिए है, बताएँ',
  ),
  'Owner / admin': ('உரிமையாளர் / நிர்வாகி', 'मालिक / एडमिन'),
  'Staff': ('பணியாளர்', 'स्टाफ़'),
  'Only an admin can change who works here': (
    'நிர்வாகி மட்டுமே இங்கு யார் வேலை செய்கிறார்கள் என்பதை மாற்ற முடியும்',
    'सिर्फ़ एडमिन बदल सकता है कि यहाँ कौन काम करता है',
  ),
  'The shop\'s owner cannot be removed or changed to staff': (
    'கடை உரிமையாளரை நீக்கவோ பணியாளராக மாற்றவோ முடியாது',
    'दुकान के मालिक को हटाया या स्टाफ़ नहीं बनाया जा सकता',
  ),
  'That would leave the shop with no admin — make somebody else an admin first':
      (
        'அது கடையை நிர்வாகி இல்லாமல் விடும் — முதலில் வேறொருவரை நிர்வாகியாக்கவும்',
        'इससे दुकान बिना एडमिन रह जाएगी — पहले किसी और को एडमिन बनाएँ',
      ),
  'That person already works here': (
    'அந்த நபர் ஏற்கனவே இங்கு வேலை செய்கிறார்',
    'वह व्यक्ति पहले से यहाँ काम करता है',
  ),
  'Received': ('பெறப்பட்டது', 'प्राप्त'),
  'Sold': ('விற்கப்பட்டது', 'बिका'),
  'Returned': ('திருப்பி வந்தது', 'वापस आया'),
  'Stock-take: more than recorded': (
    'ஸ்டாக் சரிபார்ப்பு: பதிவை விட அதிகம்',
    'स्टॉक गिनती: दर्ज से ज़्यादा',
  ),
  'Stock-take: less than recorded': (
    'ஸ்டாக் சரிபார்ப்பு: பதிவை விட குறைவு',
    'स्टॉक गिनती: दर्ज से कम',
  ),
  'Damaged or written off': (
    'சேதமடைந்தது அல்லது கழிக்கப்பட்டது',
    'खराब या बट्टे खाते',
  ),
  'Used on a repair': (
    'பழுதுபார்ப்பில் பயன்படுத்தப்பட்டது',
    'मरम्मत में लगाया',
  ),
  'Enter a quantity above zero': (
    'பூஜ்ஜியத்துக்கு மேல் அளவை உள்ளிடவும்',
    'शून्य से ज़्यादा मात्रा लिखें',
  ),
  'There is not that much on the shelf — count it, or adjust the stock first': (
    'அலமாரியில் அவ்வளவு இல்லை — எண்ணுங்கள், அல்லது முதலில் ஸ்டாக்கைச் சரிசெய்யவும்',
    'शेल्फ़ पर इतना नहीं है — गिनें, या पहले स्टॉक ठीक करें',
  ),
  'Say what this stock movement is for': (
    'இந்த ஸ்டாக் மாற்றம் எதற்கு என்று சொல்லுங்கள்',
    'यह स्टॉक बदलाव किसलिए है, बताएँ',
  ),
  'Follow-up overdue': ('பின்தொடர்தல் தாமதம்', 'फ़ॉलो-अप में देर'),
  'Open': ('திறந்தது', 'खुली'),
  'Dealt with': ('முடிக்கப்பட்டது', 'निपटाया गया'),
  'Say which sale or repair this became — a won enquiry with nothing to point at cannot be counted':
      (
        'இது எந்த விற்பனை அல்லது பழுதுபார்ப்பாக மாறியது என்று சொல்லுங்கள் — சுட்டிக்காட்ட எதுவும் இல்லாத வென்ற விசாரணையைக் கணக்கிட முடியாது',
        'बताएँ यह कौन सी बिक्री या मरम्मत बनी — जिस जीती पूछताछ के पीछे कुछ न हो, उसे गिना नहीं जा सकता',
      ),
};

/// [english] in the shop's language when it is a known rule message.
String ruleText(BuildContext context, String english) =>
    ruleTextIn(Localizations.localeOf(context).languageCode, english);

/// [english] in the language with code [lang] (`ta`, `hi`, `en`).
String ruleTextIn(String lang, String english) {
  final t = kRuleTranslations[english];
  if (t == null) return _patternText(lang, english);
  return switch (lang) {
    'ta' => t.$1,
    'hi' => t.$2,
    _ => english,
  };
}

/// Every value of a field-to-message map through [ruleText].
Map<String, String> ruleTexts(BuildContext context, Map<String, String> m) => {
  for (final e in m.entries) e.key: ruleText(context, e.value),
};

/// Messages with a number or a name inside, matched by shape. Each pattern's
/// groups are put back into the Tamil or Hindi line as {1}, {2}, ….
final List<(RegExp, String, String)> _patterns = [
  (
    RegExp(r'^An IMEI is 14 to 16 digits; this is (\d+)$'),
    'IMEI 14 முதல் 16 இலக்கங்கள்; இது {1}',
    'IMEI 14 से 16 अंकों का होता है; यह {1} का है',
  ),
  (
    RegExp(r'^Quoted ₹(\S+) against ₹(\S+) of costs$'),
    '₹{2} செலவுக்கு எதிராக ₹{1} மதிப்பிடப்பட்டது',
    '₹{2} खर्च के मुकाबले ₹{1} बताया गया',
  ),
  (
    RegExp(
      r'^The advance \(₹(\S+)\) is more than the job — there is change to give back$',
    ),
    'முன்பணம் (₹{1}) வேலையை விட அதிகம் — மீதியைத் திருப்பித் தர வேண்டும்',
    'अग्रिम (₹{1}) काम से ज़्यादा है — बाकी लौटाना है',
  ),
  (
    RegExp(r'^Locked with (.+) but nothing recorded to unlock it$'),
    '{1} மூலம் பூட்டப்பட்டுள்ளது, ஆனால் திறக்க எதுவும் பதிவு இல்லை',
    '{1} से लॉक है, पर खोलने के लिए कुछ दर्ज नहीं',
  ),
  (
    RegExp(r'^Already in the book as (.+)$'),
    'ஏற்கனவே பதிவேட்டில் {1} என உள்ளது',
    'पहले से रजिस्टर में {1} के रूप में है',
  ),
  (
    RegExp(r'^Already on the list as "(.+)"$'),
    'ஏற்கனவே பட்டியலில் "{1}" என உள்ளது',
    'पहले से सूची में "{1}" के रूप में है',
  ),
  (
    RegExp(r'^That SKU is already on "(.+)"$'),
    'அந்த SKU ஏற்கனவே "{1}" இல் உள்ளது',
    'यह SKU पहले से "{1}" पर है',
  ),
  (
    RegExp(r'^Selling at ₹(\S+) against a ₹(\S+) cost$'),
    '₹{2} அடக்கத்துக்கு எதிராக ₹{1}-க்கு விற்பனை',
    '₹{2} लागत के मुकाबले ₹{1} में बिक्री',
  ),
  (
    RegExp(r'^Priced above the printed maximum of ₹(\S+)$'),
    'அச்சிடப்பட்ட அதிகபட்ச விலையான ₹{1}-ஐ விட அதிகம்',
    'छपी अधिकतम कीमत ₹{1} से ज़्यादा',
  ),
  (
    RegExp(r'^Quoted ₹(\S+) against a ₹(\S+) budget$'),
    '₹{2} பட்ஜெட்டுக்கு எதிராக ₹{1} சொல்லப்பட்டது',
    '₹{2} बजट के मुकाबले ₹{1} बताया गया',
  ),
  (
    RegExp(r'^A GSTIN is 15 characters — this one is (\d+)$'),
    'GSTIN 15 எழுத்துகள் — இது {1}',
    'GSTIN 15 अक्षरों का होता है — यह {1} का है',
  ),
  (
    RegExp(r'^Asking price is at or below the (\S+) this handset has cost$'),
    'கேட்கும் விலை இந்தப் போனுக்கான செலவான {1}-க்குச் சமம் அல்லது குறைவு',
    'माँगी कीमत इस फ़ोन की लागत {1} के बराबर या कम है',
  ),
  (
    RegExp(r'^Marked sellable with (.+)$'),
    '{1} இருந்தும் விற்கத் தயார் எனக் குறிக்கப்பட்டது',
    '{1} होते हुए भी बिक्री योग्य चिह्नित',
  ),
  (
    RegExp(r'^₹(\S+) left on this bill — only an admin may collect it$'),
    'இந்த பில்லில் ₹{1} மீதம் — நிர்வாகி மட்டுமே வசூலிக்க முடியும்',
    'इस बिल पर ₹{1} बाकी — सिर्फ़ एडमिन ले सकता है',
  ),
  (
    RegExp(r'^Paid ₹(\S+) against a ₹(\S+) bill — ₹(\S+) to give back$'),
    '₹{2} பில்லுக்கு ₹{1} செலுத்தப்பட்டது — ₹{3} திருப்பித் தர வேண்டும்',
    '₹{2} के बिल पर ₹{1} दिए — ₹{3} लौटाने हैं',
  ),
  (
    RegExp(
      r'^Financed through (.+): recorded as fully paid, and it will not appear in Due Payments$',
    ),
    '{1} மூலம் நிதி: முழுமையாகச் செலுத்தியதாகப் பதிவு, நிலுவைப் பட்டியலில் வராது',
    '{1} से फ़ाइनेंस: पूरा भुगतान दर्ज, बकाया सूची में नहीं आएगा',
  ),
  (
    RegExp(
      r"^(.+) is not one of the shop's payment methods — treated as a direct payment$",
    ),
    '{1} கடையின் கட்டண முறைகளில் இல்லை — நேரடிக் கட்டணமாகக் கருதப்படுகிறது',
    '{1} दुकान के भुगतान तरीकों में नहीं — सीधा भुगतान माना गया',
  ),
];

String _patternText(String lang, String english) {
  if (lang != 'ta' && lang != 'hi') return english;
  for (final (re, ta, hi) in _patterns) {
    final m = re.firstMatch(english);
    if (m == null) continue;
    var out = lang == 'ta' ? ta : hi;
    for (var i = 1; i <= m.groupCount; i++) {
      out = out.replaceAll('{$i}', m.group(i) ?? '');
    }
    return out;
  }
  return english;
}
