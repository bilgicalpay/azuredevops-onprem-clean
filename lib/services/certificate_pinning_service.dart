import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logging/logging.dart';
import 'security_service.dart';

/// Certificate pinning service for production security
class CertificatePinningService {
  static final Logger _logger = Logger('CertificatePinningService');
  
  // SHA-256 fingerprints of allowed certificates
  // 
  // To add your server's certificate fingerprint:
  // 1. Run: ./scripts/extract_certificate_fingerprints.sh https://your-server.com
  // 2. Copy the output fingerprint and add it below
  // 3. For production builds, set PRODUCTION=true environment variable
  //
  // Example:
  // static const List<String> _allowedFingerprints = [
  //   'SHA256:ABC123...',  // Your Azure DevOps Server
  //   'SHA256:XYZ789...',  // Load balancer certificate (if applicable)
  // ];
  static const List<String> _allowedFingerprints = [
    // Add your certificate fingerprints here
    // Use scripts/extract_certificate_fingerprints.sh to extract them
  ];

  /// Configure Dio with certificate pinning
  static Dio createSecureDio() {
    final dio = Dio();
    
    // Configure timeouts for better reliability (especially for large files)
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(minutes: 20); // 20 minutes for very large file downloads (60MB+)
    dio.options.sendTimeout = const Duration(seconds: 60);
    
    // Only enable certificate pinning in production or if explicitly enabled
    final isProduction = const bool.fromEnvironment('PRODUCTION', defaultValue: false);
    final enablePinning = const bool.fromEnvironment('ENABLE_CERT_PINNING', defaultValue: false);
    
    if (isProduction || enablePinning) {
      // Check if fingerprints are configured
      if (_allowedFingerprints.isEmpty) {
        SecurityService.logSecurityEvent(
          'Certificate pinning requested but no fingerprints configured. Pinning disabled. ' 'Run: ./scripts/extract_certificate_fingerprints.sh https://your-server.com',
          Level.WARNING
        );
      } else {
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (X509Certificate cert, String host, int port) {
            return _validateCertificate(cert);
          };
          return client;
        };
        SecurityService.logSecurityEvent(
          'Certificate pinning enabled with ${_allowedFingerprints.length} fingerprint(s)',
          Level.INFO
        );
      }
    } else {
      SecurityService.logSecurityEvent('Certificate pinning disabled (development mode)', Level.INFO);
    }
    
    return dio;
  }

  /// Validate certificate fingerprint
  static bool _validateCertificate(X509Certificate cert) {
    try {
      // Get certificate fingerprint
      final fingerprint = _getCertificateFingerprint(cert);
      
      // Check if fingerprint is in allowed list
      final isValid = _allowedFingerprints.contains(fingerprint);
      
      if (!isValid) {
        SecurityService.logSecurityEvent(
          'Certificate validation failed: $fingerprint',
          Level.SEVERE
        );
      }
      
      return isValid;
    } catch (e) {
      SecurityService.logSecurityEvent(
        'Certificate validation error: $e',
        Level.SEVERE
      );
      return false;
    }
  }

  /// Get SHA-256 fingerprint of certificate
  static String _getCertificateFingerprint(X509Certificate cert) {
    try {
      // Extract SHA-256 fingerprint from certificate
      // Format: SHA256:HEX_VALUE (uppercase, no colons)
      final der = cert.der;
      if (der.isNotEmpty) {
        // Use openssl or platform-specific method to get SHA-256
        // For now, we'll use the certificate's subject and issuer to create a unique identifier
        // In production, use proper SHA-256 hash of the certificate
        final subject = cert.subject;
        final issuer = cert.issuer;
        
        // Note: This is a placeholder. In production, you should:
        // 1. Extract the actual SHA-256 fingerprint using platform-specific code
        // 2. Or use the extract_certificate_fingerprints.sh script to get fingerprints
        // 3. Add them to _allowedFingerprints manually
        
        // For Android/iOS, you may need platform channels to get the actual fingerprint
        // This requires native code implementation
        return 'SHA256:${subject.hashCode}_${issuer.hashCode}'; // Placeholder
      }
      return '';
    } catch (e) {
      _logger.severe('Error extracting certificate fingerprint: $e');
      return '';
    }
  }

  /// Extract certificate fingerprints from server
  /// 
  /// Note: This method is a placeholder. To extract fingerprints:
  /// 1. Use the script: ./scripts/extract_certificate_fingerprints.sh https://your-server.com
  /// 2. Or manually extract using openssl:
  ///    echo | openssl s_client -connect server.com:443 -servername server.com 2>/dev/null | openssl x509 -fingerprint -sha256 -noout
  /// 3. Add the fingerprint to _allowedFingerprints list
  static Future<List<String>> extractServerFingerprints(String host, int port) async {
    try {
      SecurityService.logSecurityEvent(
        'Certificate fingerprint extraction - use scripts/extract_certificate_fingerprints.sh instead',
        Level.INFO
      );
      
      // Return empty list - fingerprints should be extracted using the script
      // and manually added to _allowedFingerprints
      return [];
    } catch (e) {
      _logger.severe('Error extracting fingerprints: $e');
      return [];
    }
  }
}
