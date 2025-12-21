// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Azure DevOps';

  @override
  String get settings => 'Настройки';

  @override
  String get wikiSettings => 'Настройки Wiki';

  @override
  String get wikiSettingsDescription =>
      'Введите URL файла Azure DevOps wiki. Содержимое wiki будет отображаться на главной странице.';

  @override
  String get wikiUrl => 'URL Wiki';

  @override
  String get save => 'Сохранить';

  @override
  String get marketSettings => 'Настройки Маркета';

  @override
  String get marketSettingsDescription =>
      'Введите URL статического каталога IIS. Файлы APK и IPA будут перечислены и доступны для загрузки из этого каталога.';

  @override
  String get marketUrl => 'URL Маркета';

  @override
  String get notificationSettings => 'Настройки Уведомлений';

  @override
  String get controlFrequency => 'Частота Проверки';

  @override
  String get pollingInterval => 'Интервал Опроса (секунды)';

  @override
  String get pollingIntervalHelper => 'От 5 до 300 секунд';

  @override
  String get fast => 'Быстро (10с)';

  @override
  String get normal => 'Обычно (15с)';

  @override
  String get slow => 'Медленно (30с)';

  @override
  String get notificationTypes => 'Типы Уведомлений';

  @override
  String get notifyOnFirstAssignment => 'Уведомление при Первом Назначении';

  @override
  String get notifyOnFirstAssignmentDescription =>
      'Отправлять уведомление только при первом назначении мне';

  @override
  String get notifyOnAllUpdates => 'Уведомление при Всех Обновлениях';

  @override
  String get notifyOnAllUpdatesDescription =>
      'Отправлять уведомление при обновлении рабочих элементов, назначенных мне';

  @override
  String get notifyOnHotfixOnly => 'Только Hotfix';

  @override
  String get notifyOnHotfixOnlyDescription =>
      'Уведомление только для рабочих элементов типа Hotfix';

  @override
  String get notifyOnGroupAssignments => 'Уведомление при Назначении Группам';

  @override
  String get notifyOnGroupAssignmentsDescription =>
      'Отправлять уведомление при назначении указанным группам';

  @override
  String get groupName => 'Имя Группы';

  @override
  String get groupNameHint => 'Например: Разработчики, Команда QA';

  @override
  String get smartwatchNotifications => 'Уведомления на Умные Часы';

  @override
  String get smartwatchNotificationsDescription =>
      'Отправлять уведомления на умные часы (только при первом назначении)';

  @override
  String get onCallMode => 'Режим Дежурства';

  @override
  String get onCallModeDescription =>
      'В режиме дежурства уведомления становятся более агрессивными, а непрочитанные уведомления обновляются 3 раза.';

  @override
  String get onCallModePhone => 'Режим Дежурства для Телефона';

  @override
  String get onCallModePhoneDescription =>
      'Агрессивные уведомления на телефоне';

  @override
  String get onCallModeWatch => 'Режим Дежурства для Умных Часов';

  @override
  String get onCallModeWatchDescription =>
      'Агрессивные уведомления на умных часах';

  @override
  String get vacationMode => 'Режим Отпуска';

  @override
  String get vacationModeDescription =>
      'В режиме отпуска уведомления не приходят.';

  @override
  String get vacationModePhone => 'Режим Отпуска для Телефона';

  @override
  String get vacationModePhoneDescription =>
      'Отключить уведомления на телефоне';

  @override
  String get vacationModeWatch => 'Режим Отпуска для Умных Часов';

  @override
  String get vacationModeWatchDescription =>
      'Отключить уведомления на умных часах';

  @override
  String get serverUrl => 'URL Сервера';

  @override
  String get collection => 'Коллекция';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выберите Язык';

  @override
  String get languageDescription =>
      'Выберите предпочитаемый язык. Приложение будет использовать язык вашего устройства по умолчанию.';

  @override
  String get close => 'Закрыть';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String get invalidUrl => 'Пожалуйста, введите действительный URL';

  @override
  String get invalidPollingInterval =>
      'Интервал опроса должен быть от 5 до 300 секунд';

  @override
  String get noGroupsAdded =>
      'Группы еще не добавлены. Добавьте имя группы выше.';

  @override
  String get donate => 'Пожертвовать';

  @override
  String get donateDescription => 'Поддержите разработку этого приложения';

  @override
  String get donateButton => 'Купите мне кофе';
}
