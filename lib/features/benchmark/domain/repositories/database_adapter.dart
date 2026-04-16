import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_pragma_config.dart';

abstract class DatabaseAdapter {
  String get engineName;

  Future<void> open({
    required String dbPath,
    String? password,
    BenchmarkPragmaConfig pragmas = const BenchmarkPragmaConfig(),
  });

  Future<void> close();

  Future<void> deleteDatabaseFile(String dbPath);

  Future<void> createSchema();

  Future<int> insertOne(Map<String, Object?> values);

  Future<void> insertManyBatch(List<Map<String, Object?>> values);

  Future<Map<String, Object?>?> readById(int id);

  Future<List<Map<String, Object?>>> readPagedList({required int limit, required int offset});

  Future<int> readCount();

  Future<int> updateMany({required int maxId, required int status});

  Future<int> deleteByIds(List<int> ids);

  Future<int> deleteByRange({required int fromInclusive, required int toInclusive});

  Future<int> purgeAll();

  Future<List<Map<String, Object?>>> rawQuery(String query, [List<Object?>? args]);

  Future<void> executePragma(BenchmarkPragmaConfig pragmas);
}
