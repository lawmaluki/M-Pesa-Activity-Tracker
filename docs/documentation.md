---
title: "M-Pesa Activity Tracker"
subtitle: "Technical & User Documentation"
author: "lawmaluki"
date: "2026"
---

# M-Pesa Activity Tracker

### *"GitHub for your money activity"*

---

## Table of Contents

1. [Overview](#1-overview)
2. [Features](#2-features)
3. [Architecture](#3-architecture)
4. [Project Structure](#4-project-structure)
5. [Data Flow](#5-data-flow)
6. [Key Components](#6-key-components)
7. [M-Pesa SMS Parsing](#7-m-pesa-sms-parsing)
8. [Database Design](#8-database-design)
9. [Heatmap Visualisation](#9-heatmap-visualisation)
10. [Appearance & Personalisation](#10-appearance--personalisation)
11. [Sharing](#11-sharing)
12. [Screens & Navigation](#12-screens--navigation)
13. [Permissions](#13-permissions)
14. [Dependencies](#14-dependencies)
15. [Getting Started](#15-getting-started)
16. [Future Extensions](#16-future-extensions)

---

## 1. Overview

The M-Pesa Activity Tracker is a Flutter Android application that automatically parses M-Pesa SMS notifications, extracts structured transaction data, and visualises daily financial activity as a **GitHub-style contribution heatmap**.

Instead of scrolling through hundreds of SMS notifications or exporting statements manually, the app turns your raw M-Pesa history into a visual behavioural pattern — making spending habits and money movement immediately obvious at a glance.

> *"It's a personal financial contribution graph — but instead of code commits, it visualises your money activity from M-Pesa as daily behavioural patterns."*

---

## 2. Features

### 2.1 Data Ingestion

| Method | Description |
|---|---|
| **SMS Sync** | Reads M-Pesa messages directly from the device inbox with one tap |
| **Paste SMS** | Copy-paste one or many M-Pesa notifications into a text box |
| **CSV Import** | Import the official statement export from the M-Pesa app |
| **PDF Import** | Import the password-protected PDF statement export, decrypted on-device |

### 2.2 Transaction Parsing

The parser recognises all standard M-Pesa transaction types:

- **Send Money** — transfers to phone numbers
- **Receive Money** — incoming transfers
- **Paybill** — utility and business payments
- **Buy Goods (Lipa na M-Pesa)** — till/merchant payments
- **Withdraw Cash** — agent withdrawals
- **Airtime Purchase** — top-up and data bundles
- **Reversal** — failed/reversed transactions

### 2.3 Heatmap Visualisation

- GitHub-style 53-week grid (Monday → Sunday rows, oldest → newest columns)
- 5-level intensity palette based on daily transaction count, in a choice of 6 colour themes
- Cell size and shape (square/circle) are user-configurable
- Tap any cell to see every transaction on that day
- Year selector to navigate historical data
- Today's date highlighted with a border

### 2.4 Transaction Management

- Full transaction list with swipe-to-delete
- Per-day detail view with net flow summary (received vs spent)
- Automatic deduplication — re-importing the same data never creates duplicates
- Clear all data option

### 2.5 Appearance & Sharing

- Light, dark, or system-follow theme, remembered across launches
- Shareable "year in review" card — heatmap + headline stats rendered as an image, saved to the gallery or handed to the native share sheet

---

## 3. Architecture

The app uses a clean layered architecture:

```
┌───────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  HomeScreen │ ImportScreen │ DayDetailScreen │ ShareScreen  │
│  HeatmapWidget │ TransactionCard │ SummaryStats │ ShareCard │
└────────────────────────────┬────────────────────────────────┘
                             │  reads/writes via
┌────────────────────────────▼────────────────────────────────┐
│                    State Layer (Provider)                     │
│  TransactionProvider │ ThemeProvider │ HeatmapSettingsProvider│
│  - TransactionProvider holds the transaction list, the daily  │
│    count map for the heatmap, and sync/import/delete actions  │
│  - ThemeProvider / HeatmapSettingsProvider hold persisted      │
│    appearance choices, backed by shared_preferences            │
└────────────────────────────┬────────────────────────────────┘
                             │  calls
┌────────────────────────────▼────────────────────────────────┐
│                       Service Layer                           │
│  SmsService │ SmsParser │ StatementParser │ PdfStatementParser│
│                      DatabaseService                           │
└────────────────────────────┬────────────────────────────────┘
                             │  persists to
┌────────────────────────────▼────────────────────────────────┐
│                    Data Layer (SQLite)                        │
│                     mpesa_tracker.db                           │
│                     transactions table                         │
└───────────────────────────────────────────────────────────────┘
```

**State Management:** Provider (`ChangeNotifier`) — chosen for simplicity and testability without the overhead of BLoC or Riverpod for this app size. Three providers: transaction state, theme choice, and heatmap appearance — kept separate since each has an independent lifecycle and persistence concern.

**Local Storage:** SQLite via `sqflite` — durable, queryable, zero-config. Appearance preferences (theme mode, heatmap colour/size/shape) are small key-value settings and live in `shared_preferences` instead.

---

## 4. Project Structure

```
lib/
├── main.dart                        # Entry point, provider wiring, theme switch
├── models/
│   └── transaction.dart             # MpesaTransaction, DaySummary, TransactionType
├── services/
│   ├── database_service.dart        # SQLite singleton, CRUD, aggregation queries
│   ├── sms_parser.dart              # Regex parser for M-Pesa SMS format
│   ├── sms_service.dart             # Reads device inbox, permissions
│   ├── statement_parser.dart        # CSV + pasted-SMS bulk import
│   └── pdf_statement_parser.dart    # Password-protected PDF statement import
├── providers/
│   ├── transaction_provider.dart    # ChangeNotifier, transaction + heatmap state
│   ├── theme_provider.dart          # ChangeNotifier, light/dark/system choice
│   └── heatmap_settings_provider.dart # ChangeNotifier, heatmap colour/size/shape
├── screens/
│   ├── home_screen.dart             # Main screen: heatmap + stats + list
│   ├── import_screen.dart           # Tabbed import: PDF / paste SMS / CSV
│   ├── day_detail_screen.dart       # Per-day transaction breakdown
│   └── share_screen.dart            # Floating "year in review" share modal
├── widgets/
│   ├── heatmap_widget.dart          # Custom GitHub-style heatmap grid
│   ├── more_menu_sheet.dart         # Overflow (⋮) menu, as a bottom sheet
│   ├── appearance_sheet.dart        # Light/dark/system picker sheet
│   ├── heatmap_customize_sheet.dart # Colour/size/shape picker sheet
│   ├── transaction_card.dart        # Dismissible transaction list item
│   ├── summary_stats.dart           # 3-tile stats row (count/spent/received)
│   └── share_card.dart              # The captured "year in review" card
├── theme/
│   ├── app_colors.dart              # Light/dark palette as a ThemeExtension
│   ├── app_theme.dart               # ThemeData built from AppColors
│   └── heatmap_theme.dart           # Heatmap colour themes + size/shape enums
└── utils/
    └── money.dart                   # Shared "Ksh …" currency formatting

android/
└── app/src/main/
    └── AndroidManifest.xml          # SMS, storage, and legacy-storage permissions

test/
└── widget_test.dart
```

---

## 5. Data Flow

### SMS Sync Flow

```
User taps Sync
     │
     ▼
SmsService.requestPermissions()
     │
     ▼  (granted)
flutter_sms_inbox reads device inbox
     │
     ▼
Filter: SmsParser.isMpesaSms(body)
     │
     ▼
SmsParser.parseAll(messages)
  - extract ref, amount, date, type, counterparty, balance
     │
     ▼
DatabaseService.insertTransactionsBatch()
  - UNIQUE(ref) deduplication
     │
     ▼
TransactionProvider refreshes heatmap data
     │
     ▼
UI rebuilds: HeatmapWidget + TransactionList
```

### CSV Import Flow

```
User picks .csv file
     │
     ▼
dart:io File.readAsString()
     │
     ▼
StatementParser.parseCSV()
  - find header row (skip Safaricom metadata)
  - parse each row: receipt, date, paid in / withdrawn
  - infer transaction type from Details column
     │
     ▼
DatabaseService.insertTransactionsBatch()
     │
     ▼
UI refreshes
```

### PDF Import Flow

```
User picks .pdf file + enters statement password
     │
     ▼
PdfDocument.openFile(passwordProvider: ...)   [pdfrx]
  - PdfPasswordException → surfaced as a distinct,
    actionable "incorrect password" error
     │
     ▼
PdfPageText.fullText extracted from every page
     │
     ▼
PdfStatementParser._reconstructRows()
  - a row runs from one receipt-code line to the next,
    since M-Pesa wraps long Details across lines
     │
     ▼
Rows re-serialised to CSV text
     │
     ▼
StatementParser.parseCSV()   ← same code path as CSV import
     │
     ▼
Reconcile parsed totals against the statement's own
SUMMARY block; attach a non-fatal warning if they disagree
     │
     ▼
DatabaseService.insertTransactionsBatch()
     │
     ▼
UI refreshes
```

No parsing logic is duplicated between the CSV and PDF paths — the PDF importer only opens the file and rebuilds table rows, then hands off to the same `StatementParser.parseCSV`.

---

## 6. Key Components

### 6.1 TransactionProvider (`providers/transaction_provider.dart`)

The single source of truth for transaction and heatmap-count state.

| Property | Type | Description |
|---|---|---|
| `transactions` | `List<MpesaTransaction>` | All transactions, newest first |
| `dailyCounts` | `Map<String, int>` | `"yyyy-MM-dd"` → count, for heatmap |
| `selectedYear` | `int` | Year displayed on heatmap |
| `selectedDay` | `DateTime?` | Day tapped on heatmap |
| `state` | `LoadState` | `idle / loading / error` |

Key actions: `loadData()`, `syncSms()`, `importCsv()`, `importPastedSms()`, `importPdf()`, `deleteTransaction()`, `clearAll()`, `setSelectedYear()`, `selectDay()`, `onNewTransaction()`

### 6.2 ThemeProvider (`providers/theme_provider.dart`) & HeatmapSettingsProvider (`providers/heatmap_settings_provider.dart`)

Two small `ChangeNotifier`s that hold the user's appearance choices and persist them via `shared_preferences`:

- `ThemeProvider.mode` — `ThemeMode.system / light / dark`
- `HeatmapSettingsProvider` — `colorTheme`, `cellSize`, `cellShape`

Both default to a neutral choice (system theme, green, medium, square) if no preference has been saved yet, and fail silently back to that default if `shared_preferences` is unavailable.

### 6.3 DatabaseService (`services/database_service.dart`)

Singleton SQLite wrapper. All queries are async-safe via sqflite's internal locking.

Notable methods:

```dart
// Batch insert with automatic dedup
Future<int> insertTransactionsBatch(List<MpesaTransaction> txs)

// Returns {yyyy-MM-dd: count} for an entire year — used to build heatmap
Future<Map<String, int>> fetchDailyCountsForYear(int year)

Future<List<MpesaTransaction>> fetchAll()
Future<void> deleteTransaction(int id)
Future<void> deleteAll()
```

### 6.4 SmsParser (`services/sms_parser.dart`)

Pure Dart regex parser with no platform dependencies — fully unit-testable.

Extracts from each SMS message:
- **Reference** — the 10–12 character transaction code (e.g. `RHL92ABC12`)
- **Amount** — `Ksh1,234.00` → `1234.00`
- **Date & Time** — `1/5/26 at 2:30 PM` → `DateTime(2026, 5, 1, 14, 30)`
- **Type** — inferred from verb: *sent / received / withdrawn / paid / airtime*
- **Counterparty** — name and phone number after the verb
- **Balance** — new M-Pesa balance after transaction
- **Transaction cost** — fee charged

### 6.5 PdfStatementParser (`services/pdf_statement_parser.dart`)

Opens the password-protected PDF export from the M-Pesa app, extracts its text layer via `pdfrx`, and reconstructs the statement table — see [§7 PDF Statement Import](#73-pdf-statement-import) below. No transaction-parsing logic lives here; it bridges to `StatementParser.parseCSV` so PDF and CSV imports share one code path.

### 6.6 Money (`utils/money.dart`)

Every amount shown in the UI goes through this shared formatter rather than each widget building its own `NumberFormat`, so the `"Ksh "` prefix and grouping/decimal style stay consistent:

```dart
Money.exact(1234.5)    // "Ksh 1,234.50" — transaction rows, day totals
Money.whole(1234.5)    // "Ksh 1,235"    — summary stat tiles
Money.compact(1234.5)  // "Ksh 1.2K"     — share card
```

---

## 7. M-Pesa SMS Parsing

### 7.1 Supported SMS Formats

**Send Money**
```
RHL92ABC12 Confirmed. Ksh500.00 sent to JANE DOE 0722000000
on 1/5/26 at 2:30 PM. New M-Pesa balance is Ksh4,500.00.
Transaction cost, Ksh8.00.
```

**Receive Money**
```
RHL92ABC13 Confirmed.You have received Ksh1,000.00 from
JOHN KAMAU 0733000000 on 1/5/26 at 3:00 PM.
New M-Pesa balance is Ksh5,500.00.
```

**Paybill Payment**
```
RHL92ABC14 Confirmed. Ksh2,500.00 sent to SAFARICOM POSTPAY
100200 on 1/5/26 at 10:00 AM. New M-Pesa balance is Ksh3,000.00.
Transaction cost, Ksh0.00.
```

**Buy Goods (Lipa na M-Pesa)**
```
RHL92ABC15 Confirmed. Ksh350.00 paid to NAIVAS WESTGATE 12345
on 1/5/26 at 1:00 PM. New M-Pesa balance is Ksh2,650.00.
```

**Withdraw Cash**
```
RHL92ABC16 Confirmed. Ksh1,000.00 withdrawn from JOHN AGENT
000001 on 1/5/26 at 11:00 AM. New M-Pesa balance is Ksh1,650.00.
Transaction cost, Ksh28.00.
```

**Airtime Purchase**
```
RHL92ABC17 Confirmed. Airtime purchase of Ksh100.00 on 1/5/26
at 12:00 PM. New M-Pesa balance is Ksh1,550.00.
```

### 7.2 Type Detection Logic

```
SMS body (lowercased)
  ├── contains "you have received" or "received ksh"  → Received
  ├── contains "airtime purchase" or "airtime of"     → Airtime
  ├── contains "withdrawn from"                        → Withdrawn
  ├── contains "reversal"                              → Reversal
  ├── contains "paid to"                               → Buy Goods
  ├── contains "sent to" + 5–6 digit account code     → Paybill
  └── contains "sent to" (phone number)               → Sent
```

The counterparty (name + phone number, or business name) is pulled from the text between the verb and `on <date>`. The pattern keys off a standalone `from` rather than the literal phrases `received from` / `withdrawn from`, because M-Pesa's actual wording puts the amount in between — e.g. `received Ksh100.00 from JOHN DOE 0722123456 on 1/5/26` — so matching `received from` as one phrase never hits.

### 7.3 PDF Statement Import

The official M-Pesa app can export a full statement as a password-protected PDF (the password is the PIN set when requesting it). `PdfStatementParser.parsePdf()`:

1. Opens and decrypts the PDF with `pdfrx`, extracting every page's text layer. If the PDF has no text layer at all (a scanned or flattened copy rather than the genuine export), this is detected and reported rather than silently importing nothing.
2. Reconstructs table rows from the raw text — M-Pesa wraps long `Details` fields across multiple lines, so a row is defined as everything from one receipt-code line up to the next.
3. Serialises the reconstructed rows back into CSV text and calls `StatementParser.parseCSV()` on it — the same parsing path the CSV tab uses, so no transaction-parsing logic is duplicated.
4. Cross-checks the parsed totals against the statement's own `SUMMARY` block and attaches a non-fatal warning (not a hard failure) if they disagree, so a handful of misread rows surfaces as "please review" rather than a silent discrepancy.

A wrong password raises `PdfPasswordException` from `pdfrx`, which is caught by type (not by string-matching the error) and surfaced as a distinct "incorrect password" error asking the user to re-enter the statement PIN.

---

## 8. Database Design

### Schema

```sql
CREATE TABLE transactions (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    ref              TEXT    NOT NULL UNIQUE,   -- M-Pesa transaction ref
    date             TEXT    NOT NULL,          -- ISO 8601 datetime
    amount           REAL    NOT NULL,
    type             TEXT    NOT NULL,          -- enum name
    counterparty     TEXT,                      -- name/number of other party
    balance          REAL,                      -- M-Pesa balance after tx
    transaction_cost REAL,                      -- fee charged
    raw_sms          TEXT    NOT NULL           -- original SMS or import note
);

CREATE INDEX idx_date ON transactions(date);
```

### Deduplication

Every M-Pesa transaction has a unique reference number (e.g. `RHL92ABC12`). The `UNIQUE` constraint on `ref` combined with `ConflictAlgorithm.ignore` means:

- Re-syncing SMS never creates duplicate records
- Re-importing the same CSV or PDF is safe
- Mixing sources (SMS + CSV + PDF of the same period) is safe

---

## 9. Heatmap Visualisation

### Grid Layout

The heatmap renders a **53-column × 7-row** grid:

```
         Jan    Feb    Mar    ...    Dec
Mon  [ ][ ][ ][ ][ ][ ][ ][ ][ ]...[ ]
Tue  [ ][ ][ ][ ][ ][ ][ ][ ][ ]...[ ]
Wed  [ ][ ][ ][ ][ ][ ][ ][ ][ ]...[ ]
Thu  [ ][ ][ ][ ][ ][ ][ ][ ][ ]...[ ]
Fri  [ ][ ][ ][ ][ ][ ][ ][ ][ ]...[ ]
Sat  [ ][ ][ ][ ][ ][ ][ ][ ][ ]...[ ]
Sun  [ ][ ][ ][ ][ ][ ][ ][ ][ ]...[ ]
```

- Each square = 1 day
- Columns = weeks (left = older, right = newer)
- Rows = Mon through Sun
- First/last weeks padded with empty cells to align

### Colour Intensity

| Level | Transactions/day |
|---|---|
| 0 | 0 |
| 1 | 1–2 |
| 2 | 3–5 |
| 3 | 6–10 |
| 4 | 11+ |

Level 0 (no activity) is always a neutral surface tone from the app's theme. Levels 1–4 come from the user's chosen colour theme (see [§10](#10-appearance--personalisation)) — separate ramps are tuned for light and dark mode so the palette stays legible in both.

### Interaction

- **Tap a cell** → navigates to `DayDetailScreen` for that date (if count > 0)
- **Today** → highlighted with a border
- **Long-press / hover** → tooltip shows date and transaction count
- **Year selector** → chevron buttons rebuild the heatmap for any year

---

## 10. Appearance & Personalisation

Both pickers below are reached from the overflow (⋮) button, which opens `MoreMenuSheet` — a rounded bottom-sheet card rather than a stock `PopupMenuButton` dropdown, so it shares the same visual language as the pickers it opens.

### 10.1 Light / Dark / System Theme

`MoreMenuSheet` → **Appearance** opens `AppearanceSheet`: three tappable tiles — System default, Light, Dark — each with a one-line description. The choice is persisted via `shared_preferences` (`ThemeProvider`) and applied instantly across the app through a shared `AppColors` `ThemeExtension`, so every screen and widget reads its colours from one source rather than hard-coded literals.

### 10.2 Heatmap Customisation

`MoreMenuSheet` → **Customize heatmap** opens `HeatmapCustomizeSheet`. Three independent choices, each persisted via `shared_preferences` (`HeatmapSettingsProvider`) and applied live everywhere heatmap colours are read — the grid, its legend, and the day-detail intensity dot:

| Setting | Options |
|---|---|
| **Colour theme** | 18 swatches (red, orange, yellow, lime, green, mint, teal, blue, indigo, purple, violet, magenta, pink, rose, slate, gray, steel, charcoal) |
| **Cell size** | Small / Medium / Large |
| **Cell shape** | Square / Circle |

Each colour theme is one fixed hue/saturation swatch rather than a hand-tuned 4-shade ramp; the level 1–4 intensity ramp is generated on the fly as a lightness gradient from that swatch (darker stops in dark mode, lighter stops in light mode), so every swatch in the picker gets a consistent, usable ramp without hand-authoring one per colour.

---

## 11. Sharing

Tapping the share icon in the app bar opens `ShareScreen` — a floating modal (not a full page push, so the app stays visible dimmed behind it) showing `ShareCard`: a "year in review" card with the heatmap and headline received/spent stats.

The card is captured to a PNG via the `screenshot` package, then either:

- **Saved to the device gallery** via `gal`, or
- **Handed to the native share sheet** via `share_plus`

---

## 12. Screens & Navigation

### HomeScreen

The main screen uses a `CustomScrollView` with `SliverAppBar`:

```
┌──────────────────────────────────┐
│  M-Pesa Tracker   [⟳] [↗] [⋮]   │  ← SliverAppBar (pinned)
├──────────────────────────────────┤
│  ← 2026 →                       │  ← Year selector
│  [Heatmap grid]                  │  ← HeatmapWidget (scrollable)
│  Less ■■■■■ More                │  ← Legend
├──────────────────────────────────┤
│  [Transactions] [Spent] [In]     │  ← SummaryStats
├──────────────────────────────────┤
│  Recent Transactions             │
│  ───────────────────────────────  │
│  [TransactionCard]               │  ← Swipe left to delete
│  [TransactionCard]               │
│  ...                             │
└──────────────────────────────────┘
│           [ Import ]             │  ← FAB
```

The overflow button (⋮) opens `MoreMenuSheet`, a bottom sheet holding **Appearance**, **Customize heatmap**, and **Clear all data** — see [§10](#10-appearance--personalisation).

### ImportScreen

Tabbed screen with three import methods:

- **PDF Statement tab** — file picker for the password-protected PDF export, plus a password field
- **Paste SMS tab** — multi-line text field, accepts one or many messages
- **CSV File tab** — file picker for `.csv` or `.txt` exports

### DayDetailScreen

Drilled-in view for a single day:

```
┌──────────────────────────────┐
│  Wednesday, May 1, 2026  ←  │
├──────────────────────────────┤
│  [Intensity card]             │
│  Intensity 3/4                │
│  Received: Ksh 1,000         │
│  Spent:    Ksh 2,500         │
│  Net:     -Ksh 1,500         │
├──────────────────────────────┤
│  5 transactions               │
│  [TransactionCard]            │
│  [TransactionCard]            │
│  ...                          │
└──────────────────────────────┘
```

### ShareScreen

Floating modal over the triggering screen — see [§11 Sharing](#11-sharing).

---

## 13. Permissions

The app requests the following Android permissions at runtime:

| Permission | Purpose | When requested |
|---|---|---|
| `READ_SMS` | Read M-Pesa messages from device inbox | On "Sync SMS" tap |
| `RECEIVE_SMS` | Declared for future real-time listening | On "Sync SMS" tap |
| `READ_EXTERNAL_STORAGE` | File import (Android ≤12) | On "Choose File" tap |
| `READ_MEDIA_*` | File import (Android 13+) | On "Choose File" tap |
| `WRITE_EXTERNAL_STORAGE` (`maxSdkVersion=29`) | Saving the share card to the gallery on Android ≤9 | On "Save to gallery" tap |

The manifest also sets `android:requestLegacyExternalStorage="true"`, which `gal` needs to write to the gallery on Android ≤9. Both this flag and `WRITE_EXTERNAL_STORAGE` are no-ops on Android 10+ (API 30+), which use scoped storage instead.

> **Import via Paste, CSV, or PDF** works completely **without any permissions** — the user manually supplies the data.

---

## 14. Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.2 | State management |
| `sqflite` | ^2.3.3+1 | Local SQLite database |
| `path` | ^1.9.0 | File path utilities |
| `file_picker` | ^8.1.2 | Pick CSV/TXT/PDF files |
| `permission_handler` | ^11.3.1 | Runtime permissions |
| `flutter_sms_inbox` | ^1.0.3 | Read device SMS inbox |
| `csv` | ^6.0.0 | Parse CSV statement exports |
| `pdfrx` | ^1.3.5 | Open + decrypt password-protected PDF statements, extract text |
| `intl` | ^0.19.0 | Date & number formatting |
| `shared_preferences` | ^2.3.2 | Persist theme + heatmap appearance choices |
| `screenshot` | ^3.0.0 | Capture the share card widget as a PNG |
| `share_plus` | ^12.0.2 | Hand the share card to the native share sheet |
| `gal` | ^2.3.2 | Save the share card to the device gallery |

---

## 15. Getting Started

### Prerequisites

- Flutter 3.44+ / Dart 3.12+ (`flutter --version`)
- Android device or emulator (API 21+)
- Android Studio or VS Code with Flutter extension

### Build & Run

```bash
# Clone the repository
git clone https://github.com/lawmaluki/M-Pesa-Activity-Tracker.git
cd M-Pesa-Activity-Tracker

# Install dependencies
flutter pub get

# Run on connected Android device
flutter run

# Build release APK
flutter build apk --release
```

### First Use

1. **Launch the app** — the heatmap starts empty
2. **Import data** using any of four methods:
   - Tap **Sync SMS** (top-right ⟳) → grant SMS permission → syncs all M-Pesa inbox messages automatically
   - Tap **Import FAB** → **PDF Statement** tab → choose your statement export → enter its password
   - Tap **Import FAB** → **Paste SMS** tab → paste copied M-Pesa messages → tap Import
   - Tap **Import FAB** → **CSV File** tab → choose your Safaricom statement export
3. **Tap any coloured cell** on the heatmap to see that day's transactions
4. **Use the year selector** (`< 2026 >`) to browse past years
5. **Tap the share icon** to generate a "year in review" card, then save it or share it
6. **Open the overflow menu (⋮)** to switch appearance (light/dark/system) or customise the heatmap's colour, cell size, and shape

---

## 16. Future Extensions

| Feature | Description |
|---|---|
| **Real-time SMS listener** | Native Android `BroadcastReceiver` via platform channel — auto-adds new M-Pesa messages as they arrive |
| **Monthly activity score** | Roll up spending/receiving into a single behavioural score per month |
| **Category breakdown** | Pie/bar chart of spend by type (Paybill, Buy Goods, Airtime, etc.) |
| **Budget alerts** | Set daily/weekly spending limits with notifications |
| **Export to CSV** | Re-export your parsed transaction history |
| **Multi-account** | Track multiple Safaricom lines |
| **Full finance dashboard** | Balance trends, net worth tracking, savings goals |

---

*M-Pesa Activity Tracker — built with Flutter. For personal use.*
