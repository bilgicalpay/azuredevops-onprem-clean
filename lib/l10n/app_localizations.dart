import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ug.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ky'),
    Locale('nl'),
    Locale('ru'),
    Locale('tr'),
    Locale('ug'),
    Locale('ur')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Azure DevOps'**
  String get appTitle;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Wiki settings section title
  ///
  /// In en, this message translates to:
  /// **'Wiki Settings'**
  String get wikiSettings;

  /// Wiki settings description
  ///
  /// In en, this message translates to:
  /// **'Enter the URL of the Azure DevOps wiki file. This wiki content will be displayed on the home page.'**
  String get wikiSettingsDescription;

  /// Wiki URL input label
  ///
  /// In en, this message translates to:
  /// **'Wiki URL'**
  String get wikiUrl;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Market settings section title
  ///
  /// In en, this message translates to:
  /// **'Market Settings'**
  String get marketSettings;

  /// Market settings description
  ///
  /// In en, this message translates to:
  /// **'Enter the IIS static directory URL. APK and IPA files will be listed and downloadable from this directory.'**
  String get marketSettingsDescription;

  /// Market URL input label
  ///
  /// In en, this message translates to:
  /// **'Market URL'**
  String get marketUrl;

  /// Notification settings section title
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Control frequency section title
  ///
  /// In en, this message translates to:
  /// **'Control Frequency'**
  String get controlFrequency;

  /// Polling interval input label
  ///
  /// In en, this message translates to:
  /// **'Polling Interval (seconds)'**
  String get pollingInterval;

  /// Polling interval helper text
  ///
  /// In en, this message translates to:
  /// **'Between 5-300 seconds'**
  String get pollingIntervalHelper;

  /// Fast polling interval button
  ///
  /// In en, this message translates to:
  /// **'Fast (10s)'**
  String get fast;

  /// Normal polling interval button
  ///
  /// In en, this message translates to:
  /// **'Normal (15s)'**
  String get normal;

  /// Slow polling interval button
  ///
  /// In en, this message translates to:
  /// **'Slow (30s)'**
  String get slow;

  /// Notification types section title
  ///
  /// In en, this message translates to:
  /// **'Notification Types'**
  String get notificationTypes;

  /// Notify on first assignment toggle title
  ///
  /// In en, this message translates to:
  /// **'Notification on First Assignment'**
  String get notifyOnFirstAssignment;

  /// Notify on first assignment description
  ///
  /// In en, this message translates to:
  /// **'Send notification only when first assigned to me'**
  String get notifyOnFirstAssignmentDescription;

  /// Notify on all updates toggle title
  ///
  /// In en, this message translates to:
  /// **'Notification on All Updates'**
  String get notifyOnAllUpdates;

  /// Notify on all updates description
  ///
  /// In en, this message translates to:
  /// **'Send notification when work items assigned to me are updated'**
  String get notifyOnAllUpdatesDescription;

  /// Notify on hotfix only toggle title
  ///
  /// In en, this message translates to:
  /// **'Only Hotfix'**
  String get notifyOnHotfixOnly;

  /// Notify on hotfix only description
  ///
  /// In en, this message translates to:
  /// **'Notification for work items of Hotfix type only'**
  String get notifyOnHotfixOnlyDescription;

  /// Notify on group assignments toggle title
  ///
  /// In en, this message translates to:
  /// **'Notification on Group Assignments'**
  String get notifyOnGroupAssignments;

  /// Notify on group assignments description
  ///
  /// In en, this message translates to:
  /// **'Send notification when assignments are made to specified groups'**
  String get notifyOnGroupAssignmentsDescription;

  /// Group name input label
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// Group name input hint
  ///
  /// In en, this message translates to:
  /// **'E.g: Developers, QA Team'**
  String get groupNameHint;

  /// Smartwatch notifications toggle title
  ///
  /// In en, this message translates to:
  /// **'Smartwatch Notifications'**
  String get smartwatchNotifications;

  /// Smartwatch notifications description
  ///
  /// In en, this message translates to:
  /// **'Send notifications to smartwatches (only on first assignment)'**
  String get smartwatchNotificationsDescription;

  /// On-call mode section title
  ///
  /// In en, this message translates to:
  /// **'On-Call Mode'**
  String get onCallMode;

  /// On-call mode description
  ///
  /// In en, this message translates to:
  /// **'In on-call mode, notifications become more aggressive and unread notifications are refreshed 3 times.'**
  String get onCallModeDescription;

  /// On-call mode for phone toggle title
  ///
  /// In en, this message translates to:
  /// **'On-Call Mode for Phone'**
  String get onCallModePhone;

  /// On-call mode for phone description
  ///
  /// In en, this message translates to:
  /// **'Aggressive notifications on phone'**
  String get onCallModePhoneDescription;

  /// On-call mode for watch toggle title
  ///
  /// In en, this message translates to:
  /// **'On-Call Mode for Smart Watch'**
  String get onCallModeWatch;

  /// On-call mode for watch description
  ///
  /// In en, this message translates to:
  /// **'Aggressive notifications on smartwatch'**
  String get onCallModeWatchDescription;

  /// Vacation mode section title
  ///
  /// In en, this message translates to:
  /// **'Vacation Mode'**
  String get vacationMode;

  /// Vacation mode description
  ///
  /// In en, this message translates to:
  /// **'No notifications are received in vacation mode.'**
  String get vacationModeDescription;

  /// Vacation mode for phone toggle title
  ///
  /// In en, this message translates to:
  /// **'Vacation Mode for Phone'**
  String get vacationModePhone;

  /// Vacation mode for phone description
  ///
  /// In en, this message translates to:
  /// **'Disable notifications on phone'**
  String get vacationModePhoneDescription;

  /// Vacation mode for watch toggle title
  ///
  /// In en, this message translates to:
  /// **'Vacation Mode for Smart Watch'**
  String get vacationModeWatch;

  /// Vacation mode for watch description
  ///
  /// In en, this message translates to:
  /// **'Disable notifications on smartwatch'**
  String get vacationModeWatchDescription;

  /// Server URL label
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// Collection label
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// Language settings section title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Select language dropdown label
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Language settings description
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language. The app will use your device language by default.'**
  String get languageDescription;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Settings saved message
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// Invalid URL error message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get invalidUrl;

  /// Invalid polling interval error message
  ///
  /// In en, this message translates to:
  /// **'Polling interval must be between 5-300 seconds'**
  String get invalidPollingInterval;

  /// No groups added message
  ///
  /// In en, this message translates to:
  /// **'No groups added yet. Add a group name above.'**
  String get noGroupsAdded;

  /// Donate button text
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// Donate section description
  ///
  /// In en, this message translates to:
  /// **'Support the development of this app'**
  String get donateDescription;

  /// Donate button label
  ///
  /// In en, this message translates to:
  /// **'Buy Me a Coffee'**
  String get donateButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'az',
        'de',
        'en',
        'fr',
        'hi',
        'ja',
        'ky',
        'nl',
        'ru',
        'tr',
        'ug',
        'ur'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'ky':
      return AppLocalizationsKy();
    case 'nl':
      return AppLocalizationsNl();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'ug':
      return AppLocalizationsUg();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
