# Budget App – Flutter

Mobile app for budgeting and financial tracking.

## Tech
- Flutter (Dart) – iOS/Android (web target scaffolded too)
- Xcode/iOS Simulator for local iOS runs
- Android Studio (optional, for Android builds later)

## Quick Start

### Prereqs
- Flutter SDK (`flutter doctor` should pass)
- macOS: Xcode installed, iOS Simulator runtimes installed (Xcode → Settings → Platforms → iOS 17.x Simulator)
- VS Code (optional): Flutter + Dart extensions

### Run (iOS Simulator)
```bash
git clone https://github.com/1e1ouch/Budget-App.git
cd Budget-App
flutter pub get
open -a Simulator   # or open Xcode → Window → Devices and Simulators → Boot a device
flutter devices     # confirm simulator shows up
flutter run
