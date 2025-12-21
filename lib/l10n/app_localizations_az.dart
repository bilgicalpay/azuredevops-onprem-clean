// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get appTitle => 'Azure DevOps';

  @override
  String get settings => 'Parametrlər';

  @override
  String get wikiSettings => 'Wiki Parametrləri';

  @override
  String get wikiSettingsDescription =>
      'Azure DevOps wiki faylının URL-ni daxil edin. Bu wiki məzmunu ana səhifədə göstəriləcək.';

  @override
  String get wikiUrl => 'Wiki URL';

  @override
  String get save => 'Saxla';

  @override
  String get marketSettings => 'Bazar Parametrləri';

  @override
  String get marketSettingsDescription =>
      'IIS statik qovluğunun URL-ni daxil edin. APK və IPA faylları bu qovluqdan siyahıya alınacaq və yüklənə biləcək.';

  @override
  String get marketUrl => 'Bazar URL';

  @override
  String get notificationSettings => 'Bildiriş Parametrləri';

  @override
  String get controlFrequency => 'Nəzarət Tezliyi';

  @override
  String get pollingInterval => 'Sorğu Aralığı (saniyə)';

  @override
  String get pollingIntervalHelper => '5-300 saniyə arası';

  @override
  String get fast => 'Sürətli (10s)';

  @override
  String get normal => 'Normal (15s)';

  @override
  String get slow => 'Yavaş (30s)';

  @override
  String get notificationTypes => 'Bildiriş Növləri';

  @override
  String get notifyOnFirstAssignment => 'İlk Təyinatda Bildiriş';

  @override
  String get notifyOnFirstAssignmentDescription =>
      'Yalnız mənə ilk dəfə təyin edildikdə bildiriş göndər';

  @override
  String get notifyOnAllUpdates => 'Bütün Yeniləmələrdə Bildiriş';

  @override
  String get notifyOnAllUpdatesDescription =>
      'Mənə təyin edilmiş iş elementləri yeniləndikdə bildiriş göndər';

  @override
  String get notifyOnHotfixOnly => 'Yalnız Hotfix';

  @override
  String get notifyOnHotfixOnlyDescription =>
      'Yalnız Hotfix tipindəki iş elementləri üçün bildiriş';

  @override
  String get notifyOnGroupAssignments => 'Qrup Təyinləmələrində Bildiriş';

  @override
  String get notifyOnGroupAssignmentsDescription =>
      'Göstərilən qruplara təyinat edildikdə bildiriş göndər';

  @override
  String get groupName => 'Qrup Adı';

  @override
  String get groupNameHint => 'Məsələn: İnkişafçılar, QA Komandası';

  @override
  String get smartwatchNotifications => 'Ağıllı Saat Bildirişləri';

  @override
  String get smartwatchNotificationsDescription =>
      'Ağıllı saatlərə bildiriş göndər (yalnız ilk təyinatda)';

  @override
  String get onCallMode => 'Növbə Rejimi';

  @override
  String get onCallModeDescription =>
      'Növbə rejimində bildirişlər daha aqressiv olur və oxunmamış bildirişlər 3 dəfə yenilənir.';

  @override
  String get onCallModePhone => 'Telefon üçün Növbə Rejimi';

  @override
  String get onCallModePhoneDescription => 'Telefonda aqressiv bildirişlər';

  @override
  String get onCallModeWatch => 'Ağıllı Saat üçün Növbə Rejimi';

  @override
  String get onCallModeWatchDescription => 'Ağıllı saatdə aqressiv bildirişlər';

  @override
  String get vacationMode => 'Tətil Rejimi';

  @override
  String get vacationModeDescription =>
      'Tətil rejimində heç bir bildiriş alınmır.';

  @override
  String get vacationModePhone => 'Telefon üçün Tətil Rejimi';

  @override
  String get vacationModePhoneDescription =>
      'Telefonda bildirişləri deaktiv et';

  @override
  String get vacationModeWatch => 'Ağıllı Saat üçün Tətil Rejimi';

  @override
  String get vacationModeWatchDescription =>
      'Ağıllı saatdə bildirişləri deaktiv et';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get collection => 'Kolleksiya';

  @override
  String get language => 'Dil';

  @override
  String get selectLanguage => 'Dil Seçin';

  @override
  String get languageDescription =>
      'İstədiyiniz dili seçin. Tətbiq standart olaraq cihazınızın dilini istifadə edəcək.';

  @override
  String get close => 'Bağla';

  @override
  String get settingsSaved => 'Parametrlər saxlanıldı';

  @override
  String get invalidUrl => 'Zəhmət olmasa düzgün URL daxil edin';

  @override
  String get invalidPollingInterval =>
      'Sorğu aralığı 5-300 saniyə arasında olmalıdır';

  @override
  String get noGroupsAdded =>
      'Hələ qrup əlavə edilməyib. Yuxarıdan qrup adı əlavə edin.';

  @override
  String get donate => 'İanə Et';

  @override
  String get donateDescription => 'Bu tətbiqin inkişafını dəstəkləyin';

  @override
  String get donateButton => 'Mənə Bir Qəhvə Al';
}
