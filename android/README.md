Eira Health Assistant - Android Deployment Guide

This guide explains how to configure and build the Eira Health Assistant Flutter application for Android devices, either for the Google Play Store or direct APK distribution.

Prerequisites

Before you begin, ensure you have the following installed and configured:

Flutter SDK – Required for building and running the app.

Java Development Kit (JDK) – Required for Android builds.

Android Studio – For managing Android SDKs, emulators, and project configuration.

Google Play Console Account – Required if you plan to publish to the Play Store.

1. Building an Android App Bundle (AAB) for Production

The AAB format is the preferred standard for publishing on the Google Play Store. It enables Google to generate optimized APKs for users' devices automatically.

Steps

Open a terminal and navigate to the project root (the parent of the android folder).

Install all dependencies:

flutter pub get


Build the App Bundle:

flutter build appbundle --release


Locate the generated AAB file:

build/app/outputs/bundle/release/app.aab


Deploy to Google Play Store:

Log in to your Google Play Console
.

Create or select your app listing.

Upload the app.aab.

Configure versioning, release notes, and store listing.

Ensure your upload key (.jks) and Google-managed signing key are properly configured.

2. Building an APK for Direct Distribution

If you need to share the app outside the Play Store (e.g., for testers or internal users), you can generate a universal APK.

Steps

Open a terminal and navigate to the project root.

Build the APK:

flutter build apk --release


Locate the generated APK file:

build/app/outputs/flutter-apk/app-release.apk


Distribute the APK:

Share the file directly with users.

Users must enable Install from unknown sources on their Android devices.

3. Important Notes

Signing Keys: Always securely manage your upload key (.jks) and any Google-managed signing keys. Losing the key can prevent app updates.

Backend URL: Before building, ensure _baseUrl in lib/api_service.dart points to your production backend.

Versioning: Update version and build number in pubspec.yaml to reflect releases.

Testing: Always test your release build on multiple devices or emulators before deployment.

✅ Tip: For consistent builds, consider creating separate build flavors for staging and production. This allows you to switch _baseUrl and other configurations easily without modifying code each time.
