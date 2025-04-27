import 'package:uuid/uuid.dart';

class Establishment {
  final String? id;
  final String name;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final bool? active;
  final String? schedule;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Establishment({
    String? id,
    required this.name,
    this.description,
    this.address,
    this.phoneNumber,
    this.email,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.active = true,
    this.schedule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  // Crear desde un mapa
  factory Establishment.fromMap(Map<String, dynamic> map) {
    return Establishment(
      id: map['id_establishment']?.toString() ?? map['id']?.toString(),
      name: map['name'] ?? '',
      description: map['description'],
      address: map['address'],
      phoneNumber: map['phone_number'],
      email: map['email'],
      latitude: map['latitude'] is int 
          ? (map['latitude'] as int).toDouble()
          : map['latitude'] is String 
              ? double.tryParse(map['latitude'])
              : map['latitude'],
      longitude: map['longitude'] is int 
          ? (map['longitude'] as int).toDouble()
          : map['longitude'] is String 
              ? double.tryParse(map['longitude'])
              : map['longitude'],
      imageUrl: map['image_url'],
      active: map['active'] is bool ? map['active'] : map['active'] == 1,
      schedule: map['schedule'],
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

  // Convertir a un mapa
  Map<String, dynamic> toMap({bool forLocal = false}) {
    final map = {
      'id_establishment': id,
      'name': name,
      'description': description,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'active': active,
      'schedule': schedule,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };

    if (!forLocal) {
      map.removeWhere((key, value) => value == null);
    }
    
    return map;
  }

  // Crear una copia con cambios
  Establishment copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    String? email,
    double? latitude,
    double? longitude,
    String? imageUrl,
    bool? active,
    String? schedule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Establishment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      active: active ?? this.active,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}