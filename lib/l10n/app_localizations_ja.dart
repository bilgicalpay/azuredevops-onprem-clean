// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Azure DevOps';

  @override
  String get settings => '設定';

  @override
  String get wikiSettings => 'Wiki設定';

  @override
  String get wikiSettingsDescription =>
      'Azure DevOps wikiファイルのURLを入力してください。このwikiコンテンツはホームページに表示されます。';

  @override
  String get wikiUrl => 'Wiki URL';

  @override
  String get save => '保存';

  @override
  String get marketSettings => 'マーケット設定';

  @override
  String get marketSettingsDescription =>
      'IIS静的ディレクトリのURLを入力してください。APKおよびIPAファイルはこのディレクトリから一覧表示され、ダウンロード可能になります。';

  @override
  String get marketUrl => 'マーケットURL';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get controlFrequency => '制御頻度';

  @override
  String get pollingInterval => 'ポーリング間隔（秒）';

  @override
  String get pollingIntervalHelper => '5-300秒の間';

  @override
  String get fast => '高速（10秒）';

  @override
  String get normal => '通常（15秒）';

  @override
  String get slow => '低速（30秒）';

  @override
  String get notificationTypes => '通知タイプ';

  @override
  String get notifyOnFirstAssignment => '初回割り当て時の通知';

  @override
  String get notifyOnFirstAssignmentDescription => '初めて割り当てられた時のみ通知を送信';

  @override
  String get notifyOnAllUpdates => 'すべての更新時の通知';

  @override
  String get notifyOnAllUpdatesDescription => '割り当てられた作業項目が更新された時に通知を送信';

  @override
  String get notifyOnHotfixOnly => 'Hotfixのみ';

  @override
  String get notifyOnHotfixOnlyDescription => 'Hotfixタイプの作業項目のみ通知';

  @override
  String get notifyOnGroupAssignments => 'グループ割り当て時の通知';

  @override
  String get notifyOnGroupAssignmentsDescription =>
      '指定されたグループに割り当てが行われた時に通知を送信';

  @override
  String get groupName => 'グループ名';

  @override
  String get groupNameHint => '例：開発者、QAチーム';

  @override
  String get smartwatchNotifications => 'スマートウォッチ通知';

  @override
  String get smartwatchNotificationsDescription => 'スマートウォッチに通知を送信（初回割り当て時のみ）';

  @override
  String get onCallMode => 'オンコールモード';

  @override
  String get onCallModeDescription => 'オンコールモードでは、通知がより積極的になり、未読の通知が3回更新されます。';

  @override
  String get onCallModePhone => '電話用オンコールモード';

  @override
  String get onCallModePhoneDescription => '電話での積極的な通知';

  @override
  String get onCallModeWatch => 'スマートウォッチ用オンコールモード';

  @override
  String get onCallModeWatchDescription => 'スマートウォッチでの積極的な通知';

  @override
  String get vacationMode => '休暇モード';

  @override
  String get vacationModeDescription => '休暇モードでは通知を受信しません。';

  @override
  String get vacationModePhone => '電話用休暇モード';

  @override
  String get vacationModePhoneDescription => '電話での通知を無効化';

  @override
  String get vacationModeWatch => 'スマートウォッチ用休暇モード';

  @override
  String get vacationModeWatchDescription => 'スマートウォッチでの通知を無効化';

  @override
  String get serverUrl => 'サーバーURL';

  @override
  String get collection => 'コレクション';

  @override
  String get language => '言語';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get languageDescription => '希望する言語を選択してください。アプリはデフォルトでデバイスの言語を使用します。';

  @override
  String get close => '閉じる';

  @override
  String get settingsSaved => '設定が保存されました';

  @override
  String get invalidUrl => '有効なURLを入力してください';

  @override
  String get invalidPollingInterval => 'ポーリング間隔は5-300秒の間である必要があります';

  @override
  String get noGroupsAdded => 'まだグループが追加されていません。上からグループ名を追加してください。';

  @override
  String get donate => '寄付';

  @override
  String get donateDescription => 'このアプリの開発をサポートしてください';

  @override
  String get donateButton => 'コーヒーを一杯';
}
