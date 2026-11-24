import 'package:flutter/widgets.dart';

/// THE SHOP'S BUILT-IN LIST VALUES, IN THE PHONE'S LANGUAGE
///
/// Faults, hand-over checks, accessories, lock types and product categories
/// are stored in English (they are the shop's data, and a record written in
/// Tamil must read the same on a phone set to Hindi). On screen, the values
/// the app ships with are shown in Tamil or Hindi; anything the shop typed
/// itself is shown as typed. (FM #24.)
String shopValue(BuildContext context, String value) {
  final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
  if (lang == 'en') return value;
  final t = _values[value];
  if (t == null) return value;
  return lang == 'ta' ? t.$1 : (lang == 'hi' ? t.$2 : value);
}

const Map<String, (String, String)> _values = {
  // Faults (kComplaintTypes)
  'Display broken': ('டிஸ்ப்ளே உடைந்தது', 'डिस्प्ले टूटा'),
  'Display flickering': ('டிஸ்ப்ளே மின்னுகிறது', 'डिस्प्ले झिलमिलाता है'),
  'Touch not working': ('டச் வேலை செய்யவில்லை', 'टच काम नहीं करता'),
  'Battery draining': ('பேட்டரி சீக்கிரம் தீர்கிறது', 'बैटरी जल्दी ख़त्म'),
  'Not charging': ('சார்ஜ் ஆகவில்லை', 'चार्ज नहीं होता'),
  'Charging port loose': ('சார்ஜிங் போர்ட் தளர்வு', 'चार्जिंग पोर्ट ढीला'),
  'Dead / no power': ('ஆன் ஆகவில்லை', 'बंद / चालू नहीं होता'),
  'Overheating': ('அதிக சூடு', 'ज़्यादा गरम'),
  'Speaker not working': ('ஸ்பீக்கர் வேலை செய்யவில்லை', 'स्पीकर काम नहीं करता'),
  'Earpiece not working': ('இயர்பீஸ் வேலை செய்யவில்லை', 'ईयरपीस काम नहीं करता'),
  'Microphone not working': ('மைக் வேலை செய்யவில்லை', 'माइक काम नहीं करता'),
  'Front camera fault': ('முன் கேமரா கோளாறு', 'आगे का कैमरा ख़राब'),
  'Rear camera fault': ('பின் கேமரா கோளாறு', 'पीछे का कैमरा ख़राब'),
  'Network / signal issue': (
    'நெட்வொர்க் / சிக்னல் பிரச்சனை',
    'नेटवर्क / सिग्नल समस्या',
  ),
  'SIM not detected': ('சிம் கண்டறியப்படவில்லை', 'सिम नहीं पढ़ता'),
  'Wi-Fi not working': ('Wi-Fi வேலை செய்யவில்லை', 'Wi-Fi काम नहीं करता'),
  'Bluetooth not working': (
    'ப்ளூடூத் வேலை செய்யவில்லை',
    'ब्लूटूथ काम नहीं करता',
  ),
  'Fingerprint not working': (
    'கைரேகை வேலை செய்யவில்லை',
    'फ़िंगरप्रिंट काम नहीं करता',
  ),
  'Face unlock not working': (
    'முக அன்லாக் வேலை செய்யவில்லை',
    'फ़ेस अनलॉक काम नहीं करता',
  ),
  'Software / hanging': ('சாஃப்ட்வேர் / ஹேங்', 'सॉफ़्टवेयर / हैंग'),
  'Water damaged': ('தண்ணீர் சேதம்', 'पानी से ख़राब'),
  'Buttons not working': ('பட்டன்கள் வேலை செய்யவில்லை', 'बटन काम नहीं करते'),
  'Vibration not working': (
    'அதிர்வு வேலை செய்யவில்லை',
    'वाइब्रेशन काम नहीं करता',
  ),
  'Data recovery': ('டேட்டா மீட்பு', 'डेटा रिकवरी'),
  'Pattern / password unlock': (
    'பேட்டர்ன் / பாஸ்வேர்ட் அன்லாக்',
    'पैटर्न / पासवर्ड अनलॉक',
  ),
  'Other': ('மற்றவை', 'अन्य'),
  // Lock types
  'None': ('இல்லை', 'कोई नहीं'),
  'PIN': ('PIN', 'PIN'),
  'Password': ('பாஸ்வேர்ட்', 'पासवर्ड'),
  'Pattern': ('பேட்டர்ன்', 'पैटर्न'),
  'Fingerprint': ('கைரேகை', 'फ़िंगरप्रिंट'),
  'Face Unlock': ('முக அன்லாக்', 'फ़ेस अनलॉक'),
  // Hand-over checks (kDefaultPreDeliveryChecklist)
  'Display OK': ('டிஸ்ப்ளே சரி', 'डिस्प्ले ठीक'),
  'Touch working across the screen': (
    'திரை முழுதும் டச் வேலை செய்கிறது',
    'पूरी स्क्रीन पर टच चलता है',
  ),
  'Charging tested': ('சார்ஜிங் சோதிக்கப்பட்டது', 'चार्जिंग जाँची'),
  'Battery holds charge': ('பேட்டரி சார்ஜ் நிற்கிறது', 'बैटरी चार्ज टिकाती है'),
  'Both SIM slots register': (
    'இரண்டு சிம் ஸ்லாட்டும் வேலை செய்கின்றன',
    'दोनों सिम स्लॉट चलते हैं',
  ),
  'Wi-Fi and Bluetooth': ('Wi-Fi மற்றும் ப்ளூடூத்', 'Wi-Fi और ब्लूटूथ'),
  'Speaker and earpiece': ('ஸ்பீக்கர் மற்றும் இயர்பீஸ்', 'स्पीकर और ईयरपीस'),
  'Microphone': ('மைக்', 'माइक'),
  'Front and rear camera': ('முன் மற்றும் பின் கேமரா', 'आगे और पीछे का कैमरा'),
  'Fingerprint / face unlock': (
    'கைரேகை / முக அன்லாக்',
    'फ़िंगरप्रिंट / फ़ेस अनलॉक',
  ),
  'Original complaint fixed': (
    'கொண்டு வந்த பிரச்சனை சரியானது',
    'जो शिकायत थी वह ठीक हुई',
  ),
  'Accessories returned to the customer': (
    'உதிரிப் பொருட்கள் வாடிக்கையாளரிடம் திருப்பப்பட்டன',
    'सामान ग्राहक को लौटाया',
  ),
  'Device cleaned': ('போன் சுத்தம் செய்யப்பட்டது', 'फ़ोन साफ़ किया'),
  // Left with the device / product categories
  'Charger': ('சார்ஜர்', 'चार्जर'),
  'Cable': ('கேபிள்', 'केबल'),
  'Earphones': ('இயர்போன்', 'ईयरफ़ोन'),
  'Back cover': ('பேக் கவர்', 'बैक कवर'),
  'Screen guard': ('ஸ்கிரீன் கார்டு', 'स्क्रीन गार्ड'),
  'SIM card': ('சிம் கார்டு', 'सिम कार्ड'),
  'Memory card': ('மெமரி கார்டு', 'मेमोरी कार्ड'),
  'Box': ('பெட்டி', 'डिब्बा'),
  'Bill / warranty card': ('பில் / வாரண்டி கார்டு', 'बिल / वारंटी कार्ड'),
  'Bluetooth earbuds': ('ப்ளூடூத் இயர்பட்ஸ்', 'ब्लूटूथ ईयरबड्स'),
  'Power bank': ('பவர் பேங்க்', 'पावर बैंक'),
  'SIM tools': ('சிம் கருவிகள்', 'सिम टूल'),
  'Car accessory': ('கார் உபகரணம்', 'कार एक्सेसरी'),
  'Speaker': ('ஸ்பீக்கர்', 'स्पीकर'),
  'Smartwatch': ('ஸ்மார்ட்வாட்ச்', 'स्मार्टवॉच'),
  'New handset': ('புதிய போன்', 'नया फ़ोन'),
};
