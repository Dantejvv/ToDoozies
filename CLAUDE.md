# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
ToDoozies is an iOS todo application built with SwiftUI, SwiftData, and modern iOS frameworks. The app is designed to support both regular tasks and recurring habits with streak tracking.

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project ToDoozies.xcodeproj -scheme ToDoozies build

# Run unit tests
xcodebuild test -project ToDoozies.xcodeproj -scheme ToDoozies -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project ToDoozies.xcodeproj -scheme ToDoozies -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ToDooziesUITests
```

### Testing Framework
- Uses Swift Testing framework (not XCTest)
- Test files use `@Test` attributes and `#expect(...)` assertions
- Unit tests: `ToDooziesTests/ToDooziesTests.swift`
- UI tests: `ToDooziesUITests/ToDooziesUITests.swift`

## Architecture

### Core Technologies
- **SwiftUI**: Declarative UI framework
- **SwiftData**: Core Data successor for data persistence
- **CloudKit**: Planned for cross-device sync
- **Swift Testing**: Modern testing framework
- **Model-View (MV)**: Architecture pattern

### Data Model
- Uses SwiftData with `@Model` classes
- `Item.swift`: Basic data model with timestamp (placeholder for full todo structure)
- `ModelContainer` configured in `ToDooziesApp.swift`
- Supports both in-memory and persistent storage

### Project Structure
- `ToDoozies/`: Main app target
  - `ToDooziesApp.swift`: Main app entry point with SwiftData configuration
  - `ContentView.swift`: Primary UI view with navigation
  - `Item.swift`: Data model classes
- `ToDooziesTests/`: Unit tests
- `ToDooziesUITests/`: UI automation tests
- `docs/`: Project documentation including feature specs and technical plans

### Key Features (Planned)
- Regular and recurring tasks
- Habit tracking with streaks
- Natural language input
- Offline support with sync
- Widgets and notifications
- Priority levels and due dates
- Subtasks and attachments

### iOS Configuration
- Minimum deployment: iOS 17.6
- Supports iPhone and iPad (Universal)
- Background modes enabled for remote notifications
- Uses SF Symbols for icons
- Follows Apple's Human Interface Guidelines