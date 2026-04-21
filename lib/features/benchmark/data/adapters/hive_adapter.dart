import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_pragma_config.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/repositories/database_adapter.dart';

class HiveAdapter implements DatabaseAdapter {
  Box<Map>? _box;
  int _nextId = 1;

  @override
  String get engineName => 'hive';

  Box<Map> get _database => _box!;

  String _boxName(String dbPath) => '${p.basenameWithoutExtension(dbPath)}_$engineName';

  @override
  Future<void> open({
    required String dbPath,
    String? password,
    BenchmarkPragmaConfig pragmas = const BenchmarkPragmaConfig(),
  }) async {
    Hive.init(p.dirname(dbPath));
    _box = await Hive.openBox<Map>(_boxName(dbPath));
    final ids = _database.keys.whereType<int>();
    final maxId = ids.fold<int>(0, (max, id) => id > max ? id : max);
    _nextId = maxId + 1;
    await executePragma(pragmas);
  }

  @override
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  @override
  Future<void> deleteDatabaseFile(String dbPath) async {
    Hive.init(p.dirname(dbPath));
    await Hive.deleteBoxFromDisk(_boxName(dbPath));
    _nextId = 1;
  }

  @override
  Future<void> createSchema() async {}

  @override
  Future<int> insertOne(Map<String, Object?> values) async {
    final id = _nextId++;
    await _database.put(id, <String, Object?>{'id': id, ...values});
    return id;
  }

  @override
  Future<void> insertManyBatch(List<Map<String, Object?>> values) async {
    final entries = <int, Map<String, Object?>>{};
    for (final row in values) {
      final id = _nextId++;
      entries[id] = <String, Object?>{'id': id, ...row};
    }
    await _database.putAll(entries);
  }

  @override
  Future<Map<String, Object?>?> readById(int id) async {
    final value = _database.get(id);
    if (value == null) return null;
    return Map<String, Object?>.from(value);
  }

  @override
  Future<List<Map<String, Object?>>> readPagedList({required int limit, required int offset}) async {
    final sorted = _database.values
        .map((e) => Map<String, Object?>.from(e))
        .toList()
      ..sort(
        (a, b) => ((b['created_at'] as num?)?.toInt() ?? 0)
            .compareTo((a['created_at'] as num?)?.toInt() ?? 0),
      );
    if (offset >= sorted.length) return <Map<String, Object?>>[];
    final end = (offset + limit).clamp(0, sorted.length);
    return sorted.sublist(offset, end);
  }

  @override
  Future<int> readCount() async => _database.length;

  @override
  Future<int> updateMany({required int maxId, required int status}) async {
    var count = 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = <int, Map<String, Object?>>{};
    for (final key in _database.keys.whereType<int>()) {
      if (key > maxId) continue;
      final row = _database.get(key);
      if (row == null) continue;
      final next = Map<String, Object?>.from(row);
      next['status'] = status;
      next['updated_at'] = now;
      updates[key] = next;
      count++;
    }
    if (updates.isNotEmpty) {
      await _database.putAll(updates);
    }
    return count;
  }

  @override
  Future<int> deleteByIds(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      if (_database.containsKey(id)) {
        await _database.delete(id);
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> deleteByRange({required int fromInclusive, required int toInclusive}) async {
    final ids = _database.keys
        .whereType<int>()
        .where((id) => id >= fromInclusive && id <= toInclusive)
        .toList(growable: false);
    return deleteByIds(ids);
  }

  @override
  Future<int> purgeAll() async {
    final count = _database.length;
    await _database.clear();
    _nextId = 1;
    return count;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String query, [List<Object?>? args]) async {
    final normalized = query.trim().toUpperCase();
    if (normalized.startsWith('SELECT COUNT(*)')) {
      return <Map<String, Object?>>[
        <String, Object?>{'c': _database.length},
      ];
    }

    if (normalized.startsWith('SELECT * FROM BENCH_ITEMS WHERE CATEGORY = ?')) {
      final category = args != null && args.isNotEmpty ? args.first : null;
      final limit = args != null && args.length > 1 ? (args[1] as num).toInt() : _database.length;
      final filtered = _database.values
          .map((e) => Map<String, Object?>.from(e))
          .where((row) => row['category'] == category)
          .take(limit)
          .toList(growable: false);
      return filtered;
    }

    if (normalized.startsWith('SELECT * FROM BENCH_ITEMS ORDER BY CREATED_AT DESC LIMIT ?')) {
      final limit = args != null && args.isNotEmpty ? (args.first as num).toInt() : _database.length;
      final sorted = _database.values
          .map((e) => Map<String, Object?>.from(e))
          .toList()
        ..sort(
          (a, b) => ((b['created_at'] as num?)?.toInt() ?? 0)
              .compareTo((a['created_at'] as num?)?.toInt() ?? 0),
        );
      return sorted.take(limit).toList(growable: false);
    }

    throw UnsupportedError(
      'Unsupported query for $engineName: $query. Supported read patterns are count, category filter, and created_at DESC limit.',
    );
  }

  @override
  Future<void> executePragma(BenchmarkPragmaConfig pragmas) async {}
}
