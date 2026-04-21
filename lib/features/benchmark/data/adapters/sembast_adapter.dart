import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/benchmark_schema.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_pragma_config.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/repositories/database_adapter.dart';

class SembastAdapter implements DatabaseAdapter {
  static final _store = intMapStoreFactory.store(benchTable);
  Database? _db;
  int _nextId = 1;

  @override
  String get engineName => 'sembast';

  Database get _database => _db!;

  @override
  Future<void> open({
    required String dbPath,
    String? password,
    BenchmarkPragmaConfig pragmas = const BenchmarkPragmaConfig(),
  }) async {
    _db = await databaseFactoryIo.openDatabase(dbPath);
    final keys = await _store.findKeys(_database);
    final maxId = keys.isEmpty ? 0 : keys.reduce((a, b) => a > b ? a : b);
    _nextId = maxId + 1;
    await executePragma(pragmas);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<void> deleteDatabaseFile(String dbPath) async => databaseFactoryIo.deleteDatabase(dbPath);

  @override
  Future<void> createSchema() async {}

  @override
  Future<int> insertOne(Map<String, Object?> values) async {
    final id = _nextId++;
    await _store.record(id).put(_database, <String, Object?>{'id': id, ...values});
    return id;
  }

  @override
  Future<void> insertManyBatch(List<Map<String, Object?>> values) async {
    await _database.transaction((txn) async {
      for (final row in values) {
        final id = _nextId++;
        await _store.record(id).put(txn, <String, Object?>{'id': id, ...row});
      }
    });
  }

  @override
  Future<Map<String, Object?>?> readById(int id) async {
    final row = await _store.record(id).get(_database);
    if (row == null) return null;
    return Map<String, Object?>.from(row);
  }

  @override
  Future<List<Map<String, Object?>>> readPagedList({required int limit, required int offset}) async {
    final records = await _store.find(
      _database,
      finder: Finder(
        sortOrders: [SortOrder('created_at', false)],
        limit: limit,
        offset: offset,
      ),
    );
    return records.map((record) => Map<String, Object?>.from(record.value)).toList(growable: false);
  }

  @override
  Future<int> readCount() => _store.count(_database);

  @override
  Future<int> updateMany({required int maxId, required int status}) async {
    var count = 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.transaction((txn) async {
      final records = await _store.find(txn);
      for (final record in records) {
        if (record.key > maxId) continue;
        await _store.record(record.key).update(txn, <String, Object?>{
          ...record.value,
          'status': status,
          'updated_at': now,
        });
        count++;
      }
    });
    return count;
  }

  @override
  Future<int> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final finder = Finder(filter: Filter.inList(Field.key, ids));
    return _store.delete(_database, finder: finder);
  }

  @override
  Future<int> deleteByRange({required int fromInclusive, required int toInclusive}) async {
    final keys = await _store.findKeys(_database);
    final ids = keys
        .where((id) => id >= fromInclusive && id <= toInclusive)
        .toList(growable: false);
    return deleteByIds(ids);
  }

  @override
  Future<int> purgeAll() => _store.delete(_database);

  @override
  Future<List<Map<String, Object?>>> rawQuery(String query, [List<Object?>? args]) async {
    final normalized = query.trim().toUpperCase();
    if (normalized.startsWith('SELECT COUNT(*)')) {
      final count = await readCount();
      return <Map<String, Object?>>[
        <String, Object?>{'c': count},
      ];
    }

    if (normalized.startsWith('SELECT * FROM BENCH_ITEMS WHERE CATEGORY = ?')) {
      final category = args != null && args.isNotEmpty ? args.first : null;
      final limit = args != null && args.length > 1 ? (args[1] as num).toInt() : 1000000;
      final records = await _store.find(
        _database,
        finder: Finder(
          filter: Filter.equals('category', category),
          limit: limit,
        ),
      );
      return records.map((record) => Map<String, Object?>.from(record.value)).toList(growable: false);
    }

    if (normalized.startsWith('SELECT * FROM BENCH_ITEMS ORDER BY CREATED_AT DESC LIMIT ?')) {
      final limit = args != null && args.isNotEmpty ? (args.first as num).toInt() : 1000000;
      final records = await _store.find(
        _database,
        finder: Finder(
          sortOrders: [SortOrder('created_at', false)],
          limit: limit,
        ),
      );
      return records.map((record) => Map<String, Object?>.from(record.value)).toList(growable: false);
    }

    throw UnsupportedError(
      'Unsupported query for $engineName: $query. Supported read patterns are count, category filter, and created_at DESC limit.',
    );
  }

  @override
  Future<void> executePragma(BenchmarkPragmaConfig pragmas) async {}
}
