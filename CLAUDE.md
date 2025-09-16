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
- **IMPORTANT**: Tests that use SwiftData ModelContext require `@MainActor` annotation
- **Comprehensive Test Coverage**: 70+ test methods across all models
- **Test Data Factories**: Complete factory pattern for reliable test data
- **CRUD Testing**: Full Create/Read/Update/Delete operation coverage
- **Relationship Testing**: Bidirectional and cascade relationship verification
- **Async Testing**: Modern async/await patterns with proper isolation
- **Main Actor Isolation**: For SwiftData compatibility
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
│   ├── AccessibilityHelpers.swift # Accessibility model extensions and utilities
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

### Accessibility Features
- **WCAG AA Compliant**: Full accessibility support implemented in Phase 2
- **VoiceOver Support**: Complete navigation and interaction via VoiceOver
- **Dynamic Type**: Supports all text sizes from XS to XXXL
- **Accessibility Actions**: Task completion, editing, and navigation actions
- **Environment Detection**: Automatic detection of VoiceOver and accessibility settings
- **Accessibility Helpers**: Comprehensive utility extensions in `Extensions/AccessibilityHelpers.swift`
- **Color Contrast**: System colors ensure WCAG AA contrast ratios
- **Accessibility Testing**: Built-in testing framework for accessibility validation

## Development Notes
- All models are CloudKit-ready with proper schema configuration
- Test isolation ensures reliable, fast test execution with @MainActor patterns
- Factory pattern provides realistic test data across all scenarios
- Relationship testing verifies data integrity and cascade behavior
- Swift Testing framework properly configured for SwiftData compatibility
- **Accessibility-First Development**: All new UI components must include accessibility labels, hints, and actions
- **AccessibilityHelpers.swift**: Use existing model extensions for consistent accessibility implementation
- **VoiceOver Testing**: Test all new features with VoiceOver enabled during development

## IMPORTANT: MUST READ
- **DO NOT attempt runtime testing**: I will manually do the runtime testing by compiling and interacting with the app through the simulator.
- **BEFORE IMPLEMENTING ANYTHING**: reference Context7 MCP server to get up to date documentation on ANYTHING that is a part of the implementation.
