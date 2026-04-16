import 'dart:math';

class BenchmarkFakeDataGenerator {
  BenchmarkFakeDataGenerator(this.seed) : _random = Random(seed);

  final int seed;
  final Random _random;

  List<Map<String, Object?>> generateRows(int count) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(count, (index) {
      return {
        'ext_id': 'ext_${seed}_$index',
        'category': 'cat_${index % 20}',
        'title': 'Title $index',
        'description': 'Description row $index generated with seed $seed',
        'status': _random.nextInt(5),
        'score': _random.nextDouble() * 100,
        'created_at': now - _random.nextInt(500000),
        'updated_at': now,
        'payload': '{"index":$index,"seed":$seed}',
      };
    });
  }
}
