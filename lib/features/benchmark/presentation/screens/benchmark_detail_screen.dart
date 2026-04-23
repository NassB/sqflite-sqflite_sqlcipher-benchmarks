import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:database_benchmarks/core/services/export_service.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_run.dart';
import 'package:database_benchmarks/shared/widgets/app_navigation_scaffold.dart';

import '../../domain/entities/benchmark_engine.dart';
import '../../domain/entities/benchmark_scenario_type.dart';

class BenchmarkDetailScreen extends StatelessWidget {
  const BenchmarkDetailScreen({super.key, required this.run});

  final BenchmarkRun run;

  @override
  Widget build(BuildContext context) {
    final export = const ExportService();
    final theme = Theme.of(context);

    return AppNavigationScaffold(
      title: 'Benchmark detail',
      selectedIndex: 2,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary metrics ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${run.engine.label} • ${run.config.scenario.label}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('mean: ${run.summary.meanMs.toStringAsFixed(2)} ms'),
                  Text('median: ${run.summary.medianMs.toStringAsFixed(2)} ms'),
                  Text('p95: ${run.summary.p95Ms.toStringAsFixed(2)} ms'),
                  Text('ops/s: ${run.summary.opsPerSec.toStringAsFixed(2)}'),
                  Text('db size: ${run.summary.dbSizeBytes} bytes'),
                  Text('wal size: ${run.summary.walSizeBytes} bytes'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Metrics glossary ─────────────────────────────────────────────
          _MetricsGlossaryCard(scenario: run.config.scenario),
          const SizedBox(height: 12),

          // ── Scenario interpretation ──────────────────────────────────────
          _ScenarioInterpretationCard(engine: run.engine, scenario: run.config.scenario),
          const SizedBox(height: 12),

          // ── Line chart – per-iteration timings ───────────────────────────
          Text('Per-iteration timing (ms)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: run.samples
                        .map((e) => FlSpot(e.iteration.toDouble(), e.elapsedMs))
                        .toList(),
                    isCurved: true,
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Bar chart – mean / median / p95 ──────────────────────────────
          Text('Mean / Median / P95 (ms)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: run.summary.meanMs)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: run.summary.medianMs)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: run.summary.p95Ms)]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── General SQLCipher overhead note ──────────────────────────────
          const _SqlCipherOverheadNote(),
          const SizedBox(height: 12),

          // ── Export actions ───────────────────────────────────────────────
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final file = await export.exportRunJson(run);
                  await export.shareFile(file);
                },
                icon: const Icon(Icons.data_object),
                label: const Text('Export JSON'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final file = await export.exportRunsCsv([run], name: 'run_${run.id}');
                  await export.shareFile(file);
                },
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Export CSV'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Metrics glossary ─────────────────────────────────────────────────────────

class _MetricsGlossaryCard extends StatelessWidget {
  const _MetricsGlossaryCard({required this.scenario});

  final BenchmarkScenarioType scenario;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Text(
                  'How to read these metrics',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _GlossaryRow(
              term: 'Mean',
              definition:
                  'Arithmetic average across all iterations. Sensitive to outliers — '
                  'a single slow iteration pulls it up.',
            ),
            const _GlossaryRow(
              term: 'Median',
              definition:
                  'The middle value when iterations are sorted. More robust than the mean: '
                  'it reflects the "typical" run rather than the worst.',
            ),
            const _GlossaryRow(
              term: 'P95',
              definition:
                  '95th percentile — 95 % of iterations finished faster than this value. '
                  'Useful to detect tail latency spikes that the mean hides.',
            ),
            const _GlossaryRow(
              term: 'Ops/s',
              definition:
                  'Operations per second derived from the scenario\'s total operation count '
                  'and the cumulative wall-clock time. Higher is better.',
            ),
            const _GlossaryRow(
              term: 'DB size',
              definition:
                  'File size of the database after the run completes. '
                  'SQLCipher databases are slightly larger because each page stores '
                  'an encrypted MAC in addition to the data.',
            ),
            const _GlossaryRow(
              term: 'WAL size',
              definition:
                  'Size of the Write-Ahead Log file (if journal_mode=WAL is active). '
                  'A non-zero WAL means a checkpoint has not yet merged pages back into '
                  'the main file.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GlossaryRow extends StatelessWidget {
  const _GlossaryRow({required this.term, required this.definition});

  final String term;
  final String definition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(term, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(definition, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// ── Scenario-specific interpretation ─────────────────────────────────────────

class _ScenarioInterpretationCard extends StatelessWidget {
  const _ScenarioInterpretationCard({required this.engine, required this.scenario});

  final BenchmarkEngine engine;
  final BenchmarkScenarioType scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final explanation = _scenarioExplanation(scenario);

    return Card(
      color: theme.colorScheme.primaryContainer.withAlpha(80),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'sqflite vs sqflite_sqlcipher — ${scenario.label}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(explanation.headline, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(explanation.detail, style: theme.textTheme.bodySmall),
            if (explanation.tip != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      explanation.tip!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ScenarioExplanation _scenarioExplanation(BenchmarkScenarioType scenario) {
    switch (scenario) {
      case BenchmarkScenarioType.openDatabase:
        return const _ScenarioExplanation(
          headline: 'Opening a SQLCipher database takes noticeably longer.',
          detail:
              'When sqflite_sqlcipher opens a file for the first time, it must derive an '
              'AES-256 encryption key from the password using PBKDF2 (thousands of hash '
              'iterations by default). It then reads and decrypts the header page to verify '
              'integrity. sqflite skips all of that — its open cost is essentially just '
              'a file-open syscall plus a few pragma reads.\n\n'
              'Expect sqflite_sqlcipher to be 2–10× slower on first open, and still '
              'measurably slower on re-opens (key cache helps, but page MAC verification '
              'still applies).',
          tip:
              'If opening overhead is critical, consider keeping the database open for '
              'the lifetime of the app rather than opening/closing it per operation.',
        );

      case BenchmarkScenarioType.bulkInsert:
        return const _ScenarioExplanation(
          headline: 'Write-heavy workloads show the most encryption overhead.',
          detail:
              'Every page written by sqflite_sqlcipher is encrypted with AES-256-CBC '
              'before it hits disk. With batch inserts the CPU cost is proportional to the '
              'number of pages dirtied. sqflite writes pages as-is.\n\n'
              'The difference is most visible when WAL mode is active: WAL frames are '
              'each individually encrypted. Expect sqflite_sqlcipher to be 15–50% slower '
              'on large bulk inserts depending on page size, row size and hardware AES '
              'acceleration.',
          tip:
              'Wrapping bulk inserts in a single transaction minimises the number of '
              'WAL flushes, reducing encryption cost for sqflite_sqlcipher.',
        );

      case BenchmarkScenarioType.read:
        return const _ScenarioExplanation(
          headline: 'Read operations incur a page-decryption cost.',
          detail:
              'sqflite_sqlcipher must decrypt each database page before SQLite can parse '
              'it. Pages that are already in the page cache do not need to be re-decrypted, '
              'so repeated reads of the same data can be fast. Cold reads (first access '
              'after open, or after the page cache is evicted) always pay the AES cost.\n\n'
              'For small, indexed lookups the overhead is usually under 10 %. For large '
              'sequential scans that exceed the page-cache size, overhead grows.',
          tip:
              'The cache_size PRAGMA controls how many pages stay in memory. A larger '
              'cache reduces repeated decryption at the cost of RAM.',
        );

      case BenchmarkScenarioType.update:
        return const _ScenarioExplanation(
          headline: 'Updates involve both decryption (read) and encryption (write).',
          detail:
              'SQLite reads the target page, modifies it in memory, then writes it back '
              'encrypted. sqflite_sqlcipher therefore pays a double cost — decrypt on read '
              'and encrypt on write — compared to sqflite which does neither.\n\n'
              'For in-place row updates the overhead is typically 20–40% on modern '
              'hardware with AES-NI. Without hardware AES acceleration (some older '
              'Android devices) the gap can be much wider.',
          tip:
              'Batching updates in a single transaction reduces the number of page '
              'flushes and amortises the encryption cost across many changes.',
        );

      case BenchmarkScenarioType.delete:
        return const _ScenarioExplanation(
          headline: 'Deletes write a modified page back, triggering encryption.',
          detail:
              'When rows are deleted, SQLite marks the affected page(s) as free or rewrites '
              'them. sqflite_sqlcipher encrypts every modified page on write, just as with '
              'updates. The overhead is similar to the update scenario.\n\n'
              'A full purge (DELETE without WHERE) may be faster than expected in both '
              'engines because SQLite can truncate the file or zero-fill pages rather than '
              'writing individual rows — the encryption cost shrinks accordingly.',
          tip: null,
        );

      case BenchmarkScenarioType.mixed:
        return const _ScenarioExplanation(
          headline: 'Mixed workloads blend read, write and update overhead.',
          detail:
              'With a 70/20/10 read/insert/update split the overall overhead of '
              'sqflite_sqlcipher is a weighted average of the individual scenario costs. '
              'Reads are cheaper (cache hits amortise decryption) while inserts and updates '
              'are more expensive (every dirty page is encrypted).\n\n'
              'In practice, a mixed production workload typically shows sqflite_sqlcipher '
              '10–30% slower than sqflite end-to-end. The exact ratio depends on the '
              'read/write ratio and how warm the page cache is.',
          tip:
              'Run this scenario with several iteration counts to see how the cache '
              'warm-up effect changes the gap between engines.',
        );

      case BenchmarkScenarioType.repeatedOpenClose:
        return const _ScenarioExplanation(
          headline: 'Each open requires key derivation — costs accumulate quickly.',
          detail:
              'This scenario is the most discriminating for sqflite_sqlcipher. Every '
              'open call triggers PBKDF2 key derivation (configurable iteration count, '
              'default is 64 000 HMAC-SHA1 rounds in SQLCipher 4). On a mid-range phone '
              'that can take 50–200 ms per open.\n\n'
              'sqflite has no such cost — repeated opens are nearly free. The total time '
              'here reflects the true cost of designing an app that opens the database '
              'on demand rather than keeping a long-lived connection.',
          tip:
              'In production apps, open the database once at startup and keep the '
              'connection alive for the app lifecycle. Never open/close per request.',
        );

      case BenchmarkScenarioType.full:
        return const _ScenarioExplanation(
          headline: 'End-to-end total cost across all scenarios on the same database.',
          detail:
              'The Full benchmark runs every individual scenario (open/close, bulk insert, '
              'read, update, delete, mixed, and repeated open/close) sequentially on a '
              'single database file without resetting between them. The elapsed time shown '
              'here is the cumulative wall-clock time for the entire sequence.\n\n'
              'Because sqflite_sqlcipher pays an encryption or decryption cost on every '
              'page it reads or writes, the total overhead compounds across all the '
              'write-heavy sub-scenarios (bulk insert, update, delete, mixed). '
              'The open/close sub-steps also add PBKDF2 key-derivation overhead that '
              'sqflite never incurs.\n\n'
              'In practice, sqflite_sqlcipher typically completes this full sequence '
              '20–50 % slower than sqflite, depending on hardware AES acceleration and '
              'storage speed.',
          tip:
              'Use this scenario to get a single representative number for the total '
              'cost of encrypting your database. Compare individual sub-scenarios '
              'separately for more granular analysis.',
        );
    }
  }
}

class _ScenarioExplanation {
  const _ScenarioExplanation({
    required this.headline,
    required this.detail,
    required this.tip,
  });

  final String headline;
  final String detail;
  final String? tip;
}

// ── General SQLCipher overhead note ──────────────────────────────────────────

class _SqlCipherOverheadNote extends StatelessWidget {
  const _SqlCipherOverheadNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Important notes on result interpretation',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '• Always compare results measured on the same physical device. '
              'CPU speed, storage type (eMMC vs UFS) and the presence of hardware AES '
              'acceleration (AES-NI on ARM) heavily influence both absolute timings and '
              'the relative gap between engines.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              '• Run benchmarks in profile or release mode only. Debug mode disables '
              'optimisations and adds VM overhead that distorts every measurement.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              '• A warm-up iteration before measurement allows both engines to initialise '
              'internal structures (page cache, statement cache). Without warm-up the first '
              'iteration is an outlier and inflates the mean.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              '• SQLCipher\'s encryption is transparent to the application layer — the '
              'SQL API, schema and query results are identical. The only observable '
              'differences are performance and the fact that the database file is opaque '
              'binary without the correct key.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              '• Compare median values rather than means when the number of iterations '
              'is small (<10). Outliers caused by GC pauses, thermal throttling or OS '
              'scheduling can skew the mean significantly.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
