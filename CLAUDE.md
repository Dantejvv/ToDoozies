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
- **CloudKit**: Enabled for automatic cross-device sync
- **Swift Testing**: Modern testing framework
- **Model-View (MV)**: Architecture pattern

### Data Model
- Uses SwiftData with `@Model` classes integrated with CloudKit
- `Models/Core/Item.swift`: Basic data model with timestamp (placeholder for full todo structure)
- `ModelContainer` configured in `ToDooziesApp.swift` with CloudKit sync
- Supports both local storage and automatic iCloud sync via private CloudKit database
- CloudKit container: `iCloud.dante.ToDoozies`

### Project Structure
The codebase follows an organized folder structure for maintainability and scalability:

```
ToDoozies/                           # Main app target
├── Models/                          # Data models and business logic
│   ├── Core/                       # Core data models (Item.swift)
│   ├── Extensions/                 # Model extensions and computed properties
│   └── Protocols/                  # Data protocol definitions
├── Views/                          # SwiftUI views and components
│   ├── Components/                 # Reusable UI components
│   ├── Screens/                    # Main screen views (ContentView.swift)
│   └── Modifiers/                  # Custom view modifiers
├── Features/                       # Feature modules
│   ├── Tasks/                      # Task-related functionality
│   ├── Habits/                     # Habit tracking features
│   └── Settings/                   # App settings and preferences
├── Resources/                      # Assets, colors, fonts
│   ├── Colors/                     # Color definitions and themes
│   ├── Fonts/                      # Custom fonts
│   └── Localization/               # String localization files
├── Extensions/                     # Swift extensions and utilities
│   ├── Foundation/                 # Foundation framework extensions
│   ├── SwiftUI/                    # SwiftUI framework extensions
│   └── Utilities/                  # General utility functions
├── Services/                       # Network, storage, notification services
│   ├── Data/                       # Data persistence and sync
│   ├── Notifications/              # Push notifications and reminders
│   └── Network/                    # API and network operations
├── Assets.xcassets/                # App icons and images
├── ToDooziesApp.swift              # App entry point with SwiftData configuration
├── Info.plist                     # App configuration
└── ToDoozies.entitlements          # App capabilities

ToDooziesTests/                     # Unit tests
ToDooziesUITests/                   # UI automation tests
docs/                               # Project documentation including feature specs and technical plans
```

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