import 'package:uuid/uuid.dart';

class CategoriaProducto {
  final String? id;
  final String nombre;
  final String? descripcion;
  final bool? activa;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CategoriaProducto({
    String? id,
    required this.nombre,
    this.descripcion,
    this.activa = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  // Crear desde un mapa (para convertir desde Supabase, SQLite o Turso)
  factory CategoriaProducto.fromMap(Map<String, dynamic> map) {
    return CategoriaProducto(
      id: map['id_categoria_producto']?.toString() ?? map['id']?.toString(),
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'],
      activa: map['activa'] is bool ? map['activa'] : map['activa'] == 1,
      createdAt: map['created_at'] != null 
          ? map['created_at'] is DateTime 
              ? map['created_at'] 
              : DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null 
          ? map['updated_at'] is DateTime 
              ? map['updated_at'] 
              : DateTime.parse(map['updated_at'].toString())
          : null,
    );
  }

  // Convertir a un mapa (para enviar a Supabase, SQLite o Turso)
  Map<String, dynamic> toMap({bool forLocal = false}) {
    final map = {
      'id_categoria_producto': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'activa': activa,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };

    // Eliminar valores nulos para Supabase
    if (!forLocal) {
      map.removeWhere((key, value) => value == null);
    }
    
    return map;
  }

  // Crear una copia con algunos campos modificados
  CategoriaProducto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    bool? activa,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoriaProducto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activa: activa ?? this.activa,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}