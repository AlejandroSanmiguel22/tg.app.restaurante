import '../../domain/entities/table_entity.dart';

class TableModel extends TableEntity {
  TableModel({
    required super.id,
    required super.number,
    required super.status,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      number: json['number'],
      status: json['status'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'status': status,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class TablesResponseModel {
  final List<TableModel> data;

  TablesResponseModel({required this.data});

  factory TablesResponseModel.fromJson(Map<String, dynamic> json) {
    return TablesResponseModel(
      data: (json['data'] as List)
          .map((table) => TableModel.fromJson(table))
          .toList(),
    );
  }
}