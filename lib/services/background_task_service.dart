/// Arka plan görev servisi
/// 
/// Uygulama kapalıyken bile çalışarak work item değişikliklerini kontrol eder.
/// Periyodik kontroller yaparak yeni atamalar ve güncellemeler için bildirim gönderir.
/// 
/// @author Alpay Bilgiç

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'work_item_service.dart';
import 'notification_service.dart';

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
  Map<int, int> _workItemRevisions = {};
  Map<int, String?> _workItemAssignees = {}; // Track assignees to detect assignee changes
  Map<int, DateTime?> _workItemChangedDates = {}; // Track changed dates for better change detection
  Set<int> _knownWorkItemIds = {};
  Set<int> _notifiedWorkItemIds = {}; // Track which work items we've already notified about

  /// Initialize the service (called on app start)
  Future<void> init() async {
    // This method exists for consistency with other services
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
    
    // Get polling interval from settings
    final prefs = await SharedPreferences.getInstance();
    final pollingInterval = prefs.getInt('polling_interval_seconds') ?? 15;
    final clampedInterval = pollingInterval.clamp(5, 300);
    
    // Start periodic checks with configured interval
    _backgroundTimer?.cancel();
    print('⏰ [BackgroundTaskService] Setting up periodic timer (${clampedInterval} second intervals)...');
    _backgroundTimer = Timer.periodic(Duration(seconds: clampedInterval), (timer) async {
      if (!_isRunning) {
        print('⚠️ [BackgroundTaskService] Timer stopped: _isRunning = false');
        timer.cancel();
        return;
      }
      
      print('🔄 [BackgroundTaskService] Periodic check at ${DateTime.now()}...');
      await _checkForChanges();
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
          return <dynamic>[]; // Return empty list on timeout
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
          
          // Always notify for new work items
          print('🆕 [BackgroundTaskService] New work item detected: #${workItem.id} - ${workItem.title}');
          await _notificationService.showWorkItemNotification(
            workItemId: workItem.id,
            title: workItem.title,
            body: 'Size yeni bir work item atandı: ${workItem.type}',
          );
          _notifiedWorkItemIds.add(workItem.id);
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
            await _notificationService.showWorkItemNotification(
              workItemId: workItem.id,
              title: workItem.title,
              body: notificationBody,
            );
            
            await _saveLastNotifiedRevision(workItem.id, currentRev);
            _notifiedWorkItemIds.add(workItem.id);
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
      // Only mark as "known" - don't mark as "notified" so new items can still trigger notifications
      for (var workItem in workItems) {
        _knownWorkItemIds.add(workItem.id);
        _workItemRevisions[workItem.id] = workItem.rev ?? 0;
        _workItemAssignees[workItem.id] = workItem.assignedTo;
        _workItemChangedDates[workItem.id] = workItem.changedDate;
        
        // Load last notified revision from storage
        final lastNotifiedRev = await _getLastNotifiedRevision(workItem.id);
        if (lastNotifiedRev != null && lastNotifiedRev >= (workItem.rev ?? 0)) {
          // This work item was already notified for this or a later revision
          // Mark as notified to prevent duplicate notifications
          _notifiedWorkItemIds.add(workItem.id);
        }
        // If no stored revision or current rev is newer, don't mark as notified
        // This allows new notifications for items that were created before app start
      }

      print('Background: Initialized tracking for ${workItems.length} work items (${_notifiedWorkItemIds.length} already notified)');
    } catch (e) {
      print('Error initializing tracking: $e');
    }
  }
}

