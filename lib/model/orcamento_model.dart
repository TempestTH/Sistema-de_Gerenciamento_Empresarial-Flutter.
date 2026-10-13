import 'dart:convert';
import 'dart:typed_data';

class OrcamentoItemModel {
  final int? idMaterial;
  final String descricao;
  final num quantidade;
  final num valorUnitario;
  final bool material;

  const OrcamentoItemModel({
    this.idMaterial,
    required this.descricao,
    required this.quantidade,
    required this.valorUnitario,
    required this.material,
  });

  num get total => quantidade * valorUnitario;

  factory OrcamentoItemModel.fromJson(Map<String, dynamic> json) {
    return OrcamentoItemModel(
      idMaterial: json['id_material'],
      descricao: json['descricao'] ?? '',
      quantidade: json['quantidade'] ?? 0,
      valorUnitario: json['valor_unitario'] ?? 0,
      material: json['material'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMaterial != null) 'id_material': idMaterial,
      'descricao': descricao,
      'quantidade': quantidade,
      'valor_unitario': valorUnitario,
      'material': material,
      'total': total,
    };
  }
}

class OrcamentoLayoutModel {
  final Uint8List? cabecalho;
  final String? cabecalhoNome;
  final String? cabecalhoPath;
  final Uint8List? rodape;
  final String? rodapeNome;
  final String? rodapePath;
  final String textoPadrao;

  const OrcamentoLayoutModel({
    this.cabecalho,
    this.cabecalhoNome,
    this.cabecalhoPath,
    this.rodape,
    this.rodapeNome,
    this.rodapePath,
    required this.textoPadrao,
  });

  factory OrcamentoLayoutModel.fromJson(Map<String, dynamic> json) {
    return OrcamentoLayoutModel(
      cabecalho: _bytesFromBase64(json['cabecalho_base64']),
      cabecalhoNome: json['cabecalho_nome'],
      cabecalhoPath: json['cabecalho_path'],
      rodape: _bytesFromBase64(json['rodape_base64']),
      rodapeNome: json['rodape_nome'],
      rodapePath: json['rodape_path'],
      textoPadrao: json['texto_padrao'] ?? '',
    );
  }

  OrcamentoLayoutModel copyWith({
    Uint8List? cabecalho,
    String? cabecalhoNome,
    String? cabecalhoPath,
    bool limparCabecalho = false,
    Uint8List? rodape,
    String? rodapeNome,
    String? rodapePath,
    bool limparRodape = false,
    String? textoPadrao,
  }) {
    return OrcamentoLayoutModel(
      cabecalho: limparCabecalho ? null : cabecalho ?? this.cabecalho,
      cabecalhoNome: limparCabecalho
          ? null
          : cabecalhoNome ?? this.cabecalhoNome,
      cabecalhoPath: limparCabecalho
          ? null
          : cabecalhoPath ?? this.cabecalhoPath,
      rodape: limparRodape ? null : rodape ?? this.rodape,
      rodapeNome: limparRodape ? null : rodapeNome ?? this.rodapeNome,
      rodapePath: limparRodape ? null : rodapePath ?? this.rodapePath,
      textoPadrao: textoPadrao ?? this.textoPadrao,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'texto_padrao': textoPadrao,
      'cabecalho_base64': cabecalho == null ? null : base64Encode(cabecalho!),
      'cabecalho_nome': cabecalhoNome,
      'cabecalho_path': cabecalhoPath,
      'rodape_base64': rodape == null ? null : base64Encode(rodape!),
      'rodape_nome': rodapeNome,
      'rodape_path': rodapePath,
    };
  }
}

class OrcamentoModel {
  final int? id;
  final String codigo;
  final String titulo;
  final String cliente;
  final DateTime dataEmissao;
  final bool possuiValidade;
  final DateTime? validade;
  final DateTime createdAt;
  final List<OrcamentoItemModel> itens;
  final String observacoes;
  final OrcamentoLayoutModel layout;

  const OrcamentoModel({
    this.id,
    required this.codigo,
    this.titulo = '',
    required this.cliente,
    required this.dataEmissao,
    required this.possuiValidade,
    this.validade,
    required this.createdAt,
    required this.itens,
    required this.observacoes,
    required this.layout,
  });

  num get subtotal => itens.fold<num>(0, (total, item) => total + item.total);
  num get total => subtotal;

  factory OrcamentoModel.fromJson(Map<String, dynamic> json) {
    final itensJson = json['itens'];
    final itens = itensJson is List
        ? itensJson
              .whereType<Map>()
              .map((item) => OrcamentoItemModel.fromJson(Map.from(item)))
              .toList()
        : <OrcamentoItemModel>[];

    return OrcamentoModel(
      id: _intFromJson(json['id']),
      codigo: json['codigo'] ?? '',
      titulo: json['titulo'] ?? '',
      cliente: json['cliente'] ?? '',
      dataEmissao: DateTime.parse(
        json['data_emissao'] ?? json['created_at'] ?? DateTime.now().toString(),
      ),
      possuiValidade: json['possui_validade'] ?? json['validade'] != null,
      validade: json['validade'] == null
          ? null
          : DateTime.tryParse(json['validade'].toString()),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      itens: itens,
      observacoes: json['observacoes'] ?? '',
      layout: OrcamentoLayoutModel.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'titulo': titulo,
      'cliente': cliente,
      'data_emissao': _dateOnly(dataEmissao),
      'possui_validade': possuiValidade,
      'validade': possuiValidade && validade != null
          ? _dateOnly(validade!)
          : null,
      'observacoes': observacoes,
      'itens': itens.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'total': total,
      'texto_padrao': layout.textoPadrao,
    };
  }
}

Uint8List? _bytesFromBase64(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  try {
    return base64Decode(value.toString());
  } catch (_) {
    return null;
  }
}

String _dateOnly(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

int? _intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
