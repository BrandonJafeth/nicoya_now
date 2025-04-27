import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nicoya_now/services/data/data_source.dart';

/// Implementación de la fuente de datos remota usando Turso
class TursoDataSource<T> implements DataSource<T> {
  final String _url;
  final String _authToken;
  final String _tableName;
  final T Function(Map<String, dynamic>) _fromMap;
  final Map<String, dynamic> Function(T) _toMap;
  final String _idField;

  TursoDataSource({
    required String url,
    required String authToken,
    required String tableName,
    required T Function(Map<String, dynamic>) fromMap,
    required Map<String, dynamic> Function(T) toMap,
    String idField = 'id',
  })  : _url = url,
        _authToken = authToken,
        _tableName = tableName,
        _fromMap = fromMap,
        _toMap = toMap,
        _idField = idField;

  /// Ejecuta una consulta SQL en Turso
  Future<Map<String, dynamic>> _executeQuery(String sql, [List<dynamic>? params]) async {
    final response = await http.post(
      Uri.parse('$_url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
      body: jsonEncode({
        'statements': [
          {
            'q': sql,
            'params': params ?? [],
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error en la consulta Turso: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  @override
  Future<T?> create(T entity) async {
    try {
      final data = _toMap(entity);
      final columns = data.keys.join(', ');
      final placeholders = List.filled(data.keys.length, '?').join(', ');
      final values = data.values.toList();

      final sql = 'INSERT INTO $_tableName ($columns) VALUES ($placeholders) RETURNING *';
      
      final result = await _executeQuery(sql, values);
      
      final rows = result['results'][0]['rows'];
      if (rows != null && rows.isNotEmpty) {
        // Convertir el resultado a un mapa de cadenas a dinámicos
        final Map<String, dynamic> entityMap = {};
        final cols = result['results'][0]['columns'];
        for (int i = 0; i < cols.length; i++) {
          entityMap[cols[i]] = rows[0][i];
        }
        
        return _fromMap(entityMap);
      }
      
      return null;
    } catch (e) {
      print('Error creando entidad en Turso $_tableName: $e');
      return null;
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final sql = 'DELETE FROM $_tableName WHERE $_idField = ?';
      await _executeQuery(sql, [id]);
      return true;
    } catch (e) {
      print('Error eliminando entidad de Turso $_tableName: $e');
      return false;
    }
  }

  @override
  Future<List<T>> getAll() async {
    try {
      final sql = 'SELECT * FROM $_tableName';
      final result = await _executeQuery(sql);
      
      final rows = result['results'][0]['rows'];
      final cols = result['results'][0]['columns'];
      
      if (rows == null || rows.isEmpty) {
        return [];
      }
      
      // Convertir los resultados a mapas de cadenas a dinámicos
      final List<Map<String, dynamic>> entityMaps = [];
      for (final row in rows) {
        final Map<String, dynamic> entityMap = {};
        for (int i = 0; i < cols.length; i++) {
          entityMap[cols[i]] = row[i];
        }
        entityMaps.add(entityMap);
      }
      
      return entityMaps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      print('Error obteniendo todas las entidades de Turso $_tableName: $e');
      return [];
    }
  }

  @override
  Future<T?> getById(String id) async {
    try {
      final sql = 'SELECT * FROM $_tableName WHERE $_idField = ? LIMIT 1';
      final result = await _executeQuery(sql, [id]);
      
      final rows = result['results'][0]['rows'];
      final cols = result['results'][0]['columns'];
      
      if (rows == null || rows.isEmpty) {
        return null;
      }
      
      // Convertir el resultado a un mapa de cadenas a dinámicos
      final Map<String, dynamic> entityMap = {};
      for (int i = 0; i < cols.length; i++) {
        entityMap[cols[i]] = rows[0][i];
      }
      
      return _fromMap(entityMap);
    } catch (e) {
      print('Error obteniendo entidad de Turso $_tableName por ID: $e');
      return null;
    }
  }

  @override
  Future<bool> update(T entity) async {
    try {
      final data = _toMap(entity);
      final id = data[_idField];
      
      if (id == null) {
        print('Error: ID es null en la operación de actualización Turso');
        return false;
      }
      
      // Eliminar el id del mapa para la actualización
      data.remove(_idField);
      
      // Construir la consulta SQL para actualizar
      final setClause = data.keys.map((key) => '$key = ?').join(', ');
      final values = [...data.values, id]; // Agregar el ID al final para la cláusula WHERE
      
      final sql = 'UPDATE $_tableName SET $setClause WHERE $_idField = ?';
      
      await _executeQuery(sql, values);
      return true;
    } catch (e) {
      print('Error actualizando entidad en Turso $_tableName: $e');
      return false;
    }
  }
  
  /// Método adicional para obtener entidades con filtros personalizados
  Future<List<T>> getWhere(String field, dynamic value) async {
    try {
      final sql = 'SELECT * FROM $_tableName WHERE $field = ?';
      final result = await _executeQuery(sql, [value]);
      
      final rows = result['results'][0]['rows'];
      final cols = result['results'][0]['columns'];
      
      if (rows == null || rows.isEmpty) {
        return [];
      }
      
      // Convertir los resultados a mapas de cadenas a dinámicos
      final List<Map<String, dynamic>> entityMaps = [];
      for (final row in rows) {
        final Map<String, dynamic> entityMap = {};
        for (int i = 0; i < cols.length; i++) {
          entityMap[cols[i]] = row[i];
        }
        entityMaps.add(entityMap);
      }
      
      return entityMaps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      print('Error obteniendo entidades de Turso $_tableName con filtro: $e');
      return [];
    }
  }
}