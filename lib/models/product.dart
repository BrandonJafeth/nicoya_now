import 'package:uuid/uuid.dart';

class Product {
  final String? id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool? available;
  final String? categoryId;
  final String? establishmentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Product({
    String? id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.available = true,
    this.categoryId,
    this.establishmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  // Crear desde un mapa
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id_product']?.toString() ?? map['id']?.toString(),
      name: map['name'] ?? '',
      description: map['description'],
      price: map['price'] is int 
          ? (map['price'] as int).toDouble()
          : map['price'] is String 
              ? double.tryParse(map['price']) ?? 0.0
              : map['price'] ?? 0.0,
      imageUrl: map['image_url'],
      available: map['available'] is bool ? map['available'] : map['available'] == 1,
      categoryId: map['category_id']?.toString() ?? map['id_category']?.toString(),
      establishmentId: map['establishment_id']?.toString() ?? map['id_establishment']?.toString(),
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
      'id_product': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'available': available,
      'category_id': categoryId,
      'establishment_id': establishmentId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };

    if (!forLocal) {
      map.removeWhere((key, value) => value == null);
    }
    
    return map;
  }

  // Crear una copia con cambios
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? available,
    String? categoryId,
    String? establishmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      categoryId: categoryId ?? this.categoryId,
      establishmentId: establishmentId ?? this.establishmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}