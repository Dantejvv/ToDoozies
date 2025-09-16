# Product Requirements Document
## iOS Todo App with Habit Tracking - "ToDoozies"

---

## Executive Summary

**ToDoozies** is a native iOS application that revolutionizes personal productivity by seamlessly blending traditional task management with powerful habit formation tools. Built on Apple's latest technology stack, the app addresses the fundamental human need to not only manage one-time tasks but also build and maintain positive habits through scientifically-proven streak mechanics and motivational design patterns.

The application leverages Swift 6.2, SwiftUI, and SwiftData with CloudKit synchronization to deliver a premium experience that feels native to iOS while providing instant cross-device synchronization. By focusing on the psychological drivers of habit formation—visual progress tracking, milestone celebrations, and forgiveness mechanisms—ToDoozies transforms the mundane act of task completion into an engaging journey of personal growth.

**Core Value Proposition**: Empower users to achieve both immediate productivity goals and long-term behavioral change through an intuitive, motivating, and visually delightful task management experience that seamlessly integrates with Apple's ecosystem.

---

## Problem Statement

### Primary Problem
Modern professionals and individuals struggle with two distinct but interconnected challenges:
1. **Task Overload**: Managing an ever-growing list of one-time tasks, deadlines, and commitments across work and personal life
2. **Habit Inconsistency**: Difficulty in establishing and maintaining positive habits despite understanding their long-term benefits

### Current Solution Gaps
Existing task management applications typically fall into two categories:
- **Traditional Todo Apps**: Excel at one-time task management but lack robust habit tracking and motivational mechanics
- **Habit Trackers**: Focus exclusively on recurring behaviors but fail to integrate with daily task workflows

This fragmentation forces users to maintain multiple applications, leading to:
- Context switching fatigue
- Incomplete productivity pictures
- Reduced motivation due to scattered progress tracking
- Synchronization issues across devices
- Lack of unified productivity metrics

### User Pain Points
1. **Cognitive Load**: Managing tasks and habits in separate systems increases mental overhead
2. **Motivation Decay**: Without visual progress indicators and achievement systems, users lose momentum
3. **Rigid Systems**: Most apps don't account for life's unpredictability (missed days, schedule changes)
4. **Poor Integration**: Limited connection with iOS ecosystem features (widgets, Siri, Focus modes)
5. **Data Silos**: Inability to see correlations between task completion and habit success

---

## Target Audience

### Primary Personas

#### 1. The Ambitious Professional (Sarah, 32)
**Demographics**: Urban professional, tech-savvy, iOS ecosystem user
**Goals**: 
- Balance demanding work projects with personal development
- Build consistent morning routines
- Track both work deliverables and health habits

**Pain Points**:
- Juggling multiple project deadlines
- Struggling to maintain exercise routine during busy periods
- Needs quick task entry during meetings

**Use Cases**:
- Voice-adding tasks while commuting
- Checking morning routine progress via widget
- Setting up recurring team check-ins

#### 2. The Habit Builder (Marcus, 28)
**Demographics**: Health-conscious individual, self-improvement focused
**Goals**:
- Establish consistent workout routine
- Track meditation practice
- Build reading habit

**Pain Points**:
- Loses motivation after breaking streaks
- Overwhelmed by ambitious habit goals
- Needs flexibility for travel/illness

**Use Cases**:
- Tracking multiple habit streaks simultaneously
- Reviewing monthly progress patterns
- Setting up forgiveness days for planned breaks

#### 3. The Student Organizer (Alex, 21)
**Demographics**: University student, digital native
**Goals**:
- Manage coursework deadlines
- Build study habits
- Balance academic and personal life

**Pain Points**:
- Inconsistent study schedule
- Procrastination on large projects
- Difficulty building daily routines

**Use Cases**:
- Breaking down assignments into subtasks
- Setting up daily study session reminders
- Tracking assignment completion rates

### Secondary Personas

#### 4. The Family Coordinator (James, 45)
**Demographics**: Parent, household manager
**Goals**:
- Coordinate family schedules
- Track household tasks
- Model good habits for children

**Use Cases**:
- Setting up recurring household chores
- Managing family member tasks
- Quick task entry via Siri

#### 5. The Creative Professional (Maya, 35)
**Demographics**: Freelancer/creative worker
**Goals**:
- Manage client projects
- Maintain creative practice habits
- Track business tasks

**Use Cases**:
- Color-coding tasks by client
- Tracking daily creative practice
- Managing invoice reminders

---

## Feature Specifications

### 1. Task Management Core

#### 1.1 Task Creation
**Functional Requirements**:
- Single-tap task creation with minimal required fields (title only)
- Natural language processing for due dates ("tomorrow at 3pm", "next Monday")
- Voice input support through iOS speech recognition
- Quick add widget for home screen

**Acceptance Criteria**:
- Task creation completes in < 2 seconds
- Natural language parser recognizes 95% of common date/time phrases
- Voice input accuracy matches iOS system performance
- Widget loads in < 500ms

**User Story**:
*As a busy professional, I want to quickly add tasks using natural language so that I can capture thoughts without interrupting my workflow.*

#### 1.2 Task Properties
**Functional Requirements**:
- Title (required, max 200 characters)
- Description/notes (optional, rich text support)
- Due date and time (optional, with timezone support)
- Priority levels (High/Medium/Low with visual indicators)
- Completion status (Not Started/In Progress/Complete)
- File attachments (photos, documents, max 10MB per file)

**Acceptance Criteria**:
- All properties persist across device sync
- Priority changes reflect immediately in UI
- Attachments upload in background without blocking UI
- Rich text supports bold, italic, bullet points

**User Story**:
*As a project manager, I want to attach relevant documents to tasks so that all context is available when I need to complete the work.*

#### 1.3 Subtasks/Checklists
**Functional Requirements**:
- Unlimited subtasks per main task
- Independent completion tracking
- Reorderable via drag and drop
- Batch operations (mark all complete/incomplete)
- Progress indicator on parent task

**Acceptance Criteria**:
- Subtask completion updates parent progress in real-time
- Drag and drop responds within 100ms
- Parent task shows completion percentage
- Subtasks maintain order across sync

**User Story**:
*As a student, I want to break down large assignments into smaller steps so that I can track my progress and avoid feeling overwhelmed.*

#### 1.4 Search and Filter
**Functional Requirements**:
- Full-text search across task titles and descriptions
- Filter by: completion status, priority, due date range, tags
- Saved filter presets
- Search history
- Smart suggestions based on usage patterns

**Acceptance Criteria**:
- Search results appear within 200ms
- Filters combine with AND/OR logic
- Maximum 10 saved presets
- Search indexes update in background

**User Story**:
*As a team lead, I want to quickly find all high-priority tasks due this week so that I can focus on critical deliverables.*

### 2. Habit & Streak System

#### 2.1 Recurring Task Configuration
**Functional Requirements**:
- Recurrence patterns: Daily, Weekly (with day selection), Monthly (date or day), Custom
- Time-based triggers with notification support
- Start and end dates for recurring series
- Skip specific instances without breaking pattern

**Acceptance Criteria**:
- Custom patterns support complex rules (every 3 days, weekdays only)
- Modifications to single instance don't affect series
- Future instances generate automatically for 30 days ahead
- Time zones handled correctly for travelers

**User Story**:
*As a fitness enthusiast, I want to set up workout reminders for specific days so that I maintain consistency in my routine.*

#### 2.2 Streak Tracking
**Functional Requirements**:
- Visual streak counter with flame icon
- Current streak and best streak tracking
- Streak freeze/protection days (2 per month)
- Streak recovery within 24 hours of miss
- Multi-habit streak overview dashboard

**Acceptance Criteria**:
- Streak calculations update at midnight user's timezone
- Streak badge animates on milestone achievements
- Protection days clearly marked in calendar
- Historical streak data preserved for analytics

**User Story**:
*As a meditation practitioner, I want to see my consecutive days of practice so that I stay motivated to maintain my habit.*

#### 2.3 Progress Visualization
**Functional Requirements**:
- Daily progress bar for recurring tasks
- Calendar heatmap showing completion intensity
- Weekly/monthly/yearly views
- Completion rate statistics
- Trend analysis with improvement indicators

**Acceptance Criteria**:
- Heatmap colors follow accessibility guidelines
- Statistics calculate accurately across time zones
- Views load within 1 second
- Export capability for progress reports

**User Story**:
*As a habit builder, I want to see my completion patterns over time so that I can identify what's working and what needs adjustment.*

#### 2.4 Achievement System
**Functional Requirements**:
- Milestone badges: 7, 30, 100, 365 days
- Perfect week/month achievements
- Category-specific achievements
- Shareable achievement cards
- Achievement notifications with celebration animations

**Acceptance Criteria**:
- Achievements unlock immediately upon qualification
- Notification appears within 2 seconds of unlock
- Achievement history permanently stored
- Social sharing generates image within 3 seconds

**User Story**:
*As a goal-oriented user, I want to earn achievements for consistency so that I feel rewarded for my efforts.*

### 3. User Experience Features

#### 3.1 Offline Support
**Functional Requirements**:
- Full functionality without network connection
- Local data storage with SwiftData
- Background sync when connection restored
- Conflict resolution for concurrent edits
- Offline indicator in UI

**Acceptance Criteria**:
- All CRUD operations work offline
- Sync completes within 30 seconds of connection
- Conflicts resolved using last-write-wins with history
- No data loss during offline periods

**User Story**:
*As a traveler, I want to manage tasks without internet so that I stay productive during flights and in areas with poor connectivity.*

#### 3.2 Visual Themes
**Functional Requirements**:
- System-synchronized dark/light mode
- Liquid Glass design language (iOS 17+)
- Custom accent colors per task category
- High contrast accessibility mode
- Reduced motion option

**Acceptance Criteria**:
- Theme changes apply instantly
- Color selections meet WCAG AA standards
- Animations respect system reduced motion setting
- Theme preferences sync across devices

**User Story**:
*As a night owl, I want automatic dark mode so that the app is comfortable to use in low light conditions.*

#### 3.3 Widget System
**Functional Requirements**:
- Small widget: Today's task count and progress
- Medium widget: Next 3 tasks with quick complete
- Large widget: Full day schedule with habits
- Lock screen widget for quick task check
- Interactive widgets (iOS 17+)

**Acceptance Criteria**:
- Widgets update within 5 minutes of data change
- Tap targets meet minimum 44x44 points
- Widget loads in under 1 second
- Memory usage under 30MB per widget

**User Story**:
*As a productivity enthusiast, I want home screen widgets so that I can see my tasks without opening the app.*

#### 3.4 Voice Input
**Functional Requirements**:
- Siri Shortcuts for common actions
- Voice-to-text for task creation
- Custom voice commands
- Dictation for notes
- Hands-free task completion

**Acceptance Criteria**:
- Voice commands work with 90% accuracy
- Processing completes within 3 seconds
- Supports multiple languages
- Works with AirPods and CarPlay

**User Story**:
*As a busy parent, I want to add tasks using voice so that I can capture items while my hands are full.*

### 4. Smart Features

#### 4.1 Natural Language Processing
**Functional Requirements**:
- Parse dates: "tomorrow", "next Friday", "in 2 weeks"
- Parse times: "at 3pm", "morning", "end of day"
- Parse priorities: "urgent", "important", "ASAP"
- Parse categories from context
- Suggest recurring patterns from behavior

**Acceptance Criteria**:
- Parser accuracy > 95% for common phrases
- Processing time < 500ms
- Learns from user corrections
- Supports localized date formats

**User Story**:
*As a fast-paced executive, I want to type "Call John tomorrow at 2pm urgent" and have all details parsed so that task entry is effortless.*

#### 4.2 Intelligent Notifications
**Functional Requirements**:
- Smart reminder timing based on user patterns
- Location-based reminders
- Focus mode integration
- Notification grouping by priority
- Snooze with smart rescheduling

**Acceptance Criteria**:
- Notifications respect Do Not Disturb
- Location triggers within 100m accuracy
- Groups collapse after 5 notifications
- Snooze options: 5min, 1hr, tomorrow

**User Story**:
*As a remote worker, I want location-based reminders so that I remember tasks when I arrive at specific places.*

---

## User Flows

### Flow 1: First-Time User Onboarding
1. **App Launch**: Splash screen with app logo (1 second)
2. **Welcome Screen**: Brief value proposition with "Get Started" CTA
3. **Permission Requests**: 
   - Notifications (with benefit explanation)
   - Siri & Shortcuts (optional)
   - Calendar access (optional)
4. **Quick Setup**:
   - Choose theme preference
   - Set daily notification time
   - Import from Reminders (optional)
5. **Main Screen**: Land on Today view

### Flow 2: Creating a Recurring Habit
1. **Add Button**: Tap floating action button
2. **Task Type Selection**: Choose "Recurring Task"
3. **Details Entry**:
   - Enter task name
   - Select recurrence pattern
   - Set reminder time
   - Choose category color
4. **Advanced Options** (optional):
   - Add notes
   - Set location reminder
   - Configure end date
5. **Save**: Confirmation animation
6. **Return**: View updates with new recurring task

### Flow 3: Completing Daily Tasks
1. **Today View**: See all tasks for today
2. **Task Interaction**:
   - Tap checkbox to complete
   - Swipe right for quick complete
   - Swipe left for options (edit, delete, reschedule)
3. **Completion Feedback**:
   - Haptic feedback
   - Completion animation
   - Streak update if applicable
4. **Progress Update**: Daily progress bar animates
5. **Achievement Check**: Milestone notification if earned

### Flow 4: Reviewing Habit Progress
1. **Habits Tab**: Navigate to dedicated habits section
2. **Overview Dashboard**:
   - See all active streaks
   - View today's completion percentage
3. **Individual Habit**:
   - Tap to see detailed statistics
   - View calendar heatmap
   - Check historical trends

---

## Information Architecture

### Navigation Structure
```
Tab Bar (Bottom)
├── Today (Default)
│   ├── Overdue Tasks
│   ├── Today's Tasks
│   │   ├── Recurring Tasks (with streak indicators)
│   │   └── Regular Tasks
│   └── Upcoming (next 7 days preview)
├── Tasks
│   ├── All Tasks
│   ├── Projects/Categories
│   ├── Completed
│   └── Search/Filter
├── Habits
│   ├── Active Habits Dashboard
│   ├── Streak Overview
│   ├── Calendar View
│   └── Statistics
├── Add (Floating Action Button)
│   ├── Quick Add
│   ├── Regular Task
│   ├── Recurring Task
│   └── Voice Input
└── Settings
    ├── Account & Sync
    ├── Notifications
    ├── Appearance
    ├── Widgets
    ├── Siri Shortcuts
    └── About
```

### Screen Hierarchy
- **Level 1**: Tab bar screens (Today, Tasks, Habits, Settings)
- **Level 2**: List views and dashboards
- **Level 3**: Detail views (Task detail, Habit statistics)
- **Level 4**: Edit screens and modals

---

## Data Model

### Core Entities

#### Task
```
- id: UUID
- title: String (required)
- description: String?
- dueDate: Date?
- priority: Enum (high, medium, low)
- status: Enum (notStarted, inProgress, complete)
- completedDate: Date?
- category: Category?
- attachments: [Attachment]
- subtasks: [Subtask]
- isRecurring: Boolean
- recurrenceRule: RecurrenceRule?
- parentTaskId: UUID? (for recurring instances)
- createdDate: Date
- modifiedDate: Date
```

#### RecurrenceRule
```
- id: UUID
- frequency: Enum (daily, weekly, monthly, custom)
- interval: Int
- daysOfWeek: [Int]? (for weekly)
- dayOfMonth: Int? (for monthly)
- endDate: Date?
- exceptions: [Date]
```

#### Habit (extends Task)
```
- currentStreak: Int
- bestStreak: Int
- totalCompletions: Int
- completionDates: [Date]
- protectionDaysUsed: Int
- lastProtectionDate: Date?
- targetCompletionsPerPeriod: Int?
```

#### Subtask
```
- id: UUID
- title: String
- isComplete: Boolean
- order: Int
- parentTaskId: UUID
```

#### Category
```
- id: UUID
- name: String
- color: String (hex)
- icon: String (SF Symbol name)
- order: Int
```

#### Achievement
```
- id: UUID
- type: Enum (streak, completion, perfect)
- name: String
- description: String
- iconName: String
- unlockedDate: Date?
- progress: Float
- target: Int
```

### Relationships
- Task → Category: Many-to-One
- Task → Subtask: One-to-Many
- Task → Attachment: One-to-Many
- User → Achievement: Many-to-Many
- Task → RecurrenceRule: One-to-One

---

## Integration Points

### Apple Ecosystem

#### CloudKit
- **Purpose**: Cross-device synchronization
- **Implementation**: 
  - Public database for shared features (future)
  - Private database for user data
  - Push notifications for sync updates
- **Requirements**: 
  - Apple Developer account
  - CloudKit container configuration
  - Conflict resolution strategy

#### WidgetKit
- **Purpose**: Home screen and lock screen widgets
- **Implementation**:
  - Timeline provider for task updates
  - Multiple widget families
  - Deep linking to specific tasks
- **Requirements**:
  - Widget extension target
  - Shared data container
  - Background refresh handling

#### EventKit
- **Purpose**: Calendar integration
- **Implementation**:
  - Create calendar events from tasks
  - Import events as tasks
  - Two-way sync option
- **Requirements**:
  - Calendar permissions
  - Event store access
  - Conflict handling

#### App Intents (Siri)
- **Purpose**: Voice commands and shortcuts
- **Implementation**:
  - Create task intent
  - Complete task intent
  - Check progress intent
- **Requirements**:
  - Intent definitions
  - Siri usage descriptions
  - Shortcut suggestions

#### UserNotifications
- **Purpose**: Reminders and achievements
- **Implementation**:
  - Local notifications for tasks
  - Rich notifications with actions
  - Notification categories
- **Requirements**:
  - Permission handling
  - Notification service extension
  - Sound and badge management

---

## Performance Requirements

### Response Times
- **App Launch**: < 2 seconds (cold start)
- **Task Creation**: < 1 second
- **View Transitions**: < 300ms
- **Search Results**: < 200ms
- **Sync Operation**: < 5 seconds (typical dataset)
- **Widget Refresh**: < 1 second

### Resource Usage
- **Memory**: < 100MB typical usage
- **Storage**: < 50MB app size, < 500MB user data
- **Battery**: < 5% daily usage for average user
- **Network**: < 1MB daily for sync operations

### Scalability
- **Tasks**: Support 10,000+ tasks per user
- **Subtasks**: Support 100+ per task
- **Attachments**: Support 50+ per task
- **Sync**: Handle 1000 changes per sync

### Reliability
- **Crash Rate**: < 0.1% of sessions
- **Sync Success**: > 99.9% reliability
- **Data Integrity**: Zero data loss tolerance
- **Offline Duration**: Unlimited with sync on reconnect

---

## Security & Privacy

### Data Protection
- **Encryption**: 
  - At rest: iOS Data Protection (Complete)
  - In transit: TLS 1.3 minimum
  - CloudKit: End-to-end encryption
- **Authentication**: 
  - Biometric (Face ID/Touch ID)
  - Device passcode fallback
  - Optional app-specific PIN

### Privacy Measures
- **Data Collection**: 
  - No personal data collection without consent
  - Analytics opt-in with clear explanation
  - No third-party tracking
- **Data Storage**:
  - All data stored locally or in user's iCloud
  - No server-side processing
  - No data sharing with third parties
- **Permissions**:
  - Granular permission requests
  - Clear explanations for each permission
  - Graceful degradation if denied

### Compliance
- **GDPR**: Full compliance with data portability and deletion
- **CCPA**: California privacy rights respected
- **COPPA**: No collection from users under 13
- **App Store Guidelines**: Full compliance with latest requirements

---

## Accessibility Standards

### Visual Accessibility
- **VoiceOver**: Full support with descriptive labels
- **Dynamic Type**: Support for all text sizes
- **Color**: 
  - No color-only information
  - 4.5:1 contrast ratio minimum
  - Color blind friendly palettes
- **Reduce Motion**: Alternative animations

### Motor Accessibility
- **Touch Targets**: Minimum 44x44 points
- **Gestures**: Alternative buttons for all gestures
- **Voice Control**: Full navigation support
- **Switch Control**: Compatible with external switches

### Cognitive Accessibility
- **Simple Language**: Clear, concise copy
- **Consistent Navigation**: Predictable patterns
- **Error Prevention**: Confirmation for destructive actions

---

## Launch Strategy

### Phase 1: MVP (Weeks 1-6)
**Core Features**:
- Basic task creation and management
- Simple recurring tasks
- Basic streak tracking
- SwiftData local storage
- Light/dark theme support

**Success Criteria**:
- Functional task CRUD operations
- Basic recurring task support
- Local data persistence
- Theme switching

### Phase 2: Enhancement (Weeks 7-10)
**Additional Features**:
- CloudKit synchronization
- Home screen widgets
- Natural language parsing
- Subtask support
- Achievement system basics

**Success Criteria**:
- Cross-device sync working
- Widget displaying correctly
- 90% NLP accuracy
- Achievement unlocks functioning

### Phase 3: Polish (Weeks 11-12)
**Final Features**:
- Siri integration
- Calendar integration
- Advanced statistics
- Notification intelligence
- Performance optimization

**Success Criteria**:
- All features integrated
- Performance targets met
- Accessibility complete
- App Store ready

### Post-Launch Roadmap
**Version 1.1** (Month 2):
- Apple Watch app
- Additional widget designs
- Advanced filtering
- Batch operations
---

## Risks & Mitigations

### Technical Risks

#### Risk: CloudKit Sync Complexity
- **Probability**: High
- **Impact**: High
- **Mitigation**: 
  - Start with simple sync logic
  - Implement robust conflict resolution
  - Extensive testing across devices
  - Fallback to local-only mode

#### Risk: Performance with Large Datasets
- **Probability**: Medium
- **Impact**: Medium
- **Mitigation**:
  - Implement pagination
  - Use lazy loading
  - Background processing
  - Data archival strategies

---

## Appendices

### A. Wireframe References
- Main task list view with tab bar
- Task creation flow screens
- Habit dashboard with streak visualization
- Settings
- Widget designs for each size

### B. Design System Specifications
- **Typography Scale**: 
  - Title: SF Pro Display 34pt
  - Heading: SF Pro Display 28pt
  - Body: SF Pro Text 17pt
  - Caption: SF Pro Text 13pt
- **Color Palette**:
  - Primary: System Blue
  - Success: System Green
  - Warning: System Orange
  - Error: System Red
  - Neutral: System Grays
- **Spacing Grid**: 8pt system
  - Micro: 4pt
  - Small: 8pt
  - Medium: 16pt
  - Large: 24pt
  - XLarge: 32pt

### C. Technical Architecture
- **Frontend**: SwiftUI with Model-View architecture
- **Data Layer**: SwiftData with CloudKit
- **Networking**: URLSession with async/await
- **Testing**: Swift Testing framework
- **CI/CD**: Xcode Cloud
- **Analytics**: Privacy-preserving on-device metrics

---

*This document serves as the single source of truth for product requirements. All development decisions should align with these specifications while maintaining flexibility for iterative improvements based on user feedback and technical constraints.*
