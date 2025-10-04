🚀 Flutter iOS Deployment on AWS + App Store
✅ 1. Prerequisites Setup (on macOS only)

MacBook or macOS VM (AWS EC2 Mac instance if you don’t have a Mac).

Installed:

Xcode (latest) from Mac App Store.

Flutter SDK (flutter doctor should show no issues).

CocoaPods (sudo gem install cocoapods).

An Apple Developer Account (enrolled in the $99/year Apple Developer Program).

✅ 2. Build iOS App from Flutter
cd your_flutter_project
flutter clean
flutter pub get
flutter build ipa --release


👉 This generates:

.xcarchive → iOS archive for submission.

.ipa → actual installable iOS app.
Stored inside:

build/ios/archive/
build/ios/ipa/

✅ 3. Configure iOS Project in Xcode

Open the iOS Runner project in Xcode:

open ios/Runner.xcworkspace


Then:

Go to Signing & Capabilities → Set your Apple team + unique bundle identifier (e.g., com.eira.health).

Ensure Deployment Target matches the minimum iOS you want (say iOS 13.0).

Update Info.plist with required permissions, e.g.:

<key>NSCameraUsageDescription</key>
<string>This app requires camera access to scan documents</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access for health assistant</string>

✅ 4. Archive & Upload with Xcode

In Xcode:

Select Product > Archive.

When done, the Organizer window opens.

Click Distribute App → Choose App Store Connect.

Validate, then Upload.
Your app goes to App Store Connect (Apple’s dashboard).

✅ 5. App Store Connect

Log in at App Store Connect
.

Create a new app record → enter name, SKU, bundle ID.

Add screenshots (iPhone/iPad), app icon, description, category, etc.

Choose your uploaded build → Submit for review.

⚡ Important Notes

Backend URL: Update _baseUrl in lib/api_service.dart to your EC2 backend http://16.171.29.159:8080 (or HTTPS if behind CloudFront).

HTTPS Requirement: Apple enforces ATS (App Transport Security). Your backend must be HTTPS or you’ll need an exception in Info.plist (not recommended for production).

Testing: You can distribute the .ipa via TestFlight for beta testing before going live.
