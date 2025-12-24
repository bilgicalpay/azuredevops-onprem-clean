// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Azure DevOps';

  @override
  String get settings => 'Einstellungen';

  @override
  String get wikiSettings => 'Wiki-Einstellungen';

  @override
  String get wikiSettingsDescription =>
      'Geben Sie die URL der Azure DevOps Wiki-Datei ein. Dieser Wiki-Inhalt wird auf der Startseite angezeigt.';

  @override
  String get wikiUrl => 'Wiki-URL';

  @override
  String get save => 'Speichern';

  @override
  String get marketSettings => 'Markt-Einstellungen';

  @override
  String get marketSettingsDescription =>
      'Geben Sie die URL des IIS-Statikverzeichnisses ein. APK- und IPA-Dateien werden aus diesem Verzeichnis aufgelistet und heruntergeladen.';

  @override
  String get marketUrl => 'Markt-URL';

  @override
  String get notificationSettings => 'Benachrichtigungseinstellungen';

  @override
  String get controlFrequency => 'Kontrollhäufigkeit';

  @override
  String get pollingInterval => 'Abfrageintervall (Sekunden)';

  @override
  String get pollingIntervalHelper => 'Zwischen 5-300 Sekunden';

  @override
  String get fast => 'Schnell (10s)';

  @override
  String get normal => 'Normal (15s)';

  @override
  String get slow => 'Langsam (30s)';

  @override
  String get notificationTypes => 'Benachrichtigungstypen';

  @override
  String get notifyOnFirstAssignment => 'Benachrichtigung bei Erster Zuweisung';

  @override
  String get notifyOnFirstAssignmentDescription =>
      'Benachrichtigung nur senden, wenn mir zum ersten Mal zugewiesen';

  @override
  String get notifyOnAllUpdates =>
      'Benachrichtigung bei Allen Aktualisierungen';

  @override
  String get notifyOnAllUpdatesDescription =>
      'Benachrichtigung senden, wenn mir zugewiesene Arbeitselemente aktualisiert werden';

  @override
  String get notifyOnHotfixOnly => 'Nur Hotfix';

  @override
  String get notifyOnHotfixOnlyDescription =>
      'Benachrichtigung nur für Arbeitselemente vom Typ Hotfix';

  @override
  String get notifyOnGroupAssignments =>
      'Benachrichtigung bei Gruppen-Zuweisungen';

  @override
  String get notifyOnGroupAssignmentsDescription =>
      'Benachrichtigung senden, wenn Zuweisungen an angegebene Gruppen vorgenommen werden';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get groupNameHint => 'Z.B.: Entwickler, QA-Team';

  @override
  String get smartwatchNotifications => 'Smartwatch-Benachrichtigungen';

  @override
  String get smartwatchNotificationsDescription =>
      'Benachrichtigungen an Smartwatches senden (nur bei erster Zuweisung)';

  @override
  String get onCallMode => 'Bereitschaftsmodus';

  @override
  String get onCallModeDescription =>
      'Im Bereitschaftsmodus werden Benachrichtigungen aggressiver und ungelesene Benachrichtigungen werden 3-mal aktualisiert.';

  @override
  String get onCallModePhone => 'Bereitschaftsmodus für Telefon';

  @override
  String get onCallModePhoneDescription =>
      'Aggressive Benachrichtigungen auf dem Telefon';

  @override
  String get onCallModeWatch => 'Bereitschaftsmodus für Smartwatch';

  @override
  String get onCallModeWatchDescription =>
      'Aggressive Benachrichtigungen auf der Smartwatch';

  @override
  String get vacationMode => 'Urlaubsmodus';

  @override
  String get vacationModeDescription =>
      'Im Urlaubsmodus werden keine Benachrichtigungen empfangen.';

  @override
  String get vacationModePhone => 'Urlaubsmodus für Telefon';

  @override
  String get vacationModePhoneDescription =>
      'Benachrichtigungen auf dem Telefon deaktivieren';

  @override
  String get vacationModeWatch => 'Urlaubsmodus für Smartwatch';

  @override
  String get vacationModeWatchDescription =>
      'Benachrichtigungen auf der Smartwatch deaktivieren';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String get collection => 'Sammlung';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Sprache Auswählen';

  @override
  String get languageDescription =>
      'Wählen Sie Ihre bevorzugte Sprache. Die App verwendet standardmäßig die Sprache Ihres Geräts.';

  @override
  String get close => 'Schließen';

  @override
  String get settingsSaved => 'Einstellungen gespeichert';

  @override
  String get invalidUrl => 'Bitte geben Sie eine gültige URL ein';

  @override
  String get invalidMarketUrl =>
      'Bitte geben Sie eine gültige Markt-URL ein (z.B: https://devops.higgscloud.com/_static/market/)';

  @override
  String get invalidPollingInterval =>
      'Abfrageintervall muss zwischen 5-300 Sekunden liegen';

  @override
  String couldNotOpenLink(String error) {
    return 'Link konnte nicht geöffnet werden: $error';
  }

  @override
  String get wikiUrlHint =>
      'https://devops.higgscloud.com/Dev/demo/_wiki/wikis/CAB-Plan/1/README';

  @override
  String get marketUrlHint => 'https://devops.higgscloud.com/_static/market/';

  @override
  String get noGroupsAdded =>
      'Noch keine Gruppen hinzugefügt. Fügen Sie oben einen Gruppennamen hinzu.';

  @override
  String get donate => 'Spenden';

  @override
  String get donateDescription => 'Unterstützen Sie die Entwicklung dieser App';

  @override
  String get donateButton => 'Kaufen Sie mir einen Kaffee';

  @override
  String get closePopup => 'Close';

  @override
  String get companySettings => 'Company/Logo Settings';

  @override
  String get companySettingsDescription =>
      'Customize the company name and logo displayed in the top right corner.';

  @override
  String get logoDisplayMode => 'Logo Display Mode';

  @override
  String get logoModeAuto => 'Auto';

  @override
  String get logoModeCustom => 'Custom';

  @override
  String get logoModeNone => 'Hide';

  @override
  String get detectedCompany => 'Detected company';

  @override
  String get notDetected => 'Not detected';

  @override
  String get companyName => 'Company Name';

  @override
  String get companyNameHint => 'E.g: My Company Inc.';

  @override
  String get companyLogoUrl => 'Logo URL';

  @override
  String get companyLogoUrlHint => 'https://example.com/logo.png';

  @override
  String get logoPreview => 'Logo Preview';
}
