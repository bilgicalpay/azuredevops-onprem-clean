/// Yerel depolama servisi
/// 
/// SharedPreferences ve FlutterSecureStorage kullanarak uygulama verilerini kalıcı olarak saklar.
/// Token'lar güvenli bir şekilde FlutterSecureStorage'da saklanır.
/// Server URL, kullanıcı adı, collection ve wiki URL bilgileri SharedPreferences'da saklanır.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Yerel depolama servisi sınıfı
/// SharedPreferences ve FlutterSecureStorage üzerinden veri saklama işlemlerini yönetir
class StorageService extends ChangeNotifier {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Android EncryptedSharedPreferences kullan
      sharedPreferencesName: 'FlutterSecureStorage',
      preferencesKeyPrefix: 'flutter_secure_storage_',
      // Android Auto Backup ile otomatik olarak yedeklenir
      // EncryptedSharedPreferences Android 6.0+ Auto Backup ile korunur
      // NOT: Backup için kullanıcının Google hesabı giriş yapmış olmalı ve Auto Backup açık olmalı
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device, // iOS Keychain kullan
      // iOS Keychain otomatik olarak iCloud Backup ile yedeklenir (ayarlar açıksa)
      // NOT: Backup için kullanıcının iCloud Backup açık olmalı
      synchronizable: true, // iCloud Keychain sync için
    ),
  );
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Server URL
  String? getServerUrl() => _prefs?.getString('server_url');
  Future<void> setServerUrl(String url) async {
    await _prefs?.setString('server_url', url);
    notifyListeners();
  }
  
  // Authentication Token - Güvenli depolama
  // Token'lar FlutterSecureStorage'da şifrelenmiş olarak saklanır
  // Android: EncryptedSharedPreferences kullanılır
  // iOS: Keychain kullanılır
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
  
  Future<void> setToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
    notifyListeners();
  }
  
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
    notifyListeners();
  }
  
  // Username (for AD auth) - Güvenli depolama
  // Username FlutterSecureStorage'da şifrelenmiş olarak saklanır
  Future<String?> getUsername() async {
    return await _secureStorage.read(key: 'username');
  }
  
  Future<void> setUsername(String username) async {
    await _secureStorage.write(key: 'username', value: username);
    notifyListeners();
  }
  
  Future<void> deleteUsername() async {
    await _secureStorage.delete(key: 'username');
    notifyListeners();
  }
  
  // AD Password - Güvenli depolama
  // Password FlutterSecureStorage'da şifrelenmiş olarak saklanır
  Future<String?> getAdPassword() async {
    return await _secureStorage.read(key: 'ad_password');
  }
  
  Future<void> setAdPassword(String password) async {
    await _secureStorage.write(key: 'ad_password', value: password);
    notifyListeners();
  }
  
  Future<void> deleteAdPassword() async {
    await _secureStorage.delete(key: 'ad_password');
    notifyListeners();
  }
  
  // Auth Type: 'token' or 'ad'
  String? getAuthType() => _prefs?.getString('auth_type') ?? 'token';
  Future<void> setAuthType(String type) async {
    await _prefs?.setString('auth_type', type);
    notifyListeners();
  }
  
  // Collection/Project
  String? getCollection() => _prefs?.getString('collection');
  Future<void> setCollection(String collection) async {
    await _prefs?.setString('collection', collection);
    notifyListeners();
  }
  
  // Wiki URL
  String? getWikiUrl() => _prefs?.getString('wiki_url');
  Future<void> setWikiUrl(String? wikiUrl) async {
    if (wikiUrl == null || wikiUrl.isEmpty) {
      await _prefs?.remove('wiki_url');
    } else {
      await _prefs?.setString('wiki_url', wikiUrl);
    }
    notifyListeners();
  }

  // Market Repository URL (IIS static directory)
  String? getMarketRepoUrl() => _prefs?.getString('market_repo_url');
  Future<void> setMarketRepoUrl(String? repoUrl) async {
    if (repoUrl == null || repoUrl.isEmpty) {
      await _prefs?.remove('market_repo_url');
    } else {
      await _prefs?.setString('market_repo_url', repoUrl);
    }
    notifyListeners();
  }

  // Favorite Market Folders
  /// Get list of favorite folder paths
  Future<List<String>> getFavoriteFolders() async {
    try {
      final favoritesJson = _prefs?.getString('market_favorite_folders');
      if (favoritesJson == null || favoritesJson.isEmpty) {
        return [];
      }
      final List<dynamic> favorites = jsonDecode(favoritesJson);
      return favorites.cast<String>();
    } catch (e) {
      print('Error reading favorite folders: $e');
      return [];
    }
  }

  /// Add a folder to favorites
  Future<void> addFavoriteFolder(String folderPath) async {
    try {
      final favorites = await getFavoriteFolders();
      if (!favorites.contains(folderPath)) {
        favorites.add(folderPath);
        await _prefs?.setString('market_favorite_folders', jsonEncode(favorites));
        notifyListeners();
      }
    } catch (e) {
      print('Error adding favorite folder: $e');
    }
  }

  /// Remove a folder from favorites
  Future<void> removeFavoriteFolder(String folderPath) async {
    try {
      final favorites = await getFavoriteFolders();
      favorites.remove(folderPath);
      await _prefs?.setString('market_favorite_folders', jsonEncode(favorites));
      notifyListeners();
    } catch (e) {
      print('Error removing favorite folder: $e');
    }
  }

  /// Check if a folder is in favorites
  Future<bool> isFavoriteFolder(String folderPath) async {
    final favorites = await getFavoriteFolders();
    return favorites.contains(folderPath);
  }

  // Market Folder File Tracking (for notifications)
  /// Get tracked files for a folder (last known file list)
  Future<Map<String, List<String>>> getTrackedFolderFiles() async {
    try {
      final trackedJson = _prefs?.getString('market_tracked_folder_files');
      if (trackedJson == null || trackedJson.isEmpty) {
        return {};
      }
      final Map<String, dynamic> tracked = jsonDecode(trackedJson);
      return tracked.map((key, value) => MapEntry(key, (value as List).cast<String>()));
    } catch (e) {
      print('Error reading tracked folder files: $e');
      return {};
    }
  }

  /// Update tracked files for a folder
  Future<void> updateTrackedFolderFiles(String folderPath, List<String> fileNames) async {
    try {
      final tracked = await getTrackedFolderFiles();
      tracked[folderPath] = fileNames;
      await _prefs?.setString('market_tracked_folder_files', jsonEncode(tracked));
      notifyListeners();
    } catch (e) {
      print('Error updating tracked folder files: $e');
    }
  }
  
  // Polling Interval (in seconds)
  /// Get polling interval from storage (default: 15 seconds)
  Future<int> getPollingInterval() async {
    try {
      final interval = _prefs?.getInt('polling_interval_seconds');
      // Default to 15 seconds, minimum 5 seconds, maximum 300 seconds (5 minutes)
      if (interval == null || interval < 5) {
        return 15;
      }
      if (interval > 300) {
        return 300;
      }
      return interval;
    } catch (e) {
      return 15; // Default on error
    }
  }

  /// Set polling interval in seconds
  Future<void> setPollingInterval(int seconds) async {
    try {
      // Enforce limits: minimum 5 seconds, maximum 300 seconds (5 minutes)
      final clampedSeconds = seconds.clamp(5, 300);
      await _prefs?.setInt('polling_interval_seconds', clampedSeconds);
      notifyListeners();
    } catch (e) {
      print('Error saving polling interval: $e');
    }
  }
  
  // Token Expiry (for automatic refresh)
  Future<int?> getTokenExpiry() async {
    return _prefs?.getInt('token_expiry_timestamp');
  }

  Future<void> setTokenExpiry(int? timestamp) async {
    if (timestamp == null) {
      await _prefs?.remove('token_expiry_timestamp');
    } else {
      await _prefs?.setInt('token_expiry_timestamp', timestamp);
    }
    notifyListeners();
  }

  // Last Activity Timestamp (for auto-logout)
  /// Get last activity timestamp (when app was last used)
  Future<int?> getLastActivityTimestamp() async {
    return _prefs?.getInt('last_activity_timestamp');
  }

  /// Set last activity timestamp (current time)
  Future<void> updateLastActivityTimestamp() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs?.setInt('last_activity_timestamp', now);
    notifyListeners();
  }

  /// Check if auto-logout should be triggered (30 days of inactivity)
  /// Returns true if last activity was more than 30 days ago
  Future<bool> shouldAutoLogout() async {
    final lastActivity = await getLastActivityTimestamp();
    if (lastActivity == null) {
      // No activity recorded, don't logout (first time user)
      return false;
    }
    
    final lastActivityDate = DateTime.fromMillisecondsSinceEpoch(lastActivity);
    final now = DateTime.now();
    final daysSinceLastActivity = now.difference(lastActivityDate).inDays;
    
    // Auto-logout after 30 days of inactivity
    return daysSinceLastActivity >= 30;
  }

  Future<void> clear() async {
    // Güvenli depolamadan tüm hassas verileri sil
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'username');
    await _secureStorage.delete(key: 'ad_password');
    // SharedPreferences'ı temizle
    await _prefs?.clear();
    notifyListeners();
  }

  // ==================== BİLDİRİM AYARLARI ====================
  
  /// Sadece ilk atamada bildirim (varsayılan: false - kullanıcı açıkça seçmeli)
  bool getNotifyOnFirstAssignment() {
    // Eğer hiç ayarlanmamışsa, false döndür (kullanıcı açıkça seçmeli)
    if (_prefs?.containsKey('notify_on_first_assignment') != true) {
      return false;
    }
    return _prefs?.getBool('notify_on_first_assignment') ?? false;
  }
  
  Future<void> setNotifyOnFirstAssignment(bool value) async {
    await _prefs?.setBool('notify_on_first_assignment', value);
    notifyListeners();
  }
  
  /// Tüm güncellemelerde bildirim (varsayılan: false - kullanıcı açıkça seçmeli)
  bool getNotifyOnAllUpdates() {
    // Eğer hiç ayarlanmamışsa, false döndür (kullanıcı açıkça seçmeli)
    if (_prefs?.containsKey('notify_on_all_updates') != true) {
      return false;
    }
    return _prefs?.getBool('notify_on_all_updates') ?? false;
  }
  
  Future<void> setNotifyOnAllUpdates(bool value) async {
    await _prefs?.setBool('notify_on_all_updates', value);
    notifyListeners();
  }
  
  /// Sadece Hotfix tipinde bildirim (varsayılan: false)
  bool getNotifyOnHotfixOnly() {
    return _prefs?.getBool('notify_on_hotfix_only') ?? false;
  }
  
  Future<void> setNotifyOnHotfixOnly(bool value) async {
    await _prefs?.setBool('notify_on_hotfix_only', value);
    notifyListeners();
  }
  
  /// Grup atamalarında bildirim (varsayılan: false)
  bool getNotifyOnGroupAssignments() {
    return _prefs?.getBool('notify_on_group_assignments') ?? false;
  }
  
  Future<void> setNotifyOnGroupAssignments(bool value) async {
    await _prefs?.setBool('notify_on_group_assignments', value);
    notifyListeners();
  }
  
  /// Bildirim grupları listesi
  Future<List<String>> getNotificationGroups() async {
    try {
      final groupsJson = _prefs?.getString('notification_groups');
      if (groupsJson == null || groupsJson.isEmpty) {
        return [];
      }
      final List<dynamic> groups = jsonDecode(groupsJson);
      return groups.cast<String>();
    } catch (e) {
      print('Error reading notification groups: $e');
      return [];
    }
  }
  
  /// Tüm bildirim gruplarını ayarla
  Future<void> setNotificationGroups(List<String> groups) async {
    try {
      await _prefs?.setString('notification_groups', jsonEncode(groups));
      notifyListeners();
    } catch (e) {
      print('Error setting notification groups: $e');
    }
  }

  // ==================== AKILLI SAAT BİLDİRİMLERİ ====================
  
  /// Akıllı saat bildirimleri aktif mi? (varsayılan: false)
  bool getEnableSmartwatchNotifications() {
    return _prefs?.getBool('enable_smartwatch_notifications') ?? false;
  }
  
  Future<void> setEnableSmartwatchNotifications(bool value) async {
    await _prefs?.setBool('enable_smartwatch_notifications', value);
    notifyListeners();
  }

  // ==================== NÖBETÇİ MODU ====================
  
  /// Nöbetçi modu aktif mi? (telefon için, varsayılan: false)
  bool getOnCallModePhone() {
    return _prefs?.getBool('on_call_mode_phone') ?? false;
  }
  
  Future<void> setOnCallModePhone(bool value) async {
    await _prefs?.setBool('on_call_mode_phone', value);
    notifyListeners();
  }
  
  /// Nöbetçi modu aktif mi? (akıllı saat için, varsayılan: false)
  bool getOnCallModeWatch() {
    return _prefs?.getBool('on_call_mode_watch') ?? false;
  }
  
  Future<void> setOnCallModeWatch(bool value) async {
    await _prefs?.setBool('on_call_mode_watch', value);
    notifyListeners();
  }
  
  /// Nöbetçi modu aktif mi? (genel - telefon veya saat için)
  bool getOnCallMode() {
    return getOnCallModePhone() || getOnCallModeWatch();
  }

  // ==================== TATİL MODU ====================
  
  /// Tatil modu aktif mi? (telefon için, varsayılan: false)
  bool getVacationModePhone() {
    return _prefs?.getBool('vacation_mode_phone') ?? false;
  }
  
  Future<void> setVacationModePhone(bool value) async {
    await _prefs?.setBool('vacation_mode_phone', value);
    notifyListeners();
  }
  
  /// Tatil modu aktif mi? (akıllı saat için, varsayılan: false)
  bool getVacationModeWatch() {
    return _prefs?.getBool('vacation_mode_watch') ?? false;
  }
  
  Future<void> setVacationModeWatch(bool value) async {
    await _prefs?.setBool('vacation_mode_watch', value);
    notifyListeners();
  }
  
  /// Tatil modu aktif mi? (genel - telefon veya saat için)
  bool getVacationMode() {
    return getVacationModePhone() || getVacationModeWatch();
  }

  // ==================== OKUNMAYAN BİLDİRİMLER TAKİBİ ====================
  
  /// Okunmayan bildirimler için yeniden gönderme sayısı (work item ID -> count)
  Future<Map<int, int>> getUnreadNotificationRetryCounts() async {
    try {
      final countsJson = _prefs?.getString('unread_notification_retry_counts');
      if (countsJson == null || countsJson.isEmpty) {
        return {};
      }
      final Map<String, dynamic> counts = jsonDecode(countsJson);
      return counts.map((key, value) => MapEntry(int.parse(key), value as int));
    } catch (e) {
      print('Error reading unread notification retry counts: $e');
      return {};
    }
  }
  
  /// Okunmayan bildirim için yeniden gönderme sayısını artır
  Future<void> incrementUnreadNotificationRetry(int workItemId) async {
    try {
      final counts = await getUnreadNotificationRetryCounts();
      counts[workItemId] = (counts[workItemId] ?? 0) + 1;
      await _prefs?.setString('unread_notification_retry_counts', jsonEncode(counts));
      notifyListeners();
    } catch (e) {
      print('Error incrementing unread notification retry: $e');
    }
  }
  
  /// Okunmayan bildirim için yeniden gönderme sayısını sıfırla (bildirim okunduğunda)
  Future<void> resetUnreadNotificationRetry(int workItemId) async {
    try {
      final counts = await getUnreadNotificationRetryCounts();
      counts.remove(workItemId);
      await _prefs?.setString('unread_notification_retry_counts', jsonEncode(counts));
      notifyListeners();
    } catch (e) {
      print('Error resetting unread notification retry: $e');
    }
  }
  
  /// Okunmayan bildirim için yeniden gönderme sayısını al
  Future<int> getUnreadNotificationRetryCount(int workItemId) async {
    final counts = await getUnreadNotificationRetryCounts();
    return counts[workItemId] ?? 0;
  }

  // ==================== DİL AYARLARI ====================
  
  /// Seçili dil kodu (varsayılan: cihaz dili veya 'tr')
  String getSelectedLanguage() {
    return _prefs?.getString('selected_language') ?? 'system';
  }
  
  Future<void> setSelectedLanguage(String languageCode) async {
    await _prefs?.setString('selected_language', languageCode);
    notifyListeners();
  }

  // ==================== ŞİRKET/LOGO AYARLARI ====================
  
  /// Özel şirket adı (kullanıcı tarafından ayarlanabilir)
  String? getCompanyName() {
    return _prefs?.getString('company_name');
  }
  
  Future<void> setCompanyName(String? name) async {
    if (name == null || name.isEmpty) {
      await _prefs?.remove('company_name');
    } else {
      await _prefs?.setString('company_name', name);
    }
    notifyListeners();
  }
  
  /// Özel logo URL (kullanıcı tarafından ayarlanabilir)
  String? getCompanyLogoUrl() {
    return _prefs?.getString('company_logo_url');
  }
  
  Future<void> setCompanyLogoUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _prefs?.remove('company_logo_url');
    } else {
      await _prefs?.setString('company_logo_url', url);
    }
    notifyListeners();
  }
  
  /// Logo gösterim modu: 'auto' (domain'den), 'custom' (kullanıcı ayarı), 'none' (gösterme)
  String getLogoDisplayMode() {
    return _prefs?.getString('logo_display_mode') ?? 'auto';
  }
  
  Future<void> setLogoDisplayMode(String mode) async {
    await _prefs?.setString('logo_display_mode', mode);
    notifyListeners();
  }
  
  /// Server URL'den domain adını çıkar ve şirket adına dönüştür
  /// Örnek 1: https://dev.azure.com/softwareoneturkiye/ -> Softwareoneturkiye (Azure DevOps Cloud)
  /// Örnek 2: https://devops.higgscloud.com/Dev -> Higgscloud (On-premise)
  /// Örnek 3: https://devops.vakifkatilim.com.tr -> Vakıf Katılım (On-premise)
  String getCompanyNameFromServerUrl() {
    final serverUrl = getServerUrl();
    if (serverUrl == null || serverUrl.isEmpty) {
      return '';
    }
    
    try {
      final uri = Uri.parse(serverUrl);
      final host = uri.host; // dev.azure.com veya devops.higgscloud.com
      
      // Azure DevOps Cloud kontrolü: dev.azure.com/organizationname/
      if (host == 'dev.azure.com' || host == 'azure.com') {
        // Path'ten organization adını al
        // https://dev.azure.com/softwareoneturkiye/ -> softwareoneturkiye
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final orgName = pathSegments.first;
          if (orgName.isNotEmpty) {
            return _formatCompanyName(orgName);
          }
        }
        return 'Azure DevOps';
      }
      
      // visualstudio.com eski format kontrolü
      // https://softwareoneturkiye.visualstudio.com/ -> softwareoneturkiye
      if (host.endsWith('.visualstudio.com')) {
        final parts = host.split('.');
        if (parts.isNotEmpty && parts.first.isNotEmpty) {
          return _formatCompanyName(parts.first);
        }
      }
      
      // On-premise: Özel domain'den şirket adını al
      // devops.higgscloud.com -> higgscloud
      // devops.vakifkatilim.com.tr -> vakifkatilim
      final parts = host.split('.');
      if (parts.length < 2) {
        return _formatCompanyName(host);
      }
      
      // Alt domain'leri atla (devops, tfs, azuredevops gibi)
      final commonSubdomains = ['devops', 'tfs', 'azuredevops', 'azure', 'dev', 'www'];
      String mainDomain;
      
      if (parts.length >= 3) {
        // devops.higgscloud.com -> higgscloud (index 1)
        // devops.vakifkatilim.com.tr -> vakifkatilim (index 1)
        if (commonSubdomains.contains(parts[0].toLowerCase())) {
          mainDomain = parts[1];
        } else {
          mainDomain = parts[0];
        }
      } else {
        mainDomain = parts[0];
      }
      
      return _formatCompanyName(mainDomain);
    } catch (e) {
      return '';
    }
  }
  
  /// Domain/organization adını okunabilir şirket adına dönüştür
  String _formatCompanyName(String name) {
    if (name.isEmpty) return '';
    
    // Bilinen isimler için özel formatlar
    final knownNames = {
      'vakifkatilim': 'Vakıf Katılım',
      'higgscloud': 'Higgs Cloud',
      'microsoft': 'Microsoft',
      'azure': 'Azure',
      'google': 'Google',
      'amazon': 'Amazon',
      'github': 'GitHub',
      'softwareone': 'SoftwareOne',
      'softwareoneturkiye': 'SoftwareOne Türkiye',
    };
    
    final lowerName = name.toLowerCase();
    if (knownNames.containsKey(lowerName)) {
      return knownNames[lowerName]!;
    }
    
    // Genel format: İlk harfi büyük yap
    return name[0].toUpperCase() + name.substring(1);
  }
  
  /// Gösterilecek şirket adını al (öncelik: özel ayar > domain'den otomatik)
  String getDisplayCompanyName() {
    final mode = getLogoDisplayMode();
    
    if (mode == 'none') {
      return '';
    }
    
    if (mode == 'custom') {
      final customName = getCompanyName();
      if (customName != null && customName.isNotEmpty) {
        return customName;
      }
    }
    
    // Auto mode veya custom boşsa domain'den al
    return getCompanyNameFromServerUrl();
  }

  // ==================== İLK AÇILIŞ DIALOG AYARLARI ====================
  
  /// İlk açılış welcome dialog'unun gösterilip gösterilmediğini kontrol et
  bool hasShownWelcomeDialog() {
    return _prefs?.getBool('has_shown_welcome_dialog') ?? false;
  }
  
  /// İlk açılış welcome dialog'unun gösterildiğini işaretle
  Future<void> setHasShownWelcomeDialog(bool shown) async {
    await _prefs?.setBool('has_shown_welcome_dialog', shown);
    notifyListeners();
  }

  // ==================== FIELD DEFINITIONS CACHE ====================
  
  /// Work item type field definitions'ı secure storage'a kaydet
  /// Key format: "field_definitions_{project}_{workItemType}"
  Future<void> setFieldDefinitions(String project, String workItemType, Map<String, dynamic> fieldDefinitions) async {
    try {
      final key = 'field_definitions_${project}_$workItemType';
      final jsonString = jsonEncode(fieldDefinitions);
      await _secureStorage.write(key: key, value: jsonString);
      await _updateFieldDefinitionsKeys(key);
      debugPrint('✅ [StorageService] Field definitions cached for $project/$workItemType');
    } catch (e) {
      debugPrint('❌ [StorageService] Error caching field definitions: $e');
    }
  }
  
  /// Work item type field definitions'ı secure storage'dan oku
  Future<Map<String, dynamic>?> getFieldDefinitions(String project, String workItemType) async {
    try {
      final key = 'field_definitions_${project}_$workItemType';
      final jsonString = await _secureStorage.read(key: key);
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint('✅ [StorageService] Field definitions loaded from cache for $project/$workItemType');
        return decoded;
      }
    } catch (e) {
      debugPrint('❌ [StorageService] Error loading field definitions from cache: $e');
    }
    return null;
  }
  
  // Theme Mode: 'light', 'dark', or 'system'
  String getThemeMode() => _prefs?.getString('theme_mode') ?? 'system';
  Future<void> setThemeMode(String mode) async {
    await _prefs?.setString('theme_mode', mode);
    notifyListeners();
  }

  /// Tüm cached field definitions'ları temizle
  Future<void> clearFieldDefinitionsCache() async {
    try {
      // Secure storage'dan tüm field definition key'lerini sil
      // Note: FlutterSecureStorage doesn't have a way to list all keys,
      // so we'll use a different approach - store a list of keys in SharedPreferences
      final keysJson = _prefs?.getString('field_definitions_keys');
      if (keysJson != null && keysJson.isNotEmpty) {
        final keys = (jsonDecode(keysJson) as List).cast<String>();
        for (final key in keys) {
          await _secureStorage.delete(key: key);
        }
        await _prefs?.remove('field_definitions_keys');
      }
      debugPrint('✅ [StorageService] Field definitions cache cleared');
    } catch (e) {
      debugPrint('❌ [StorageService] Error clearing field definitions cache: $e');
    }
  }
  
  /// Field definitions key listesini güncelle
  Future<void> _updateFieldDefinitionsKeys(String key) async {
    try {
      final keysJson = _prefs?.getString('field_definitions_keys');
      final keys = keysJson != null && keysJson.isNotEmpty
          ? (jsonDecode(keysJson) as List).cast<String>()
          : <String>[];
      if (!keys.contains(key)) {
        keys.add(key);
        await _prefs?.setString('field_definitions_keys', jsonEncode(keys));
      }
    } catch (e) {
      debugPrint('❌ [StorageService] Error updating field definitions keys: $e');
    }
  }
}

