import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher_benchmarks/core/constants/app_constants.dart';
import 'package:sqflite_sqlcipher_benchmarks/core/services/device_metadata_service.dart';
import 'package:sqflite_sqlcipher_benchmarks/core/services/stats_calculator.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/drift_adapter.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/hive_adapter.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/isar_community_adapter.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/objectbox_adapter.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/sembast_adapter.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/sqflite_adapter.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/sqflite_sqlcipher_adapter.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/services/benchmark_fake_data_generator.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_engine.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_log_entry.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_run.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_sample.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_scenario_config.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_scenario_type.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_summary.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/repositories/database_adapter.dart';

class BenchmarkRunner {
  BenchmarkRunner({
    required StatsCalculator statsCalculator,
    required DeviceMetadataService deviceMetadataService,
  })  : _statsCalculator = statsCalculator,
        _deviceMetadataService = deviceMetadataService;

  final StatsCalculator _statsCalculator;
  final DeviceMetadataService _deviceMetadataService;

  Future<List<BenchmarkRun>> run(
    BenchmarkScenarioConfig config, {
    required void Function(BenchmarkLogEntry log) onLog,
    required bool Function() isCancelled,
  }) async {
    final device = await _deviceMetadataService.load();
    final runs = <BenchmarkRun>[];

    for (final engine in config.engines) {
      if (isCancelled()) break;
      final adapter = _adapterFor(engine);
      final dbPath = await _dbPathFor(engine);

      if (config.resetDatabase) {
        await adapter.deleteDatabaseFile(dbPath);
      }

      if (config.enableWarmup) {
        onLog(BenchmarkLogEntry(
          timestamp: DateTime.now(),
          message: '[${engine.label}] Warmup...',
        ));
        await _runSingleIteration(adapter, dbPath, config, warmup: true);
      }

      final sampleValues = <double>[];
      for (var i = 0; i < config.iterations; i++) {
        if (isCancelled()) break;
        onLog(BenchmarkLogEntry(
          timestamp: DateTime.now(),
          message: '[${engine.label}] Iteration ${i + 1}/${config.iterations}',
        ));
        final elapsedMs = await _runSingleIteration(adapter, dbPath, config);
        sampleValues.add(elapsedMs);
      }

      final dbSize = await _sizeOf(dbPath);
      final walSize = await _sizeOf('$dbPath-wal');

      final totalMs = _statsCalculator.total(sampleValues);
      final operationCount = _operationCount(config);
      final summary = BenchmarkSummary(
        totalMs: totalMs,
        meanMs: _statsCalculator.mean(sampleValues),
        medianMs: _statsCalculator.median(sampleValues),
        minMs: _statsCalculator.min(sampleValues),
        maxMs: _statsCalculator.max(sampleValues),
        p95Ms: _statsCalculator.percentile(sampleValues, 95),
        opsPerSec: _statsCalculator.opsPerSecond(
          operationCount: operationCount,
          totalMs: totalMs,
        ),
        dbSizeBytes: dbSize,
        walSizeBytes: walSize,
      );

      final samples = List.generate(
        sampleValues.length,
        (index) => BenchmarkSample(iteration: index + 1, elapsedMs: sampleValues[index]),
      );

      runs.add(
        BenchmarkRun(
          id: '${DateTime.now().millisecondsSinceEpoch}_${engine.name}_${config.scenario.name}',
          timestamp: DateTime.now(),
          engine: engine,
          config: config,
          samples: samples,
          summary: summary,
          deviceMetadata: device,
          success: true,
        ),
      );

      await adapter.close();
    }

    return runs;
  }

  Future<double> _runSingleIteration(
    DatabaseAdapter adapter,
    String dbPath,
    BenchmarkScenarioConfig config, {
    bool warmup = false,
  }) async {
    final generator = BenchmarkFakeDataGenerator(config.seed);
    final rows = generator.generateRows(config.recordCount);
    final watch = Stopwatch()..start();

    await adapter.open(
      dbPath: dbPath,
      password: config.sqlcipherPassword,
      pragmas: config.pragmas,
    );

    if (config.scenario != BenchmarkScenarioType.openDatabase &&
        config.scenario != BenchmarkScenarioType.repeatedOpenClose &&
        config.scenario != BenchmarkScenarioType.full) {
      await adapter.createSchema();
    }

    switch (config.scenario) {
      case BenchmarkScenarioType.openDatabase:
        for (var i = 0; i < config.openRepeatCount; i++) {
          await adapter.close();
          await adapter.open(
            dbPath: dbPath,
            password: config.sqlcipherPassword,
            pragmas: config.pragmas,
          );
        }
        break;
      case BenchmarkScenarioType.bulkInsert:
        if (config.enableBatch) {
          await adapter.insertManyBatch(rows);
        } else if (config.enableTransaction) {
          for (final row in rows) {
            await adapter.insertOne(row);
          }
        } else {
          for (final row in rows) {
            await adapter.insertOne(row);
          }
        }
        break;
      case BenchmarkScenarioType.read:
        await adapter.insertManyBatch(rows);
        await adapter.readById(1);
        await adapter.readPagedList(limit: config.limit, offset: config.offset);
        await adapter.rawQuery(
          'SELECT * FROM bench_items WHERE category = ? LIMIT ?',
          ['cat_1', config.limit],
        );
        await adapter.rawQuery('SELECT * FROM bench_items ORDER BY created_at DESC LIMIT ?', [config.limit]);
        await adapter.readCount();
        break;
      case BenchmarkScenarioType.update:
        await adapter.insertManyBatch(rows);
        await adapter.updateMany(maxId: config.recordCount, status: 3);
        break;
      case BenchmarkScenarioType.delete:
        await adapter.insertManyBatch(rows);
        await adapter.deleteByIds(List.generate(config.limit, (i) => i + 1));
        await adapter.deleteByRange(fromInclusive: config.limit + 1, toInclusive: config.recordCount);
        await adapter.purgeAll();
        break;
      case BenchmarkScenarioType.mixed:
        await adapter.insertManyBatch(rows);
        for (var i = 0; i < config.mixedOperations; i++) {
          final op = i % 10;
          if (op < 7) {
            await adapter.readById((i % config.recordCount) + 1);
          } else if (op < 9) {
            await adapter.insertOne(generator.generateRows(1).first);
          } else {
            await adapter.updateMany(maxId: (i % config.recordCount) + 1, status: i % 5);
          }
        }
        break;
      case BenchmarkScenarioType.repeatedOpenClose:
        for (var i = 0; i < config.openRepeatCount; i++) {
          await adapter.close();
          await adapter.open(
            dbPath: dbPath,
            password: config.sqlcipherPassword,
            pragmas: config.pragmas,
          );
        }
        break;
      case BenchmarkScenarioType.full:
        // ── 1. Repeated open/close (cold-open cost) ──────────────────────
        for (var i = 0; i < config.openRepeatCount; i++) {
          await adapter.close();
          await adapter.open(
            dbPath: dbPath,
            password: config.sqlcipherPassword,
            pragmas: config.pragmas,
          );
        }
        // Ensure schema exists after reopens
        await adapter.createSchema();

        // ── 2. Bulk insert ────────────────────────────────────────────────
        await adapter.insertManyBatch(rows);

        // ── 3. Read (uses data from bulk insert) ──────────────────────────
        await adapter.readById(1);
        await adapter.readPagedList(limit: config.limit, offset: config.offset);
        await adapter.rawQuery(
          'SELECT * FROM bench_items WHERE category = ? LIMIT ?',
          ['cat_1', config.limit],
        );
        await adapter.rawQuery('SELECT * FROM bench_items ORDER BY created_at DESC LIMIT ?', [config.limit]);
        await adapter.readCount();

        // ── 4. Update (uses data from bulk insert) ────────────────────────
        await adapter.updateMany(maxId: config.recordCount, status: 3);

        // ── 5. Delete (clears the table) ──────────────────────────────────
        await adapter.deleteByIds(List.generate(config.limit, (i) => i + 1));
        await adapter.deleteByRange(fromInclusive: config.limit + 1, toInclusive: config.recordCount);
        await adapter.purgeAll();

        // ── 6. Mixed (re-inserts fresh data, then mixed ops) ──────────────
        final freshRows = generator.generateRows(config.recordCount);
        await adapter.insertManyBatch(freshRows);
        for (var i = 0; i < config.mixedOperations; i++) {
          final op = i % 10;
          if (op < 7) {
            await adapter.readById((i % config.recordCount) + 1);
          } else if (op < 9) {
            await adapter.insertOne(generator.generateRows(1).first);
          } else {
            await adapter.updateMany(maxId: (i % config.recordCount) + 1, status: i % 5);
          }
        }

        // ── 7. Repeated open/close (warm-close cost, with data) ───────────
        for (var i = 0; i < config.openRepeatCount; i++) {
          await adapter.close();
          await adapter.open(
            dbPath: dbPath,
            password: config.sqlcipherPassword,
            pragmas: config.pragmas,
          );
        }
        break;
    }

    watch.stop();
    await adapter.close();

    return watch.elapsedMicroseconds / 1000;
  }

  int _operationCount(BenchmarkScenarioConfig config) {
    switch (config.scenario) {
      case BenchmarkScenarioType.openDatabase:
      case BenchmarkScenarioType.repeatedOpenClose:
        return config.openRepeatCount * config.iterations;
      case BenchmarkScenarioType.bulkInsert:
      case BenchmarkScenarioType.update:
      case BenchmarkScenarioType.delete:
      case BenchmarkScenarioType.read:
        return config.recordCount * config.iterations;
      case BenchmarkScenarioType.mixed:
        return config.mixedOperations * config.iterations;
      case BenchmarkScenarioType.full:
        // Sum of all sub-scenario operation counts (iterations is fixed to 1)
        return (config.openRepeatCount * 2) +
            (config.recordCount * 4) +
            config.mixedOperations;
    }
  }

  DatabaseAdapter _adapterFor(BenchmarkEngine engine) {
    switch (engine) {
      case BenchmarkEngine.sqflite:
        return SqfliteAdapter();
      case BenchmarkEngine.sqfliteSqlcipher:
        return SqfliteSqlcipherAdapter();
      case BenchmarkEngine.drift:
        return DriftAdapter();
      case BenchmarkEngine.hive:
        return HiveAdapter();
      case BenchmarkEngine.sembast:
        return SembastAdapter();
      case BenchmarkEngine.objectbox:
        return ObjectboxAdapter();
      case BenchmarkEngine.isarCommunity:
        return IsarCommunityAdapter();
    }
  }

  Future<String> _dbPathFor(BenchmarkEngine engine) async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, '${AppConstants.benchmarkDbPrefix}_${engine.name}.db');
  }

  Future<int> _sizeOf(String path) async {
    final file = File(path);
    if (!file.existsSync()) return 0;
    return file.length();
  }
}
