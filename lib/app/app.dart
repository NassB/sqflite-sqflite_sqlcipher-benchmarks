import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:database_benchmarks/app/app_router.dart';
import 'package:database_benchmarks/features/settings/presentation/providers/settings_provider.dart';
import 'package:database_benchmarks/shared/theme/app_theme.dart';

class BenchmarkApp extends ConsumerWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildRouter();
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'SQLite Benchmark Lab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
