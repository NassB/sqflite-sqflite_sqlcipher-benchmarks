const benchTable = 'bench_items';

const createBenchSchema = '''
CREATE TABLE IF NOT EXISTS bench_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ext_id TEXT,
  category TEXT,
  title TEXT,
  description TEXT,
  status INTEGER,
  score REAL,
  created_at INTEGER,
  updated_at INTEGER,
  payload TEXT
);
''';

const createBenchIndexes = <String>[
  'CREATE INDEX IF NOT EXISTS idx_bench_ext_id ON bench_items(ext_id);',
  'CREATE INDEX IF NOT EXISTS idx_bench_category ON bench_items(category);',
  'CREATE INDEX IF NOT EXISTS idx_bench_created_at ON bench_items(created_at);',
  'CREATE INDEX IF NOT EXISTS idx_bench_status ON bench_items(status);',
];
