/// Arka plan görev servisi
/// 
/// Uygulama kapalıyken bile çalışarak work item değişikliklerini kontrol eder.
/// Periyodik kontroller yaparak yeni atamalar ve güncellemeler için bildirim gönderir.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'work_item_service.dart' show WorkItemService, WorkItem;
import 'notification_service.dart';
import 'market_service.dart';
import 'storage_service.dart';

/// Arka plan görev servisi sınıfı
/// Uygulama kapalıyken bile periyodik kontroller yapar
class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  Timer? _backgroundTimer;
  bool _isRunning = false;
  final WorkItemService _workItemService = WorkItemService();
  final NotificationService _notificationService = NotificationService();
  StorageService? _storageService;
  final Map<int, int> _workItemRevisions = {};
  final Map<int, String?> _workItemAssignees = {}; // Track assignees to detect assignee changes
  final Map<int, DateTime?> _workItemChangedDates = {}; // Track changed dates for better change detection
  Set<int> _knownWorkItemIds = {};
  Set<int> _notifiedWorkItemIds = {}; // Track which work items we've already notified about
  
  // SharedPreferences key for persistent notified work item IDs
  static const String _notifiedIdsKey = 'notified_work_item_ids';
  static const String _firstAssignmentNotifiedIdsKey = 'first_assignment_notified_work_item_ids';

  /// Initialize the service (called on app start)
  Future<void> init() async {
    // Initialize storage service
    _storageService = StorageService();
    await _storageService!.init();
    // Actual initialization happens in initializeTracking()
  }

  /// Start background task
  Future<void> start() async {
    if (_isRunning) {
      print('🔄 [BackgroundTaskService] Already running, skipping start');
      return;
    }
    
    print('🚀 [BackgroundTaskService] Starting background task service...');
    _isRunning = true;
    
    // Initialize tracking first if not already done
    if (_knownWorkItemIds.isEmpty) {
      print('🔄 [BackgroundTaskService] Initializing tracking...');
      await initializeTracking();
    }
    
    // Initial check
    print('🔄 [BackgroundTaskService] Performing initial check...');
    await _checkForChanges();
    await _checkForMarketFolderUpdates();
    
    // Get polling interval from settings
    final prefs = await SharedPreferences.getInstance();
    final pollingInterval = prefs.getInt('polling_interval_seconds') ?? 15;
    final clampedInterval = pollingInterval.clamp(5, 300);
    
    // Start periodic checks with configured interval
    _backgroundTimer?.cancel();
    print('⏰ [BackgroundTaskService] Setting up periodic timer ($clampedInterval second intervals)...');
    _backgroundTimer = Timer.periodic(Duration(seconds: clampedInterval), (timer) async {
      if (!_isRunning) {
        print('⚠️ [BackgroundTaskService] Timer stopped: _isRunning = false');
        timer.cancel();
        return;
      }
      
      print('🔄 [BackgroundTaskService] Periodic check at ${DateTime.now()}...');
      await _checkForChanges();
      await _checkForMarketFolderUpdates();
    });
    
    print('✅ [BackgroundTaskService] Background task service started successfully');
  }

  /// Stop background task
  void stop() {
    _isRunning = false;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    print('Background task service stopped');
  }

  /// Check for work item changes
  Future<void> _checkForChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('server_url');
      final collection = prefs.getString('collection');
      
      // Token'ı güvenli depolamadan al
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');
      
      if (serverUrl == null || token == null) {
        print('❌ [BackgroundTaskService] No auth data - serverUrl: ${serverUrl != null ? "✓" : "✗"}, token: ${token != null ? "✓" : "✗"}');
        return;
      }

      print('🔄 [BackgroundTaskService] Checking for work item changes... (tracking ${_knownWorkItemIds.length} items)');
      
      // Fetch work items with error handling and timeout
      final workItems = await _workItemService.getWorkItems(
        serverUrl: serverUrl,
        token: token,
        collection: collection,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ [BackgroundTaskService] Request timeout after 30 seconds');
          return List<WorkItem>.empty(); // Return empty list on timeout
        },
      );

      for (var workItem in workItems) {
        final currentRev = workItem.rev ?? 0;
        final knownRev = _workItemRevisions[workItem.id];
        final currentAssignee = workItem.assignedTo;
        final knownAssignee = _workItemAssignees[workItem.id];
        final currentChangedDate = workItem.changedDate;
        final knownChangedDate = _workItemChangedDates[workItem.id];
        
        if (!_knownWorkItemIds.contains(workItem.id)) {
          // New work item - just assigned to user
          _knownWorkItemIds.add(workItem.id);
          _workItemRevisions[workItem.id] = currentRev;
          _workItemAssignees[workItem.id] = currentAssignee;
          _workItemChangedDates[workItem.id] = currentChangedDate;
          
          // ÖNEMLİ: Eğer bu work item "ilk atamada bildirim" ile işaretlenmişse ve sadece "ilk atamada bildirim" aktifse,
          // bir daha asla bildirim gönderme
          if (await _isFirstAssignmentNotified(workItem.id)) {
            final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
            final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
            
            if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
              print('🔒 [BackgroundTaskService] Work item #${workItem.id} was first-assignment-notified, skipping all future notifications');
              continue;
            }
          }
          
          // ÖNEMLİ: Bu work item için daha önce bildirim gönderilmiş mi kontrol et
          // Uygulama yeniden kurulsa bile bu bilgi kalıcı olarak saklanır
          if (_wasNotified(workItem.id)) {
            // Son bildirim gönderilen revision'ı kontrol et
            final lastNotifiedRev = await _getLastNotifiedRevision(workItem.id);
            if (lastNotifiedRev != null && lastNotifiedRev >= currentRev) {
              // Bu work item için zaten bildirim gönderilmiş ve değişiklik yok
              print('📌 [BackgroundTaskService] Work item #${workItem.id} already notified previously (rev: $lastNotifiedRev), skipping');
              continue; // Bildirim gönderme, sonraki work item'a geç
            }
          }
          
          // Bildirim ayarlarını kontrol et
          final shouldNotify = await _shouldNotifyForWorkItem(workItem, isNew: true, wasAssigned: true);
          if (!shouldNotify) {
            print('🔕 [BackgroundTaskService] Notification skipped for work item #${workItem.id} based on settings');
            continue;
          }
          
          // Yeni work item veya değişiklik var - bildirim gönder
          print('🆕 [BackgroundTaskService] New work item detected: #${workItem.id} - ${workItem.title}');
          await _notificationService.showWorkItemNotification(
            workItemId: workItem.id,
            title: workItem.title,
            body: 'Size yeni bir work item atandı: ${workItem.type}',
          );
          
          // ÖNEMLİ: Eğer sadece "ilk atamada bildirim" aktifse (ve "tüm güncellemelerde bildirim" aktif değilse),
          // bu work item için bir daha ASLA bildirim gönderme (uygulama kaldırılıp tekrar kurulsa bile)
          final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
          final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
          
          if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
            // Sadece ilk atamada bildirim aktifse, bu work item'ı "first_assignment_notified" olarak işaretle
            // Bu sayede bir daha asla bildirim gönderilmeyecek
            await _markAsFirstAssignmentNotified(workItem.id);
            print('🔒 [BackgroundTaskService] Work item #${workItem.id} marked as first-assignment-notified (no more notifications)');
          }
          
          await _markAsNotified(workItem.id); // Kalıcı olarak kaydet
          await _saveLastNotifiedRevision(workItem.id, currentRev);
          print('✅ [BackgroundTaskService] Notification sent for work item #${workItem.id}');
        } else {
          // Check for changes
          bool shouldNotify = false;
          String notificationBody = '';
          
          // Check assignee change (highest priority - always notify)
          if (knownAssignee != currentAssignee) {
            shouldNotify = true;
            if (currentAssignee != null && currentAssignee.isNotEmpty) {
              notificationBody = 'Work item size atandı: ${workItem.type}';
            } else {
              notificationBody = 'Work item ataması kaldırıldı';
            }
            _workItemAssignees[workItem.id] = currentAssignee;
            print('👤 [BackgroundTaskService] Work item #${workItem.id} assignee changed: $knownAssignee -> $currentAssignee');
          }
          
          // Check revision change
          if (knownRev != null && currentRev > knownRev) {
            final lastNotifiedRev = await _getLastNotifiedRevision(workItem.id);
            
            if (lastNotifiedRev == null || currentRev > lastNotifiedRev) {
              shouldNotify = true;
              if (notificationBody.isEmpty) {
                notificationBody = 'Work item güncellendi: ${workItem.state}';
              }
              _workItemRevisions[workItem.id] = currentRev;
              print('📝 [BackgroundTaskService] Work item #${workItem.id} revision changed: $knownRev -> $currentRev');
            }
          }
          
          // Check changed date (more reliable for some changes)
          if (currentChangedDate != null && knownChangedDate != null) {
            if (currentChangedDate.isAfter(knownChangedDate)) {
              final lastNotifiedRev = await _getLastNotifiedRevision(workItem.id);
              
              // Only notify if we haven't already notified for this change
              if (lastNotifiedRev == null || (workItem.rev ?? 0) > lastNotifiedRev) {
                shouldNotify = true;
                if (notificationBody.isEmpty) {
                  notificationBody = 'Work item güncellendi: ${workItem.state}';
                }
              }
              _workItemChangedDates[workItem.id] = currentChangedDate;
              print('📅 [BackgroundTaskService] Work item #${workItem.id} changed date updated: $knownChangedDate -> $currentChangedDate');
            }
          } else if (currentChangedDate != null) {
            _workItemChangedDates[workItem.id] = currentChangedDate;
          }
          
          if (shouldNotify) {
            // ÖNEMLİ: Eğer bu work item "ilk atamada bildirim" ile işaretlenmişse ve sadece "ilk atamada bildirim" aktifse,
            // bir daha asla bildirim gönderme
            if (await _isFirstAssignmentNotified(workItem.id)) {
              final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
              final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
              
              if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
                print('🔒 [BackgroundTaskService] Work item #${workItem.id} was first-assignment-notified, skipping all future notifications');
                // Update tracking even if notification skipped
                if (knownRev == null) {
                  _workItemRevisions[workItem.id] = currentRev;
                }
                if (knownAssignee == null) {
                  _workItemAssignees[workItem.id] = currentAssignee;
                }
                if (knownChangedDate == null && currentChangedDate != null) {
                  _workItemChangedDates[workItem.id] = currentChangedDate;
                }
                continue;
              }
            }
            
            // Bildirim ayarlarını kontrol et
            final wasAssigned = knownAssignee == null && currentAssignee != null;
            final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
            final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
            
            // ÇİFT KONTROL: Eğer sadece "ilk atamada bildirim" aktifse, güncellemelerde bildirim gönderme
            if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
              print('🔒 [BackgroundTaskService] Work item #${workItem.id} - First assignment only mode active, blocking update notification');
              // Update tracking even if notification skipped
              if (knownRev == null) {
                _workItemRevisions[workItem.id] = currentRev;
              }
              if (knownAssignee == null) {
                _workItemAssignees[workItem.id] = currentAssignee;
              }
              if (knownChangedDate == null && currentChangedDate != null) {
                _workItemChangedDates[workItem.id] = currentChangedDate;
              }
              continue;
            }
            
            if (!await _shouldNotifyForWorkItem(workItem, isNew: false, wasAssigned: wasAssigned)) {
              print('🔕 [BackgroundTaskService] Notification skipped for work item #${workItem.id} based on settings');
              // Update tracking even if notification skipped
              if (knownRev == null) {
                _workItemRevisions[workItem.id] = currentRev;
              }
              if (knownAssignee == null) {
                _workItemAssignees[workItem.id] = currentAssignee;
              }
              if (knownChangedDate == null && currentChangedDate != null) {
                _workItemChangedDates[workItem.id] = currentChangedDate;
              }
              continue;
            }
            
            await _notificationService.showWorkItemNotification(
              workItemId: workItem.id,
              title: workItem.title,
              body: notificationBody,
            );
            
            await _saveLastNotifiedRevision(workItem.id, currentRev);
            await _markAsNotified(workItem.id); // Kalıcı olarak kaydet
            print('✅ [BackgroundTaskService] Notification sent for work item #${workItem.id}: $notificationBody');
          }
          
          // Update tracking even if no notification sent
          if (knownRev == null) {
            _workItemRevisions[workItem.id] = currentRev;
          }
          if (knownAssignee == null) {
            _workItemAssignees[workItem.id] = currentAssignee;
          }
          if (knownChangedDate == null && currentChangedDate != null) {
            _workItemChangedDates[workItem.id] = currentChangedDate;
          }
        }
      }

      // Update known IDs
      final previousCount = _knownWorkItemIds.length;
      _knownWorkItemIds = workItems.map((item) => item.id).toSet();
      
      // Remove tracking data for items no longer assigned
      _workItemRevisions.removeWhere((id, _) => !_knownWorkItemIds.contains(id));
      _workItemAssignees.removeWhere((id, _) => !_knownWorkItemIds.contains(id));
      _workItemChangedDates.removeWhere((id, _) => !_knownWorkItemIds.contains(id));
      
      print('✅ [BackgroundTaskService] Check completed - tracking ${_knownWorkItemIds.length} items (was $previousCount)');
      
    } catch (e, stackTrace) {
      print('❌ [BackgroundTaskService] Check error: $e');
      print('❌ [BackgroundTaskService] Stack trace: $stackTrace');
    }
  }

  /// Get last notified revision for a work item
  Future<int?> _getLastNotifiedRevision(int workItemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('notified_rev_$workItemId');
    } catch (e) {
      return null;
    }
  }

  /// Save last notified revision for a work item
  Future<void> _saveLastNotifiedRevision(int workItemId, int revision) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notified_rev_$workItemId', revision);
    } catch (e) {
      print('Error saving notified revision: $e');
    }
  }
  
  /// Load notified work item IDs from persistent storage
  Future<void> _loadNotifiedWorkItemIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsJson = prefs.getString(_notifiedIdsKey);
      if (idsJson != null && idsJson.isNotEmpty) {
        final List<dynamic> ids = jsonDecode(idsJson);
        _notifiedWorkItemIds = ids.map((e) => e as int).toSet();
        print('📂 [BackgroundTaskService] Loaded ${_notifiedWorkItemIds.length} notified work item IDs from storage');
      }
    } catch (e) {
      print('⚠️ [BackgroundTaskService] Error loading notified work item IDs: $e');
    }
  }
  
  /// Save notified work item IDs to persistent storage
  Future<void> _saveNotifiedWorkItemIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notifiedIdsKey, jsonEncode(_notifiedWorkItemIds.toList()));
      print('💾 [BackgroundTaskService] Saved ${_notifiedWorkItemIds.length} notified work item IDs to storage');
    } catch (e) {
      print('⚠️ [BackgroundTaskService] Error saving notified work item IDs: $e');
    }
  }
  
  /// Add work item ID to notified set and persist
  Future<void> _markAsNotified(int workItemId) async {
    _notifiedWorkItemIds.add(workItemId);
    await _saveNotifiedWorkItemIds();
  }
  
  /// Check if work item was already notified
  bool _wasNotified(int workItemId) {
    return _notifiedWorkItemIds.contains(workItemId);
  }
  
  /// Mark work item as first-assignment-notified (permanent, even after app reinstall)
  Future<void> _markAsFirstAssignmentNotified(int workItemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsJson = prefs.getString(_firstAssignmentNotifiedIdsKey);
      Set<int> firstAssignmentNotifiedIds = {};
      
      if (idsJson != null && idsJson.isNotEmpty) {
        final List<dynamic> ids = jsonDecode(idsJson);
        firstAssignmentNotifiedIds = ids.map((e) => e as int).toSet();
      }
      
      firstAssignmentNotifiedIds.add(workItemId);
      await prefs.setString(_firstAssignmentNotifiedIdsKey, jsonEncode(firstAssignmentNotifiedIds.toList()));
      print('🔒 [BackgroundTaskService] Work item #$workItemId marked as first-assignment-notified (permanent)');
    } catch (e) {
      print('⚠️ [BackgroundTaskService] Error marking first-assignment-notified: $e');
    }
  }
  
  /// Check if work item was first-assignment-notified (permanent check)
  Future<bool> _isFirstAssignmentNotified(int workItemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsJson = prefs.getString(_firstAssignmentNotifiedIdsKey);
      
      if (idsJson == null || idsJson.isEmpty) {
        return false;
      }
      
      final List<dynamic> ids = jsonDecode(idsJson);
      final firstAssignmentNotifiedIds = ids.map((e) => e as int).toSet();
      return firstAssignmentNotifiedIds.contains(workItemId);
    } catch (e) {
      print('⚠️ [BackgroundTaskService] Error checking first-assignment-notified: $e');
      return false;
    }
  }

  /// Reset tracking data
  void reset() {
    _knownWorkItemIds.clear();
    _workItemRevisions.clear();
    _workItemAssignees.clear();
    _workItemChangedDates.clear();
    _notifiedWorkItemIds.clear();
  }

  /// Initialize tracking data from storage (called on app start)
  Future<void> initializeTracking() async {
    try {
      // ÖNCE: Kalıcı olarak saklanan bildirim gönderilmiş ID'leri yükle
      await _loadNotifiedWorkItemIds();
      
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('server_url');
      final collection = prefs.getString('collection');
      
      // Token'ı güvenli depolamadan al
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');
      
      if (serverUrl == null || token == null) {
        return;
      }

      // Load current work items to initialize tracking
      final workItems = await _workItemService.getWorkItems(
        serverUrl: serverUrl,
        token: token,
        collection: collection,
      );

      // Initialize tracking without sending notifications
      for (var workItem in workItems) {
        _knownWorkItemIds.add(workItem.id);
        _workItemRevisions[workItem.id] = workItem.rev ?? 0;
        _workItemAssignees[workItem.id] = workItem.assignedTo;
        _workItemChangedDates[workItem.id] = workItem.changedDate;
        
        // Eğer bu work item daha önce bildirim gönderilmişse (kalıcı listede varsa)
        // tekrar bildirim gönderme
        if (_wasNotified(workItem.id)) {
          // Son bildirim gönderilen revision'ı kontrol et
          final lastNotifiedRev = await _getLastNotifiedRevision(workItem.id);
          if (lastNotifiedRev != null && lastNotifiedRev >= (workItem.rev ?? 0)) {
            // Bu work item için zaten bildirim gönderilmiş ve değişiklik yok
            print('📌 [BackgroundTaskService] Work item #${workItem.id} already notified (rev: $lastNotifiedRev)');
          }
        }
      }

      print('✅ [BackgroundTaskService] Initialized tracking for ${workItems.length} work items (${_notifiedWorkItemIds.length} already notified in storage)');
    } catch (e) {
      print('❌ [BackgroundTaskService] Error initializing tracking: $e');
    }
  }

  /// Check for new files in favorite market folders
  Future<void> _checkForMarketFolderUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final marketUrl = prefs.getString('market_repo_url');
      
      if (marketUrl == null || marketUrl.isEmpty) {
        return; // No market URL configured
      }

      // Get favorite folders
      final favoritesJson = prefs.getString('market_favorite_folders');
      if (favoritesJson == null || favoritesJson.isEmpty) {
        return; // No favorite folders
      }

      final List<dynamic> favoriteFolders = jsonDecode(favoritesJson);
      if (favoriteFolders.isEmpty) {
        return; // No favorite folders
      }

      // Get tracked files
      final trackedJson = prefs.getString('market_tracked_folder_files');
      Map<String, List<String>> trackedFiles = {};
      if (trackedJson != null && trackedJson.isNotEmpty) {
        try {
          final Map<String, dynamic> tracked = jsonDecode(trackedJson);
          trackedFiles = tracked.map((key, value) => MapEntry(key, (value as List).cast<String>()));
        } catch (e) {
          print('⚠️ [BackgroundTaskService] Error parsing tracked files: $e');
        }
      }

      print('🔄 [BackgroundTaskService] Checking ${favoriteFolders.length} favorite market folders...');

      for (var folderPath in favoriteFolders) {
        try {
          // FIXED Bug #2: Normalize marketUrl before concatenation
          // Prevents malformed URLs like "https://example.com/_static/marketandroid/"
          // when marketUrl doesn't have trailing slash
          String normalizedMarketUrl = marketUrl;
          if (!normalizedMarketUrl.endsWith('/')) {
            normalizedMarketUrl += '/';
          }
          final folderUrl = '$normalizedMarketUrl$folderPath';
          
          // Get folder name from path (e.g., "android/bankacilik-uygulamasi/" -> "bankacilik-uygulamasi")
          final folderName = folderPath.split('/').where((p) => p.isNotEmpty).lastOrNull ?? folderPath;
          
          // Get current files in folder
          final currentFiles = await _getFilesFromFolder(folderUrl);
          final currentFileNames = currentFiles.map((a) => a.name).toList();
          
          // Get previously tracked files
          final previousFiles = trackedFiles[folderPath] ?? [];
          
          // Find new files
          final newFiles = currentFileNames.where((name) => !previousFiles.contains(name)).toList();
          
          if (newFiles.isNotEmpty) {
            print('🆕 [BackgroundTaskService] New files found in folder $folderName: $newFiles');
            
            // Send notification for each new file
            for (var fileName in newFiles) {
              await _notificationService.showLocalNotification(
                title: 'Yeni Dosya: $folderName',
                body: fileName,
                payload: 'market:$folderPath:$fileName',
              );
            }
            
            // Update tracked files
            trackedFiles[folderPath] = currentFileNames;
          }
        } catch (e) {
          print('⚠️ [BackgroundTaskService] Error checking folder $folderPath: $e');
          continue; // Continue with next folder
        }
      }

      // Save updated tracked files
      if (trackedFiles.isNotEmpty) {
        await prefs.setString('market_tracked_folder_files', jsonEncode(trackedFiles));
      }

      print('✅ [BackgroundTaskService] Market folder check completed');
    } catch (e, stackTrace) {
      print('❌ [BackgroundTaskService] Market folder check error: $e');
      print('❌ [BackgroundTaskService] Stack trace: $stackTrace');
    }
  }

  /// Get files from a market folder (simplified version for background service)
  Future<List<Artifact>> _getFilesFromFolder(String folderUrl) async {
    try {
      // Use Dio directly for background service (no auth needed for public IIS directories)
      final dio = Dio();
      
      // Normalize URL
      String normalizedUrl = folderUrl.trim();
      if (!normalizedUrl.endsWith('/')) {
        normalizedUrl += '/';
      }

      final response = await dio.get(
        normalizedUrl,
        options: Options(
          headers: {
            'Accept': 'text/html,application/json',
          },
          responseType: ResponseType.plain,
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final content = response.data as String;
        if (content.isEmpty) return [];

        // Try JSON first
        try {
          final jsonData = jsonDecode(content);
          if (jsonData is List) {
            return _parseJsonFiles(jsonData, normalizedUrl);
          } else if (jsonData is Map && jsonData['files'] != null) {
            return _parseJsonFiles(jsonData['files'] as List, normalizedUrl);
          }
        } catch (e) {
          // Not JSON, try HTML
        }

        // Parse HTML
        return _parseHtmlFiles(content, normalizedUrl);
      }
      
      return [];
    } catch (e) {
      print('⚠️ [BackgroundTaskService] Error getting files from folder: $e');
      return [];
    }
  }

  /// Parse JSON files (simplified)
  List<Artifact> _parseJsonFiles(List<dynamic> files, String baseUrl) {
    final artifacts = <Artifact>[];
    for (var file in files) {
      if (file is Map<String, dynamic>) {
        final name = file['name'] as String? ?? '';
        final isDirectory = file['isDirectory'] as bool? ?? false;
        if (!isDirectory && (name.toLowerCase().endsWith('.apk') || 
            name.toLowerCase().endsWith('.ipa') || 
            name.toLowerCase().endsWith('.aab'))) {
          artifacts.add(Artifact(
            name: name,
            downloadUrl: '$baseUrl$name',
            size: file['size'] as int?,
            contentType: 'application/octet-stream',
          ));
        }
      }
    }
    return artifacts;
  }

  /// Parse HTML files (simplified)
  List<Artifact> _parseHtmlFiles(String html, String baseUrl) {
    final artifacts = <Artifact>[];
    final document = html_parser.parse(html);
    final links = document.querySelectorAll('a');
    
    for (var link in links) {
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;
      if (href == '../' || href == '..' || href == './' || href == '.' || href.endsWith('/')) continue;
      
      String fileName = href;
      if (fileName.contains('?')) fileName = fileName.split('?').first;
      if (fileName.contains('#')) fileName = fileName.split('#').first;
      
      try {
        fileName = Uri.decodeComponent(fileName);
      } catch (e) {
        // Ignore
      }
      
      fileName = fileName.split('/').last.trim();
      final lowerName = fileName.toLowerCase();
      
      if (lowerName.endsWith('.apk') || lowerName.endsWith('.ipa') || lowerName.endsWith('.aab')) {
        String downloadUrl;
        if (href.startsWith('http://') || href.startsWith('https://')) {
          downloadUrl = href;
        } else {
          final baseUri = Uri.parse(baseUrl);
          downloadUrl = baseUri.resolve(href).toString();
        }
        
        if (!artifacts.any((a) => a.name == fileName)) {
          artifacts.add(Artifact(
            name: fileName,
            downloadUrl: downloadUrl,
            size: null,
            contentType: 'application/octet-stream',
          ));
        }
      }
    }
    
    return artifacts;
  }
  
  /// Check if notification should be sent based on user settings
  Future<bool> _shouldNotifyForWorkItem(WorkItem workItem, {required bool isNew, required bool wasAssigned}) async {
    try {
      // Initialize storage service if not already done
      if (_storageService == null) {
        _storageService = StorageService();
        await _storageService!.init();
      }
      
      // Get notification settings
      final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
      final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
      final notifyOnHotfixOnly = _storageService!.getNotifyOnHotfixOnly();
      final notifyOnGroupAssignments = _storageService!.getNotifyOnGroupAssignments();
      final notificationGroups = await _storageService!.getNotificationGroups();
      
      // DEBUG: Log all notification settings
      print('🔍 [BackgroundTaskService] Notification settings: notifyOnFirstAssignment=$notifyOnFirstAssignment, notifyOnAllUpdates=$notifyOnAllUpdates, notifyOnHotfixOnly=$notifyOnHotfixOnly, notifyOnGroupAssignments=$notifyOnGroupAssignments, groups=${notificationGroups.length}');
      
      // ÖNEMLİ: Eğer hiçbir bildirim ayarı aktif değilse, bildirim gönderme
      if (!notifyOnFirstAssignment && !notifyOnAllUpdates && !notifyOnHotfixOnly && !notifyOnGroupAssignments) {
        print('🔕 [BackgroundTaskService] Skipping notification: No notification settings enabled (all disabled)');
        return false;
      }
      
      // ÖNEMLİ: Eğer sadece "ilk atamada bildirim" aktifse (ve "tüm güncellemelerde bildirim" aktif değilse),
      // ve bu work item daha önce "first_assignment_notified" olarak işaretlenmişse,
      // bir daha asla bildirim gönderme
      if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
        if (await _isFirstAssignmentNotified(workItem.id)) {
          print('🔒 [BackgroundTaskService] Skipping notification: First assignment only mode and work item #${workItem.id} was already notified');
          return false;
        }
      }
      
      // Sadece Hotfix filtresi
      if (notifyOnHotfixOnly && workItem.type.toLowerCase() != 'hotfix') {
        print('🔕 [BackgroundTaskService] Skipping notification: Only Hotfix allowed, but type is ${workItem.type}');
        return false;
      }
      
      // İlk atamada bildirim kontrolü
      if (isNew && wasAssigned) {
        // Sadece ilk atamada bildirim gönder seçeneği aktifse ve bu ilk atama ise, bildirim gönder
        if (notifyOnFirstAssignment) {
          print('✅ [BackgroundTaskService] Notifying: First assignment allowed and this is a new assignment');
          return true;
        } else {
          print('🔕 [BackgroundTaskService] Skipping notification: First assignment notifications disabled');
          return false;
        }
      }
      
      // Tüm güncellemelerde bildirim kontrolü (sadece ilk atama değilse)
      if (!isNew && !wasAssigned) {
        // Eğer sadece "ilk atamada bildirim" aktifse, güncellemelerde bildirim gönderme
        if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
          print('🔕 [BackgroundTaskService] Skipping notification: First assignment only mode, no updates allowed');
          return false;
        }
        // Tüm güncellemelerde bildirim gönder seçeneği aktifse, bildirim gönder
        if (notifyOnAllUpdates) {
          print('✅ [BackgroundTaskService] Notifying: All updates allowed and this is an update');
          return true;
        } else {
          print('🔕 [BackgroundTaskService] Skipping notification: All updates notifications disabled');
          return false;
        }
      }
      
      // Eğer ilk atama değil ama assignee değiştiyse, notifyOnAllUpdates kontrolü yap
      if (!isNew && wasAssigned) {
        // Eğer sadece "ilk atamada bildirim" aktifse, assignee değişikliklerinde de bildirim gönderme
        if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
          print('🔕 [BackgroundTaskService] Skipping notification: First assignment only mode, no updates allowed for assignee change');
          return false;
        }
        if (notifyOnAllUpdates) {
          print('✅ [BackgroundTaskService] Notifying: All updates allowed and assignee changed');
          return true;
        } else {
          print('🔕 [BackgroundTaskService] Skipping notification: All updates disabled for assignee change');
          return false;
        }
      }
      
      // Grup atamalarında bildirim kontrolü
      if (notifyOnGroupAssignments && notificationGroups.isNotEmpty) {
        final assignedTo = workItem.assignedTo?.toLowerCase() ?? '';
        final isGroupAssignment = notificationGroups.any((group) {
          final groupLower = group.toLowerCase();
          // Check if assignedTo contains group name or vice versa
          return assignedTo.contains(groupLower) || groupLower.contains(assignedTo);
        });
        
        if (!isGroupAssignment && wasAssigned) {
          print('🔕 [BackgroundTaskService] Skipping notification: Not a group assignment (groups: $notificationGroups, assignedTo: ${workItem.assignedTo})');
          return false;
        }
      }
      
      // Eğer sadece "ilk atamada bildirim" aktifse ve bu bir güncelleme ise, bildirim gönderme
      if (notifyOnFirstAssignment && !notifyOnAllUpdates && !isNew) {
        print('🔕 [BackgroundTaskService] Skipping notification: First assignment only mode, this is an update (isNew=$isNew, wasAssigned=$wasAssigned)');
        return false;
      }
      
      // Eğer hiçbir koşul eşleşmediyse ve sadece "ilk atamada bildirim" aktifse, bildirim gönderme
      if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
        print('🔕 [BackgroundTaskService] Skipping notification: First assignment only mode, no matching condition (isNew=$isNew, wasAssigned=$wasAssigned)');
        return false;
      }
      
      // Eğer hiçbir bildirim ayarı aktif değilse, bildirim gönderme
      if (!notifyOnFirstAssignment && !notifyOnAllUpdates) {
        print('🔕 [BackgroundTaskService] Skipping notification: No notification settings enabled (notifyOnFirstAssignment=$notifyOnFirstAssignment, notifyOnAllUpdates=$notifyOnAllUpdates)');
        return false;
      }
      
      // Default: bildirim gönder (sadece yukarıdaki kontrollerden geçtiyse)
      // NOT: Bu sadece notifyOnAllUpdates aktifse veya notifyOnFirstAssignment aktif değilse çalışır
      return true;
    } catch (e) {
      print('⚠️ [BackgroundTaskService] Error checking notification settings: $e');
      // On error, default to sending notification (fail-safe)
      return true;
    }
  }
}

