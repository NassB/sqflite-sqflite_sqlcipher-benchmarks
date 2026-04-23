import 'package:flutter_test/flutter_test.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_engine.dart';

void main() {
  group('BenchmarkEngine.label', () {
    const expectedLabels = <BenchmarkEngine, String>{
      BenchmarkEngine.sqflite: 'sqflite',
      BenchmarkEngine.sqfliteSqlcipher: 'sqflite_sqlcipher',
      BenchmarkEngine.drift: 'drift',
      BenchmarkEngine.hive: 'hive',
      BenchmarkEngine.sembast: 'sembast',
      BenchmarkEngine.objectbox: 'objectbox',
      BenchmarkEngine.isarCommunity: 'isar_community',
    };

    for (final entry in expectedLabels.entries) {
      test('${entry.key.name} has label "${entry.value}"', () {
        expect(entry.key.label, entry.value);
      });
    }

    test('all enum values have a label entry', () {
      for (final engine in BenchmarkEngine.values) {
        expect(expectedLabels, contains(engine),
            reason: '${engine.name} is missing from expectedLabels — add it');
      }
    });
  });
}
