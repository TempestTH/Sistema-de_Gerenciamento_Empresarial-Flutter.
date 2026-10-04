class AgendamentoHistoricoModel {
  final int? id;
  final DateTime? createdAt;
  final int? idAgendamento;
  final String titulo;
  final String descricao;

  AgendamentoHistoricoModel({
    this.id,
    this.createdAt,
    this.idAgendamento,
    required this.titulo,
    required this.descricao,
  });

  factory AgendamentoHistoricoModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoHistoricoModel(
      id: json['id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      idAgendamento: json['id_agendamento'],
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (idAgendamento != null) 'id_agendamento': idAgendamento,
      'titulo': titulo,
      'descricao': descricao,
    };
  }
}
