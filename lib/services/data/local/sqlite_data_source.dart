import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:nicoya_now/services/data/data_source.dart';

/// Implementación de la fuente de datos local usando SQLite
class SQLiteDataSource<T> implements DataSource<T> {
  final Database _db;
  final String _tableName;
  final T Function(Map<String, dynamic>) _fromMap;
  final Map<String, dynamic> Function(T, {bool forLocal}) _toMap;
  final String _idField;

  SQLiteDataSource({
    required Database db,
    required String tableName,
    required T Function(Map<String, dynamic>) fromMap,
    required Map<String, dynamic> Function(T, {bool forLocal}) toMap,
    String idField = 'id',
  })  : _db = db,
        _tableName = tableName,
        _fromMap = fromMap,
        _toMap = toMap,
        _idField = idField;

  @override
  Future<T?> create(T entity) async {
    try {
      final data = _toMap(entity, forLocal: true);
      final id = await _db.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Si la inserción fue exitosa y tenemos un ID
      if (id > 0) {
        // Recuperar la entidad recién creada para devolverla
        final createdEntity = await _db.query(
          _tableName,
          where: '$_idField = ?',
          whereArgs: [data[_idField] ?? id],
          limit: 1,
        );
        
        if (createdEntity.isNotEmpty) {
          return _fromMap(createdEntity.first);
        }
      }
      
      return null;
    } catch (e) {
      print('Error creando entidad en SQLite $_tableName: $e');
      return null;
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final count = await _db.delete(
        _tableName,
        where: '$_idField = ?',
        whereArgs: [id],
      );
      
      return count > 0;
    } catch (e) {
      print('Error eliminando entidad de SQLite $_tableName: $e');
      return false;
    }
  }

  @override
  Future<List<T>> getAll() async {
    try {
      final results = await _db.query(_tableName);
      return results.map((item) => _fromMap(item)).toList();
    } catch (e) {
      print('Error obteniendo todas las entidades de SQLite $_tableName: $e');
      return [];
    }
  }

  @override
  Future<T?> getById(String id) async {
    try {
      final results = await _db.query(
        _tableName,
        where: '$_idField = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        return _fromMap(results.first);
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo entidad de SQLite $_tableName por ID: $e');
      return null;
    }
  }

  @override
  Future<bool> update(T entity) async {
    try {
      final data = _toMap(entity, forLocal: true);
      final id = data[_idField];
      
      if (id == null) {
        print('Error: ID es null en la operación de actualización SQLite');
        return false;
      }
      
      final count = await _db.update(
        _tableName,
        data,
        where: '$_idField = ?',
        whereArgs: [id],
      );
      
      return count > 0;
    } catch (e) {
      print('Error actualizando entidad en SQLite $_tableName: $e');
      return false;
    }
  }
  
  /// Método adicional para obtener entidades con filtros personalizados
  Future<List<T>> getWhere(String field, dynamic value) async {
    try {
      final results = await _db.query(
        _tableName,
        where: '$field = ?',
        whereArgs: [value],
      );
      
      return results.map((item) => _fromMap(item)).toList();
    } catch (e) {
      print('Error obteniendo entidades de SQLite $_tableName con filtro: $e');
      return [];
    }
  }
  
  /// Método para borrar todos los datos de la tabla
  Future<void> clearTable() async {
    try {
      await _db.delete(_tableName);
    } catch (e) {
      print('Error al limpiar la tabla SQLite $_tableName: $e');
    }
  }
}