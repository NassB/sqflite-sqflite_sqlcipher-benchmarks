import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_engine.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_scenario_config.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_scenario_type.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/presentation/providers/benchmark_providers.dart';
import 'package:sqflite_sqlcipher_benchmarks/shared/widgets/app_navigation_scaffold.dart';

class RunBenchmarkScreen extends ConsumerStatefulWidget {
  const RunBenchmarkScreen({super.key});

  @override
  ConsumerState<RunBenchmarkScreen> createState() => _RunBenchmarkScreenState();
}

class _RunBenchmarkScreenState extends ConsumerState<RunBenchmarkScreen> {
  late TextEditingController _iterations;
  late TextEditingController _records;
  late TextEditingController _password;

  @override
  void initState() {
    super.initState();
    final config = ref.read(benchmarkControllerProvider).config;
    _iterations = TextEditingController(text: '${config.iterations}');
    _records = TextEditingController(text: '${config.recordCount}');
    _password = TextEditingController(text: config.sqlcipherPassword);
  }

  @override
  void dispose() {
    _iterations.dispose();
    _records.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Shows a confirmation dialog before running the Full benchmark.
  /// Returns [true] if the user confirmed, [false] otherwise.
  Future<bool> _confirmFullBenchmark() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Full Benchmark'),
        content: const Text(
          'This will run all scenarios sequentially on the same database without '
          'resetting between them.\n\n'
          'Depending on your device, this may take several minutes to complete.\n\n'
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Run'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(benchmarkControllerProvider);
    final controller = ref.read(benchmarkControllerProvider.notifier);
    final isFull = state.config.scenario == BenchmarkScenarioType.full;

    return AppNavigationScaffold(
      title: 'Run benchmark',
      selectedIndex: 1,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<BenchmarkScenarioType>(
            key: const ValueKey('scenarioDropdown'),
            value: state.config.scenario,
            decoration: const InputDecoration(labelText: 'Scenario'),
            items: BenchmarkScenarioType.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              var newConfig = state.config.copyWith(scenario: value);
              if (value == BenchmarkScenarioType.full) {
                newConfig = newConfig.copyWith(
                  iterations: BenchmarkScenarioTypeX.fullIterations,
                  recordCount: BenchmarkScenarioTypeX.fullRecordCount,
                );
                _iterations.text = '${BenchmarkScenarioTypeX.fullIterations}';
                _records.text = '${BenchmarkScenarioTypeX.fullRecordCount}';
              }
              controller.updateConfig(newConfig);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('iterationsField'),
            controller: _iterations,
            keyboardType: TextInputType.number,
            readOnly: isFull,
            decoration: InputDecoration(
              labelText: 'Iterations',
              helperText: isFull ? 'Fixed for Full benchmark' : null,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('recordCountField'),
            controller: _records,
            keyboardType: TextInputType.number,
            readOnly: isFull,
            decoration: InputDecoration(
              labelText: 'Record count',
              helperText: isFull ? 'Fixed for Full benchmark' : null,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('sqlcipherPasswordField'),
            controller: _password,
            decoration: const InputDecoration(labelText: 'SQLCipher password'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: BenchmarkEngine.values
                .map(
                  (engine) => FilterChip(
                    label: Text(engine.label),
                    selected: state.config.engines.contains(engine),
                    onSelected: (selected) {
                      final engines = [...state.config.engines];
                      if (selected) {
                        engines.add(engine);
                      } else {
                        engines.remove(engine);
                      }
                      if (engines.isEmpty) return;
                      controller.updateConfig(state.config.copyWith(engines: engines));
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: state.config.enableWarmup,
            onChanged: (value) => controller.updateConfig(state.config.copyWith(enableWarmup: value)),
            title: const Text('Warmup'),
          ),
          SwitchListTile(
            value: state.config.resetDatabase,
            onChanged: (value) => controller.updateConfig(state.config.copyWith(resetDatabase: value)),
            title: const Text('Reset DB before run'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.isRunning
                ? null
                : () async {
                    final iterations = isFull
                        ? BenchmarkScenarioTypeX.fullIterations
                        : int.tryParse(_iterations.text) ?? state.config.iterations;
                    final records = isFull
                        ? BenchmarkScenarioTypeX.fullRecordCount
                        : int.tryParse(_records.text) ?? state.config.recordCount;

                    if (isFull) {
                      final confirmed = await _confirmFullBenchmark();
                      if (!confirmed) return;
                    }

                    controller.updateConfig(
                      state.config.copyWith(
                        iterations: iterations,
                        recordCount: records,
                        sqlcipherPassword: _password.text,
                      ),
                    );
                    await controller.run();
                    if (!mounted) return;
                    if (ref.read(benchmarkControllerProvider).runs.isNotEmpty) {
                      context.go('/detail', extra: ref.read(benchmarkControllerProvider).runs.first);
                    }
                  },
            child: const Text('Run'),
          ),
          if (state.isRunning)
            TextButton.icon(
              onPressed: controller.cancel,
              icon: const Icon(Icons.stop),
              label: const Text('Cancel'),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 12),
          const Text('Live logs'),
          Card(
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: state.logs.length,
                itemBuilder: (_, index) {
                  final log = state.logs[index];
                  return ListTile(
                    dense: true,
                    title: Text(log.message),
                    subtitle: Text(log.timestamp.toIso8601String()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
