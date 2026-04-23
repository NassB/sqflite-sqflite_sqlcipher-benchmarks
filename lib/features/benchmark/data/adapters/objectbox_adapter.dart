import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/data/adapters/key_value_benchmark_adapter.dart';

class ObjectboxAdapter extends KeyValueBenchmarkAdapter {
  @override
  String get engineName => 'objectbox';
}
