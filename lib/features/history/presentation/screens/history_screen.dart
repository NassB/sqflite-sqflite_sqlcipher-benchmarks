import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/history/presentation/providers/history_provider.dart';
import 'package:sqflite_sqlcipher_benchmarks/shared/widgets/app_navigation_scaffold.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return AppNavigationScaffold(
      title: 'History',
      selectedIndex: 2,
      child: history.when(
        data: (runs) {
          if (runs.isEmpty) {
            return const Center(child: Text('Historique vide.'));
          }
          return ListView.builder(
            itemCount: runs.length,
            itemBuilder: (_, index) {
              final run = runs[index];
              return ListTile(
                title: Text('${run.engine.label} • ${run.config.scenario.label}'),
                subtitle: Text(
                  '${DateFormat('yyyy-MM-dd HH:mm').format(run.timestamp)} • ${run.summary.meanMs.toStringAsFixed(2)} ms',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(historyProvider.notifier).remove(run.id),
                ),
                onTap: () => context.go('/detail', extra: run),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
