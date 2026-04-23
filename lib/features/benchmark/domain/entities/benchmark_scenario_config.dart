import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_engine.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_pragma_config.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_scenario_type.dart';

class BenchmarkScenarioConfig {
  const BenchmarkScenarioConfig({
    required this.scenario,
    required this.engines,
    this.sqlcipherPassword = 'benchmark_password',
    this.iterations = 5,
    this.recordCount = 1000,
    this.limit = 100,
    this.offset = 0,
    this.enableTransaction = true,
    this.enableBatch = true,
    this.resetDatabase = true,
    this.enableWarmup = true,
    this.openRepeatCount = 10,
    this.mixedOperations = 1000,
    this.mixedReadRatio = 70,
    this.mixedInsertRatio = 20,
    this.mixedUpdateRatio = 10,
    this.seed = 42,
    this.pragmas = const BenchmarkPragmaConfig(),
  });

  final BenchmarkScenarioType scenario;
  final List<BenchmarkEngine> engines;
  final String sqlcipherPassword;
  final int iterations;
  final int recordCount;
  final int limit;
  final int offset;
  final bool enableTransaction;
  final bool enableBatch;
  final bool resetDatabase;
  final bool enableWarmup;
  final int openRepeatCount;
  final int mixedOperations;
  final int mixedReadRatio;
  final int mixedInsertRatio;
  final int mixedUpdateRatio;
  final int seed;
  final BenchmarkPragmaConfig pragmas;

  BenchmarkScenarioConfig copyWith({
    BenchmarkScenarioType? scenario,
    List<BenchmarkEngine>? engines,
    String? sqlcipherPassword,
    int? iterations,
    int? recordCount,
    int? limit,
    int? offset,
    bool? enableTransaction,
    bool? enableBatch,
    bool? resetDatabase,
    bool? enableWarmup,
    int? openRepeatCount,
    int? mixedOperations,
    int? mixedReadRatio,
    int? mixedInsertRatio,
    int? mixedUpdateRatio,
    int? seed,
    BenchmarkPragmaConfig? pragmas,
  }) {
    return BenchmarkScenarioConfig(
      scenario: scenario ?? this.scenario,
      engines: engines ?? this.engines,
      sqlcipherPassword: sqlcipherPassword ?? this.sqlcipherPassword,
      iterations: iterations ?? this.iterations,
      recordCount: recordCount ?? this.recordCount,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      enableTransaction: enableTransaction ?? this.enableTransaction,
      enableBatch: enableBatch ?? this.enableBatch,
      resetDatabase: resetDatabase ?? this.resetDatabase,
      enableWarmup: enableWarmup ?? this.enableWarmup,
      openRepeatCount: openRepeatCount ?? this.openRepeatCount,
      mixedOperations: mixedOperations ?? this.mixedOperations,
      mixedReadRatio: mixedReadRatio ?? this.mixedReadRatio,
      mixedInsertRatio: mixedInsertRatio ?? this.mixedInsertRatio,
      mixedUpdateRatio: mixedUpdateRatio ?? this.mixedUpdateRatio,
      seed: seed ?? this.seed,
      pragmas: pragmas ?? this.pragmas,
    );
  }

  Map<String, dynamic> toJson() => {
        'scenario': scenario.name,
        'engines': engines.map((e) => e.name).toList(),
        'sqlcipherPassword': sqlcipherPassword,
        'iterations': iterations,
        'recordCount': recordCount,
        'limit': limit,
        'offset': offset,
        'enableTransaction': enableTransaction,
        'enableBatch': enableBatch,
        'resetDatabase': resetDatabase,
        'enableWarmup': enableWarmup,
        'openRepeatCount': openRepeatCount,
        'mixedOperations': mixedOperations,
        'mixedReadRatio': mixedReadRatio,
        'mixedInsertRatio': mixedInsertRatio,
        'mixedUpdateRatio': mixedUpdateRatio,
        'seed': seed,
        'pragmas': pragmas.toJson(),
      };

  factory BenchmarkScenarioConfig.fromJson(Map<String, dynamic> json) {
    return BenchmarkScenarioConfig(
      scenario: BenchmarkScenarioType.values.firstWhere(
        (e) => e.name == json['scenario'],
        orElse: () => BenchmarkScenarioType.bulkInsert,
      ),
      engines: ((json['engines'] as List<dynamic>? ?? const [])
          .map((e) => BenchmarkEngine.values.firstWhere(
                (v) => v.name == e,
                orElse: () => BenchmarkEngine.sqflite,
              ))
          .toList()),
      sqlcipherPassword: json['sqlcipherPassword'] as String? ?? 'benchmark_password',
      iterations: (json['iterations'] as num?)?.toInt() ?? 5,
      recordCount: (json['recordCount'] as num?)?.toInt() ?? 1000,
      limit: (json['limit'] as num?)?.toInt() ?? 100,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      enableTransaction: json['enableTransaction'] as bool? ?? true,
      enableBatch: json['enableBatch'] as bool? ?? true,
      resetDatabase: json['resetDatabase'] as bool? ?? true,
      enableWarmup: json['enableWarmup'] as bool? ?? true,
      openRepeatCount: (json['openRepeatCount'] as num?)?.toInt() ?? 10,
      mixedOperations: (json['mixedOperations'] as num?)?.toInt() ?? 1000,
      mixedReadRatio: (json['mixedReadRatio'] as num?)?.toInt() ?? 70,
      mixedInsertRatio: (json['mixedInsertRatio'] as num?)?.toInt() ?? 20,
      mixedUpdateRatio: (json['mixedUpdateRatio'] as num?)?.toInt() ?? 10,
      seed: (json['seed'] as num?)?.toInt() ?? 42,
      pragmas: BenchmarkPragmaConfig.fromJson(
        Map<String, dynamic>.from((json['pragmas'] as Map?) ?? const <String, dynamic>{}),
      ),
    );
  }
}
