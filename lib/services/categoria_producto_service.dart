import 'package:nicoya_now/models/categoria_producto.dart';
import 'package:nicoya_now/services/data/data_manager.dart';
import 'package:nicoya_now/services/repositories/multi_source_repository.dart';

class CategoriaProductoService {
  final MultiSourceRepository<CategoriaProducto> _repository;
  
  CategoriaProductoService({MultiSourceRepository<CategoriaProducto>? repository}) 
      : _repository = repository ?? DataManager.instance.categoriaProductoRepository;
  
  /// Obtener todas las categorías de productos
  Future<List<CategoriaProducto>> getCategorias({DataSourcePriority? priority}) async {
    return await _repository.getAll(priority: priority);
  }
  
  /// Obtener una categoría por su ID
  Future<CategoriaProducto?> getCategoriaById(String id, {DataSourcePriority? priority}) async {
    return await _repository.getById(id, priority: priority);
  }
  
  /// Crear una nueva categoría
  Future<CategoriaProducto?> createCategoria(CategoriaProducto categoria, {DataSourcePriority? priority}) async {
    return await _repository.create(categoria, priority: priority);
  }
  
  /// Actualizar una categoría existente
  Future<bool> updateCategoria(CategoriaProducto categoria, {DataSourcePriority? priority}) async {
    return await _repository.update(categoria, priority: priority);
  }
  
  /// Eliminar una categoría
  Future<bool> deleteCategoria(String id, {DataSourcePriority? priority}) async {
    return await _repository.delete(id, priority: priority);
  }
  
  /// Suscribirse a los cambios en las categorías
  Stream<List<CategoriaProducto>> get categoriasStream => _repository.entities;
  
  /// Cambiar la prioridad predeterminada para este tipo de entidad
  Future<void> setDataSourcePriority(DataSourcePriority priority) async {
    await _repository.setDataSourcePriority(priority);
  }
  
  /// Forzar una sincronización con las fuentes remotas
  Future<void> syncWithRemote() async {
    await _repository.syncWithRemote();
  }
}