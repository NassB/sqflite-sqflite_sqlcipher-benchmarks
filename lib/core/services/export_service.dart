import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_sqlcipher_benchmarks/core/constants/app_constants.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_run.dart';

class ExportService {
  const ExportService();

  Future<File> exportRunJson(BenchmarkRun run) async {
    final dir = await _exportDir();
    final file = File(p.join(dir.path, 'run_${run.id}.json'));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(run.toJson()));
    return file;
  }

  Future<File> exportRunsCsv(List<BenchmarkRun> runs, {String name = 'benchmark_runs'}) async {
    final rows = <List<dynamic>>[
      [
        'id',
        'timestamp',
        'engine',
        'scenario',
        'total_ms',
        'mean_ms',
        'median_ms',
        'p95_ms',
        'ops_per_sec',
        'db_size_bytes',
        'wal_size_bytes',
        'success',
      ],
      ...runs.map(
        (run) => [
          run.id,
          run.timestamp.toIso8601String(),
          run.engine.label,
          run.config.scenario.name,
          run.summary.totalMs,
          run.summary.meanMs,
          run.summary.medianMs,
          run.summary.p95Ms,
          run.summary.opsPerSec,
          run.summary.dbSizeBytes,
          run.summary.walSizeBytes,
          run.success,
        ],
      ),
    ];

    final dir = await _exportDir();
    final file = File(p.join(dir.path, '$name.csv'));
    await file.writeAsString(const ListToCsvConverter().convert(rows));
    return file;
  }

  Future<void> shareFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
  }

  Future<Directory> _exportDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, AppConstants.exportFolderName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
