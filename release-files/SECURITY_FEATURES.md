# Security Features Documentation

**Last Updated:** 2025-12-18  
**Version:** 1.0.20+

## Overview

This document describes the security features implemented in the AzureDevOps Mobile Application, including recent enhancements and important configuration notes.

## 🔒 Implemented Security Features

### 1. Certificate Pinning

**Status:** ✅ Implemented (Production Ready)

Certificate pinning ensures that the app only communicates with servers that have specific SSL/TLS certificates, preventing man-in-the-middle (MITM) attacks.

#### Implementation Details:
- **Service:** `lib/services/certificate_pinning_service.dart`
- **Method:** SHA-256 fingerprint validation
- **Activation:** Automatically enabled in production builds (`PRODUCTION=true`)
- **Manual Testing:** Use `ENABLE_CERT_PINNING=true` flag

#### Configuration Required:
1. Extract certificate fingerprints from your Azure DevOps Server:
   ```bash
   ./scripts/extract_certificate_fingerprints.sh https://your-azure-devops-server.com
   ```

2. Add fingerprints to `lib/services/certificate_pinning_service.dart`:
   ```dart
   static const List<String> _allowedFingerprints = [
     'SHA256:AB:CD:EF:...',  // Your Azure DevOps Server
   ];
   ```

#### Important Notes:
- ⚠️ **Certificate fingerprints must be added before production deployment**
- ⚠️ **When server certificates are renewed, fingerprints must be updated**
- ✅ Development builds work normally without fingerprints (pinning disabled)
- ✅ Production builds will fail if fingerprints are missing and pinning is enabled

#### Documentation:
- Setup Guide: `scripts/setup_certificate_pinning.md`
- Extraction Script: `scripts/extract_certificate_fingerprints.sh`

---

### 2. Root/Jailbreak Detection

**Status:** ✅ Implemented

Device security checks to detect if the device is rooted (Android) or jailbroken (iOS).

#### Implementation Details:
- **Service:** `lib/services/security_service.dart`
- **Package:** `flutter_root_jailbreak_checker: ^2.0.1`
- **Method:** `checkOfflineIntegrity()` (API v2.0+)
- **Check Time:** Application startup

#### API Usage:
```dart
final checker = FlutterRootJailbreakChecker();
final result = await checker.checkOfflineIntegrity();
final isCompromised = result.isRooted || result.isJailbroken;
```

#### Behavior:
- ✅ Checks device security at app startup
- ✅ Logs security events (does not block app usage)
- ✅ Error handling: Assumes device is safe on error (to avoid blocking legitimate users)

#### Important Notes:
- ⚠️ **Package API changed in v2.0+**: Use `checkOfflineIntegrity()` method
- ⚠️ **Instance-based**: Create instance before calling method
- ✅ **Non-blocking**: App continues to work even if device is compromised (logged for monitoring)

---

### 3. Automatic Token Refresh

**Status:** ✅ Implemented (Conceptual for PATs)

Automatic token refresh mechanism to ensure authentication tokens remain valid.

#### Implementation Details:
- **Service:** `lib/services/token_refresh_service.dart`
- **Check Time:** Application startup
- **Expiry Buffer:** 5 minutes before token expiry

#### Current Implementation:
- ✅ Token expiry checking
- ✅ Automatic refresh trigger
- ⚠️ **PAT Limitation:** Azure DevOps PATs don't have refresh tokens
- ⚠️ **Placeholder:** Actual refresh logic needs implementation based on auth method

#### Storage:
- Token expiry stored in `SharedPreferences` via `StorageService`
- Methods: `getTokenExpiry()`, `setTokenExpiry()`

#### Important Notes:
- ⚠️ **PAT Refresh Not Implemented:** Azure DevOps PATs require manual token generation
- ⚠️ **Future Enhancement:** Implement refresh for OAuth2 or other auth methods
- ✅ **Expiry Tracking:** Currently tracks and logs token expiry status

---

### 4. Security Logging

**Status:** ✅ Implemented

Centralized security event logging for monitoring and auditing.

#### Implementation Details:
- **Service:** `lib/services/security_service.dart`
- **Package:** `logging: ^1.3.0`
- **Log Levels:** INFO, WARNING, SEVERE

#### Logged Events:
- ✅ Authentication events (`logAuthentication`)
- ✅ Token operations (`logTokenOperation`)
- ✅ API calls (`logApiCall`)
- ✅ Sensitive data access (`logSensitiveDataAccess`)
- ✅ Security events (`logSecurityEvent`)

#### Usage Example:
```dart
SecurityService.logAuthentication('Token login attempt', details: {'serverUrl': serverUrl});
SecurityService.logTokenOperation('Token stored', success: true);
SecurityService.logApiCall('/api/projects', method: 'GET', statusCode: 200);
```

#### Important Notes:
- ✅ **Centralized:** All security events logged through `SecurityService`
- ✅ **Level-based:** Different log levels for different severity
- ⚠️ **Production Integration:** TODO: Integrate with security monitoring service
- ✅ **Console Output:** Logs to console in debug mode (WARNING+)

---

## 🔧 Integration Points

### Main Application (`lib/main.dart`)

All security services are initialized at application startup:

```dart
// Initialize security service first
await SecurityService.initialize();

// Check device security
final isCompromised = await SecurityService.isDeviceCompromised();

// Ensure token is valid
await TokenRefreshService.ensureValidToken(storage);
```

### API Services

All API calls use certificate pinning:

- `lib/services/auth_service.dart` - Uses `CertificatePinningService.createSecureDio()`
- `lib/services/work_item_service.dart` - Uses `CertificatePinningService.createSecureDio()`
- `lib/services/wiki_service.dart` - Uses `CertificatePinningService.createSecureDio()`

### Storage Service

Token expiry tracking:

- `lib/services/storage_service.dart` - Methods: `getTokenExpiry()`, `setTokenExpiry()`

---

## 📋 CI/CD Integration

All security features are integrated into CI/CD pipelines:

### GitHub Actions
- ✅ `PRODUCTION=true` flag in build commands
- ✅ Security checks in workflow
- ✅ SBOM generation
- ✅ Security audit reports

### GitLab CI
- ✅ `PRODUCTION=true` flag in build commands
- ✅ Security scanning stages

### Jenkins
- ✅ `PRODUCTION=true` flag in build commands
- ✅ Security audit jobs

---

## 🚨 Important Security Notes

### Certificate Pinning
1. **Fingerprint Configuration Required:** Must add server fingerprints before production
2. **Certificate Renewal:** Update fingerprints when certificates are renewed
3. **Multiple Certificates:** Add all certificates in chain (server, load balancer, CDN)

### Root/Jailbreak Detection
1. **Non-Blocking:** App continues to work even if device is compromised
2. **Monitoring:** Security events are logged for investigation
3. **Production Consideration:** May want to block app usage on compromised devices

### Token Refresh
1. **PAT Limitation:** Azure DevOps PATs don't support refresh tokens
2. **Manual Token Generation:** Users must generate new PATs when expired
3. **Future Enhancement:** Implement for OAuth2 or other auth methods

### Security Logging
1. **Production Integration:** TODO: Send logs to security monitoring service
2. **Log Retention:** Consider log retention policies
3. **Privacy:** Ensure sensitive data is not logged

---

## 📚 Related Documentation

- **Certificate Pinning Setup:** `scripts/setup_certificate_pinning.md`
- **Security Audit:** `security/security_audit.md`
- **Security Report:** `security/security_report.md`
- **Security Implementation Report:** `security/security_implementation_report.md`
- **Comprehensive Audit:** `security/comprehensive_audit.md`

---

## 🔄 Recent Changes (v1.0.20+)

### Certificate Pinning
- ✅ Fixed fingerprint extraction script (preserve colon format)
- ✅ Added comprehensive setup documentation
- ✅ Improved error handling and warnings
- ✅ Added `ENABLE_CERT_PINNING` flag for manual testing

### Root/Jailbreak Detection
- ✅ Fixed API usage for `flutter_root_jailbreak_checker` v2.0+
- ✅ Updated to use `checkOfflineIntegrity()` method
- ✅ Improved error handling

### Security Logging
- ✅ Integrated into all authentication flows
- ✅ Added logging for API calls
- ✅ Added logging for token operations

---

## 📞 Support

For security-related issues or questions:
- Review security implementation report: `security/security_implementation_report.md`
- Check security audit: `security/security_audit.md`
- Run security checks: `./scripts/security_checks.sh`

---

**Developer:** Alpay Bilgiç  
**Email:** bilgicalpay@gmail.com  
**Last Updated:** 2025-12-18

