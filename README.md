📱 Eira Health Assistant - Android Deployment Guide

This document provides instructions for building and deploying the Eira Health Assistant mobile application to Android devices, either via the Google Play Store (recommended) or through direct APK distribution.

🚀 Prerequisites

Before you begin, make sure you have the following installed and configured:

Flutter SDK
 (latest stable version)

Java Development Kit (JDK)
 (required for Android builds)

Android Studio
 (for Android SDKs, device emulators, and debugging)

Google Play Console Account
 (if deploying to the Play Store)

📦 Building the Android App Bundle (AAB) – For Play Store Deployment

The .aab (Android App Bundle) format is the required standard for publishing apps to the Google Play Store.
It allows Google to generate optimized APKs for users’ devices.

Steps:

Navigate to the project root directory (where pubspec.yaml is located).

Fetch all dependencies:

flutter pub get


Run the build command:

flutter build appbundle


Locate the generated bundle at:

build/app/outputs/bundle/release/app.aab


Upload app.aab to your app listing in the Google Play Console.

Ensure you have set the correct version number in pubspec.yaml.

Manage signing keys (upload key and Google Play signing).

Complete your app’s store listing details before publishing.

📲 Building an APK – For Direct Distribution or Testing

If you want to distribute the app outside the Play Store (e.g., for testing or internal users), build a universal .apk.

Steps:

Navigate to the project root directory.

Run the build command:

flutter build apk


Locate the generated APK at:

build/app/outputs/flutter-apk/app-release.apk


Share the app-release.apk with testers or internal users.
⚠️ Users must enable “Install from Unknown Sources” on their device to install.

🔑 Notes & Best Practices

Signing Keys:

Always secure your .jks (upload key).

Keep it safe and do not commit it to version control.

For Play Store builds, Google manages the final app signing key.

Backend URL Configuration:

Before building for production, ensure that the _baseUrl in:

lib/api_service.dart


points to your live production backend server (not a local or staging server).

Testing Before Release:

Test the app on both real devices and emulators.

Validate API calls and check for runtime errors before uploading.

✅ Summary

Use AAB for Play Store deployments.

Use APK for direct installs and testing.

Double-check version numbers, signing keys, and backend URLs before release.
