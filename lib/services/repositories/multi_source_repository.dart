import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nicoya_now/services/data/data_source.dart';
import 'package:nicoya_now/services/data/local/sqlite_data_source.dart';
import 'package:nicoya_now/services/data/remote/supabase_data_source.dart';
import 'package:nicoya_now/services/data/remote/turso_data_source.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DataSourcePriority {
  local,  // SQLite primero
  remote, // Supabase primero
  turso,  // Turso primero
  all     // Intentar todos en orden: remoto, turso, local
}

/// Repositorio que integra múltiples fuentes de datos (Supabase, SQLite, Turso)
class MultiSourceRepository<T> {
  final SupabaseDataSource<T>? _supabaseDataSource;
  final SQLiteDataSource<T> _sqliteDataSource;
  final TursoDataSource<T>? _tursoDataSource;
  final String _entityName;
  
  final BehaviorSubject<List<T>> _entitiesSubject = BehaviorSubject<List<T>>();
  
  // Preferencia de origen de datos por defecto
  DataSourcePriority _defaultPriority = DataSourcePriority.remote;

  MultiSourceRepository({
    SupabaseDataSource<T>? supabaseDataSource,
    required SQLiteDataSource<T> sqliteDataSource,
    TursoDataSource<T>? tursoDataSource,
    required String entityName,
    DataSourcePriority defaultPriority = DataSourcePriority.remote,
  })  : _supabaseDataSource = supabaseDataSource,
        _sqliteDataSource = sqliteDataSource,
        _tursoDataSource = tursoDataSource,
        _entityName = entityName,
        _defaultPriority = defaultPriority;
  
  /// Stream de entidades para escuchar cambios
  Stream<List<T>> get entities => _entitiesSubject.stream;
  
  /// Método para inicializar el repositorio y sincronizar datos
  Future<void> initialize() async {
    // Cargar la prioridad guardada en preferencias
    await _loadSavedPriority();
    
    // Cargar primero los datos locales para mostrar algo rápidamente
    final localEntities = await _sqliteDataSource.getAll();
    _entitiesSubject.add(localEntities);
    
    // Intentar sincronizar con datos remotos según la prioridad
    await syncWithRemote();
    
    // Configurar suscripción a cambios remotos si existe Supabase
    if (_supabaseDataSource != null) {
      _supabaseDataSource!.subscribe().listen((remoteEntities) async {
        // Actualizar la caché local
        await _updateLocalCache(remoteEntities);
        // Notificar a los oyentes
        _entitiesSubject.add(remoteEntities);
      });
    }
  }
  
  /// Cargar la prioridad guardada en preferencias
  Future<void> _loadSavedPriority() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final priorityIndex = prefs.getInt('datasource_priority_$_entityName');
      if (priorityIndex != null) {
        _defaultPriority = DataSourcePriority.values[priorityIndex];
      }
    } catch (e) {
      print('Error cargando preferencia de prioridad: $e');
    }
  }
  
  /// Guardar la prioridad en preferencias
  Future<void> _savePriority(DataSourcePriority priority) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('datasource_priority_$_entityName', priority.index);
      _defaultPriority = priority;
    } catch (e) {
      print('Error guardando preferencia de prioridad: $e');
    }
  }
  
  /// Cambiar la prioridad de las fuentes de datos
  Future<void> setDataSourcePriority(DataSourcePriority priority) async {
    await _savePriority(priority);
    // Recargar datos según la nueva prioridad
    await syncWithRemote();
  }
  
  /// Sincronizar datos con fuentes remotas
  Future<void> syncWithRemote() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('Sin conexión a Internet. Usando solo datos locales.');
        return;
      }
      
      List<T>? entities;
      
      // Intentar obtener datos según la prioridad configurada
      switch (_defaultPriority) {
        case DataSourcePriority.remote:
          if (_supabaseDataSource != null) {
            entities = await _supabaseDataSource!.getAll();
          } else if (_tursoDataSource != null) {
            entities = await _tursoDataSource!.getAll();
          }
          break;
        
        case DataSourcePriority.turso:
          if (_tursoDataSource != null) {
            entities = await _tursoDataSource!.getAll();
          } else if (_supabaseDataSource != null) {
            entities = await _supabaseDataSource!.getAll();
          }
          break;
          
        case DataSourcePriority.local:
          // Ya hemos cargado los datos locales, solo regresar
          return;
          
        case DataSourcePriority.all:
          // Intentar todas las fuentes en orden
          if (_supabaseDataSource != null) {
            entities = await _supabaseDataSource!.getAll();
          }
          
          if ((entities == null || entities.isEmpty) && _tursoDataSource != null) {
            entities = await _tursoDataSource!.getAll();
          }
          
          if (entities == null || entities.isEmpty) {
            entities = await _sqliteDataSource.getAll();
          }
          break;
      }
      
      if (entities != null && entities.isNotEmpty) {
        // Actualizar la caché local
        await _updateLocalCache(entities);
        
        // Notificar a los oyentes sobre los nuevos datos
        _entitiesSubject.add(entities);
      }
    } catch (e) {
      print('Error sincronizando con datos remotos: $e');
    }
  }
  
  /// Actualizar la caché local con los datos remotos
  Future<void> _updateLocalCache(List<T> entities) async {
    try {
      // Limpiar la tabla local y volver a insertar todos los datos
      await _sqliteDataSource.clearTable();
      
      for (final entity in entities) {
        await _sqliteDataSource.create(entity);
      }
    } catch (e) {
      print('Error actualizando caché local: $e');
    }
  }
  
  /// Obtener todas las entidades
  Future<List<T>> getAll({DataSourcePriority? priority}) async {
    final effectivePriority = priority ?? _defaultPriority;
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none || effectivePriority == DataSourcePriority.local) {
        // Sin conexión o prioridad local explícita, usar solo datos locales
        return await _sqliteDataSource.getAll();
      } else {
        // Con conexión, intentar obtener datos remotos según la prioridad
        try {
          List<T>? entities;
          
          switch (effectivePriority) {
            case DataSourcePriority.remote:
              if (_supabaseDataSource != null) {
                entities = await _supabaseDataSource!.getAll();
              } else if (_tursoDataSource != null) {
                entities = await _tursoDataSource!.getAll();
              }
              break;
              
            case DataSourcePriority.turso:
              if (_tursoDataSource != null) {
                entities = await _tursoDataSource!.getAll();
              } else if (_supabaseDataSource != null) {
                entities = await _supabaseDataSource!.getAll();
              }
              break;
              
            case DataSourcePriority.all:
              // Intentar todas las fuentes en orden
              if (_supabaseDataSource != null) {
                entities = await _supabaseDataSource!.getAll();
              }
              
              if ((entities == null || entities.isEmpty) && _tursoDataSource != null) {
                entities = await _tursoDataSource!.getAll();
              }
              
              if (entities == null || entities.isEmpty) {
                entities = await _sqliteDataSource.getAll();
              }
              break;
              
            default:
              entities = await _sqliteDataSource.getAll();
          }
          
          if (entities != null && entities.isNotEmpty) {
            await _updateLocalCache(entities);
            return entities;
          }
        } catch (e) {
          print('Error obteniendo datos remotos: $e');
        }
        
        // Si falla, usar datos locales como respaldo
        return await _sqliteDataSource.getAll();
      }
    } catch (e) {
      print('Error en getAll: $e');
      return [];
    }
  }
  
  /// Obtener una entidad por ID
  Future<T?> getById(String id, {DataSourcePriority? priority}) async {
    final effectivePriority = priority ?? _defaultPriority;
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none || effectivePriority == DataSourcePriority.local) {
        // Sin conexión o prioridad local explícita, usar solo datos locales
        return await _sqliteDataSource.getById(id);
      } else {
        // Con conexión, intentar obtener datos remotos según la prioridad
        DataSource<T>? primarySource;
        DataSource<T>? secondarySource;
        
        switch (effectivePriority) {
          case DataSourcePriority.remote:
            primarySource = _supabaseDataSource;
            secondarySource = _tursoDataSource;
            break;
          case DataSourcePriority.turso:
            primarySource = _tursoDataSource;
            secondarySource = _supabaseDataSource;
            break;
          case DataSourcePriority.all:
            // Manejar casos "all" en la lógica siguiente
            break;
          default:
            primarySource = null;
        }
        
        if (effectivePriority == DataSourcePriority.all) {
          // Intentar todas las fuentes en orden para "all"
          if (_supabaseDataSource != null) {
            try {
              final entity = await _supabaseDataSource!.getById(id);
              if (entity != null) {
                await _sqliteDataSource.update(entity);
                return entity;
              }
            } catch (e) {
              print('Error obteniendo de Supabase: $e');
            }
          }
          
          if (_tursoDataSource != null) {
            try {
              final entity = await _tursoDataSource!.getById(id);
              if (entity != null) {
                await _sqliteDataSource.update(entity);
                return entity;
              }
            } catch (e) {
              print('Error obteniendo de Turso: $e');
            }
          }
          
          // Si nada funciona, usar local
          return await _sqliteDataSource.getById(id);
        } else if (primarySource != null) {
          // Usar la fuente primaria según la prioridad
          try {
            final entity = await primarySource.getById(id);
            if (entity != null) {
              await _sqliteDataSource.update(entity);
              return entity;
            }
          } catch (e) {
            print('Error obteniendo de fuente primaria: $e');
          }
          
          // Si la primaria falla, intentar la secundaria
          if (secondarySource != null) {
            try {
              final entity = await secondarySource.getById(id);
              if (entity != null) {
                await _sqliteDataSource.update(entity);
                return entity;
              }
            } catch (e) {
              print('Error obteniendo de fuente secundaria: $e');
            }
          }
        }
        
        // Si todo falla, usar local
        return await _sqliteDataSource.getById(id);
      }
    } catch (e) {
      print('Error en getById: $e');
      return null;
    }
  }
  
  /// Crear una nueva entidad
  Future<T?> create(T entity, {DataSourcePriority? priority}) async {
    final effectivePriority = priority ?? _defaultPriority;
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        // Sin conexión, guardar solo localmente por ahora
        final localEntity = await _sqliteDataSource.create(entity);
        
        if (localEntity != null) {
          // Actualizar el stream
          final currentList = _entitiesSubject.valueOrNull ?? [];
          _entitiesSubject.add([...currentList, localEntity]);
        }
        
        return localEntity;
      } else {
        T? resultEntity;
        bool remoteSaved = false;
        
        // Con conexión, guardar según la prioridad
        if (effectivePriority == DataSourcePriority.remote || effectivePriority == DataSourcePriority.all) {
          if (_supabaseDataSource != null) {
            try {
              resultEntity = await _supabaseDataSource!.create(entity);
              remoteSaved = resultEntity != null;
            } catch (e) {
              print('Error creando en Supabase: $e');
            }
          }
        }
        
        if (!remoteSaved && (effectivePriority == DataSourcePriority.turso || effectivePriority == DataSourcePriority.all)) {
          if (_tursoDataSource != null) {
            try {
              resultEntity = await _tursoDataSource!.create(entity);
              remoteSaved = resultEntity != null;
            } catch (e) {
              print('Error creando en Turso: $e');
            }
          }
        }
        
        // Si no se pudo guardar remotamente o la prioridad es local
        if (!remoteSaved || effectivePriority == DataSourcePriority.local) {
          // Guardar localmente
          resultEntity = await _sqliteDataSource.create(resultEntity ?? entity);
          
          if (resultEntity != null) {
            // Actualizar el stream manualmente si no hubo éxito remoto
            if (!remoteSaved) {
              final currentList = _entitiesSubject.valueOrNull ?? [];
              _entitiesSubject.add([...currentList, resultEntity]);
            }
          }
        }
        
        return resultEntity;
      }
    } catch (e) {
      print('Error en create: $e');
      return null;
    }
  }
  
  /// Actualizar una entidad existente
  Future<bool> update(T entity, {DataSourcePriority? priority}) async {
    final effectivePriority = priority ?? _defaultPriority;
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        // Sin conexión, actualizar solo localmente por ahora
        final success = await _sqliteDataSource.update(entity);
        
        if (success) {
          // Actualizar el stream manualmente
          // Nota: Esto asume que T tiene un método para obtener el ID
          final currentList = _entitiesSubject.valueOrNull ?? [];
          _updateStreamWithEntity(currentList, entity);
        }
        
        return success;
      } else {
        bool success = false;
        
        // Con conexión, actualizar según la prioridad
        if (effectivePriority == DataSourcePriority.remote || effectivePriority == DataSourcePriority.all) {
          if (_supabaseDataSource != null) {
            try {
              success = await _supabaseDataSource!.update(entity);
            } catch (e) {
              print('Error actualizando en Supabase: $e');
            }
          }
        }
        
        if (!success && (effectivePriority == DataSourcePriority.turso || effectivePriority == DataSourcePriority.all)) {
          if (_tursoDataSource != null) {
            try {
              success = await _tursoDataSource!.update(entity);
            } catch (e) {
              print('Error actualizando en Turso: $e');
            }
          }
        }
        
        // Si no se pudo actualizar remotamente o la prioridad es local
        if (!success || effectivePriority == DataSourcePriority.local) {
          // Actualizar localmente
          success = await _sqliteDataSource.update(entity);
          
          if (success) {
            // Actualizar el stream manualmente si no hubo éxito remoto
            if (!success) {
              final currentList = _entitiesSubject.valueOrNull ?? [];
              _updateStreamWithEntity(currentList, entity);
            }
          }
        }
        
        return success;
      }
    } catch (e) {
      print('Error en update: $e');
      return false;
    }
  }
  
  // Método auxiliar para actualizar una entidad específica en el stream
  void _updateStreamWithEntity(List<T> currentList, T updatedEntity) {
    // Esta es una implementación genérica y puede necesitar ajustes según tu modelo específico
    // Asume que puedes comparar las entidades de alguna manera
    try {
      final dynamic id = (updatedEntity as dynamic).id;
      
      if (id != null) {
        final index = currentList.indexWhere((item) => (item as dynamic).id == id);
        
        if (index >= 0) {
          final newList = List<T>.from(currentList);
          newList[index] = updatedEntity;
          _entitiesSubject.add(newList);
        }
      }
    } catch (e) {
      print('Error actualizando stream: $e');
    }
  }
  
  /// Eliminar una entidad
  Future<bool> delete(String id, {DataSourcePriority? priority}) async {
    final effectivePriority = priority ?? _defaultPriority;
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        // Sin conexión, eliminar solo localmente por ahora
        final success = await _sqliteDataSource.delete(id);
        
        if (success) {
          // Actualizar el stream manualmente
          final currentList = _entitiesSubject.valueOrNull ?? [];
          _entitiesSubject.add(currentList.where((e) => (e as dynamic).id != id).toList());
        }
        
        return success;
      } else {
        bool success = false;
        
        // Con conexión, eliminar según la prioridad
        if (effectivePriority == DataSourcePriority.remote || effectivePriority == DataSourcePriority.all) {
          if (_supabaseDataSource != null) {
            try {
              success = await _supabaseDataSource!.delete(id);
            } catch (e) {
              print('Error eliminando en Supabase: $e');
            }
          }
        }
        
        if (!success && (effectivePriority == DataSourcePriority.turso || effectivePriority == DataSourcePriority.all)) {
          if (_tursoDataSource != null) {
            try {
              success = await _tursoDataSource!.delete(id);
            } catch (e) {
              print('Error eliminando en Turso: $e');
            }
          }
        }
        
        // Eliminar localmente siempre, independientemente del resultado remoto
        final localSuccess = await _sqliteDataSource.delete(id);
        
        // Si no se pudo eliminar remotamente, actualizar el stream manualmente
        if (!success && localSuccess) {
          final currentList = _entitiesSubject.valueOrNull ?? [];
          _entitiesSubject.add(currentList.where((e) => (e as dynamic).id != id).toList());
        }
        
        return success || localSuccess;
      }
    } catch (e) {
      print('Error en delete: $e');
      return false;
    }
  }
  
  /// Método adicional para obtener entidades con filtros personalizados
  Future<List<T>> getWhere(String field, dynamic value, {DataSourcePriority? priority}) async {
    final effectivePriority = priority ?? _defaultPriority;
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none || effectivePriority == DataSourcePriority.local) {
        // Sin conexión o prioridad local, usar solo datos locales
        return await _sqliteDataSource.getWhere(field, value);
      } else {
        // Con conexión, intentar obtener datos remotos según la prioridad
        try {
          List<T>? entities;
          
          switch (effectivePriority) {
            case DataSourcePriority.remote:
              if (_supabaseDataSource != null) {
                entities = await _supabaseDataSource!.getWhere(field, value);
              } else if (_tursoDataSource != null) {
                entities = await _tursoDataSource!.getWhere(field, value);
              }
              break;
              
            case DataSourcePriority.turso:
              if (_tursoDataSource != null) {
                entities = await _tursoDataSource!.getWhere(field, value);
              } else if (_supabaseDataSource != null) {
                entities = await _supabaseDataSource!.getWhere(field, value);
              }
              break;
              
            case DataSourcePriority.all:
              // Intentar todas las fuentes en orden
              if (_supabaseDataSource != null) {
                entities = await _supabaseDataSource!.getWhere(field, value);
              }
              
              if ((entities == null || entities.isEmpty) && _tursoDataSource != null) {
                entities = await _tursoDataSource!.getWhere(field, value);
              }
              
              if (entities == null || entities.isEmpty) {
                entities = await _sqliteDataSource.getWhere(field, value);
              }
              break;
              
            default:
              entities = await _sqliteDataSource.getWhere(field, value);
          }
          
          if (entities != null && entities.isNotEmpty) {
            return entities;
          }
        } catch (e) {
          print('Error obteniendo datos remotos con filtro: $e');
        }
        
        // Si falla, usar datos locales como respaldo
        return await _sqliteDataSource.getWhere(field, value);
      }
    } catch (e) {
      print('Error en getWhere: $e');
      return [];
    }
  }
  
  void dispose() {
    _entitiesSubject.close();
  }
}