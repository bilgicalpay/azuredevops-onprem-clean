# Release Notes - v1.0.20 (Build 21)

**Release Date:** 2025-12-18  
**Package Name:** io.rdc.azuredevops  
**Developer:** Alpay Bilgiç (bilgicalpay@gmail.com)

## 📦 Build Files

- **Android APK:** azuredevops.apk (54MB)
- **iOS IPA:** azuredevops.ipa (7.7MB)

## 🚀 Deployment Status

- ✅ **Android:** Deployed to device via ADB
- ✅ **iOS:** Deployed to simulator

## 🔒 Security Enhancements

### Security Audit & Compliance
- ✅ **SBOM Generated:** Software Bill of Materials created in SPDX and text formats
  - `build/sbom/spdx.json` (SPDX format)
  - `build/sbom/sbom.txt` (Text format)
- ✅ **Security Audit Report:** Comprehensive security analysis completed
  - `security/security_audit.md`
  - `security/security_report.md`
- ✅ **OWASP Top 10 Analysis:** Security vulnerabilities assessed
- ✅ **Dependency Vulnerability Scan:** Outdated packages identified
- ✅ **Cosign Installed:** Ready for artifact signing

### Security Features
- ✅ Secure token storage using FlutterSecureStorage
- ✅ Android: EncryptedSharedPreferences
- ✅ iOS: Keychain
- ✅ HTTPS enforced for all API calls
- ✅ Background service security improvements
- ✅ Android 15 compatibility

## 📋 Package Name Change

**Previous:** io.purplesoft.azuredevops_onprem  
**Current:** io.rdc.azuredevops

### Updated Files
- Android: build.gradle.kts, MainActivity.kt, AndroidManifest.xml
- iOS: project.pbxproj, Appfile
- Scripts: build_and_deploy.sh
- Documentation: All documentation files updated

## 🐛 Bug Fixes

- Fixed duplicate MainActivity.kt compilation error
- Fixed background service notifications when app is swiped away
- Fixed FlutterSecureStorage access in background service
- Fixed NotificationService context issues in background service
- Improved persistent storage for tracking data

## ✨ Features

- Background service notifications (Android 15 compatible)
- User-configurable polling interval (5-300 seconds)
- Persistent storage for background service tracking
- Real-time work item updates
- Push notifications for new work items and changes
- Wiki content display
- Query execution and results display
- Work item detail view

## 📚 Documentation Updates

- Updated all dates from 2024 to 2025
- Updated developer email to bilgicalpay@gmail.com
- Added security documentation
- Added SBOM generation scripts
- Added security scanning scripts

## 🔧 Technical Details

### Dependencies
- Flutter SDK: 3.40.0-1.0.pre-212
- Dart SDK: 3.11.0 (build 3.11.0-245.0.dev)
- Minimum Android: SDK 21 (Android 5.0)
- Target Android: SDK 34 (Android 14)
- Minimum iOS: 13.0
- Target iOS: 17.0

### Build Information
- Build Date: 2025-12-18
- Build Number: 21
- Version: 1.0.20

## 📝 Security Recommendations

1. Update outdated dependencies to latest versions
2. Implement certificate pinning for production
3. Add root/jailbreak detection
4. Implement automatic token refresh
5. Add security logging for sensitive operations
6. Regular security audits and dependency updates

## 📦 Files Included in Release

- azuredevops.apk (Android APK)
- azuredevops.ipa (iOS IPA)
- RELEASE_NOTES.md (This file)
- build/sbom/spdx.json (SBOM - SPDX format)
- build/sbom/sbom.txt (SBOM - Text format)
- security/security_report.md (Security Report)
- security/security_audit.md (Security Audit)

## 🔗 Links

- **Repository:** https://github.com/bilgicalpay/azuredevops-onprem-clean
- **Release:** https://github.com/bilgicalpay/azuredevops-onprem-clean/releases/tag/v1.0.20
- **Security Report:** security/security_report.md
- **SBOM:** build/sbom/

## 📞 Support

**Developer:** Alpay Bilgiç  
**Email:** bilgicalpay@gmail.com

---

**Note:** This release includes comprehensive security audits, SBOM generation, and all necessary documentation for compliance and security review.
