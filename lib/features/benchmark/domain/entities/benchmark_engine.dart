enum BenchmarkEngine { sqflite, sqfliteSqlcipher }

extension BenchmarkEngineX on BenchmarkEngine {
  String get label {
    switch (this) {
      case BenchmarkEngine.sqflite:
        return 'sqflite';
      case BenchmarkEngine.sqfliteSqlcipher:
        return 'sqflite_sqlcipher';
    }
  }
}
