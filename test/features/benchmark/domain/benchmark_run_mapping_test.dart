import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_engine.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_run.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_sample.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_scenario_config.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_scenario_type.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_summary.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/device_metadata.dart';

BenchmarkRun _makeRun(BenchmarkEngine engine) => BenchmarkRun(
      id: 'run_${engine.name}',
      timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
      engine: engine,
      config: BenchmarkScenarioConfig(
        scenario: BenchmarkScenarioType.bulkInsert,
        engines: [engine],
      ),
      samples: const [BenchmarkSample(iteration: 1, elapsedMs: 10)],
      summary: const BenchmarkSummary(
        totalMs: 10,
        meanMs: 10,
        medianMs: 10,
        minMs: 10,
        maxMs: 10,
        p95Ms: 10,
        opsPerSec: 100,
        dbSizeBytes: 1000,
        walSizeBytes: 0,
      ),
      deviceMetadata: const DeviceMetadata(
        device: 'dev',
        os: 'android',
        osVersion: '14',
        appVersion: '1.0.0',
        buildMode: 'profile',
      ),
      success: true,
    );

void main() {
  group('BenchmarkRun json roundtrip', () {
    for (final engine in BenchmarkEngine.values) {
      test('roundtrip for engine ${engine.name}', () {
        final run = _makeRun(engine);
        final restored = BenchmarkRun.fromJson(run.toJson());
        expect(restored.id, run.id);
        expect(restored.engine, engine);
        expect(restored.summary.p95Ms, 10);
        expect(restored.config.engines, [engine]);
      });
    }
  });

  test('fromJson falls back to sqflite for unknown engine name', () {
    final run = _makeRun(BenchmarkEngine.sqflite);
    final json = run.toJson()..['engine'] = 'unknown_engine';
    final restored = BenchmarkRun.fromJson(json);
    expect(restored.engine, BenchmarkEngine.sqflite);
  });
}
