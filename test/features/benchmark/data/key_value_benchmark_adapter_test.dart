import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/objectbox_adapter.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_pragma_config.dart';

/// Uses [ObjectboxAdapter] as a concrete test vehicle for the shared
/// [KeyValueBenchmarkAdapter] logic (ObjectboxAdapter adds no extra behaviour).
void main() {
  late ObjectboxAdapter adapter;

  // A helper that returns a fake row map similar to BenchmarkFakeDataGenerator output.
  Map<String, Object?> row(int index, {int status = 0, int createdAt = 1000}) => {
        'ext_id': 'ext_$index',
        'category': 'cat_${index % 3}',
        'title': 'Title $index',
        'description': 'Desc $index',
        'status': status,
        'score': index.toDouble(),
        'created_at': createdAt,
        'updated_at': createdAt,
        'payload': '{"i":$index}',
      };

  setUp(() async {
    adapter = ObjectboxAdapter();
    // Open against a path that will not exist — the adapter is fully in-memory
    // until close() persists to disk.  Passing '/nonexistent/...' means no
    // file will be found and no file I/O occurs during the test.
    await adapter.open(dbPath: '/nonexistent/bench_kv_test');
  });

  tearDown(() {
    // Create a fresh instance to discard in-memory state without persisting.
    adapter = ObjectboxAdapter();
  });

  group('engineName', () {
    test('returns objectbox', () {
      expect(adapter.engineName, 'objectbox');
    });
  });

  group('insertOne', () {
    test('returns incrementing ids starting at 1', () async {
      final id1 = await adapter.insertOne(row(0));
      final id2 = await adapter.insertOne(row(1));
      expect(id1, 1);
      expect(id2, 2);
    });

    test('stored row is retrievable by id', () async {
      await adapter.insertOne(row(0));
      final retrieved = await adapter.readById(1);
      expect(retrieved, isNotNull);
      expect(retrieved!['title'], 'Title 0');
      expect(retrieved['id'], 1);
    });
  });

  group('insertManyBatch', () {
    test('inserts all rows', () async {
      await adapter.insertManyBatch([row(0), row(1), row(2)]);
      expect(await adapter.readCount(), 3);
    });

    test('ids are consecutive and unique', () async {
      await adapter.insertManyBatch([row(0), row(1), row(2)]);
      for (var id = 1; id <= 3; id++) {
        final r = await adapter.readById(id);
        expect(r, isNotNull, reason: 'Expected row with id=$id');
      }
    });
  });

  group('readById', () {
    test('returns null for missing id', () async {
      expect(await adapter.readById(999), isNull);
    });
  });

  group('readPagedList', () {
    test('returns rows in descending created_at order', () async {
      await adapter.insertOne({...row(0), 'created_at': 100});
      await adapter.insertOne({...row(1), 'created_at': 300});
      await adapter.insertOne({...row(2), 'created_at': 200});

      final page = await adapter.readPagedList(limit: 10, offset: 0);
      expect(page.length, 3);
      expect(page[0]['created_at'], 300);
      expect(page[1]['created_at'], 200);
      expect(page[2]['created_at'], 100);
    });

    test('respects limit and offset', () async {
      for (var i = 0; i < 5; i++) {
        await adapter.insertOne({...row(i), 'created_at': i * 100});
      }
      final page = await adapter.readPagedList(limit: 2, offset: 1);
      expect(page.length, 2);
    });

    test('returns empty list when offset exceeds row count', () async {
      await adapter.insertOne(row(0));
      final page = await adapter.readPagedList(limit: 10, offset: 100);
      expect(page, isEmpty);
    });
  });

  group('readCount', () {
    test('returns 0 when empty', () async {
      expect(await adapter.readCount(), 0);
    });

    test('returns correct count after inserts', () async {
      await adapter.insertManyBatch([row(0), row(1), row(2)]);
      expect(await adapter.readCount(), 3);
    });
  });

  group('updateMany', () {
    test('updates status and updated_at for rows with id <= maxId', () async {
      await adapter.insertManyBatch([row(0), row(1), row(2)]);

      final count = await adapter.updateMany(maxId: 2, status: 9);
      expect(count, 2);

      final r1 = await adapter.readById(1);
      final r2 = await adapter.readById(2);
      final r3 = await adapter.readById(3);
      expect(r1!['status'], 9);
      expect(r2!['status'], 9);
      expect(r3!['status'], isNot(9));
    });

    test('returns 0 when no rows match', () async {
      await adapter.insertOne(row(0));
      final count = await adapter.updateMany(maxId: 0, status: 5);
      expect(count, 0);
    });
  });

  group('deleteByIds', () {
    test('removes specified rows and returns count', () async {
      await adapter.insertManyBatch([row(0), row(1), row(2)]);

      final count = await adapter.deleteByIds([1, 3]);
      expect(count, 2);
      expect(await adapter.readById(1), isNull);
      expect(await adapter.readById(2), isNotNull);
      expect(await adapter.readById(3), isNull);
    });

    test('returns 0 for empty id list', () async {
      expect(await adapter.deleteByIds([]), 0);
    });
  });

  group('deleteByRange', () {
    test('removes rows in inclusive id range', () async {
      await adapter.insertManyBatch([row(0), row(1), row(2), row(3), row(4)]);

      final count = await adapter.deleteByRange(fromInclusive: 2, toInclusive: 4);
      expect(count, 3);
      expect(await adapter.readCount(), 2);
      expect(await adapter.readById(1), isNotNull);
      expect(await adapter.readById(5), isNotNull);
    });
  });

  group('purgeAll', () {
    test('removes all rows and returns original count', () async {
      await adapter.insertManyBatch([row(0), row(1), row(2)]);

      final count = await adapter.purgeAll();
      expect(count, 3);
      expect(await adapter.readCount(), 0);
    });

    test('resets id sequence so next insert starts at 1', () async {
      await adapter.insertOne(row(0));
      await adapter.purgeAll();
      final id = await adapter.insertOne(row(0));
      expect(id, 1);
    });
  });

  group('rawQuery', () {
    setUp(() async {
      await adapter.insertOne({...row(0), 'category': 'cat_0', 'created_at': 100});
      await adapter.insertOne({...row(1), 'category': 'cat_1', 'created_at': 300});
      await adapter.insertOne({...row(2), 'category': 'cat_0', 'created_at': 200});
    });

    test('count query returns total row count', () async {
      final result = await adapter.rawQuery('SELECT COUNT(*) AS c FROM bench_items');
      expect(result.length, 1);
      expect(result.first['c'], 3);
    });

    test('category filter returns matching rows respecting limit', () async {
      final result = await adapter.rawQuery(
        'SELECT * FROM bench_items WHERE category = ? LIMIT ?',
        ['cat_0', 1],
      );
      expect(result.length, 1);
      expect(result.first['category'], 'cat_0');
    });

    test('category filter returns all matching rows', () async {
      final result = await adapter.rawQuery(
        'SELECT * FROM bench_items WHERE category = ? LIMIT ?',
        ['cat_0', 100],
      );
      expect(result.length, 2);
    });

    test('created_at desc query returns rows in descending order', () async {
      final result = await adapter.rawQuery(
        'SELECT * FROM bench_items ORDER BY created_at DESC LIMIT ?',
        [10],
      );
      expect(result.length, 3);
      expect(result[0]['created_at'], 300);
      expect(result[1]['created_at'], 200);
      expect(result[2]['created_at'], 100);
    });

    test('created_at desc query respects limit', () async {
      final result = await adapter.rawQuery(
        'SELECT * FROM bench_items ORDER BY created_at DESC LIMIT ?',
        [2],
      );
      expect(result.length, 2);
    });

    test('unsupported query throws UnsupportedError', () async {
      expect(
        () => adapter.rawQuery('SELECT * FROM bench_items WHERE score > ?', [50]),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('createSchema and executePragma', () {
    test('createSchema completes without error', () async {
      await expectLater(adapter.createSchema(), completes);
    });

    test('executePragma completes without error', () async {
      await expectLater(
        adapter.executePragma(const BenchmarkPragmaConfig()),
        completes,
      );
    });
  });
}
