import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  static DatabaseManager get instance => _instance;
  
  Database? _database;
  
  DatabaseManager._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    // Obtener la ruta para almacenar la base de datos
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'nicoya_now.db');
    
    // Abrir/crear la base de datos
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Crear las tablas de la base de datos
    await db.execute('''
      CREATE TABLE establishment (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        address TEXT,
        phone_number TEXT,
        image_url TEXT,
        latitude REAL,
        longitude REAL,
        category_id TEXT,
        owner_id TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE product (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        image_url TEXT,
        category_id TEXT,
        establishment_id TEXT NOT NULL,
        is_available INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (establishment_id) REFERENCES establishment (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE categoria_producto (
        id_categoria_producto INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        establishment_id TEXT NOT NULL,
        status TEXT NOT NULL,
        total_amount REAL,
        delivery_address TEXT,
        delivery_latitude REAL,
        delivery_longitude REAL,
        notes TEXT,
        payment_method TEXT,
        is_paid INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (establishment_id) REFERENCES establishment (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migraciones cuando sea necesario
    if (oldVersion < 2) {
      // Ejemplo de migración para la versión 2
      // await db.execute('ALTER TABLE ...');
    }
  }
  
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
  
  Future<void> deleteDatabase() async {
    await closeDatabase();
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'nicoya_now.db');
    await databaseFactory.deleteDatabase(path);
  }
}