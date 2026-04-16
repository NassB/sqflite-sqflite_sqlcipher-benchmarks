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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(benchmarkControllerProvider);
    final controller = ref.read(benchmarkControllerProvider.notifier);

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
              controller.updateConfig(
                state.config.copyWith(scenario: value),
              );
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('iterationsField'),
            controller: _iterations,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Iterations'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('recordCountField'),
            controller: _records,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Record count'),
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
                    final iterations = int.tryParse(_iterations.text) ?? state.config.iterations;
                    final records = int.tryParse(_records.text) ?? state.config.recordCount;
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
