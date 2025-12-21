/// Bildirim servisi
/// 
/// Yerel push notification'ları yönetir.
/// Work item atamaları ve güncellemeleri için bildirim gönderir.
/// 
/// Akıllı saat desteği:
/// - Android Wear OS: Bildirimler otomatik olarak eşleşen Wear OS cihazlara gönderilir
/// - iOS watchOS: Bildirimler otomatik olarak eşleşen Apple Watch cihazlara gönderilir
/// 
/// @author Alpay Bilgiç
library;

import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'storage_service.dart';
import 'work_item_service.dart';

/// Bildirim servisi sınıfı
/// Flutter Local Notifications kullanarak bildirim gönderir
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  // State değiştirme callback'i (work item ID -> yeni state)
  Function(int workItemId, String newState)? onStateChangeRequested;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Initialize iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == false) {
        print('Failed to initialize notifications');
        return;
      }

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Create notification channel for work items
        const workItemsChannel = AndroidNotificationChannel(
          'work_items',
          'Work Items',
          description: 'Notifications for Azure DevOps work items',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );
        await androidPlugin.createNotificationChannel(workItemsChannel);
        
        // Create notification channel for foreground service (Android 15+)
        const foregroundChannel = AndroidNotificationChannel(
          'work_item_check',
          'Work Item Check',
          description: 'Background service for checking work item updates',
          importance: Importance.low, // Low importance for foreground service
          enableVibration: false,
          playSound: false,
        );
        await androidPlugin.createNotificationChannel(foregroundChannel);
        
        // Request permissions (Android 13+)
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted != null) {
          print('Notification permission granted: $granted');
        }
      }

      _initialized = true;
      print('Notification service initialized');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  /// Bildirim tıklama olayını işler
  /// Şu anda sadece log kaydı tutar, gelecekte work item detay sayfasına yönlendirme eklenebilir
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Not: Work item detay sayfasına yönlendirme için navigator context gereklidir
    // Bu özellik ana uygulama akışında yönetilmelidir
    
    // Eğer etkileşimli buton tıklandıysa (state değiştirme)
    if (response.actionId != null && response.actionId!.startsWith('state_')) {
      final workItemId = int.tryParse(response.payload ?? '');
      final newState = response.actionId!.replaceFirst('state_', '');
      if (workItemId != null && newState.isNotEmpty) {
        print('🔄 State change requested: Work Item #$workItemId -> $newState');
        // State değiştirme callback'ini çağır
        onStateChangeRequested?.call(workItemId, newState);
      }
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isOnCallMode = false,
  }) async {
    try {
      if (!_initialized) {
        try {
          await init();
        } catch (e) {
          // If init fails (e.g., in background service without context), try to show anyway
          print('⚠️ [NotificationService] Init failed, trying to show notification anyway: $e');
        }
      }

      // Don't request permission in background service - assume it's already granted
      // Permission should be requested when app is in foreground
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Skip permission request in background - assume already granted
        // Only check if we're in app context (which we're not in background service)
        try {
          final permission = await androidPlugin.requestNotificationsPermission();
          if (permission == false) {
            print('⚠️ [NotificationService] Notification permission denied, but trying to show anyway');
            // Continue anyway - permission might be granted but check failed
          }
        } catch (e) {
          // Permission check failed (likely in background service), continue anyway
          print('⚠️ [NotificationService] Permission check failed (likely background context), continuing: $e');
        }
      }

      // Nöbetçi modu kontrolü (parametre olarak geçiliyor)
      final androidDetails = AndroidNotificationDetails(
        'work_items',
        'Work Items',
        channelDescription: 'Notifications for Azure DevOps work items',
        importance: isOnCallMode ? Importance.max : Importance.high,
        priority: isOnCallMode ? Priority.max : Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        ongoing: false,
        autoCancel: true,
        // Wear OS (Akıllı Saat) desteği
        // Bildirimler otomatik olarak eşleşen Wear OS cihazlara gönderilir
        // Android Wear cihazlarda bildirimler görüntülenir ve etkileşimli olabilir
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // watchOS (Apple Watch) desteği
        // Bildirimler otomatik olarak eşleşen Apple Watch cihazlara gönderilir
        // watchOS'ta bildirimler görüntülenir ve etkileşimli olabilir
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use timestamp as notification ID to ensure newer notifications appear on top
      // Convert to int and use modulo to fit in 32-bit range
      final notificationId = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 2147483647;
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
      
      print('✅ Notification shown: $title - $body');
    } catch (e) {
      print('Error showing notification: $e');
      // Print stack trace for debugging
      print(e.toString());
    }
  }

  Future<void> showWorkItemNotification({
    required int workItemId,
    required String title,
    required String body,
    bool isFirstAssignment = false,
    bool isOnCallMode = false,
    List<String>? availableStates,
    String? currentState,
    StorageService? storageService,
    WorkItemService? workItemService,
  }) async {
    // Normal telefon bildirimi
    await showLocalNotification(
      title: 'Work Item #$workItemId: $title',
      body: body,
      payload: workItemId.toString(),
      isOnCallMode: isOnCallMode,
    );
    
    // Akıllı saat bildirimi (sadece ilk atamada)
    if (isFirstAssignment && storageService != null && storageService.getEnableSmartwatchNotifications()) {
      await showSmartwatchNotification(
        workItemId: workItemId,
        title: title,
        body: body,
        availableStates: availableStates,
        currentState: currentState,
        workItemService: workItemService,
        storageService: storageService,
      );
    }
  }

  /// Akıllı saat için özel bildirim gönderir
  /// Sadece ilk atamada, titreşim, ses ve ekran bildirimi ile
  /// Etkileşimli butonlar ile state değiştirme desteği
  Future<void> showSmartwatchNotification({
    required int workItemId,
    required String title,
    required String body,
    List<String>? availableStates,
    String? currentState,
    WorkItemService? workItemService,
    StorageService? storageService,
  }) async {
    try {
      if (!_initialized) {
        try {
          await init();
        } catch (e) {
          print('⚠️ [NotificationService] Init failed for smartwatch notification: $e');
          return;
        }
      }
      
      // Android Wear OS için etkileşimli butonlar
      List<AndroidNotificationAction>? actions;
      if (availableStates != null && availableStates.isNotEmpty && workItemService != null) {
        // İlk 3 state'i buton olarak ekle (akıllı saat ekranı sınırlı)
        final statesToShow = availableStates.take(3).toList();
        actions = statesToShow.map((state) {
          return AndroidNotificationAction(
            'state_$state',
            state, // label parameter
            // State değiştirme için action
            showsUserInterface: false,
          );
        }).toList();
      }

      // Android Wear OS için özel bildirim detayları
      final androidDetails = AndroidNotificationDetails(
        'work_items_smartwatch',
        'Work Items (Smartwatch)',
        channelDescription: 'Smartwatch notifications for Azure DevOps work items (first assignment only)',
        importance: Importance.max, // Maksimum öncelik
        priority: Priority.max,
        showWhen: true,
        enableVibration: true, // Titreşim aktif
        playSound: true, // Ses aktif
        ongoing: false,
        autoCancel: true,
        category: AndroidNotificationCategory.message,
        // Wear OS için özel ayarlar
        actions: actions, // Etkileşimli butonlar
        styleInformation: BigTextStyleInformation(body), // Büyük metin stili
      );

      // iOS watchOS için bildirim detayları
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true, // Ekran bildirimi
        presentBadge: true,
        presentSound: true, // Ses aktif
        // watchOS için category (etkileşimli butonlar için)
        categoryIdentifier: availableStates != null && availableStates.isNotEmpty 
            ? 'WORK_ITEM_STATE_CHANGE' 
            : null,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Akıllı saat bildirimi için özel ID (work item ID kullan)
      final notificationId = workItemId % 2147483647;
      
      await _localNotifications.show(
        notificationId,
        'Work Item #$workItemId: $title',
        body,
        details,
        payload: workItemId.toString(),
      );
      
      print('⌚ Smartwatch notification shown: Work Item #$workItemId - $title');
    } catch (e) {
      print('Error showing smartwatch notification: $e');
    }
  }

  /// Nöbetçi modunda agresif bildirim gönderir
  /// Daha yüksek öncelik, daha fazla titreşim, daha yüksek ses
  Future<void> showOnCallNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_initialized) {
        try {
          await init();
        } catch (e) {
          print('⚠️ [NotificationService] Init failed, trying to show notification anyway: $e');
        }
      }

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        try {
          final permission = await androidPlugin.requestNotificationsPermission();
          if (permission == false) {
            print('⚠️ [NotificationService] Notification permission denied');
          }
        } catch (e) {
          print('⚠️ [NotificationService] Permission check failed: $e');
        }
      }

      // Nöbetçi modu için agresif bildirim ayarları
      // Int64List runtime'da oluşturulduğu için const kullanılamaz
      final vibrationPattern = Int64List(6);
      vibrationPattern[0] = 0;
      vibrationPattern[1] = 500;
      vibrationPattern[2] = 200;
      vibrationPattern[3] = 500;
      vibrationPattern[4] = 200;
      vibrationPattern[5] = 500;
      
      final androidDetails = AndroidNotificationDetails(
        'work_items_oncall',
        'Work Items (On-Call)',
        channelDescription: 'Aggressive notifications for on-call mode',
        importance: Importance.max, // Maksimum öncelik
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern, // Daha agresif titreşim
        playSound: true,
        ongoing: false,
        autoCancel: true,
        category: AndroidNotificationCategory.alarm, // Alarm kategorisi (daha agresif)
        fullScreenIntent: true, // Tam ekran intent (Android 11+)
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default', // Varsayılan ses (daha yüksek)
        interruptionLevel: InterruptionLevel.critical, // Kritik seviye (iOS 15+)
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 2147483647;
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
      
      print('🚨 On-call notification shown: $title - $body');
    } catch (e) {
      print('Error showing on-call notification: $e');
    }
  }

  /// FCM token'ı alır
  /// Firebase yapılandırması tamamlandığında implement edilecektir
  /// Şu anda null döner çünkü Firebase entegrasyonu henüz yapılmamıştır
  Future<String?> getFCMToken() async {
    // Not: Firebase Cloud Messaging entegrasyonu için firebase_messaging paketi gerekli
    // Bu özellik gelecekte eklenebilir
    return null;
  }
}
