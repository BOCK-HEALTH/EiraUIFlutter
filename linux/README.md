# Eira Health Assistant - Linux Deployment Guide

This folder contains the source code and configuration specific to building a native desktop application for Linux distributions (like Ubuntu, Fedora, etc.).

## Prerequisites

To build the Linux application, you must be working from a Linux development environment.

1.  **A Linux Machine:** Ubuntu 20.04 LTS or later is recommended.
2.  **Flutter SDK:** Ensure you have the Flutter SDK installed and configured for Linux development.
3.  **Linux Development Dependencies:** You must install several packages required for building C++ applications. Run the following command to install them:
    ```bash
    sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
    ```
4.  **Enable Linux Desktop Support:** If you haven't already, enable Flutter's desktop support:
    ```bash
    flutter config --enable-linux-desktop
    ```
5.  **Verify Setup:** Run `flutter doctor` and ensure there are no issues under the "Linux toolchain" section.

## Building the Linux Application for Release

The build process will compile your Dart code and C++ shell into a self-contained executable application.

1.  **Navigate to the project root directory** in your terminal.

2.  **Ensure all dependencies are up to date:**
    ```bash
    flutter pub get
    ```

3.  **Run the build command:**
    ```bash
    flutter build linux
    ```

4.  **Locate the Output:** The complete, distributable application will be generated in the following directory:
    ```
    build/linux/x64/release/bundle/
    ```

## How to Run and Distribute the Application

Inside the `bundle/` directory, you will find everything needed to run the application:
*   The main **executable file** (named after your project, e.g., `eira_health_assistant`).
*   A `lib/` directory containing required libraries.
*   A `data/` directory containing your Flutter assets (images, fonts, etc.).

**To Run:**
You can run the application directly from the terminal:
```bash
./build/linux/x64/release/bundle/eira_health_assistant
