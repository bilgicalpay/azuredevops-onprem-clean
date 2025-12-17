/// Background Worker Servisi
/// 
/// Flutter Background Service kullanarak uygulama kapalıyken bile
/// periyodik olarak work item kontrolü yapar.
/// 
/// @author Alpay Bilgiç

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'work_item_service.dart' show WorkItemService, WorkItem;
import 'notification_service.dart';

/// Background Worker Servisi
class BackgroundWorkerService {
  static const String notificationChannelId = 'work_item_check';
  static const String notificationChannelName = 'Work Item Check';
  
  /// Initialize background service
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true, // Android 15 requires foreground service
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Azure DevOps',
        initialNotificationContent: 'Work item kontrolü aktif',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: true, // Start service on device boot
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    
    print('✅ [BackgroundWorkerService] Background service initialized');
  }
  
  /// Start background service
  static Future<void> start() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    
    if (!isRunning) {
      await service.startService();
      print('✅ [BackgroundWorkerService] Background service started');
    } else {
      print('ℹ️ [BackgroundWorkerService] Background service already running');
    }
  }
  
  /// Stop background service
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    
    if (isRunning) {
      service.invoke('stopService');
      print('✅ [BackgroundWorkerService] Background service stop requested');
    }
  }
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Android/iOS foreground handler
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  print('🚀 [BackgroundWorker] Service onStart called');
  
  if (service is AndroidServiceInstance) {
    // Set as foreground service immediately (required for Android 15)
    service.setAsForegroundService();
    print('✅ [BackgroundWorker] Set as foreground service');
    
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    
    service.on('setAsBackground').listen((event) {
      // Don't set as background on Android 15 - keep as foreground
      print('⚠️ [BackgroundWorker] Background mode requested but keeping foreground for Android 15');
    });
  }
  
  service.on('stopService').listen((event) {
    print('🛑 [BackgroundWorker] Stop service requested');
    service.stopSelf();
  });
  
  // Get polling interval from settings
  final prefs = await SharedPreferences.getInstance();
  final pollingIntervalSeconds = prefs.getInt('polling_interval_seconds') ?? 15;
  final clampedInterval = pollingIntervalSeconds.clamp(5, 300);
  
  print('⏰ [BackgroundWorker] Polling interval: ${clampedInterval} seconds');
  
  // Update foreground notification immediately
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Azure DevOps',
      content: 'Work item kontrolü aktif',
    );
  }
  
  // Start periodic checks
  Timer.periodic(Duration(seconds: clampedInterval), (timer) async {
    try {
      if (service is AndroidServiceInstance) {
        final now = DateTime.now();
        service.setForegroundNotificationInfo(
          title: 'Azure DevOps',
          content: 'Son kontrol: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
        );
      }
      
      print('🔄 [BackgroundWorker] Periodic check started at ${DateTime.now()}...');
      await _checkForWorkItems(service);
    } catch (e) {
      print('❌ [BackgroundWorker] Error in periodic check: $e');
    }
  });
  
  // Do immediate check
  print('🔄 [BackgroundWorker] Performing immediate check...');
  await _checkForWorkItems(service);
  
  print('✅ [BackgroundWorker] Service started successfully with ${clampedInterval}s interval');
}

/// Check for work item changes
Future<void> _checkForWorkItems(ServiceInstance service) async {
  try {
    print('🔄 [BackgroundWorker] Checking for work item changes...');
    
    // Get auth data from storage
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url');
    final collection = prefs.getString('collection');
    
    // Use FlutterSecureStorage with proper Android options for background service
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        sharedPreferencesName: 'FlutterSecureStorage',
        preferencesKeyPrefix: 'flutter_secure_storage_',
      ),
    );
    
    String? token;
    try {
      token = await secureStorage.read(key: 'auth_token');
      print('🔑 [BackgroundWorker] Token read: ${token != null ? "✓ (${token.length} chars)" : "✗"}');
    } catch (e) {
      print('❌ [BackgroundWorker] Error reading token: $e');
      token = null;
    }
    
    if (serverUrl == null || token == null) {
      print('❌ [BackgroundWorker] No auth data available - serverUrl: ${serverUrl != null ? "✓" : "✗"}, token: ${token != null ? "✓" : "✗"}');
      // Update notification to show the issue
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Azure DevOps',
          content: 'Auth data eksik - uygulamayı açın',
        );
      }
      return;
    }
    
    print('✅ [BackgroundWorker] Auth data available - serverUrl: ✓, token: ✓');

    // Don't initialize notification service here - it needs app context
    // NotificationService should be initialized in main() before background service starts
    
    // Get work items
    final workItemService = WorkItemService();
    final workItems = await workItemService.getWorkItems(
      serverUrl: serverUrl,
      token: token,
      collection: collection,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        print('⏱️ [BackgroundWorker] Request timeout');
        return <WorkItem>[];
      },
    );

    // Load tracking data from SharedPreferences (persistent storage)
    final knownWorkItemIdsStr = prefs.getStringList('bg_known_work_item_ids') ?? [];
    final knownWorkItemIds = knownWorkItemIdsStr.map((e) => int.tryParse(e)).whereType<int>().toSet();
    final workItemRevisions = <int, int>{};
    final workItemAssignees = <int, String?>{};
    final workItemChangedDates = <int, DateTime?>{};
    
    // Load revision data from persistent storage
    for (final id in knownWorkItemIds) {
      final rev = prefs.getInt('bg_work_item_rev_$id');
      if (rev != null) workItemRevisions[id] = rev;
      
      final assignee = prefs.getString('bg_work_item_assignee_$id');
      workItemAssignees[id] = assignee;
      
      final changedDateStr = prefs.getString('bg_work_item_changed_date_$id');
      if (changedDateStr != null) {
        workItemChangedDates[id] = DateTime.tryParse(changedDateStr);
      }
      
      // Load last notified revision
      final lastNotifiedRev = prefs.getInt('bg_notified_rev_$id');
      if (lastNotifiedRev != null && lastNotifiedRev >= (workItemRevisions[id] ?? 0)) {
        // Already notified for this revision
      }
    }

    final notificationService = NotificationService();
    bool hasChanges = false;

    for (var workItem in workItems) {
      final currentRev = workItem.rev ?? 0;
      final knownRev = workItemRevisions[workItem.id];
      final currentAssignee = workItem.assignedTo;
      final knownAssignee = workItemAssignees[workItem.id];
      final currentChangedDate = workItem.changedDate;
      final knownChangedDate = workItemChangedDates[workItem.id];
      
      if (!knownWorkItemIds.contains(workItem.id)) {
        // New work item
        print('🆕 [BackgroundWorker] New work item detected: #${workItem.id}');
        hasChanges = true;
        
        await notificationService.showWorkItemNotification(
          workItemId: workItem.id,
          title: workItem.title,
          body: 'Size yeni bir work item atandı: ${workItem.type}',
        );
        
        // Update tracking and save to persistent storage immediately
        knownWorkItemIds.add(workItem.id);
        workItemRevisions[workItem.id] = currentRev;
        workItemAssignees[workItem.id] = currentAssignee;
        if (currentChangedDate != null) {
          workItemChangedDates[workItem.id] = currentChangedDate;
        }
        
        // Save to SharedPreferences immediately
        await prefs.setInt('bg_work_item_rev_${workItem.id}', currentRev);
        if (currentAssignee != null) {
          await prefs.setString('bg_work_item_assignee_${workItem.id}', currentAssignee);
        }
        if (currentChangedDate != null) {
          await prefs.setString('bg_work_item_changed_date_${workItem.id}', currentChangedDate.toIso8601String());
        }
        await prefs.setInt('bg_notified_rev_${workItem.id}', currentRev);
      } else {
        // Check for changes
        bool shouldNotify = false;
        String notificationBody = '';
        
        // Check assignee change
        if (knownAssignee != currentAssignee) {
          shouldNotify = true;
          if (currentAssignee != null && currentAssignee.isNotEmpty) {
            notificationBody = 'Work item size atandı: ${workItem.type}';
          } else {
            notificationBody = 'Work item ataması kaldırıldı';
          }
          workItemAssignees[workItem.id] = currentAssignee;
          print('👤 [BackgroundWorker] Work item #${workItem.id} assignee changed');
        }
        
        // Check revision change
        if (knownRev != null && currentRev > knownRev) {
          shouldNotify = true;
          if (notificationBody.isEmpty) {
            notificationBody = 'Work item güncellendi: ${workItem.state}';
          }
          workItemRevisions[workItem.id] = currentRev;
          print('📝 [BackgroundWorker] Work item #${workItem.id} revision changed');
        }
        
        // Check changed date
        if (currentChangedDate != null && knownChangedDate != null) {
          if (currentChangedDate.isAfter(knownChangedDate)) {
            shouldNotify = true;
            if (notificationBody.isEmpty) {
              notificationBody = 'Work item güncellendi: ${workItem.state}';
            }
            workItemChangedDates[workItem.id] = currentChangedDate;
          }
        } else if (currentChangedDate != null) {
          workItemChangedDates[workItem.id] = currentChangedDate;
        }
        
        if (shouldNotify) {
          print('✅ [BackgroundWorker] Sending notification for work item #${workItem.id}');
          hasChanges = true;
          await notificationService.showWorkItemNotification(
            workItemId: workItem.id,
            title: workItem.title,
            body: notificationBody,
          );
          
          // Save notified revision to prevent duplicate notifications
          await prefs.setInt('bg_notified_rev_${workItem.id}', currentRev);
        }
        
        // Update tracking and save to persistent storage
        workItemRevisions[workItem.id] = currentRev;
        workItemAssignees[workItem.id] = currentAssignee;
        if (currentChangedDate != null) {
          workItemChangedDates[workItem.id] = currentChangedDate;
        }
        
        // Save to SharedPreferences
        await prefs.setInt('bg_work_item_rev_${workItem.id}', currentRev);
        if (currentAssignee != null) {
          await prefs.setString('bg_work_item_assignee_${workItem.id}', currentAssignee);
        } else {
          await prefs.remove('bg_work_item_assignee_${workItem.id}');
        }
        if (currentChangedDate != null) {
          await prefs.setString('bg_work_item_changed_date_${workItem.id}', currentChangedDate.toIso8601String());
        } else {
          await prefs.remove('bg_work_item_changed_date_${workItem.id}');
        }
      }
    }

    // Save tracking data to persistent storage (with bg_ prefix)
    final updatedKnownWorkItemIds = workItems.map((item) => item.id).toSet();
    await prefs.setStringList('bg_known_work_item_ids', updatedKnownWorkItemIds.map((e) => e.toString()).toList());
    
    for (final workItem in workItems) {
      await prefs.setInt('bg_work_item_rev_${workItem.id}', workItem.rev ?? 0);
      if (workItem.assignedTo != null) {
        await prefs.setString('bg_work_item_assignee_${workItem.id}', workItem.assignedTo!);
      } else {
        await prefs.remove('bg_work_item_assignee_${workItem.id}');
      }
      if (workItem.changedDate != null) {
        await prefs.setString('bg_work_item_changed_date_${workItem.id}', workItem.changedDate!.toIso8601String());
      } else {
        await prefs.remove('bg_work_item_changed_date_${workItem.id}');
      }
    }

    // Remove tracking for items no longer assigned
    final oldIds = knownWorkItemIds.difference(updatedKnownWorkItemIds);
    for (final id in oldIds) {
      await prefs.remove('bg_work_item_rev_$id');
      await prefs.remove('bg_work_item_assignee_$id');
      await prefs.remove('bg_work_item_changed_date_$id');
      await prefs.remove('bg_notified_rev_$id');
    }
    
    print('💾 [BackgroundWorker] Saved tracking data to persistent storage (${updatedKnownWorkItemIds.length} items)');

    if (hasChanges) {
      print('✅ [BackgroundWorker] Changes detected and notifications sent');
    } else {
      print('ℹ️ [BackgroundWorker] No changes detected');
    }
  } catch (e, stackTrace) {
    print('❌ [BackgroundWorker] Error checking work items: $e');
    print('❌ [BackgroundWorker] Stack trace: $stackTrace');
  }
}

