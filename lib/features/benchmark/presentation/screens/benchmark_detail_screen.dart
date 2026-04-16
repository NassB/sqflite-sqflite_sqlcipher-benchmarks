import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher_benchmarks/core/services/export_service.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_run.dart';
import 'package:sqflite_sqlcipher_benchmarks/shared/widgets/app_navigation_scaffold.dart';

class BenchmarkDetailScreen extends StatelessWidget {
  const BenchmarkDetailScreen({super.key, required this.run});

  final BenchmarkRun run;

  @override
  Widget build(BuildContext context) {
    final export = const ExportService();

    return AppNavigationScaffold(
      title: 'Benchmark detail',
      selectedIndex: 2,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${run.engine.label} • ${run.config.scenario.label}'),
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
