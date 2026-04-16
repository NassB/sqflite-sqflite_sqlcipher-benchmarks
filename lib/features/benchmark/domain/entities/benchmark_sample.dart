class BenchmarkSample {
  const BenchmarkSample({
    required this.iteration,
    required this.elapsedMs,
  });

  final int iteration;
  final double elapsedMs;

  Map<String, dynamic> toJson() => {
        'iteration': iteration,
        'elapsedMs': elapsedMs,
      };

  factory BenchmarkSample.fromJson(Map<String, dynamic> json) {
    return BenchmarkSample(
      iteration: (json['iteration'] as num).toInt(),
      elapsedMs: (json['elapsedMs'] as num).toDouble(),
    );
  }
}
