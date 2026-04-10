# LiTasker

LiTasker is a local-first Flutter task manager with a bold neo-brutalism interface. It focuses on fast task capture, practical list organization, calendar-based planning, and simple backup/export workflows.

LiTasker 是一个本地优先的 Flutter 任务管理应用，采用鲜明的 neo-brutalism 视觉风格，强调快速记录任务、清晰组织列表、用日历安排事项，以及简单直接的数据备份与恢复。

![LiTasker Icon](lib/11a7da6ddae72513d88438305757b3ff.png)

## Overview

- Built with Flutter and Dart
- Stores data locally with Hive
- Supports task lists, smart views, and calendar browsing
- Includes JSON import/export for backup and migration
- Designed around a distinctive desktop-and-mobile friendly UI

## 项目简介

- 使用 Flutter 与 Dart 构建
- 基于 Hive 进行本地数据持久化
- 支持任务列表、智能视图和日历浏览
- 提供 JSON 导入导出，方便备份与迁移
- 保留了鲜明的 neo-brutalism 风格，兼顾桌面端与移动端体验

## Features

- Local-first task storage with no required backend
- Smart views such as Inbox, Today, and Next 7 Days
- Custom task lists with icon and color settings
- Task priority, completion state, and detail editing
- Calendar mode for planning and reviewing tasks
- Quick-add flow for faster task entry
- JSON backup import/export using a file picker

## 功能特性

- 本地优先，无需后端即可使用
- 提供 Inbox、Today、Next 7 Days 等智能视图
- 支持自定义任务列表、图标和颜色
- 支持任务优先级、完成状态和详情编辑
- 提供日历模式，便于按时间查看和安排任务
- 支持快速新增任务
- 支持通过文件选择器导入导出 JSON 备份

## Tech Stack

- Flutter
- Dart
- Hive / hive_flutter
- file_picker
- flutter_markdown
- shared_preferences
- lucide_icons

## Project Structure

```text
lib/
  main.dart
  enums.dart
  models/
    task.dart
    task.g.dart
    task_list.dart
    task_list.g.dart
  screens/
    neo_home_page.dart
    neo_home_page_calendar.dart
    neo_home_page_detail.dart
    neo_home_page_misc.dart
    neo_home_page_widgets.dart
  utils/
    neo_brutalism.dart
    priority_color.dart
```

## App Flow

1. Launch the app.
2. Create or select a list.
3. Add a task with title, detail, date, and priority.
4. Switch between smart views and calendar view.
5. Export data to JSON when you want a backup.

## 使用流程

1. 启动应用。
2. 创建或选择任务列表。
3. 新增任务，并填写标题、详情、日期和优先级。
4. 在智能视图和日历视图之间切换查看任务。
5. 需要备份时导出为 JSON 文件。

## Getting Started

### Prerequisites

- Flutter SDK
- A supported IDE such as VS Code or Android Studio
- A simulator, emulator, or physical device

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Regenerate Hive adapters

Run this if the model fields change:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Regenerate launcher icons

Launcher icons are configured in `pubspec.yaml`:

```bash
flutter pub run flutter_launcher_icons
```

## Data Storage

- Hive box `tasks`: stores task records
- Hive box `taskLists`: stores custom list metadata

All task data stays on-device unless you explicitly export it.

## Repository Status

The project is currently maintained as a single Flutter app with modularized screen files under `lib/screens`. The current codebase is intended to be runnable and analyzable as-is.

## Roadmap Ideas

- Better recurring task support
- Improved backup preview and conflict handling
- More polished onboarding and empty states
- Additional desktop interaction refinements

## License

No license file is included yet. Add one before public distribution if needed.
