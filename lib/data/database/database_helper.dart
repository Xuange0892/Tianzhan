import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tunnelmate.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        employee_no TEXT UNIQUE NOT NULL,
        id_card TEXT,
        phone TEXT,
        department TEXT,
        job_type TEXT,
        job_level TEXT,
        certificate_no TEXT,
        certificate_expire_date TEXT,
        entry_date TEXT,
        status TEXT DEFAULT 'active',
        emergency_contact TEXT,
        emergency_phone TEXT,
        photo_path TEXT,
        remark TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        shift_type TEXT,
        check_in_time TEXT,
        check_out_time TEXT,
        check_in_location TEXT,
        status TEXT DEFAULT 'normal',
        work_hours REAL,
        overtime_hours REAL DEFAULT 0,
        remark TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (worker_id) REFERENCES workers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        shift_type TEXT NOT NULL,
        position TEXT,
        is_duty_leader INTEGER DEFAULT 0,
        status TEXT DEFAULT 'scheduled',
        exchange_with INTEGER,
        remark TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (worker_id) REFERENCES workers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE measure_docs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        doc_type TEXT,
        content TEXT,
        version INTEGER DEFAULT 1,
        status TEXT DEFAULT 'draft',
        author TEXT,
        reviewer TEXT,
        approver TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_attendance_date ON attendance(date);
    ''');
    await db.execute('''
      CREATE INDEX idx_attendance_worker ON attendance(worker_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_schedules_date ON schedules(date);
    ''');
    await db.execute('''
      CREATE INDEX idx_workers_status ON workers(status);
    ''');
    await db.execute('''
      CREATE INDEX idx_workers_department ON workers(department);
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 后续版本升级在此处理
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
