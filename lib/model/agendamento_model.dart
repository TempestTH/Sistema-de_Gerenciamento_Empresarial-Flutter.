class AgendamentoModel {
  final int? id;
  final DateTime? createdAt;
  final String cliente;
  final String servico;
  final String responsavel;
  final DateTime inicio;
  final DateTime fim;
  final String status;
  final num valor;
  final String? observacao;

  AgendamentoModel({
    this.id,
    this.createdAt,
    required this.cliente,
    required this.servico,
    required this.responsavel,
    required this.inicio,
    required this.fim,
    required this.status,
    required this.valor,
    this.observacao,
  });

  factory AgendamentoModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoModel(
      id: json['id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      cliente: json['cliente'] ?? '',
      servico: json['servico'] ?? '',
      responsavel: json['responsavel'] ?? '',
      inicio: DateTime.parse(json['inicio']),
      fim: DateTime.parse(json['fim']),
      status: json['status'] ?? 'Agendado',
      valor: json['valor'] ?? 0,
      observacao: json['observacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'cliente': cliente,
      'servico': servico,
      'responsavel': responsavel,
      'inicio': inicio.toIso8601String(),
      'fim': fim.toIso8601String(),
      'status': status,
      'valor': valor,
      if (observacao != null && observacao!.isNotEmpty)
        'observacao': observacao,
    };
  }
}
