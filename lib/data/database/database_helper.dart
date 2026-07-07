import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';

/// 数据库辅助类
/// 单例模式管理 SQLite 数据库
/// 版本2：新增自定义字段、签到、证件、待办、排班配置等功能表
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// 获取数据库实例（懒加载）
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/${AppConstants.databaseName}';

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建所有数据表
  Future<void> _onCreate(Database db, int version) async {
    // ==================== 人员表 ====================
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
        custom_fields TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ==================== 考勤表 ====================
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

    // ==================== 排班表 ====================
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

    // ==================== 措施文档表 ====================
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

    // ==================== 自定义字段表（保留旧字段结构兼容） ====================
    await db.execute('''
      CREATE TABLE custom_fields (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT DEFAULT 'text',
        sort_order INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ==================== 人员自定义字段值表 ====================
    await db.execute('''
      CREATE TABLE worker_custom_values (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_id INTEGER NOT NULL,
        field_id INTEGER NOT NULL,
        value TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(worker_id, field_id),
        FOREIGN KEY (worker_id) REFERENCES workers(id) ON DELETE CASCADE,
        FOREIGN KEY (field_id) REFERENCES custom_fields(id) ON DELETE CASCADE
      )
    ''');

    // ==================== 签到事项表 ====================
    await db.execute('''
      CREATE TABLE sign_in_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ==================== 签到记录表 ====================
    await db.execute('''
      CREATE TABLE sign_in_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        worker_id INTEGER NOT NULL,
        signed_in INTEGER DEFAULT 0,
        signed_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(event_id, worker_id),
        FOREIGN KEY (event_id) REFERENCES sign_in_events(id) ON DELETE CASCADE,
        FOREIGN KEY (worker_id) REFERENCES workers(id)
      )
    ''');

    // ==================== 证件管理表 ====================
    await db.execute('''
      CREATE TABLE certificates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        number TEXT,
        image_path TEXT,
        issue_date TEXT,
        expire_date TEXT,
        remark TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (worker_id) REFERENCES workers(id)
      )
    ''');

    // ==================== 待办事项表 ====================
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        priority TEXT DEFAULT 'medium',
        is_completed INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ==================== 应用设置表 ====================
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // ==================== 管理人员排班表 ====================
    await db.execute('''
      CREATE TABLE manager_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        position TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (worker_id) REFERENCES workers(id)
      )
    ''');

    // ==================== 排班配置表 ====================
    await db.execute('''
      CREATE TABLE schedule_configs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_name TEXT NOT NULL,
        config_key TEXT NOT NULL,
        config_value TEXT,
        UNIQUE(group_name, config_key)
      )
    ''');

    // ==================== 索引 ====================
    await db.execute('CREATE INDEX idx_attendance_date ON attendance(date)');
    await db.execute('CREATE INDEX idx_attendance_worker ON attendance(worker_id)');
    await db.execute('CREATE INDEX idx_schedules_date ON schedules(date)');
    await db.execute('CREATE INDEX idx_workers_status ON workers(status)');
    await db.execute('CREATE INDEX idx_workers_department ON workers(department)');
    await db.execute('CREATE INDEX idx_sign_in_records_event ON sign_in_records(event_id)');
    await db.execute('CREATE INDEX idx_certificates_worker ON certificates(worker_id)');
    await db.execute('CREATE INDEX idx_certificates_expire ON certificates(expire_date)');
    await db.execute('CREATE INDEX idx_todos_due ON todos(due_date)');
    await db.execute('CREATE INDEX idx_manager_schedules_date ON manager_schedules(date)');
    await db.execute('CREATE INDEX idx_worker_custom_values_worker ON worker_custom_values(worker_id)');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 -> v2: 新增签到、证件、待办、设置、管理人员排班、排班配置等表
    if (oldVersion < 2) {
      // 确保workers表有 custom_fields 列
      try { await db.execute('ALTER TABLE workers ADD COLUMN custom_fields TEXT'); } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sign_in_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sign_in_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          worker_id INTEGER NOT NULL,
          signed_in INTEGER DEFAULT 0,
          signed_at TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(event_id, worker_id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS certificates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          worker_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          number TEXT,
          image_path TEXT,
          issue_date TEXT,
          expire_date TEXT,
          remark TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS todos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          due_date TEXT,
          priority TEXT DEFAULT 'medium',
          is_completed INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS manager_schedules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          worker_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          position TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS schedule_configs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_name TEXT NOT NULL,
          config_key TEXT NOT NULL,
          config_value TEXT,
          UNIQUE(group_name, config_key)
        )
      ''');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
