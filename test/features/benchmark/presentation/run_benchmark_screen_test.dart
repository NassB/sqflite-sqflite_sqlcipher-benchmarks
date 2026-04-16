import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/presentation/screens/run_benchmark_screen.dart';

void main() {
  testWidgets('shows benchmark config form fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RunBenchmarkScreen()),
      ),
    );

    expect(find.byKey(const ValueKey('scenarioDropdown')), findsOneWidget);
    expect(find.byKey(const ValueKey('iterationsField')), findsOneWidget);
    expect(find.byKey(const ValueKey('recordCountField')), findsOneWidget);
    expect(find.byKey(const ValueKey('sqlcipherPasswordField')), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
  });
}
