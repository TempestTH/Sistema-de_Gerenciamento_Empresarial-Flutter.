import 'package:projeto_elifone/model/agendamento_anexo_model.dart';
import 'package:projeto_elifone/model/agendamento_historico_model.dart';
import 'package:projeto_elifone/model/agendamento_item_model.dart';
import 'package:projeto_elifone/model/agendamento_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAgendamentoService {
  final SupabaseClient _client = Supabase.instance.client;
  static const List<String> _historicoTables = [
    'agendamento_historico',
    'AgendamentoHistorico',
  ];

  Future<AgendamentoModel> inserir(AgendamentoModel agendamento) async {
    final data = await _client
        .from('Agendamentos')
        .insert(agendamento.toJson())
        .select()
        .single();

    return AgendamentoModel.fromJson(data);
  }

  Future<List<AgendamentoModel>> listar() async {
    final data = await _client
        .from('Agendamentos')
        .select()
        .order('inicio', ascending: true);

    return (data as List)
        .map((json) => AgendamentoModel.fromJson(json))
        .toList();
  }

  Future<AgendamentoModel> buscarPorId(int id) async {
    final data = await _client
        .from('Agendamentos')
        .select()
        .eq('id', id)
        .single();

    return AgendamentoModel.fromJson(data);
  }

  Future<void> atualizar(AgendamentoModel agendamento, int id) async {
    await _client
        .from('Agendamentos')
        .update(agendamento.toJson())
        .eq('id', id);
  }

  Future<void> atualizarStatus(int id, String status) async {
    await _client.from('Agendamentos').update({'status': status}).eq('id', id);
  }

  Future<List<AgendamentoItemModel>> listarItens(int idAgendamento) async {
    final data = await _client
        .from('AgendamentoItens')
        .select()
        .eq('id_agendamento', idAgendamento)
        .order('created_at', ascending: true);

    return (data as List)
        .map((json) => AgendamentoItemModel.fromJson(json))
        .toList();
  }

  Future<void> inserirItem(AgendamentoItemModel item) async {
    await _client.from('AgendamentoItens').insert(item.toJson());
  }

  Future<void> deletarItem(int id) async {
    await _client.from('AgendamentoItens').delete().eq('id', id);
  }

  Future<List<AgendamentoAnexoModel>> listarAnexos(int idAgendamento) async {
    final data = await _client
        .from('AgendamentoAnexos')
        .select()
        .eq('id_agendamento', idAgendamento)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => AgendamentoAnexoModel.fromJson(json))
        .toList();
  }

  Future<void> inserirAnexo(AgendamentoAnexoModel anexo) async {
    await _client.from('AgendamentoAnexos').insert(anexo.toJson());
  }

  Future<void> deletarAnexo(int id) async {
    await _client.from('AgendamentoAnexos').delete().eq('id', id);
  }

  Future<List<AgendamentoHistoricoModel>> listarHistorico(
    int idAgendamento,
  ) async {
    Object? ultimoErro;

    for (final table in _historicoTables) {
      try {
        final data = await _client
            .from(table)
            .select()
            .eq('id_agendamento', idAgendamento)
            .order('created_at', ascending: false);

        return (data as List)
            .map((json) => AgendamentoHistoricoModel.fromJson(json))
            .toList();
      } catch (error) {
        ultimoErro = error;
      }
    }

    throw ultimoErro ?? Exception('Historico indisponivel');
  }

  Future<void> inserirHistorico(AgendamentoHistoricoModel historico) async {
    Object? ultimoErro;

    for (final table in _historicoTables) {
      try {
        await _client.from(table).insert(historico.toJson());
        return;
      } catch (error) {
        ultimoErro = error;
      }
    }

    throw ultimoErro ?? Exception('Historico indisponivel');
  }

  Future<void> deletar(int id) async {
    await _client.from('Agendamentos').delete().eq('id', id);
  }
}
