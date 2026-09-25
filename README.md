# Santian

Offline-first tasks app (and, later, a clockface). Flutter, Android only.

## Installation

### Prerequisites

- [Git](https://git-scm.com/)
- [Flutter](https://docs.flutter.dev/get-started/install) stable, Dart SDK `^3.11.1` (verified with Flutter 3.41.4)
- Android SDK + platform-tools (via Android Studio), and either an Android emulator (AVD) or a physical device with USB debugging on

Check your toolchain:

```bash
flutter doctor
```

### 1. Clone

```bash
git clone https://github.com/arcbyte-lab/Santian.git
cd Santian
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run

Start an emulator (or plug in a device), then:

```bash
flutter emulators --launch <emulator_id>   # list ids with: flutter emulators
flutter run
```

The first build is a cold Gradle build and can take several minutes.

### Build an APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Install it with `adb install <path>`.

## Development

Run tests:

```bash
flutter test
```

Tests download the Isar native core (`libisar.*`) into the repo root on first run; it's gitignored.

Regenerate Isar models after changing anything in `lib/tasks/models/` (the generated `*.g.dart` files are committed):

```bash
dart run build_runner build --delete-conflicting-outputs
```
