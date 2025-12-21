// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Azure DevOps';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get wikiSettings => 'विकी सेटिंग्स';

  @override
  String get wikiSettingsDescription =>
      'Azure DevOps विकी फ़ाइल का URL दर्ज करें। यह विकी सामग्री होम पेज पर प्रदर्शित की जाएगी।';

  @override
  String get wikiUrl => 'विकी URL';

  @override
  String get save => 'सहेजें';

  @override
  String get marketSettings => 'मार्केट सेटिंग्स';

  @override
  String get marketSettingsDescription =>
      'IIS स्थिर निर्देशिका URL दर्ज करें। APK और IPA फ़ाइलें इस निर्देशिका से सूचीबद्ध और डाउनलोड करने योग्य होंगी।';

  @override
  String get marketUrl => 'मार्केट URL';

  @override
  String get notificationSettings => 'सूचना सेटिंग्स';

  @override
  String get controlFrequency => 'नियंत्रण आवृत्ति';

  @override
  String get pollingInterval => 'पोलिंग अंतराल (सेकंड)';

  @override
  String get pollingIntervalHelper => '5-300 सेकंड के बीच';

  @override
  String get fast => 'तेज़ (10s)';

  @override
  String get normal => 'सामान्य (15s)';

  @override
  String get slow => 'धीमा (30s)';

  @override
  String get notificationTypes => 'सूचना प्रकार';

  @override
  String get notifyOnFirstAssignment => 'पहले असाइनमेंट पर सूचना';

  @override
  String get notifyOnFirstAssignmentDescription =>
      'केवल पहली बार मुझे असाइन किए जाने पर सूचना भेजें';

  @override
  String get notifyOnAllUpdates => 'सभी अपडेट पर सूचना';

  @override
  String get notifyOnAllUpdatesDescription =>
      'मुझे असाइन किए गए कार्य आइटम अपडेट होने पर सूचना भेजें';

  @override
  String get notifyOnHotfixOnly => 'केवल Hotfix';

  @override
  String get notifyOnHotfixOnlyDescription =>
      'केवल Hotfix प्रकार के कार्य आइटम के लिए सूचना';

  @override
  String get notifyOnGroupAssignments => 'समूह असाइनमेंट पर सूचना';

  @override
  String get notifyOnGroupAssignmentsDescription =>
      'निर्दिष्ट समूहों को असाइनमेंट किए जाने पर सूचना भेजें';

  @override
  String get groupName => 'समूह नाम';

  @override
  String get groupNameHint => 'उदाहरण: डेवलपर्स, QA टीम';

  @override
  String get smartwatchNotifications => 'स्मार्टवॉच सूचनाएं';

  @override
  String get smartwatchNotificationsDescription =>
      'स्मार्टवॉच पर सूचनाएं भेजें (केवल पहले असाइनमेंट पर)';

  @override
  String get onCallMode => 'ऑन-कॉल मोड';

  @override
  String get onCallModeDescription =>
      'ऑन-कॉल मोड में, सूचनाएं अधिक आक्रामक हो जाती हैं और अपठित सूचनाएं 3 बार ताज़ा की जाती हैं।';

  @override
  String get onCallModePhone => 'फोन के लिए ऑन-कॉल मोड';

  @override
  String get onCallModePhoneDescription => 'फोन पर आक्रामक सूचनाएं';

  @override
  String get onCallModeWatch => 'स्मार्टवॉच के लिए ऑन-कॉल मोड';

  @override
  String get onCallModeWatchDescription => 'स्मार्टवॉच पर आक्रामक सूचनाएं';

  @override
  String get vacationMode => 'छुट्टी मोड';

  @override
  String get vacationModeDescription =>
      'छुट्टी मोड में कोई सूचना प्राप्त नहीं होती है।';

  @override
  String get vacationModePhone => 'फोन के लिए छुट्टी मोड';

  @override
  String get vacationModePhoneDescription => 'फोन पर सूचनाएं अक्षम करें';

  @override
  String get vacationModeWatch => 'स्मार्टवॉच के लिए छुट्टी मोड';

  @override
  String get vacationModeWatchDescription => 'स्मार्टवॉच पर सूचनाएं अक्षम करें';

  @override
  String get serverUrl => 'सर्वर URL';

  @override
  String get collection => 'संग्रह';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get languageDescription =>
      'अपनी पसंदीदा भाषा चुनें। ऐप डिफ़ॉल्ट रूप से आपकी डिवाइस भाषा का उपयोग करेगा।';

  @override
  String get close => 'बंद करें';

  @override
  String get settingsSaved => 'सेटिंग्स सहेजी गईं';

  @override
  String get invalidUrl => 'कृपया एक वैध URL दर्ज करें';

  @override
  String get invalidPollingInterval =>
      'पोलिंग अंतराल 5-300 सेकंड के बीच होना चाहिए';

  @override
  String get noGroupsAdded =>
      'अभी तक कोई समूह नहीं जोड़ा गया है। ऊपर से समूह नाम जोड़ें।';

  @override
  String get donate => 'दान करें';

  @override
  String get donateDescription => 'इस ऐप के विकास का समर्थन करें';

  @override
  String get donateButton => 'मुझे एक कॉफी खरीदें';
}
