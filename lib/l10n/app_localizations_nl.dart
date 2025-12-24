// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Azure DevOps';

  @override
  String get settings => 'Instellingen';

  @override
  String get wikiSettings => 'Wiki Instellingen';

  @override
  String get wikiSettingsDescription =>
      'Voer de URL van het Azure DevOps wiki-bestand in. Deze wiki-inhoud wordt op de startpagina weergegeven.';

  @override
  String get wikiUrl => 'Wiki URL';

  @override
  String get save => 'Opslaan';

  @override
  String get marketSettings => 'Markt Instellingen';

  @override
  String get marketSettingsDescription =>
      'Voer de URL van de IIS statische directory in. APK- en IPA-bestanden worden uit deze directory weergegeven en gedownload.';

  @override
  String get marketUrl => 'Markt URL';

  @override
  String get notificationSettings => 'Melding Instellingen';

  @override
  String get controlFrequency => 'Controle Frequentie';

  @override
  String get pollingInterval => 'Polling Interval (seconden)';

  @override
  String get pollingIntervalHelper => 'Tussen 5-300 seconden';

  @override
  String get fast => 'Snel (10s)';

  @override
  String get normal => 'Normaal (15s)';

  @override
  String get slow => 'Langzaam (30s)';

  @override
  String get notificationTypes => 'Melding Typen';

  @override
  String get notifyOnFirstAssignment => 'Melding bij Eerste Toewijzing';

  @override
  String get notifyOnFirstAssignmentDescription =>
      'Melding alleen verzenden bij eerste toewijzing aan mij';

  @override
  String get notifyOnAllUpdates => 'Melding bij Alle Updates';

  @override
  String get notifyOnAllUpdatesDescription =>
      'Melding verzenden wanneer aan mij toegewezen werkitems worden bijgewerkt';

  @override
  String get notifyOnHotfixOnly => 'Alleen Hotfix';

  @override
  String get notifyOnHotfixOnlyDescription =>
      'Melding alleen voor werkitems van het type Hotfix';

  @override
  String get notifyOnGroupAssignments => 'Melding bij Groepstoewijzingen';

  @override
  String get notifyOnGroupAssignmentsDescription =>
      'Melding verzenden wanneer toewijzingen worden gemaakt aan opgegeven groepen';

  @override
  String get groupName => 'Groepsnaam';

  @override
  String get groupNameHint => 'Bijv: Ontwikkelaars, QA Team';

  @override
  String get smartwatchNotifications => 'Smartwatch Meldingen';

  @override
  String get smartwatchNotificationsDescription =>
      'Meldingen naar smartwatches verzenden (alleen bij eerste toewijzing)';

  @override
  String get onCallMode => 'Dienstmodus';

  @override
  String get onCallModeDescription =>
      'In dienstmodus worden meldingen agressiever en ongelezen meldingen worden 3 keer vernieuwd.';

  @override
  String get onCallModePhone => 'Dienstmodus voor Telefoon';

  @override
  String get onCallModePhoneDescription => 'Agressieve meldingen op telefoon';

  @override
  String get onCallModeWatch => 'Dienstmodus voor Smartwatch';

  @override
  String get onCallModeWatchDescription => 'Agressieve meldingen op smartwatch';

  @override
  String get vacationMode => 'Vakantiemodus';

  @override
  String get vacationModeDescription =>
      'In vakantiemodus worden geen meldingen ontvangen.';

  @override
  String get vacationModePhone => 'Vakantiemodus voor Telefoon';

  @override
  String get vacationModePhoneDescription =>
      'Meldingen op telefoon uitschakelen';

  @override
  String get vacationModeWatch => 'Vakantiemodus voor Smartwatch';

  @override
  String get vacationModeWatchDescription =>
      'Meldingen op smartwatch uitschakelen';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get collection => 'Collectie';

  @override
  String get language => 'Taal';

  @override
  String get selectLanguage => 'Selecteer Taal';

  @override
  String get languageDescription =>
      'Kies uw voorkeurstaal. De app gebruikt standaard de taal van uw apparaat.';

  @override
  String get close => 'Sluiten';

  @override
  String get settingsSaved => 'Instellingen opgeslagen';

  @override
  String get invalidUrl => 'Voer een geldige URL in';

  @override
  String get invalidMarketUrl =>
      'Voer een geldige Markt URL in (bijv: https://devops.higgscloud.com/_static/market/)';

  @override
  String get invalidPollingInterval =>
      'Polling interval moet tussen 5-300 seconden liggen';

  @override
  String couldNotOpenLink(String error) {
    return 'Kon link niet openen: $error';
  }

  @override
  String get wikiUrlHint =>
      'https://devops.higgscloud.com/Dev/demo/_wiki/wikis/CAB-Plan/1/README';

  @override
  String get marketUrlHint => 'https://devops.higgscloud.com/_static/market/';

  @override
  String get noGroupsAdded =>
      'Nog geen groepen toegevoegd. Voeg hierboven een groepsnaam toe.';

  @override
  String get donate => 'Doneren';

  @override
  String get donateDescription => 'Ondersteun de ontwikkeling van deze app';

  @override
  String get donateButton => 'Koop me een Koffie';

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
