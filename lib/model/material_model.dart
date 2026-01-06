class MaterialModel {
  final int? id;
  final String nome;
  final int quantidade;

  MaterialModel({
    this.id,
    required this.nome,
    required this.quantidade,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json){
    return MaterialModel(
      id: json['id'],
      nome: json['nome'], 
      quantidade: json['quantidade']
    );
  }
  Map<String, dynamic> toJson(){
    return {
      if (id != null) 'id' : id,
      'nome': nome,
      'quantidade': quantidade, 
    };
  }
}