/// REMINDERS THE PHONE SHOWS ITSELF
///
/// The morning summary and the enquiry call-backs are scheduled on the phone
/// (Android's own alarms), from the records the app last saw — no server, no
/// extra Firebase plan. The web preview has no reminders (conditional
/// import), so nothing is scheduled there.
library;

export 'phone_reminders_none.dart'
    if (dart.library.io) 'phone_reminders_android.dart';
