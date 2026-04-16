import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/benchmark_schema.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_pragma_config.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/repositories/database_adapter.dart';

class SqfliteAdapter implements DatabaseAdapter {
  sqflite.Database? _db;

  @override
  String get engineName => 'sqflite';

  sqflite.Database get _database => _db!;

  @override
  Future<void> open({
    required String dbPath,
    String? password,
    BenchmarkPragmaConfig pragmas = const BenchmarkPragmaConfig(),
  }) async {
    _db = await sqflite.openDatabase(dbPath, version: 1);
    await executePragma(pragmas);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<void> deleteDatabaseFile(String dbPath) => sqflite.deleteDatabase(dbPath);

  @override
  Future<void> createSchema() async {
    await _database.execute(createBenchSchema);
    for (final statement in createBenchIndexes) {
      await _database.execute(statement);
    }
  }

  @override
  Future<int> insertOne(Map<String, Object?> values) => _database.insert(benchTable, values);

  @override
  Future<void> insertManyBatch(List<Map<String, Object?>> values) async {
    final batch = _database.batch();
    for (final row in values) {
      batch.insert(benchTable, row);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<Map<String, Object?>?> readById(int id) async {
    final rows = await _database.query(benchTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<List<Map<String, Object?>>> readPagedList({required int limit, required int offset}) {
    return _database.query(
      benchTable,
      limit: limit,
      offset: offset,
      orderBy: 'created_at DESC',
    );
  }

  @override
  Future<int> readCount() async {
    final result = await _database.rawQuery('SELECT COUNT(*) AS c FROM $benchTable');
    return (result.first['c'] as num).toInt();
  }

  @override
  Future<int> updateMany({required int maxId, required int status}) {
    return _database.update(
      benchTable,
      {'status': status, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id <= ?',
      whereArgs: [maxId],
    );
  }

  @override
  Future<int> deleteByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value(0);
    final marks = List.generate(ids.length, (_) => '?').join(',');
    return _database.delete(benchTable, where: 'id IN ($marks)', whereArgs: ids);
  }

  @override
  Future<int> deleteByRange({required int fromInclusive, required int toInclusive}) {
    return _database.delete(
      benchTable,
      where: 'id BETWEEN ? AND ?',
      whereArgs: [fromInclusive, toInclusive],
    );
  }

  @override
  Future<int> purgeAll() => _database.delete(benchTable);

  @override
  Future<List<Map<String, Object?>>> rawQuery(String query, [List<Object?>? args]) {
    return _database.rawQuery(query, args);
  }

  @override
  Future<void> executePragma(BenchmarkPragmaConfig pragmas) async {
    await _database.rawQuery('PRAGMA journal_mode=${pragmas.journalMode}');
    await _database.rawQuery('PRAGMA synchronous=${pragmas.synchronous}');
    await _database.rawQuery('PRAGMA temp_store=${pragmas.tempStore}');
    await _database.rawQuery('PRAGMA cache_size=${pragmas.cacheSize}');
    await _database.rawQuery('PRAGMA foreign_keys=${pragmas.foreignKeys ? 1 : 0}');
  }
}
