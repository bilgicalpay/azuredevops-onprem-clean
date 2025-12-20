/// Kimlik doğrulama servisi
/// 
/// Azure DevOps Server 2022 için Personal Access Token (PAT) ve
/// Active Directory (AD) kullanıcı adı/şifre ile kimlik doğrulama sağlar.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:convert' show base64, utf8;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'storage_service.dart';
import 'certificate_pinning_service.dart';
import 'security_service.dart';

/// Kimlik doğrulama servisi sınıfı
/// PAT ve AD kimlik doğrulama yöntemlerini destekler
class AuthService extends ChangeNotifier {
  StorageService? _storage;
  bool _isAuthenticated = false;
  String? _serverUrl;
  String? _token;
  String? _username;
  String? _authType;

  AuthService() {
    _loadAuthState();
  }

  void setStorage(StorageService storage) {
    _storage = storage;
    _loadAuthState();
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get serverUrl => _serverUrl;
  String? get token => _token;
  String? get username => _username;
  String? get authType => _authType;
  
  /// Get authentication token for API calls
  /// For PAT: returns stored token
  /// For AD: generates token from stored username and password at runtime
  Future<String?> getAuthToken() async {
    if (_authType == 'ad') {
      // For AD auth, generate token from stored credentials at runtime
      final username = await _storage?.getUsername();
      final password = await _storage?.getAdPassword();
      if (username != null && password != null) {
        return _encodeBasicAuth(username, password);
      }
      return null;
    } else {
      // For PAT, return stored token
      return _token;
    }
  }

  Future<void> _loadAuthState() async {
    if (_storage == null) return;
    _serverUrl = _storage!.getServerUrl();
    _authType = _storage!.getAuthType();
    
    if (_authType == 'ad') {
      // For AD auth, check if username and password exist
      _username = await _storage!.getUsername();
      final password = await _storage!.getAdPassword();
      _token = null; // AD auth doesn't store token
      _isAuthenticated = _username != null && password != null && _serverUrl != null;
    } else {
      // For PAT auth, check if token exists
      _token = await _storage!.getToken();
      _username = null; // PAT doesn't use username
      // For AD auth, check username and password; for PAT, check token
    if (_authType == 'ad') {
      _isAuthenticated = _username != null && _serverUrl != null;
    } else {
      _isAuthenticated = _token != null && _serverUrl != null;
    }
    }
    
    notifyListeners();
  }

  /// Personal Access Token ile giriş yapar
  /// Token'ı Base64 ile kodlayarak Basic Authentication kullanır
  /// Güvenlik: Token FlutterSecureStorage'da şifrelenmiş olarak saklanır
  Future<bool> loginWithToken({
    required String serverUrl,
    required String token,
    String? collection,
  }) async {
    try {
      // Log authentication attempt
      SecurityService.logAuthentication('Token login attempt', details: {'serverUrl': serverUrl});
      
      // Bağlantıyı test et
      final dio = CertificatePinningService.createSecureDio();
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      final testUrl = collection != null && collection.isNotEmpty
          ? '$cleanUrl/$collection/_apis/projects?api-version=7.0'
          : '$cleanUrl/_apis/projects?api-version=7.0';

      SecurityService.logApiCall(testUrl, method: 'GET');
      
      final response = await dio.get(
        testUrl,
        options: Options(
          headers: {
            'Authorization': 'Basic ${_encodeToken(token)}',
            'Content-Type': 'application/json',
          },
        ),
      );

      SecurityService.logApiCall(testUrl, method: 'GET', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        await _storage?.setServerUrl(cleanUrl);
        await _storage?.setToken(token);
        await _storage?.setAuthType('token');
        if (collection != null && collection.isNotEmpty) {
          await _storage?.setCollection(collection);
        }
        
        _isAuthenticated = true;
        _serverUrl = cleanUrl;
        _token = token;
        _authType = 'token';
        
        SecurityService.logAuthentication('Token login successful', details: {'serverUrl': cleanUrl});
        SecurityService.logTokenOperation('Token stored', success: true);
        
        notifyListeners();
        return true;
      }
      
        SecurityService.logAuthentication('Token login failed', details: {'statusCode': response.statusCode});
      return false;
    } catch (e) {
      debugPrint('Token login error: $e');
      SecurityService.logAuthentication('Token login error', details: {'error': e.toString()});
      return false;
    }
  }

  /// Active Directory kullanıcı adı/şifre ile giriş yapar
  /// Basic Authentication kullanır.
  /// Local user formatını destekler: DOMAIN\username veya COMPUTERNAME\username
  /// Güvenlik: AD token (Base64 kodlanmış kullanıcı adı/şifre) FlutterSecureStorage'da şifrelenmiş olarak saklanır
  Future<bool> loginWithAD({
    required String serverUrl,
    required String username,
    required String password,
    String? collection,
  }) async {
    try {
      // Log authentication attempt
      SecurityService.logAuthentication('AD login attempt', details: {'serverUrl': serverUrl, 'username': username});
      
      final dio = CertificatePinningService.createSecureDio();
      final cleanUrl = serverUrl.endsWith('/') 
          ? serverUrl.substring(0, serverUrl.length - 1) 
          : serverUrl;
      
      // Normalize username: DOMAIN\username formatını koru
      // Azure DevOps Server local user authentication için DOMAIN\username formatını kabul eder
      String normalizedUsername = username.trim();
      
      // Eğer username'de \ yoksa ve domain belirtilmemişse, olduğu gibi kullan
      // Eğer DOMAIN\username formatındaysa, olduğu gibi kullan (Azure DevOps bunu kabul eder)
      
      debugPrint('🔐 [AD Login] Attempting login with username: $normalizedUsername');
      
      // Azure DevOps On-Premise Basic Auth kullanır (local user için de)
      // Birden fazla endpoint deneyelim
      List<String> testUrls = [];
      
      if (collection != null && collection.isNotEmpty) {
        testUrls.add('$cleanUrl/$collection/_apis/projects?api-version=7.0');
        testUrls.add('$cleanUrl/$collection/_apis/connectionData?api-version=7.0');
      }
      testUrls.add('$cleanUrl/_apis/projects?api-version=7.0');
      testUrls.add('$cleanUrl/_apis/connectionData?api-version=7.0');

      DioException? lastError;
      
      for (final testUrl in testUrls) {
        try {
          SecurityService.logApiCall(testUrl, method: 'GET');
          
          final response = await dio.get(
            testUrl,
            options: Options(
              headers: {
                'Authorization': 'Basic ${_encodeBasicAuth(normalizedUsername, password)}',
                'Content-Type': 'application/json',
              },
              validateStatus: (status) => status != null && status < 500, // Don't throw for 4xx
            ),
          );

          SecurityService.logApiCall(testUrl, method: 'GET', statusCode: response.statusCode);
          
          debugPrint('🔐 [AD Login] Response status: ${response.statusCode} for URL: $testUrl');

          if (response.statusCode == 200) {
            // Store username and password separately in secure storage (encrypted)
            // Base64 encoding is only done at runtime for API calls, not for storage
            await _storage?.setServerUrl(cleanUrl);
            await _storage?.setUsername(normalizedUsername);
            await _storage?.setAdPassword(password);
            await _storage?.setAuthType('ad');
            if (collection != null && collection.isNotEmpty) {
              await _storage?.setCollection(collection);
            }
            
            // For AD auth, we don't store a token - we store username and password separately
            // Token will be generated at runtime from stored credentials
            _isAuthenticated = true;
            _serverUrl = cleanUrl;
            _username = normalizedUsername;
            _token = null; // AD auth doesn't use a stored token
            _authType = 'ad';
            
            SecurityService.logAuthentication('AD login successful', details: {'serverUrl': cleanUrl, 'username': normalizedUsername});
            SecurityService.logTokenOperation('AD credentials stored securely', success: true);
            
            debugPrint('✅ [AD Login] Login successful with username: $normalizedUsername');
            
            notifyListeners();
            return true;
          } else if (response.statusCode == 401) {
            // Unauthorized - wrong credentials
            debugPrint('❌ [AD Login] Unauthorized (401) - Check username and password');
            debugPrint('❌ [AD Login] Username format: $normalizedUsername');
            debugPrint('❌ [AD Login] Response: ${response.data}');
            lastError = DioException(
              requestOptions: RequestOptions(path: testUrl),
              response: response,
              type: DioExceptionType.badResponse,
            );
            continue; // Try next URL
          } else {
            debugPrint('⚠️ [AD Login] Unexpected status code: ${response.statusCode}');
            lastError = DioException(
              requestOptions: RequestOptions(path: testUrl),
              response: response,
              type: DioExceptionType.badResponse,
            );
            continue; // Try next URL
          }
        } catch (e) {
          debugPrint('⚠️ [AD Login] Error trying URL $testUrl: $e');
          if (e is DioException) {
            lastError = e;
            if (e.response?.statusCode == 401) {
              // Unauthorized - don't try other URLs
              break;
            }
          }
          continue; // Try next URL
        }
      }
      
      // If we get here, all URLs failed
      if (lastError != null) {
        final statusCode = lastError.response?.statusCode;
        final errorMessage = lastError.response?.data?.toString() ?? lastError.message ?? 'Unknown error';
        
        debugPrint('❌ [AD Login] All login attempts failed');
        debugPrint('❌ [AD Login] Last status code: $statusCode');
        debugPrint('❌ [AD Login] Last error: $errorMessage');
        
        SecurityService.logAuthentication('AD login failed', details: {
          'statusCode': statusCode,
          'error': errorMessage,
          'username': normalizedUsername,
        });
      } else {
        SecurityService.logAuthentication('AD login failed', details: {
          'error': 'All authentication attempts failed',
          'username': normalizedUsername,
        });
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ [AD Login] Unexpected error: $e');
      SecurityService.logAuthentication('AD login error', details: {'error': e.toString()});
      return false;
    }
  }

  Future<void> logout() async {
    await _storage?.clear();
    _isAuthenticated = false;
    _serverUrl = null;
    _token = null;
    _username = null;
    _authType = null;
    notifyListeners();
  }

  /// Token'ı Base64 ile kodlar (PAT için)
  /// Azure DevOps API'si için Basic Auth formatında hazırlar
  String _encodeToken(String token) {
    return base64.encode(utf8.encode(':$token'));
  }

  /// Kullanıcı adı ve şifreyi Base64 ile kodlar (AD için)
  /// Basic Authentication için kullanılır
  String _encodeBasicAuth(String username, String password) {
    return base64.encode(utf8.encode('$username:$password'));
  }

}

