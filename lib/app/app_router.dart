import 'package:go_router/go_router.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_run.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/presentation/screens/benchmark_detail_screen.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/presentation/screens/run_benchmark_screen.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/history/presentation/screens/history_screen.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/settings/presentation/screens/settings_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/run', builder: (_, __) => const RunBenchmarkScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(
        path: '/detail',
        builder: (_, state) => BenchmarkDetailScreen(run: state.extra! as BenchmarkRun),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
}
