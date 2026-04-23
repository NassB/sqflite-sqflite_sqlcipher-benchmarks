# Database Benchmarks

A Flutter benchmarking app for **Android and iOS** that measures and compares multiple database packages under identical, reproducible conditions.

---

## Table of Contents

- [Purpose](#purpose)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Screens](#screens)
- [Benchmark Scenarios](#benchmark-scenarios)
- [Configuration Reference](#configuration-reference)
- [SQLite PRAGMA Defaults](#sqlite-pragma-defaults)
- [Statistics & Metrics](#statistics--metrics)
- [Database Engines Currently Benchmarked](#database-engines-currently-benchmarked)
- [Methodology & Measurement Guarantees](#methodology--measurement-guarantees)
- [Methodological Limitations](#methodological-limitations)
- [Export Formats](#export-formats)
- [Getting Started](#getting-started)
- [Running Tests](#running-tests)
- [Project Dependencies](#project-dependencies)
- [Extension Ideas](#extension-ideas)

---

## Purpose

The app answers one question: **how do different Flutter database engines compare on common CRUD workloads?**

It runs equivalent workloads against selected engines with the same scenario settings (iterations, record counts, warmup/reset behavior, and metrics collection), then surfaces side-by-side statistics you can export and analyse.

---

## Key Features

- Eight reproducible benchmark scenarios (including a **Full** end-to-end scenario).
- Optional warmup iteration to eliminate cold-start bias.
- Optional database reset between runs for isolation.
- Configurable SQLite PRAGMAs (`journal_mode`, `synchronous`, `temp_store`, `cache_size`, `foreign_keys`).
- Live log panel showing iteration progress in real time.
- Statistical summary: total, mean, median, min, max, p95, ops/s.
- DB file size and WAL file size captured after each run.
- Persistent run history stored locally as JSON.
- Export individual runs as **JSON** or export any set of runs as **CSV**.
- Share exports directly from the device via the system share sheet.
- Light / Dark / System theme support.

---

## Architecture

The project follows a feature-first clean architecture with a presentation → domain → data layering inside each feature.

```
lib/
├── app/                        # Router and root app widget
├── core/
│   ├── constants/              # AppConstants (file names, folder names)
│   ├── services/               # StatsCalculator, ExportService, DeviceMetadataService
│   └── utils/
├── features/
│   ├── benchmark/
│   │   ├── data/
│   │   │   ├── adapters/       # Sqflite/SQLCipher/Drift/Hive/Sembast/ObjectBox/Isar adapters
│   │   │   └── services/       # BenchmarkRunner, BenchmarkFakeDataGenerator
│   │   ├── domain/
│   │   │   ├── entities/       # BenchmarkRun, BenchmarkSummary, BenchmarkScenarioConfig, …
│   │   │   └── repositories/   # DatabaseAdapter (abstract interface)
│   │   └── presentation/
│   │       ├── providers/      # BenchmarkController (Riverpod Notifier), BenchmarkRunState
│   │       └── screens/        # RunBenchmarkScreen, BenchmarkDetailScreen
│   ├── dashboard/
│   │   └── presentation/screens/  # DashboardScreen
│   ├── history/
│   │   ├── data/               # HistoryRepository (JSON file persistence)
│   │   └── presentation/
│   │       ├── providers/      # historyProvider
│   │       └── screens/        # HistoryScreen
│   └── settings/
│       └── presentation/
│           ├── providers/      # settingsProvider (in-memory Riverpod state)
│           └── screens/        # SettingsScreen
└── shared/
    ├── theme/
    └── widgets/                # AppNavigationScaffold (bottom nav)
```

State management uses **Riverpod** (`flutter_riverpod`). Navigation uses **go_router** with five named routes: `/`, `/run`, `/history`, `/detail`, `/settings`.

---

## Screens

| Screen | Route | Description |
|--------|-------|-------------|
| **Dashboard** | `/` | Shows the last recorded run for each engine and the mean-time delta between them. Quick-launch button to go directly to the Run screen. |
| **Run benchmark** | `/run` | Configure and launch a benchmark. Scenario picker, engine chips, iterations, record count, SQLCipher password, warmup / reset toggles. Live log stream during execution. |
| **History** | `/history` | List of all past runs sorted by date. Tap a run to open its detail. Delete individual runs or clear all from Settings. |
| **Benchmark detail** | `/detail` | Full statistics for a run: summary card, metrics glossary, scenario interpretation, per-iteration line chart, mean/median/p95 bar chart, JSON / CSV export actions. |
| **Settings** | `/settings` | Default SQLCipher password, default seed, theme selector, PRAGMA reset, history clear. |

---

## Benchmark Scenarios

Each scenario stresses a different class of SQLite operations. You can run any one scenario against one or both engines simultaneously.

| Scenario | What it measures |
|----------|-----------------|
| **Open database** | Cost of opening (and re-opening) the database file N times. For `sqflite_sqlcipher` this includes PBKDF2 key derivation on first open. |
| **Bulk insert** | Batch-insert N rows in a single transaction. Measures write throughput and page-encryption overhead. |
| **Read** | Read-by-id, paginated list query, two filtered raw queries, and a COUNT on a pre-populated table. Measures page-decryption overhead for reads. |
| **Update** | Bulk-insert N rows then update all of them in one statement. Measures write-back cost. |
| **Delete** | Bulk-insert N rows then delete them via id list, id range, and full purge. |
| **Mixed workload** | Bulk-insert N rows then run M mixed operations: 70 % reads, 20 % inserts, 10 % updates. Reflects a realistic production workload. |
| **Repeated open/close** | Open and close the connection N times in a tight loop. Isolates connection-lifecycle overhead. |
| **Full benchmark** | Runs **all of the above scenarios sequentially on the same database file**, without resetting between sub-steps. Gives a single cumulative timing representative of full-app usage. Iterations and record count are fixed (1 iteration, 500 records) and cannot be changed. A confirmation dialog is shown before the run because it may take several minutes. |

### Full benchmark — internal order

1. Repeated open/close (cold, before any data)
2. Schema creation
3. Bulk insert
4. Read (uses data from step 3)
5. Update (uses data from step 3)
6. Delete (clears the table)
7. Mixed workload (re-inserts fresh rows, then mixed ops)
8. Repeated open/close (warm, with data present)

---

## Configuration Reference

All parameters are exposed on the **Run benchmark** screen. They are stored in a `BenchmarkScenarioConfig` object.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `scenario` | `bulkInsert` | Which scenario to run. |
| `engines` | both | Which engines to benchmark. |
| `iterations` | 5 | Number of timed iterations per engine (fixed to 1 for Full). |
| `recordCount` | 1 000 | Number of rows involved in data scenarios (fixed to 500 for Full). |
| `limit` | 100 | Page size used in read / delete queries. |
| `offset` | 0 | Offset used in paginated reads. |
| `enableBatch` | true | Use `batch().commit()` for inserts (faster). |
| `enableTransaction` | true | Wrap individual inserts in a transaction. |
| `resetDatabase` | true | Delete and recreate the DB file before each run. |
| `enableWarmup` | true | Run one un-timed iteration before measuring. |
| `openRepeatCount` | 10 | Number of open/close cycles in the open/repeated-open scenarios. |
| `mixedOperations` | 1 000 | Total number of operations in the Mixed and Full scenarios. |
| `mixedReadRatio` | 70 | Percentage of reads in mixed operations. |
| `mixedInsertRatio` | 20 | Percentage of inserts in mixed operations. |
| `mixedUpdateRatio` | 10 | Percentage of updates in mixed operations. |
| `seed` | 42 | Random seed for deterministic fake data generation. |
| `sqlcipherPassword` | `benchmark_password` | Password used by `sqflite_sqlcipher`. |
| `pragmas` | see below | SQLite PRAGMA configuration applied after opening. |

---

## SQLite PRAGMA Defaults

The following PRAGMAs are applied to every connection after opening. They can be reset to these defaults from the Settings screen.

| PRAGMA | Default | Effect |
|--------|---------|--------|
| `journal_mode` | `WAL` | Write-Ahead Logging — better read concurrency, lower write latency. |
| `synchronous` | `NORMAL` | Flush at safe checkpoints; faster than `FULL` with acceptable durability. |
| `temp_store` | `MEMORY` | Temporary tables and indices kept in memory. |
| `cache_size` | `-2000` | Negative value = kilobytes; 2 MB page cache. |
| `foreign_keys` | `true` | Enforce foreign key constraints. |

---

## Statistics & Metrics

After each scenario run the following statistics are computed by `StatsCalculator` and stored in `BenchmarkSummary`:

| Metric | Description |
|--------|-------------|
| `totalMs` | Sum of all iteration times in milliseconds. |
| `meanMs` | Arithmetic mean of iteration times. |
| `medianMs` | Middle value of the sorted sample — more robust than mean for skewed distributions. |
| `minMs` | Fastest single iteration. |
| `maxMs` | Slowest single iteration. |
| `p95Ms` | 95th percentile — indicates tail latency. |
| `opsPerSec` | Operations per second = `operationCount / (totalMs / 1000)`. |
| `dbSizeBytes` | Size of the main database file after the run. |
| `walSizeBytes` | Size of the WAL file after the run (0 if WAL was checkpointed). |

**How to read results:**

- Compare **median + p95** first; they are more representative than the mean when a few iterations are outliers.
- Use **ops/s** to compare raw throughput across different record counts.
- Use **DB/WAL size** to understand the storage footprint of each engine and the effect of your PRAGMA choices.
- The dashboard shows the **mean delta %** between comparable runs.

---

## Database Engines Currently Benchmarked

The app currently benchmarks the following engines:

- `sqflite`
- `sqflite_sqlcipher`
- `drift`
- `hive`
- `sembast`
- `objectbox`
- `isar_community`

Scenarios are executed through a common adapter contract so each engine is measured with the same benchmark flow and reporting model.

---

## Methodology & Measurement Guarantees

- **Timing**: measured with Dart's `Stopwatch` at microsecond resolution, converted to milliseconds. The clock starts immediately after the initial `open()` call and stops before the final `close()`.
- **Warmup**: if enabled, one full un-timed iteration is executed before the measured iterations. This amortises JIT compilation, OS page cache cold starts, and Flutter engine warm-up.
- **Isolation**: each engine gets its own storage/database namespace (for SQLite-based engines, dedicated files such as `bench_db_<engine>.db`). If reset is enabled, storage is recreated before the run.
- **Fake data**: generated deterministically from a configurable seed via `BenchmarkFakeDataGenerator`. The same seed always produces the same rows.
- **Cancellation**: any run can be cancelled mid-flight; partial results are discarded.

---

## Methodological Limitations

> **Always run benchmarks in `--profile` or `--release` mode.**
> Debug mode disables AOT compilation, runs Dart in interpreter/JIT mode with extra assertions and instrumentation, and produces timings 5–20× slower than production.

- Results vary with device temperature, battery level, system I/O load, and background processes. Take multiple samples and average.
- **Avoid the emulator** — emulated storage and the absence of hardware AES acceleration make results incomparable to physical devices.
- The warmup iteration only partially eliminates cold-page-cache effects. On devices with slow flash storage, the first measured iteration may still be an outlier even with warmup enabled.
- SQLCipher-specific settings (such as PBKDF2 iteration count) are configurable at the library level and can affect `sqflite_sqlcipher` results.

---

## Export Formats

### JSON (single run)

Exported to `<documents>/exports/run_<id>.json`. Contains the full `BenchmarkRun` object including config, all per-iteration samples, summary statistics, and device metadata.

### CSV (one or more runs)

Exported to `<documents>/exports/benchmark_runs.csv`. Columns:

```
id, timestamp, engine, scenario, total_ms, mean_ms, median_ms,
p95_ms, ops_per_sec, db_size_bytes, wal_size_bytes, success
```

Both formats are shareable directly from the device via the system share sheet (`share_plus`).

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.10 (Dart ≥ 3.10)
- A physical Android or iOS device (strongly recommended over an emulator)

### Setup

```bash
# Verify Flutter version
flutter --version

# Install dependencies
flutter pub get
```

### Running the app

```bash
# Profile mode (recommended for benchmarking)
flutter run --profile

# Release mode
flutter run --release

# Debug mode — UI development only, NOT for benchmarking
flutter run
```

### Code generation (optional — only needed if adding freezed/json_serializable models)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Running Tests

```bash
# Unit tests — statistics calculator
flutter test test/core/services/stats_calculator_test.dart

# Unit tests — JSON round-trip for BenchmarkRun
flutter test test/features/benchmark/domain/benchmark_run_mapping_test.dart

# Widget tests — RunBenchmarkScreen
flutter test test/features/benchmark/presentation/run_benchmark_screen_test.dart

# Integration test — minimal benchmark flow (requires a connected device)
flutter test integration_test/minimal_benchmark_flow_test.dart
```

Run all unit and widget tests at once:

```bash
flutter test test/
```

---

## Project Dependencies

| Package | Version | Role |
|---------|---------|------|
| `flutter_riverpod` | ^2.5.1 | State management |
| `go_router` | ^14.2.3 | Declarative navigation |
| `sqflite` | ^2.3.3+1 | SQLite engine |
| `sqflite_sqlcipher` | ^3.2.0 | AES-256 encrypted SQLite engine |
| `drift` / `drift_flutter` | ^2.28.2 / ^0.2.5 | Typed SQLite layer |
| `hive` | ^2.2.3 | Lightweight key-value store |
| `sembast` | ^3.8.5+1 | NoSQL persistent store |
| `objectbox` | ^4.3.0 | Object-oriented local database |
| `isar_community` | ^3.1.0+1 | Local NoSQL database |
| `fl_chart` | ^0.69.0 | Line and bar charts in the detail screen |
| `csv` | ^6.0.0 | CSV serialisation for exports |
| `share_plus` | ^10.1.4 | Native share sheet for file export |
| `device_info_plus` | ^10.1.2 | Device model / OS version metadata |
| `package_info_plus` | ^8.0.2 | App version metadata |
| `path` / `path_provider` | — | File system path helpers |
| `intl` | ^0.19.0 | Date formatting |
| `collection` | ^1.18.0 | `minOrNull` / `maxOrNull` helpers |

**Dev dependencies:** `flutter_lints`, `mocktail`, `build_runner`, `freezed`, `json_serializable`.

---

## Extension Ideas

- **Add more engines** — implement `DatabaseAdapter` for additional backends (for example `sqlite3` FFI or Realm) without touching existing benchmark scenarios.
- **Multi-run comparison** — render two runs side-by-side in the detail screen (grouped bar chart).
- **Persist settings** — write `settingsProvider` state to shared preferences so choices survive app restarts.
- **Global CSV export** — export the entire history across all scenarios in one file.
- **Scenario presets** — save named configurations for quick recall.
- **Hardware AES detection** — surface whether the device has hardware-accelerated AES, which can significantly affect encrypted-engine results.
