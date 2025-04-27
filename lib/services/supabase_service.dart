import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  late final SupabaseClient _client;
  static final SupabaseService _instance = SupabaseService._internal();

  // Singleton pattern
  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  // Método general para obtener todos los registros de una tabla
  Future<List<Map<String, dynamic>>> getAll(String tableName) async {
    try {
      final response = await _client.from(tableName).select();
      return response;
    } catch (e) {
      print('Error al obtener datos de $tableName: $e');
      return [];
    }
  }

  // Método para obtener un registro por ID
  Future<Map<String, dynamic>?> getById(String tableName, String id, {String idColumnName = 'id'}) async {
    try {
      final response = await _client
          .from(tableName)
          .select()
          .eq(idColumnName, id)
          .single();
      return response;
    } catch (e) {
      print('Error al obtener registro $id de $tableName: $e');
      return null;
    }
  }

  // Método para insertar un nuevo registro
  Future<Map<String, dynamic>?> insert(String tableName, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(tableName)
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error al insertar en $tableName: $e');
      return null;
    }
  }

  // Método para actualizar un registro
  Future<Map<String, dynamic>?> update(
    String tableName,
    String id,
    Map<String, dynamic> data, {
    String idColumnName = 'id',
  }) async {
    try {
      final response = await _client
          .from(tableName)
          .update(data)
          .eq(idColumnName, id)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error al actualizar registro $id en $tableName: $e');
      return null;
    }
  }

  // Método para eliminar un registro
  Future<bool> delete(String tableName, String id, {String idColumnName = 'id'}) async {
    try {
      await _client.from(tableName).delete().eq(idColumnName, id);
      return true;
    } catch (e) {
      print('Error al eliminar registro $id de $tableName: $e');
      return false;
    }
  }

  // Método para obtener registros con filtro
  Future<List<Map<String, dynamic>>> getWithFilter(
    String tableName,
    String column,
    dynamic value,
  ) async {
    try {
      final response = await _client
          .from(tableName)
          .select()
          .eq(column, value);
      return response;
    } catch (e) {
      print('Error al obtener datos filtrados de $tableName: $e');
      return [];
    }
  }

  // Método para buscar texto
  Future<List<Map<String, dynamic>>> search(
    String tableName,
    String column,
    String query,
  ) async {
    try {
      final response = await _client
          .from(tableName)
          .select()
          .ilike(column, '%$query%');
      return response;
    } catch (e) {
      print('Error al buscar en $tableName: $e');
      return [];
    }
  }
}