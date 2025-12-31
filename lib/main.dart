/// AzureDevOps Mobile Application
/// 
/// Geliştirici: Alpay Bilgiç
/// 
/// Bu uygulama AzureDevOps on-premise kurulumları için
/// mobil erişim sağlar. Work item yönetimi, query çalıştırma, wiki görüntüleme
/// ve push notification desteği sunar.
/// 
/// @author Alpay Bilgiç
/// @version 1.0.0
library;

import 'dart:ui' as ui;
import 'dart:ui' show Locale;
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:azuredevops_onprem/l10n/app_localizations.dart';

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
  
  StorageService? storage;
  
  try {
    // Initialize security service first
    try {
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
    } catch (e) {
      debugPrint('⚠️ [Main] SecurityService initialization error: $e');
      // Continue even if security service fails
    }
    
    // Servisleri başlat
    storage = StorageService();
    try {
      await storage.init();
    } catch (e) {
      debugPrint('⚠️ [Main] StorageService init error: $e');
      // Continue with storage even if init fails
    }
    
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('⚠️ [Main] NotificationService init error: $e');
      // Continue even if notification service fails
    }
    
    // Background Worker Service'i başlat (uygulama kapalıyken çalışmak için)
    try {
      await BackgroundWorkerService.initialize();
      await BackgroundWorkerService.start();
    } catch (e) {
      debugPrint('⚠️ [Main] BackgroundWorkerService error: $e');
      // Continue even if background worker fails
    }
    
    // Arka plan görev servisini başlat (uygulama açıkken çalışmak için)
    try {
      final backgroundService = BackgroundTaskService();
      await backgroundService.init();
      await backgroundService.initializeTracking(); // Bildirim göndermeden takibi başlat
      backgroundService.start();
    } catch (e) {
      debugPrint('⚠️ [Main] BackgroundTaskService error: $e');
      // Continue even if background task service fails
    }
    
    // Ensure token is valid
    try {
      if (storage != null) {
        await TokenRefreshService.ensureValidToken(storage);
      }
    } catch (e) {
      debugPrint('⚠️ [Main] TokenRefreshService error: $e');
      // Continue even if token refresh fails
    }
    
    // Check for auto-logout (30 days of inactivity)
    try {
      if (storage != null) {
        final authService = AuthService();
        authService.setStorage(storage);
        await AutoLogoutService.checkAndPerformAutoLogout(storage, authService);
      }
    } catch (e) {
      debugPrint('⚠️ [Main] AutoLogoutService error: $e');
      // Continue even if auto-logout check fails
    }
  } catch (e, stackTrace) {
    debugPrint('❌ [Main] Critical error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Create storage if it wasn't created
    if (storage == null) {
      storage = StorageService();
      try {
        await storage.init();
      } catch (e2) {
        debugPrint('❌ [Main] Failed to create StorageService: $e2');
      }
    }
  }
  
  // Always run app, even if some services failed
  if (storage != null) {
    runApp(MyApp(storage: storage));
  } else {
    // Last resort: create minimal storage
    final fallbackStorage = StorageService();
    try {
      await fallbackStorage.init();
      runApp(MyApp(storage: fallbackStorage));
    } catch (e) {
      debugPrint('❌ [Main] Failed to start app: $e');
      // App will crash, but at least we tried
      rethrow;
    }
  }
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
      child: Consumer<StorageService>(
        builder: (context, storageService, _) {
          // Get selected language or use system default
          final selectedLanguage = storageService.getSelectedLanguage();
          Locale? locale;
          
          if (selectedLanguage != 'system') {
            locale = Locale(selectedLanguage);
          } else {
            // Use system locale
            final systemLocale = ui.PlatformDispatcher.instance.locale;
            // Check if system locale is supported
            final supportedLocales = ['tr', 'en', 'ru', 'hi', 'nl', 'de', 'fr', 'ur'];
            if (supportedLocales.contains(systemLocale.languageCode)) {
              locale = systemLocale;
            } else {
              // Default to Turkish if system locale not supported
              locale = const Locale('tr');
            }
          }
          
          return MaterialApp(
            title: '',
            debugShowCheckedModeBanner: false,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('tr', ''), // Turkish
              Locale('en', ''), // English
              Locale('ru', ''), // Russian
              Locale('hi', ''), // Hindi
              Locale('nl', ''), // Dutch
              Locale('de', ''), // German
              Locale('fr', ''), // French
              Locale('ur', ''), // Urdu
              Locale('ug', ''), // Uyghur
              Locale('az', ''), // Azerbaijani
              Locale('ky', ''), // Kyrgyz
              Locale('ja', ''), // Japanese
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              textTheme: _getTextTheme(ThemeData.light().textTheme),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              textTheme: _getTextTheme(ThemeData.dark().textTheme),
              useMaterial3: true,
            ),
            themeMode: _getThemeMode(storageService.getThemeMode()),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Get ThemeMode from string
ThemeMode _getThemeMode(String mode) {
  switch (mode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

/// Google Fonts yüklenirken hata olursa fallback text theme döndürür
TextTheme _getTextTheme(TextTheme baseTheme) {
  try {
    return GoogleFonts.robotoTextTheme(baseTheme);
  } catch (e) {
    // Google Fonts yüklenemezse (internet yok, vs.) varsayılan tema kullan
    debugPrint('⚠️ [Main] Google Fonts yüklenemedi, varsayılan tema kullanılıyor: $e');
    return baseTheme;
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Show welcome dialog on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialogIfNeeded();
    });
  }

  Future<void> _showWelcomeDialogIfNeeded() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    
    // Check if welcome dialog has been shown
    if (!storage.hasShownWelcomeDialog()) {
      // Wait a bit for the screen to render
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Show welcome dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WelcomeDialog(),
      );
      
      // Mark as shown
      await storage.setHasShownWelcomeDialog(true);
      
      // Auto-dismiss after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

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

/// Welcome dialog shown on first app launch
class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.business_center,
                size: 32,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'RDC Partner tarafından AzureDevOps kullanıcılarına sunulmuştur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
