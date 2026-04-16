import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_sqlcipher_benchmarks/features/benchmark/presentation/screens/run_benchmark_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('minimal screen flow renders run button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RunBenchmarkScreen()),
      ),
    );

    expect(find.text('Run'), findsOneWidget);
  });
}
