import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:database_benchmarks/core/services/device_metadata_service.dart';
import 'package:database_benchmarks/core/services/stats_calculator.dart';
import 'package:database_benchmarks/features/benchmark/data/services/benchmark_runner.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_engine.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_log_entry.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_scenario_config.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_scenario_type.dart';
import 'package:database_benchmarks/features/benchmark/presentation/providers/benchmark_run_state.dart';
import 'package:database_benchmarks/features/history/presentation/providers/history_provider.dart';
import 'package:database_benchmarks/features/settings/presentation/providers/settings_provider.dart';

final statsCalculatorProvider = Provider<StatsCalculator>((ref) => const StatsCalculator());

final deviceMetadataProvider = Provider<DeviceMetadataService>((ref) => const DeviceMetadataService());

final benchmarkRunnerProvider = Provider<BenchmarkRunner>((ref) {
  return BenchmarkRunner(
    statsCalculator: ref.watch(statsCalculatorProvider),
    deviceMetadataService: ref.watch(deviceMetadataProvider),
  );
});

final benchmarkControllerProvider = NotifierProvider<BenchmarkController, BenchmarkRunState>(
  BenchmarkController.new,
);

class BenchmarkController extends Notifier<BenchmarkRunState> {
  bool _cancelRequested = false;

  @override
  BenchmarkRunState build() {
    final settings = ref.watch(settingsProvider);
    return BenchmarkRunState(
      config: BenchmarkScenarioConfig(
        scenario: BenchmarkScenarioType.bulkInsert,
        engines: BenchmarkEngine.values,
        sqlcipherPassword: settings.sqlcipherPassword,
        seed: settings.seed,
        pragmas: settings.pragmas,
      ),
    );
  }

  void updateConfig(BenchmarkScenarioConfig config) {
    state = state.copyWith(config: config, clearError: true);
  }

  Future<void> run() async {
    _cancelRequested = false;
    state = state.copyWith(
      isRunning: true,
      isCancelled: false,
      logs: [],
      runs: [],
      clearError: true,
    );

    try {
      final runs = await ref.read(benchmarkRunnerProvider).run(
            state.config,
            onLog: _appendLog,
            isCancelled: () => _cancelRequested,
          );
      state = state.copyWith(isRunning: false, runs: runs, isCancelled: _cancelRequested);
      if (runs.isNotEmpty) {
        await ref.read(historyProvider.notifier).addRuns(runs);
      }
    } catch (error) {
      state = state.copyWith(isRunning: false, error: error.toString());
    }
  }

  void cancel() {
    _cancelRequested = true;
    state = state.copyWith(isCancelled: true, isRunning: false);
  }

  void _appendLog(BenchmarkLogEntry log) {
    state = state.copyWith(logs: [...state.logs, log]);
  }
}
