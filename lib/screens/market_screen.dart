/// Market Ekranı
/// 
/// IIS static dizininden klasörleri ve dosyaları gösterir.
/// Kullanıcılar klasörleri favorilerine ekleyebilir ve APK/IPA dosyalarını indirebilir.
/// 
/// @author Alpay Bilgiç
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/market_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';

/// Market ekranı widget'ı
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  MarketService? _marketService;
  List<MarketFolder> _folders = [];
  List<Artifact> _artifacts = [];
  bool _isLoading = false;
  String? _error;
  String? _downloadingArtifact;
  String? _currentFolderPath; // Currently viewing folder or null for root
  Set<String> _favoriteFolders = {}; // Track favorite folders

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadFolders();
  }

  void _initializeService() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      setState(() {
        _marketService = MarketService(authService);
      });
    });
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentFolderPath = ''; // Reset to root (empty string for easier path concatenation)
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final marketUrl = storage.getMarketRepoUrl();

      if (marketUrl == null || marketUrl.isEmpty) {
        setState(() {
          _error = 'Market URL ayarlanmamış. Lütfen Ayarlar\'dan Market URL\'sini girin.\n\nÖrnek: https://devops.higgscloud.com/_static/market/';
          _isLoading = false;
        });
        return;
      }

      if (_marketService == null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        _marketService = MarketService(authService);
      }

      // Load favorite folders
      final favorites = await storage.getFavoriteFolders();
      setState(() {
        _favoriteFolders = favorites.toSet();
      });

      // Load folders and files from current path
      // Normalize marketUrl - ensure it ends with /
      String normalizedMarketUrl = marketUrl;
      if (!normalizedMarketUrl.endsWith('/')) {
        normalizedMarketUrl += '/';
      }
      
      final baseUrl = _currentFolderPath != null && _currentFolderPath!.isNotEmpty
          ? '$normalizedMarketUrl$_currentFolderPath'
          : normalizedMarketUrl;
      
      // Load both folders and files
      final folders = await _marketService!.getFolders(baseUrl);
      final allArtifacts = await _marketService!.getFiles(baseUrl);
      
      // Filter out folders from artifacts (only show files)
      final fileArtifacts = allArtifacts.where((a) => 
        !a.name.endsWith('/') && 
        (a.name.toLowerCase().endsWith('.apk') || 
         a.name.toLowerCase().endsWith('.ipa') || 
         a.name.toLowerCase().endsWith('.aab'))
      ).toList();
      
        // Update tracked files for favorite folders (root level)
        final currentPath = _currentFolderPath;
        for (var favoritePath in _favoriteFolders) {
          // Only update if we're at root or in the favorite folder
          if (currentPath == null || favoritePath.startsWith(currentPath)) {
          try {
            final favoriteUrl = '$marketUrl$favoritePath';
            final favoriteFiles = await _marketService!.getFiles(favoriteUrl);
            final favoriteFileNames = favoriteFiles
                .where((a) => a.name.toLowerCase().endsWith('.apk') || 
                             a.name.toLowerCase().endsWith('.ipa') || 
                             a.name.toLowerCase().endsWith('.aab'))
                .map((a) => a.name)
                .toList();
            await storage.updateTrackedFolderFiles(favoritePath, favoriteFileNames);
          } catch (e) {
            // Ignore errors for individual favorite folders
            print('⚠️ Error updating tracked files for $favoritePath: $e');
          }
        }
      }
      
      setState(() {
        _folders = folders;
        _artifacts = fileArtifacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Klasörler yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFolder(String folderPath) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final marketUrl = storage.getMarketRepoUrl();

      if (marketUrl == null || marketUrl.isEmpty) {
        setState(() {
          _error = 'Market URL ayarlanmamış.';
          _isLoading = false;
        });
        return;
      }

      // Normalize folderPath - ensure it doesn't start with / and ends with /
      String normalizedFolderPath = folderPath;
      if (normalizedFolderPath.startsWith('/')) {
        // Remove leading slash
        normalizedFolderPath = normalizedFolderPath.substring(1);
      }
      if (!normalizedFolderPath.endsWith('/')) {
        normalizedFolderPath += '/';
      }
      
      
      // FIXED Bug #1: Use folderPath directly as the full path
      // Previous code incorrectly appended to _currentFolderPath, causing navigation issues
      // like "android/app/android/" when clicking back button
      String fullPath = normalizedFolderPath;
      
      // Update current folder path
      setState(() {
        _currentFolderPath = fullPath;
      });
      
      // Ensure marketUrl ends with /
      String normalizedMarketUrl = marketUrl;
      if (!normalizedMarketUrl.endsWith('/')) {
        normalizedMarketUrl += '/';
      }
      
      final folderUrl = '$normalizedMarketUrl$fullPath';
      final folders = await _marketService!.getFolders(folderUrl);
      final allArtifacts = await _marketService!.getFiles(folderUrl);
      
      // Filter out folders from artifacts (only show files)
      final fileArtifacts = allArtifacts.where((a) => 
        !a.name.endsWith('/') && 
        (a.name.toLowerCase().endsWith('.apk') || 
         a.name.toLowerCase().endsWith('.ipa') || 
         a.name.toLowerCase().endsWith('.aab'))
      ).toList();
      
      // CRITICAL: Filter folders to only show direct children of current directory
      // This prevents parent directory folders from appearing in subdirectories
      final validFolders = folders.where((folder) {
        // folder.path should be a relative path like "ABC/" or "1.0.29/"
        // It should NOT contain the current fullPath
        // For example, if fullPath is "market/ABC/", folder.path should be "1.0.29/" not "market/DEF/"
        
        // Simple check: folder's path should not contain multiple segments beyond current level
        final folderPathSegments = folder.path.split('/').where((s) => s.isNotEmpty).toList();
        
        // Direct child folders should have exactly 1 segment
        // Example: if we're in "market/ABC/", valid folders are "1.0.29/", "1.0.30/" (1 segment each)
        // Invalid would be "market/DEF/" (contains "market" which is parent)
        return folderPathSegments.length == 1;
      }).toList();
      
      // Update tracked files for favorite folders
      if (_favoriteFolders.contains(fullPath)) {
        final fileNames = fileArtifacts.map((a) => a.name).toList();
        await storage.updateTrackedFolderFiles(fullPath, fileNames);
      }
      
      setState(() {
        _folders = validFolders; // Use filtered folders
        _artifacts = fileArtifacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Klasör yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  /// Helper method to calculate full path from relative folder path
  String _getFullPath(String relativePath) {
    final currentPath = _currentFolderPath ?? '';
    return currentPath.isEmpty ? relativePath : '$currentPath$relativePath';
  }

  Future<void> _toggleFavorite(String folderPath) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    
    if (_favoriteFolders.contains(folderPath)) {
      await storage.removeFavoriteFolder(folderPath);
      setState(() {
        _favoriteFolders.remove(folderPath);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorilerden kaldırıldı'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      await storage.addFavoriteFolder(folderPath);
      setState(() {
        _favoriteFolders.add(folderPath);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorilere eklendi'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _downloadArtifact(Artifact artifact) async {
    if (_downloadingArtifact == artifact.name) {
      return; // Already downloading
    }

    setState(() {
      _downloadingArtifact = artifact.name;
    });

    // Show progress dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Dosya İndiriliyor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              artifact.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (artifact.size != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatSize(artifact.size),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Lütfen bekleyin...',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );

    try {
      print('📥 [MarketScreen] Starting download: ${artifact.name}');
      print('📥 [MarketScreen] URL: ${artifact.downloadUrl}');
      print('📥 [MarketScreen] Folder path: $_currentFolderPath');
      
      await _marketService!.downloadArtifact(artifact, folderPath: _currentFolderPath);
      
      print('✅ [MarketScreen] Download completed: ${artifact.name}');
      
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${artifact.name} başarıyla indirildi!\nİndirilenler > RDC_AzureDevOps klasöründe'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ [MarketScreen] Download error: $e');
      print('❌ [MarketScreen] Stack trace: $stackTrace');
      
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        
        String errorMessage = 'İndirme hatası: ';
        final errorString = e.toString();
        if (errorString.contains('Connection closed')) {
          errorMessage += 'Bağlantı kesildi. Lütfen tekrar deneyin.';
        } else if (errorString.contains('timeout')) {
          errorMessage += 'Zaman aşımı. Lütfen tekrar deneyin.';
        } else if (errorString.contains('Could not copy to Downloads')) {
          errorMessage += 'Dosya indirildi ancak Downloads klasörüne kopyalanamadı. Detaylar için logları kontrol edin.';
        } else {
          errorMessage += errorString;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: () {
                _downloadArtifact(artifact);
              },
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _downloadingArtifact = null;
      });
    }
  }

  String _formatSize(int? size) {
    if (size == null) return 'Bilinmiyor';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentFolderPath != null && _currentFolderPath!.isNotEmpty ? 'Market: $_currentFolderPath' : 'Market: Uygulama Listesi'),
        leading: _currentFolderPath != null && _currentFolderPath!.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Go back to parent folder
                  String? parentPath = _currentFolderPath;
                  if (parentPath != null && parentPath.isNotEmpty) {
                    // Remove trailing slash
                    if (parentPath.endsWith('/')) {
                      parentPath = parentPath.substring(0, parentPath.length - 1);
                    }
                    // Get parent directory
                    final pathParts = parentPath.split('/').where((p) => p.isNotEmpty).toList();
                    if (pathParts.length > 1) {
                      pathParts.removeLast();
                      _loadFolder('${pathParts.join('/')}/');
                    } else if (pathParts.length == 1) {
                      // Go back to root
                      _loadFolders();
                    } else {
                      _loadFolders(); // Already at root
                    }
                  } else {
                    _loadFolders(); // Go back to root
                  }
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadFolders,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                            // Reload when returning from settings
                            _loadFolders();
                          },
                          child: const Text('Ayarlara Git'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFolders,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Folders section
                      if (_folders.isNotEmpty) ...[
                        const Text(
                          'Klasörler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._folders.map((folder) => Card(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: const Icon(Icons.folder, color: Colors.blue),
                                title: Text(folder.name),
                                subtitle: Text(folder.path),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final fullPath = _getFullPath(folder.path);
                                        final isFavorite = _favoriteFolders.contains(fullPath);
                                        return IconButton(
                                          icon: Icon(
                                            isFavorite ? Icons.star : Icons.star_border,
                                            color: isFavorite ? Colors.amber : Colors.grey,
                                          ),
                                          onPressed: () => _toggleFavorite(fullPath),
                                          tooltip: isFavorite
                                              ? 'Favorilerden kaldır'
                                              : 'Favorilere ekle',
                                        );
                                      },
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () {
                                  // CRITICAL FIX: Append folder.path to current path for multi-level navigation
                                  // Example: current="market/ABC/", folder="1.0.29/" → full="market/ABC/1.0.29/"
                                  // folder.path is always relative (e.g., "1.0.29/"), so we append it to current path
                                  final fullPath = _getFullPath(folder.path);
                                  _loadFolder(fullPath);
                                },
                              ),
                            )),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                      ],
                      // Files section
                      if (_artifacts.isNotEmpty) ...[
                        const Text(
                          'Dosyalar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._artifacts.map((artifact) {
                          IconData icon;
                          Color color;

                          if (artifact.isApk) {
                            icon = Icons.android;
                            color = Colors.green;
                          } else if (artifact.isIpa) {
                            icon = Icons.phone_iphone;
                            color = Colors.blue;
                          } else if (artifact.isAab) {
                            icon = Icons.android;
                            color = Colors.orange;
                          } else {
                            icon = Icons.insert_drive_file;
                            color = Colors.grey;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              leading: Icon(icon, color: color, size: 32),
                              title: Text(
                                artifact.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(_formatSize(artifact.size)),
                              trailing: _downloadingArtifact == artifact.name
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.download),
                                      onPressed: () => _downloadArtifact(artifact),
                                      tooltip: 'İndir',
                                    ),
                              onTap: () => _downloadArtifact(artifact),
                            ),
                          );
                        }),
                      ],
                      // Empty state
                      if (_folders.isEmpty && _artifacts.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Henüz klasör veya dosya bulunamadı',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
