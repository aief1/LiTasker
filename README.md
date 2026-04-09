# LiTasker

LiTasker is a Flutter task manager with a bold neo-brutalism UI style.  
It stores data locally with Hive and supports list view, calendar view, and JSON backup import/export.

## Features

- Local-first task storage using Hive.
- Smart views: Inbox, Today, and Next 7 Days.
- Custom task lists with icon and color.
- Task priority and completion status management.
- Calendar mode (month/week/day switch in UI).
- Quick add task flow.
- JSON backup export/import via file picker.

## Tech Stack

- Flutter (Material 3)
- Dart
- Hive / hive_flutter
- file_picker
- flutter_markdown

## Project Structure

```text
lib/
  main.dart
  enums.dart
  models/
    task.dart
    task_list.dart
  screens/
    neo_home_page.dart
  utils/
    neo_brutalism.dart
    priority_color.dart
```

## Getting Started

### 1. Prerequisites

- Flutter SDK installed
- A supported IDE (VS Code / Android Studio)
- Device emulator or physical device

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

```bash
flutter run
```

## Data Storage

- Hive box `tasks`: stores all task records.
- Hive box `taskLists`: stores custom list metadata.

Data stays on-device unless you manually export/import a backup JSON file.

## Build Notes

- App icon generation is configured through `flutter_launcher_icons` in `pubspec.yaml`.
- If model classes change, regenerate Hive adapters:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Current Repository Status

This repository currently includes ongoing UI refactor changes (legacy files removed and `neo_home_page.dart` introduced).  
If `flutter analyze` reports syntax errors, complete the pending refactor before preparing a production release.

## License

No license file is included yet. Add one before public distribution if needed.
