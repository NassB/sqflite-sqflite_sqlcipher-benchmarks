import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/benchmark_schema.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_pragma_config.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/repositories/database_adapter.dart';

class DriftAdapter implements DatabaseAdapter {
  static const _insertSql = '''
      INSERT INTO $benchTable
      (ext_id, category, title, description, status, score, created_at, updated_at, payload)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''';

  _DriftExecutor? _db;

  @override
  String get engineName => 'drift';

  _DriftExecutor get _database => _db!;

  @override
  Future<void> open({
    required String dbPath,
    String? password,
    BenchmarkPragmaConfig pragmas = const BenchmarkPragmaConfig(),
  }) async {
    _db = _DriftExecutor(NativeDatabase(File(dbPath)));
    await executePragma(pragmas);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<void> deleteDatabaseFile(String dbPath) async {
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
    final wal = File('$dbPath-wal');
    if (await wal.exists()) {
      await wal.delete();
    }
    final shm = File('$dbPath-shm');
    if (await shm.exists()) {
      await shm.delete();
    }
  }

  @override
  Future<void> createSchema() async {
    await _database.customStatement(createBenchSchema);
    for (final statement in createBenchIndexes) {
      await _database.customStatement(statement);
    }
  }

  @override
  Future<int> insertOne(Map<String, Object?> values) async {
    await _database.customStatement(
      _insertSql,
      _insertArgs(values),
    );
    final rows = await _database.customSelect('SELECT last_insert_rowid() AS id').get();
    return (rows.first.data['id'] as num).toInt();
  }

  @override
  Future<void> insertManyBatch(List<Map<String, Object?>> values) async {
    await _database.customStatement('BEGIN TRANSACTION');
    try {
      for (final row in values) {
        await _database.customStatement(_insertSql, _insertArgs(row));
      }
      await _database.customStatement('COMMIT');
    } catch (_) {
      await _database.customStatement('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<Map<String, Object?>?> readById(int id) async {
    final rows = await _database.customSelect(
      'SELECT * FROM $benchTable WHERE id = ? LIMIT 1',
      variables: [Variable<int>(id)],
    ).get();
    return rows.isEmpty ? null : rows.first.data;
  }

  @override
  Future<List<Map<String, Object?>>> readPagedList({required int limit, required int offset}) async {
    final rows = await _database.customSelect(
      'SELECT * FROM $benchTable ORDER BY created_at DESC LIMIT ? OFFSET ?',
      variables: [Variable<int>(limit), Variable<int>(offset)],
    ).get();
    return rows.map((row) => row.data).toList(growable: false);
  }

  @override
  Future<int> readCount() async {
    final rows = await _database.customSelect('SELECT COUNT(*) AS c FROM $benchTable').get();
    return (rows.first.data['c'] as num).toInt();
  }

  @override
  Future<int> updateMany({required int maxId, required int status}) async {
    await _database.customStatement(
      'UPDATE $benchTable SET status = ?, updated_at = ? WHERE id <= ?',
      [status, DateTime.now().millisecondsSinceEpoch, maxId],
    );
    final rows = await _database.customSelect('SELECT changes() AS c').get();
    return (rows.first.data['c'] as num).toInt();
  }

  @override
  Future<int> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final marks = List.generate(ids.length, (_) => '?').join(',');
    await _database.customStatement(
      'DELETE FROM $benchTable WHERE id IN ($marks)',
      ids.cast<Object?>(),
    );
    final rows = await _database.customSelect('SELECT changes() AS c').get();
    return (rows.first.data['c'] as num).toInt();
  }

  @override
  Future<int> deleteByRange({required int fromInclusive, required int toInclusive}) async {
    await _database.customStatement(
      'DELETE FROM $benchTable WHERE id BETWEEN ? AND ?',
      [fromInclusive, toInclusive],
    );
    final rows = await _database.customSelect('SELECT changes() AS c').get();
    return (rows.first.data['c'] as num).toInt();
  }

  @override
  Future<int> purgeAll() async {
    await _database.customStatement('DELETE FROM $benchTable');
    final rows = await _database.customSelect('SELECT changes() AS c').get();
    return (rows.first.data['c'] as num).toInt();
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String query, [List<Object?>? args]) async {
    final rows = await _database.customSelect(
      query,
      variables: (args ?? const <Object?>[])
          .map((arg) => Variable<Object?>(arg))
          .toList(growable: false),
    ).get();
    return rows.map((row) => row.data).toList(growable: false);
  }

  @override
  Future<void> executePragma(BenchmarkPragmaConfig pragmas) async {
    await _database.customStatement('PRAGMA journal_mode=${pragmas.journalMode}');
    await _database.customStatement('PRAGMA synchronous=${pragmas.synchronous}');
    await _database.customStatement('PRAGMA temp_store=${pragmas.tempStore}');
    await _database.customStatement('PRAGMA cache_size=${pragmas.cacheSize}');
    await _database.customStatement('PRAGMA foreign_keys=${pragmas.foreignKeys ? 1 : 0}');
  }

  List<Object?> _insertArgs(Map<String, Object?> values) => <Object?>[
        values['ext_id'],
        values['category'],
        values['title'],
        values['description'],
        values['status'],
        values['score'],
        values['created_at'],
        values['updated_at'],
        values['payload'],
      ];
}

class _DriftExecutor extends DatabaseConnectionUser {
  _DriftExecutor(QueryExecutor executor) : super(DatabaseConnection(executor));
}
