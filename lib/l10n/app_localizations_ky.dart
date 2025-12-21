// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kirghiz Kyrgyz (`ky`).
class AppLocalizationsKy extends AppLocalizations {
  AppLocalizationsKy([String locale = 'ky']) : super(locale);

  @override
  String get appTitle => 'Azure DevOps';

  @override
  String get settings => 'Жөндөөлөр';

  @override
  String get wikiSettings => 'Wiki Жөндөөлөрү';

  @override
  String get wikiSettingsDescription =>
      'Azure DevOps wiki файлынын URL дарегин киргизиңиз. Бул wiki мазмуну башкы бетте көрсөтүлөт.';

  @override
  String get wikiUrl => 'Wiki URL';

  @override
  String get save => 'Сактоо';

  @override
  String get marketSettings => 'Базар Жөндөөлөрү';

  @override
  String get marketSettingsDescription =>
      'IIS статикалык директориясынын URL дарегин киргизиңиз. APK жана IPA файлдары бул директориядан тизмеленет жана жүктөлөт.';

  @override
  String get marketUrl => 'Базар URL';

  @override
  String get notificationSettings => 'Эскертүүлөр Жөндөөлөрү';

  @override
  String get controlFrequency => 'Көзөмөлдөө Жыштыгы';

  @override
  String get pollingInterval => 'Суроо Аралыгы (секунд)';

  @override
  String get pollingIntervalHelper => '5-300 секунд арасы';

  @override
  String get fast => 'Тез (10s)';

  @override
  String get normal => 'Кадимки (15s)';

  @override
  String get slow => 'Жай (30s)';

  @override
  String get notificationTypes => 'Эскертүү Түрлөрү';

  @override
  String get notifyOnFirstAssignment => 'Биринчи Тайындоодо Эскертүү';

  @override
  String get notifyOnFirstAssignmentDescription =>
      'Мага биринчи жолу тайындалганда гана эскертүү жөнөтүңүз';

  @override
  String get notifyOnAllUpdates => 'Бардык Жаңылоолордо Эскертүү';

  @override
  String get notifyOnAllUpdatesDescription =>
      'Мага тайындалган жумуш элементтери жаңыланганда эскертүү жөнөтүңүз';

  @override
  String get notifyOnHotfixOnly => 'Жалгыз Hotfix';

  @override
  String get notifyOnHotfixOnlyDescription =>
      'Жалгыз Hotfix түрүндөгү жумуш элементтери үчүн эскертүү';

  @override
  String get notifyOnGroupAssignments => 'Топ Тайындоолорунда Эскертүү';

  @override
  String get notifyOnGroupAssignmentsDescription =>
      'Көрсөтүлгөн топторго тайындоо жасоодо эскертүү жөнөтүңүз';

  @override
  String get groupName => 'Топ Аты';

  @override
  String get groupNameHint => 'Мисалы: Өнүктүрүүчүлөр, QA Тобу';

  @override
  String get smartwatchNotifications => 'Акылдуу Саат Эскертүүлөрү';

  @override
  String get smartwatchNotificationsDescription =>
      'Акылдуу сааттарга эскертүү жөнөтүңүз (жалгыз биринчи тайындоодо)';

  @override
  String get onCallMode => 'Кызмат Режими';

  @override
  String get onCallModeDescription =>
      'Кызмат режиминде эскертүүлөр күчтүүрөөк болот жана окулбаган эскертүүлөр 3 жолу жаңыланат.';

  @override
  String get onCallModePhone => 'Телефон үчүн Кызмат Режими';

  @override
  String get onCallModePhoneDescription => 'Телефондо күчтүү эскертүүлөр';

  @override
  String get onCallModeWatch => 'Акылдуу Саат үчүн Кызмат Режими';

  @override
  String get onCallModeWatchDescription => 'Акылдуу саатта күчтүү эскертүүлөр';

  @override
  String get vacationMode => 'Эс Алуу Режими';

  @override
  String get vacationModeDescription =>
      'Эс алуу режиминде эч кандай эскертүү кабыл алынбайт.';

  @override
  String get vacationModePhone => 'Телефон үчүн Эс Алуу Режими';

  @override
  String get vacationModePhoneDescription => 'Телефондо эскертүүлөрдү өчүрүңүз';

  @override
  String get vacationModeWatch => 'Акылдуу Саат үчүн Эс Алуу Режими';

  @override
  String get vacationModeWatchDescription =>
      'Акылдуу саатта эскертүүлөрдү өчүрүңүз';

  @override
  String get serverUrl => 'Сервер URL';

  @override
  String get collection => 'Жыйнак';

  @override
  String get language => 'Тил';

  @override
  String get selectLanguage => 'Тилди Тандаңыз';

  @override
  String get languageDescription =>
      'Өзүңүздүн каалаган тилиңизди тандаңыз. Колдонмо ыңгайлаштырылган жобого ылайык түзүлүштүн тилин колдонот.';

  @override
  String get close => 'Жабуу';

  @override
  String get settingsSaved => 'Жөндөөлөр сакталды';

  @override
  String get invalidUrl => 'Сураныч, туура URL дарегин киргизиңиз';

  @override
  String get invalidPollingInterval =>
      'Суроо аралыгы 5-300 секунд арасында болушу керек';

  @override
  String get noGroupsAdded =>
      'Азырынча эч кандай топ кошулган жок. Жогорудан топ атын кошуңуз.';

  @override
  String get donate => 'Жардам Берүү';

  @override
  String get donateDescription => 'Бул колдонмонун өнүгүүсүн колдоңуз';

  @override
  String get donateButton => 'Мага Бир Кофе Сатып Бер';
}
