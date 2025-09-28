Eira Health Assistant - iOS Deployment Guide

This guide explains how to build and deploy the Eira Health Assistant Flutter application to iOS devices, including testing on physical devices and publishing to the App Store.

The folder contains the Xcode project, configuration files (Info.plist, Podfile), and necessary assets.

1. Prerequisites

Before you begin, ensure you have the following:

macOS Computer – Required for Xcode and iOS builds.

Flutter SDK – Installed and configured.

Xcode – Latest version from the Mac App Store.

CocoaPods – Dependency manager for iOS projects. Install via:

sudo gem install cocoapods


Apple Developer Program Membership – Needed to run on physical devices and publish to the App Store.

2. Building the iOS App for App Store Deployment
Step 1: Navigate to the project root
cd /path/to/EiraUIFlutter

Step 2: Install Flutter dependencies
flutter pub get

Step 3: Install iOS dependencies
cd ios
pod install
cd ..

Step 4: Build the iOS archive
flutter build ipa --release


This generates an Xcode archive (.xcarchive) in build/ios/archive/.

A distributable .ipa file will also be created in build/ios/ipa/.

Step 5: Deploy using Xcode

Open ios/Runner.xcworkspace in Xcode.

Navigate to Product > Archive to create a build archive.

Xcode Organizer will open showing the archive.

Click Distribute App to validate and upload the build to App Store Connect.

3. Important iOS Configurations

Permissions: Ensure ios/Runner/Info.plist includes all necessary permissions, e.g.:

<key>NSCameraUsageDescription</key>
<string>Required for capturing user input</string>
<key>NSMicrophoneUsageDescription</key>
<string>Required for audio recording</string>


Signing & Capabilities: In Xcode, configure your Team, Bundle Identifier, and signing certificates for running on devices and App Store submission.

Backend URL: Ensure _baseUrl in lib/api_service.dart points to your production backend server.

Testing: Always test on multiple physical devices and simulators before submitting to the App Store.

✅ Tip: Consider creating separate build configurations for staging and production to avoid manually switching backend URLs before each build.
