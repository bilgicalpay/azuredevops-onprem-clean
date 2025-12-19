/// Auto Logout Service
/// 
/// Handles automatic logout when app is not used for 30 days
/// Checks last activity timestamp and triggers logout if needed
/// 
/// @author Alpay Bilgiç
library;

import 'package:logging/logging.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import 'security_service.dart';

/// Service for automatic logout functionality
class AutoLogoutService {
  static final Logger _logger = Logger('AutoLogoutService');
  static const int _autoLogoutDays = 30; // 30 days of inactivity

  /// Check if auto-logout should be triggered and perform logout if needed
  /// 
  /// This should be called when the app starts or resumes
  static Future<bool> checkAndPerformAutoLogout(
    StorageService storage,
    AuthService authService,
  ) async {
    try {
      final shouldLogout = await storage.shouldAutoLogout();
      
      if (shouldLogout) {
        _logger.warning('Auto-logout triggered: App not used for $_autoLogoutDays days');
        SecurityService.logSecurityEvent(
          'Auto-logout triggered due to inactivity (30 days)',
          Level.WARNING
        );
        
        // Perform logout
        await authService.logout();
        
        return true; // Logout was performed
      }
      
      // Update last activity timestamp
      await storage.updateLastActivityTimestamp();
      
      return false; // No logout needed
    } catch (e) {
      _logger.severe('Error in auto-logout check: $e');
      SecurityService.logSecurityEvent(
        'Error checking auto-logout: $e',
        Level.SEVERE
      );
      return false;
    }
  }

  /// Update last activity timestamp
  /// 
  /// Call this whenever user interacts with the app
  static Future<void> updateActivity(StorageService storage) async {
    try {
      await storage.updateLastActivityTimestamp();
    } catch (e) {
      _logger.warning('Error updating activity timestamp: $e');
    }
  }
}

