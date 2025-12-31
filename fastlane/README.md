fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build_apk

```sh
[bundle exec] fastlane android build_apk
```

Build Android APK

### android build_aab

```sh
[bundle exec] fastlane android build_aab
```

Build Android App Bundle (AAB)

### android test

```sh
[bundle exec] fastlane android test
```

Run Flutter tests

### android analyze

```sh
[bundle exec] fastlane android analyze
```

Run Flutter analyze

### android beta

```sh
[bundle exec] fastlane android beta
```

Build and deploy to internal testing

### android release

```sh
[bundle exec] fastlane android release
```

Build and deploy to production

### android upload_testing

```sh
[bundle exec] fastlane android upload_testing
```

Upload AAB to Alpha and Internal Testing tracks

### android clean

```sh
[bundle exec] fastlane android clean
```

Clean build artifacts

----


## iOS

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```

Build iOS IPA

### ios build_app

```sh
[bundle exec] fastlane ios build_app
```

Build iOS App

### ios test

```sh
[bundle exec] fastlane ios test
```

Run Flutter tests

### ios analyze

```sh
[bundle exec] fastlane ios analyze
```

Run Flutter analyze

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and deploy to TestFlight (beta)

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and deploy to App Store (production)

### ios clean

```sh
[bundle exec] fastlane ios clean
```

Clean build artifacts

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
