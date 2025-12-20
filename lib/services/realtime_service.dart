/// Gerçek zamanlı servis
/// 
/// WebSocket kullanarak gerçek zamanlı work item güncellemelerini dinler.
/// WebSocket mevcut değilse optimize edilmiş polling mekanizmasına geçer.
/// 
/// @author Alpay Bilgiç
library;

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'work_item_service.dart';
import 'notification_service.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// Gerçek zamanlı servis sınıfı
/// WebSocket veya polling ile gerçek zamanlı güncellemeleri dinler
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  bool _shouldReconnect = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  
  final WorkItemService _workItemService = WorkItemService();
  final NotificationService _notificationService = NotificationService();
  StorageService? _storageService;
  Set<int> _knownWorkItemIds = {};
  
  // Callbacks
  Function(List<int>)? onNewWorkItems;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  /// Start real-time monitoring
  Future<void> start({
    required AuthService authService,
    required StorageService storageService,
    Function(List<int>)? onNewWorkItems,
    Function(String)? onError,
    Function()? onConnected,
    Function()? onDisconnected,
  }) async {
    print('🚀 [RealtimeService] Starting service...');
    
    // Store storage service for notification settings
    _storageService = storageService;
    
    // Update callbacks even if already running
    this.onNewWorkItems = onNewWorkItems;
    this.onError = onError;
    this.onConnected = onConnected;
    this.onDisconnected = onDisconnected;
    
    _shouldReconnect = true;
    
    // Check auth first
    final token = await authService.getAuthToken();
    if (authService.serverUrl == null || token == null) {
      print('❌ [RealtimeService] Cannot start: missing auth data');
      onError?.call('Missing authentication data');
      return;
    }
    
    // Get current polling interval
    final currentInterval = await storageService.getPollingInterval();
    
    // If polling is already running, check if interval changed
    if (_pollingTimer != null && _pollingTimer!.isActive) {
      // Check if interval needs to be updated
      // Note: We can't change interval of existing timer, so we'll restart if needed
      // For now, just update callbacks
      print('ℹ️ [RealtimeService] Polling already running (${currentInterval}s), updating callbacks only');
      onConnected?.call();
      return;
    }
    
    print('✅ [RealtimeService] Auth data available, starting polling...');
    
    // Skip WebSocket for now - Azure DevOps Server typically doesn't support it
    // Go directly to polling for reliability
    await _startOptimizedPolling(authService, storageService);
    onConnected?.call(); // Notify that polling started
    print('✅ [RealtimeService] Service started successfully');
  }
  
  /// Restart polling with new interval (called when settings change)
  Future<void> restartPolling(
    AuthService authService,
    StorageService storageService,
  ) async {
    print('🔄 [RealtimeService] Restarting polling with new interval...');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    await _startOptimizedPolling(authService, storageService);
  }

  /// Try to establish WebSocket connection
  Future<bool> _tryWebSocket(
    AuthService authService,
    StorageService storageService,
  ) async {
    try {
      final token = await authService.getAuthToken();
      if (authService.serverUrl == null || token == null) {
        return false;
      }

      final serverUrl = authService.serverUrl!;
      
      // Azure DevOps Server WebSocket endpoint (if available)
      // Note: This may need to be adjusted based on your server configuration
      final wsUrl = serverUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://')
          .replaceAll(RegExp(r'/$'), '');
      
      // Try different WebSocket endpoints
      final endpoints = [
        '$wsUrl/_apis/signalr/hubs',
        '$wsUrl/_apis/realtime',
        '$wsUrl/_apis/notifications',
      ];

      for (final endpoint in endpoints) {
        try {
          // Create WebSocket with authentication
          final uri = Uri.parse('$endpoint?token=$token');
          _channel = WebSocketChannel.connect(uri);
          
          // Set up listeners
          _channel!.stream.listen(
            _handleWebSocketMessage,
            onError: _handleWebSocketError,
            onDone: _handleWebSocketDone,
            cancelOnError: false,
          );
          
          // Send subscription message
          _channel!.sink.add(jsonEncode({
            'type': 'subscribe',
            'event': 'workitem.assigned',
            'userId': authService.username,
          }));
          
          _isConnected = true;
          _reconnectAttempts = 0;
          onConnected?.call();
          
          // Start heartbeat
          _startHeartbeat();
          
          return true;
        } catch (e) {
          print('WebSocket endpoint failed: $endpoint - $e');
          continue;
        }
      }
      
      return false;
    } catch (e) {
      print('WebSocket connection failed: $e');
      return false;
    }
  }

  /// Handle WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      
      if (data['type'] == 'workitem.assigned') {
        final workItemId = data['workItemId'] as int?;
        if (workItemId != null && !_knownWorkItemIds.contains(workItemId)) {
          _knownWorkItemIds.add(workItemId);
          onNewWorkItems?.call([workItemId]);
          _showNotification(workItemId, data['title'] as String? ?? 'New Work Item');
        }
      } else if (data['type'] == 'pong') {
        // Heartbeat response
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    onError?.call('WebSocket error: $error');
    _scheduleReconnect();
  }

  /// Handle WebSocket close
  void _handleWebSocketDone() {
    print('WebSocket closed');
    _isConnected = false;
    onDisconnected?.call();
    _scheduleReconnect();
  }

  /// Schedule reconnection
  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectAttempts >= maxReconnectAttempts) {
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: 5 * _reconnectAttempts); // Exponential backoff
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      // Reconnection will be handled by the calling code
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          print('Heartbeat failed: $e');
          _handleWebSocketError(e);
        }
      }
    });
  }

  Timer? _pollingTimer;
  final Map<int, int> _workItemRevisions = {}; // Track revisions to detect changes
  final Map<int, String?> _workItemAssignees = {}; // Track assignees to detect assignee changes
  final Map<int, DateTime?> _workItemChangedDates = {}; // Track changed dates for better change detection
  
  /// Optimized polling fallback - works in background
  Future<void> _startOptimizedPolling(
    AuthService authService,
    StorageService storageService,
  ) async {
    print('🔄 [RealtimeService] Starting optimized polling...');
    
    // Check auth before starting
    final token = await authService.getAuthToken();
    if (authService.serverUrl == null || token == null) {
      print('❌ [RealtimeService] Cannot start polling: missing auth data');
      onError?.call('Missing authentication data for polling');
      return;
    }
    
    print('✅ [RealtimeService] Auth data verified, initializing tracking...');
    
    // Initialize tracking with current work items (without sending notifications)
    await _initializeTracking(authService, storageService);
    
    // Get polling interval from settings
    final pollingInterval = await storageService.getPollingInterval();
    print('⏰ [RealtimeService] Setting up polling timer ($pollingInterval second intervals)...');
    
    // Start polling timer - this will continue even when app is in background
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: pollingInterval), (timer) async {
      if (!_shouldReconnect) {
        print('⚠️ [RealtimeService] Polling stopped: shouldReconnect = false');
        timer.cancel();
        return;
      }
      
      try {
        print('🔄 [RealtimeService] Polling check started at ${DateTime.now()}...');
        final hasChanges = await _checkForNewWorkItems(authService, storageService);
        if (hasChanges) {
          print('✅ [RealtimeService] Changes detected in polling check');
        } else {
          print('ℹ️ [RealtimeService] No changes in polling check');
        }
      } catch (e, stackTrace) {
        print('❌ [RealtimeService] Background polling error: $e');
        print('❌ [RealtimeService] Stack trace: $stackTrace');
        // Continue polling even if there's an error
      }
    });
    
    print('✅ [RealtimeService] Background polling started successfully ($pollingInterval second intervals)');
    
    // Do an immediate check after starting
    print('🔄 [RealtimeService] Performing immediate check...');
    try {
      await _checkForNewWorkItems(authService, storageService);
    } catch (e) {
      print('❌ [RealtimeService] Immediate check error: $e');
    }
  }

  /// Initialize tracking with current work items (without notifications)
  Future<void> _initializeTracking(
    AuthService authService,
    StorageService storageService,
  ) async {
    try {
      final token = await authService.getAuthToken();
      if (authService.serverUrl == null || token == null) {
        print('⚠️ [RealtimeService] Cannot initialize: missing auth');
        return;
      }

      final workItems = await _workItemService.getWorkItems(
        serverUrl: authService.serverUrl!,
        token: token,
        collection: storageService.getCollection(),
      );

      // Initialize tracking for all current work items (without notifications)
      for (var workItem in workItems) {
        _knownWorkItemIds.add(workItem.id);
        _workItemRevisions[workItem.id] = workItem.rev ?? 0;
        _workItemAssignees[workItem.id] = workItem.assignedTo;
        _workItemChangedDates[workItem.id] = workItem.changedDate;
      }

      print('✅ [RealtimeService] Tracking initialized for ${workItems.length} work items');
    } catch (e) {
      print('❌ [RealtimeService] Error initializing tracking: $e');
    }
  }

  /// Check for new work items and changes (optimized)
  Future<bool> _checkForNewWorkItems(
    AuthService authService,
    StorageService storageService,
  ) async {
    try {
      final token = await authService.getAuthToken();
      if (authService.serverUrl == null || token == null) {
        print('⚠️ [RealtimeService] Cannot check: missing auth');
        return false;
      }

      print('🔄 [RealtimeService] Fetching work items...');
      // Use optimized query: only get IDs and changed date
      final workItems = await _workItemService.getWorkItems(
        serverUrl: authService.serverUrl!,
        token: token,
        collection: storageService.getCollection(),
      );

      print('📊 [RealtimeService] Found ${workItems.length} work items, tracking ${_knownWorkItemIds.length}');

      final newIds = <int>[];
      final changedIds = <int>[];
      final assigneeChangedIds = <int>[];
      
      for (var workItem in workItems) {
        final currentRev = workItem.rev ?? 0;
        final knownRev = _workItemRevisions[workItem.id];
        final currentAssignee = workItem.assignedTo;
        final knownAssignee = _workItemAssignees[workItem.id];
        final currentChangedDate = workItem.changedDate;
        final knownChangedDate = _workItemChangedDates[workItem.id];
        
        if (!_knownWorkItemIds.contains(workItem.id)) {
          // New work item - just assigned to user
          print('🆕 [RealtimeService] New work item detected: #${workItem.id} - ${workItem.title}');
          newIds.add(workItem.id);
          _knownWorkItemIds.add(workItem.id);
          _workItemRevisions[workItem.id] = currentRev;
          _workItemAssignees[workItem.id] = currentAssignee;
          _workItemChangedDates[workItem.id] = currentChangedDate;
          
          // Bildirim ayarlarını kontrol et
          if (await _shouldNotifyForWorkItem(workItem, isNew: true, wasAssigned: true)) {
            await _notificationService.showWorkItemNotification(
              workItemId: workItem.id,
              title: workItem.title,
              body: 'Size yeni bir work item atandı: ${workItem.type}',
            );
          } else {
            print('🔕 [RealtimeService] Notification skipped for work item #${workItem.id} based on settings');
          }
        } else {
          // Check for changes
          bool hasChanged = false;
          bool assigneeChanged = false;
          String changeMessage = '';
          
          // Check revision change
          if (knownRev != null && currentRev > knownRev) {
            hasChanged = true;
            _workItemRevisions[workItem.id] = currentRev;
            print('📝 [RealtimeService] Work item #${workItem.id} revision changed: $knownRev -> $currentRev');
          }
          
          // Check assignee change (important!)
          if (knownAssignee != currentAssignee) {
            hasChanged = true;
            assigneeChanged = true;
            assigneeChangedIds.add(workItem.id);
            print('👤 [RealtimeService] Work item #${workItem.id} assignee changed: $knownAssignee -> $currentAssignee');
            if (currentAssignee != null && currentAssignee.isNotEmpty) {
              changeMessage = 'Work item size atandı: ${workItem.type}';
            } else {
              changeMessage = 'Work item ataması kaldırıldı';
            }
            _workItemAssignees[workItem.id] = currentAssignee;
          }
          
          // Check changed date (more reliable than revision for some changes)
          if (currentChangedDate != null && knownChangedDate != null) {
            if (currentChangedDate.isAfter(knownChangedDate)) {
              hasChanged = true;
              if (!assigneeChanged) {
                changeMessage = 'Work item güncellendi: ${workItem.state}';
              }
              _workItemChangedDates[workItem.id] = currentChangedDate;
              print('📅 [RealtimeService] Work item #${workItem.id} changed date updated');
            }
          } else if (currentChangedDate != null) {
            _workItemChangedDates[workItem.id] = currentChangedDate;
          }
          
          if (hasChanged) {
            changedIds.add(workItem.id);
            print('🔄 [RealtimeService] Work item #${workItem.id} changed, checking notification settings');
            
            // Bildirim ayarlarını kontrol et
            final wasAssigned = knownAssignee == null && currentAssignee != null;
            if (await _shouldNotifyForWorkItem(workItem, isNew: false, wasAssigned: wasAssigned)) {
              // Send notification with appropriate message
              await _notificationService.showWorkItemNotification(
                workItemId: workItem.id,
                title: workItem.title,
                body: changeMessage.isNotEmpty 
                    ? changeMessage 
                    : 'Work item güncellendi: ${workItem.state}',
              );
            } else {
              print('🔕 [RealtimeService] Notification skipped for work item #${workItem.id} based on settings');
            }
          }
          
          // Update tracking even if no change detected (to keep data fresh)
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

      // Update known IDs (remove items that are no longer assigned)
      _knownWorkItemIds = workItems.map((item) => item.id).toSet();
      
      // Remove tracking data for items no longer assigned
      _workItemRevisions.removeWhere((id, _) => !_knownWorkItemIds.contains(id));
      _workItemAssignees.removeWhere((id, _) => !_knownWorkItemIds.contains(id));
      _workItemChangedDates.removeWhere((id, _) => !_knownWorkItemIds.contains(id));

      // Always call callback if there are changes - this ensures UI updates
      if (newIds.isNotEmpty || changedIds.isNotEmpty || assigneeChangedIds.isNotEmpty) {
        final allChangedIds = <int>{...newIds, ...changedIds, ...assigneeChangedIds};
        print('✅ [RealtimeService] Detected changes: ${allChangedIds.length} work items (new: ${newIds.length}, changed: ${changedIds.length}, assignee changed: ${assigneeChangedIds.length})');
        print('📞 [RealtimeService] Calling onNewWorkItems callback with ${allChangedIds.length} items');
        onNewWorkItems?.call(allChangedIds.toList());
        return true;
      } else {
        print('ℹ️ [RealtimeService] No changes detected (tracking ${_knownWorkItemIds.length} items)');
      }

      return false;
    } catch (e, stackTrace) {
      print('❌ [RealtimeService] Check for new work items error: $e');
      print('❌ [RealtimeService] Stack trace: $stackTrace');
      onError?.call('Error checking work items: $e');
      return false;
    }
  }

  /// Show notification for new work item
  Future<void> _showNotification(int workItemId, String title) async {
    await _notificationService.showWorkItemNotification(
      workItemId: workItemId,
      title: title,
      body: 'Size yeni bir work item atandı',
    );
  }

  /// Stop real-time monitoring
  void stop() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _pollingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  /// Reset known work item IDs
  void reset() {
    _knownWorkItemIds.clear();
    _workItemRevisions.clear();
    _workItemAssignees.clear();
    _workItemChangedDates.clear();
  }
  
  /// Check if notification should be sent based on user settings
  Future<bool> _shouldNotifyForWorkItem(WorkItem workItem, {required bool isNew, required bool wasAssigned}) async {
    try {
      if (_storageService == null) {
        // If storage service not available, default to sending notification
        return true;
      }
      
      // Get notification settings
      final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
      final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
      final notifyOnHotfixOnly = _storageService!.getNotifyOnHotfixOnly();
      final notifyOnGroupAssignments = _storageService!.getNotifyOnGroupAssignments();
      final notificationGroups = await _storageService!.getNotificationGroups();
      
      // Sadece Hotfix filtresi
      if (notifyOnHotfixOnly && workItem.type.toLowerCase() != 'hotfix') {
        print('🔕 [RealtimeService] Skipping notification: Only Hotfix allowed, but type is ${workItem.type}');
        return false;
      }
      
      // İlk atamada bildirim kontrolü
      if (isNew && wasAssigned) {
        // Sadece ilk atamada bildirim gönder seçeneği aktifse ve bu ilk atama ise, bildirim gönder
        if (notifyOnFirstAssignment) {
          print('✅ [RealtimeService] Notifying: First assignment allowed and this is a new assignment');
          return true;
        } else {
          print('🔕 [RealtimeService] Skipping notification: First assignment notifications disabled');
          return false;
        }
      }
      
      // Tüm güncellemelerde bildirim kontrolü (sadece ilk atama değilse)
      if (!isNew && !wasAssigned) {
        // Tüm güncellemelerde bildirim gönder seçeneği aktifse, bildirim gönder
        if (notifyOnAllUpdates) {
          print('✅ [RealtimeService] Notifying: All updates allowed and this is an update');
          return true;
        } else {
          print('🔕 [RealtimeService] Skipping notification: All updates notifications disabled');
          return false;
        }
      }
      
      // Eğer ilk atama değil ama assignee değiştiyse, notifyOnAllUpdates kontrolü yap
      if (!isNew && wasAssigned) {
        if (notifyOnAllUpdates) {
          print('✅ [RealtimeService] Notifying: All updates allowed and assignee changed');
          return true;
        } else {
          print('🔕 [RealtimeService] Skipping notification: All updates disabled for assignee change');
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
          print('🔕 [RealtimeService] Skipping notification: Not a group assignment (groups: $notificationGroups, assignedTo: ${workItem.assignedTo})');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('⚠️ [RealtimeService] Error checking notification settings: $e');
      // On error, default to sending notification (fail-safe)
      return true;
    }
  }
}

