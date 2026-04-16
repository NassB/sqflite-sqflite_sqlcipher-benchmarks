import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher_benchmarks/core/services/stats_calculator.dart';

void main() {
  const calculator = StatsCalculator();

  test('computes median and p95', () {
    const values = [10.0, 20.0, 30.0, 40.0, 50.0];
    expect(calculator.median(values), 30.0);
    expect(calculator.percentile(values, 95), closeTo(48, 0.1));
  });

  test('computes ops/s', () {
    expect(calculator.opsPerSecond(operationCount: 1000, totalMs: 500), 2000);
  });

  test('computes delta', () {
    expect(
      calculator.deltaPercent(reference: 100, candidate: 120),
      20,
    );
  });
}
