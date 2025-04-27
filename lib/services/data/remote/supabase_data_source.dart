import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nicoya_now/services/data/data_source.dart';

/// Implementación de la fuente de datos remota usando Supabase
class SupabaseDataSource<T> implements DataSource<T> {
  final SupabaseClient _client;
  final String _tableName;
  final T Function(Map<String, dynamic>) _fromMap;
  final Map<String, dynamic> Function(T) _toMap;
  final String _idField;

  SupabaseDataSource({
    required SupabaseClient client,
    required String tableName,
    required T Function(Map<String, dynamic>) fromMap,
    required Map<String, dynamic> Function(T) toMap,
    String idField = 'id',
  })  : _client = client,
        _tableName = tableName,
        _fromMap = fromMap,
        _toMap = toMap,
        _idField = idField;

  @override
  Future<T?> create(T entity) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert(_toMap(entity))
          .select()
          .single();
      
      return _fromMap(response);
    } catch (e) {
      print('Error creando entidad en $_tableName: $e');
      return null;
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq(_idField, id);
      
      return true;
    } catch (e) {
      print('Error eliminando entidad de $_tableName: $e');
      return false;
    }
  }

  @override
  Future<List<T>> getAll() async {
    try {
      final response = await _client
          .from(_tableName)
          .select();
      
      return response.map((item) => _fromMap(item)).toList();
    } catch (e) {
      print('Error obteniendo todas las entidades de $_tableName: $e');
      return [];
    }
  }

  @override
  Future<T?> getById(String id) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq(_idField, id)
          .single();
      
      return _fromMap(response);
    } catch (e) {
      print('Error obteniendo entidad de $_tableName por ID: $e');
      return null;
    }
  }

  @override
  Future<bool> update(T entity) async {
    try {
      final Map<String, dynamic> data = _toMap(entity);
      final id = data[_idField];
      
      if (id == null) {
        print('Error: ID es null en la operación de actualización');
        return false;
      }
      
      // Eliminar el id del mapa para la actualización
      data.remove(_idField);
      
      await _client
          .from(_tableName)
          .update(data)
          .eq(_idField, id);
      
      return true;
    } catch (e) {
      print('Error actualizando entidad en $_tableName: $e');
      return false;
    }
  }
  
  /// Método adicional para obtener entidades con filtros personalizados
  Future<List<T>> getWhere(String field, dynamic value) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq(field, value);
      
      return response.map((item) => _fromMap(item)).toList();
    } catch (e) {
      print('Error obteniendo entidades de $_tableName con filtro: $e');
      return [];
    }
  }
  
  /// Método para escuchar cambios en tiempo real
  Stream<List<T>> subscribe() {
    return _client
        .from(_tableName)
        .stream(primaryKey: [_idField])
        .map((data) => data.map((item) => _fromMap(item)).toList());
  }
}