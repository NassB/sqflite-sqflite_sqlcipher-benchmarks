import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/domain/entities/benchmark_pragma_config.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/history/presentation/providers/history_provider.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/settings/presentation/providers/settings_provider.dart';
import 'package:sqflite_sqlcipher_benchmarks/shared/widgets/app_navigation_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AppNavigationScaffold(
      title: 'Settings',
      selectedIndex: 3,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            initialValue: settings.sqlcipherPassword,
            decoration: const InputDecoration(labelText: 'Default SQLCipher password'),
            onChanged: notifier.updatePassword,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: '${settings.seed}',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Default seed'),
            onChanged: (value) => notifier.updateSeed(int.tryParse(value) ?? settings.seed),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ThemeMode>(
            value: settings.themeMode,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            onChanged: (mode) {
              if (mode != null) notifier.updateTheme(mode);
            },
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () {
              notifier.updatePragmas(const BenchmarkPragmaConfig());
            },
            child: const Text('Reset PRAGMA defaults'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () => ref.read(historyProvider.notifier).clear(),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );
  }
}
