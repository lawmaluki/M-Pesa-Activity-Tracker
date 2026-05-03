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
10. [Screens & Navigation](#10-screens--navigation)
11. [Permissions](#11-permissions)
12. [Dependencies](#12-dependencies)
13. [Getting Started](#13-getting-started)
14. [Future Extensions](#14-future-extensions)

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
- **5-level Safaricom-green intensity palette** based on daily transaction count
- Tap any cell to see every transaction on that day
- Year selector to navigate historical data
- Today's date highlighted with a white border

### 2.4 Transaction Management

- Full transaction list with swipe-to-delete
- Per-day detail view with net flow summary (received vs spent)
- Automatic deduplication — re-importing the same data never creates duplicates
- Clear all data option

---

## 3. Architecture

The app uses a clean layered architecture:

```
┌─────────────────────────────────────────────────────┐
│                    UI Layer                          │
│   HomeScreen  │  ImportScreen  │  DayDetailScreen   │
│   HeatmapWidget  │  TransactionCard  │  SummaryStats│
└────────────────────────┬────────────────────────────┘
                         │  reads/writes via
┌────────────────────────▼────────────────────────────┐
│               State Layer (Provider)                 │
│             TransactionProvider                      │
│  - holds transactions list                           │
│  - holds daily count/amount maps for heatmap        │
│  - exposes sync, import, delete actions             │
└────────────────────────┬────────────────────────────┘
                         │  calls
┌────────────────────────▼────────────────────────────┐
│                 Service Layer                        │
│  SmsService  │  SmsParser  │  StatementParser       │
│              DatabaseService                         │
└────────────────────────┬────────────────────────────┘
                         │  persists to
┌────────────────────────▼────────────────────────────┐
│              Data Layer (SQLite)                     │
│            mpesa_tracker.db                         │
│            transactions table                        │
└─────────────────────────────────────────────────────┘
```

**State Management:** Provider (`ChangeNotifier`) — chosen for simplicity and testability without the overhead of BLoC or Riverpod for this app size.

**Local Storage:** SQLite via `sqflite` — durable, queryable, zero-config.

---

## 4. Project Structure

```
lib/
├── main.dart                        # Entry point, app theme, Provider setup
├── models/
│   └── transaction.dart             # MpesaTransaction, DaySummary, TransactionType
├── services/
│   ├── database_service.dart        # SQLite singleton, CRUD, aggregation queries
│   ├── sms_parser.dart              # Regex parser for M-Pesa SMS format
│   ├── sms_service.dart             # Reads device inbox, permissions
│   └── statement_parser.dart        # CSV + pasted-SMS bulk import
├── providers/
│   └── transaction_provider.dart    # ChangeNotifier, app-wide state
├── screens/
│   ├── home_screen.dart             # Main screen: heatmap + stats + list
│   ├── import_screen.dart           # Tabbed import: paste SMS / CSV file
│   └── day_detail_screen.dart       # Per-day transaction breakdown
└── widgets/
    ├── heatmap_widget.dart          # Custom GitHub-style heatmap grid
    ├── transaction_card.dart        # Dismissible transaction list item
    └── summary_stats.dart           # 3-tile stats row (count/spent/received)

android/
└── app/src/main/
    └── AndroidManifest.xml          # SMS + storage permissions

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

---

## 6. Key Components

### 6.1 TransactionProvider (`providers/transaction_provider.dart`)

The single source of truth for all UI state.

| Property | Type | Description |
|---|---|---|
| `transactions` | `List<MpesaTransaction>` | All transactions, newest first |
| `dailyCounts` | `Map<String, int>` | `"yyyy-MM-dd"` → count, for heatmap |
| `dailyAmounts` | `Map<String, double>` | `"yyyy-MM-dd"` → total amount |
| `selectedYear` | `int` | Year displayed on heatmap |
| `selectedDay` | `DateTime?` | Day tapped on heatmap |
| `state` | `LoadState` | `idle / loading / error` |

Key actions: `loadData()`, `syncSms()`, `importCsv()`, `importPastedSms()`, `deleteTransaction()`, `clearAll()`, `setSelectedYear()`, `selectDay()`

### 6.2 DatabaseService (`services/database_service.dart`)

Singleton SQLite wrapper. All queries are async-safe via sqflite's internal locking.

Notable methods:

```dart
// Batch insert with automatic dedup
Future<int> insertTransactionsBatch(List<MpesaTransaction> txs)

// Returns {yyyy-MM-dd: count} for an entire year — used to build heatmap
Future<Map<String, int>> fetchDailyCountsForYear(int year)

// Returns {yyyy-MM-dd: total_amount} for an entire year
Future<Map<String, double>> fetchDailyAmountsForYear(int year)
```

### 6.3 SmsParser (`services/sms_parser.dart`)

Pure Dart regex parser with no platform dependencies — fully unit-testable.

Extracts from each SMS message:
- **Reference** — the 10–12 character transaction code (e.g. `RHL92ABC12`)
- **Amount** — `Ksh1,234.00` → `1234.00`
- **Date & Time** — `1/5/26 at 2:30 PM` → `DateTime(2026, 5, 1, 14, 30)`
- **Type** — inferred from verb: *sent / received / withdrawn / paid / airtime*
- **Counterparty** — name and phone number after the verb
- **Balance** — new M-Pesa balance after transaction
- **Transaction cost** — fee charged

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
    balance          TEXT,                      -- M-Pesa balance after tx
    transaction_cost REAL,                      -- fee charged
    raw_sms          TEXT    NOT NULL           -- original SMS or import note
);

CREATE INDEX idx_date ON transactions(date);
```

### Deduplication

Every M-Pesa transaction has a unique reference number (e.g. `RHL92ABC12`). The `UNIQUE` constraint on `ref` combined with `ConflictAlgorithm.ignore` means:

- Re-syncing SMS never creates duplicate records
- Re-importing the same CSV is safe
- Mixing sources (SMS + CSV of the same period) is safe

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

| Level | Transactions/day | Colour |
|---|---|---|
| 0 | 0 | `#1C1C1E` (dark surface) |
| 1 | 1–2 | `#0A3D1F` (very dark green) |
| 2 | 3–5 | `#1A6B38` |
| 3 | 6–10 | `#25A244` |
| 4 | 11+ | `#4CD964` (brightest) |

The palette mirrors **Safaricom's brand green** at increasing brightness levels.

### Interaction

- **Tap a cell** → navigates to `DayDetailScreen` for that date (if count > 0)
- **Today** → highlighted with a white border
- **Tooltip** → shows date and transaction count on long-press
- **Year selector** → `<` and `>` buttons rebuild the heatmap for any year

---

## 10. Screens & Navigation

### HomeScreen

The main screen uses a `CustomScrollView` with `SliverAppBar`:

```
┌──────────────────────────────┐
│  M-Pesa Tracker    [⟳] [⋮]  │  ← SliverAppBar (pinned)
├──────────────────────────────┤
│  ← 2026 →                   │  ← Year selector
│  [Heatmap grid]              │  ← HeatmapWidget (scrollable)
│  Less ■■■■■ More            │  ← Legend
├──────────────────────────────┤
│  [Transactions] [Spent] [In] │  ← SummaryStats
├──────────────────────────────┤
│  Recent Transactions         │
│  ─────────────────────────── │
│  [TransactionCard]           │  ← Swipe left to delete
│  [TransactionCard]           │
│  ...                         │
└──────────────────────────────┘
│         [ Import ]           │  ← FAB
```

### ImportScreen

Tabbed screen with two import methods:

- **Paste SMS tab** — multi-line text field, accepts one or many messages
- **CSV File tab** — file picker for `.csv` or `.txt` exports

### DayDetailScreen

Drilled-in view for a single day:

```
┌──────────────────────────────┐
│  Wednesday, May 1, 2026  ←  │
├──────────────────────────────┤
│  [Green gradient card]       │
│  Intensity 3/4               │
│  Received: Ksh 1,000        │
│  Spent:    Ksh 2,500        │
│  Net:     -Ksh 1,500        │
├──────────────────────────────┤
│  5 transactions              │
│  [TransactionCard]           │
│  [TransactionCard]           │
│  ...                         │
└──────────────────────────────┘
```

---

## 11. Permissions

The app requests the following Android permissions at runtime:

| Permission | Purpose | When requested |
|---|---|---|
| `READ_SMS` | Read M-Pesa messages from device inbox | On "Sync SMS" tap |
| `RECEIVE_SMS` | Declared for future real-time listening | On "Sync SMS" tap |
| `READ_EXTERNAL_STORAGE` | File import (Android ≤12) | On "Choose File" tap |
| `READ_MEDIA_*` | File import (Android 13+) | On "Choose File" tap |

> **Import via Paste or CSV** works completely **without any permissions** — the user manually copies the data.

---

## 12. Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.2 | State management |
| `sqflite` | ^2.3.3+1 | Local SQLite database |
| `path` | ^1.9.0 | File path utilities |
| `path_provider` | ^2.1.3 | Platform-specific directories |
| `file_picker` | ^8.1.2 | Pick CSV/TXT files |
| `permission_handler` | ^11.3.1 | Runtime permissions |
| `flutter_sms_inbox` | ^1.0.3 | Read device SMS inbox |
| `csv` | ^6.0.0 | Parse CSV statement exports |
| `intl` | ^0.19.0 | Date & number formatting |

---

## 13. Getting Started

### Prerequisites

- Flutter 3.41+ (`flutter --version`)
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
2. **Import data** using any of three methods:
   - Tap **Sync SMS** (top-right ⟳) → grant SMS permission → syncs all M-Pesa inbox messages automatically
   - Tap **Import FAB** → **Paste SMS** tab → paste copied M-Pesa messages → tap Import
   - Tap **Import FAB** → **CSV File** tab → choose your Safaricom statement export
3. **Tap any green cell** on the heatmap to see that day's transactions
4. **Use the year selector** (`< 2026 >`) to browse past years

---

## 14. Future Extensions

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
