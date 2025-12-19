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
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device, // iOS Keychain kullan
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
}

