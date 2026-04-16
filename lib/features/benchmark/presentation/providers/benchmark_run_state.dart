import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_log_entry.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_run.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_scenario_config.dart';

class BenchmarkRunState {
  const BenchmarkRunState({
    required this.config,
    this.isRunning = false,
    this.isCancelled = false,
    this.runs = const [],
    this.logs = const [],
    this.error,
  });

  final BenchmarkScenarioConfig config;
  final bool isRunning;
  final bool isCancelled;
  final List<BenchmarkRun> runs;
  final List<BenchmarkLogEntry> logs;
  final String? error;

  BenchmarkRunState copyWith({
    BenchmarkScenarioConfig? config,
    bool? isRunning,
    bool? isCancelled,
    List<BenchmarkRun>? runs,
    List<BenchmarkLogEntry>? logs,
    String? error,
    bool clearError = false,
  }) {
    return BenchmarkRunState(
      config: config ?? this.config,
      isRunning: isRunning ?? this.isRunning,
      isCancelled: isCancelled ?? this.isCancelled,
      runs: runs ?? this.runs,
      logs: logs ?? this.logs,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
