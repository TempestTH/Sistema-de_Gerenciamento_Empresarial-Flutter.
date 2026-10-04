class MaterialModel {
  final int? id;
  final DateTime? createdAt;
  final String nome;
  final int quantidade;
  final num valor;
  final bool metro;

  MaterialModel({
    this.createdAt,
    this.id,
    required this.nome,
    required this.quantidade,
    required this.valor,
    required this.metro,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      id: json['id'],
      nome: json['nome'],
      quantidade: json['quantidade'],
      valor: json['valor'],
      metro: json['metro'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'nome': nome,
      'quantidade': quantidade,
      'valor': valor,
      'metro': metro,
    };
  }
}
