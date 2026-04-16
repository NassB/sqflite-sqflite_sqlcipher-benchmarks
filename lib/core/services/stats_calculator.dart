import 'dart:math' as math;

import 'package:collection/collection.dart';

class StatsCalculator {
  const StatsCalculator();

  double total(List<double> values) => values.fold(0, (a, b) => a + b);

  double mean(List<double> values) {
    if (values.isEmpty) return 0;
    return total(values) / values.length;
  }

  double median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isEven) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    }
    return sorted[middle];
  }

  double percentile(List<double> values, double percentile) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final rank = (percentile / 100) * (sorted.length - 1);
    final low = rank.floor();
    final high = rank.ceil();
    if (low == high) return sorted[low];
    final weight = rank - low;
    return sorted[low] * (1 - weight) + sorted[high] * weight;
  }

  double min(List<double> values) => values.minOrNull ?? 0;

  double max(List<double> values) => values.maxOrNull ?? 0;

  double opsPerSecond({required int operationCount, required double totalMs}) {
    if (totalMs <= 0) return 0;
    return operationCount / (totalMs / 1000);
  }

  double deltaPercent({required double reference, required double candidate}) {
    if (reference == 0) return 0;
    return ((candidate - reference) / reference) * 100;
  }

  String formatDeltaMessage({required double delta, required String baseline}) {
    final sign = delta >= 0 ? '+' : '';
    if (delta > 1) return '$sign${delta.toStringAsFixed(1)}% slower than $baseline';
    if (delta < -1) {
      return '${delta.toStringAsFixed(1)}% faster';
    }
    return '$sign${delta.toStringAsFixed(1)}% similar to $baseline';
  }

  int percentileIndex(int size, double pct) {
    if (size <= 0) return 0;
    return math.max(0, ((size - 1) * pct).round());
  }
}
