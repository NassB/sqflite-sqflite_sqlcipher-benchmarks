import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:database_benchmarks/core/constants/app_constants.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/benchmark_run.dart';

class HistoryRepository {
  const HistoryRepository();

  Future<List<BenchmarkRun>> readAll() async {
    final file = await _historyFile();
    if (!file.existsSync()) return [];
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    final raw = jsonDecode(content) as List<dynamic>;
    return raw
        .map((e) => BenchmarkRun.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveRun(BenchmarkRun run) async {
    final all = await readAll();
    all.insert(0, run);
    await _write(all);
  }

  Future<void> saveRuns(List<BenchmarkRun> runs) async {
    final all = await readAll();
    all.insertAll(0, runs);
    await _write(all);
  }

  Future<void> deleteRun(String id) async {
    final all = await readAll();
    all.removeWhere((run) => run.id == id);
    await _write(all);
  }

  Future<void> clear() async {
    final file = await _historyFile();
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> _write(List<BenchmarkRun> runs) async {
    final file = await _historyFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(runs.map((e) => e.toJson()).toList()),
    );
  }

  Future<File> _historyFile() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, AppConstants.historyFolderName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, AppConstants.historyFileName));
  }
}
