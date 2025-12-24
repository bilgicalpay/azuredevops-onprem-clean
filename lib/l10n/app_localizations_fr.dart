// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Azure DevOps';

  @override
  String get settings => 'Paramètres';

  @override
  String get wikiSettings => 'Paramètres Wiki';

  @override
  String get wikiSettingsDescription =>
      'Entrez l\'URL du fichier wiki Azure DevOps. Ce contenu wiki sera affiché sur la page d\'accueil.';

  @override
  String get wikiUrl => 'URL Wiki';

  @override
  String get save => 'Enregistrer';

  @override
  String get marketSettings => 'Paramètres du Marché';

  @override
  String get marketSettingsDescription =>
      'Entrez l\'URL du répertoire statique IIS. Les fichiers APK et IPA seront listés et téléchargeables depuis ce répertoire.';

  @override
  String get marketUrl => 'URL du Marché';

  @override
  String get notificationSettings => 'Paramètres de Notification';

  @override
  String get controlFrequency => 'Fréquence de Contrôle';

  @override
  String get pollingInterval => 'Intervalle d\'Interrogation (secondes)';

  @override
  String get pollingIntervalHelper => 'Entre 5-300 secondes';

  @override
  String get fast => 'Rapide (10s)';

  @override
  String get normal => 'Normal (15s)';

  @override
  String get slow => 'Lent (30s)';

  @override
  String get notificationTypes => 'Types de Notification';

  @override
  String get notifyOnFirstAssignment =>
      'Notification lors de la Première Attribution';

  @override
  String get notifyOnFirstAssignmentDescription =>
      'Envoyer une notification uniquement lors de la première attribution';

  @override
  String get notifyOnAllUpdates =>
      'Notification lors de Toutes les Mises à Jour';

  @override
  String get notifyOnAllUpdatesDescription =>
      'Envoyer une notification lorsque les éléments de travail qui me sont attribués sont mis à jour';

  @override
  String get notifyOnHotfixOnly => 'Uniquement Hotfix';

  @override
  String get notifyOnHotfixOnlyDescription =>
      'Notification uniquement pour les éléments de travail de type Hotfix';

  @override
  String get notifyOnGroupAssignments =>
      'Notification lors des Attributions de Groupe';

  @override
  String get notifyOnGroupAssignmentsDescription =>
      'Envoyer une notification lorsque des attributions sont faites aux groupes spécifiés';

  @override
  String get groupName => 'Nom du Groupe';

  @override
  String get groupNameHint => 'Ex: Développeurs, Équipe QA';

  @override
  String get smartwatchNotifications => 'Notifications Montre Intelligente';

  @override
  String get smartwatchNotificationsDescription =>
      'Envoyer des notifications aux montres intelligentes (uniquement lors de la première attribution)';

  @override
  String get onCallMode => 'Mode de Garde';

  @override
  String get onCallModeDescription =>
      'En mode de garde, les notifications deviennent plus agressives et les notifications non lues sont actualisées 3 fois.';

  @override
  String get onCallModePhone => 'Mode de Garde pour Téléphone';

  @override
  String get onCallModePhoneDescription =>
      'Notifications agressives sur le téléphone';

  @override
  String get onCallModeWatch => 'Mode de Garde pour Montre Intelligente';

  @override
  String get onCallModeWatchDescription =>
      'Notifications agressives sur la montre intelligente';

  @override
  String get vacationMode => 'Mode Vacances';

  @override
  String get vacationModeDescription =>
      'Aucune notification n\'est reçue en mode vacances.';

  @override
  String get vacationModePhone => 'Mode Vacances pour Téléphone';

  @override
  String get vacationModePhoneDescription =>
      'Désactiver les notifications sur le téléphone';

  @override
  String get vacationModeWatch => 'Mode Vacances pour Montre Intelligente';

  @override
  String get vacationModeWatchDescription =>
      'Désactiver les notifications sur la montre intelligente';

  @override
  String get serverUrl => 'URL du Serveur';

  @override
  String get collection => 'Collection';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la Langue';

  @override
  String get languageDescription =>
      'Choisissez votre langue préférée. L\'application utilisera la langue de votre appareil par défaut.';

  @override
  String get close => 'Fermer';

  @override
  String get settingsSaved => 'Paramètres enregistrés';

  @override
  String get invalidUrl => 'Veuillez entrer une URL valide';

  @override
  String get invalidMarketUrl =>
      'Veuillez entrer une URL de Marché valide (ex: https://devops.higgscloud.com/_static/market/)';

  @override
  String get invalidPollingInterval =>
      'L\'intervalle d\'interrogation doit être entre 5-300 secondes';

  @override
  String couldNotOpenLink(String error) {
    return 'Impossible d\'ouvrir le lien: $error';
  }

  @override
  String get wikiUrlHint =>
      'https://devops.higgscloud.com/Dev/demo/_wiki/wikis/CAB-Plan/1/README';

  @override
  String get marketUrlHint => 'https://devops.higgscloud.com/_static/market/';

  @override
  String get noGroupsAdded =>
      'Aucun groupe ajouté pour le moment. Ajoutez un nom de groupe ci-dessus.';

  @override
  String get donate => 'Faire un Don';

  @override
  String get donateDescription =>
      'Soutenez le développement de cette application';

  @override
  String get donateButton => 'Offrez-moi un Café';

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
