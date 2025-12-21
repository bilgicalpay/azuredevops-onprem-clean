// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Azure DevOps';

  @override
  String get settings => 'Ayarlar';

  @override
  String get wikiSettings => 'Wiki Ayarları';

  @override
  String get wikiSettingsDescription =>
      'Azure DevOps wiki dosyasının URL\'sini girin. Bu wiki içeriği ana sayfada gösterilecektir.';

  @override
  String get wikiUrl => 'Wiki URL';

  @override
  String get save => 'Kaydet';

  @override
  String get marketSettings => 'Market Ayarları';

  @override
  String get marketSettingsDescription =>
      'IIS static dizin URL\'sini girin. Bu dizinden APK ve IPA dosyaları listelenecek ve indirilebilecektir.';

  @override
  String get marketUrl => 'Market URL';

  @override
  String get notificationSettings => 'Bildirim Ayarları';

  @override
  String get controlFrequency => 'Kontrol Sıklığı';

  @override
  String get pollingInterval => 'Polling Interval (saniye)';

  @override
  String get pollingIntervalHelper => '5-300 saniye arası';

  @override
  String get fast => 'Hızlı (10s)';

  @override
  String get normal => 'Normal (15s)';

  @override
  String get slow => 'Yavaş (30s)';

  @override
  String get notificationTypes => 'Bildirim Türleri';

  @override
  String get notifyOnFirstAssignment => 'İlk Atamada Bildirim';

  @override
  String get notifyOnFirstAssignmentDescription =>
      'Sadece bana ilk atandığında bildirim gönder';

  @override
  String get notifyOnAllUpdates => 'Tüm Güncellemelerde Bildirim';

  @override
  String get notifyOnAllUpdatesDescription =>
      'Bana atanmış work item\'lar güncellendiğinde bildirim gönder';

  @override
  String get notifyOnHotfixOnly => 'Sadece Hotfix';

  @override
  String get notifyOnHotfixOnlyDescription =>
      'Sadece Hotfix tipindeki work item\'lar için bildirim';

  @override
  String get notifyOnGroupAssignments => 'Grup Atamalarında Bildirim';

  @override
  String get notifyOnGroupAssignmentsDescription =>
      'Belirtilen gruplara atama yapıldığında bildirim gönder';

  @override
  String get groupName => 'Grup Adı';

  @override
  String get groupNameHint => 'Örn: Developers, QA Team';

  @override
  String get smartwatchNotifications => 'Akıllı Saat Bildirimleri';

  @override
  String get smartwatchNotificationsDescription =>
      'Akıllı saatlere bildirim gönder (sadece ilk atamada)';

  @override
  String get onCallMode => 'Nöbetçi Modu';

  @override
  String get onCallModeDescription =>
      'Nöbetçi modunda bildirimler daha agresif olur ve okunmayan bildirimler 3 kez yenilenir.';

  @override
  String get onCallModePhone => 'Telefon için Nöbetçi Modu';

  @override
  String get onCallModePhoneDescription => 'Telefonda agresif bildirimler';

  @override
  String get onCallModeWatch => 'Akıllı Saat için Nöbetçi Modu';

  @override
  String get onCallModeWatchDescription => 'Akıllı saatte agresif bildirimler';

  @override
  String get vacationMode => 'Tatil Modu';

  @override
  String get vacationModeDescription => 'Tatil modunda hiçbir bildirim gelmez.';

  @override
  String get vacationModePhone => 'Telefon için Tatil Modu';

  @override
  String get vacationModePhoneDescription =>
      'Telefonda bildirimleri devre dışı bırak';

  @override
  String get vacationModeWatch => 'Akıllı Saat için Tatil Modu';

  @override
  String get vacationModeWatchDescription =>
      'Akıllı saatte bildirimleri devre dışı bırak';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get collection => 'Collection';

  @override
  String get language => 'Dil';

  @override
  String get selectLanguage => 'Dil Seçin';

  @override
  String get languageDescription =>
      'Tercih ettiğiniz dili seçin. Uygulama varsayılan olarak cihaz dilinizi kullanacaktır.';

  @override
  String get close => 'Kapat';

  @override
  String get settingsSaved => 'Ayarlar kaydedildi';

  @override
  String get invalidUrl => 'Geçerli bir URL girin';

  @override
  String get invalidPollingInterval =>
      'Polling interval 5-300 saniye arasında olmalıdır';

  @override
  String get noGroupsAdded =>
      'Henüz grup eklenmedi. Yukarıdan grup adı girerek ekleyin.';

  @override
  String get donate => 'Bağış Yap';

  @override
  String get donateDescription => 'Bu uygulamanın geliştirilmesini destekleyin';

  @override
  String get donateButton => 'Bana Bir Kahve Ismarla';
}
