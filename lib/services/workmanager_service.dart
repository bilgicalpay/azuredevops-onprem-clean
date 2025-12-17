/// WorkManager servisi
/// 
/// Android WorkManager kullanarak uygulama kapalıyken bile
/// periyodik olarak work item kontrolü yapar.
/// 
/// @author Alpay Bilgiç

import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'work_item_service.dart' show WorkItemService, WorkItem;
import 'notification_service.dart';

/// WorkManager callback function
/// Bu fonksiyon WorkManager tarafından periyodik olarak çağrılır
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 [WorkManager] Background task started: $task');
    
    try {
      // Get auth data from storage
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('server_url');
      final collection = prefs.getString('collection');
      
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');
      
      if (serverUrl == null || token == null) {
        print('❌ [WorkManager] No auth data available');
        return Future.value(false);
      }

      // Get polling interval
      final pollingInterval = prefs.getInt('polling_interval_seconds') ?? 15;
      
      print('🔄 [WorkManager] Checking for work item changes...');
      
      // Initialize notification service
      await NotificationService().init();
      
      // Get work items
      final workItemService = WorkItemService();
      final workItems = await workItemService.getWorkItems(
        serverUrl: serverUrl,
        token: token,
        collection: collection,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ [WorkManager] Request timeout');
          return <WorkItem>[];
        },
      );

      // Load tracking data
      final knownWorkItemIds = prefs.getStringList('known_work_item_ids')?.map((e) => int.parse(e)).toSet() ?? <int>{};
      final workItemRevisions = <int, int>{};
      final workItemAssignees = <int, String?>{};
      final workItemChangedDates = <int, DateTime?>{};
      
      // Load revision data
      for (final id in knownWorkItemIds) {
        final rev = prefs.getInt('work_item_rev_$id');
        if (rev != null) workItemRevisions[id] = rev;
        
        final assignee = prefs.getString('work_item_assignee_$id');
        workItemAssignees[id] = assignee;
        
        final changedDateStr = prefs.getString('work_item_changed_date_$id');
        if (changedDateStr != null) {
          workItemChangedDates[id] = DateTime.tryParse(changedDateStr);
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
          print('🆕 [WorkManager] New work item detected: #${workItem.id}');
          hasChanges = true;
          
          await notificationService.showWorkItemNotification(
            workItemId: workItem.id,
            title: workItem.title,
            body: 'Size yeni bir work item atandı: ${workItem.type}',
          );
          
          // Update tracking
          knownWorkItemIds.add(workItem.id);
          workItemRevisions[workItem.id] = currentRev;
          workItemAssignees[workItem.id] = currentAssignee;
          if (currentChangedDate != null) {
            workItemChangedDates[workItem.id] = currentChangedDate;
          }
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
            print('👤 [WorkManager] Work item #${workItem.id} assignee changed');
          }
          
          // Check revision change
          if (knownRev != null && currentRev > knownRev) {
            shouldNotify = true;
            if (notificationBody.isEmpty) {
              notificationBody = 'Work item güncellendi: ${workItem.state}';
            }
            workItemRevisions[workItem.id] = currentRev;
            print('📝 [WorkManager] Work item #${workItem.id} revision changed');
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
            print('✅ [WorkManager] Sending notification for work item #${workItem.id}');
            hasChanges = true;
            await notificationService.showWorkItemNotification(
              workItemId: workItem.id,
              title: workItem.title,
              body: notificationBody,
            );
          }
          
          // Update tracking
          workItemRevisions[workItem.id] = currentRev;
          workItemAssignees[workItem.id] = currentAssignee;
          if (currentChangedDate != null) {
            workItemChangedDates[workItem.id] = currentChangedDate;
          }
        }
      }

      // Save tracking data
      await prefs.setStringList('known_work_item_ids', knownWorkItemIds.map((e) => e.toString()).toList());
      for (final entry in workItemRevisions.entries) {
        await prefs.setInt('work_item_rev_${entry.key}', entry.value);
      }
      for (final entry in workItemAssignees.entries) {
        if (entry.value != null) {
          await prefs.setString('work_item_assignee_${entry.key}', entry.value!);
        } else {
          await prefs.remove('work_item_assignee_${entry.key}');
        }
      }
      for (final entry in workItemChangedDates.entries) {
        if (entry.value != null) {
          await prefs.setString('work_item_changed_date_${entry.key}', entry.value!.toIso8601String());
        } else {
          await prefs.remove('work_item_changed_date_${entry.key}');
        }
      }

      // Remove tracking for items no longer assigned
      final currentIds = workItems.map((item) => item.id).toSet();
      for (final id in knownWorkItemIds) {
        if (!currentIds.contains(id)) {
          await prefs.remove('work_item_rev_$id');
          await prefs.remove('work_item_assignee_$id');
          await prefs.remove('work_item_changed_date_$id');
        }
      }

      if (hasChanges) {
        print('✅ [WorkManager] Changes detected and notifications sent');
      } else {
        print('ℹ️ [WorkManager] No changes detected');
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      print('❌ [WorkManager] Error in background task: $e');
      print('❌ [WorkManager] Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}

/// WorkManager servisi
class WorkManagerService {
  static const String taskName = 'workItemCheckTask';
  
  /// Initialize WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    print('✅ [WorkManagerService] WorkManager initialized');
  }
  
  /// Register periodic task
  static Future<void> registerPeriodicTask() async {
    try {
      // Get polling interval from settings
      final prefs = await SharedPreferences.getInstance();
      final pollingIntervalSeconds = prefs.getInt('polling_interval_seconds') ?? 15;
      
      // WorkManager minimum interval is 15 minutes for periodic tasks
      // We'll use 15 minutes as minimum, but try to respect user preference
      // For user intervals less than 15 minutes, we use 15 minutes
      // For user intervals >= 15 minutes, we use that value
      final workManagerIntervalMinutes = pollingIntervalSeconds < 900 
          ? 15  // Minimum 15 minutes
          : (pollingIntervalSeconds / 60).ceil(); // Convert seconds to minutes
      
      await Workmanager().registerPeriodicTask(
        taskName,
        taskName,
        frequency: Duration(minutes: workManagerIntervalMinutes),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        initialDelay: Duration(minutes: workManagerIntervalMinutes),
      );
      
      print('✅ [WorkManagerService] Periodic task registered (${workManagerIntervalMinutes} minutes, user setting: ${pollingIntervalSeconds}s)');
      print('ℹ️ [WorkManagerService] Note: WorkManager minimum interval is 15 minutes when app is closed');
    } catch (e) {
      print('❌ [WorkManagerService] Error registering periodic task: $e');
    }
  }
  
  /// Cancel periodic task
  static Future<void> cancelTask() async {
    try {
      await Workmanager().cancelByUniqueName(taskName);
      print('✅ [WorkManagerService] Periodic task cancelled');
    } catch (e) {
      print('❌ [WorkManagerService] Error cancelling task: $e');
    }
  }
}

