# Certificate Pinning Setup Guide

## Overview

Certificate pinning is a security feature that ensures your app only communicates with servers that have specific SSL/TLS certificates. This prevents man-in-the-middle (MITM) attacks by rejecting connections to servers with different certificates, even if they are valid.

## Prerequisites

- OpenSSL installed on your system
- Access to your Azure DevOps Server URL
- Production build environment configured

## Step 1: Extract Certificate Fingerprints

Use the provided script to extract SHA-256 fingerprints from your Azure DevOps Server:

```bash
./scripts/extract_certificate_fingerprints.sh https://your-azure-devops-server.com
```

**Example:**

```bash
./scripts/extract_certificate_fingerprints.sh https://devops.company.com
```

The script will output:

```
✅ Extracted SHA-256 Fingerprints:
SHA256:AB-CD-EF-12-34-56-78-90-AB-CD-EF-12-34-56-78-90-AB-CD-EF-12-34-56-78-90-AB-CD-EF-12-34-56-78-90-AB-CD-EF
```

## Step 2: Add Fingerprints to Code

1. Open `lib/services/certificate_pinning_service.dart`
2. Find the `_allowedFingerprints` list
3. Add your fingerprint(s) to the list:

```dart
static const List<String> _allowedFingerprints = [
  'SHA256:AB-CD-EF-12-34-56-78-90-AB-CD-EF-12-34-56-78-90-AB-CD-EF-12-34-56-78-90-AB-CD-EF-12-34-56-78-90-AB-CD-EF',  // Your Azure DevOps Server
  // Add additional fingerprints for load balancers or CDNs if applicable
];
```

**Important Notes:**

- The fingerprint format must be: `SHA256:HEX-VALUE` (with colons)
- If you have multiple certificates (e.g., load balancer + server), add all of them
- The script automatically formats the fingerprint correctly

## Step 3: Enable Certificate Pinning

Certificate pinning is automatically enabled in production builds. The build process sets `PRODUCTION=true`:

### Android Build:

```bash
flutter build apk --release --dart-define=PRODUCTION=true
flutter build appbundle --release --dart-define=PRODUCTION=true
```

### iOS Build:

```bash
flutter build ipa --release --dart-define=PRODUCTION=true
```

### Manual Testing (Development):

If you want to test certificate pinning in development mode:

```bash
flutter run --dart-define=ENABLE_CERT_PINNING=true
```

## Step 4: Verify Configuration

After adding fingerprints, verify the configuration:

1. **Check the service file:**

   ```bash
   grep -A 5 "_allowedFingerprints" lib/services/certificate_pinning_service.dart
   ```
2. **Run security checks:**

   ```bash
   ./scripts/security_checks.sh
   ```
3. **Check the report:**

   ```bash
   cat security/security_implementation_report.md
   ```

## Step 5: Test Certificate Pinning

### Test in Development Mode:

```bash
# Without pinning (should work normally)
flutter run

# With pinning enabled (should work if fingerprints match)
flutter run --dart-define=ENABLE_CERT_PINNING=true
```

### Test Production Build:

```bash
# Build with production flag
flutter build apk --release --dart-define=PRODUCTION=true

# Install and test
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

### Issue: "Certificate validation failed"

**Cause:** The server's certificate doesn't match any fingerprint in the list.

**Solutions:**

1. Re-extract fingerprints: `./scripts/extract_certificate_fingerprints.sh https://your-server.com`
2. Check if the certificate was renewed/changed
3. Verify you're connecting to the correct server
4. Check for load balancer certificates (add all certificates in the chain)

### Issue: "Certificate pinning requested but no fingerprints configured"

**Cause:** Production build is enabled but no fingerprints are in the list.

**Solution:**

1. Add at least one fingerprint to `_allowedFingerprints`
2. Or disable pinning by removing `PRODUCTION=true` from build command

### Issue: Connection fails in production build

**Cause:** Certificate pinning is blocking the connection.

**Solutions:**

1. Verify fingerprints are correct
2. Check if certificate chain includes intermediate certificates
3. Temporarily disable pinning to test: Remove `PRODUCTION=true` from build

## Certificate Updates

When your server's certificate is renewed or changed:

1. **Extract new fingerprints:**

   ```bash
   ./scripts/extract_certificate_fingerprints.sh https://your-server.com
   ```
2. **Update the code:**

   - Replace old fingerprints in `_allowedFingerprints`
   - Or add new fingerprints alongside old ones (during transition period)
3. **Test:**

   - Build and test the app
   - Verify connections work correctly
4. **Deploy:**

   - Create a new release with updated fingerprints
   - Notify users to update if necessary

## Best Practices

1. **Multiple Fingerprints:**

   - Add fingerprints for all certificates in the chain (server, load balancer, CDN)
   - Keep old fingerprints during certificate transitions
2. **Regular Updates:**

   - Check certificate expiry dates
   - Update fingerprints before certificates expire
3. **Monitoring:**

   - Monitor security logs for certificate validation failures
   - Set up alerts for repeated failures
4. **Testing:**

   - Test certificate pinning in staging environment first
   - Verify both valid and invalid certificate scenarios

## CI/CD Integration

Certificate pinning is automatically enabled in all CI/CD pipelines:

- **GitHub Actions:** `PRODUCTION=true` is set in build commands
- **GitLab CI:** `PRODUCTION=true` is set in build commands
- **Jenkins:** `PRODUCTION=true` is set in build commands

No additional configuration needed in pipelines.

## Security Considerations

1. **Fingerprint Storage:**

   - Fingerprints are stored in source code (public repository)
   - This is acceptable as fingerprints are public information
   - They don't reveal private keys or sensitive data
2. **Certificate Renewal:**

   - Plan certificate renewals in advance
   - Update fingerprints before expiry
   - Test thoroughly before production deployment
3. **Fallback Strategy:**

   - Consider implementing a fallback mechanism for certificate updates
   - Monitor for certificate validation failures
   - Have a rollback plan if pinning causes issues

## Additional Resources

- [OWASP Certificate Pinning Guide](https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning)
- [Flutter SSL Pinning](https://flutter.dev/docs/development/data-and-backend/networking)
- [OpenSSL Documentation](https://www.openssl.org/docs/)

## Support

If you encounter issues:

1. Check the security implementation report: `security/security_implementation_report.md`
2. Review logs for certificate validation errors
3. Verify OpenSSL and script execution
4. Test with `ENABLE_CERT_PINNING=true` flag in development mode
