import 'package:projeto_elifone/model/orcamento_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseOrcamentoService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<OrcamentoModel>> listar() async {
    final data = await _client
        .from('orcamentos')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => OrcamentoModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<OrcamentoModel> inserir(OrcamentoModel orcamento) async {
    debugPrint('Payload orcamento: ${orcamento.toJson()}');
    final data = await _client
        .from('orcamentos')
        .insert(orcamento.toJson())
        .select()
        .single();

    return OrcamentoModel.fromJson(Map<String, dynamic>.from(data));
  }
}
