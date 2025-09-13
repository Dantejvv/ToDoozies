# PRD Generation Prompt for iOS Todo App

Create a comprehensive Product Requirements Document (PRD) for a modern iOS todo/task management application with the following specifications:

## Product Vision
iOS todo application that emphasizes habit formation and streak tracking alongside traditional task management. The app should seamlessly integrate with Apple's ecosystem while providing an intuitive, motivating experience for users to manage both one-time tasks and recurring habits.

## Core Requirements

### Task Management Fundamentals
- **Task Creation**: Quick and effortless task entry with support for subtasks/checklists to break down complex items
- **Temporal Features**: Due dates, times, and customizable reminder notifications  
- **Organization**: Three-tier priority system (high/medium/low), completion status tracking, powerful search/filter capabilities, and flexible sorting options
- **Rich Content**: Support for notes and file attachments on tasks

### Habit & Streak System
- **Dual Task Types**: Clear separation between recurring tasks and regular one-time tasks
- **Recurrence Patterns**: Daily, weekly, monthly, and custom recurring schedules
- **Motivation Mechanics**: 
  - Visual streak counters showing consecutive completion days
  - Daily progress bars for recurring task completion percentage
  - Achievement badges and milestone celebrations (7, 30, 100-day markers)
  - Calendar heatmap visualization for habit chains
  - Forgiveness system with grace/skip days to maintain streaks

### User Experience Requirements
- **Accessibility**: Full offline functionality with background sync when connected
- **Visual Preferences**: Both dark and light mode support following system settings
- **Quick Access**: Home screen widgets for rapid task viewing and creation
- **Input Methods**: Voice input support for hands-free task entry
- **Cross-Device**: Seamless synchronization across all user's Apple devices

### Smart Capabilities
- **Natural Language**: Quick add functionality that parses natural language input
- **Personalization**: Customizable themes and colors for different task categories

## Technical Foundation
Build on Apple's modern iOS development stack including:
- Native Swift and SwiftUI for optimal performance
- SwiftData for local persistence with CloudKit for sync
- Integration with Siri and Shortcuts through App Intents
- Home screen widgets via WidgetKit
- Calendar integration through EventKit
- Push notifications for reminders

## Design Principles
- **Visual Hierarchy**: Follow 60-30-10 color distribution (60% neutral, 30% complementary, 10% brand accent)
- **Typography**: Maximum 4 font sizes and 2 font weights for clarity
- **Spatial Design**: Implement 8pt grid system for consistent spacing
- **Copy**: Clear, concise messaging throughout the interface
- **Apple HIG**: Full adherence to Human Interface Guidelines and Liquid Glass design system

## User Interface Structure

### Primary Views
1. **Main Task View**: Combined display of today's recurring tasks with streak indicators and regular task list
2. **Habits & Streaks Dashboard**: Comprehensive streak overview, habit calendar, and milestone tracking
3. **Task Creation Flow**: Streamlined interface for adding tasks with type selection, recurrence configuration, and metadata

### Key Interactions
- Single-tap task completion with visual feedback
- Swipe gestures for quick actions
- Long-press for context menus
- Pull-to-refresh for manual sync

## Success Metrics
Define product success through:
- User engagement with recurring tasks and streak maintenance
- Task completion rates
- Cross-device usage patterns
- Widget interaction frequency
- Retention metrics focused on habit formation

## Constraints & Considerations
- Maintain privacy-first approach with on-device processing where possible
- Ensure accessibility compliance for all users
- Optimize for battery efficiency during background operations
- Support latest iOS version and two prior major versions

## PRD Generation Instructions

Generate a detailed PRD that expands on these requirements, providing:

### Document Structure
1. **Executive Summary**: Brief overview of the product vision and goals
2. **Problem Statement**: Clear articulation of user needs being addressed
3. **Target Audience**: Detailed user personas and use cases
4. **Feature Specifications**: Comprehensive breakdown of each feature with:
   - Functional requirements
   - Acceptance criteria
   - User stories in "As a... I want... So that..." format
5. **User Flows**: Step-by-step descriptions of key user journeys
6. **Information Architecture**: Navigation structure and screen hierarchy
7. **Data Model**: Conceptual overview of data entities and relationships
8. **Integration Points**: Third-party services and Apple ecosystem touchpoints
9. **Performance Requirements**: Response times, sync speeds, offline capabilities
10. **Security & Privacy**: Data protection and user privacy measures
11. **Accessibility Standards**: WCAG compliance and inclusive design requirements
12. **Launch Strategy**: MVP features vs. future enhancements
14. **Risks & Mitigations**: Potential challenges and mitigation strategies
15. **Appendices**: Wireframes references

### Key Deliverables
- Clear acceptance criteria for each feature
- Prioritized feature backlog
- User journey maps
- Edge cases and error states
- Localization requirements

### Writing Guidelines
- Use clear, unambiguous language
- Avoid technical jargon when describing user-facing features
- Include specific examples and scenarios
- Define all acronyms on first use
- Maintain consistent terminology throughout
- Focus on the "what" and "why", not the "how" of implementation

Generate the PRD with sufficient detail for a development team of one to understand requirements completely while maintaining focus on product perspective rather than technical implementation details. Use phased implementation to manage complexity.
