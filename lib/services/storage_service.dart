/// Yerel depolama servisi
/// 
/// SharedPreferences ve FlutterSecureStorage kullanarak uygulama verilerini kalıcı olarak saklar.
/// Token'lar güvenli bir şekilde FlutterSecureStorage'da saklanır.
/// Server URL, kullanıcı adı, collection ve wiki URL bilgileri SharedPreferences'da saklanır.
/// 
/// @author Alpay Bilgiç

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
  
  // Username (for AD auth)
  String? getUsername() => _prefs?.getString('username');
  Future<void> setUsername(String username) async {
    await _prefs?.setString('username', username);
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
  
  Future<void> clear() async {
    // Güvenli depolamadan token'ı sil
    await _secureStorage.delete(key: 'auth_token');
    // SharedPreferences'ı temizle
    await _prefs?.clear();
    notifyListeners();
  }
}

