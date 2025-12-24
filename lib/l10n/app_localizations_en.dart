// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Azure DevOps';

  @override
  String get settings => 'Settings';

  @override
  String get wikiSettings => 'Wiki Settings';

  @override
  String get wikiSettingsDescription =>
      'Enter the URL of the Azure DevOps wiki file. This wiki content will be displayed on the home page.';

  @override
  String get wikiUrl => 'Wiki URL';

  @override
  String get save => 'Save';

  @override
  String get marketSettings => 'Market Settings';

  @override
  String get marketSettingsDescription =>
      'Enter the IIS static directory URL. APK and IPA files will be listed and downloadable from this directory.';

  @override
  String get marketUrl => 'Market URL';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get controlFrequency => 'Control Frequency';

  @override
  String get pollingInterval => 'Polling Interval (seconds)';

  @override
  String get pollingIntervalHelper => 'Between 5-300 seconds';

  @override
  String get fast => 'Fast (10s)';

  @override
  String get normal => 'Normal (15s)';

  @override
  String get slow => 'Slow (30s)';

  @override
  String get notificationTypes => 'Notification Types';

  @override
  String get notifyOnFirstAssignment => 'Notification on First Assignment';

  @override
  String get notifyOnFirstAssignmentDescription =>
      'Send notification only when first assigned to me';

  @override
  String get notifyOnAllUpdates => 'Notification on All Updates';

  @override
  String get notifyOnAllUpdatesDescription =>
      'Send notification when work items assigned to me are updated';

  @override
  String get notifyOnHotfixOnly => 'Only Hotfix';

  @override
  String get notifyOnHotfixOnlyDescription =>
      'Notification for work items of Hotfix type only';

  @override
  String get notifyOnGroupAssignments => 'Notification on Group Assignments';

  @override
  String get notifyOnGroupAssignmentsDescription =>
      'Send notification when assignments are made to specified groups';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupNameHint => 'E.g: Developers, QA Team';

  @override
  String get smartwatchNotifications => 'Smartwatch Notifications';

  @override
  String get smartwatchNotificationsDescription =>
      'Send notifications to smartwatches (only on first assignment)';

  @override
  String get onCallMode => 'On-Call Mode';

  @override
  String get onCallModeDescription =>
      'In on-call mode, notifications become more aggressive and unread notifications are refreshed 3 times.';

  @override
  String get onCallModePhone => 'On-Call Mode for Phone';

  @override
  String get onCallModePhoneDescription => 'Aggressive notifications on phone';

  @override
  String get onCallModeWatch => 'On-Call Mode for Smart Watch';

  @override
  String get onCallModeWatchDescription =>
      'Aggressive notifications on smartwatch';

  @override
  String get vacationMode => 'Vacation Mode';

  @override
  String get vacationModeDescription =>
      'No notifications are received in vacation mode.';

  @override
  String get vacationModePhone => 'Vacation Mode for Phone';

  @override
  String get vacationModePhoneDescription => 'Disable notifications on phone';

  @override
  String get vacationModeWatch => 'Vacation Mode for Smart Watch';

  @override
  String get vacationModeWatchDescription =>
      'Disable notifications on smartwatch';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get collection => 'Collection';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageDescription =>
      'Choose your preferred language. The app will use your device language by default.';

  @override
  String get close => 'Close';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get invalidUrl => 'Please enter a valid URL';

  @override
  String get invalidMarketUrl =>
      'Please enter a valid Market URL (e.g: https://devops.higgscloud.com/_static/market/)';

  @override
  String get invalidPollingInterval =>
      'Polling interval must be between 5-300 seconds';

  @override
  String couldNotOpenLink(String error) {
    return 'Could not open link: $error';
  }

  @override
  String get wikiUrlHint =>
      'https://devops.higgscloud.com/Dev/demo/_wiki/wikis/CAB-Plan/1/README';

  @override
  String get marketUrlHint => 'https://devops.higgscloud.com/_static/market/';

  @override
  String get noGroupsAdded => 'No groups added yet. Add a group name above.';

  @override
  String get donate => 'Donate';

  @override
  String get donateDescription => 'Support the development of this app';

  @override
  String get donateButton => 'Buy Me a Coffee';

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
