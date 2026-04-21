enum BenchmarkEngine {
  sqflite,
  sqfliteSqlcipher,
  drift,
  hive,
  sembast,
  objectbox,
  isarCommunity,
}

extension BenchmarkEngineX on BenchmarkEngine {
  String get label {
    switch (this) {
      case BenchmarkEngine.sqflite:
        return 'sqflite';
      case BenchmarkEngine.sqfliteSqlcipher:
        return 'sqflite_sqlcipher';
      case BenchmarkEngine.drift:
        return 'drift';
      case BenchmarkEngine.hive:
        return 'hive';
      case BenchmarkEngine.sembast:
        return 'sembast';
      case BenchmarkEngine.objectbox:
        return 'objectbox';
      case BenchmarkEngine.isarCommunity:
        return 'isar_community';
    }
  }
}
