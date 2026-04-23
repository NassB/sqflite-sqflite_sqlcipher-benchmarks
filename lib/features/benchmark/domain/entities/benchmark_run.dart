import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_engine.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_sample.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_scenario_config.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_summary.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/device_metadata.dart';

class BenchmarkRun {
  const BenchmarkRun({
    required this.id,
    required this.timestamp,
    required this.engine,
    required this.config,
    required this.samples,
    required this.summary,
    required this.deviceMetadata,
    required this.success,
    this.errorMessage,
  });

  final String id;
  final DateTime timestamp;
  final BenchmarkEngine engine;
  final BenchmarkScenarioConfig config;
  final List<BenchmarkSample> samples;
  final BenchmarkSummary summary;
  final DeviceMetadata deviceMetadata;
  final bool success;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'engine': engine.name,
        'config': config.toJson(),
        'samples': samples.map((e) => e.toJson()).toList(),
        'summary': summary.toJson(),
        'deviceMetadata': deviceMetadata.toJson(),
        'success': success,
        'errorMessage': errorMessage,
      };

  factory BenchmarkRun.fromJson(Map<String, dynamic> json) {
    return BenchmarkRun(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      engine: BenchmarkEngine.values.firstWhere(
        (e) => e.name == json['engine'],
        orElse: () => BenchmarkEngine.sqflite,
      ),
      config: BenchmarkScenarioConfig.fromJson(json['config'] as Map<String, dynamic>),
      samples: (json['samples'] as List<dynamic>)
          .map((e) => BenchmarkSample.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: BenchmarkSummary.fromJson(json['summary'] as Map<String, dynamic>),
      deviceMetadata:
          DeviceMetadata.fromJson(json['deviceMetadata'] as Map<String, dynamic>),
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
