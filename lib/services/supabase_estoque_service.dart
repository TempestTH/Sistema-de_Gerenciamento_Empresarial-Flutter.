import '../model/estoque_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEstoqueService {
  final SupabaseClient _client = Supabase.instance.client;

  // CREATE
  Future<void> inserir(EstoqueModel estoque) async {
    await _client
        .from('Estoque')
        .insert(estoque.toJson());
  }

  // READ
  Future<List<dynamic>> listarComMaterial() async {
    final data = await _client
        .from('Estoque')
        .select('''
          id,
          created_at,
          Quantidade,
          Entrada,
          Saida,
          Material (
            nome
          )
        ''')
        .order('created_at', ascending: false);

    return data;
  }


  // DELETE
  Future<void> deletar(int id) async {
    await _client
        .from('Estoque')
        .delete()
        .eq('id', id);
  }
}
