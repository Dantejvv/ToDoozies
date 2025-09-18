# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
ToDoozies is an iOS todo application built with SwiftUI, SwiftData, and modern iOS frameworks. The app is designed to support both regular tasks and recurring habits with streak tracking and visualization.

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
- **Business Logic**: Streak tracking and visualization, recurrence patterns, progress calculation
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
│   ├── Calendar/                   # Calendar data models and utilities
│   ├── Export/                     # Export-related models (ICSEvent, etc.)
│   ├── Extensions/                 # Model extensions and computed properties
│   └── Protocols/                  # Data protocol definitions
├── Views/                          # SwiftUI views and components
│   ├── Components/                 # Reusable UI components
│   │   ├── AttachmentViews.swift   # File attachment UI components
│   │   ├── CategoryPickerView.swift # Unified category selection component with search and filtering
│   │   ├── RecurrencePickerView.swift # Comprehensive recurrence pattern picker with live preview
│   │   ├── Calendar/               # Calendar visualization components
│   │   └── ...                     # Other UI components
│   ├── Screens/                    # Main screen views (ContentView.swift, CalendarTabView.swift)
│   ├── Export/                     # Export-related views
│   └── Modifiers/                  # Custom view modifiers
├── ViewModels/                     # View model layer for UI state management
├── Navigation/                     # Modern SwiftUI navigation system
│   ├── NavigationDestinations.swift # Enum-based destinations and @Observable models
│   └── NavigationViewBuilder.swift # View factory and navigation modifiers
├── Features/                       # Feature modules
│   ├── Tasks/                      # Task-related functionality
│   ├── Habits/                     # Habit tracking features
│   └── Settings/                   # App settings and preferences
├── Extensions/                     # Swift extensions and utilities
│   ├── Foundation/                 # Foundation framework extensions
│   ├── SwiftUI/                    # SwiftUI framework extensions
│   ├── Resources/                  # Assets, colors, fonts, localization
│   │   ├── Colors/                 # Color definitions and themes
│   │   ├── Fonts/                  # Custom fonts
│   │   └── Localization/           # String localization files
│   ├── AccessibilityHelpers.swift # Accessibility model extensions and utilities
│   ├── DesignSystem.swift          # Design system constants and utilities
│   └── TaskAliases.swift           # Type aliases and utilities
├── Services/                       # Network, storage, notification services
│   ├── AttachmentService.swift     # File attachment management and storage
│   ├── CloudKitSyncService.swift   # CloudKit synchronization
│   ├── DIContainer.swift           # Dependency injection container
│   ├── HabitService.swift          # Habit tracking business logic
│   ├── NetworkMonitor.swift        # Network connectivity monitoring
│   ├── NotificationPermissionService.swift # Notification permissions
│   ├── TaskService.swift           # Task management business logic
│   ├── ThemeManager.swift          # App theming and appearance
│   └── Export/                     # Export services (ICS, etc.)
├── Assets.xcassets/                # App icons and images
├── ToDooziesApp.swift              # App entry point with SwiftData configuration
├── AppDelegate.swift               # App delegate for lifecycle management
├── Info.plist                     # App configuration
└── ToDoozies.entitlements          # App capabilities

ToDooziesTests/                     # Unit tests
ToDooziesUITests/                   # UI automation tests
docs/                               # Project documentation including feature specs and technical plans
```

### iOS Configuration
- Minimum deployment: iOS 17.6
- Supports iPhone and iPad (Universal)
- Foreground-only CloudKit sync (no background processing)
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

### Batch Operations System
- **Multi-Task Selection**: ✅ IMPLEMENTED - Users can select multiple tasks in edit mode
- **Custom Edit Button**: Uses custom implementation instead of SwiftUI's EditButton for reliable state management
- **Task Model Hashable Conformance**: Tasks conform to Hashable protocol for List selection support
- **Toolbar Integration**: Dynamic toolbar buttons that appear/disappear based on edit mode and selection state
- **Selection Management**:
  - Select All: Selects all visible tasks in current view
  - Deselect All: Clears all task selections
  - Individual Selection: Tap tasks to toggle selection state
- **Batch Actions**:
  - Batch Complete: Mark multiple selected tasks as complete
  - Batch Delete: Delete multiple selected tasks with confirmation dialog
- **UI Components**:
  - Top toolbar: Edit/Done button, Select All/Deselect All buttons
  - Bottom toolbar: Complete X, X selected count, Delete X buttons
- **Implementation Location**: `Views/Screens/TasksView.swift`
- **Key Technical Details**:
  - Uses `@State private var isEditingTasks` for custom edit mode management
  - List environment set to `.editMode(.active)` when in selection mode for multi-selection support
  - Task selection state managed via `@State private var selectedTasks = Set<UUID>()`

## Development Notes
- All models are CloudKit-ready with proper schema configuration
- Test isolation ensures reliable, fast test execution with @MainActor patterns
- Factory pattern provides realistic test data across all scenarios
- Relationship testing verifies data integrity and cascade behavior
- Swift Testing framework properly configured for SwiftData compatibility
- **Modern Hybrid Navigation**: Uses native SwiftUI APIs (iOS 16+) with platform-appropriate patterns - legacy NavigationCoordinator completely removed
- **No External Dependencies**: Navigation system built entirely with native SwiftUI - no third-party libraries required
- **NavigationStack Pattern**: All navigation modifiers must be applied within NavigationStack containers
- **Type-Safe Navigation**: Use enum destinations (`TaskDestination`, `HabitDestination`, `AppDestination`) for compile-time safety
- **Environment Injection**: Navigation models available via environment keys (`\.taskNavigation`, `\.habitNavigation`, `\.appNavigation`)
- **Navigation Pattern Selection**:
  - **Modal Sheets**: For creation flows (AddTaskView, AddHabitView) - uses direct sheet presentation with NavigationStack wrapper
  - **Hierarchical Navigation**: For list→detail→edit flows - uses navigationDestination() with enum-based routing
  - **Platform Consistency**: Follows iOS Human Interface Guidelines for modal vs push navigation
- **Accessibility-First Development**: All new UI components must include accessibility labels, hints, and actions
- **AccessibilityHelpers.swift**: Use existing model extensions for consistent accessibility implementation
- **VoiceOver Testing**: Test all new features with VoiceOver enabled during development

### Streak System
- **Core Functionality**: Tracks current and best streaks for habits
- **Visualization**: Uses flame icons and `StreakBadge` components
- **Protection Days**: 2 protection days per month to maintain streaks
- **Accessibility**: Special VoiceOver announcements for milestone streaks (7, 30, 100 days)
- **No Achievement System**: Focuses on simple streak tracking without complex systems

### Calendar Integration
- **Calendar Tab**: Dedicated calendar view with three visualization modes (✅ IMPLEMENTED)
- **Habit Heatmap**: GitHub-style intensity visualization showing completion patterns over time (✅ IMPLEMENTED)
- **Streak Chain**: Linear consecutive day visualization with flame indicators for active streaks (✅ IMPLEMENTED)
- **Task Calendar**: Monthly calendar with task indicators, priority markers, and completion status (✅ IMPLEMENTED)
- **Interactive Elements**: Date selection, month navigation, habit switching, time range selection (✅ IMPLEMENTED)
- **Data Integration**: Full integration with existing Task and Habit models (✅ IMPLEMENTED)
- **Accessibility**: Complete VoiceOver support with descriptive labels and navigation actions (✅ IMPLEMENTED)
- **Design Consistency**: Follows established 8pt grid and card-based design system (✅ IMPLEMENTED)
- **ICS Export**: Basic calendar export functionality with iOS share sheet integration (✅ IMPLEMENTED)
- **Mini Calendar Views**: Integrated calendar previews within HabitsView (✅ IMPLEMENTED)

### Picker Components System
- **CategoryPickerView**: Unified category selection component with search functionality (✅ IMPLEMENTED)
- **RecurrencePickerView**: Comprehensive recurrence pattern picker with progressive disclosure (✅ IMPLEMENTED)
- **Multi-Section Design**: Frequency selection, interval configuration, weekday/monthly options (✅ IMPLEMENTED)
- **Real-Time Validation**: Live form validation with user-friendly error messages (✅ IMPLEMENTED)
- **Live Preview**: Shows next occurrence dates for recurrence patterns (✅ IMPLEMENTED)
- **Search & Filter**: Category picker includes real-time search and filtering (✅ IMPLEMENTED)
- **Accessibility**: Complete VoiceOver support with descriptive labels and interaction hints (✅ IMPLEMENTED)
- **Design Consistency**: Follows established SwiftUI patterns and 8pt grid system (✅ IMPLEMENTED)

### Navigation Architecture (September 2025)
- **Modern Hybrid Navigation**: Best-practice approach using appropriate navigation patterns for different flows (✅ IMPLEMENTED)
- **Enum-Based Destinations**: Type-safe navigation with `TaskDestination`, `HabitDestination`, `AppDestination` (✅ IMPLEMENTED)
- **@Observable Navigation Models**: Feature-specific navigation state management with `TaskNavigationModel`, `HabitNavigationModel`, `AppNavigationModel` (✅ IMPLEMENTED)
- **NavigationStack Integration**: Proper `navigationDestination(item:)` usage for hierarchical navigation (detail/edit flows) (✅ IMPLEMENTED)
- **Hybrid Sheet Presentation**: Direct sheet presentation for creation flows, modern navigation for hierarchical flows (✅ IMPLEMENTED)
- **Platform-Appropriate Patterns**: Modal sheets for temporary creation flows, navigationDestination for list→detail→edit flows (✅ IMPLEMENTED)
- **Environment Injection**: Dedicated environment keys for navigation models with DIContainer integration (✅ IMPLEMENTED)
- **Legacy Coordinator Removal**: NavigationCoordinator completely removed from codebase - fully modernized (✅ IMPLEMENTED)
- **Navigation View Builder**: Centralized view factory system for destination rendering (✅ IMPLEMENTED)
- **Task Creation Fix**: Resolved dual navigation system causing double loading animations (✅ IMPLEMENTED)
- **Status**: ✅ FULLY IMPLEMENTED

### Recently Completed Features (September 2025)
- **Navigation System Modernization**: Complete refactoring to use native SwiftUI navigation APIs with type-safe enum-based destinations (✅ IMPLEMENTED)
- **NavigationCoordinator Removal**: Legacy navigation coordinator completely removed from entire codebase (✅ IMPLEMENTED)
- **Picker Components System**: Complete implementation of CategoryPickerView and RecurrencePickerView (✅ IMPLEMENTED)
- **Text Size Settings Navigation**: Interactive button to open iOS system settings for Dynamic Type adjustment (✅ IMPLEMENTED)
- **Task Creation Navigation Fix**: Resolved dual navigation system bug causing double loading animations in task creation flow (✅ IMPLEMENTED)
- **TodayView Read-Only Mode**: Converted TodayView to display-only, removing all task/habit interaction capabilities (✅ IMPLEMENTED)

### Offline Mode UI Feedback
- **NetworkMonitor Service**: Real-time connectivity detection using Apple's Network framework (✅ IMPLEMENTED)
- **OfflineToast Component**: Temporary notifications for connectivity state changes with auto-dismiss (✅ IMPLEMENTED)
- **OfflineBanner Component**: Persistent banner showing offline status and pending changes count (✅ IMPLEMENTED)
- **Enhanced SyncStatusView**: Combined sync progress and offline status display (✅ IMPLEMENTED)
- **Pending Changes Tracking**: Automatic counting of local modifications when offline (✅ IMPLEMENTED)
- **Manual Retry Functionality**: User-initiated sync attempts when connectivity returns (✅ IMPLEMENTED)
- **Progressive UI Feedback**: Toast → Banner → Persistent status indicator pattern (✅ IMPLEMENTED)
- **Accessibility Integration**: Full VoiceOver support with descriptive offline status announcements (✅ IMPLEMENTED)
- **Service Integration**: TaskService and HabitService automatically track offline changes (✅ IMPLEMENTED)

### Settings & User Preferences
- **App Appearance**: Theme selector (System/Light/Dark) with @AppStorage persistence and real-time switching (✅ IMPLEMENTED)
- **Enhanced iCloud Sync**: Expanded sync status display with auto-sync preferences and manual retry (✅ IMPLEMENTED)
- **Notification Management**: UNUserNotificationCenter permission handling, status display, and basic preferences (✅ IMPLEMENTED)
- **Data Management**: Direct access to ICS export, app data summary, and offline status display (✅ IMPLEMENTED)
- **Accessibility Preferences**: VoiceOver announcements, reduce animations, and Dynamic Type size display (✅ IMPLEMENTED)
- **App Information**: Version display, privacy policy, and support links (✅ IMPLEMENTED)
- **Interactive Settings Navigation**: Text Size setting with direct iOS Settings navigation (✅ IMPLEMENTED)
- **Persistent Storage**: @AppStorage integration for all user preferences with automatic UI updates (✅ IMPLEMENTED)
- **Theme Manager Service**: Centralized theme management with ColorScheme handling (✅ IMPLEMENTED)
- **Notification Permission Service**: Comprehensive permission state management with system integration (✅ IMPLEMENTED)

### Attachment System
- **Data Model**: Complete SwiftData model with CloudKit integration (Attachment.swift)
- **Service Layer**: Full AttachmentService with file management, thumbnail generation, and validation
- **UI Components**: Complete attachment management in AddTaskView and TaskDetailView
- **File Picker**: SwiftUI fileImporter integration with multi-file selection
- **File Types**: Images (PNG, JPEG, HEIC, GIF), Documents (PDF, TXT, RTF), Audio (MP3, WAV), Video (MP4, MOV), Office files
- **Storage**: App sandbox structure (`Documents/Attachments/{taskId}/`) with CloudKit sync
- **Features**: Thumbnail generation, file size validation, security-scoped resource handling
- **File Size Limits**: Images (25MB), Documents (50MB), Audio/Video (100MB)
- **Status**: ✅ FULLY IMPLEMENTED

### Habit Management System
- **Habit Details Page**: Complete habit detail view with comprehensive statistics and interaction (✅ IMPLEMENTED)
- **Core Components**:
  - **HabitDetailView**: Rich interactive UI with statistics dashboard, calendar, and management actions
  - **HabitDetailViewModel**: Modern @Observable implementation with full habit tracking capabilities
  - **AddHabitView/ViewModel**: Complete habit creation flow with form validation and category selection
  - **EditHabitView/ViewModel**: Full habit editing functionality with change detection and validation
- **Interactive Features**:
  - **Statistics Dashboard**: Current/best streak, completion rate, weekly averages, monthly progress
  - **Monthly Calendar**: Interactive tap-to-toggle completion dates with visual indicators
  - **Protection Days**: 2 protection days per month system with usage tracking and availability display
  - **Streak Visualization**: StreakBadge components with flame icons for current and best streaks
- **Navigation Integration**: Seamless routing through modern enum-based navigation from HabitsView → HabitDetail → EditHabit
- **Service Layer**: Enhanced HabitServiceProtocol with completion tracking, protection day usage, and CRUD operations
- **Accessibility**: Complete VoiceOver support with descriptive labels, values, and interaction hints
- **Data Integrity**: Robust delete confirmation with clear consequences explanation for habit and associated task data
- **UI/UX Consistency**: Follows established design system with 8pt grid, card layouts, and consistent color schemes
- **Validation System**: Shared ValidationError enum across all view models for consistent form validation
- **Status**: ✅ FULLY IMPLEMENTED

### TodayView Dashboard (September 2025)
- **Read-Only Display Mode**: TodayView converted to pure information display without interaction capabilities (✅ IMPLEMENTED)
- **Core Display Features**:
  - **Today's Tasks**: Shows all tasks scheduled for today with completion status indicators (✅ IMPLEMENTED)
  - **Overdue Tasks**: Displays overdue tasks with warning indicators and timestamps (✅ IMPLEMENTED)
  - **Daily Habits**: Shows recurring habits/tasks with progress tracking and flame icons (✅ IMPLEMENTED)
  - **Tomorrow Preview**: Limited preview of upcoming tasks for next day planning (✅ IMPLEMENTED)
  - **Daily Summary**: Greeting text, date display, and overall completion statistics (✅ IMPLEMENTED)
- **Read-Only Components**:
  - **ReadOnlyTaskRowView**: Task display with read-only completion status indicators (✅ IMPLEMENTED)
  - **ReadOnlyHabitTaskRowView**: Habit display with read-only flame icons and streak information (✅ IMPLEMENTED)
- **Removed Interactive Elements**:
  - ❌ Add Task button removed from toolbar
  - ❌ Task completion toggle functionality removed
  - ❌ Task editing and context menu options removed
  - ❌ Habit interaction and completion tracking removed
  - ❌ Navigation to task creation/editing flows removed
- **Design Philosophy**: Pure information dashboard focusing on awareness without action, directing users to dedicated Tasks/Habits tabs for interactions
- **Status**: ✅ FULLY IMPLEMENTED

### Console Output & Debugging
- **Navigation Warnings**: All navigationDestination misplacement warnings have been resolved (✅ FIXED)
- **CloudKit Messages**: Expected console messages when no iCloud account is configured:
  - `CloudKit: No iCloud account available. Using local storage only.` (NORMAL)
  - `CoreData+CloudKit: Failed to set up CloudKit integration...` (NORMAL)
  - `Could not validate account info cache.` (NORMAL)
- **Simulator Warnings**: `load_eligibility_plist: Failed to open .../eligibility.plist` (IGNORE - simulator-only)
- **Background Mode**: Required `remote-notification` background mode configured in Info.plist for CloudKit sync
- **Build Success**: Project builds without errors and runs successfully on iOS 17.6+ simulators

## IMPORTANT: MUST READ
- **DO NOT attempt runtime testing**: I will manually do the runtime testing by compiling and interacting with the app through the simulator.
- **BEFORE IMPLEMENTING ANYTHING**: reference Context7 MCP server to get up to date documentation on ANYTHING that is a part of the implementation.
