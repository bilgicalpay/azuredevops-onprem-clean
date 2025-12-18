# Release Notes - v1.0.22 (Build 25)

**Release Date:** 2025-12-18  
**Package Name:** io.rdc.azuredevops  
**Developer:** Alpay Bilgiç (bilgicalpay@gmail.com)

## 📦 Build Files

- **Android APK:** azuredevops-1.0.22.apk
- **iOS IPA:** azuredevops-1.0.22.ipa (if available)

## 🚀 Deployment Status

- ✅ **Android:** Ready for deployment
- ✅ **iOS:** Ready for deployment (if built)

## 🔒 Security Enhancements

### Critical Security Improvements

#### 1. Secure Credential Storage ✅
- **AD Username:** Now stored encrypted in FlutterSecureStorage (not Base64)
- **AD Password:** Now stored encrypted in FlutterSecureStorage (not Base64)
- **PAT Token:** Already stored encrypted (no Base64 encoding)
- **Base64 Encoding:** Only used at runtime for API calls, NOT for storage
- **Security Level:** High (was Medium-High)

#### 2. Root/Jailbreak Detection ✅
- **Status:** Fully Implemented and Active
- **Package:** `root_detector: ^0.0.2` (replaced disabled package)
- **Service:** `lib/services/security_service.dart`
- **Method:** `isDeviceCompromised()` - Active and working
- **Behavior:** Checks device security at app startup, logs events

#### 3. Automatic Logout ✅
- **Status:** Implemented
- **Service:** `lib/services/auto_logout_service.dart`
- **Feature:** 30 days of inactivity triggers automatic logout
- **Tracking:** Last activity timestamp stored and checked
- **Integration:** HomeScreen activity tracking on app resume

#### 4. Certificate Pinning ✅
- **Status:** Production Ready (Fingerprint configuration required)
- **Service:** `lib/services/certificate_pinning_service.dart`
- **Activation:** Automatically enabled in production builds (`PRODUCTION=true`)
- **Setup Guide:** `scripts/setup_certificate_pinning.md`
- **Extraction Script:** `scripts/extract_certificate_fingerprints.sh`

#### 5. Security Logging ✅
- **Status:** Implemented
- **Service:** `lib/services/security_service.dart`
- **Package:** `logging: ^1.3.0`
- **Events:** Authentication, token operations, API calls, sensitive data access, security events

### Artifact Signing (Sigstore)

- ✅ **APK Signing:** Sigstore signing implemented
- ✅ **Script:** `scripts/sign_artifact.sh`
- ✅ **CI/CD Integration:** All pipelines updated
  - GitHub Actions ✅
  - GitLab CI ✅
  - Jenkins ✅
  - Azure DevOps ✅

### Security Audit & Compliance

- ✅ **SBOM Generated:** Software Bill of Materials created in SPDX and text formats
  - build/sbom/spdx.json (SPDX format)
  - build/sbom/sbom.txt (Text format)
- ✅ **Security Audit Report:** Comprehensive security analysis completed
  - security/security_audit.md
- ✅ **OWASP Top 10 Analysis:** Security vulnerabilities assessed
- ✅ **Dependency Vulnerability Scan:** Outdated packages identified
- ✅ **Comprehensive Security Audit:** Combined security analysis

## 🐛 Bug Fixes

### Authentication Fixes
- ✅ **AD Auth Support:** Fixed all services to use `getAuthToken()` method
- ✅ **Token Generation:** AD auth now generates token at runtime from stored credentials
- ✅ **Service Updates:** All services updated to support both PAT and AD auth
  - RealtimeService ✅
  - HomeScreen ✅
  - WorkItemDetailScreen ✅
  - QueriesScreen ✅

## ✨ New Features

### Auto-Logout
- ✅ **30-Day Inactivity:** Automatic logout after 30 days of no activity
- ✅ **Activity Tracking:** Last activity timestamp stored and checked
- ✅ **Integration:** HomeScreen tracks activity on app resume

### CI/CD Enhancements
- ✅ **Azure DevOps Pipeline:** New pipeline created (`azure-pipelines.yml`)
- ✅ **Sigstore Signing:** Added to all CI/CD pipelines
- ✅ **Automated Security:** SBOM generation in all pipelines

## 📝 Documentation Updates

- ✅ **docs/SECURITY.md:** Updated with current security implementations
- ✅ **docs/README.md:** Updated security status (all features implemented)
- ✅ **RELEASE_NOTES.md:** Comprehensive release notes

## 🔧 Technical Details

### Dependencies
- Flutter SDK: 3.27.0
- Dart SDK: 3.5.0+
- Minimum Android: SDK 21 (Android 5.0)
- Target Android: SDK 34 (Android 14)
- Minimum iOS: 12.0
- Target iOS: 17.0

### New Dependencies
- `root_detector: ^0.0.2` - Root/jailbreak detection

### Build Information
- Build Date: 2025-12-18
- Build Number: 25
- Version: 1.0.22

## 🔄 Migration Notes

### For Existing Users
- **AD Auth Users:** Credentials will be migrated to secure storage on next login
- **PAT Users:** No changes required, tokens already secure
- **Auto-Logout:** Will trigger if app not used for 30+ days

### For Developers
- All `authService.token!` usages replaced with `await authService.getAuthToken()`
- AD auth now requires async token generation
- Services updated to support both auth methods

## 📦 Files Included in Release

- azuredevops-1.0.22.apk (Android APK)
- azuredevops-1.0.22.apk.sigstore (Sigstore signature - if signed)
- RELEASE_NOTES.md (This file)
- build/sbom/spdx.json (SBOM - SPDX format)
- build/sbom/sbom.txt (SBOM - Text format)
- security/security_report.md (Security Report)
- security/security_audit.md (Security Audit)
- security/comprehensive_audit.md (Comprehensive Security Audit)
- security/security_implementation_report.md (Security Implementation Report)

## 🔗 Links

- **Repository:** https://github.com/bilgicalpay/azuredevops-onprem-clean
- **Release:** https://github.com/bilgicalpay/azuredevops-onprem-clean/releases/tag/v1.0.22
- **Security Documentation:** docs/SECURITY.md
- **Security Features:** docs/SECURITY_FEATURES.md
- **SBOM:** build/sbom/

## 📞 Support

**Developer:** Alpay Bilgiç  
**Email:** bilgicalpay@gmail.com

---

## 🎯 Summary of Changes

### Security Improvements
1. ✅ AD credentials moved to FlutterSecureStorage (encrypted, no Base64)
2. ✅ Root/jailbreak detection fully implemented
3. ✅ Auto-logout after 30 days of inactivity
4. ✅ Sigstore signing for all artifacts
5. ✅ All CI/CD pipelines updated with security features

### Code Quality
1. ✅ All services updated to support AD auth
2. ✅ Async token generation for AD auth
3. ✅ Comprehensive error handling
4. ✅ Security logging throughout

### Documentation
1. ✅ Security documentation updated
2. ✅ Release notes comprehensive
3. ✅ All features documented

---

**Note:** This release includes critical security improvements, especially for AD authentication. All credentials are now stored encrypted without Base64 encoding. Base64 encoding is only used at runtime for API calls.
