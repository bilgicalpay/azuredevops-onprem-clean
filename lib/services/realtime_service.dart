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
import 'package:shared_preferences/shared_preferences.dart';
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
  Set<int> _notifiedWorkItemIds = {}; // Track which work items we've already notified about
  
  // SharedPreferences key for persistent notified work item IDs
  static const String _notifiedIdsKey = 'notified_work_item_ids';
  static const String _firstAssignmentNotifiedIdsKey = 'first_assignment_notified_work_item_ids';
  
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
  
  /// Load notified work item IDs from persistent storage
  Future<void> _loadNotifiedWorkItemIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsJson = prefs.getString(_notifiedIdsKey);
      if (idsJson != null && idsJson.isNotEmpty) {
        final List<dynamic> ids = jsonDecode(idsJson);
        _notifiedWorkItemIds = ids.map((e) => e as int).toSet();
        print('📂 [RealtimeService] Loaded ${_notifiedWorkItemIds.length} notified work item IDs from storage');
      }
    } catch (e) {
      print('⚠️ [RealtimeService] Error loading notified work item IDs: $e');
    }
  }
  
  /// Save notified work item IDs to persistent storage
  Future<void> _saveNotifiedWorkItemIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notifiedIdsKey, jsonEncode(_notifiedWorkItemIds.toList()));
      print('💾 [RealtimeService] Saved ${_notifiedWorkItemIds.length} notified work item IDs to storage');
    } catch (e) {
      print('⚠️ [RealtimeService] Error saving notified work item IDs: $e');
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
      print('🔒 [RealtimeService] Work item #$workItemId marked as first-assignment-notified (permanent)');
    } catch (e) {
      print('⚠️ [RealtimeService] Error marking first-assignment-notified: $e');
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
      print('⚠️ [RealtimeService] Error checking first-assignment-notified: $e');
      return false;
    }
  }
  
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
      // ÖNCE: Kalıcı olarak saklanan bildirim gönderilmiş ID'leri yükle
      await _loadNotifiedWorkItemIds();
      
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
        
        // Eğer bu work item daha önce bildirim gönderilmişse (kalıcı listede varsa)
        // tekrar bildirim gönderme
        if (_wasNotified(workItem.id)) {
          // Son bildirim gönderilen revision'ı kontrol et
          final lastNotifiedRev = await _getLastNotifiedRevision(workItem.id);
          if (lastNotifiedRev != null && lastNotifiedRev >= (workItem.rev ?? 0)) {
            // Bu work item için zaten bildirim gönderilmiş ve değişiklik yok
            print('📌 [RealtimeService] Work item #${workItem.id} already notified (rev: $lastNotifiedRev)');
          }
        }
      }

      print('✅ [RealtimeService] Tracking initialized for ${workItems.length} work items (${_notifiedWorkItemIds.length} already notified in storage)');
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
          _knownWorkItemIds.add(workItem.id);
          _workItemRevisions[workItem.id] = currentRev;
          _workItemAssignees[workItem.id] = currentAssignee;
          _workItemChangedDates[workItem.id] = currentChangedDate;
          
          // TATİL MODU KONTROLÜ - En önce kontrol et, eğer tatil modu aktifse hiçbir bildirim gönderme
          final vacationModePhone = _storageService!.getVacationModePhone();
          final vacationModeWatch = _storageService!.getVacationModeWatch();
          if (vacationModePhone && vacationModeWatch) {
            print('🏖️ [RealtimeService] Skipping all notifications: Vacation mode enabled for both phone and watch');
            continue;
          }
          
          // ÖNEMLİ: Eğer bu work item "ilk atamada bildirim" ile işaretlenmişse ve sadece "ilk atamada bildirim" aktifse,
          // bir daha asla bildirim gönderme
          if (await _isFirstAssignmentNotified(workItem.id)) {
            final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
            final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
            
            if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
              print('🔒 [RealtimeService] Work item #${workItem.id} was first-assignment-notified, skipping all future notifications');
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
              print('📌 [RealtimeService] Work item #${workItem.id} already notified previously (rev: $lastNotifiedRev), skipping');
              continue; // Bildirim gönderme, sonraki work item'a geç
            }
          }
          
          // Bildirim ayarlarını kontrol et (tatil modu kontrolü _shouldNotifyForWorkItem içinde yapılıyor)
          final shouldNotify = await _shouldNotifyForWorkItem(workItem, isNew: true, wasAssigned: true);
          if (!shouldNotify) {
            print('🔕 [RealtimeService] Notification skipped for work item #${workItem.id} based on settings');
            continue;
          }
          
          // Yeni work item veya değişiklik var - bildirim gönder
          print('🆕 [RealtimeService] New work item detected: #${workItem.id} - ${workItem.title}');
          newIds.add(workItem.id);
          
          // Nöbetçi modu kontrolü
          final isOnCallModePhone = _storageService!.getOnCallModePhone();
          final isOnCallModeWatch = _storageService!.getOnCallModeWatch();
          
          // Telefon bildirimi
          final shouldNotifyPhone = await _shouldNotifyForWorkItem(workItem, isNew: true, wasAssigned: true, forPhone: true, forWatch: false);
          if (shouldNotifyPhone) {
            if (isOnCallModePhone) {
              await _notificationService.showOnCallNotification(
                title: 'Work Item #${workItem.id}: ${workItem.title}',
                body: 'Size yeni bir work item atandı: ${workItem.type}',
                payload: workItem.id.toString(),
              );
            } else {
              await _notificationService.showWorkItemNotification(
                workItemId: workItem.id,
                title: workItem.title,
                body: 'Size yeni bir work item atandı: ${workItem.type}',
                isFirstAssignment: true,
                isOnCallMode: false,
                availableStates: null,
                currentState: workItem.state,
                storageService: _storageService,
                workItemService: _workItemService,
              );
            }
          }
          
          // Akıllı saat bildirimi (sadece ilk atamada)
          final shouldNotifyWatch = await _shouldNotifyForWorkItem(workItem, isNew: true, wasAssigned: true, forPhone: false, forWatch: true);
          if (shouldNotifyWatch && _storageService!.getEnableSmartwatchNotifications()) {
            if (isOnCallModeWatch) {
              await _notificationService.showOnCallNotification(
                title: 'Work Item #${workItem.id}: ${workItem.title}',
                body: 'Size yeni bir work item atandı: ${workItem.type}',
                payload: workItem.id.toString(),
              );
            } else {
              await _notificationService.showWorkItemNotification(
                workItemId: workItem.id,
                title: workItem.title,
                body: 'Size yeni bir work item atandı: ${workItem.type}',
                isFirstAssignment: true,
                isOnCallMode: false,
                availableStates: null,
                currentState: workItem.state,
                storageService: _storageService,
                workItemService: _workItemService,
              );
            }
          }
          
          // ÖNEMLİ: Eğer sadece "ilk atamada bildirim" aktifse (ve "tüm güncellemelerde bildirim" aktif değilse),
          // bu work item için bir daha ASLA bildirim gönderme (uygulama kaldırılıp tekrar kurulsa bile)
          final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
          final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
          
          if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
            // Sadece ilk atamada bildirim aktifse, bu work item'ı "first_assignment_notified" olarak işaretle
            // Bu sayede bir daha asla bildirim gönderilmeyecek
            await _markAsFirstAssignmentNotified(workItem.id);
            print('🔒 [RealtimeService] Work item #${workItem.id} marked as first-assignment-notified (no more notifications)');
          }
          
          await _markAsNotified(workItem.id); // Kalıcı olarak kaydet
          await _saveLastNotifiedRevision(workItem.id, currentRev);
          print('✅ [RealtimeService] Notification sent for work item #${workItem.id}');
        } else {
          // ÖNEMLİ: ÖNCE kontrol et - eğer bu work item "ilk atamada bildirim" ile işaretlenmişse ve sadece "ilk atamada bildirim" aktifse,
          // bir daha asla bildirim gönderme (değişiklik olsa bile)
          // Bu kontrolü değişiklik tespitinden ÖNCE yapıyoruz
          final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
          final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
          
          if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
            if (await _isFirstAssignmentNotified(workItem.id)) {
              print('🔒 [RealtimeService] Work item #${workItem.id} was first-assignment-notified, skipping all future notifications (including updates)');
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
              continue; // Bu work item için hiçbir bildirim gönderme
            }
          }
          
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
            
            // ÖNEMLİ: Bu work item için daha önce bildirim gönderilmiş mi kontrol et
            final lastNotifiedRev = await _getLastNotifiedRevision(workItem.id);
            if (lastNotifiedRev != null && lastNotifiedRev >= currentRev) {
              // Bu work item için zaten bildirim gönderilmiş ve değişiklik yok
              print('📌 [RealtimeService] Work item #${workItem.id} already notified for this revision (rev: $lastNotifiedRev), skipping');
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
            
            changedIds.add(workItem.id);
            print('🔄 [RealtimeService] Work item #${workItem.id} changed, checking notification settings');
            
            // TATİL MODU KONTROLÜ - En önce kontrol et, eğer tatil modu aktifse hiçbir bildirim gönderme
            final vacationModePhone = _storageService!.getVacationModePhone();
            final vacationModeWatch = _storageService!.getVacationModeWatch();
            if (vacationModePhone && vacationModeWatch) {
              print('🏖️ [RealtimeService] Skipping all notifications: Vacation mode enabled for both phone and watch');
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
            
            // Bildirim ayarlarını kontrol et
            final wasAssigned = knownAssignee == null && currentAssignee != null;
            final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
            final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
            
            // ÇİFT KONTROL: Eğer sadece "ilk atamada bildirim" aktifse, güncellemelerde bildirim gönderme
            if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
              print('🔒 [RealtimeService] Work item #${workItem.id} - First assignment only mode active, blocking update notification');
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
              print('🔕 [RealtimeService] Notification skipped for work item #${workItem.id} based on settings');
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
            
            // Send notification with appropriate message
            // Telefon ve saat için ayrı ayrı kontrol et (tatil modu kontrolü _shouldNotifyForWorkItem içinde yapılıyor)
            final isOnCallModePhone = _storageService!.getOnCallModePhone();
            final shouldNotifyPhone = await _shouldNotifyForWorkItem(workItem, isNew: false, wasAssigned: wasAssigned, forPhone: true, forWatch: false);
            final shouldNotifyWatch = await _shouldNotifyForWorkItem(workItem, isNew: false, wasAssigned: wasAssigned, forPhone: false, forWatch: true);
            
            if (shouldNotifyPhone) {
              if (isOnCallModePhone) {
                await _notificationService.showOnCallNotification(
                  title: 'Work Item #${workItem.id}: ${workItem.title}',
                  body: changeMessage.isNotEmpty 
                      ? changeMessage 
                      : 'Work item güncellendi: ${workItem.state}',
                  payload: workItem.id.toString(),
                );
              } else {
                await _notificationService.showWorkItemNotification(
                  workItemId: workItem.id,
                  title: workItem.title,
                  body: changeMessage.isNotEmpty 
                      ? changeMessage 
                      : 'Work item güncellendi: ${workItem.state}',
                  isFirstAssignment: false,
                  isOnCallMode: false,
                  availableStates: null,
                  currentState: workItem.state,
                  storageService: _storageService,
                  workItemService: _workItemService,
                );
              }
            }
            
            if (shouldNotifyWatch && _storageService!.getEnableSmartwatchNotifications()) {
              final isOnCallModeWatch = _storageService!.getOnCallModeWatch();
              if (isOnCallModeWatch) {
                await _notificationService.showOnCallNotification(
                  title: 'Work Item #${workItem.id}: ${workItem.title}',
                  body: changeMessage.isNotEmpty 
                      ? changeMessage 
                      : 'Work item güncellendi: ${workItem.state}',
                  payload: workItem.id.toString(),
                );
              } else {
                await _notificationService.showWorkItemNotification(
                  workItemId: workItem.id,
                  title: workItem.title,
                  body: changeMessage.isNotEmpty 
                      ? changeMessage 
                      : 'Work item güncellendi: ${workItem.state}',
                  isFirstAssignment: false,
                  isOnCallMode: false,
                  availableStates: null,
                  currentState: workItem.state,
                  storageService: _storageService,
                  workItemService: _workItemService,
                );
              }
            }
            
            // Sadece bildirim gönderildiyse tracking güncelle
            if (shouldNotifyPhone || shouldNotifyWatch) {
              await _saveLastNotifiedRevision(workItem.id, currentRev);
              await _markAsNotified(workItem.id); // Kalıcı olarak kaydet
              print('✅ [RealtimeService] Notification sent for work item #${workItem.id}: $changeMessage');
            } else {
              print('🔕 [RealtimeService] No notification sent for work item #${workItem.id} (vacation mode or other settings)');
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
    _notifiedWorkItemIds.clear();
  }
  
  /// Check if notification should be sent based on user settings
  Future<bool> _shouldNotifyForWorkItem(WorkItem workItem, {required bool isNew, required bool wasAssigned, bool forPhone = true, bool forWatch = false}) async {
    try {
      if (_storageService == null) {
        // If storage service not available, default to NOT sending notification (safer)
        print('🔕 [RealtimeService] Storage service not available, skipping notification');
        return false;
      }
      
      // Tatil modu kontrolü
      if (forPhone && _storageService!.getVacationModePhone()) {
        print('🏖️ [RealtimeService] Skipping notification: Vacation mode enabled for phone');
        return false;
      }
      if (forWatch && _storageService!.getVacationModeWatch()) {
        print('🏖️ [RealtimeService] Skipping notification: Vacation mode enabled for watch');
        return false;
      }
      
      // Get notification settings
      final notifyOnFirstAssignment = _storageService!.getNotifyOnFirstAssignment();
      final notifyOnAllUpdates = _storageService!.getNotifyOnAllUpdates();
      final notifyOnHotfixOnly = _storageService!.getNotifyOnHotfixOnly();
      final notifyOnGroupAssignments = _storageService!.getNotifyOnGroupAssignments();
      final notificationGroups = await _storageService!.getNotificationGroups();
      
      // DEBUG: Log all notification settings
      print('🔍 [RealtimeService] Notification settings: notifyOnFirstAssignment=$notifyOnFirstAssignment, notifyOnAllUpdates=$notifyOnAllUpdates, notifyOnHotfixOnly=$notifyOnHotfixOnly, notifyOnGroupAssignments=$notifyOnGroupAssignments, groups=${notificationGroups.length}');
      
      // ÖNEMLİ: Eğer hiçbir bildirim ayarı aktif değilse, bildirim gönderme
      if (!notifyOnFirstAssignment && !notifyOnAllUpdates && !notifyOnHotfixOnly && !notifyOnGroupAssignments) {
        print('🔕 [RealtimeService] Skipping notification: No notification settings enabled (all disabled)');
        return false;
      }
      
      // Akıllı saat için: Sadece ilk atamada bildirim gönder
      if (forWatch && !isNew) {
        print('⌚ [RealtimeService] Skipping watch notification: Only first assignment allowed for smartwatch');
        return false;
      }
      
      // ÖNEMLİ: Eğer sadece "ilk atamada bildirim" aktifse (ve "tüm güncellemelerde bildirim" aktif değilse),
      // ve bu work item daha önce "first_assignment_notified" olarak işaretlenmişse,
      // bir daha asla bildirim gönderme
      if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
        if (await _isFirstAssignmentNotified(workItem.id)) {
          print('🔒 [RealtimeService] Skipping notification: First assignment only mode and work item #${workItem.id} was already notified');
          return false;
        }
      }
      
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
        // Eğer sadece "ilk atamada bildirim" aktifse, güncellemelerde bildirim gönderme
        if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
          print('🔕 [RealtimeService] Skipping notification: First assignment only mode, no updates allowed');
          return false;
        }
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
        // Eğer sadece "ilk atamada bildirim" aktifse, assignee değişikliklerinde de bildirim gönderme
        if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
          print('🔕 [RealtimeService] Skipping notification: First assignment only mode, no updates allowed for assignee change');
          return false;
        }
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
      
      // Eğer sadece "ilk atamada bildirim" aktifse ve bu bir güncelleme ise, bildirim gönderme
      if (notifyOnFirstAssignment && !notifyOnAllUpdates && !isNew) {
        print('🔕 [RealtimeService] Skipping notification: First assignment only mode, this is an update (isNew=$isNew, wasAssigned=$wasAssigned)');
        return false;
      }
      
      // Eğer hiçbir koşul eşleşmediyse ve sadece "ilk atamada bildirim" aktifse, bildirim gönderme
      if (notifyOnFirstAssignment && !notifyOnAllUpdates) {
        print('🔕 [RealtimeService] Skipping notification: First assignment only mode, no matching condition (isNew=$isNew, wasAssigned=$wasAssigned)');
        return false;
      }
      
      // Eğer hiçbir bildirim ayarı aktif değilse, bildirim gönderme (zaten yukarıda kontrol edildi ama tekrar kontrol)
      if (!notifyOnFirstAssignment && !notifyOnAllUpdates) {
        print('🔕 [RealtimeService] Skipping notification: No notification settings enabled (notifyOnFirstAssignment=$notifyOnFirstAssignment, notifyOnAllUpdates=$notifyOnAllUpdates)');
        return false;
      }
      
      // Default: bildirim gönderme (sadece yukarıdaki kontrollerden geçtiyse ve bir ayar aktifse)
      // Eğer buraya geldiysek, bir ayar aktif demektir, ama yine de false döndürelim çünkü
      // yukarıdaki koşullar zaten tüm durumları kapsıyor
      print('🔕 [RealtimeService] Skipping notification: No matching condition (isNew=$isNew, wasAssigned=$wasAssigned, notifyOnFirstAssignment=$notifyOnFirstAssignment, notifyOnAllUpdates=$notifyOnAllUpdates)');
      return false;
    } catch (e) {
      print('⚠️ [RealtimeService] Error checking notification settings: $e');
      // On error, default to sending notification (fail-safe)
      return true;
    }
  }
}

