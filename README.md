# sqflite-sqflite_sqlcipher-benchmarks

Application Flutter Android/iOS pour benchmarker et comparer `sqflite` et `sqflite_sqlcipher` dans des conditions équivalentes.

## Objectif

- Exécuter des scénarios reproductibles de benchmark SQLite.
- Comparer les engines (`sqflite`, `sqflite_sqlcipher`) à configuration identique.
- Afficher des résultats live et des métriques statistiques (moyenne, médiane, p95, ops/s).
- Conserver un historique local des runs.
- Exporter les résultats en JSON/CSV.

## Architecture

```text
lib/
  app/
  core/
    constants/
    error/
    services/
    utils/
  features/
    benchmark/
      data/
      domain/
      presentation/
    history/
      data/
      presentation/
    settings/
      presentation/
    dashboard/
      presentation/
  shared/
    theme/
    widgets/
```

## Dépendances principales

- State: `flutter_riverpod`
- Navigation: `go_router`
- DB: `sqflite`, `sqflite_sqlcipher`
- Charts: `fl_chart`
- Export: `csv`, `share_plus`
- Device/build metadata: `device_info_plus`, `package_info_plus`

## Différences fonctionnelles sqflite vs sqflite_sqlcipher

- `sqflite_sqlcipher` ajoute le chiffrement et nécessite un mot de passe.
- Overhead attendu à l'ouverture et sur write-heavy workloads.
- Schéma, requêtes, index, volumes et scénarios restent identiques pour limiter les biais.

## Méthodologie benchmark intégrée

- Warmup optionnel avant mesure.
- Itérations séquentielles.
- Mesure via `Stopwatch`.
- Réinitialisation DB optionnelle.
- Noms de fichiers DB distincts par engine.
- PRAGMAs configurables (`journal_mode`, `synchronous`, `temp_store`, `cache_size`, `foreign_keys`).
- Captures: total, moyenne, médiane, min, max, p95, ops/s, tailles DB/WAL.

## Limites méthodologiques

- Les résultats varient selon device, température, batterie, I/O système.
- Éviter l’émulateur si possible.
- Exécuter en **profile** ou **release** uniquement.
- Le mode debug fausse les timings (assertions, instrumentation, VM overhead).

## Pourquoi mesurer sur device réel

- Le stockage physique et le chiffrement matériel diffèrent fortement de l’émulateur.
- Les performances I/O et scheduler reflètent mieux le comportement utilisateur réel.

## Setup

```bash
flutter --version
flutter pub get
```

## Génération de code (si extension future avec freezed/json_serializable)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Lancer l’application

```bash
flutter run --profile
# ou
flutter run --release
```

## Scénarios implémentés

- Open database
- Bulk insert
- Read
- Update
- Delete
- Mixed workload
- Repeated open/close

## Interpréter les résultats

- Comparer d’abord médiane + p95 (plus robustes que la moyenne seule).
- Utiliser ops/s pour comparer la capacité brute.
- Vérifier taille DB/WAL pour interpréter l’impact des PRAGMA.
- Lire le delta `%` entre engines par scénario.

## Exports

- Export run individuel en JSON.
- Export CSV (run(s)) pour analyse externe.

## Tests

```bash
flutter test test/core/services/stats_calculator_test.dart
flutter test test/features/benchmark/domain/benchmark_run_mapping_test.dart
flutter test test/features/benchmark/presentation/run_benchmark_screen_test.dart
flutter test integration_test/minimal_benchmark_flow_test.dart
```

## Pistes d’extension

- Ajouter `drift` ou `sqlite3/ffi` via implémentations supplémentaires de `DatabaseAdapter`.
- Ajouter comparaison multi-runs directement dans l’écran détail.
- Persist settings sur disque (actuellement en mémoire Riverpod).
- Ajouter exports globaux multi-scenarios.
