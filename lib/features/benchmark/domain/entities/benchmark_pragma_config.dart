class BenchmarkPragmaConfig {
  const BenchmarkPragmaConfig({
    this.journalMode = 'WAL',
    this.synchronous = 'NORMAL',
    this.tempStore = 'MEMORY',
    this.cacheSize = -2000,
    this.foreignKeys = true,
  });

  final String journalMode;
  final String synchronous;
  final String tempStore;
  final int cacheSize;
  final bool foreignKeys;

  Map<String, dynamic> toJson() => {
        'journal_mode': journalMode,
        'synchronous': synchronous,
        'temp_store': tempStore,
        'cache_size': cacheSize,
        'foreign_keys': foreignKeys,
      };

  factory BenchmarkPragmaConfig.fromJson(Map<String, dynamic> json) {
    return BenchmarkPragmaConfig(
      journalMode: json['journal_mode'] as String? ?? 'WAL',
      synchronous: json['synchronous'] as String? ?? 'NORMAL',
      tempStore: json['temp_store'] as String? ?? 'MEMORY',
      cacheSize: (json['cache_size'] as num?)?.toInt() ?? -2000,
      foreignKeys: json['foreign_keys'] as bool? ?? true,
    );
  }
}
