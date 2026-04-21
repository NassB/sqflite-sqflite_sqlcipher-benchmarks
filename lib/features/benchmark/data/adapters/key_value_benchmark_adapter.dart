import 'dart:convert';
import 'dart:io';

import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_pragma_config.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/repositories/database_adapter.dart';

abstract class KeyValueBenchmarkAdapter implements DatabaseAdapter {
  static const _countOperationPrefix = 'SELECT COUNT(*)';
  static const _categoryFilterOperationPrefix = 'SELECT * FROM BENCH_ITEMS WHERE CATEGORY = ?';
  static const _latestByCreatedAtOperationPrefix =
      'SELECT * FROM BENCH_ITEMS ORDER BY CREATED_AT DESC LIMIT ?';

  /// In-memory benchmark row store loaded from disk on open and flushed on close.
  final Map<int, Map<String, Object?>> _rows = <int, Map<String, Object?>>{};
  int _nextId = 1;
  String? _storagePath;

  String resolveStoragePath(String dbPath) => '$dbPath.kvdb';

  @override
  Future<void> open({
    required String dbPath,
    String? password,
    BenchmarkPragmaConfig pragmas = const BenchmarkPragmaConfig(),
  }) async {
    _storagePath = resolveStoragePath(dbPath);
    _rows.clear();
    _nextId = 1;
    final file = File(_storagePath!);
    if (!await file.exists()) {
      await executePragma(pragmas);
      return;
    }

    final raw = await file.readAsString();
    if (raw.isEmpty) {
      await executePragma(pragmas);
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _nextId = (decoded['nextId'] as num?)?.toInt() ?? 1;
      final rows = (decoded['rows'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      for (final row in rows) {
        final id = (row['id'] as num?)?.toInt();
        if (id == null) continue;
        _rows[id] = Map<String, Object?>.from(row);
      }
    } catch (_) {
      _rows.clear();
      _nextId = 1;
    }
    await executePragma(pragmas);
  }

  @override
  Future<void> close() async {
    final path = _storagePath;
    if (path == null) return;
    final file = File(path);
    await file.parent.create(recursive: true);
    final payload = <String, Object?>{
      'nextId': _nextId,
      'rows': _rows.values.toList(),
    };
    await file.writeAsString(jsonEncode(payload), flush: true);
    _storagePath = null;
  }

  @override
  Future<void> deleteDatabaseFile(String dbPath) async {
    final file = File(resolveStoragePath(dbPath));
    if (await file.exists()) {
      await file.delete();
    }
    _rows.clear();
    _nextId = 1;
  }

  @override
  Future<void> createSchema() async {}

  @override
  Future<int> insertOne(Map<String, Object?> values) async {
    final id = _nextId++;
    _rows[id] = <String, Object?>{
      'id': id,
      ...values,
    };
    return id;
  }

  @override
  Future<void> insertManyBatch(List<Map<String, Object?>> values) async {
    for (final row in values) {
      final id = _nextId++;
      _rows[id] = <String, Object?>{
        'id': id,
        ...row,
      };
    }
  }

  @override
  Future<Map<String, Object?>?> readById(int id) async => _rows[id];

  @override
  Future<List<Map<String, Object?>>> readPagedList({required int limit, required int offset}) async {
    final sorted = _rows.values.toList()
      ..sort(
        (a, b) => ((b['created_at'] as num?)?.toInt() ?? 0)
            .compareTo((a['created_at'] as num?)?.toInt() ?? 0),
      );
    if (offset >= sorted.length) return <Map<String, Object?>>[];
    final end = (offset + limit).clamp(0, sorted.length);
    return sorted.sublist(offset, end);
  }

  @override
  Future<int> readCount() async => _rows.length;

  @override
  Future<int> updateMany({required int maxId, required int status}) async {
    var updated = 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final entry in _rows.entries) {
      if (entry.key > maxId) continue;
      entry.value['status'] = status;
      entry.value['updated_at'] = now;
      updated++;
    }
    return updated;
  }

  @override
  Future<int> deleteByIds(List<int> ids) async {
    var deleted = 0;
    for (final id in ids) {
      if (_rows.remove(id) != null) {
        deleted++;
      }
    }
    return deleted;
  }

  @override
  Future<int> deleteByRange({required int fromInclusive, required int toInclusive}) async {
    final ids = _rows.keys
        .where((id) => id >= fromInclusive && id <= toInclusive)
        .toList(growable: false);
    return deleteByIds(ids);
  }

  @override
  Future<int> purgeAll() async {
    final count = _rows.length;
    _rows.clear();
    _nextId = 1;
    return count;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String query, [List<Object?>? args]) async {
    final normalized = query.trim().toUpperCase();
    if (normalized.startsWith(_countOperationPrefix)) {
      return <Map<String, Object?>>[
        <String, Object?>{'c': _rows.length},
      ];
    }

    if (normalized.startsWith(_categoryFilterOperationPrefix)) {
      final category = args != null && args.isNotEmpty ? args.first as String? : null;
      final limit = args != null && args.length > 1 ? (args[1] as num).toInt() : _rows.length;
      final filtered = _rows.values
          .where((row) => row['category'] == category)
          .take(limit)
          .toList(growable: false);
      return filtered;
    }

    if (normalized.startsWith(_latestByCreatedAtOperationPrefix)) {
      final limit = args != null && args.isNotEmpty ? (args.first as num).toInt() : _rows.length;
      final sorted = _rows.values.toList()
        ..sort(
          (a, b) => ((b['created_at'] as num?)?.toInt() ?? 0)
              .compareTo((a['created_at'] as num?)?.toInt() ?? 0),
        );
      return sorted.take(limit).toList(growable: false);
    }

    throw UnsupportedError(
      'Unsupported query for $engineName: $query. '
      'Supported read patterns are count, category filter, and created_at DESC limit.',
    );
  }

  @override
  Future<void> executePragma(BenchmarkPragmaConfig pragmas) async {}
}
