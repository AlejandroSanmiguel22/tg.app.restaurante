import 'order_item_entity.dart';

class OrderEntity {
  final String id;
  final String tableId;
  final String waiterId;
  final String status;
  final List<OrderItem> items;
  final double subtotal;
  final double tip;
  final double total;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderEntity({
    required this.id,
    required this.tableId,
    required this.waiterId,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.tip,
    required this.total,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    return OrderEntity(
      id: json['id'] ?? '',
      tableId: json['tableId'] ?? '',
      waiterId: json['waiterId'] ?? '',
      status: json['status'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromOrderJson(item))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tip: (json['tip'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'waiterId': waiterId,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tip': tip,
      'total': total,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  OrderEntity copyWith({
    String? id,
    String? tableId,
    String? waiterId,
    String? status,
    List<OrderItem>? items,
    double? subtotal,
    double? tip,
    double? total,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      waiterId: waiterId ?? this.waiterId,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tip: tip ?? this.tip,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}