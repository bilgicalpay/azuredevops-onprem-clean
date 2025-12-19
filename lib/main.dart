/// Azure DevOps Server 2022 Mobile Application
/// 
/// Geliştirici: Alpay Bilgiç
/// 
/// Bu uygulama Azure DevOps Server 2022 on-premise kurulumları için
/// mobil erişim sağlar. Work item yönetimi, query çalıştırma, wiki görüntüleme
/// ve push notification desteği sunar.
/// 
/// @author Alpay Bilgiç
/// @version 1.0.0
library;

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderErrorBox, debugDisableShadows;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/background_task_service.dart';
import 'services/background_worker_service.dart';
import 'services/security_service.dart';
import 'services/token_refresh_service.dart';
import 'services/auto_logout_service.dart';
import 'package:logging/logging.dart';

/// Uygulama giriş noktası
/// Servisleri başlatır ve ana widget'ı çalıştırır
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Debug overflow göstergelerini tamamen kapat (OVERFLOWED BY X banner'ını gizler)
  // RenderErrorBox ayarları ile overflow banner'ları şeffaf yapılır
  RenderErrorBox.backgroundColor = Colors.transparent;
  RenderErrorBox.textStyle = ui.TextStyle(
    color: Colors.transparent,
    fontSize: 0.0,
  );
  // Debug mode'da overflow göstergelerini kapat
  debugDisableShadows = true;
  
  // Initialize security service first
  await SecurityService.initialize();
  
  // Check device security
  final isCompromised = await SecurityService.isDeviceCompromised();
  if (isCompromised) {
    SecurityService.logSecurityEvent(
      'WARNING: Device is compromised (rooted/jailbroken)',
      Level.SEVERE
    );
    // In production, you might want to block app usage or show warning
  }
  
  // Servisleri başlat
  final storage = StorageService();
  await storage.init();
  await NotificationService().init();
  
  // Background Worker Service'i başlat (uygulama kapalıyken çalışmak için)
  await BackgroundWorkerService.initialize();
  await BackgroundWorkerService.start();
  
  // Arka plan görev servisini başlat (uygulama açıkken çalışmak için)
  final backgroundService = BackgroundTaskService();
  await backgroundService.init();
  await backgroundService.initializeTracking(); // Bildirim göndermeden takibi başlat
  backgroundService.start();
  
  // Ensure token is valid
  await TokenRefreshService.ensureValidToken(storage);
  
  // Check for auto-logout (30 days of inactivity)
  final authService = AuthService();
  authService.setStorage(storage);
  await AutoLogoutService.checkAndPerformAutoLogout(storage, authService);
  
  runApp(MyApp(storage: storage));
}

/// Ana uygulama widget'ı
/// Provider'ları ve tema ayarlarını yapılandırır

class MyApp extends StatelessWidget {
  final StorageService storage;

  const MyApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final auth = AuthService();
          auth.setStorage(storage);
          return auth;
        }),
        ChangeNotifierProvider.value(value: storage),
      ],
      child: MaterialApp(
        title: '',
        debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.robotoTextTheme(),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
