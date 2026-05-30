# Work Log

A local-first time tracking and work management app built with Flutter. Track live sessions, add manual entries, analyze time by day/month/company, and import or share data as CSV.

## Overview

Time Tracker is designed for fast, offline-first logging of work sessions. It uses Hive for local storage and BLoC for state management. The UI includes a tracker, manual entry flow, sessions list, calendar view, and dashboard insights.

## Features

- Live tracker with check-in/check-out and running timer
- Manual session entry with validation and overlap checks
- Sessions list with search and filters
- Session detail view
- Calendar view with per-day session rollups
- Dashboard insights with charts and heatmaps
- Company management with color and hourly rate
- CSV export via share sheet
- CSV import with overwrite confirmation
- Settings for default company, time rounding, and theme mode
- Light and dark mode support, system-aware

## CSV Import/Export

### Export

Export uses the share sheet so you can send the CSV to email, Drive, or any supported app. The export file contains all sessions for the selected month.

### Import

Import replaces existing data after a confirmation dialog. The CSV must include the following header columns:

```
session_id,company_id,company_name,start_time,end_time,duration_seconds,notes
```

Notes:
- Dates must be ISO 8601 (the format used by the export).
- Empty `end_time` is allowed for active sessions.
- If a company ID is missing, a company will be created based on the name.

## Data Model

### Company

- `id`: string
- `name`: string
- `colorCode`: integer (ARGB)
- `hourlyRate`: number (optional)

### Work Session

- `id`: string
- `companyId`: string
- `startTime`: DateTime
- `endTime`: DateTime (nullable)
- `durationInSeconds`: integer
- `notes`: string (optional)

## Settings

- Default company for new sessions
- Time rounding for new sessions (applies on save and check-out)
- Theme mode: System, Light, or Dark

## Theme and Branding

- Primary color: `#FD7800`
- Material 3 styling with custom typography
- Dedicated light and dark schemes

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK (via Flutter)

### Install dependencies

```
flutter pub get
```

### Run the app

```
flutter run
```

## Development Notes

- Data is stored locally using Hive.
- Import overwrites existing sessions and companies after confirmation.
- If the imported data does not include the current default company, the default is cleared.

## Troubleshooting

- If a theme or dependency change does not appear, run a full restart instead of hot reload.
- For CSV import failures, verify the header and date formats match the export format.
