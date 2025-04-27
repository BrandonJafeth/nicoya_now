import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nicoya_now/models/establishment.dart';
import 'package:nicoya_now/services/data/local/sqlite_data_source.dart';
import 'package:nicoya_now/services/data/remote/supabase_data_source.dart';
import 'package:rxdart/rxdart.dart';

/// Repositorio híbrido para establecimientos que combina datos locales y remotos
class EstablishmentRepository {
  final SupabaseDataSource<Establishment> _remoteDataSource;
  final SQLiteDataSource<Establishment> _localDataSource;
  
  final BehaviorSubject<List<Establishment>> _establishmentsSubject = BehaviorSubject<List<Establishment>>();
  
  EstablishmentRepository({
    required SupabaseDataSource<Establishment> remoteDataSource,
    required SQLiteDataSource<Establishment> localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;
  
  /// Stream de establecimientos para escuchar cambios
  Stream<List<Establishment>> get establishments => _establishmentsSubject.stream;
  
  /// Método para inicializar el repositorio y sincronizar datos
  Future<void> initialize() async {
    // Cargar primero los datos locales para mostrar algo rápidamente
    final localEstablishments = await _localDataSource.getAll();
    _establishmentsSubject.add(localEstablishments);
    
    // Intentar sincronizar con datos remotos si hay conectividad
    await syncWithRemote();
    
    // Suscribirse a cambios remotos en tiempo real
    _remoteDataSource.subscribe().listen((remoteEstablishments) async {
      // Actualizar la caché local
      await _updateLocalCache(remoteEstablishments);
      // Notificar a los oyentes
      _establishmentsSubject.add(remoteEstablishments);
    });
  }
  
  /// Sincronizar datos con la fuente remota
  Future<void> syncWithRemote() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('Sin conexión a Internet. Usando solo datos locales.');
        return;
      }
      
      final remoteEstablishments = await _remoteDataSource.getAll();
      
      // Actualizar la caché local
      await _updateLocalCache(remoteEstablishments);
      
      // Notificar a los oyentes sobre los nuevos datos
      _establishmentsSubject.add(remoteEstablishments);
    } catch (e) {
      print('Error sincronizando con datos remotos: $e');
    }
  }
  
  /// Actualizar la caché local con los datos remotos
  Future<void> _updateLocalCache(List<Establishment> remoteEstablishments) async {
    try {
      // Limpiar la tabla local y volver a insertar todos los datos
      await _localDataSource.clearTable();
      
      for (final establishment in remoteEstablishments) {
        await _localDataSource.create(establishment);
      }
    } catch (e) {
      print('Error actualizando caché local: $e');
    }
  }
  
  /// Obtener todos los establecimientos
  Future<List<Establishment>> getAll() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        // Sin conexión, usar solo datos locales
        return await _localDataSource.getAll();
      } else {
        // Con conexión, intentar obtener datos remotos y sincronizar
        try {
          final remoteEstablishments = await _remoteDataSource.getAll();
          await _updateLocalCache(remoteEstablishments);
          return remoteEstablishments;
        } catch (e) {
          print('Error obteniendo datos remotos: $e');
          // Si falla, usar datos locales como respaldo
          return await _localDataSource.getAll();
        }
      }
    } catch (e) {
      print('Error en getAll: $e');
      return [];
    }
  }
  
  /// Obtener un establecimiento por ID
  Future<Establishment?> getById(String id) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        // Sin conexión, usar solo datos locales
        return await _localDataSource.getById(id);
      } else {
        // Con conexión, intentar obtener datos remotos
        try {
          final remoteEstablishment = await _remoteDataSource.getById(id);
          
          if (remoteEstablishment != null) {
            // Actualizar la versión local
            await _localDataSource.update(remoteEstablishment);
            return remoteEstablishment;
          }
        } catch (e) {
          print('Error obteniendo datos remotos del establecimiento $id: $e');
        }
        
        // Si falla o no hay datos remotos, usar datos locales como respaldo
        return await _localDataSource.getById(id);
      }
    } catch (e) {
      print('Error en getById: $e');
      return null;
    }
  }
  
  /// Crear un nuevo establecimiento
  Future<Establishment?> create(Establishment establishment) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        // Sin conexión, guardar solo localmente por ahora
        final localEstablishment = await _localDataSource.create(establishment);
        
        if (localEstablishment != null) {
          // Actualizar el stream
          final currentList = _establishmentsSubject.valueOrNull ?? [];
          _establishmentsSubject.add([...currentList, localEstablishment]);
        }
        
        return localEstablishment;
      } else {
        // Con conexión, guardar remotamente primero
        final remoteEstablishment = await _remoteDataSource.create(establishment);
        
        if (remoteEstablishment != null) {
          // Guardar localmente también
          await _localDataSource.create(remoteEstablishment);
          
          // No necesitamos actualizar el stream porque la suscripción remota lo hará
        }
        
        return remoteEstablishment;
      }
    } catch (e) {
      print('Error en create: $e');
      return null;
    }
  }
  
  /// Actualizar un establecimiento existente
  Future<bool> update(Establishment establishment) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        // Sin conexión, actualizar solo localmente por ahora
        final success = await _localDataSource.update(establishment);
        
        if (success) {
          // Actualizar el stream manualmente
          final currentList = _establishmentsSubject.valueOrNull ?? [];
          final index = currentList.indexWhere((e) => e.id == establishment.id);
          
          if (index >= 0) {
            currentList[index] = establishment;
            _establishmentsSubject.add([...currentList]);
          }
        }
        
        return success;
      } else {
        // Con conexión, actualizar remotamente primero
        final success = await _remoteDataSource.update(establishment);
        
        if (success) {
          // Actualizar localmente también
          await _localDataSource.update(establishment);
          
          // No necesitamos actualizar el stream porque la suscripción remota lo hará
        }
        
        return success;
      }
    } catch (e) {
      print('Error en update: $e');
      return false;
    }
  }
  
  /// Eliminar un establecimiento
  Future<bool> delete(String id) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        // Sin conexión, eliminar solo localmente por ahora
        final success = await _localDataSource.delete(id);
        
        if (success) {
          // Actualizar el stream manualmente
          final currentList = _establishmentsSubject.valueOrNull ?? [];
          _establishmentsSubject.add(currentList.where((e) => e.id != id).toList());
        }
        
        return success;
      } else {
        // Con conexión, eliminar remotamente primero
        final success = await _remoteDataSource.delete(id);
        
        if (success) {
          // Eliminar localmente también
          await _localDataSource.delete(id);
          
          // No necesitamos actualizar el stream porque la suscripción remota lo hará
        }
        
        return success;
      }
    } catch (e) {
      print('Error en delete: $e');
      return false;
    }
  }
  
  void dispose() {
    _establishmentsSubject.close();
  }
}