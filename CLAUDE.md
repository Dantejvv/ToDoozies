# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
ToDoozies is an iOS todo application built with SwiftUI, SwiftData, and modern iOS frameworks. The app is designed to support both regular tasks and recurring habits with streak tracking.

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project ToDoozies.xcodeproj -scheme ToDoozies build -destination 'platform=iOS Simulator,name=iPhone 16'

# Run unit tests
xcodebuild test -project ToDoozies.xcodeproj -scheme ToDoozies -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -project ToDoozies.xcodeproj -scheme ToDoozies -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ToDooziesUITests

# Available simulator destinations (iOS 18.6):
# - iPhone 16, iPhone 16 Plus, iPhone 16 Pro, iPhone 16 Pro Max
# - iPad (A16), iPad Air 11-inch (M3), iPad Pro 11-inch (M4), iPad mini (A17 Pro)
```

### Testing Framework
- Uses Swift Testing framework (not XCTest)
- Test files use `@Test` attributes and `#expect(...)` assertions
- **Comprehensive Test Coverage**: 70+ test methods across all models
- **Test Data Factories**: Complete factory pattern for reliable test data
- **CRUD Testing**: Full Create/Read/Update/Delete operation coverage
- **Relationship Testing**: Bidirectional and cascade relationship verification
- **Async Testing**: Modern async/await patterns with proper isolation
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
- **Core Models**: Task, RecurrenceRule, Habit, Category, Subtask, Attachment
- **Relationships**: Proper cascade/nullify delete rules configured
- **Business Logic**: Streak tracking, recurrence patterns, progress calculation
- `ModelContainer` configured in `ToDooziesApp.swift` with CloudKit sync and shared app group
- Supports both local storage and automatic iCloud sync via private CloudKit database
- CloudKit container: `iCloud.dante.ToDoozies`
- App group: `group.dante.ToDoozies` for widget data sharing

### Project Structure
The codebase follows an organized folder structure for maintainability and scalability:

```
ToDoozies/                           # Main app target
├── Models/                          # Data models and business logic
│   ├── Core/                       # Core data models (Task, Habit, Category, etc.)
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

### Key Features
**✅ Implemented (Phase 1 - Core Data Layer):**
- SwiftData models with CloudKit integration
- Task management with priority levels and due dates
- Habit tracking with streak calculation and protection days
- Recurring task patterns (daily, weekly, monthly, custom)
- Subtasks and file attachments
- Category organization
- Comprehensive test coverage

**🔄 Planned (Phase 2+ - UI Implementation):**
- SwiftUI user interface
- Natural language input
- Widgets and notifications
- Advanced UI features

### iOS Configuration
- Minimum deployment: iOS 17.6
- Supports iPhone and iPad (Universal)
- Background modes enabled for remote notifications
- App groups configured for widget data sharing (`group.dante.ToDoozies`)
- Comprehensive permission descriptions in Info.plist for:
  - Notifications, Siri & Shortcuts, Calendar, Reminders, Location, Speech Recognition
- Custom SF Symbols catalog with ToDoozies-specific icons
- App icons configured for light/dark/tinted modes with checklist theme
- Launch screen with branded design
- Uses SF Symbols for icons
- Follows Apple's Human Interface Guidelines

## Current Implementation Status

### ✅ Phase 1: Core Data Layer (Complete)
**SwiftData Models:**
- `Task.swift`: Core task model with properties, relationships, and business logic
- `RecurrenceRule.swift`: Complex recurrence patterns with next occurrence calculation
- `Habit.swift`: Habit tracking with streak management and protection days
- `Category.swift`: Task organization with progress tracking
- `Subtask.swift`: Task breakdown with ordering and completion status
- `Attachment.swift`: File attachments with type classification

**Data Persistence:**
- SwiftData ModelContainer with CloudKit integration
- CRUD operations for all models
- Relationship integrity (cascade/nullify delete rules)
- In-memory testing with isolated containers

**Testing Foundation:**
- 70+ test methods using Swift Testing framework
- Comprehensive test data factories for all models
- CRUD operation testing with ModelContext
- Relationship integrity and cascade deletion testing
- Async testing patterns following 2024/2025 best practices

### 🔄 Next Phase: Core UI Implementation
Ready to begin Phase 2 with:
- Model-View architecture setup
- @Observable classes for shared state
- SwiftUI views (TodayView, TaskListView, HabitsView)
- Navigation coordinator
- Liquid Glass design system implementation

## Development Notes
- All models are CloudKit-ready with proper schema configuration
- Test isolation ensures reliable, fast test execution
- Factory pattern provides realistic test data across all scenarios
- Relationship testing verifies data integrity and cascade behavior
- Ready for UI layer implementation with confidence in data layer stability