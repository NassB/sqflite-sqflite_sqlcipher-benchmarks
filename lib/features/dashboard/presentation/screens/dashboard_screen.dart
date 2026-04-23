import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_engine.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_run.dart';
import 'package:database_benchmarks/features/benchmark/presentation/providers/benchmark_providers.dart';
import 'package:database_benchmarks/features/history/presentation/providers/history_provider.dart';
import 'package:database_benchmarks/shared/widgets/app_navigation_scaffold.dart';

import '../../../benchmark/domain/entities/benchmark_scenario_type.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final stats = ref.watch(statsCalculatorProvider);

    return AppNavigationScaffold(
      title: 'SQLite Benchmark Dashboard',
      selectedIndex: 0,
      child: history.when(
        data: (runs) {
          if (runs.isEmpty) {
            return const Center(child: Text('No benchmarks recorded.'));
          }

          final latestByEngine = <BenchmarkEngine, BenchmarkRun>{};
          for (final run in runs) {
            latestByEngine.putIfAbsent(run.engine, () => run);
          }
          final latestSqflite = latestByEngine[BenchmarkEngine.sqflite];
          final latestCipher = latestByEngine[BenchmarkEngine.sqfliteSqlcipher];
          final delta = latestSqflite != null && latestCipher != null
              ? stats.deltaPercent(
                  reference: latestSqflite.summary.meanMs,
                  candidate: latestCipher.summary.meanMs,
                )
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Latest run'),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(runs.first.timestamp)),
                  trailing: Text(runs.first.config.scenario.label),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: latestByEngine.entries
                    .map(
                      (entry) => SizedBox(
                        width: 220,
                        child: _MetricCard(
                          title: entry.key.label,
                          value: '${entry.value.summary.meanMs.toStringAsFixed(2)} ms',
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (delta != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(stats.formatDeltaMessage(delta: delta, baseline: 'sqflite')),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go('/run'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run benchmark'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
