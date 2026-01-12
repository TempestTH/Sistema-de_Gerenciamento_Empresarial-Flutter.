class EstoqueModel {
  final int? id;
  final DateTime? createdAt;
  final int quantidade;
  final int idMaterial;
  final bool entrada;
  final bool saida;

  EstoqueModel({
    this.id,
    this.createdAt,
    required this.quantidade,
    required this.idMaterial,
    required this.entrada,
    required this.saida,
  });

  factory EstoqueModel.fromJson(Map<String, dynamic> json) {
    return EstoqueModel(
      id: json['id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      quantidade: json['Quantidade'],
      idMaterial: json['id_material'],
      entrada: json['Entrada'],
      saida: json['Saida'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'Quantidade': quantidade,
      'id_material': idMaterial,
      'Entrada': entrada,
      'Saida': saida,
    };
  }
}
