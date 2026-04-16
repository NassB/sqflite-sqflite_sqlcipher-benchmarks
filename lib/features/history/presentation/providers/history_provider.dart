import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_run.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/history/data/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return const HistoryRepository();
});

final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<BenchmarkRun>>(
  HistoryNotifier.new,
);

class HistoryNotifier extends AsyncNotifier<List<BenchmarkRun>> {
  @override
  Future<List<BenchmarkRun>> build() {
    return ref.read(historyRepositoryProvider).readAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(historyRepositoryProvider).readAll());
  }

  Future<void> addRuns(List<BenchmarkRun> runs) async {
    await ref.read(historyRepositoryProvider).saveRuns(runs);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(historyRepositoryProvider).deleteRun(id);
    await refresh();
  }

  Future<void> clear() async {
    await ref.read(historyRepositoryProvider).clear();
    await refresh();
  }
}
