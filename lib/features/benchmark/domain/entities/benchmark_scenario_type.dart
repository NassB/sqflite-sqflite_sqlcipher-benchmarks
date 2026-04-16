enum BenchmarkScenarioType {
  openDatabase,
  bulkInsert,
  read,
  update,
  delete,
  mixed,
  repeatedOpenClose,
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
    }
  }
}
