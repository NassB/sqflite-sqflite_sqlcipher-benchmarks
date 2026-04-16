enum BenchmarkScenarioType {
  openDatabase,
  bulkInsert,
  read,
  update,
  delete,
  mixed,
  repeatedOpenClose,
  full,
}

extension BenchmarkScenarioTypeX on BenchmarkScenarioType {
  String get label {
    switch (this) {
      case BenchmarkScenarioType.openDatabase:
        return 'Open database';
      case BenchmarkScenarioType.bulkInsert:
        return 'Bulk insert';
      case BenchmarkScenarioType.read:
        return 'Read';
      case BenchmarkScenarioType.update:
        return 'Update';
      case BenchmarkScenarioType.delete:
        return 'Delete';
      case BenchmarkScenarioType.mixed:
        return 'Mixed workload';
      case BenchmarkScenarioType.repeatedOpenClose:
        return 'Repeated open/close';
      case BenchmarkScenarioType.full:
        return 'Full benchmark';
    }
  }

  /// Fixed iterations used when this scenario is [full].
  static const int fullIterations = 10;

  /// Fixed record count used when this scenario is [full].
  static const int fullRecordCount = 1000;
}
