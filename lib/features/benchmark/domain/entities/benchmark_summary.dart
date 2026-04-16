class BenchmarkSummary {
  const BenchmarkSummary({
    required this.totalMs,
    required this.meanMs,
    required this.medianMs,
    required this.minMs,
    required this.maxMs,
    required this.p95Ms,
    required this.opsPerSec,
    required this.dbSizeBytes,
    required this.walSizeBytes,
  });

  final double totalMs;
  final double meanMs;
  final double medianMs;
  final double minMs;
  final double maxMs;
  final double p95Ms;
  final double opsPerSec;
  final int dbSizeBytes;
  final int walSizeBytes;

  Map<String, dynamic> toJson() => {
        'totalMs': totalMs,
        'meanMs': meanMs,
        'medianMs': medianMs,
        'minMs': minMs,
        'maxMs': maxMs,
        'p95Ms': p95Ms,
        'opsPerSec': opsPerSec,
        'dbSizeBytes': dbSizeBytes,
        'walSizeBytes': walSizeBytes,
      };

  factory BenchmarkSummary.fromJson(Map<String, dynamic> json) {
    return BenchmarkSummary(
      totalMs: (json['totalMs'] as num).toDouble(),
      meanMs: (json['meanMs'] as num).toDouble(),
      medianMs: (json['medianMs'] as num).toDouble(),
      minMs: (json['minMs'] as num).toDouble(),
      maxMs: (json['maxMs'] as num).toDouble(),
      p95Ms: (json['p95Ms'] as num).toDouble(),
      opsPerSec: (json['opsPerSec'] as num).toDouble(),
      dbSizeBytes: (json['dbSizeBytes'] as num).toInt(),
      walSizeBytes: (json['walSizeBytes'] as num).toInt(),
    );
  }
}
