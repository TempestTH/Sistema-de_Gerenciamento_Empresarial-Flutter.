class AgendamentoAnexoModel {
  final int? id;
  final DateTime? createdAt;
  final int? idAgendamento;
  final String nome;
  final String tipo;
  final String caminho;

  AgendamentoAnexoModel({
    this.id,
    this.createdAt,
    this.idAgendamento,
    required this.nome,
    required this.tipo,
    required this.caminho,
  });

  factory AgendamentoAnexoModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoAnexoModel(
      id: json['id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      idAgendamento: json['id_agendamento'],
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      caminho: json['caminho'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (idAgendamento != null) 'id_agendamento': idAgendamento,
      'nome': nome,
      'tipo': tipo,
      'caminho': caminho,
    };
  }
}
