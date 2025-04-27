import 'package:uuid/uuid.dart';
import 'package:nicoya_now/models/product.dart';

// Enumeración para el estado del pedido
enum OrderStatus {
  pending,
  preparing,
  readyForPickup,
  inDelivery,
  delivered,
  canceled,
}

// Clase para representar un elemento de orden
class OrderItem {
  final String? id;
  final String productId;
  final int quantity;
  final double unitPrice;
  final String? notes;
  final Product? product; // Para almacenar la relación

  OrderItem({
    String? id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.notes,
    this.product,
  }) : this.id = id ?? const Uuid().v4();

  // Obtener el precio total del elemento
  double get totalPrice => unitPrice * quantity;

  // Crear desde un mapa
  factory OrderItem.fromMap(Map<String, dynamic> map, List<Product> products) {
    final productId = map['product_id']?.toString() ?? '';
    
    // Buscar el producto relacionado en la lista de productos
    final product = products.firstWhere(
      (p) => p.id == productId, 
      orElse: () => Product(name: 'Desconocido', price: 0)
    );
    
    return OrderItem(
      id: map['id']?.toString(),
      productId: productId,
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unit_price'] is int) 
          ? (map['unit_price'] as int).toDouble() 
          : (map['unit_price'] is String)
              ? double.tryParse(map['unit_price']) ?? 0.0
              : map['unit_price'] ?? 0.0,
      notes: map['notes'],
      product: product,
    );
  }

  // Convertir a un mapa
  Map<String, dynamic> toMap({bool forLocal = false}) {
    final map = {
      if (id != null) 'id': id,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'notes': notes,
    };

    if (!forLocal) {
      map.removeWhere((key, value) => value == null);
    }
    
    return map;
  }

  // Crear una copia con cambios
  OrderItem copyWith({
    String? id,
    String? productId,
    int? quantity,
    double? unitPrice,
    String? notes,
    Product? product,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
      product: product ?? this.product,
    );
  }
}

// Clase principal para la orden
class Order {
  final String? id;
  final String? userId;
  final String? establishmentId;
  final List<OrderItem> items;
  final OrderStatus status;
  final double? deliveryFee;
  final double? tip;
  final String? deliveryAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? notes;

  Order({
    String? id,
    this.userId,
    this.establishmentId,
    List<OrderItem>? items,
    this.status = OrderStatus.pending,
    this.deliveryFee = 0.0,
    this.tip = 0.0,
    this.deliveryAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.notes,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.items = items ?? [],
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  // Obtener el subtotal (suma de los elementos)
  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  
  // Obtener el total (subtotal + envío + propina)
  double get total => subtotal + (deliveryFee ?? 0) + (tip ?? 0);

  // Crear desde un mapa
  factory Order.fromMap(Map<String, dynamic> map, List<Product> products) {
    // Convertir de string a enum
    OrderStatus parseStatus(dynamic status) {
      if (status is int) {
        return OrderStatus.values[status];
      } else if (status is String) {
        return OrderStatus.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == status.toLowerCase(),
          orElse: () => OrderStatus.pending
        );
      }
      return OrderStatus.pending;
    }

    return Order(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString(),
      establishmentId: map['establishment_id']?.toString(),
      items: map['items'] != null 
          ? (map['items'] as List)
              .map((item) => OrderItem.fromMap(item, products))
              .toList()
          : [],
      status: parseStatus(map['status']),
      deliveryFee: (map['delivery_fee'] is int) 
          ? (map['delivery_fee'] as int).toDouble() 
          : (map['delivery_fee'] is String)
              ? double.tryParse(map['delivery_fee']) ?? 0.0
              : map['delivery_fee'] ?? 0.0,
      tip: (map['tip'] is int) 
          ? (map['tip'] as int).toDouble() 
          : (map['tip'] is String)
              ? double.tryParse(map['tip']) ?? 0.0
              : map['tip'] ?? 0.0,
      deliveryAddress: map['delivery_address'],
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
      notes: map['notes'],
    );
  }

  // Convertir a un mapa
  Map<String, dynamic> toMap({bool forLocal = false}) {
    final map = {
      if (id != null) 'id': id,
      'user_id': userId,
      'establishment_id': establishmentId,
      'status': status.toString().split('.').last,
      'delivery_fee': deliveryFee,
      'tip': tip,
      'delivery_address': deliveryAddress,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'notes': notes,
      'total': total,
      'subtotal': subtotal,
    };

    if (!forLocal) {
      map.removeWhere((key, value) => value == null);
    }
    
    return map;
  }

  // Crear una copia con cambios
  Order copyWith({
    String? id,
    String? userId,
    String? establishmentId,
    List<OrderItem>? items,
    OrderStatus? status,
    double? deliveryFee,
    double? tip,
    String? deliveryAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      establishmentId: establishmentId ?? this.establishmentId,
      items: items ?? this.items,
      status: status ?? this.status,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tip: tip ?? this.tip,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }
}