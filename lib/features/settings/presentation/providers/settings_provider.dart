import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_pragma_config.dart';

class AppSettings {
  const AppSettings({
    this.sqlcipherPassword = 'benchmark_password',
    this.pragmas = const BenchmarkPragmaConfig(),
    this.seed = 42,
    this.themeMode = ThemeMode.system,
  });

  final String sqlcipherPassword;
  final BenchmarkPragmaConfig pragmas;
  final int seed;
  final ThemeMode themeMode;

  AppSettings copyWith({
    String? sqlcipherPassword,
    BenchmarkPragmaConfig? pragmas,
    int? seed,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      sqlcipherPassword: sqlcipherPassword ?? this.sqlcipherPassword,
      pragmas: pragmas ?? this.pragmas,
      seed: seed ?? this.seed,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void updatePassword(String value) => state = state.copyWith(sqlcipherPassword: value);

  void updateSeed(int value) => state = state.copyWith(seed: value);

  void updateTheme(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void updatePragmas(BenchmarkPragmaConfig pragmas) => state = state.copyWith(pragmas: pragmas);
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
