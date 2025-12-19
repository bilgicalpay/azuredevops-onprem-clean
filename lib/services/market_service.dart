/// Market Service
/// 
/// IIS static dizininden dosyaları listeler ve indirir.
/// APK ve IPA dosyalarını indirme işlemlerini yönetir.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:convert';
import 'dart:io' show Platform, File, Directory;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform;
import 'package:logging/logging.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'auth_service.dart';
import 'certificate_pinning_service.dart';

/// Directory Entry model
class DirectoryEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modifiedDate;

  DirectoryEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.modifiedDate,
  });
}

/// Market Folder model
class MarketFolder {
  final String name;
  final String path;
  final String fullPath;
  final int fileCount;

  MarketFolder({
    required this.name,
    required this.path,
    required this.fullPath,
    this.fileCount = 0,
  });
}

/// Artifact model
class Artifact {
  final String name;
  final String downloadUrl;
  final int? size;
  final String contentType;

  Artifact({
    required this.name,
    required this.downloadUrl,
    required this.size,
    required this.contentType,
  });

  bool get isApk => name.toLowerCase().endsWith('.apk');
  bool get isIpa => name.toLowerCase().endsWith('.ipa');
  bool get isAab => name.toLowerCase().endsWith('.aab');
}

/// Market Service
class MarketService {
  static final Logger _logger = Logger('MarketService');
  final AuthService _authService;

  MarketService(AuthService authService) : _authService = authService;

  /// Get folders from IIS static directory
  /// Returns list of folders (directories) in the given URL
  Future<List<MarketFolder>> getFolders(String baseUrl) async {
    try {
      _logger.info('Fetching folders from IIS static directory: $baseUrl');

      // Validate URL format
      final uri = Uri.tryParse(baseUrl.trim());
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        throw Exception('Geçersiz Market URL formatı. Örnek: https://devops.higgscloud.com/_static/market/');
      }

      // Normalize URL - ensure it ends with /
      String normalizedUrl = baseUrl.trim();
      if (!normalizedUrl.endsWith('/')) {
        normalizedUrl += '/';
      }

      final dio = CertificatePinningService.createSecureDio();
      
      // Try to get directory listing
      final response = await dio.get(
        normalizedUrl,
        options: Options(
          headers: {
            'Accept': 'text/html,application/json',
          },
          responseType: ResponseType.plain,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final content = response.data as String;
        
        if (content.isEmpty) {
          _logger.warning('Empty response from directory listing');
          return [];
        }
        
        // Try to parse as JSON first
        try {
          final jsonData = jsonDecode(content);
          if (jsonData is List) {
            return _parseJsonFolders(jsonData, normalizedUrl);
          } else if (jsonData is Map && jsonData['files'] != null) {
            return _parseJsonFolders(jsonData['files'] as List, normalizedUrl);
          }
        } catch (e) {
          _logger.info('Response is not JSON, trying HTML parsing: $e');
        }

        // Parse as HTML directory listing
        return _parseHtmlFolders(content, normalizedUrl);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('IIS dizinine erişim reddedildi (${response.statusCode}). Kimlik doğrulama gerekebilir.');
      } else if (response.statusCode == 404) {
        throw Exception('IIS dizini bulunamadı (404). URL\'yi kontrol edin: $normalizedUrl');
      } else {
        throw Exception('Dizin listesi alınamadı: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Bağlantı zaman aşımı. IIS sunucusuna erişilemiyor.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Bağlantı hatası. IIS sunucusuna erişilemiyor: ${e.message}');
      } else if (e.type == DioExceptionType.badCertificate) {
        throw Exception('SSL sertifika hatası. IIS sunucusunun sertifikası doğrulanamadı.');
      } else if (e.response != null) {
        throw Exception('HTTP ${e.response!.statusCode}: ${e.response!.statusMessage}');
      } else {
        throw Exception('IIS dizinine erişilemedi: ${e.message}');
      }
    } catch (e) {
      _logger.severe('Error fetching folders: $e');
      if (e.toString().contains('Invalid repository URL')) {
        throw Exception('Geçersiz Market URL formatı. Örnek: https://devops.higgscloud.com/_static/market/');
      }
      rethrow;
    }
  }

  /// Parse JSON folders
  List<MarketFolder> _parseJsonFolders(List<dynamic> files, String baseUrl) {
    final folders = <MarketFolder>[];

    for (var file in files) {
      if (file is Map<String, dynamic>) {
        final name = file['name'] as String? ?? '';
        final isDirectory = file['isDirectory'] as bool? ?? false;
        
        if (isDirectory && name.isNotEmpty) {
          final folderPath = name.endsWith('/') ? name : '$name/';
          final fullPath = '$baseUrl$folderPath';
          
          folders.add(MarketFolder(
            name: name.replaceAll('/', ''),
            path: folderPath,
            fullPath: fullPath,
          ));
        }
      }
    }

    folders.sort((a, b) => a.name.compareTo(b.name));
    return folders;
  }

  /// Parse HTML folders
  List<MarketFolder> _parseHtmlFolders(String html, String baseUrl) {
    final folders = <MarketFolder>[];
    final document = html_parser.parse(html);
    final links = document.querySelectorAll('a');
    
    // Parse baseUrl to get its path
    final baseUri = Uri.parse(baseUrl);
    final basePath = baseUri.path.endsWith('/') 
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final basePathSegments = basePath.split('/').where((s) => s.isNotEmpty).toList();
    
    for (var link in links) {
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;
      
      // Skip parent directory links
      if (href == '../' || href == '..' || href == './' || href == '.' || 
          href == '/' || href.toLowerCase().contains('parent') ||
          href.toLowerCase().contains('up')) {
        continue;
      }
      
      // Only include directories (ending with /)
      if (href.endsWith('/')) {
        // Clean href - remove query params and fragments
        String cleanHref = href;
        if (cleanHref.contains('?')) {
          cleanHref = cleanHref.split('?').first;
        }
        if (cleanHref.contains('#')) {
          cleanHref = cleanHref.split('#').first;
        }
        
        // Decode URL encoding
        try {
          cleanHref = Uri.decodeComponent(cleanHref);
        } catch (e) {
          _logger.warning('Failed to decode href: $cleanHref');
        }
        
        // SIMPLIFIED: Parse href to get relative path
        String relativePath = '';
        
        if (cleanHref.startsWith('/')) {
          // Absolute path like "/static/market/ABC/" or "/_static/market/ABC/"
          // We need to extract only the part that comes AFTER the baseUrl path
          final hrefUri = Uri.parse(cleanHref);
          final hrefPathSegments = hrefUri.path.split('/').where((s) => s.isNotEmpty).toList();
          
          // Find the last segment that's different from base path
          // For example: base="/static/market/" href="/_static/market/ABC/"
          // We want just "ABC/"
          int lastMatchIndex = -1;
          for (int i = 0; i < basePathSegments.length && i < hrefPathSegments.length; i++) {
            // Compare segments ignoring _static variations
            String baseSegClean = basePathSegments[i].replaceAll('_static', '').replaceAll('static', '');
            String hrefSegClean = hrefPathSegments[i].replaceAll('_static', '').replaceAll('static', '');
            
            if (baseSegClean == hrefSegClean || basePathSegments[i] == hrefPathSegments[i]) {
              lastMatchIndex = i;
            } else {
              break;
            }
          }
          
          // CRITICAL: Skip parent directories
          // If href has FEWER or EQUAL segments than base, it's a parent/current directory - skip it!
          // Example: base="/_static/market/DEF/" (3 segments) vs href="/_static/market/" (2 segments) = parent!
          if (hrefPathSegments.length <= basePathSegments.length) {
            // This is a parent or current directory link, skip it
            continue;
          }
          

          // Extract the NEW segments (after the matching base path)
          if (lastMatchIndex >= 0 && lastMatchIndex < hrefPathSegments.length - 1) {
            // Get segments after the last match
            final newSegments = hrefPathSegments.sublist(lastMatchIndex + 1);
            relativePath = newSegments.join('/') + '/';
          } else if (hrefPathSegments.isNotEmpty) {
            // If no match, just use the last segment
            relativePath = hrefPathSegments.last + '/';
          }
        } else {
          // Relative path like "ABC/" or "./ABC/"
          // Use as-is, just remove "./" prefix if present
          relativePath = cleanHref;
          if (relativePath.startsWith('./')) {
            relativePath = relativePath.substring(2);
          }
        }
        
        // Ensure trailing slash
        if (!relativePath.endsWith('/')) {
          relativePath += '/';
        }
        
        // Extract clean folder name from relative path
        final pathSegments = relativePath.split('/').where((s) => s.isNotEmpty).toList();
        if (pathSegments.isEmpty) continue;
        
        // Get the FIRST segment as the folder name (for direct children)
        String folderName = pathSegments.first;
        
        // Remove _static prefix from folder name if present
        if (folderName.startsWith('_static')) {
          folderName = folderName.substring('_static'.length);
        }
        
        if (folderName.isEmpty) continue;
        
        // For the path stored in MarketFolder, use only the first segment
        // This ensures "ABC/" not "ABC/1.0.29/" when we're listing subdirectories
        final normalizedPath = pathSegments.length == 1 ? relativePath : '${pathSegments.first}/';
        
        // Build full path by appending to baseUrl
        final fullPath = baseUrl.endsWith('/') 
            ? '$baseUrl$normalizedPath'
            : '$baseUrl/$normalizedPath';
        
        // Check if folder already exists
        if (!folders.any((f) => f.path == normalizedPath)) {
          folders.add(MarketFolder(
            name: folderName,
            path: normalizedPath,
            fullPath: fullPath,
          ));
        }
      }
    }

    folders.sort((a, b) => a.name.compareTo(b.name));
    return folders;
  }

  /// Get files from a specific folder
  /// URL format: https://{instance}/_static/market/{folder}/
  Future<List<Artifact>> getFilesFromFolder(String folderUrl) async {
    return await getFiles(folderUrl);
  }

  /// Get files from IIS static directory
  /// URL format: https://{instance}/_static/market/
  Future<List<Artifact>> getFiles(String baseUrl) async {
    try {
      _logger.info('Fetching files from IIS static directory: $baseUrl');

      // Validate URL format
      final uri = Uri.tryParse(baseUrl.trim());
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        throw Exception('Geçersiz Market URL formatı. Örnek: https://devops.higgscloud.com/_static/market/');
      }

      // Normalize URL - ensure it ends with /
      String normalizedUrl = baseUrl.trim();
      if (!normalizedUrl.endsWith('/')) {
        normalizedUrl += '/';
      }

      final dio = CertificatePinningService.createSecureDio();
      
      // Try to get directory listing
      final response = await dio.get(
        normalizedUrl,
        options: Options(
          headers: {
            'Accept': 'text/html,application/json',
          },
          responseType: ResponseType.plain,
          validateStatus: (status) => status! < 500, // Accept 4xx errors to handle them
        ),
      );

      if (response.statusCode == 200) {
        final content = response.data as String;
        
        if (content.isEmpty) {
          _logger.warning('Empty response from directory listing');
          return [];
        }
        
        // Try to parse as JSON first (if IIS has JSON directory listing)
        try {
          final jsonData = jsonDecode(content);
          if (jsonData is List) {
            return _parseJsonDirectoryListing(jsonData, normalizedUrl);
          } else if (jsonData is Map && jsonData['files'] != null) {
            return _parseJsonDirectoryListing(jsonData['files'] as List, normalizedUrl);
          }
        } catch (e) {
          _logger.info('Response is not JSON, trying HTML parsing: $e');
        }

        // Parse as HTML directory listing
        return _parseHtmlDirectoryListing(content, normalizedUrl);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('IIS dizinine erişim reddedildi (${response.statusCode}). Kimlik doğrulama gerekebilir.');
      } else if (response.statusCode == 404) {
        throw Exception('IIS dizini bulunamadı (404). URL\'yi kontrol edin: $normalizedUrl');
      } else {
        throw Exception('Dizin listesi alınamadı: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Bağlantı zaman aşımı. IIS sunucusuna erişilemiyor.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Bağlantı hatası. IIS sunucusuna erişilemiyor: ${e.message}');
      } else if (e.response != null) {
        throw Exception('HTTP ${e.response!.statusCode}: ${e.response!.statusMessage}');
      } else {
        throw Exception('IIS dizinine erişilemedi: ${e.message}');
      }
    } catch (e) {
      _logger.severe('Error fetching files: $e');
      if (e.toString().contains('Invalid repository URL')) {
        throw Exception('Geçersiz Market URL formatı. Örnek: https://devops.higgscloud.com/_static/market/');
      }
      rethrow;
    }
  }

  /// Parse JSON directory listing
  List<Artifact> _parseJsonDirectoryListing(List<dynamic> files, String baseUrl) {
    final artifacts = <Artifact>[];

    for (var file in files) {
      if (file is Map<String, dynamic>) {
        final name = file['name'] as String? ?? '';
        final isDirectory = file['isDirectory'] as bool? ?? false;
        final size = file['size'] as int?;
        
        // Only include APK, IPA, and AAB files
        if (!isDirectory && (name.toLowerCase().endsWith('.apk') || 
            name.toLowerCase().endsWith('.ipa') || 
            name.toLowerCase().endsWith('.aab'))) {
          final downloadUrl = '$baseUrl$name';
          final contentType = _getContentType(name);
          
          artifacts.add(Artifact(
            name: name,
            downloadUrl: downloadUrl,
            size: size,
            contentType: contentType,
          ));
        }
      }
    }

    // Sort by name (newest first - assuming version in filename)
    artifacts.sort((a, b) => b.name.compareTo(a.name));

    return artifacts;
  }

  /// Parse HTML directory listing (IIS default directory listing)
  List<Artifact> _parseHtmlDirectoryListing(String html, String baseUrl) {
    final artifacts = <Artifact>[];
    final document = html_parser.parse(html);
    
    // Find all links in the HTML - IIS directory listing uses <a> tags
    final links = document.querySelectorAll('a');
    
    _logger.info('Found ${links.length} links in HTML directory listing');
    
    // Also try to find files in table rows (IIS sometimes uses tables)
    final tableRows = document.querySelectorAll('tr');
    _logger.info('Found ${tableRows.length} table rows in HTML');
    
    // Process links first
    for (var link in links) {
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;
      
      // Skip parent directory links and self-references
      if (href == '../' || href == '..' || href == './' || href == '.' || 
          href == '/' || href.toLowerCase().contains('parent') ||
          href.toLowerCase().contains('up')) {
        continue;
      }
      
      // Get file name from href
      String fileName = href;
      
      // Remove trailing slash for directories
      if (fileName.endsWith('/')) {
        continue; // Skip directories
      }
      
      // Remove query parameters if any
      if (fileName.contains('?')) {
        fileName = fileName.split('?').first;
      }
      
      // Remove hash if any
      if (fileName.contains('#')) {
        fileName = fileName.split('#').first;
      }
      
      // Decode URL-encoded file names
      try {
        fileName = Uri.decodeComponent(fileName);
      } catch (e) {
        _logger.warning('Failed to decode filename: $fileName');
      }
      
      // Clean up file name (remove any path components)
      fileName = fileName.split('/').last.trim();
      
      // Skip empty or invalid file names
      if (fileName.isEmpty || fileName == '.' || fileName == '..') continue;
      
      _logger.info('Processing file from link: $fileName');
      
      // Only include APK, IPA, and AAB files
      final lowerFileName = fileName.toLowerCase();
      if (lowerFileName.endsWith('.apk') || 
          lowerFileName.endsWith('.ipa') || 
          lowerFileName.endsWith('.aab')) {
        // Ensure download URL is properly formatted
        String downloadUrl;
        if (href.startsWith('http://') || href.startsWith('https://')) {
          downloadUrl = href;
        } else {
          // Relative URL - combine with base URL
          final baseUri = Uri.parse(baseUrl);
          downloadUrl = baseUri.resolve(href).toString();
        }
        
        final contentType = _getContentType(fileName);
        
        _logger.info('Adding artifact: $fileName -> $downloadUrl');
        
        // Check if artifact already exists (avoid duplicates)
        if (!artifacts.any((a) => a.name == fileName)) {
          artifacts.add(Artifact(
            name: fileName,
            downloadUrl: downloadUrl,
            size: null, // Size not available from HTML directory listing
            contentType: contentType,
          ));
        }
      }
    }
    
    // Also process table rows for file names (IIS directory listing in table format)
    for (var row in tableRows) {
      final cells = row.querySelectorAll('td');
      if (cells.length >= 2) {
        // Usually first cell or link contains file name
        final linkInRow = row.querySelector('a');
        if (linkInRow != null) {
          final href = linkInRow.attributes['href'];
          if (href != null && href.isNotEmpty) {
            String fileName = href;
            
            // Skip directories and parent links
            if (fileName.endsWith('/') || fileName == '../' || fileName == '..' || 
                fileName == './' || fileName == '.' || fileName == '/') {
              continue;
            }
            
            // Clean up file name
            if (fileName.contains('?')) fileName = fileName.split('?').first;
            if (fileName.contains('#')) fileName = fileName.split('#').first;
            
            try {
              fileName = Uri.decodeComponent(fileName);
            } catch (e) {
              // Ignore decode errors
            }
            
            fileName = fileName.split('/').last.trim();
            
            if (fileName.isEmpty) continue;
            
            final lowerFileName = fileName.toLowerCase();
            if (lowerFileName.endsWith('.apk') || 
                lowerFileName.endsWith('.ipa') || 
                lowerFileName.endsWith('.aab')) {
              String downloadUrl;
              if (href.startsWith('http://') || href.startsWith('https://')) {
                downloadUrl = href;
              } else {
                final baseUri = Uri.parse(baseUrl);
                downloadUrl = baseUri.resolve(href).toString();
              }
              
              // Check if artifact already exists
              if (!artifacts.any((a) => a.name == fileName)) {
                artifacts.add(Artifact(
                  name: fileName,
                  downloadUrl: downloadUrl,
                  size: null,
                  contentType: _getContentType(fileName),
                ));
                _logger.info('Adding artifact from table row: $fileName');
              }
            }
          }
        }
      }
    }

    _logger.info('Parsed ${artifacts.length} artifacts from HTML directory listing');

    // Sort by name (newest first - assuming version in filename)
    artifacts.sort((a, b) => b.name.compareTo(a.name));

    return artifacts;
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.apk')) {
      return 'application/vnd.android.package-archive';
    } else if (lowerName.endsWith('.ipa')) {
      return 'application/octet-stream';
    } else if (lowerName.endsWith('.aab')) {
      return 'application/octet-stream';
    }
    return 'application/octet-stream';
  }

  /// Parse size string to bytes
  int? _parseSize(String sizeStr) {
    if (sizeStr.isEmpty) return null;
    
    try {
      // Remove commas and spaces
      final cleaned = sizeStr.replaceAll(',', '').replaceAll(' ', '');
      
      // Try to parse as number directly
      final bytes = int.tryParse(cleaned);
      if (bytes != null) return bytes;
      
      // Try to parse with units (KB, MB, GB)
      final units = ['KB', 'MB', 'GB'];
      for (var unit in units) {
        if (cleaned.toUpperCase().endsWith(unit)) {
          final numberStr = cleaned.substring(0, cleaned.length - unit.length);
          final number = double.tryParse(numberStr);
          if (number != null) {
            final multiplier = unit == 'KB' ? 1024 : (unit == 'MB' ? 1024 * 1024 : 1024 * 1024 * 1024);
            return (number * multiplier).round();
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to parse size: $sizeStr');
    }
    
    return null;
  }

  /// Download artifact
  Future<void> downloadArtifact(Artifact artifact) async {
    try {
      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      
      if (isAndroid) {
        // Android: Dosyayı direkt indirip Downloads klasörüne kaydet
        await _downloadFileAndroid(artifact);
      } else {
        // iOS/Other: url_launcher kullan
        await _downloadFileIOS(artifact);
      }
    } catch (e) {
      _logger.severe('Error downloading artifact: $e');
      rethrow;
    }
  }
  
  /// Android için dosya indirme
  Future<void> _downloadFileAndroid(Artifact artifact) async {
    try {
      _logger.info('Downloading artifact on Android: ${artifact.name}');
      
      // Android 9 ve altı için storage izni iste (Android 10+ için gerekli değil)
      if (Platform.isAndroid) {
        try {
          final androidVersion = await _getAndroidVersion();
          if (androidVersion != null && androidVersion < 29) {
            // Android 9 ve altı için storage izni iste
            final status = await Permission.storage.request();
            if (!status.isGranted) {
              _logger.warning('Storage permission not granted, file will be saved to app directory');
            }
          }
        } catch (e) {
          _logger.warning('Could not check Android version or request permission: $e');
        }
      }
      
      // Önce uygulama dizinine indir (Android 10+ scoped storage için)
      final appDir = await getApplicationDocumentsDirectory();
      final tempFilePath = path.join(appDir.path, artifact.name);
      
      _logger.info('Downloading to temporary location: $tempFilePath');
      
      final dio = CertificatePinningService.createSecureDio();
      await dio.download(
        artifact.downloadUrl,
        tempFilePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            _logger.info('Download progress: $progress%');
          }
        },
      );
      
      _logger.info('File downloaded to temporary location: $tempFilePath');
      
      // Android 10+ için Downloads klasörüne kopyala
      try {
        // Android'in Downloads klasörüne erişmeye çalış
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Android 10+ için Downloads klasörü
          final downloadsPath = path.join(externalDir.parent.path, 'Download');
          final downloadsDir = Directory(downloadsPath);
          
          // Klasör yoksa oluştur
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          
          final finalFilePath = path.join(downloadsPath, artifact.name);
          final tempFile = File(tempFilePath);
          final finalFile = File(finalFilePath);
          
          // Dosyayı kopyala
          await tempFile.copy(finalFilePath);
          _logger.info('File copied to Downloads: $finalFilePath');
          
          // Geçici dosyayı sil
          await tempFile.delete();
          _logger.info('Temporary file deleted');
        } else {
          _logger.warning('Could not access external storage, file saved to app directory: $tempFilePath');
        }
      } catch (e) {
        // Downloads klasörüne yazma başarısız, uygulama dizininde kalsın
        _logger.warning('Could not copy to Downloads directory: $e');
        _logger.info('File saved to app directory: $tempFilePath');
        // Dosya uygulama dizininde kalacak, kullanıcıya bildirim gösterilebilir
      }
      
    } catch (e) {
      _logger.severe('Error downloading file on Android: $e');
      rethrow;
    }
  }
  
  /// iOS için dosya indirme
  Future<void> _downloadFileIOS(Artifact artifact) async {
    try {
      _logger.info('Downloading artifact on iOS: ${artifact.name}');
      
      // iOS'ta Documents dizinine indir (iOS sandbox içinde)
      // iOS otomatik olarak dosyaları Files app'te gösterir
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = path.join(appDir.path, artifact.name);
      
      _logger.info('Downloading to: $filePath');
      
      final dio = CertificatePinningService.createSecureDio();
      await dio.download(
        artifact.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            _logger.info('Download progress: $progress%');
          }
        },
      );
      
      _logger.info('Successfully downloaded: ${artifact.name} to $filePath');
      _logger.info('File is available in Files app under: ${appDir.path}');
      
    } catch (e) {
      _logger.severe('Error downloading file on iOS: $e');
      // Fallback: url_launcher kullan
      try {
        final uri = Uri.parse(artifact.downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          _logger.info('Fallback: Launched download via browser for: ${artifact.name}');
        }
      } catch (e2) {
        _logger.severe('Fallback download also failed: $e2');
        rethrow;
      }
    }
  }
  
  /// Android sürümünü al (API level)
  Future<int?> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        // Platform.version format: "Android 12, API level 31"
        final versionString = Platform.version;
        final match = RegExp(r'API level (\d+)').firstMatch(versionString);
        if (match != null) {
          return int.tryParse(match.group(1)!);
        }
      }
    } catch (e) {
      _logger.warning('Could not get Android version: $e');
    }
    return null;
  }
}
