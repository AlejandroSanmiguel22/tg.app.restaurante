class TableEntity {
  final String id;
  final int number;
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TableEntity({
    required this.id,
    required this.number,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper methods para obtener el estado de la mesa
  bool get isAvailable => status == 'libre';
  bool get isOccupied => status == 'ocupada';
  bool get isAttended => status == 'atendida';
}