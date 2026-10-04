class AgendamentoItemModel {
  final int? id;
  final DateTime? createdAt;
  final int? idAgendamento;
  final int? idMaterial;
  final String descricao;
  final num quantidade;
  final num valorUnitario;
  final bool material;

  AgendamentoItemModel({
    this.id,
    this.createdAt,
    this.idAgendamento,
    this.idMaterial,
    required this.descricao,
    required this.quantidade,
    required this.valorUnitario,
    required this.material,
  });

  num get total => quantidade * valorUnitario;

  factory AgendamentoItemModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoItemModel(
      id: json['id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      idAgendamento: json['id_agendamento'],
      idMaterial: json['id_material'],
      descricao: json['descricao'] ?? '',
      quantidade: json['quantidade'] ?? 0,
      valorUnitario: json['valor_unitario'] ?? 0,
      material: json['material'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (idAgendamento != null) 'id_agendamento': idAgendamento,
      if (idMaterial != null) 'id_material': idMaterial,
      'descricao': descricao,
      'quantidade': quantidade,
      'valor_unitario': valorUnitario,
      'material': material,
    };
  }
}
