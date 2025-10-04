# 🐧 Eira Health Assistant - Linux Deployment Guide

This document explains how to build, run, and distribute the **Eira Health Assistant** as a native Linux desktop application.  
It applies to all major Linux distributions such as **Ubuntu**, **Fedora**, and **Debian**.

---

## 🧰 Prerequisites

To build the Linux application, you must be working from a Linux environment.

### 1. System Requirements
- **Operating System:** Ubuntu 20.04 LTS or later (recommended)
- **RAM:** Minimum 4 GB
- **Disk Space:** At least 2 GB free
- **Internet:** Required to download Flutter dependencies

### 2. Install Required Packages
These packages are needed for C++ build support:

```bash
sudo apt-get update
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev -y
3. Install and Configure Flutter

If you haven’t already set up Flutter for Linux desktop:

flutter config --enable-linux-desktop
flutter doctor


Ensure there are no issues under the "Linux toolchain" section.

🏗️ Building the Linux Application

The build process compiles Dart and C++ components into a single, self-contained executable.

Navigate to your project root directory:

cd path/to/EiraUIFlutter


Install all dependencies:

flutter pub get


Build the release version:

flutter build linux --release


Locate the build output:
The distributable files will be generated at:

build/linux/x64/release/bundle/

▶️ Running the Application

Run the compiled binary directly:

./build/linux/x64/release/bundle/eira_health_assistant

Folder Structure
bundle/
├── eira_health_assistant     # Main executable
├── data/                     # Flutter assets
└── lib/                      # Required libraries

📦 Distributing the Application
Option 1: Run Locally (Simple)

Copy the bundle/ folder to another machine and run the executable.

Option 2: System-Wide Installation (Recommended)

Install the app system-wide for easier access:

sudo cp -r build/linux/x64/release/bundle /opt/eira_health_assistant
sudo ln -s /opt/eira_health_assistant/eira_health_assistant /usr/local/bin/eira


Now you can launch it by typing:

eira

🧩 (Optional) Create a Desktop Shortcut

To make Eira appear in your app launcher:

nano ~/.local/share/applications/eira_health_assistant.desktop


Paste the following:

[Desktop Entry]
Type=Application
Name=Eira Health Assistant
Exec=/opt/eira_health_assistant/eira_health_assistant
Icon=/opt/eira_health_assistant/data/flutter_assets/assets/icon.png
Comment=AI-powered Health Monitoring App
Categories=Utility;


Then:

chmod +x ~/.local/share/applications/eira_health_assistant.desktop


You can now find Eira Health Assistant in your system menu.

🧱 (Optional) Create a .deb Package

If you want to distribute the app as a Debian package:

sudo apt install fakeroot dpkg-dev
cd build/linux/x64/release/
mkdir -p DEBIAN


Create a DEBIAN/control file:

Package: eira-health-assistant
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Your Name <your@email.com>
Description: Eira Health Assistant - AI-powered health monitoring desktop app


Then build the package:

dpkg-deb --build release eira-health-assistant.deb


You can now install it with:

sudo dpkg -i eira-health-assistant.deb

🌐 Backend Connection

Before building, ensure your Flutter app’s backend URL is correct.

Edit:

// lib/api_service.dart
final String _baseUrl = "http://16.171.29.159:8080";


Rebuild after editing:

flutter build linux --release

✅ Summary
Step	Description
1️⃣	Install dependencies and enable Linux desktop support
2️⃣	Build with flutter build linux --release
3️⃣	Run from build/linux/x64/release/bundle
4️⃣	(Optional) Install system-wide or create a .deb
5️⃣	(Optional) Add desktop shortcut
