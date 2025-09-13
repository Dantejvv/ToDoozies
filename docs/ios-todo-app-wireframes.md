# iOS Todo App Wireframes
## Multiple Design Variations

---

## 1. TODAY VIEW - Main Task Screen

### Version A: Unified List with Section Headers
```
+----------------------------------+
|        9:41 AM      🔋 100%      |
+----------------------------------+
|            TODAY                 |
|         Saturday, Sep 13         |
+----------------------------------+
| Daily Progress  [■■■■■----] 60%  |
+----------------------------------+

 🔁 RECURRING TASKS ---------------
 
 ○ Morning Run          🔥 7
   7:00 AM             
   
 ● Read 20 min          🔥 3
   8:00 AM             ✓ Done
   
 ○ Meditate            🔥 12
   8:30 AM             
 
 📝 REGULAR TASKS -----------------
 
 ○ Finish design draft
   ⏰ Today, 5:00 PM    🔴 High
   
 ○ Grocery shopping
   ⏰ Tomorrow          🟡 Medium
   
 ○ Call mom
   No due date         🟢 Low

+----------------------------------+
| 📋 Tasks | 🔥 Habits | ➕ | ⚙️   |
+----------------------------------+
```

### Version B: Card-Based Layout
```
+----------------------------------+
|        9:41 AM      🔋 100%      |
+----------------------------------+
|     Good Morning, Sarah! ☀️      |
|      3 habits • 5 tasks         |
+----------------------------------+

┌─────────────────────────────────┐
│ 📊 Today's Progress             │
│ ████████░░░░░░░ 60% Complete   │
│ 3 of 5 tasks done               │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 🔥 Active Streaks               │
│ Morning Run: 7 days             │
│ Reading: 3 days                  │
│ Meditation: 12 days             │
│            [View All →]          │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 📌 Priority Tasks               │
│                                 │
│ ○ Finish design draft    5 PM   │
│ ○ Team standup          10 AM   │
│ ○ Review proposals       2 PM   │
│                                 │
│            [See All Tasks →]    │
└─────────────────────────────────┘

+----------------------------------+
| 🏠 Today | 📋 All | 🔥 | ➕ | 👤  |
+----------------------------------+
```

---

## 2. ADD TASK SCREEN

### Version A: Traditional Form
```
+----------------------------------+
|  Cancel     Add Task      Save   |
+----------------------------------+

 What needs to be done?
 ┌─────────────────────────────────┐
 │ Buy groceries                   │
 └─────────────────────────────────┘

 Task Type
 ┌─────────────────────────────────┐
 │ ○ One-time  ● Recurring        │
 └─────────────────────────────────┘

 📅 Due Date
 ┌─────────────────────────────────┐
 │ Tomorrow at 5:00 PM      ⌄     │
 └─────────────────────────────────┘

 🔁 Repeat
 ┌─────────────────────────────────┐
 │ Daily                    ⌄     │
 └─────────────────────────────────┘

 🎯 Priority
 ┌─────────────────────────────────┐
 │ ○ Low  ● Medium  ○ High        │
 └─────────────────────────────────┘

 📝 Notes
 ┌─────────────────────────────────┐
 │ Remember to check for sales...  │
 │                                 │
 └─────────────────────────────────┘

 📎 Attachments
 ┌─────────────────────────────────┐
 │  + Add Photo or File            │
 └─────────────────────────────────┘

+----------------------------------+
```

---

## 3. HABITS & STREAKS DASHBOARD

### Version A: Stats-Focused
```
+----------------------------------+
|       Habits & Streaks           |
+----------------------------------+

 ┌─────────────────────────────────┐
 │      CURRENT STREAKS            │
 │                                 │
 │  🏃 Running        ███ 7 days   │
 │  📚 Reading        ██ 3 days    │
 │  🧘 Meditation     █████ 12 days│
 │  💧 Water         ████ 8 days   │
 └─────────────────────────────────┘

 This Month Performance
 ┌─────────────────────────────────┐
 │ Completion Rate:  78%           │
 │ Perfect Days:     5             │
 │ Best Streak:      12 days       │
 │ Total Completed:  89 tasks      │
 └─────────────────────────────────┘

 September 2025
 ┌─────────────────────────────────┐
 │ Mo Tu We Th Fr Sa Su           │
 │ ■  ■  □  ■  ■  ■  ■            │
 │ ■  □  ■  ■  ■  ▨  □            │
 │ ■  ■  ■  ■  ■  ■  ■            │
 │ ■  ■  ■  ■  □  ■  ■            │
 └─────────────────────────────────┘
 ■ Perfect  ▨ Partial  □ Missed

 🏆 Recent Achievements
 [7-Day Badge] [Perfect Week] [→]

+----------------------------------+
| 📋 Tasks | 🔥 Habits | ➕ | ⚙️   |
+----------------------------------+
```

### Version B: List-Based with Actions
```
+----------------------------------+
|    Habits          + Add New     |
+----------------------------------+
| Today: 2/4 Complete      60%     |
+----------------------------------+

 ┌─────────────────────────────────┐
 │ ✓ Morning Run                   │
 │   Every day at 7:00 AM          │
 │   🔥 7 day streak • Best: 15    │
 │   [Skip Today] [View Stats]     │
 ├─────────────────────────────────┤
 │ ✓ Read 20 Minutes               │
 │   Every day at 8:00 PM          │
 │   🔥 3 day streak • Best: 21    │
 │   [Skip Today] [View Stats]     │
 ├─────────────────────────────────┤
 │ ○ Meditate                      │
 │   Every day at 8:30 AM          │
 │   🔥 12 day streak • Best: 12   │
 │   [Complete] [Skip] [Stats]     │
 ├─────────────────────────────────┤
 │ ○ Drink 8 Glasses Water         │
 │   Daily goal                    │
 │   🔥 8 day streak • 5/8 done    │
 │   [+] [+] [+] [-] [Stats]       │
 └─────────────────────────────────┘

 Protection Days: 2 remaining
 [Use Protection Day]

+----------------------------------+
| 📋 Tasks | 🔥 Habits | ➕ | ⚙️   |
+----------------------------------+
```

---

## 4. TASK DETAIL VIEW

### Version A: Comprehensive Details
```
+----------------------------------+
| < Back    Task Details    Edit   |
+----------------------------------+

 ┌─────────────────────────────────┐
 │ ○ Finish Q3 presentation        │
 └─────────────────────────────────┘

 📅 Due Date
 Monday, Sep 15, 2025 at 5:00 PM
 (In 2 days)

 🔴 Priority: High

 📁 Project: Quarterly Review

 📝 Description
 ┌─────────────────────────────────┐
 │ Complete slides for Q3 review   │
 │ meeting. Include:               │
 │ - Revenue analysis              │
 │ - Team performance metrics      │
 │ - Q4 projections                │
 └─────────────────────────────────┘

 ✓ Subtasks (2/5)
 ┌─────────────────────────────────┐
 │ ✓ Gather sales data            │
 │ ✓ Create charts                │
 │ ○ Write executive summary      │
 │ ○ Review with team             │
 │ ○ Final formatting             │
 └─────────────────────────────────┘

 📎 Attachments (2)
 ┌─────────────────────────────────┐
 │ 📊 Q3-data.xlsx      2.3 MB    │
 │ 📄 Guidelines.pdf    456 KB    │
 │ [+ Add Attachment]              │
 └─────────────────────────────────┘

 [Mark Complete]  [Delete Task]
```
### Version B: Minimal Clean
```
+----------------------------------+
|              ✕                   |
+----------------------------------+

 Finish Q3 presentation

 Tomorrow • 5:00 PM • High Priority

 ──────────────────────────────────
 
 Complete slides for Q3 review 
 meeting with all metrics and 
 projections.

 ──────────────────────────────────

 Checklist                    2/5
 
 ✓ Gather sales data
 ✓ Create charts
 ○ Write executive summary
 ○ Review with team
 ○ Final formatting

 ──────────────────────────────────

 Files
 
 Q3-data.xlsx
 Guidelines.pdf
 + Add file

 ──────────────────────────────────

         [Complete Task]
```

---

## 5. SETTINGS SCREEN

### Version A: Grouped Sections
```
+----------------------------------+
|           Settings               |
+----------------------------------+

 ACCOUNT
 ┌─────────────────────────────────┐
 │ Sarah Johnson                  >│
 │ sarah@example.com               │
 ├─────────────────────────────────┤
 │ iCloud Sync              ON  ⊙ │
 │ Last synced: 2 min ago          │
 └─────────────────────────────────┘

 PREFERENCES
 ┌─────────────────────────────────┐
 │ Theme                  Auto   > │
 │ Default View          Today   > │
 │ Start Week On         Monday  > │
 │ Sound Effects           ON   ⊙ │
 └─────────────────────────────────┘

 NOTIFICATIONS
 ┌─────────────────────────────────┐
 │ Task Reminders          ON   ⊙ │
 │ Daily Summary         9:00 AM > │
 │ Achievement Alerts      ON   ⊙ │
 │ Streak Reminders        ON   ⊙ │
 └─────────────────────────────────┘

 WIDGETS & SHORTCUTS
 ┌─────────────────────────────────┐
 │ Configure Widgets             > │
 │ Siri Shortcuts               > │
 │ Focus Mode Integration       > │
 └─────────────────────────────────┘

 ABOUT
 ┌─────────────────────────────────┐
 │ Version 1.0.0                   │
 │ Help & Support               > │
 │ Privacy Policy               > │
 │ Rate ToDoozies              > │
 └─────────────────────────────────┘

+----------------------------------+
| 📋 Tasks | 🔥 Habits | ➕ | ⚙️   |
+----------------------------------+
```

### Version B: List Style
```
+----------------------------------+
|  < Back       Settings           |
+----------------------------------+

 Profile
 ─────────────────────────────────
 👤 Sarah Johnson                 >
 📧 sarah@example.com
 ☁️ iCloud Sync                  ✓

 Appearance
 ─────────────────────────────────
 🎨 Theme                    Auto >
 🏷️ Accent Color            Blue >
 📱 App Icon              Default >

 Behavior
 ─────────────────────────────────
 📅 Default View           Today >
 🗓️ Week Starts          Monday >
 🔊 Sounds                     ON
 📳 Haptics                    ON

 Notifications
 ─────────────────────────────────
 🔔 Enable Notifications       ON
 ⏰ Default Reminder Time  9:00 AM
 🔥 Streak Alerts             ON
 📊 Daily Summary             ON

 Data & Privacy
 ─────────────────────────────────
 💾 Export Data                  >
 🗑️ Clear Cache                 >
 🔒 Privacy Settings            >

 Support
 ─────────────────────────────────
 ❓ Help Center                 >
 💬 Contact Support             >
 ⭐ Rate App                    >

 Version 1.0.0 (Build 42)
```

---

## 7. WIDGET DESIGNS

### Small Widget (2x2)
```
┌─────────────────┐
│ ToDoozies       │
│                 │
│ Today: 3/8 📝   │
│ Streaks: 4 🔥   │
│                 │
│ [Tap to open]   │
└─────────────────┘
```

### Medium Widget (4x2)
```
┌───────────────────────────────┐
│ ToDoozies - Today             │
│                               │
│ ○ Morning Run          7🔥    │
│ ○ Team Meeting        10 AM   │
│ ○ Finish Report        5 PM   │
│                               │
│ Progress: ████░░░░ 3/8        │
└───────────────────────────────┘
```

### Large Widget (4x4)
```
┌───────────────────────────────┐
│ ToDoozies                     │
│ Saturday, Sep 13              │
├───────────────────────────────┤
│ 🔥 Habits                     │
│ • Running: 7 days             │
│ • Reading: 3 days             │
│ • Meditation: 12 days         │
├───────────────────────────────┤
│ 📝 Priority Tasks             │
│ ○ Design draft - 5 PM         │
│ ○ Call client - 2 PM          │
│ ○ Review docs - Tomorrow      │
├───────────────────────────────┤
│ Daily: ████████░░ 80%         │
│                    [+ Add]    │
└───────────────────────────────┘
```

---

## 8. EMPTY STATES

### No Tasks
```
+----------------------------------+
|            TODAY                 |
+----------------------------------+
|                                  |
|         ✨                       |
|                                  |
|    All done for today!           |
|                                  |
|  You've completed everything.    |
|    Time to relax or add          |
|      something new.              |
|                                  |
|      [Add First Task]            |
|                                  |
+----------------------------------+
```

### No Habits
```
+----------------------------------+
|       Habits & Streaks           |
+----------------------------------+
|                                  |
|         🌱                       |
|                                  |
|   Start Building Habits          |
|                                  |
|  Create your first recurring     |
|  task and watch your             |
|  streaks grow!                   |
|                                  |
|    [Create First Habit]          |
|                                  |
+----------------------------------+
```

---

## Navigation Patterns

### Tab Bar Icons
```
+----------------------------------+
|                                  |
|         [Main Content]           |
|                                  |
+----------------------------------+
| 📋     🔥      ➕      ⚙️        |
| Tasks  Habits  Add   Settings    |
+----------------------------------+

Alternative icon set:
| 📝     🎯      +      👤        |
| Today  Goals   Add   Profile     |
```

### Gesture Indicators
```
Task Row Interactions:
┌─────────────────────────────────┐
│ ← Swipe left for options        │
│ → Swipe right to complete       │
│ ⬆️ Long press for quick actions │
└─────────────────────────────────┘
```

---

## Design System Notes

### Color Usage
- **Primary Actions**: System Blue (#007AFF)
- **Success/Complete**: System Green (#34C759)
- **High Priority**: System Red (#FF3B30)
- **Medium Priority**: System Orange (#FF9500)
- **Low Priority**: System Green (#34C759)
- **Backgrounds**: System Grays
- **Streak Indicators**: Orange/Red gradient

### Typography Hierarchy
- **Large Title**: 34pt Bold (Screen titles)
- **Title 1**: 28pt Regular (Section headers)
- **Body**: 17pt Regular (Main content)
- **Callout**: 16pt Regular (Emphasis)
- **Footnote**: 13pt Regular (Secondary info)

### Spacing Grid (8pt system)
- **Micro**: 4pt (Between related elements)
- **Small**: 8pt (Default padding)
- **Medium**: 16pt (Between sections)
- **Large**: 24pt (Major sections)
- **XLarge**: 32pt (Screen margins)

### Interactive Elements
- **Minimum touch target**: 44x44pt
- **Button height**: 50pt (primary), 44pt (secondary)
- **List row height**: 60-80pt depending on content
- **Corner radius**: 12pt (cards), 8pt (buttons)

---

## Responsive Considerations

### iPhone SE/Mini (Small)
- Reduce padding to 12pt
- Single column layouts only
- Compact font sizes (-1pt)
- Fewer items visible in lists

### iPhone Pro Max (Large)
- Increase padding to 20pt
- Consider 2-column layouts for iPads
- Show more context in cards
- Display additional metadata

### Dynamic Type Support
- All text must scale with system settings
- Maintain minimum contrast ratios
- Stack layouts vertically when text is large
- Hide non-essential icons at largest sizes

### Landscape Orientation
- Use master-detail split view
- Move tab bar to side rail
- Increase content density
- Show calendar alongside task list
