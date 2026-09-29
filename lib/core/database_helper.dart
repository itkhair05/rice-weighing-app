import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static DatabaseHelper? _instance;
  late final Database db;
  late final String path;

  DatabaseHelper._();

  static Future<DatabaseHelper> get instance async {
    _instance ??= await DatabaseHelper._init();
    return _instance!;
  }

  static Future<DatabaseHelper> _init() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'can_lua_gia_dinh.db');
    final database = await openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await _createOldTables(db);
        await _createWeighingTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createWeighingTables(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE weighing_sessions ADD COLUMN price_per_kg REAL',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE weighing_sessions ADD COLUMN owner TEXT',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE weighing_sessions ADD COLUMN '
            'deduct_total REAL NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE weighing_sessions ADD COLUMN rice_variety TEXT',
          );
          await db.execute(
            'ALTER TABLE weighing_sessions ADD COLUMN deposit REAL',
          );
        }
      },
    );
    return DatabaseHelper._()
      ..db = database
      ..path = path;
  }

  static Future<void> _createOldTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rice_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        price_per_kg REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rice_batch_id INTEGER NOT NULL,
        sold_weight_kg REAL NOT NULL,
        total REAL NOT NULL,
        sold_at INTEGER NOT NULL,
        FOREIGN KEY (rice_batch_id) REFERENCES rice_batches(id)
      )
    ''');
  }

  static Future<void> _createWeighingTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weighing_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        bags_per_set INTEGER NOT NULL DEFAULT 5,
        deduct_per_bag REAL NOT NULL DEFAULT 0,
        deduct_total REAL NOT NULL DEFAULT 0,
        price_per_kg REAL,
        owner TEXT,
        rice_variety TEXT,
        deposit REAL,
        note TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weighing_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES weighing_sessions(id)
          ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        set_id INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        FOREIGN KEY (set_id) REFERENCES weighing_sets(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await db.close();
    _instance = null;
  }
}
