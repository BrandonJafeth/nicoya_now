import 'package:nicoya_now/services/data/local/database_manager.dart';
import 'package:nicoya_now/services/data/local/sqlite_data_source.dart';
import 'package:nicoya_now/services/data/remote/supabase_data_source.dart';
import 'package:nicoya_now/services/data/remote/turso_data_source.dart';
import 'package:nicoya_now/services/supabase_service.dart';
import 'package:nicoya_now/models/establishment.dart';
import 'package:nicoya_now/models/product.dart';
import 'package:nicoya_now/models/categoria_producto.dart';
import 'package:nicoya_now/models/order.dart';
import 'package:nicoya_now/services/repositories/multi_source_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Clase para inicializar y proporcionar acceso a todos los repositorios de datos
class DataManager {
  static final DataManager _instance = DataManager._internal();
  static DataManager get instance => _instance;
  
  DataManager._internal();
  
  // URL y token para Turso
  static const String _tursoUrl = 'https://nicoyanow-brandonjafeth.aws-us-east-1.turso.io';
  static const String _tursoToken = 'eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJleHAiOjE3NzczMTY4MTQsImlhdCI6MTc0NTc4MDgxNCwiaWQiOiI1NDA1ZmRmNi0yODY1LTRlZTItODQyMS1hNzc2YjVmOWE5ODUiLCJyaWQiOiI1ZGY4YjRkZC0xMjRmLTQ2ODgtYWI5NC0xYTg2ZDRhNzEyNjQifQ.QmudeZyRJbv07vXzrT0_Xbc_V1iY5j-VOy9tm-0JMrvS4k9kVV-xE26_zRcc8c7xWsvPpjnfd3avc6BR1os0DA';
  
  // Repositorios
  late MultiSourceRepository<Establishment> establishmentRepository;
  late MultiSourceRepository<Product> productRepository;
  late MultiSourceRepository<CategoriaProducto> categoriaProductoRepository;
  late MultiSourceRepository<Order> orderRepository;
  
  bool _initialized = false;
  
  /// Inicializar todas las fuentes de datos y repositorios
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // 1. Inicializar Supabase
      await SupabaseService.initialize();
      
      // 2. Inicializar SQLite
      final Database db = await DatabaseManager.instance.database;
      
      // 3. Configurar las fuentes de datos para cada modelo
      
      // Establishment
      final establishmentSupabaseDataSource = SupabaseDataSource<Establishment>(
        client: SupabaseService.client,
        tableName: 'establishment',
        fromMap: Establishment.fromMap,
        toMap: (e) => e.toMap(),
      );
      
      final establishmentSqliteDataSource = SQLiteDataSource<Establishment>(
        db: db,
        tableName: 'establishment',
        fromMap: Establishment.fromMap,
        toMap: (e, {bool forLocal = false}) => e.toMap(forLocal: forLocal),
      );
      
      final establishmentTursoDataSource = TursoDataSource<Establishment>(
        url: _tursoUrl,
        authToken: _tursoToken,
        tableName: 'establishment',
        fromMap: Establishment.fromMap,
        toMap: (e) => e.toMap(),
      );
      
      // Producto
      final productSupabaseDataSource = SupabaseDataSource<Product>(
        client: SupabaseService.client,
        tableName: 'product',
        fromMap: Product.fromMap,
        toMap: (p) => p.toMap(),
      );
      
      final productSqliteDataSource = SQLiteDataSource<Product>(
        db: db,
        tableName: 'product',
        fromMap: Product.fromMap,
        toMap: (p, {bool forLocal = false}) => p.toMap(forLocal: forLocal),
      );
      
      final productTursoDataSource = TursoDataSource<Product>(
        url: _tursoUrl,
        authToken: _tursoToken,
        tableName: 'product',
        fromMap: Product.fromMap,
        toMap: (p) => p.toMap(),
      );
      
      // Categoría de producto
      final categoriaProductoSupabaseDataSource = SupabaseDataSource<CategoriaProducto>(
        client: SupabaseService.client,
        tableName: 'categoria_producto',
        fromMap: CategoriaProducto.fromMap,
        toMap: (c) => c.toMap(),
      );
      
      final categoriaProductoSqliteDataSource = SQLiteDataSource<CategoriaProducto>(
        db: db,
        tableName: 'categoria_producto',
        fromMap: CategoriaProducto.fromMap,
        toMap: (c, {bool forLocal = false}) => c.toMap(forLocal: forLocal),
        idField: 'id_categoria_producto',
      );
      
      final categoriaProductoTursoDataSource = TursoDataSource<CategoriaProducto>(
        url: _tursoUrl,
        authToken: _tursoToken,
        tableName: 'categoria_producto',
        fromMap: CategoriaProducto.fromMap,
        toMap: (c) => c.toMap(),
        idField: 'id_categoria_producto',
      );
      
      // 4. Crear los repositorios híbridos
      establishmentRepository = MultiSourceRepository<Establishment>(
        supabaseDataSource: establishmentSupabaseDataSource,
        sqliteDataSource: establishmentSqliteDataSource,
        tursoDataSource: establishmentTursoDataSource,
        entityName: 'establishment',
        defaultPriority: DataSourcePriority.remote,
      );
      
      productRepository = MultiSourceRepository<Product>(
        supabaseDataSource: productSupabaseDataSource,
        sqliteDataSource: productSqliteDataSource,
        tursoDataSource: productTursoDataSource,
        entityName: 'product',
        defaultPriority: DataSourcePriority.remote,
      );
      
      categoriaProductoRepository = MultiSourceRepository<CategoriaProducto>(
        supabaseDataSource: categoriaProductoSupabaseDataSource,
        sqliteDataSource: categoriaProductoSqliteDataSource,
        tursoDataSource: categoriaProductoTursoDataSource,
        entityName: 'categoria_producto',
        defaultPriority: DataSourcePriority.remote,
      );
      
      // Order repository (simplificado, solo con Supabase por ahora)
      final orderSqliteDataSource = SQLiteDataSource<Order>(
        db: db,
        tableName: 'orders',
        fromMap: (map) => Order.fromMap(map, []), // Esto requiere lógica adicional para cargar elementos
        toMap: (o, {bool forLocal = false}) => o.toMap(forLocal: forLocal),
      );
      
      orderRepository = MultiSourceRepository<Order>(
        sqliteDataSource: orderSqliteDataSource,
        entityName: 'order',
        defaultPriority: DataSourcePriority.local,
      );
      
      // 5. Inicializar los repositorios
      await establishmentRepository.initialize();
      await productRepository.initialize();
      await categoriaProductoRepository.initialize();
      // await orderRepository.initialize(); // Esto requiere lógica adicional
      
      _initialized = true;
    } catch (e) {
      print('Error inicializando el DataManager: $e');
      rethrow;
    }
  }
  
  /// Método para cambiar la prioridad de fuente de datos para todas las entidades
  Future<void> setGlobalDataSourcePriority(DataSourcePriority priority) async {
    try {
      await establishmentRepository.setDataSourcePriority(priority);
      await productRepository.setDataSourcePriority(priority);
      await categoriaProductoRepository.setDataSourcePriority(priority);
      // await orderRepository.setDataSourcePriority(priority);
    } catch (e) {
      print('Error cambiando la prioridad global: $e');
    }
  }
}