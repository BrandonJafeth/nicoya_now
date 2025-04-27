/// Interfaz base para todas las fuentes de datos
abstract class DataSource<T> {
  /// Obtener una entidad por su ID
  Future<T?> getById(String id);
  
  /// Obtener todas las entidades
  Future<List<T>> getAll();
  
  /// Crear una nueva entidad
  Future<T?> create(T entity);
  
  /// Actualizar una entidad existente
  Future<bool> update(T entity);
  
  /// Eliminar una entidad
  Future<bool> delete(String id);
}